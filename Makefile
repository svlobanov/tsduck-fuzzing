# SPDX-License-Identifier: BSD-2-Clause

CC = cc
CFLAGS = -O3

fuzzing.o: fuzzing.c
	$(CC) $(CFLAGS) -c fuzzing.c -o fuzzing.o

fuzzing: fuzzing.o
	$(CC) fuzzing.o -o fuzzing

test: fuzzing
	./fuzzing.sh in.ts out.ts 1 10 100000 "1 5 10 50 100 200 300 400 500 600 800 1000 2000 3000 5000 8000 10000 30000 80000"
