#!/usr/bin/env tclsh
#set auto_path [linsert $::auto_path 0 [pwd]]
#package require TBuild::Clang

TBuild Require Clang
Alias Clang TBuild Clang

Clang obj main.o main.c

# depends all excutable
# 
# Clang exe executable { object.o object.c }
# Clang obj 
# 
# Clang src file.c
# Clang obj file.o { file.c }
# Clang lnk executable { file.o }
