//  File Name        : resultsreaderthread.cpp
//  Description      : FPGA Engine Results Reader Thread
//                     Full description in resultsreaderthread.h
//
//  Revision History :
//      Albert Ng   Oct 08 2013     Initial Revision 
//      Albert Ng   Oct 10 2013     Finished initial implementation, untested
//      Albert Ng   Oct 14 2013     Tested with swthread

#include "picodrv_stub.h"
#include "resultsreaderthread.h"
#include "threadqueue.h"
#include "def.h"
#include <pthread.h>
#include <stdint.h>

ResultsReaderThread::ResultsReaderThread() {
}

ResultsReaderThread::ResultsReaderThread(PicoDrv* pico_drivers, int num_drivers, int** streams,
                                         int* num_streams, ThreadQueue<HighScoreRegion>* hsr_queue,
                                         QuerySeqManager* query_seq_manager,
                                         ThreadQueue<AlignmentJob>** alignment_job_queue) {
  Init(pico_drivers, num_drivers, streams, num_streams, hsr_queue, query_seq_manager,
       alignment_job_queue);
}

void ResultsReaderThread::Init(PicoDrv* pico_drivers, int num_drivers, int** streams,
                               int* num_streams, ThreadQueue<HighScoreRegion>* hsr_queue,
                               QuerySeqManager* query_seq_manager,
                               ThreadQueue<AlignmentJob>** alignment_job_queue) {
  args_.pico_drivers = pico_drivers;
  args_.num_drivers = num_drivers;
  args_.streams = streams;
  args_.num_streams = num_streams;
  args_.hsr_queue = hsr_queue;
  args_.query_seq_manager = query_seq_manager;
  args_.alignment_job_queue = alignment_job_queue;
}

void ResultsReaderThread::Run() {
  pthread_create(&thread_, NULL, &ResultsReaderThread::ReadResults, (void*) (&args_));
}

void ResultsReaderThread::Join() {
  pthread_join(thread_, NULL);
}

void* ResultsReaderThread::ReadResults(void* args) {
  // Get result reader arguments
  PicoDrv* pico_drivers = ((ResultsReaderThreadArgs*)args)->pico_drivers;
  int num_drivers = ((ResultsReaderThreadArgs*)args)->num_drivers;
  int** streams = ((ResultsReaderThreadArgs*)args)->streams;
  int* num_streams = ((ResultsReaderThreadArgs*)args)->num_streams;
  ThreadQueue<HighScoreRegion>* hsr_queue = ((ResultsReaderThreadArgs*)args)->hsr_queue;
  QuerySeqManager* query_seq_manager = ((ResultsReaderThreadArgs*)args)->query_seq_manager;
  ThreadQueue<AlignmentJob>** alignment_job_queue = ((ResultsReaderThreadArgs*)args)->alignment_job_queue;

  // Set up memory buffers
  uint32_t*** read_mem_buf = new uint32_t**[num_drivers];
  for (int i = 0; i < num_drivers; i++) {
    read_mem_buf[i] = new uint32_t*[num_streams[i]];
    for (int j = 0; j < num_streams[i]; j++) {
      read_mem_buf[i][j] = new uint32_t[4096];
      for (int k = 0; k < 4096; k++) {
        read_mem_buf[i][j][k] = 0;
      }
    }
  }

  // Initialize FSM states and values
  HSRParserState* states[num_drivers];
  for (int i = 0; i < num_drivers; i++) {
    states[i] = new HSRParserState[num_streams[i]];
    for (int j = 0; j < num_streams[i]; j++) {
      states[i][j] = INIT;
    }
  }
  CoalescedHighScoreBlock* chsbs[num_drivers];
  AlignmentJob* jobs[num_drivers];
  for (int i = 0; i < num_drivers; i++) {
    chsbs[i] = new CoalescedHighScoreBlock[num_streams[i]];
    jobs[i] = new AlignmentJob[num_streams[i]];
  }

  while(true) {
    for (int i = 0; i < num_drivers; i++) {
      for (int j = 0; j < num_streams[i]; j++) {
        int num_bytes_available = pico_drivers[i].GetBytesAvailable(streams[i][j], true);
        if (num_bytes_available >= 16) {
          
          // Read full 128-bit packets (check might not be necessary)
          int num_bytes_to_read = num_bytes_available > 4096 ? 4096 : (num_bytes_available/16)*16;
          pico_drivers[i].ReadStream(streams[i][j], read_mem_buf[i][j], num_bytes_to_read);


          for (int k = 0; k < num_bytes_to_read / 16; k++) {
            uint32_t high_score_block = read_mem_buf[i][j][k*4];
            uint32_t query_id = read_mem_buf[i][j][k*4 + 1];
            
            // High scoring ref seq block parser FSM
            switch(states[i][j]) {
              case INIT:
                jobs[i][j] = alignment_job_queue[i][j].Pop();
                if (high_score_block == END_OF_ALIGNMENT) {
                  query_seq_manager->DecHighScoreRegionCount(jobs[i][j].query_id);
                  states[i][j] = INIT;
                } else {
                  chsbs[i][j] = StartCHSB(high_score_block);
                  states[i][j] = IN_HSR;
                }
                break;

              case IN_HSR:
                if (high_score_block == END_OF_ALIGNMENT) {
                  StoreHSR(chsbs[i][j], jobs[i][j], hsr_queue, query_seq_manager);
                  query_seq_manager->DecHighScoreRegionCount(jobs[i][j].query_id);
                  states[i][j] = INIT;
                } else if (IsAdjacentBlock(high_score_block, chsbs[i][j])) {
                  chsbs[i][j] = ExtendCHSB(chsbs[i][j]);
                  states[i][j] = IN_HSR;
                } else {
                  StoreHSR(chsbs[i][j], jobs[i][j], hsr_queue, query_seq_manager);
                  chsbs[i][j] = StartCHSB(high_score_block);
                  states[i][j] = IN_HSR;
                }
                break;

              default: // Shouldn't get here
                break;
            }
            /*if (jobs[i][j].query_id != query_id) {
              std::cerr << "FATAL: Alignment job query ID " << jobs[i][j].query_id <<
                           " does not match received query ID " << query_id <<
                           " from FPGA engine stream!" << std::endl;
              exit(1);
            }*/
          }
        }
      }
    }
  }
}

// Stores the high scoring region onto the high score region queue to pass to Smith-Waterman
//   threads for alignment. Modifies the HSR length and offset to include up to 2 query
//   length extension at the front (bounded by the job boundaries).
void ResultsReaderThread::StoreHSR(CoalescedHighScoreBlock chsb, AlignmentJob job, ThreadQueue<HighScoreRegion>* hsr_queue, QuerySeqManager* query_seq_manager) {
  HighScoreRegion hsr;
  hsr.query_id = job.query_id;
  hsr.ref_id = job.ref_id;
  hsr.threshold = job.threshold;

  hsr.offset = (job.ref_offset/REF_BLOCK_LEN)*REF_BLOCK_LEN + chsb.block_offset * REF_BLOCK_LEN - 2*job.query_len;
  hsr.len = chsb.num_blocks * REF_BLOCK_LEN + 2*job.query_len;
  
  // Left boundary check
  if (hsr.offset < job.ref_offset) {
    hsr.len -= (job.ref_offset - hsr.offset);
    hsr.offset = job.ref_offset;
  }

  // Right boundary check
  if ((hsr.offset + hsr.len) > (job.ref_offset + job.ref_len)) {
    hsr.len -= ((hsr.offset + hsr.len) - (job.ref_offset + job.ref_len));
  } 
  
  hsr_queue->Push(hsr);
  query_seq_manager->IncHighScoreRegionCount(hsr.query_id);
}

// Begins a new coalesced high scoring block
ResultsReaderThread::CoalescedHighScoreBlock ResultsReaderThread::StartCHSB(uint32_t block_offset) {
  CoalescedHighScoreBlock chsb;
  chsb.block_offset = block_offset;
  chsb.num_blocks = 1;
  return chsb;
}

// Coalesces a high scoring block with the next block
ResultsReaderThread::CoalescedHighScoreBlock ResultsReaderThread::ExtendCHSB(CoalescedHighScoreBlock chsb) {
  chsb.num_blocks++;
  return chsb;
}

// Checks if a high scoring block index is adjacent to the given block, indicating
//   that they should be coalesced.
bool ResultsReaderThread::IsAdjacentBlock(uint32_t high_score_block, CoalescedHighScoreBlock chsb) {
  if (chsb.block_offset + chsb.num_blocks == high_score_block) {
    return true;
  }
  return false;
}