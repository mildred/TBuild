
tbuild: main.o
	$(CC) -ltcl8.5 -o $@ $<

script.tcl: TBuild.pkg.tcl tbuild.tcl
	cat $+ > $@

script.h: script.h.in script.tcl
	./replace.lua script.tcl < $< > $@

main.o: main.c script.h
