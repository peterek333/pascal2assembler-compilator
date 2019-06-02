LEX = flex
YACC = bison
CC = g++

FLAGS =-std=c++11
OBJECTS = lexer.o parser.o symtable.o writer.o

.PHONY: clean

all: ${OBJECTS}
	${CC} ${FLAGS} ${OBJECTS} -o compilator

lexer.cpp: lexer.l
	${LEX} -o lexer.cpp lexer.l

parser.cpp parser.hpp: parser.y
	${YACC} -o parser.cpp -d parser.y

lexer.o: lexer.cpp parser.hpp symtable.hpp
	${CC} ${FLAGS} -c lexer.cpp

parser.o: parser.cpp symtable.hpp writer.hpp
	${CC} ${FLAGS} -c parser.cpp

symtable.o: symtable.cpp symtable.hpp
	${CC} ${FLAGS} -c symtable.cpp 

writer.o: writer.cpp writer.hpp symtable.hpp
	${CC} ${FLAGS} -c writer.cpp 

clean:
	rm -f *.o
	rm -f compilator lexer.cpp parser.cpp parser.hpp

