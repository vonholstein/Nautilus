# Makefile for CLISP module set pcre

CC = gcc -mno-cygwin
PCRECPPFLAGS = 
CFLAGS = -O2
CLISP = clisp -q -norc
INCLUDES = $$($(CLISP) -b)/linkkit

LN = ln

MAKE = make

SHELL = /bin/sh

DISTRIBFILES = cpcre.o link.sh Makefile pcre.lisp test.tst pcre.xml preload.lisp
distribdir =

all : pcre.fas cpcre.o

pcre.fas : pcre.lisp
	$(CLISP) -c pcre.lisp

cpcre.o : cpcre.m.c config.h
	$(CC) $(CPPFLAGS) $(PCRECPPFLAGS) $(CFLAGS) -I$(INCLUDES) -c cpcre.m.c -o cpcre.o

cpcre.m.c : cpcre.c
	$(CLISP) -C $(INCLUDES)/modprep cpcre.c

# Make a module
clisp-module : all

# Make a module distribution into $(distribdir)
clisp-module-distrib : clisp-module force
	$(LN) $(DISTRIBFILES) $(distribdir)

clean : force
	rm -f core *.o *.a

force :

