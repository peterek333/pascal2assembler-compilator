#include "writer.hpp"
#include "parser.hpp"

extern ofstream outputFile;
extern bool isGlobal;

stringstream localBuffer;

bool SHOW_ON_CONSOLE = true;
int labelCounter = 0;
string spaceBetween = "\t\t";

void displayCommand(string command) {
    if (isGlobal) {
        if (SHOW_ON_CONSOLE) {
            cout << command << endl;
        } else {
            outputFile << command << endl; 
        }   
    } else {
        localBuffer << command << endl;
    }
}

void displayLocalFromBuffer() {
    if (SHOW_ON_CONSOLE) {
        cout << localBuffer.rdbuf()->str();
    } else {
        outputFile << localBuffer.rdbuf()->str(); 
    }
    localBuffer.str(string()); //clear buffer
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

void displaySupportedMethod(string methodName, Type methodType, string value) {
    string command = "\t" + methodName;

    command += getTypeSuffix(methodType);
    command += spaceBetween;
    command += value;

    displayCommand(command);
}

void displayJump(string label) {
    string command = "\tjump.i" + spaceBetween + "#" + label;

    displayCommand(command);
}

void displayMov(Type type, string value, string destination) {
    string command = "\tmov";
    command += getTypeSuffix(type);

    command += spaceBetween;
    command += value;
    command += "," + destination;

    displayCommand(command);
}

void displayPush(string address) {
    string command = "\tpush.i";

    command += spaceBetween;
    command += address;

    displayCommand(command);
}

void displayIncsp(int incspValue) {
    string command = "\tincsp.i";

    command += spaceBetween;
    command += "#" + to_string(incspValue);

    displayCommand(command);
}

void displayAddop(int token, Type type, string lhs, string rhs, string dst) {
    string command= "\t";
    command += getFunctionByToken(token);
    command += getTypeSuffix(type);

    command += spaceBetween;
    command += lhs;
    command += "," + rhs;
    command += "," + dst;

    displayCommand(command);
}

void displayCast(Type type, string value, string destination) {
    string command = "\t";
    command += getCastFunctionByType(type);
    command += "\t";

    command += value;
    command += "," + destination;

    displayCommand(command);
}

void displayRelopJump(int token, Type type, string leftValue, string rightValue, string label) {
    string command = "\t";
    command += getRelop(token);
    command += getTypeSuffix(type);

    command += spaceBetween;
    command += leftValue;
    command += "," + rightValue;
    command += ",#" + label;

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
    cout << "Unrecognized type" << endl;
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
    } else if ( token == AND ) {
        return "and";
    } else if ( token == OR ) {
        return "or";
    } else if ( token == MOD ) {
        return "mod";
    }

    return "syntax error";
    //throw exception();
}

string getRelop(int token) {
    if ( token == EQ) {
        return "je";
    } else if ( token == NOTEQ ) {
        return "jne";
    } else if ( token == LTE ) {
        return "jle";
    } else if ( token == GTE ) {
        return "jge";
    } else if ( token == GT ) {
        return "jg";
    } else if ( token == LT ) {
        return "jl";\
    }
    cout << "Error relop" << endl;
    throw exception();
}
