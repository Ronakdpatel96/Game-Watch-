#include <iostream>
#include <cstring>
#include <string>


#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <arpa/inet.h>

int main() {

	// =====================================================
	// 1. TCP Server Socket
	//    for Python
	// =====================================================
	
	int pythonTcpServer = socket(AF_INET, SOCK_STREAM, 0);

	if (pythonTcpServer == -1)
	{
    		std::cerr << "Failed to create TCP Server socket\n";
    		return 1;
	}

	std::cout << "TCP socket created!\n";

	sockaddr_in pythonAddress{};

	pythonAddress.sin_family = AF_INET;
	pythonAddress.sin_addr.s_addr = INADDR_ANY;
	pythonAddress.sin_port = htons(5000);

        sockaddr_in tcpAddress{};

        if(bind(
                pythonTcpServer,
                reinterpret_cast<sockaddr*>(&pythonAddress),                    sizeof(pythonAddress)
        ) == -1) {
                perror("Python TCP bind error");
                return 1;
        }

	if (listen(pythonTcpServer,5) == -1) {
		perror("Python TCP Listen failed");
		return 1;
	}

	std::cout << "Waiting for Python TCP connection...\n";

	int pythonTcpSocket = accept(
		pythonTcpServer,
		nullptr,
		nullptr		
	);

	if (pythonTcpSocket == -1) {
		perror("python TCP accept failed");
		return 1;
	}

	std::cout << "Python TCP connected!\n";



	// =====================================================
	// 2. UDP Server Socket
	//    Python sends metrics to this
	// =====================================================

	int udpSocket = socket(AF_INET, SOCK_DGRAM,0);

	if (udpSocket == -1) {
		perror("UDP Socket Failed");
		return 1;
	}

	sockaddr_in udpAddress{};

	udpAddress.sin_family = AF_INET;
	udpAddress.sin_addr.s_addr = INADDR_ANY;
	udpAddress.sin_port = htons(5001);

	if(bind(
		udpSocket,
		reinterpret_cast<sockaddr*>(&udpAddress),			sizeof(udpAddress)
	) == -1) {
		perror("UDP bind Failed");
		return 1;
	}

	// =====================================================
	// 3. TCP Client Socket
	//    C++ connects to Node.js
	// =====================================================
	
	int nodeTcpSocket = socket(AF_INET, SOCK_STREAM, 0);

	if (nodeTcpSocket == -1) {
		perror("Node TCP Socket Failed");
		return 1;
	}

	sockaddr_in nodeAddress{};

	nodeAddress.sin_family = AF_INET;
	nodeAddress.sin_port = htons(5002);

	// Node.js VM/server IP
	inet_pton(
		AF_INET,
		"127.0.0.1",
		&nodeAddress.sin_addr		
	);

	std::cout << "Connecting to Node.js...\n";

	if (connect(
		nodeTcpSocket,
		reinterpret_cast<sockaddr*>(&nodeAddress),			sizeof(nodeAddress)	
	) == -1) {
		perror("Node TCP connect failed");
		return 1;
	}

	std::cout << "Connected to Node.js!\n";


	// =====================================================
	// 4. Main Data Loop
	// =====================================================

	while (true){

		char udpBuffer[4096];

    		sockaddr_in udpClientAddress{};
    		socklen_t udpClientAddressLength =
        		sizeof(udpClientAddress);

    		ssize_t udpBytesReceived = recvfrom(
        		udpSocket,
        		udpBuffer,
        		sizeof(udpBuffer) - 1,
        		0,
        		reinterpret_cast<sockaddr*>(&udpClientAddress),
        		&udpClientAddressLength
    		);

    		if (udpBytesReceived == -1) {
        		std::cerr << "UDP recvfrom failed\n";
			break;
    		}

    		udpBuffer[udpBytesReceived] = '\0';
    		std::cout << "UDP received: " << udpBuffer << std::endl;

		std::string json = udpBuffer;
		json += "\n";

		ssize_t bytesSent = send(
			nodeTcpSocket,
			json.c_str(),
			json.size(),
			0
		);

		if (bytesSent == -1) {
			perror("TCP send to Node failed");
			return 1;
		}

		std::cout << "Forwarded " << bytesSent << " bytes sent to Node.js\n";
	}

	close(pythonTcpSocket);
	close(pythonTcpServer);
	close(udpSocket);
	close(nodeTcpSocket);

	return 0;
}
