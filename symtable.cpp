#include "symtable.hpp"
#include "parser.hpp"

extern bool isGlobal;

vector<string> supportedMethods = { "write", "read" };

int tempSymbolsCounter = 0;
string tempSymbolPrefix = "$t";

void Symbol::print() {
    cout << "(" << id 
    << ", " << token 
    << ", " << static_cast<std::underlying_type<Type>::type>(type) 
    << ", " << address
    << " [address]"
    << ", " << (global ? "G" : "LOC")
    << ", " << reference
    << " [reference]"
    << ")" << endl; 
}

int SymTable::insert(string id, int token, Type type) {
    Symbol symbol = createSymbol(id, token, type);

    symbols.push_back(symbol);
    return symbols.size() - 1;
}

Symbol& SymTable::insertTemp(Type type) {
    return get(insertTempReturnIndex(type));
}

int SymTable::insertTempReturnIndex(Type type) {
    string tempId = tempSymbolPrefix + to_string(tempSymbolsCounter++);

    return insert(tempId, ID, type);
}

void SymTable::fillSymbol(int symbolIndex, int token, Type type) {
    Symbol& symbol = get(symbolIndex);
    symbol.token = token;
    symbol.type = type;
    if ( !symbol.reference) {
        symbol.address = calculateAddress(type);
    }
    symbol.global = isGlobal;
}

Symbol& SymTable::get(int index) {
    return symbols.at(index);
}

Symbol& SymTable::get(string id) {
    return get(find(id));
}

int SymTable::find(string id) {
    //start from end because we want local symbols first    
    for (int index = symbols.size() - 1; index >= 0; index--) {
        if (symbols[index].id == id)  {
            return index;
        }
    }
    return -1;
}

bool SymTable::exists(string id) {
    return find(id) != -1;
}

int SymTable::getLocalLastAddress() {
    return localLastAddress;
}

void SymTable::print() {
    /*
    cout << "SymTable "
    << "lastAddress = " << lastAddress
    << " localLastAddress = " << localLastAddress
    << endl;
    */
    for (int i = 0; i < symbols.size(); i++) {
        cout << "(" << symbols[i].id 
        << ", " << symbols[i].token 
        << ", " << static_cast<std::underlying_type<Type>::type>(symbols[i].type) 
        << ",a " << symbols[i].address
        << ", " << (symbols[i].global ? "G" : "LOC")
        << ",r " << symbols[i].reference
        << ") || ";
    }
    cout << "\n";
}

Symbol SymTable::createSymbol(string id, int token, Type type) {
    Symbol symbol;
    symbol.id = id;
    symbol.token = token;
    symbol.type = type;
    if (token == ID) {
        symbol.address = calculateAddress(type);
    }
    symbol.global = isGlobal;

    return symbol;
}

int SymTable::calculateAddress(Type type) {
    return isGlobal
        ? globalAddress(type)
        : localAddress(type);
}

int SymTable::globalAddress(Type type) {
    int address = lastAddress;
    if (type == Type::Integer) {
        lastAddress += 4;
    } else if (type == Type::Real) {
        lastAddress += 8;
    } else {
        return -1;
    }
    return address;
}

int SymTable::localAddress(Type type) {
    if (type == Type::Integer) {
        localLastAddress += 4;
    } else if (type == Type::Real) {
        localLastAddress += 8;
    } else {
        return -1;
    }
    return -localLastAddress;
}

SymTable SymTable::deepCopy() {
    SymTable copiedTable;
    copiedTable.lastAddress = lastAddress;
    copiedTable.localLastAddress = localLastAddress;
    copiedTable.symbols = symbols;

    return copiedTable;
}