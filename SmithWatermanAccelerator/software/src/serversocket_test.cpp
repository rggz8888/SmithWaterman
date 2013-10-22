//  File Name        : serversocket_test.cpp
//  Description      : Server Socket class test
//
//  Revision History :
//      Albert Ng   Oct 21 2013     Initial Revision
//

#include "serversocket.h"
#include <iostream>

int main(void) {
  std::cout << "Running server process..." << std::endl;

  ServerSocket server(30000);
  while (true) {
    ServerSocket new_sock;
    server.Accept(&new_sock);
    std::string data;
    new_sock.Recv(&data);
    std::cout << data << std::endl;
    new_sock.Send(data);
  }

  return 0;
}
