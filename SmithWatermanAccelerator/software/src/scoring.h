//  File Name        : scoring.h
//  Description      : Scoring Parameters definitions
//
//  Revision History :
//      Albert Ng   Oct 22 2013     Initial Revision
//      Albert Ng   Oct 29 2013     Changed sub_mat_ to int** from [][]

#ifndef SCORING_H_
#define SCORING_H_

#include <string>

#define SW_PARAMS_BUF_LENGTH 12

// Data structure holding affine gap penalty scoring scheme parameters
class SwAffineGapParams {
  public:
    SwAffineGapParams();
    SwAffineGapParams(int sub_mat[][4], int gap_open, int gap_extend);
    SwAffineGapParams(std::string s);
    ~SwAffineGapParams();
    
    void GetSubMat(int** sub_mat);
    int GetGapOpen();
    int GetGapExtend();
    
    // Check if substitution matrix is symmetric
    bool IsValid();
    
    // Format params as a string
    std::string ToString();
    
    // Allocate and store params in the buffer and get the buffer length
    int* ToBuf(int* buf_len);
    
  private:
    int sub_mat_[4][4];
    int gap_open_;
    int gap_extend_;
};

#endif // SCORING_H_
