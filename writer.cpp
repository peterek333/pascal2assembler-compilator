#include "writer.hpp"
#include "parser.hpp"

bool SHOW_ON_CONSOLE = true;
int labelCounter = 0;
string spaceBetween = "\t\t";

void displayCommand(string command) {
    if (SHOW_ON_CONSOLE) {
        cout << command << endl;
    }
}

void displayLabel(string label) {
    string command = label + ":";

    displayCommand(command);
}

void displayJump(string label) {
    string command = "\tjump.i" + spaceBetween + "#" + label;

    displayCommand(command);
}

void displayMov(Type type, int lhs, int rhs) {
    string command = "\tmov";
    command += getTypeSuffix(type);

    command += spaceBetween;
    command += formatAddresses(lhs, rhs);

    displayCommand(command);
}

void displayAddop(int token, Type type, int lhs, int rhs, int dst) {
    string command= "\t";
    command += getFunctionByToken(token);
    command += getTypeSuffix(type);

    command += spaceBetween;
    command += formatAddresses(lhs, rhs, dst);

    displayCommand(command);
}

void displayCast(Type type, int lhs, int dst) {
    string command = "\t";
    command += getCastFunctionByType(type);
    command += "\t";
    command += formatAddresses(lhs, dst);

    displayCommand(command);
}

string formatAddresses(int first, int second, int third) {
    string addresses = "";
    if ( first != -1 ) {
        addresses += to_string(first);
    }
    if ( second != -1 ) {
        addresses += "," + to_string(second);
    }
    if ( third != -1 ) {
        addresses += "," + to_string(third);
    }
    return addresses;
}

string getNextLabel() {
    return "lab" + to_string(labelCounter++);
}

string getTypeSuffix(Type type) {
    if (type == Type::Integer) {
        return ".i";
    } else if (type == Type::Real) {
        return ".r";
    }
    throw exception();
}

string getCastFunctionByType(Type type) {
    if (type == Type::Integer) {
        return "inttoreal.i";
    } else if (type == Type::Real) {
        return "realtoint.r";
    }
    return "";
}

string getFunctionByToken(int token) {
    if ( token == PLUS ) {
        return "add";
    } else if ( token == MINUS ) {
        return "sub";
    } else if ( token == MUL ) {
        return "mul";
    } else if ( token == DIV ) {
        return "div";
    }

    return "syntax error";
    //throw exception();
}

