//EZASMI   JOB USER=%user%,PASSWORD=%pass%,REGION=2048K
//******************************************************************/
//*                                                                */
//* This JCL will install the EZASOH03 load module into            */
//* SYS2.LINKLIB, and the set of EZASMI macros into SYS2.MACLIB.   */
//* The optional source material will be copied to SYS2.ASM.       */
//*                                                                */
//******************************************************************/
//*
//*
//EZASOH03 EXEC PGM=IEBCOPY
//******************************************************************/
//*                                                                */
//* This step will copy the EZASOH03 load module into SYS2.LINKLIB.*/
//* If you choose to use a different load module library, modify   */
//* the LOADLIB DD accordingly.                                    */
//*                                                                */
//******************************************************************/
//TAPE     DD   DSN=EZASOH03,UNIT=TAPE,VOL=(,RETAIN,SER=EZASMI),
//  DISP=(,KEEP)
//LOADLIB  DD   DSN=SYS2.LINKLIB,DISP=OLD
//SYSPRINT DD   SYSOUT=*
//SYSIN    DD   *
 COPY I=((TAPE,R)),O=LOADLIB
/*
//*
//*
//EZASMI   EXEC PGM=IEBCOPY
//******************************************************************/
//*                                                                */
//* This step will copy the EZASMI macro set into SYS2.MACLIB.     */
//* If you choose to use a different macro library, modify the     */
//* MACLIB DD accordingly.                                         */
//*                                                                */
//******************************************************************/
//TAPE     DD   DSN=EZASMI,UNIT=TAPE,VOL=(,RETAIN,SER=EZASMI),
//  LABEL=2,DISP=(,KEEP)
//MACLIB   DD   DSN=SYS2.MACLIB,DISP=OLD
//SYSPRINT DD   SYSOUT=*
//SYSIN    DD   *
 COPY I=((TAPE,R)),O=MACLIB
/*
//*
//*
//OPTSRCE  EXEC PGM=IEBCOPY
//******************************************************************/
//*                                                                */
//* This step will copy the optional source into SYS2.ASM. You may */
//* skip this step altogether, modify which modules are copied, or */
//* change the library to which the modules are copied (SOURCE DD).*/
//*                                                                */
//* UPDATE: SOURCE changed to create SYS2.ASM                      */
//******************************************************************/
//TAPE     DD   DSN=OPTSRCE,UNIT=TAPE,VOL=SER=EZASMI,
//  LABEL=3,DISP=(,KEEP)
//SOURCE   DD   DSN=SYS2.ASM,
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(TRK,(10,10,5)),
//            UNIT=SYSALLDA,
//            DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=800)
//SYSPRINT DD   SYSOUT=*
//SYSIN    DD   *
 COPY I=((TAPE,R)),O=SOURCE
 SELECT M=(EZASOH03,EZACIC04,EZACIC05,NSLOOKUP,NCAT)
/*