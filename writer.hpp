#include "symtable.hpp"

void displayCommand(string command);
void displayLabel(string label);
void displayEnter(int offset);
void displaySubprogramEnd();
void displayMethod(MethodType methodType, string text);
void displaySupportedMethod(string methodName, Type methodType, string value);
void displayJump(string label);
void displayMov(Type type, string value, int destination);
void displayAddop(int token, Type type, string lhs, string rhs, int dst);
void displayCast(Type type, string value, int destination);
string getNextLabel();
string getTypeSuffix(Type type);
string getCastFunctionByType(Type type);
string getFunctionByToken(int token);