//  File Name        : swthread.h
//  Description      : Smith-Waterman aligner thread definitions
//
//                     The SWThread class is the worker thread class that performs
//                     software Smith-Waterman alignment construction on high scoring
//                     regions discovered by the FPGA accelerator engines. They
//                     obtain high scoring regions from a HighScoreRegion shared
//                     queue prepared by the ResultsReaderThread, and store
//                     completed alignments in an AlignmentResult shared queue
//                     for the main thread.
//
//                     The class receives the query id, reference id, high scoring
//                     region length and offset from the HighScoreRegion shared
//                     queue. With this info, it obtains the query sequence and
//                     reference sequence from a shared QuerySeqManager and 
//                     RefSeqManager, respectively.
//
//                     Upon completion of an alignment, it decrements the high
//                     scoring region count (managed by the query sequence manager)
//                     of that query.
//
//  Revision History :
//      Albert Ng   Oct 02 2013     Initial Revision 
//      Albert Ng   Oct 05 2013     AlnOp names suffixed with _OP
//      Albert Ng   Oct 07 2013     Added SWThread::Join()
//      Albert Ng   oct 09 2013     Added query seq manager

#ifndef SWTHREAD_H_
#define SWTHREAD_H_

#include <pthread.h>
#include "def.h"
#include "threadqueue.h"
#include "utils.h"
#include "refseqmanager_stub.h"
#include "queryseqmanager.h"

// Software Smith-Waterman aligner worker thread
class SWThread {
  public:
    // Empty constructor
    SWThread();

    // Complete constructor 
    SWThread(SwAffineGapParams params, ThreadQueue<HighScoreRegion>* hsr_queue,
             ThreadQueue<AlignmentResult>* result_queue, RefSeqManager* ref_seq_manager,
             QuerySeqManager* query_seq_manager);

    // Initialization function (called by constructor)
    void Init(SwAffineGapParams params, ThreadQueue<HighScoreRegion>* hsr_queue,
             ThreadQueue<AlignmentResult>* result_queue, RefSeqManager* ref_seq_manager,
             QuerySeqManager* query_seq_manager);

    // Set affine gap scoring metric parameters
    void SetParams(SwAffineGapParams params);

    // Run the thread
    void Run();  

    // Join the thread
    // Can't be used for now, since the thread infinite loops and never terminates
    void Join(); 

  private:
    // Enumeration of possible alignment operations
    enum AlnOp {INSERT_OP, DELETE_OP, MATCH_OP, ZERO_OP};

    // Smith-Waterman aligner thread arguments struct
    struct SWThreadArgs {
      // Pointer to affine gap metric scoring parameters
      SwAffineGapParams* params;          
  
      // Pointer to mutex for scoring parameters
      pthread_mutex_t* params_mutex;
    
      // Pointer to shared job queue of high scoring regions to be aligned
      ThreadQueue<HighScoreRegion>* hsr_queue;
    
      // Pointer to shared result queue in which alignment results are to be stored
      ThreadQueue<AlignmentResult>* result_queue;

      // Pointer to shared reference sequence manager
      RefSeqManager* ref_seq_manager;

      // Pointer to shared query sequence manager
      QuerySeqManager* query_seq_manager;
    };

    // Function for thread to run.
    // Continuously perform alignments, grabbing alignment jobs from the hsr_queue
    //   and storing results in the result_queue
    static void* Align(void* args);

    // Actual pthread instance
    pthread_t thread_;
    
    // Thread arguments
    SWThreadArgs args_;

    // Smith-Waterman affine gap scoring params
    SwAffineGapParams params_;

    // Mutex for scoring params
    pthread_mutex_t params_mutex_;
};

#endif // SWTHREAD_H_