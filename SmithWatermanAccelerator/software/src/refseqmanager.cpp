//  File Name        : refseqmanager.cpp
//  Description      : Reference sequence manager
//
//  Revision History :
//      Albert Ng   Oct 18 2013     Initial Revision
//      Albert Ng   Oct 19 2013     Completed StreamRefSeq()
//      Albert Ng   Oct 29 2013     Uses fasta.h to parse FASTA files
//      Albert Ng   Nov 01 2013     Added GetRefName()
//      Albert Ng   Nov 19 2013     Added chromosomes

#include "def.h"
#include <stdlib.h>
#include <time.h>
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <assert.h>
#include "refseqmanager.h"
#include "utils.h"
#include "fasta.h"
#ifdef SIM_PICO
  #include "picodrv_sim.h"
#else
  #include <picodrv.h>
  #include <pico_errors.h>
#endif

static const int CHR_NAME_FIELD = 0;

RefSeqManager::RefSeqManager() {
//  cur_ref_id_ = 0;
  cur_block_ = 0;
  srand(time(NULL));
}

RefSeqManager::RefSeqManager(PicoDrv** pico_drivers) {
  Init(pico_drivers);
}

void RefSeqManager::Init(PicoDrv** pico_drivers) {
//  cur_ref_id_ = 0;
  cur_block_ = 0;
  pico_drivers_ = pico_drivers;
}

char* RefSeqManager::GetRefSeq(int ref_id, int chr_id, long long int ref_offset, long long int ref_len) {
  //assert(ref_seq_.count(ref_id) > 0);
  assert(ref_id < ref_seq_.size());
  assert(ref_offset + ref_len <= ref_length_[ref_id][chr_id]);
  //std::cout<<"GetRefSeq: "<<ref_id <<" "<<ref_offset<<" " <<ref_len<<std::endl;
  char* ref_seq = ref_seq_[ref_id][chr_id];
  return &(ref_seq[ref_offset]);
}

long long int RefSeqManager::GetRefAddr(int ref_id, int chr_id) {
  assert(ref_id < ref_addr_.size());
  assert(chr_id < ref_addr_[ref_id].size());
  return ref_addr_[ref_id][chr_id];
}

long long int RefSeqManager::GetRefLength(int ref_id, int chr_id) {
  assert(ref_id < ref_length_.size());
  assert(chr_id < ref_length_[ref_id].size());
  return ref_length_[ref_id][chr_id];
}

int RefSeqManager::GetRefID(std::string ref_name) {
  if (ref_id_.count(ref_name) == 0) {
    return -1;
  }
  return ref_id_[ref_name];
}

int RefSeqManager::GetChrID(int ref_id, std::string chr_name) {
  if (ref_id >= chr_id_.size() || chr_id_[ref_id].count(chr_name) == 0) {
    return -1;
  }
  return chr_id_[ref_id][chr_name];
}

std::string RefSeqManager::GetRefName(int ref_id) {
  assert(ref_id < ref_name_.size());
  return ref_name_[ref_id];
}

std::string RefSeqManager::GetChrName(int ref_id, int chr_id) {
  assert(ref_id < chr_name_.size());
  assert(chr_id < chr_name_[ref_id].size());
  return chr_name_[ref_id][chr_id];
}

void RefSeqManager::AddRef(std::string filename, std::string ref_name) {
  std::vector<std::vector<std::string> > descrips;
  std::vector<char*> seqs;
  std::vector<int> lengths;
  
  ParseFastaFile(filename, &descrips, &seqs, &lengths);

  int ref_id;
  if (ref_id_.count(ref_name) == 0) {
    ref_id = ref_name_.size();
    ref_id_[ref_name] = ref_id;
    
    std::map<std::string, int> chr_id_v;
    chr_id_.push_back(chr_id_v);
    
    ref_name_.push_back(ref_name);
    
    std::vector<std::string> chr_name_v;
    chr_name_.push_back(chr_name_v);
    
    std::vector<char*> ref_seq_v;
    ref_seq_.push_back(ref_seq_v);
    
    std::vector<long long int> ref_addr_v;
    ref_addr_.push_back(ref_addr_v);
    
    std::vector<long long int> ref_length_v;
    ref_length_.push_back(ref_length_v);
  } else {
    ref_id = ref_id_[ref_name];
  }
    
  for (int i = 0; i < seqs.size(); i++) {     
    // Stream ref seq to DRAM
    StreamRefSeq(seqs[i], ((long long int) cur_block_) * (REF_BLOCK_LEN/4), lengths[i]);
    
    // Record ref seq information
    /*ref_id_[descrips[i][REF_NAME_FIELD]] = cur_ref_id_;
    ref_name_[cur_ref_id_] = descrips[i][REF_NAME_FIELD];
    ref_seq_[cur_ref_id_] = seqs[i];
    ref_addr_[cur_ref_id_] = cur_block_;
    ref_length_[cur_ref_id_] = lengths[i];*/
    int chr_id = chr_name_[ref_id].size();
    chr_id_[ref_id][descrips[i][CHR_NAME_FIELD]] = chr_id;
    chr_name_[ref_id].push_back(descrips[i][CHR_NAME_FIELD]);
    ref_seq_[ref_id].push_back(seqs[i]);
    ref_addr_[ref_id].push_back(cur_block_);
    ref_length_[ref_id].push_back(lengths[i]);

    std::cout << "Ref ID: " << ref_id << "\tRef Name: " << ref_name_[ref_id] 
              << "\tChr ID: " << chr_id << "\tChr Name: " << chr_name_[ref_id][chr_id]
              << "\tRef Len: " << ref_length_[ref_id][chr_id] << "\tRef Addr: " << ref_addr_[ref_id][chr_id]
              << std::endl;

    //std::cout<<"Ref ID: "<<cur_ref_id_<<"\tName: "<<ref_name_[cur_ref_id_]<<"\tRef Len: "<<ref_length_[cur_ref_id_]<<"\tRef Addr: "<<ref_addr_[cur_ref_id_]<<std::endl;
    /*for (int j = 0; j < ref_length_[cur_ref_id_]; j++) {
      std::cout<<seqs[i][j];
    }
    std::cout << '\n' << std::endl;*/

    // Move to next ref seq
    //cur_ref_id_++;
    if (lengths[i] % REF_BLOCK_LEN == 0) {
      cur_block_ += (lengths[i] / REF_BLOCK_LEN);
    } else {
      cur_block_ += ((lengths[i] / REF_BLOCK_LEN) + 1);
    }
  }
}

// Note: ref_addr is the BYTE address in the FPGA DRAM to stream to
void RefSeqManager::StreamRefSeq(char* ref_seq, long long int ref_addr, long long int ref_length) {
  assert(REF_BLOCK_LEN % 4 == 0);

  // Compute length of 2-bit formatted ref seq buffer
  // Pad ref seq buffer hold a multiple of REF_BLOCK_LEN nucleotides
  int twobit_buf_length = ref_length / REF_BLOCK_LEN;
  if (ref_length % REF_BLOCK_LEN != 0) {
    twobit_buf_length++;
  }
  twobit_buf_length *= (REF_BLOCK_LEN / 4);

  // Build 2-bit formatted ref seq buffer
  // Replace N's with random nucleotide
  char* twobit_buf = new char[twobit_buf_length];
  for (int i = 0; i < twobit_buf_length; i++) {
    char val = 0;
    for (int j = i*4+3; j >= i*4; j--) {
      val <<= 2;
      if (j < ref_length) {
        if (ref_seq[j] != 'N' && ref_seq[j] != 'n') {
          val += NtChar2Int(ref_seq[j]);
        } else {
          val += (rand() % 4);
        }
      }
    }
    twobit_buf[i] = val;
  }

  // Write the ref seq to the FPGA DRAMS
  int err;
  char ibuf[1024];
  for (int i = 0; i < NUM_FPGAS; i++) {
    err = pico_drivers_[i]->WriteRam(ref_addr, (void*) twobit_buf, twobit_buf_length);
    if (err < 0) {
      fprintf(stderr, "Failed to write ref seq to FPGA %d, error: %s\n", i, 
              PicoErrors_FullError(err, ibuf, sizeof(ibuf)));
    }
  }

  delete[] twobit_buf;
}

