NCAT     TITLE 'TCP/IP EZASMI -- Assembler XF Interface Demo'           00000100
*********************************************************************** 00000200
***                                                                 *** 00000300
*** Program:  NCAT                                                  *** 00000400
***                                                                 *** 00000500
*** Purpose:  Demonstrate using the EZASMI API to interface to      *** 00000600
***           the Hercules host's IP stack via the TCPIP (X'75')    *** 00000700
***           instruction.                                          *** 00000800
***                                                                 *** 00000900
***           NCAT communicates interactively with a network-cat    *** 00001000
***           tool like ncat, netcat, socat, or another NCAT        *** 00001100
***           instance. This can be used to perform interactive     *** 00001200
***           chats over the the internet, or even to run an        *** 00001300
***           interactive "telnet like" shell session.              *** 00001400
***                                                                 *** 00001500
***           A "telnet like" session requires a suitable shell to  *** 00001600
***           be used on the remote side, like for example bash     *** 00001700
***           on *i*x or powershell.exe on Windows systems. For     *** 00001800
***           example, on a Linux host, issuing the following       *** 00001900
***           command will provide a "telnet like" bash session:    *** 00002000
***                                                                 *** 00002100
***           ncat --exec "/bin/bash" -l 4466                       *** 00002200
***                                                                 *** 00002300
***           Issuing the NCAT command without arguments on TSO     *** 00002400
***           will then connect to this bash session, allowing to   *** 00002500
***           execute commands on the host directly from the TSO    *** 00002600
***           terminal.                                             *** 00002700
***                                                                 *** 00002800
*** Usage:    NCAT <options> <hostname> <port>                      *** 00002900
***                                                                 *** 00003000
***           NCAT operates in one of two modes: Connect mode and   *** 00003100
***           listen mode. In connect mode, NCAT works as a client. *** 00003200
***           In listen mode it is a server.                        *** 00003300
***                                                                 *** 00003400
***           - In connect mode, the <hostname> and <port>          *** 00003500
***             arguments tell where to connect to. <hostname> is   *** 00003600
***             required, and may be a hostname or an IP address.   *** 00003700
***             If <port> is supplied, it must be a decimal port    *** 00003800
***             number. If omitted, it defaults to 4466.            *** 00003900
***                                                                 *** 00004000
***           - In listen mode, <hostname> and <port> control the   *** 00004100
***             address the server will bind to. Both arguments are *** 00004200
***             optional. If <hostname> is omitted, it defaults to  *** 00004300
***             listening on all available addresses. If <port> is  *** 00004400
***             omitted, it defaults to 4466.                       *** 00004500
***                                                                 *** 00004600
***           Options                                               *** 00004700
***                                                                 *** 00004800
***           -l Bind and listen for incoming connections.          *** 00004900
***           -j Improved handling and readability for interactive  *** 00005000
***              chats. This option shouldn't be used with sessions *** 00005100
***              where the remote session partner is a shell style  *** 00005200
***              program.                                           *** 00005300
***                                                                 *** 00005400
***           Once the connection is established, data entered in   *** 00005500
***           the TSO session running NCAT will be transferred to   *** 00005600
***           the remote peer and data received from the remote     *** 00005700
***           peer will be displayed on the TSO terminal.           *** 00005800
***                                                                 *** 00005900
***           To terminate enter /* on the NCAT session, or send    *** 00006000
***           EOT from the remote peer, or close the connection at  *** 00006100
***           the remote peer. When NCAT is running as a server     *** 00006200
***           (i.e. the -l flag was specified) it is recommended    *** 00006300
***           to have the remote peer close its connection first,   *** 00006400
***           because otherwise the server port might enter a       *** 00006500
***           FIN_WAIT_x or a TIME_WAIT state, making it            *** 00006600
***           unavailable until the respective timeout(s)           *** 00006700
***           expire(s).                                            *** 00006800
***                                                                 *** 00006900
*** Note:     The NCAT program isn't designed to perform receive    *** 00007000
***           operations in quick succession, as, after each        *** 00007100
***           receive operation, the data received is written to    *** 00007200
***           the terminal before the next recv() call is           *** 00007300
***           performed. This is no (significant) restriction for   *** 00007400
***           interactive chatting or shell sessions. A peer        *** 00007500
***           program sending bulks of data in quick succession,    *** 00007600
***           however, can easily overrun NCAT.                     *** 00007700
***                                                                 *** 00007800
*** Updates:  2017/01/10 original implementation.                   *** 00007900
***           2017/01/22 command line processing using IKJPARSE.    *** 00008000
***                                                                 *** 00008100
*** Author:   Juergen Winkelmann, winkelmann@id.ethz.ch             *** 00008200
***                                                                 *** 00008300
*** Credits:  Thanks to Shelby Beach for providing an MVS 3.8j      *** 00008400
***           (Assembler XF) version of the EZASMI API.             *** 00008500
***                                                                 *** 00008600
*********************************************************************** 00008700
TERMSIZE EQU   4096             size of terminal input buffer           00008800
RECVSIZE EQU   81920            size of network receive buffer          00008900
NCAT     CSECT ,                start of program                        00009000
         STM   R14,R12,12(R13)  save registers                          00009100
         LR    R12,R15          establish module addressability         00009200
         LA    R11,1(,R12)      second base ..                          00009300
         LA    R11,4095(,R11)                 .. is base plus 4096      00009400
         USING NCAT,R12,R11     tell assembler of base                  00009500
         ST    R13,REGSMAIN+4   chain ..                                00009600
         LA    R2,REGSMAIN        .. the ..                             00009700
         ST    R2,8(R13)            .. save ..                          00009800
         LR    R13,R2                 .. areas                          00009900
*                                                                       00010000
* Parse command line                                                    00010100
*                                                                       00010200
         USING CPPL,R1          establish CPPL addressability           00010300
         MVC   PPLUPT,CPPLUPT   put in the UPT address from CPPL        00010400
         MVC   PPLECT,CPPLECT   put in the ECT address from CPPL        00010500
         MVC   PPLCBUF,CPPLCBUF put in the command buffer address       00010600
         DROP  R1               don't use CPPL any more                 00010700
         CALLTSSR EP=IKJPARS,MF=(E,PPLUPT) invoke parse                 00010800
         L     R2,ANSWER        get answer address                      00010900
         USING OPERANDS,R2      establish answer addressability         00011000
         USING OPERPDE,R3       establish PDE addressability            00011100
         SR    R9,R9            exit indicator for storage release      00011200
         LA    R3,O1            get address of first operand PDE        00011300
         LA    R10,4            operand count                           00011400
PROCESS  TM    OPERFLGS,X'80'   operand present?                        00011500
         BZ    NEXT             no -> process next operand              00011600
         L     R4,OPER          yes -> get operand address              00011700
         LH    R5,OPERLNG       get operand length                      00011800
         CHI   R5,2             at least two characters?                00011900
         BL    NOTFLAG          no -> can't be a flag                   00012000
         CLC   0(2,R4),=CL2'-j' chat mode requested?                    00012100
         BNE   *+12             no -> default to shell mode             00012200
         MVI   CHAT,X'01'       yes -> enable chat mode                 00012300
         B     NEXT             process next operand                    00012400
         CLC   0(2,R4),=CL2'-l' listen mode requested?                  00012500
         BNE   *+12             no -> default to connect mode           00012600
         MVI   LISTEN,X'01'     yes -> enable listen mode               00012700
         B     NEXT             process next operand                    00012800
         CLI   0(R4),C'-'       any other flag specified?               00012900
         BNE   NOTFLAG          no -> done with flags                   00013000
         LA    R9,1             signal exit after storage release       00013100
         STRING 'Invalid flag specified: ',((R4),(R5)),                +00013200
               INTO=PRTDATA     yes -> format error message ..          00013300
         TPUT  PRTDATA,L'PRTDATA       .. and tell user                 00013400
         B     PARSERLS         release parse storage and exit          00013500
NOTFLAG  LR    R6,R4            operand address                         00013600
         LR    R7,R5            operand length                          00013700
ISDIGIT  CLI   0(R6),C'0'       EBCDIC zero or greater?                 00013800
         BL    NOTPORT          no -> can't be a port number            00013900
         CLI   0(R6),C'9'       EBCDIC nine or lower?                   00014000
         BH    NOTPORT          no -> can't be a port number            00014100
         LA    R6,1(,R6)        increment and ..                        00014200
         BCT   R7,ISDIGIT                       .. check next character 00014300
         LR    R7,R5            number of digits entered as port number 00014400
         CHI   R7,5             more than five digits?                  00014500
         BNH   *+8              no -> use it                            00014600
         LA    R7,5             yes -> truncate to 5 digits             00014700
         ST    R7,PORTLEN       remember number of digits               00014800
         LA    R6,PORTR+5       right justify ..                        00014900
         SR    R6,R7              .. to 5 digits                        00015000
         BCTR  R7,0             decrement for EXecute                   00015100
         EX    R7,MOVEPRTR      get port number right justified         00015200
         PACK  PORTD(8),PORTRPCK(10) pack port number and ..            00015300
         CVB   R6,PORTD             .. convert to binary                00015400
         STH   R6,PORT          remember port number                    00015500
         B     NEXT             process next operand                    00015600
NOTPORT  LR    R7,R5            operand length                          00015700
         BCTR  R7,0             decrement for EXecute                   00015800
         EX    R7,MOVEHOST      get hostname or IP address              00015900
         ST    R5,NAMELEN       remember length                         00016000
NEXT     LA    R3,O2-O1(,R3)    address next operand                    00016100
         BCT   R10,PROCESS      process next operand                    00016200
         DROP  R2,R3            don't need PDEs any more                00016300
PARSERLS IKJRLSA (R2)           free storage that parse allocated       00016400
         LTR   R9,R9            exit signaled?                          00016500
         BNZ   ALLDONE          yes -> exit                             00016600
*                                                                       00016700
* Initialize EZASMI interface                                           00016800
*                                                                       00016900
         XC    EZASMTIE(TIELENTH),EZASMTIE clear EZASMI storage         00017000
         EZASMI TYPE=INITAPI,MAXSNO=MAXSNO,ERRNO=ERRCD,RETCODE=RETCD    00017100
*                                                                       00017200
* Try converting hostname/IP addr to network binary format using PTON   00017300
*                                                                       00017400
         EZASMI TYPE=PTON,AF='INET',SRCADDR=HOSTIN,SRCLEN=NAMELEN+2,   +00017500
               DSTADDR=IPADDR,ERRNO=ERRCD,RETCODE=RETCD                 00017600
         CLC   RETCD,=X'FFFFFFFF' conversion successful?                00017700
         BE    GETHBN           no, go treat input as a hostname        00017800
         LH    R6,NAMELEN+2     get length                              00017900
         STH   R6,ADDRLEN       remember for display                    00018000
         BCTR  R6,0             decrement for EXecute                   00018100
         LA    R3,HOSTIN        address of IP address                   00018200
         EX    R6,GETIP         copy IP address                         00018300
*                                                                       00018400
* Resolve IP address to hostname using GETHOSTBYADDR                    00018500
*                                                                       00018600
         EZASMI TYPE=GETHOSTBYADDR,HOSTADR=IPADDR,HOSTENT=HOSTENT,     +00018700
               RETCODE=RETCD                                            00018800
         L     R3,HOSTENT       get hostname address ..                 00018900
         L     R3,0(,R3)            .. from HOSTENT                     00019000
         LR    R6,R3            \                                       00019100
CHKLEN   CLI   0(R6),X'00'       \                                      00019200
         BE    HOSTEND            \ compute length                      00019300
         LA    R6,1(,R6)          / of hostname                         00019400
         B     CHKLEN            /                                      00019500
HOSTEND  SR    R6,R3            /                                       00019600
         ST    R6,NAMELEN       remember length                         00019700
         BCTR  R6,0             decrement for EXecute                   00019800
         EX    R6,GETHOST       copy hostname                           00019900
         B     SOCKET           create socket                           00020000
*                                                                       00020100
* Resolve hostname to IP address using GETHOSTBYNAME                    00020200
*                                                                       00020300
GETHBN   L     R6,NAMELEN       get length                              00020400
         BCTR  R6,0             decrement for EXecute                   00020500
         LA    R3,HOSTIN        hostname address                        00020600
         EX    R6,GETHOST       copy hostname                           00020700
         EZASMI TYPE=GETHOSTBYNAME,NAMELEN=NAMELEN,NAME=HOSTNAME,      +00020800
               HOSTENT=HOSTENT,RETCODE=RETCD                            00020900
         L     R3,HOSTENT       \                                       00021000
         L     R3,16(,R3)        \                                      00021100
         L     R3,0(,R3)          > get first IP address from HOSTENT   00021200
         L     R3,0(,R3)         /                                      00021300
         ST    R3,IPADDR        /                                       00021400
*                                                                       00021500
* Convert IP address to dotted decimal format using NTOP                00021600
*                                                                       00021700
         EZASMI TYPE=NTOP,AF='INET',SRCADDR=IPADDR,DSTADDR=ADDR,       +00021800
               DSTLEN=ADDRLEN,ERRNO=ERRCD,RETCODE=RETCD                 00021900
*                                                                       00022000
* Create socket                                                         00022100
*                                                                       00022200
SOCKET   EZASMI TYPE=SOCKET,AF='INET',SOCTYPE='STREAM',                +00022300
               ERRNO=ERRCD,RETCODE=SOCKDESC                             00022400
         LT    R3,SOCKDESC      socket created?                         00022500
         BNL   MODE             yes -> continue                         00022600
         TPUT  MNOSOCK,L'MNOSOCK \ no -> tell user..                    00022700
         B     RETNSOCK          /                  .. and exit         00022800
*                                                                       00022900
* listen or connect                                                     00023000
*                                                                       00023100
MODE     CLI   LISTEN,X'01'     listen mode requested?                  00023200
         BNE   CONNECT          no -> go connect                        00023300
*                                                                       00023400
* Listen                                                                00023500
*                                                                       00023600
         LH    R6,ADDRLEN       length of dotted decimal IP address     00023700
         ICM   R5,B'1111',NAMELEN length of hostname                    00023800
         BNZ   *+16             not zero -> continue                    00023900
         MVI   HOSTNAME,C'*'    \                                       00024000
         LA    R5,1              > else -> set hostname to asterisk     00024100
         ST    R5,NAMELEN       /                                       00024200
         STRING 'Listening at ',(HOSTNAME,(R5)),' (',(ADDR,(R6)),')',  +00024300
               ' port ',(PORT,H,L),INTO=PRTDATA format message          00024400
BIND     EZASMI TYPE=BIND,S=SOCKDESC+2,NAME=SOCKADDR,                  +00024500
               ERRNO=ERRCD,RETCODE=RETCD                                00024600
         LT    R3,RETCD         socket bound?                           00024700
         BNL   BOUND            yes -> continue                         00024800
         CLFHSI ERRCD,EADDINUS  no -> address already in use?           00024900
         BE    RETRYBND               yes -> wait and retry             00025000
         TPUT  MNOBIND,L'MNOBIND      no -> tell user..                 00025100
         B     RETURN           exit                                    00025200
RETRYBND TPUT  MINUSE,L'MINUSE  tell user                               00025300
         STIMER WAIT,BINTVL=WAIT1000 wait ten seconds                   00025400
         B     BIND             retry                                   00025500
BOUND    EZASMI TYPE=LISTEN,S=SOCKDESC+2,BACKLOG='1',                  +00025600
               ERRNO=ERRCD,RETCODE=RETCD                                00025700
         LT    R3,RETCD         listening?                              00025800
         BNL   LISTNING         yes -> continue                         00025900
         TPUT  MNOLIST,L'MNOLIST no -> tell user..                      00026000
         B     RETURN           exit                                    00026100
LISTNING TPUT  PRTDATA,L'PRTDATA listening, tell user                   00026200
         EZASMI TYPE=ACCEPT,S=SOCKDESC+2,NAME=SOCKADDR,                +00026300
               ERRNO=ERRCD,RETCODE=NEWSOCK                              00026400
         LT    R3,NEWSOCK       socket connected?                       00026500
         BNL   ACCEPTED         yes -> continue                         00026600
         TPUT  MNOACPT,L'MNOACPT no -> tell user..                      00026700
         B     RETURN           exit                                    00026800
ACCEPTED EZASMI TYPE=CLOSE,S=SOCKDESC+2,ERRNO=ERRCD,RETCODE=RETCD       00026900
         MVC   SOCKDESC,NEWSOCK                                         00027000
         B     CONECTED         connection established                  00027100
*                                                                       00027200
* Connect                                                               00027300
*                                                                       00027400
CONNECT  CLC   IPADDR,=XL4'00000000' address zero?                      00027500
         BNE   ADDROK           no -> continue                          00027600
         MVC   IPADDR,=XL4'7F000001'  \                                 00027700
         MVC   ADDR,=CL9'127.0.0.1'    \                                00027800
         MVC   HOSTNAME,=CL9'localhost' \ yes -> connect to             00027900
         LA    R6,9                     /        localhost (127.0.0.1)  00028000
         STH   R6,ADDRLEN              /                                00028100
         ST    R6,NAMELEN             /                                 00028200
ADDROK   EZASMI TYPE=CONNECT,S=SOCKDESC+2,NAME=SOCKADDR,               +00028300
               ERRNO=ERRCD,RETCODE=RETCD                                00028400
         LT    R3,RETCD         socket connected?                       00028500
         BNL   CONECTED         yes -> continue                         00028600
         TPUT  MNOCONN,L'MNOCONN no -> tell user..                      00028700
         B     RETURN           exit                                    00028800
*                                                                       00028900
* Identify peer                                                         00029000
*                                                                       00029100
CONECTED EZASMI TYPE=GETPEERNAME,S=SOCKDESC+2,NAME=SOCKADDR,           +00029200
               ERRNO=ERRCD,RETCODE=RETCD                                00029300
         LT    R3,RETCD         GETPEERNAME successful?                 00029400
         BNL   GOTPEER          yes -> continue                         00029500
         TPUT  MNOPEER,L'MNOPEER no -> tell user..                      00029600
         B     RETURN           exit                                    00029700
*                                                                       00029800
* Resolve peer IP address to hostname using GETHOSTBYADDR               00029900
*                                                                       00030000
GOTPEER  EZASMI TYPE=GETHOSTBYADDR,HOSTADR=IPADDR,HOSTENT=HOSTENT,     +00030100
               RETCODE=RETCD                                            00030200
         L     R3,HOSTENT       get hostname address ..                 00030300
         L     R3,0(,R3)            .. from HOSTENT                     00030400
         LR    R6,R3            \                                       00030500
CHKLENP  CLI   0(R6),X'00'       \                                      00030600
         BE    HOSTENDP           \ compute length                      00030700
         LA    R6,1(,R6)          / of hostname                         00030800
         B     CHKLENP           /                                      00030900
HOSTENDP SR    R6,R3            /                                       00031000
         ST    R6,NAMELEN       remember length                         00031100
         BCTR  R6,0             decrement for EXecute                   00031200
         EX    R6,GETHOST       copy hostname                           00031300
*                                                                       00031400
* Convert peer IP address to dotted decimal format using NTOP           00031500
*                                                                       00031600
         LA    R6,L'ADDR        reinitialize length ..                  00031700
         STH    R6,ADDRLEN                            .. of IP address  00031800
         EZASMI TYPE=NTOP,AF='INET',SRCADDR=IPADDR,DSTADDR=ADDR,       +00031900
               DSTLEN=ADDRLEN,ERRNO=ERRCD,RETCODE=RETCD                 00032000
*                                                                       00032100
* Display connection message                                            00032200
*                                                                       00032300
         LH    R6,ADDRLEN       length of dotted decimal IP address     00032400
         L     R5,NAMELEN       length of hostname                      00032500
         LA    R4,MFROM         indicate server mode                    00032600
         LA    R3,L'MFROM       length of server mode message           00032700
         LT    R2,NEWSOCK       did we get a new socket?                00032800
         BNL   *+12             yes -> continue                         00032900
         LA    R4,MTO           indicate client mode                    00033000
         LA    R3,L'MTO         length of client mode message           00033100
         STRING ((R4),(R3)),(HOSTNAME,(R5)),' (',(ADDR,(R6)),')',      +00033200
               ' port ',(PORT,H,L),INTO=PRTDATA format message          00033300
         TPUT  PRTDATA,L'PRTDATA display message                        00033400
*                                                                       00033500
* Get storage for SEND/RECV buffers                                     00033600
*                                                                       00033700
         GETMAIN R,LV=TERMSIZE  get terminal input buffer               00033800
         ST    R1,TERMBUFA      remember address                        00033900
         GETMAIN R,LV=RECVSIZE  get network input buffer                00034000
         ST    R1,NETIN         remember address                        00034100
*                                                                       00034200
* Use linefeed character matching the installation's conversion tables  00034300
*                                                                       00034400
         LA    R3,1             convert ASCII linefeed ..               00034500
         ST    R3,NETLENR                .. to EBCDIC (LF or NL) and .. 00034600
         CALL  EZACIC05,(LF1+4,NETLENR),VL .. put it into ..            00034700
         MVC   LF2+1(1),LF1+4                .. immediate instructions  00034800
*                                                                       00034900
* Start terminal input task                                             00035000
*                                                                       00035100
         MVI   RUNNING,X'01'    indicate dialog is running              00035200
         IDENTIFY EP=NCATRMIN,ENTRY=GETLINE define entry point          00035300
         ATTACH EP=NCATRMIN     attach task                             00035400
         ST    R1,TERMTCB       remember TCB                            00035500
*                                                                       00035600
* While RUNNING is X'01' and no RECV error occurs:                      00035700
* Read network input from peer and display it on terminal               00035800
*                                                                       00035900
         TPUT  UNLOCK,5,CONTROL unlock keyboard                         00036000
READNET  CLI   RUNNING,X'01'    dialog running?                         00036100
         BNE   RETURN           no -> exit                              00036200
         MVC   NETLENR,NETINL   yes -> get length of network buffer     00036300
         EZASMI TYPE=RECV,S=SOCKDESC+2,NBYTE=NETLENR,BUF=*NETIN,       +00036400
               ERRNO=ERRCD,RETCODE=RETCD                                00036500
         LT    R3,RETCD         successfully received?                  00036600
         BNL   RECVOK           yes -> continue                         00036700
         CLFHSI ERRCD,ENOTSOCK  no -> socket already closed?            00036800
         BE    RETNSOCK               yes -> exit without error msg     00036900
         CLFHSI ERRCD,ECANCELD        no -> RECV cancelled?             00037000
         BE    RETNSOCK                     yes -> exit without msg     00037100
         TPUT  MNORECV,L'MNORECV            no -> tell user..           00037200
         B     RETURN           exit                                    00037300
RECVOK   BH    CONVERT          convert if at least one byte received   00037400
         TPUT  EOD,L'EOD        nothing received: Tell user ..          00037500
         B     RETURN              .. and exit                          00037600
CONVERT  ST    R3,NETLENR       store length for use by EZACIC05        00037700
         L     R4,NETIN         address data                            00037800
         CALL  EZACIC05,((R4),NETLENR),VL convert to EBCDIC             00037900
         CLI   0(R4),55         EOT character received?                 00038000
         BNE   CHKCHATR         no -> check for dialog type             00038100
         TPUT  EOT,L'EOT        yes -> Tell user ..                     00038200
         B     RETURN              .. and exit                          00038300
CHKCHATR CLI   CHAT,X'01'       chat mode?                              00038400
         BNE   DISPLAY          no -> display received data             00038500
         TPUT  NEWLINE,1,ASIS   yes -> avoid overtyping of input        00038600
*                                                                       00038700
* Split data at LF or CRLF and display line by line on terminal         00038800
*                                                                       00038900
DISPLAY  LR    R5,R4            initialize compare pointer              00039000
         SR    R8,R8            initialize to zero for CLIJ             00039100
NEXTCHAR IC    R8,0(,R5)        load character to check                 00039200
LF1      CLIJE R8,X'0A',DISPLINE if linefeed -> display line            00039300
         LA    R5,1(,R5)                else -> point to next character 00039400
         B     NEXTCHAR         check next character                    00039500
DISPLINE MVI   0(R5),X'15'      replace linefeed with newline           00039600
         LR    R7,R4            remember begin of current output line   00039700
         LA    R6,1(,R5)        remember begin of next output line      00039800
         BCTR  R5,0             last character of output line           00039900
         IC    R8,0(,R5)        load character to check                 00040000
         CLIJNE R8,X'0D',LASTCHAR if not CR -> go ahead                 00040100
         BCTR  R5,0                    else -> decrement                00040200
LASTCHAR LA    R5,1(,R5)        compute ...                             00040300
         SR    R5,R4                       ... length of output line    00040400
         TPUT  (R7),(R5)        display on terminal                     00040500
         LR    R5,R6            compute ..                              00040600
         SR    R5,R7                      .. residual ..                00040700
         SR    R3,R5                                    .. count        00040800
         LR    R4,R6            initialize ..                           00040900
         LR    R5,R6                         .. next line               00041000
         BNZ   NEXTCHAR         more data -> check it                   00041100
         TPUT  NEWLINE,1,ASIS        else -> newline ..                 00041200
         TPUT  PROMPT,1,ASIS                       .. prompt            00041300
         TPUT  UNLOCK,5,CONTROL                  .. and unlock keyboard 00041400
         B     READNET          continue reading socket                 00041500
*                                                                       00041600
* Exit processing                                                       00041700
*                                                                       00041800
RETURN   EZASMI TYPE=CLOSE,S=SOCKDESC+2,ERRNO=ERRCD,RETCODE=RETCD       00041900
RETNSOCK MVI   RUNNING,X'02'    terminate terminal task                 00042000
         STIMER WAIT,BINTVL=WAIT50 wait half a second                   00042100
         EZASMI TYPE=TERMAPI    terminate API                           00042200
         CLI   RUNNING,X'00'    never running?                          00042300
         BE    DONE             yes -> just exit                        00042400
         STIMER WAIT,BINTVL=WAIT50 wait half a second                   00042500
         CLI   RUNNING,X'FF'    terminal subtask already terminated?    00042600
         BE    DONE             yes -> we are done                      00042700
         STIMER WAIT,BINTVL=WAIT50 no -> wait half a second and exit    00042800
*                                                                       00042900
* Release SEND/RECV buffers                                             00043000
*                                                                       00043100
DONE     ICM   R1,B'1111',TERMBUFA send buffer address                  00043200
         BZ    RELNETIN         skip release if never allocated         00043300
         FREEMAIN R,LV=TERMSIZE,A=(R1) release send buffer              00043400
RELNETIN ICM   R1,B'1111',NETIN receive buffer address                  00043500
         BZ    ALLDONE          skip release if never allocated         00043600
         FREEMAIN R,LV=RECVSIZE,A=(R1) release receive buffer           00043700
*                                                                       00043800
* That's all folks!                                                     00043900
*                                                                       00044000
ALLDONE  L     R13,4(,R13)      caller's save area pointer              00044100
         RETURN (14,12),RC=0    restore registers and return            00044200
*                                                                       00044300
* Read terminal input and send it to peer                               00044400
*                                                                       00044500
         DROP  R11,R12          avoid confusion                         00044600
MAINLEN  DC    Y(GETLINE-NCAT)  length of mainline code                 00044700
GETLINE  STM   R14,R12,12(R13)  save registers                          00044800
         USING GETLINE,R15      tell assembler of temporary base        00044900
         ST    R13,REGSTGET+4   chain ..                                00045000
         LA    R2,REGSTGET        .. the ..                             00045100
         ST    R2,8(R13)            .. save ..                          00045200
         LR    R13,R2                 .. areas                          00045300
         LA    R5,GETLINE       address ..                              00045400
         BCTR  R5,0                      .. length of ..                00045500
         BCTR  R5,0                                    .. mainline code 00045600
         DROP  R15              temporary base no longer needed         00045700
         LR    R12,R15          entry address minus mainline ..         00045800
         SH    R12,0(,R5)                    .. length is mainline base 00045900
         LA    R11,1(,R12)      second base ..                          00046000
         LA    R11,4095(,R11)                 .. is base plus 4096      00046100
         USING NCAT,R12,R11     tell assembler to use mainline bases    00046200
*                                                                       00046300
* Loop while RUNNING is X'01' and no SEND error occurs                  00046400
*                                                                       00046500
         TPUT  NEWLINE,1,ASIS   initial newline and ..                  00046600
         TPUT  PROMPT,1,ASIS                          .. prompt         00046700
         B     READNEXT         unlock keyboard and read from terminal  00046800
READTERM CLI   RUNNING,X'01'    dialog running?                         00046900
         BNE   STOPTRMI         no -> stop this task                    00047000
         L     R9,TERMBUFA      address of terminal buffer              00047100
         L     R8,TERMBUFS      size of terminal buffer                 00047200
         TGET  (R9),(R8),,NOWAIT yes -> read input from terminal        00047300
         CFI   R15,4            input available?                        00047400
         BNE   GOTINPUT         yes -> check for EOD                    00047500
         STIMER WAIT,BINTVL=WAIT25 no -> wait quarter second ..         00047600
         B     READTERM                  .. and try again               00047700
GOTINPUT CLHHSI 0(R9),C'/*'     EOD?                                    00047800
         BNE   SENDIT           no -> send it                           00047900
         TPUT  EOD,L'EOD        yes -> Tell user ..                     00048000
         B     STOPTRMI                .. and stop this task            00048100
SENDIT   LA    R3,1(,R1)        increment length for newline            00048200
         ST    R3,NETLENS       store length for use by EZACIC04/SEND   00048300
         LA    R2,0(R1,R9)      terminal input                          00048400
LF2      MVI   0(R2),*-*        insert linefeed character               00048500
         L     R4,TERMBUFA      address data                            00048600
         CALL  EZACIC04,((R4),NETLENS),VL convert to ASCII              00048700
         EZASMI TYPE=SEND,S=SOCKDESC+2,NBYTE=NETLENS,BUF=*TERMBUFA,    +00048800
               ERRNO=ERRCDS,RETCODE=RETCDS,MF=(E,TRMPLIST)              00048900
         LT    R3,RETCDS        successfully sent?                      00049000
         BNL   CHKCHATS         yes -> check for dialog type            00049100
         TPUT  MNOSEND,L'MNOSEND no -> tell user..                      00049200
         B     STOPTRMI                .. and stop this task            00049300
CHKCHATS CLI   CHAT,X'01'       chat mode?                              00049400
         BNE   READNEXT         no -> read next line                    00049500
         TPUT  NEWLINE,1,ASIS   yes -> newline and ..                   00049600
         TPUT  PROMPT,1,ASIS                         .. prompt          00049700
READNEXT TPUT  UNLOCK,5,CONTROL unlock keyboard                         00049800
         B     READTERM         start over                              00049900
*                                                                       00050000
* Close connection and exit terminal input handler                      00050100
*                                                                       00050200
STOPTRMI CLI   RUNNING,X'02'    stopped by main task?                   00050300
         BE    OUT              yes -> exit, no -> close, then exit     00050400
         EZASMI TYPE=CLOSE,S=SOCKDESC+2,ERRNO=ERRCDS,RETCODE=RETCDS,   +00050500
               MF=(E,TRMPLIST)                                          00050600
         STIMER WAIT,BINTVL=WAIT25 wait quarter second                  00050700
OUT      MVI   RUNNING,X'FF'    indicate we are out                     00050800
         L     R13,4(,R13)      caller's save area pointer              00050900
         RETURN (14,12),RC=0    restore registers and return            00051000
*                                                                       00051100
* EXecuted instructions                                                 00051200
*                                                                       00051300
GETHOST  MVC   HOSTNAME(*-*),0(R3) copy hostname                        00051400
GETIP    MVC   ADDR(*-*),0(R3)  copy IP address                         00051500
MOVEPRTR MVC   0(*-*,R6),0(R4)  right justify port number               00051600
MOVEHOST MVC   HOSTIN(*-*),0(R4) get hostname/IP addr from command line 00051700
*                                                                       00051800
* Data areas                                                            00051900
*                                                                       00052000
REGSMAIN DS    18F              main task save area                     00052100
REGSTGET DS    18F              terminal input task save area           00052200
ERRCD    DC    A(*-*)           error code main task                    00052300
ERRCDS   DC    A(*-*)           error code terminal input task          00052400
RETCD    DC    A(*-*)           return code main task                   00052500
RETCDS   DC    A(*-*)           return code terminal input task         00052600
MAXSNO   DC    A(*-*)           highest socket number assigned          00052700
SOCKDESC DC    F'-1'            socket descriptor                       00052800
SOCKADDR DS    0F               sockaddr structure                      00052900
AF@INET  DC    H'2'             address family                          00053000
PORT     DC    H'4466'          port to connect to or listen at         00053100
IPADDR   DC    F'0'             INET address (netid)                    00053200
         DC    XL8'00'          Reserved area not used                  00053300
NEWSOCK  DC    F'-1'            new socket descriptor from ACCEPT       00053400
HOSTENT  DC    F'0'             address of HOSTENT structure goes here  00053500
PORTD    DC    D'0'             decimal port number                     00053600
MNOSOCK  DC    C'SOCKET failed'                                         00053700
MNOCLOS  DC    C'CLOSE failed'                                          00053800
MNOCONN  DC    C'CONNECT failed'                                        00053900
MNOBIND  DC    C'BIND failed'                                           00054000
MINUSE   DC    C'BIND: Address in use, retrying in 10 seconds...'       00054100
MNOLIST  DC    C'LISTEN failed'                                         00054200
MNOACPT  DC    C'ACCEPT failed'                                         00054300
MNOPEER  DC    C'GETPEERNAME failed'                                    00054400
MNOSEND  DC    C'SEND failed'                                           00054500
MNORECV  DC    C'RECV failed'                                           00054600
MFROM    DC    C'Connection from '                                      00054700
MTO      DC    C'Connected to '                                         00054800
EOD      DC    C'Terminating at EOD'                                    00054900
EOT      DC    C'Terminating at EOT'                                    00055000
NEWLINE  DC    X'15'            EBCDIC newline character                00055100
PROMPT   DC    C'$'             prompt character                        00055200
CHAT     DC    X'00'            dialog type: chat = 1, shell = 0        00055300
LISTEN   DC    X'00'            mode: listen = 1, connect = 0           00055400
RUNNING  DC    X'00'            status indicator                        00055500
UNLOCK   DC    X'27F1C30013'    control datastream to unlock keyboard   00055600
ADDR     DC    CL15' '          dotted decimal IP address               00055700
ADDRLEN  DC    Y(L'ADDR)        length of dotted decimal IP address     00055800
HOSTNAME DC    CL256' '         Hostname                                00055900
TERMTCB  DS    F                TCB of terminal input subtask           00056000
WAIT25   DC    F'25'            quarter of a second                     00056100
WAIT50   DC    F'50'            half a second                           00056200
WAIT1000 DC    F'1000'          ten seconds                             00056300
NAMELEN  DC    F'0'             length of hostname                      00056400
PORTLEN  DC    F'0'             length of port number                   00056500
NETLENR  DS    F                number of bytes for RECV/EZACIC05       00056600
NETLENS  DS    F                number of bytes for SEND/EZACIC04       00056700
PORTRPCK DC    CL5' '           port right justified for PACK           00056800
PORTR    DC    CL5' '           port right justified                    00056900
PRTDATA  DC    CL78' '          formatted result                        00057000
HOSTIN   DC    CL50' '          hostname or IP addr from command line   00057100
TERMBUFA DC    F'0'             address of terminal input buffer        00057200
TERMBUFS DC    A(TERMSIZE)      size of terminal input buffer           00057300
NETIN    DC    F'0'             address of network input buffer         00057400
NETINL   DC    A(RECVSIZE)      size of network input buffer            00057500
ANSWER   DS    F                IKJPARSE answer place                   00057600
PPLUPT   DS    A                address of UPT                          00057700
PPLECT   DS    A                address of ECT                          00057800
PPLECB   DC    A(ECB)           address of CP's ECB                     00057900
PPLPCL   DC    A(PCLDEFS)       address of PCL                          00058000
PPLANS   DC    A(ANSWER)        address of answer place                 00058100
PPLCBUF  DS    A                address of command buffer               00058200
PPLUWA   DC    A(0)             address of user work area               00058300
ECB      DC    F'0'             CP's event control block                00058400
PCLDEFS  IKJPARM  DSECT=OPERANDS begin of operand descriptions          00058500
O1       IKJIDENT 'Operand 1',ASIS,CHAR                                 00058600
O2       IKJIDENT 'Operand 2',ASIS,CHAR                                 00058700
O3       IKJIDENT 'Operand 3',ASIS,CHAR                                 00058800
O4       IKJIDENT 'Operand 4',ASIS,CHAR                                 00058900
         IKJENDP ,              end of operand descriptions             00059000
TRMPLIST EZASMI MF=L            EZASMI parameter list for terminal task 00059100
         EZASMI TYPE=TASK,STORAGE=CSECT EZASMI task storage             00059200
         LTORG                  literals go here                        00059300
         STRING GENERATE        STRING storage and code goes here       00059400
ENOTSOCK EQU   38               socket already closed on RECV           00059500
EADDINUS EQU   48               address already in use                  00059600
ECANCELD EQU   1009             RECV cancelled, EIBMCANCELLED           00059700
OPERPDE  DSECT ,                PDE mapping for a positional operand    00059800
OPER     DS    F                address of operand value                00059900
OPERLNG  DS    H                length of operand value                 00060000
OPERFLGS DS    CL1              flags byte                              00060100
         DS    CL1              reserved                                00060200
         IKJCPPL ,              command processor parameter list        00060300
         CVT   DSECT=YES        CVT mapping needed for CALLTSSR         00060400
         YREGS ,                register equates                        00060500
         END   NCAT             end of program                          00060600
