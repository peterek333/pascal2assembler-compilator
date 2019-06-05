%{
	#include "symtable.hpp"
    #include "writer.hpp"
    
    extern vector<string> supportedMethods;

    SymTable symTable;

    vector<int> identifiersVector;
    string mainLabel;

    int subprogramOffset = 0;
    bool isGlobal = true;

    const char* outputFilename = "output.asm";
    ofstream outputFile;

    void fillSymbolIfTypeIsKnown(int identifier, int type_);
    void castTypeIfNeeded(Symbol& leftSide, Symbol& rightSide);
    void castTypeForAssignmentIfNeeded(Symbol& leftSide, Symbol& rightSide);
    Symbol castVarOrNumber(Type type, Symbol symbol);
    int createExpression(int op, int leftSideIndex, int rightSideIndex);
    void createAssignment(int leftSideIndex, int rightSideIndex);
    string getAddressOrIdIfNumber(Symbol symbol);
    int createCallMethod(int methodIndex);
    void createCallFunctionOrProcedure(Symbol method);
    bool allArgumentsPassed(Symbol method);
    bool isSupportedMethod(string methodName);
%}


%token PROGRAM
%token VAR
%token INTEGER
%token REAL
%token BEGIN_
%token END
%token NUMBER
%token ID

%token FUNCTION
%token PROCEDURE
%token IF
%token THEN
%token ELSE
%token WHILE
%token DO
%token OR
%token NOT

%token ASSIGNOP
%token MULOP
%token RELOP
%token SIGN

%token PLUS
%token MINUS
%token MUL
%token DIV
%token GT
%token LT
%token GTE
%token LTE
%token EQ
%token NOTEQ

%%

program:
    PROGRAM ID '(' identifier_list ')' ';' {
        mainLabel = getNextLabel();
        displayJump(mainLabel);
        identifiersVector.clear();
    }
    declarations
    subprogram_declarations {
        displayLabel(mainLabel);
    }
    compound_statement {
        //symTable.print();
    }
    '.' {
        displayCommand("\texit");
        symTable.print();
    }
    ;

identifier_list:
    ID {
        identifiersVector.push_back($1);
    }
    | 
    identifier_list ',' ID {
        identifiersVector.push_back($3);
    }
    ;

declarations:
    declarations VAR identifier_list ':' type ';' {
        for (auto &identifier: identifiersVector) {
            fillSymbolIfTypeIsKnown(identifier, $5);
        }
        identifiersVector.clear();
    }
    |
    ;

type:
    standard_type
    ;

standard_type:
    INTEGER
    |
    REAL
    ;

subprogram_declarations:
    subprogram_declarations subprogram_declaration
    ';' {
        displaySubprogramEnd();
        isGlobal = true;
    }
    |
    ;

subprogram_declaration:
    subprogram_head declarations {
        displayEnter(subprogramOffset);
    }
    compound_statement
    ;

subprogram_head:
    FUNCTION ID arguments ':' standard_type ';' {
        isGlobal = false;
    }
    |
    PROCEDURE ID arguments ';' {
        isGlobal = false;
        Symbol& procedure = symTable.get($2);
        procedure.token = PROCEDURE;
        displayLabel(procedure.id);
    }
    ;

arguments:
    '(' parameter_list ')'
    |
    ;

parameter_list:
    identifier_list ':' type
    |
    parameter_list ';' identifier_list ':' type
    ;

compound_statement:
    BEGIN_
    optional_statements
    END
    ;

optional_statements:
    statement_list
    |
    ;

statement_list:
    statement
    |
    statement_list ';' statement
    ;

statement:
    variable ASSIGNOP expression {
        createAssignment($1, $3);
    }
    |
    procedure_statement
    |
    compound_statement
    |
    IF expression THEN statement ELSE statement
    |
    WHILE expression DO statement
    ;

variable:
    ID
    |
    ID '[' expression ']'
    ;

procedure_statement:
    ID {
        Symbol method = symTable.get($1);
        if (allArgumentsPassed(method)) {
            createCallFunctionOrProcedure(method);
        }
    }
    |
    ID '(' expression_list ')' {
        int returnedSymbolIndex = createCallMethod($1);
        if (symTable.get($1).token == FUNCTION) {
            $$ = returnedSymbolIndex;
        }
        identifiersVector.clear();
    }
    ;

expression_list:
    expression {
        identifiersVector.push_back($1);
    }
    |
    expression_list ',' expression {
        identifiersVector.push_back($3);
    }
    ;

expression:
    simple_expression
    |
    simple_expression RELOP simple_expression
    ;

simple_expression:
    term
    |
    SIGN term
    |
    simple_expression SIGN term {
        $$ = createExpression($2, $1, $3);
    }
    |
    simple_expression OR term
    ;

term:
    factor
    |
    term MULOP factor {
        $$ = createExpression($2, $1, $3);
    }
    ;

factor:
    variable
    |
    ID '(' expression_list ')'
    |
    NUMBER
    |
    '(' expression ')'
    |
    NOT factor
    ;

%%

void yyerror(char *s)
{
    fprintf(stderr, "%s\n", s);
}

int main(int argc, char *argv[])
{
    /* yydebug = 1; */
    if (argc > 2) {
        outputFilename = argv[1];
    }
    outputFile.open(outputFilename);

    yyparse();

    outputFile.close();
    
    return 0;
}

void fillSymbolIfTypeIsKnown(int identifier, int type_) {
    Type type = Type::Unknown;
    switch(type_) {
        case INTEGER:
            type = Type::Integer;
            break;
        case REAL:
            type = Type::Real;
            break;
        default:
            yyerror("Not supported type");
            break;
    }
    if (type != Type::Unknown) {
        symTable.fillSymbol(identifier, VAR, type);
        symTable.get(identifier).global = isGlobal;
    }
}

void castTypeIfNeeded(Symbol& leftSide, Symbol& rightSide) {
    if (leftSide.type == Type::Real && rightSide.type == Type::Integer) {
        rightSide = castVarOrNumber(Type::Real, rightSide);
    } else if (leftSide.type == Type::Integer && rightSide.type == Type::Real) {
        leftSide = castVarOrNumber(Type::Real, leftSide);
    }
}

void castTypeForAssignmentIfNeeded(Symbol& leftSide, Symbol& rightSide) {
    if (leftSide.type == Type::Real && rightSide.type == Type::Integer) {
        rightSide = castVarOrNumber(Type::Real, rightSide);
    } else if (leftSide.type == Type::Integer && rightSide.type == Type::Real) {
        rightSide = castVarOrNumber(Type::Integer, rightSide);
    }
}

Symbol castVarOrNumber(Type type, Symbol symbol) {
    Symbol temp = symTable.insertTemp(type);
    string value = getAddressOrIdIfNumber(symbol);
    
    displayCast(symbol.type, value, temp.address);
    return temp;
}

int createExpression(int op, int leftSideIndex, int rightSideIndex) {
    Symbol leftSide = symTable.get(leftSideIndex);
    Symbol rightSide = symTable.get(rightSideIndex);
    castTypeIfNeeded(leftSide, rightSide);

    int resultIndex = symTable.insertTempReturnIndex(leftSide.type);
    Symbol resultSymbol = symTable.get(resultIndex);
    string lhs = getAddressOrIdIfNumber(leftSide);
    string rhs = getAddressOrIdIfNumber(rightSide);
    displayAddop(op, resultSymbol.type, lhs, rhs, resultSymbol.address);
    
    return resultIndex;
}

void createAssignment(int leftSideIndex, int rightSideIndex) {
    Symbol leftSide = symTable.get(leftSideIndex);
    Symbol rightSide = symTable.get(rightSideIndex);

    castTypeForAssignmentIfNeeded(leftSide, rightSide);
    string movedValue = getAddressOrIdIfNumber(rightSide);
    
    displayMov(leftSide.type, movedValue, leftSide.address);
}

string getAddressOrIdIfNumber(Symbol symbol) {
    return symbol.token == NUMBER
        ? "#" + symbol.id
        : to_string(symbol.address);
}

int createCallMethod(int methodIndex) {
    Symbol method = symTable.get(methodIndex);
    if (method.token == FUNCTION) { 
        return 1;
    } else if (method.token == PROCEDURE) {
        //call
    } else if (isSupportedMethod(method.id)) {
        for (auto& identifier: identifiersVector) {
            Symbol methodSymbol = symTable.get(identifier);
            displaySupportedMethod(method.id, methodSymbol.type, getAddressOrIdIfNumber(methodSymbol));
        }
    } else {
        yyerror("Function or procedure does not exist");
    }
    return -1;
}

void createCallFunctionOrProcedure(Symbol method) {
    displayMethod(MethodType::Call, method.id);
}

bool allArgumentsPassed(Symbol method) {
    if (method.token == FUNCTION || method.token == PROCEDURE) {
        if (method.arguments.size() > 0) {
            yyerror("Function or procedure does not have enough arguments");
            return false;
        } else {
            return true;
        }
    }
    return false;   //because it is not function or procedure
}

bool isSupportedMethod(string methodName) {
    return find(
        supportedMethods.begin(),
        supportedMethods.end(),
        methodName) != supportedMethods.end();
}