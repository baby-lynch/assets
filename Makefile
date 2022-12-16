CC=cc
CFLAGS=-pipe -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror -g
# CFLAGS+=-fsanitize=address
LDFLAGS=-lcrypto
INCFLAGS=-I..

# output app main.c
SRC:=main.c 

# for manifest srcs
SRC+=../dos_manifest.c
SRC+=../dos_debug.c

APP=main

all:$(SRC)
	$(CC) -o $(APP) $^  \
	$(CFLAGS) $(LDFLAGS) $(INCFLAGS)

.PHONY:clean
clean:
	rm -rf main
	find . -name \*.txt -type f -delete
