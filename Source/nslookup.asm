NSLOOKUP TITLE 'TCP/IP EZASMI -- Assembler XF Interface Demo'           00010000
*********************************************************************** 00020000
***                                                                 *** 00030000
*** Program:  NSLOOKUP                                              *** 00040000
***                                                                 *** 00050000
*** Purpose:  Demonstrate using the EZASMI API to interface to      *** 00060000
***           the Hercules host's IP stack via the TCPIP (X'75')    *** 00070000
***           instruction.                                          *** 00080000
***                                                                 *** 00090000
*** Usage:    Run from the TSO READY prompt.                        *** 00100000
***                                                                 *** 00110000
*** Function: - read hostname or IP address from terminal.          *** 00120000
***                                                                 *** 00130000
***           - resolve depending on type of input:                 *** 00140000
***                                                                 *** 00150000
***             o Hostname:   Call GETHOSTBYNAME and NTOP           *** 00160000
***             o IP address: Call PTON and GETHOSTBYADDR           *** 00170000
***                                                                 *** 00180000
***           - display result on terminal.                         *** 00190000
***                                                                 *** 00200000
*** Updates:  2016/12/31 original implementation.                   *** 00210000
***                                                                 *** 00220000
*** Author:   Juergen Winkelmann, winkelmann@id.ethz.ch             *** 00230000
***                                                                 *** 00240000
*** Credits:  Thanks to Shelby Beach for providing an MVS 3.8j      *** 00250000
***           (Assembler XF) version of the EZASMI API.             *** 00260000
***                                                                 *** 00270000
*********************************************************************** 00280000
NSLOOKUP CSECT ,                start of program                        00290000
         STM   R14,R12,12(R13)  save registers                          00300000
         LR    R12,R15          establish module addressability         00310000
         USING NSLOOKUP,R12     tell assembler of base                  00320000
         ST    R13,REGSAVE+4    chain ..                                00330000
         LA    R2,REGSAVE         .. the ..                             00340000
         ST    R2,8(R13)            .. save ..                          00350000
         LR    R13,R2                 .. areas                          00360000
*                                                                       00370000
* Get input                                                             00380000
*                                                                       00390000
         TPUT  BANNER,BANNERL,ASIS prompt for hostname or IP address    00400000
         TGET  INPUT,L'INPUT    read input from terminal                00410000
         LR    R5,R1            remember length ..                      00420000
         ST    R5,NAMELEN                          .. of input          00430000
*                                                                       00440000
* Initialize EZASMI interface                                           00450000
*                                                                       00460000
         EZASMI TYPE=INITAPI,MAXSNO=MAXSNO,ERRNO=ERRCD,RETCODE=RETCD    00470000
*                                                                       00480000
* Try converting input to network binary format using PTON              00490000
*                                                                       00500000
         EZASMI TYPE=PTON,AF='INET',SRCADDR=INPUT,SRCLEN=NAMELEN+2,    +00510000
               DSTADDR=IPADDR,ERRNO=ERRCD,RETCODE=RETCD                 00520000
         CLC   RETCD,=X'FFFFFFFF' conversion successful?                00530000
         BE    GETHBN           no, go treat input as a hostname        00540000
*                                                                       00550000
* Resolve IP address to hostname using GETHOSTBYADDR                    00560000
*                                                                       00570000
         EZASMI TYPE=GETHOSTBYADDR,HOSTADR=IPADDR,HOSTENT=HOSTENT,     +00580000
               RETCODE=RETCD                                            00590000
         L     R3,HOSTENT       get hostname address ..                 00600000
         L     R3,0(,R3)            .. from HOSTENT                     00610000
         LR    R6,R3            \                                       00620000
CHKLEN   CLI   0(R6),X'00'       \                                      00630000
         BE    HOSTEND            \ compute length                      00640000
         LA    R6,1(,R6)          / of hostname                         00650000
         B     CHKLEN            /                                      00660000
HOSTEND  SR    R6,R3            /                                       00670000
         STRING 'IP address: ',(INPUT,(R5)),', Hostname: ',((R3),(R6)),+00680000
               INTO=PRTDATA     format result                           00690000
         B     DISPLAY          display result on terminal              00700000
*                                                                       00710000
* Resolve hostname to IP address using GETHOSTBYNAME                    00720000
*                                                                       00730000
GETHBN   DS    0H               come here if input isn't an IP address  00740000
         EZASMI TYPE=GETHOSTBYNAME,NAMELEN=NAMELEN,NAME=INPUT,         +00750000
               HOSTENT=HOSTENT,RETCODE=RETCD                            00760000
         L     R3,HOSTENT       \                                       00770000
         L     R3,16(,R3)        \                                      00780000
         L     R3,0(,R3)          > get first IP address from HOSTENT   00790000
         L     R3,0(,R3)         /                                      00800000
         ST    R3,IPADDR        /                                       00810000
*                                                                       00820000
* Convert IP address to dotted decimal format using NTOP                00830000
*                                                                       00840000
         EZASMI TYPE=NTOP,AF='INET',SRCADDR=IPADDR,DSTADDR=ADDR,       +00850000
               DSTLEN=ADDRLEN,ERRNO=ERRCD,RETCODE=RETCD                 00860000
         LH    R6,ADDRLEN       length of converted address             00870000
         STRING 'Hostname: ',(INPUT,(R5)),', IP address: ',(ADDR,(R6)),+00880000
               INTO=PRTDATA     format result                           00890000
*                                                                       00900000
* Display result, terminate EZASMI interface and return                 00910000
*                                                                       00920000
DISPLAY  TPUT  PRTDATA,L'PRTDATA display result                         00930000
         EZASMI TYPE=TERMAPI    terminate API                           00940000
         L     R13,4(,R13)      caller's save area pointer              00950000
         RETURN (14,12),RC=0    restore registers and return            00960000
*                                                                       00970000
* Data areas                                                            00980000
*                                                                       00990000
REGSAVE  DS    18F              save area                               01000000
ERRCD    DC    A(*-*)           error code                              01010000
RETCD    DC    A(*-*)           return code                             01020000
MAXSNO   DC    A(*-*)           highest socket number assigned          01030000
NAMELEN  DS    F                length of hostname                      01040000
IPADDR   DS    F                IP address in network binary format     01050000
HOSTENT  DS    F                address of HOSTENT structure goes here  01060000
BANNER   DC    C'MVS 3.8j NSLOOKUP - enter hostname or IP address:'     01070000
BANNERL  EQU   *-BANNER         length of banner                        01080000
ADDR     DC    CL15' '          dotted decimal IP address               01090000
ADDRLEN  DC    AL2(L'ADDR)      length of dotted decimal IP address     01100000
INPUT    DC    CL60' '          input from terminal goes here           01110000
PRTDATA  DC    CL78' '          formated result                         01120000
         EZASMI TYPE=TASK,STORAGE=CSECT EZASMI storage goes here        01130000
         STRING GENERATE        STRING storage and code goes here       01140000
         YREGS ,                register equates                        01150000
         END   NSLOOKUP         end of program                          01160000
