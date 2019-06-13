#include "symtable.hpp"

void displayCommand(string command);
void displayLocalFromBuffer();
void displayLabel(string label);
void displayEnter(int offset);
void displaySubprogramEnd();
void displayMethod(MethodType methodType, string text);
void displaySupportedMethod(string methodName, Type methodType, string value);
void displayJump(string label);
void displayMov(Type type, string value, string destination);
void displayPush(string address);
void displayIncsp(int incspValue);
void displayAddop(int token, Type type, string lhs, string rhs, string dst);
void displayCast(Type type, string value, string destination);
void displayRelopJump(int token, Type type, string leftValue, string rightValue, string label);
string getNextLabel();
string getTypeSuffix(Type type);
string getCastFunctionByType(Type type);
string getFunctionByToken(int token);
string getRelop(int token);