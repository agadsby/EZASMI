//JCCLSTN JOB USER=%user%,PASSWORD=%pass%,REGION=8M
//*
//*
//* Example echo listener for MVS on JCC
//*
//MAIN  EXEC JCCCG
//COMPILE.SYSIN    DD *
#include <stdio.h>
#include <string.h>
#include <sockets.h>

#define PORT    8830

 /* 
  * send an ebcdic string converting to ascii before sending
  */
int 
send_ascii(int fd, char *ebuf, int len) {
    char *a;    // ascii outgoing data
    int rc;
    
    if (len == 0)
        len = strlen(ebuf);
        
    if ((a = (char *)malloc(len)) == NULL) {
        perror("send malloc failed");
        return -1;
    }
    strncpy(a, ebuf, len);

    rc = send(fd, ebcdic2ascii(a, len), len, 0);
    
    free(a);
    return rc;
}

int
recv_ascii(int fd, char *ebuf, int len) {
    char *a;    // ascii incoming data
    int rl;     // recv len
    
    // Clear buffer and read incoming data
    memset(ebuf, 0, len);

    if ((rl = recv(fd, ebuf, len - 1, 0)) <= 0)
        return rl;
    ebuf[rl] = '\0';    // guard
    
    ascii2ebcdic(ebuf, rl);   // NOTE: in-situ
    
    return rl; 
}

int 
main() {
    int server_fd, client_fd;
    struct sockaddr_in server_addr, client_addr;
    long addr_len = sizeof(client_addr);
    
    char *host_ip = "127.0.0.1";    // localhost
    int host_port = PORT;
    int loop = 1;   
    char buffer[1024];
    char wto_buf[132];
    
    /* Due to the way the MVS sockets work, old sockets may
     * be left open at the system level if a previous
     * creator dies. This loop will close ALL open sockets.
     */
    // int p;
    // for (p = 0; p < 1000; p++)
    //    closesocket(p);

    printf("Initializing port %d...\n", host_port);

    server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) {
        perror( "ERROR: Failed to create socket.");
        exit(-1);
    }

    // Set up the address structure
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(host_port);
    server_addr.sin_addr.s_addr = inet_addr(host_ip);
    
    if (bind(server_fd, (struct sockaddr *)&server_addr, 
                sizeof(server_addr)) < 0) {
        perror( "Bind failed");
        closesocket(server_fd);
        exit(-1);
    }

    if (listen(server_fd, 5) < 0) {
        perror("Listen failed");
        closesocket(server_fd);
        exit(-1);
    }

    sprintf(wto_buf, "JCC Server: Listening on port %d...", host_port);
    _write2op(wto_buf);
    printf("%s\n", wto_buf);
     
    // Accept loop
    while (loop) {
        int l;
        char *welcome = "Welcome to MVS\n";
        
        client_fd = accept(server_fd, 
                (struct sockaddr *)&client_addr, &addr_len);
        if (client_fd < 0) {
            perror( "Accept failed");
            continue;
        }

        printf( "Connection accepted!\n");
        send_ascii(client_fd, welcome, 0);
        while (1) {
            // Read incoming data
            l = recv_ascii(client_fd, buffer, sizeof(buffer) - 1);
            printf( "Received data: len %d = %s\n", l, buffer);
            
            if (l == 0)
                break;
            if (l < 0) {
                printf("Bad receive\n");
                break;
            }
            
            if (strncmp(buffer, "END", 3) == 0) {
                send_ascii(client_fd, "BYE\n", 0);
                loop = 0;   // Exit program
                break;
            }

            // Echo response back to client
            send_ascii(client_fd, buffer, 0);
        }
        closesocket(client_fd);
    }   // accept

    // Close the server listening socket
    closesocket(server_fd);
    _write2op("JCC server: exited");
    exit(0);
}
/*
@@
//
