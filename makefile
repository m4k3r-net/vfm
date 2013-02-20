all: libvfm.a runtime.s vfa vfc vfm vft libtest.vfa

libvfm.a: runtime.o compiler.o loader.o profiler.o utility.o
	ar rcs libvfm.a runtime.o compiler.o loader.o profiler.o utility.o

utility.o: utility.c vfm.h optab.i
	gcc -O3 -Wall -c utility.c -o utility.o

runtime.o: runtime.c vfm.h optab.i	
	gcc -Wall -Os -fno-crossjumping -fomit-frame-pointer -fno-gcse -c runtime.c -o runtime.o
	# gcc -Os -Wall -c runtime.c -o runtime.o

compiler.o: compiler.c vfm.h optab.i
	gcc -O3 -Wall -c compiler.c -o compiler.o

loader.o: loader.c vfm.h optab.i
	gcc -O3 -Wall -c loader.c -o loader.o

profiler.o: profiler.c vfm.h optab.i
	gcc -O3 -Wall -c profiler.c -o profiler.o

runtime.s: runtime.o
	gcc -Wall -S -Os -fno-crossjumping -fomit-frame-pointer -fno-gcse runtime.c
	# gcc -S -Os -Wall -c runtime.c

new:
	make clean
	make

clean:
	rm -f *.s *~ *.vfm *.vfa *.o test/*
	rm -f optab.i vfm.h libvfm.a vfa vfc vfm vft

vfm.h: header.i footer.i runtime.c
	cat header.i > vfm.h
	echo "" >> vfm.h
	echo "#ifndef _VFM_H_" >> vfm.h
	echo "#define _VFM_H_" >> vfm.h
	echo "" >> vfm.h
	echo "// NB: Operation codes generated by makefile" >> vfm.h
	echo "" >> vfm.h
	echo "enum vfm_opcode {" >> vfm.h
	grep "^OP(" runtime.c | \
	  sed s"/OP(/\ VFM_OP_/" | \
	  sed s"/)/\,/" >> vfm.h
	echo "};" >> vfm.h
	echo "" >> vfm.h
	cat footer.i >> vfm.h
	echo "" >> vfm.h
	echo "#endif" >> vfm.h

optab.i: runtime.c
	echo "// NB: Operation names and jump table generated by makefile" > optab.i
	echo "" >> optab.i
	echo "static char* opname[VFM_OPMAX + 1] = {" >> optab.i
	grep "^OP(" runtime.c | \
	  sed s"/OP(/\ \"/" | \
	  sed s"/)/\"\,/" >> optab.i
	echo " 0" >> optab.i 
	echo "};" >> optab.i
	echo "" >> optab.i
	echo "static void* optab[VFM_OPMAX + 1] = {" >> optab.i
	grep "^OP(" runtime.c | \
	  sed s"/OP(/\ \&\&/" | \
	  sed s"/)/\,/" >> optab.i 
	echo " 0" >> optab.i 
	echo "};" >> optab.i 

vfa: vfa.c libvfm.a
	gcc -O3 -Wall vfa.c -L. -lvfm -o vfa

vfc: vfc.c libvfm.a
	gcc -O3 -Wall vfc.c -L. -lvfm -o vfc

vfm: vfm.c libvfm.a
	gcc -O3 -Wall vfm.c -L. -lvfm -o vfm

libtest.vfa: vfc vfa test test*.fpp
	./vfc *.fpp
	./vfa libtest test/*.vfm

vft: vfc vft.c libvfm.a test0.fpp test1.fpp test2.fpp test3.fpp
	./vfc -s test0 test1 test2 test3
	gcc -O3 -Wall -I. vft.c -L. -lvfm -o vft

statistics: 
	# Number of opcodes
	grep VFM_OP vfm.h | wc
	# Source code lines
	wc *.c *.h 
	# Test code lines
	wc *.fpp

run:
	make tests > log/`uname -n`_`date +%s`.log

tests:
	uname -a 
	date
	make test1
	make test2
	make test3
	make test4
	make test5
	make test6

test1:
	# Static analysis during compiling
	./vfc -pc test3

test2:
	# Dump symbols for module object code
	./vfm -s test.test1
	# Dump symbols for module in archive 
	./vfa -s test test.test2
	# Dump all symbols for module in archive 
	./vfa -r test test.test3
	# Dump archived files
	./vfa -l test

test3:
	# Run embedded test file
	./vft -tpc
	# Run object file with tracing, profiling and coverage
	./vfm -tpc test.test3
	# Run archive file with tracing, profiling and coverage
	./vfm -ltest -tpc -e test.test3::main

test4: 
	# Run test files with tracing, profiling and coverage
	./vfm -tpc test.test1
	./vfm -tpc test.test2
	./vfm -tpc test.test3
	./vfm -pc test.test4
	./vfm -tpc test.test5
	./vfm -tpc test.test6
	./vfm -tpc test.test7
	./vfm -tpc test.test8

test5:
	# Simple benchmarks
	./vfm -b 10000000 -e test1 test.test1
	./vfm -b 10000000 -e test2 test.test1
	./vfm -b 10000000 -e test3 test.test1
	./vfm -b 10000000 -e test4 test.test1
	./vfm -b 10000000 -e test11 test.test1
	./vfm -b 100 -e 1-MILLION test.thread
	./vfm -b 1 -e 32-MILLION test.thread
	./vfm -b 1 -e test4 test.test2
test6:
	# Benchmarks for profiling and coverage overhead
	./vfm -b 100000 test.test2
	./vfm -b 100000 -n test.test2
	./vfm -b 100000 -c test.test2
	./vfm -b 100000 -pc test.test2




