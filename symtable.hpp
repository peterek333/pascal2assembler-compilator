#ifndef SYMTABLE_H

#define SYMTABLE_H

#include <string>
#include <vector>
#include <iostream>
#include <fstream>
#include <stdlib.h>
#include <stdio.h>
#include <sstream>

using namespace std;

enum class Type {
    Unknown = -1,
    Integer = 0,
    Real = 1
};

enum class MethodType {
    Call,
    Write
};

struct Symbol {
    string id;
    int token;
    int address;
    Type type;
    /* only functions and procedures */
    vector<Type> arguments;
};

class SymTable {
    vector<Symbol> symbols;
    int lastAddress = 0;
    Symbol createSymbol(string id, int token, Type type);
    int calculateAddress(Type type);

public:
    int insert(string id, int token, Type type);
    Symbol& insertTemp(Type type);
    int insertTempReturnIndex(Type type);
    void fillSymbol(int symbolIndex, int token, Type type);

    Symbol& get(int index);
    Symbol& get(string id);
    int find(string id);
    bool exists(string id);

    void print();
};

extern SymTable symTable;   //TODO usunac

int yylex(void);
void yyerror(char* );

#endif