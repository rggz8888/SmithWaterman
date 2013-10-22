//  File Name        : socket.cpp
//  Description      : Basic socket class
//
//  Revision History :
//      Albert Ng   Oct 21 2013     Initial Revision
//

#include "socket.h"
#include <string>
#include <iostream>
#include <errno.h>

Socket::Socket() {
  sock_fd_ = INVALID;
  memset(&sock_addr_, 0, sizeof(sock_addr_));
}

Socket::~Socket() {
  if (sock_fd_ != INVALID) {
    close(sock_fd_);
  }
}

bool Socket::Create() {
  sock_fd_ = socket(AF_INET, SOCK_STREAM, 0);
  if (sock_fd_ == INVALID) {
    return false;
  }
 
  // Reuse local addresses 
  int on = 1;
  if (setsockopt(sock_fd_, SOL_SOCKET, SO_REUSEADDR, (const char*) &on, sizeof(on)) == -1) {
    return false;
  }

  return true;
}

bool Socket::Send(std::string s) {
  int status = send(sock_fd_, s.c_str(), s.size(), SO_NOSIGPIPE);
  return (status != -1);
}

int Socket::Recv(std::string* s) {
  char buf[RECV_BUF_SIZE];
  memset(buf, 0, RECV_BUF_SIZE);

  int status = recv(sock_fd_, buf, RECV_BUF_SIZE, 0);
  *s = "";
  if (status == -1) {
    std::cout << "In Socket::Recv(), Error number " << errno << std::endl;
    return 0;
  } else if (status == 0) {
    return 0;
  }

  *s = buf;
  return status;
}

void Socket::SetSockFD(int sock_fd) {
  sock_fd_ = sock_fd;
}
