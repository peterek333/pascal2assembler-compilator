#include "symtable.hpp"

void displayCommand(string command);
void displayLabel(string label);
void displayJump(string label);
void displayMov(Type type, int lhs, int rhs);
void displayAddop(int token, Type type, int lhs, int rhs, int dst);
void displayCast(Type type, int lhs, int dst);
string formatAddresses(int first = -1, int second = -1, int third = -1);
string getNextLabel();
string getTypeSuffix(Type type);
string getCastFunctionByType(Type type);
string getFunctionByToken(int token);