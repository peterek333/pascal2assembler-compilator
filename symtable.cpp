#include "symtable.hpp"
#include "parser.hpp"

vector<string> supportedMethods = { "write", "read" };

int tempSymbolsCounter = 0;
string tempSymbolPrefix = "$t";

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
    symbol.address = calculateAddress(type);
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
        if (symbols[index].id == id) {
            return index;
        }
    }
    return -1;
}

bool SymTable::exists(string id) {
    return find(id) != -1;
}

void SymTable::print() {
    for (int i = 0; i < symbols.size(); i++) {
        cout << "(" << symbols[i].id 
        << ", " << symbols[i].token 
        << ", " << static_cast<std::underlying_type<Type>::type>(symbols[i].type) 
        << ", " << symbols[i].address
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

    return symbol;
}

int SymTable::calculateAddress(Type type) {
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