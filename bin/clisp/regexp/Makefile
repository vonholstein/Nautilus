# Makefile for CLISP module set regexp

CC = gcc -mno-cygwin
CPPFLAGS = 
CFLAGS = -O2
CLISP = clisp -q -norc
INCLUDES = $$($(CLISP) -b)/linkkit

LN = ln

MAKE = make

SHELL = /bin/sh

DISTRIBFILES = regexi.o link.sh Makefile README regexp.lisp regexp.texinfo regexp.dvi preload.lisp
distribdir =

all : regexp.fas regexi.o

regexp.fas : regexp.lisp
	$(CLISP) -c regexp.lisp

regexi.o : regexi.m.c config.h
	$(CC) $(CPPFLAGS) $(CFLAGS) -I$(INCLUDES) -c regexi.m.c -o regexi.o

regexi.m.c : regexi.c
	$(CLISP) -C $(INCLUDES)/modprep regexi.c

# Make a module
clisp-module : all

# Make a module distribution into $(distribdir)
clisp-module-distrib : clisp-module force
	$(LN) $(DISTRIBFILES) $(distribdir)

clean : force
	rm -f core *.o *.a
	rm -f *.aux *.cp *.fn *.ky *.log *.pg *.toc *.tp *.vr

distclean : clean
	rm -f *.dvi

force :

