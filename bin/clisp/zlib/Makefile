# Makefile for CLISP module set zlib

CC = gcc -mno-cygwin
CPPFLAGS = 
CFLAGS = -O2
CLISP = clisp -q -norc
INCLUDES = $$($(CLISP) -b)/linkkit

LN = ln

MAKE = make

SHELL = /bin/sh

DISTRIBFILES = zlib.o link.sh Makefile zlib.lisp
distribdir =

all : zlib.o zlib.fas

zlib.c zlib.fas : zlib.lisp
	$(CLISP) -c zlib.lisp

zlib.o : zlib.c config.h
	$(CC) $(CPPFLAGS) $(CFLAGS) -I$(INCLUDES) -c zlib.c

# Make a module
clisp-module : all

# Make a module distribution into $(distribdir)
clisp-module-distrib : clisp-module force
	$(LN) $(DISTRIBFILES) $(distribdir)

clean : force
	rm -f core *.o *.a

distclean : clean

force :

