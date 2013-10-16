//  File Name        : enginedispatchthread.h
//  Description      : FPGA Engine Alignment Dispatch Thread definitions
//
//  Revision History :
//      Albert Ng   Oct 15 2013     Initial Revision 

#ifndef ENGINEDISPATCHTHREAD_H_
#define ENGINEDISPATCHTHREAD_H_

#include "picodrv_stub.h"
#include "threadqueue.h"
#include "queryseqmanager.h"
#include "def.h"
#include <pthread.h>

class EngineDispatchThread{
  public:
    // Empty constructor
    EngineDispatchThread();

    // Complete constructor
    EngineDispatchThread(PicoDrv* pico_drivers, int** streams, 
                         ThreadQueue<AlignmentJob>* alignment_job_queue,
                         ThreadQueue<AlignmentJob>** engine_job_queues,
                         QuerySeqManager* query_seq_manager);

    // Initialization function (called by constructor)
    void Init(PicoDrv* pico_drivers, int** streams,
              ThreadQueue<AlignmentJob>* alignment_job_queue,
              ThreadQueue<AlignmentJob>** engine_job_queues,
              QuerySeqManager* query_seq_manager);

    // Run the thread
    void Run();

    // Join the thread
    // Can't be used for now, since the thread infinite loops and never terminates
    void Join();

  private:
    // FPGA engine dispatch thread arguments struct
    struct EngineDispatchThreadArgs {
      // Pointers to FPGA driver class objects
      PicoDrv* pico_drivers;
      
      // Engine stream handles, indexed by [FPGA][Stream]
      int** streams;
      
      // Pointer to shared queue of alignment jobs to be done
      ThreadQueue<AlignmentJob>* alignment_job_queue;

      // Pointers to shared queues of alignment jobs dispatched to FPGA engines
      ThreadQueue<EngineJob>** engine_job_queues;

      // Pointer to shared query sequence manager
      QuerySeqManager* query_seq_manager;

      // Pointer to shared reference sequence manager
      RefSeqManager* ref_seq_manager;
    };

    // Function for thread to run.
    // Continuously retrieves alignment jobs from alignment job queue, splits the alignment
    //   jobs into engine sub-jobs, sends the engine sub-jobs to the FPGA engines, and
    //   records the scheduled engine jobs onto the engine job queues.
    static void* Dispatch(void* args);

    // Dispatch an alignment job to an engine
    static void DispatchJob(PicoDrv* pico_driver, int stream, int query_id, char* query_seq, int query_len, int num_ref_blocks, int first_ref_block, int threshold);

    static void RecordEngineJob(ThreadQueue<EngineJob>* engine_job_queue, int query_id, int query_len, int ref_id, int ref_offset, int ref_len, int overlap_offset, int threshold);

    // Actual pthread instance
    pthread_t thread_;

    // Thread arguments
    EngineDispatchThreadArgs args_;
};

#endif // ENGINEDISPATCHTHREAD_H_