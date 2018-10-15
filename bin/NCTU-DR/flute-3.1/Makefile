CC = g++ -std=c++1y
CFLAGS = -O3 -I.

SRC     = dist.c dl.c err.c heap.c mst2.c neighbors.c \
	bookshelf_IO.c memAlloc.c flute.c flute_mst.c
OBJ     = $(SRC:.c=.o)

all: flute-net 

flute-net: flute-net.c ${OBJ}
	$(CC) $(CFLAGS) -o flute-net flute-net.c ${OBJ} -lm

flute.o: flute.c flute.h
	$(CC) $(CFLAGS) -c -o flute.o flute.c

flute_mst.o: flute_mst.c flute.h
	$(CC) $(CFLAGS) -c -o flute_mst.o flute_mst.c

clean:
	rm -f *.o core*
