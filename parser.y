%{
	#include "symtable.hpp"
    #include "writer.hpp"

    SymTable symTable;

    std::vector<int> identifiersVector;
    string label;

    void fillSymbolIfTypeIsKnown(int identifier, int type_);
    void castTypeIfNeeded(Symbol& leftSide, Symbol& rightSide);
    void castTypeForAssignmentIfNeeded(Symbol& leftSide, Symbol& rightSide);
    int createExpression(int op, int leftSideIndex, int rightSideIndex);
    void createAssignment(int leftSideIndex, int rightSideIndex);
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
        label = getNextLabel();
        displayJump(label);
        identifiersVector.clear();
    }
    declarations {
        displayLabel(label);
    }
    subprogram_declarations
    compound_statement {
        //symTable.print();
    }
    '.' {
        displayCommand("\texit");
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
    |
    ;

subprogram_declaration:
    subprogram_head
    declarations
    compound_statement
    ;

subprogram_head:
    FUNCTION ID arguments ':' standard_type ';'
    |
    PROCEDURE ID arguments ';'
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
    ID
    |
    ID '(' expression_list ')'
    ;

expression_list:
    expression
    |
    expression_list ',' expression
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

int main(void)
{
    /* yydebug = 1; */
    yyparse();
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
            break;
    }
    if (type != Type::Unknown) {
        symTable.fillSymbol(identifier, VAR, type);
    }
}

void castTypeIfNeeded(Symbol& leftSide, Symbol& rightSide) {
    if (leftSide.type == Type::Real && rightSide.type == Type::Integer) {
        Symbol temp = symTable.insertTemp(Type::Real);
        displayCast(rightSide.type, rightSide.address, temp.address);
        rightSide = temp;
    } else if (leftSide.type == Type::Integer && rightSide.type == Type::Real) {
        Symbol temp = symTable.insertTemp(Type::Real);
        displayCast(leftSide.type, leftSide.address, temp.address);
        leftSide = temp;
    }
}

void castTypeForAssignmentIfNeeded(Symbol& leftSide, Symbol& rightSide) {
    if (leftSide.type == Type::Real && rightSide.type == Type::Integer) {
        Symbol temp = symTable.insertTemp(Type::Real);
        displayCast(rightSide.type, rightSide.address, temp.address);
        rightSide = temp;
    } else if (leftSide.type == Type::Integer && rightSide.type == Type::Real) {
        Symbol temp = symTable.insertTemp(Type::Integer);
        displayCast(rightSide.type, rightSide.address, temp.address);
        rightSide = temp;
    }
}

int createExpression(int op, int leftSideIndex, int rightSideIndex) {
    Symbol leftSide = symTable.get(leftSideIndex);
    Symbol rightSide = symTable.get(rightSideIndex);
    castTypeIfNeeded(leftSide, rightSide);

    int resultIndex = symTable.insertTempReturnIndex(leftSide.type);
    Symbol resultSymbol = symTable.get(resultIndex);
    displayAddop(op, resultSymbol.type, leftSide.address, rightSide.address, resultSymbol.address);
    
    return resultIndex;
}

void createAssignment(int leftSideIndex, int rightSideIndex) {
    Symbol leftSide = symTable.get(leftSideIndex);
    Symbol rightSide = symTable.get(rightSideIndex);

    castTypeForAssignmentIfNeeded(leftSide, rightSide);
    displayMov(leftSide.type, rightSide.address, leftSide.address);
}