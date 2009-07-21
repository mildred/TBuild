#!/usr/bin/env tbuild

#Clang obj main.o main.c
Clang exe tbuild {main.c} -ltcl8.5

# depends all excutable
# 
# Clang exe executable { object.o object.c }
# Clang obj 
# 
# Clang src file.c
# Clang obj file.o { file.c }
# Clang lnk executable { file.o }
