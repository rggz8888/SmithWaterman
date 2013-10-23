//  File Name        : serverqueryparser.h
//  Description      : Server Query Parser class definitions
//
//  Revision History :
//      Albert Ng   Oct 22 2013     Initial Revision
//

#ifndef SERVERQUERYPARSER_H_
#define SERVERQUERYPARSER_H_

#include "serversocket.h"
#include "threadqueue.h"
#include "queryseqmanager.h"
#include "refseqmanager.h"
#include "def.h"
#include <string>
#include <list>

class ServerQueryParser {
  public:
    ServerQueryParser(int port);
    ~ServerQueryParser();
    
    // Receive the next query group from a client.
    // Add the queries to the query seq manager
    // Store the scoring params and queries onto the alignment job queue
    // Returns the list of query IDs in this group
    std::list<int> ParseQueryGroup(ThreadQueue<AlignmentJob>* alignment_job_queue, 
                                   QuerySeqManager* query_seq_manager,
                                   RefSeqManager* ref_seq_manager);
     
  private:
    enum ParserState {PARAMS, QUERIES};
    
    // FSM action function
    // Returns true when a query group is done
    bool Action(std::string line,
                ThreadQueue<AlignmentJob>* alignment_job_queue, 
                QuerySeqManager* query_seq_manager,
                RefSeqManager* ref_seq_manager,
                std::list<int>* query_ids);
    
    ServerSocket server_;
    ServerSocket client_sock_;
    std::string rcv_buf_;
    std::string cur_line_;
    bool client_active_;
    ParserState state_;
    SwAffineGapParams params_;
};
    
    
    
#endif // SERVERQUERYPARSER_H_