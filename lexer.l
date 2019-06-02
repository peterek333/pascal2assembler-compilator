%{
	#include "symtable.hpp"
	#include "parser.hpp"

    extern SymTable symTable;

    int getMulopToken(string val);
    int getSignToken(string val);
    int getRelopToken(string val);
%}

digit               [0-9]
digits              {digit}+
optional_fraction   (\.{digits})?
optional_exponent   ([Ee]([+-]?){digits})?
num                 {digits}{optional_fraction}{optional_exponent}

character           [a-zA-Z]
id                  {character}({character}|{digit})*

assignop            :=
mulop               \*|\/|(div)|(mod)|(and)
sign                \+|-
relop               >|<|>=|<=|=|<>

whitespace          [ \t\n\r]+
default_chars       [\(\)\,\;\:\.\[\]]{1}
comment             \{.*\}|\/\/.*

%%

program             { return PROGRAM; }
var                 { return VAR; }
integer             { 
                        yylval = INTEGER; 
                        return INTEGER; 
                    }
real                { 
                        yylval = REAL;
                        return REAL; 
                    }
begin               { return BEGIN_; }
end                 { return END; }
function            { return FUNCTION; }
procedure           { return PROCEDURE; }
if					{ return IF; }
then				{ return THEN; }
else				{ return ELSE; }
while	            { return WHILE; }
do					{ return DO; }
or					{ return OR; }
not					{ return NOT; }

{digits}            { 
                        yylval = symTable.insert(yytext, ID, Type::Integer); 
                        return NUMBER; 
                    }
{num}               { 
                        yylval = symTable.insert(yytext, ID, Type::Real); 
                        return NUMBER; 
                    }
{id}                { 
                        if ( !symTable.exists(yytext)) {
                            yylval = symTable.insert(yytext, ID, Type::Unknown);
                        } else {
                            yylval = symTable.find(yytext);
                        }
                        return ID;  
                    }

{assignop}          { return ASSIGNOP; }
{mulop}             {
                        yylval = getMulopToken(yytext);
                        return MULOP;
                    }
{sign}              {
                        yylval = getSignToken(yytext);
                        return SIGN;
                    }
{relop}             {
                        yylval = getRelopToken(yytext);
                        return RELOP;
                    }

{whitespace}        { /* NIC */ }
{default_chars}     { return *yytext; }
{comment}           { /* NIC */ }

%%

int yywrap(void) 
{
    return 1;
}

int getMulopToken(string val) {
    if ( !val.compare("*") ) {
        return MUL;
    }
    if ( !val.compare("/") || !val.compare("div") ) {
        return DIV;
    }
    return 0;
}

int getSignToken(string val) {
    if ( !val.compare("+") ) {
        return PLUS;
    }
    if ( !val.compare("-") ) {
        return MINUS;
    }
    return 0;
}

int getRelopToken(string val) {
    if ( !val.compare(">") ) {
        return GT;
    }
    if ( !val.compare("<") ) {
        return LT;
    }
    if ( !val.compare(">=") ) {
        return GTE;
    }
    if ( !val.compare("<=") ) {
        return LTE;
    }
    if ( !val.compare("=") ) {
        return EQ;
    }
    if ( !val.compare("<>") ) {
        return NOTEQ;
    }
    return 0;

}

