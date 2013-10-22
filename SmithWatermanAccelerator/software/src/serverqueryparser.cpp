//  File Name        : serverqueryparser.cpp
//  Description      : Server Query Parser class
//
//  Revision History :
//      Albert Ng   Oct 22 2013     Initial Revision
//

#include "serverqueryparser.h"
#include "threadqueue.h"
#include "scoring.h"
#include <sstream>
#include "def.h"
#include "queryseqmanager.h"
#include "refseqmanager.h"

ServerQueryParser::ServerQueryParser(int port) {
  server_.Init(port);
}

ServerQueryParser::~ServerQueryParser() {
}

std::list<int> ServerQueryParser::ParseQueryGroup(ThreadQueue<AlignmentJob>* alignment_job_queue, 
                                                  QuerySeqManager* query_seq_manager,
                                                  RefSeqManager* ref_seq_manager) {
  // Accept the next client's connection request
  ServerSocket new_sock;
  server_.Accept(&new_sock);
  
  // Receive the scoring params and store onto job queue
  std::string s;
  new_sock.Recv(&s);
  SwAffineGapParams params(s);
  AlignmentJob params_job;
  params_job.query_id = PARAMS_JOB;
  params_job.params = params;
  alignment_job_queue->Push(params_job);
  
  // Receive the queries and store onto job queue
  std::list<int> query_ids;
  std::string query_name;
  std::string ref_name;
  long long int ref_start;
  long long int ref_end;
  int threshold;
  std::string query_seq;
  new_sock.Recv(&s);
  while (s != END_OF_QUERY_GROUP) {
    std::istringstream iss(s);
    iss >> query_name;
    iss >> query_seq; 
    iss >> ref_name;
    iss >> ref_start;
    iss >> ref_end;
    iss >> threshold;
    
    int query_id = query_seq_manager->AddQuery(query_name, query_seq)
    query_ids.push_back(query_id);
    
    AlignmentJob job;
    job.query_id = query_id;
    job.ref_id = ref_seq_manager->GetRefID(ref_name);
    job.ref_offset = ref_start - 1;
    job.ref_len = ref_end - ref_start;
    job.threshold = threshold;
    job.params = params;
    alignment_job_queue->Push(job);
    
    new_sock.Recv(&s);
  }
  
  return query_ids;
}
