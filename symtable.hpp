#ifndef SYMTABLE_H

#define SYMTABLE_H

#include <string>
#include <vector>
#include <iostream>
#include <fstream>
#include <stdlib.h>
#include <stdio.h>
#include <sstream>
#include <algorithm>

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

    bool global;
    bool reference = false;
    /* only functions and procedures */
    vector<Type> arguments;
    int argumentsAddress;

public:
    void print();
};

class SymTable {
    vector<Symbol> symbols;
    int lastAddress = 0;
    int localLastAddress = 0;

    Symbol createSymbol(string id, int token, Type type);
    int calculateAddress(Type type);
    int globalAddress(Type type);
    int localAddress(Type type);

public:
    int insert(string id, int token, Type type);
    Symbol& insertTemp(Type type);
    int insertTempReturnIndex(Type type);
    int insertIfNotExist(string id, int token, Type type);
    void fillSymbol(int symbolIndex, int token, Type type);

    Symbol& get(int index);
    Symbol& get(string id);
    int find(string id);
    bool exists(string id);

    int getLocalLastAddress();

    void print();
    
    SymTable deepCopy();
};

extern SymTable symTable;   //TODO usunac

int yylex(void);
void yyerror(char* );

#endif