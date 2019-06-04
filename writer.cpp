#include "writer.hpp"
#include "parser.hpp"

extern ofstream outputFile;

bool SHOW_ON_CONSOLE = true;
int labelCounter = 0;
string spaceBetween = "\t\t";

void displayCommand(string command) {
    if (SHOW_ON_CONSOLE) {
        cout << command << endl;
        //outputFile << command << endl; 
    }
}

void displayLabel(string label) {
    string command = label + ":";

    displayCommand(command);
}

void displayEnter(int offset) {
    string command = "\tenter.i";
    command += spaceBetween;
    command += "#" + to_string(offset);

    displayCommand(command);
}

void displaySubprogramEnd() {
    string command = "\tleave\n\treturn";

    displayCommand(command);
}

void displayMethod(MethodType methodType, string text) {
    string command = "\t";
    switch (methodType) {
        case MethodType::Call:
            command += "call.i";
            command += spaceBetween;
            command += "#" + text;
            break;
        case MethodType::Write:
            command += "write";
            break;
        default:
            break;
    }

    displayCommand(command);
}

void displayJump(string label) {
    string command = "\tjump.i" + spaceBetween + "#" + label;

    displayCommand(command);
}

void displayMov(Type type, string value, int destination) {
    string command = "\tmov";
    command += getTypeSuffix(type);

    command += spaceBetween;
    command += value;
    command += "," + to_string(destination);

    displayCommand(command);
}

void displayAddop(int token, Type type, string lhs, string rhs, int dst) {
    string command= "\t";
    command += getFunctionByToken(token);
    command += getTypeSuffix(type);

    command += spaceBetween;
    command += lhs;
    command += "," + rhs;
    command += "," + to_string(dst);

    displayCommand(command);
}

void displayCast(Type type, string value, int destination) {
    string command = "\t";
    command += getCastFunctionByType(type);
    command += "\t";

    command += value;
    command += "," + to_string(destination);

    displayCommand(command);
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

