# Makefile for CLISP module set wildcard

CC = gcc -mno-cygwin
CPPFLAGS = 
CFLAGS = -O2
CLISP = clisp -q -norc
INCLUDES = $$($(CLISP) -b)/linkkit

LN = ln

MAKE = make

SHELL = /bin/sh

DISTRIBFILES = wildcard.o link.sh Makefile README wildcard.lisp wildcard.xml
distribdir =

all : wildcard.o wildcard.fas

wildcard.c wildcard.fas : wildcard.lisp
	$(CLISP) -c wildcard.lisp

wildcard.o : wildcard.c config.h
	$(CC) $(CPPFLAGS) $(CFLAGS) -I$(INCLUDES) -c wildcard.c

# Make a module
clisp-module : all

# Make a module distribution into $(distribdir)
clisp-module-distrib : clisp-module force
	$(LN) $(DISTRIBFILES) $(distribdir)

clean : force
	rm -f core *.o *.a

distclean : clean

force :

