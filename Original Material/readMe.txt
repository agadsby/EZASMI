The desktop install process will create an install directory to contain the
TCP/IP for MVS 3.8 Assembler help file (EZASMIHelp.jar), the MVS installation
JCL (InstallEZASMI.jcl), and the MVS installation tape file (EZASMI.het). The
MVS installation JCL can be used to install the EZASMI macro set, the EZASOH03
load module, and the optional source material into the appropriate libraries.

The following files are included in the desktop install directory:
	- EZASMIHelp.jar
	- InstallEZASMI.jcl
	- LinkEZASOH03.jcl
	- readMe.txt (this file)
	- EZASMI.het

The LinkEZASOH03.jcl file contains a linkage editor step. If you make any
changes to the modules contained in EZASOH03, this file demonstrates how
the modified load module should be created.	
	
The desktop installation process will also create an Uninstaller folder
containing uninstall.jar which may be used to uninstall the files
in the install directory.

1. Currently, the desktop installation program can only create a desktop
   shortcut (if requested) for the Windows environment and
   Linux/Unix environments using the KDE desktop.

2. For Linux/Unix environments using other X11 family desktops
   (such as Gnome), a TCP/IP for MVS 3.8 Assembler Help application
   menu will be created, but a desktop shortcut will not.

3. For Mac OS X, the desktop installer will provide all the TCP/IP for
   MVS 3.8 Assembler files, but it cannot currently create
   a shortcut for this  environment. All the pieces for creating
   an OS X bundle should be available in the Client installation
   folder for those who know how to work such magic.

Prerequisites:

TCP/IP for MVS 3.8 Assembler requires the TK4-, Update 09 or later version of Hercules.