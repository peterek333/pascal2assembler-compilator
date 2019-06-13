%{
	#include "symtable.hpp"
    #include "writer.hpp"
    
    extern vector<string> supportedMethods;

    SymTable symTable;
    SymTable dumpedTable;
    bool isGlobal = true;

    vector<int> identifiersVector;
    vector<int> parameterVector;
    string mainLabel;
    string actualMethodLabel;

    int subprogramOffset = 0;
    string elseLabel = "";
    string afterIf = "";

    const char* outputFilename = "output.asm";
    ofstream outputFile;

    void fillSymbolIfTypeIsKnown(int identifier, int type_);
    void castTypeIfNeeded(Symbol& leftSide, Symbol& rightSide);
    void castTypeForAssignmentIfNeeded(Symbol& leftSide, Symbol& rightSide);
    Symbol castVarOrNumber(Type type, Symbol symbol);
    void addParameters(int type_);
    void fillParameters();

    int createExpression(int op, int leftSideIndex, int rightSideIndex);
    void createAssignment(int leftSideIndex, int rightSideIndex);
    string getAddressOrIdIfNumber(Symbol symbol);
    void createMethodInMemoryAndDumpSymTable(int methodIndex, int _methodToken);
    void fillFunctionReturnType(int functionIndex, int _returnType);
    
    int createCallMethod(Symbol method);
    void createTempParameterIfNumber(Symbol& parameter, Type parameterType);
    int pushReturnTempIfFunction(Symbol method, int& incsp);
    void validNoArgsMethod(Symbol method);
    bool isSupportedMethod(string methodName);

    void createRelopJump(int _relopToken, int leftSideIndex, int rightSideIndex, string label);
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
%token MOD
%token AND

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
    subprogram_declarations subprogram_declaration ';'
    |
    ;

subprogram_declaration:
    subprogram_head declarations compound_statement {
        isGlobal = true;
        displayLabel(actualMethodLabel);
        displayEnter(symTable.getLocalLastAddress());
        displayLocalFromBuffer();
        displaySubprogramEnd();
        symTable = dumpedTable.deepCopy();
    }
    ;

subprogram_head:
    FUNCTION ID {
        createMethodInMemoryAndDumpSymTable($2, FUNCTION);
    }
    arguments ':' standard_type ';' {
        fillFunctionReturnType($2, $7);
    }
    |
    PROCEDURE ID {
        createMethodInMemoryAndDumpSymTable($2, PROCEDURE);
    }
    arguments ';'
    ;

arguments:
    '(' parameter_list ')' {
        fillParameters();
    }
    |
    ;

 parameter_list:
     identifier_list ':' type {
        addParameters($3);
    }
    |
    parameter_list ';' identifier_list ':' type {
        addParameters($5);
    }
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
    IF expression {
        elseLabel = getNextLabel();
        int falseValue = symTable.insertIfNotExist("0", NUMBER, Type::Integer);
        //je - jump to else if expression is false
        createRelopJump(EQ, $2, falseValue, elseLabel);
    } THEN statement {
        afterIf = getNextLabel();
        displayJump(afterIf);
        displayLabel(elseLabel);
    } ELSE statement {
        displayLabel(afterIf);
        // elseLabel = "";
        // afterIf = "";
    }
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
        validNoArgsMethod(method);
        
        if(method.token == FUNCTION) {
            $$ = createCallMethod(method);
        } else if (method.token == PROCEDURE) {
            createCallMethod(method);
        } else {
            cout << method.id << " is not procedure or function" << endl;
        }
    }
    |
    ID '(' expression_list ')' {
        Symbol method = symTable.get($1);
        
        if(isSupportedMethod(method.id)) {
            Symbol methodSymbol = symTable.get(identifiersVector.back());
            displaySupportedMethod(method.id, methodSymbol.type, getAddressOrIdIfNumber(methodSymbol));
        } else if (method.token == FUNCTION) {
            $$ = createCallMethod(method);
        } else if (method.token == PROCEDURE) {
            createCallMethod(method);
        } else {
            cout << method.id << " is not procedure or function" << endl;
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
    simple_expression RELOP simple_expression {
        string labelTrue = getNextLabel();
        createRelopJump($2, $1, $3, labelTrue);

        Symbol relopResult = symTable.insertTemp(Type::Integer);
        int falseValue = symTable.insertIfNotExist("0", NUMBER, Type::Integer);
        createAssignment(symTable.find(relopResult.id), falseValue);

        string labelEndRelop = getNextLabel();
        displayJump(labelEndRelop);
        displayLabel(labelTrue);

        int trueValue = symTable.insertIfNotExist("1", NUMBER, Type::Integer);
        createAssignment(symTable.find(relopResult.id), trueValue);
        displayLabel(labelEndRelop);

        $$ = symTable.find(relopResult.id);
    }
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
    simple_expression OR term {
        $$ = createExpression(OR, $1, $3);
    }
    ;

term:
    factor
    |
    term MULOP factor {
        $$ = createExpression($2, $1, $3);
    }
    ;

factor:
    variable {
        int variableIndex = $1;
        Symbol function = symTable.get($1);
        if (function.token == FUNCTION) {
            validNoArgsMethod(function);

            int incsp = 0;
            variableIndex = pushReturnTempIfFunction(function, incsp);

            displayMethod(MethodType::Call, function.id);
            if (incsp != 0) {
                displayIncsp(incsp);
            }
        } else if (function.token == PROCEDURE) { 
            cout << "Procedure can't return value" << endl;
            throw exception();
        }
        $$ = variableIndex;
    }
    |
    ID '(' expression_list ')' {
        Symbol function = symTable.get($1);
        if (function.token != FUNCTION) {
            cout << function.id << " is not a function" << endl;
            throw exception();
        }
        $$ = createCallMethod(function);
        identifiersVector.clear();
    }
    |
    NUMBER
    |
    '(' expression ')' {
        $$ = $2;
    }
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
    string tempValue = getAddressOrIdIfNumber(temp);
    
    displayCast(symbol.type, value, tempValue);
    return temp;
}

void addParameters(int type_) {
    for (auto &identifier: identifiersVector) {
        symTable.get(identifier).reference = true;
        fillSymbolIfTypeIsKnown(identifier, type_);
        parameterVector.push_back(identifier);
    }
    identifiersVector.clear();
}

void fillParameters() {
    Symbol& method = symTable.get(actualMethodLabel);
    Symbol& dumpedMethod = dumpedTable.get(actualMethodLabel);
    reverse(begin(parameterVector), end(parameterVector));
    for (auto &parameterIndex: parameterVector) {
        Symbol& parameter = symTable.get(parameterIndex);
        parameter.address = method.argumentsAddress;
        method.argumentsAddress += 4;
        
        method.arguments.insert(
            method.arguments.begin(), parameter.type);
        dumpedMethod.arguments.insert(
            dumpedMethod.arguments.begin(), parameter.type); //need this information after reset symTable
        // method.arguments.push_back(parameter.type);
        // dumpedMethod.arguments.push_back(parameter.type); //need this information after reset symTable
    }
    parameterVector.clear();
}

int createExpression(int op, int leftSideIndex, int rightSideIndex) {
    Symbol leftSide = symTable.get(leftSideIndex);
    Symbol rightSide = symTable.get(rightSideIndex);
    castTypeIfNeeded(leftSide, rightSide);

    int resultIndex = symTable.insertTempReturnIndex(leftSide.type);
    Symbol resultSymbol = symTable.get(resultIndex);
    
    string lhs = getAddressOrIdIfNumber(leftSide);
    string rhs = getAddressOrIdIfNumber(rightSide);
    string dst = getAddressOrIdIfNumber(resultSymbol);
    displayAddop(op, resultSymbol.type, lhs, rhs, dst);
    
    return resultIndex;
}

void createAssignment(int leftSideIndex, int rightSideIndex) {
    Symbol leftSide = symTable.get(leftSideIndex);
    Symbol rightSide = symTable.get(rightSideIndex);

    castTypeForAssignmentIfNeeded(leftSide, rightSide);
    string movedValue = getAddressOrIdIfNumber(rightSide);
    string leftSideValue = getAddressOrIdIfNumber(leftSide);
    
    displayMov(leftSide.type, movedValue, leftSideValue);
}

string getAddressOrIdIfNumber(Symbol symbol) {
    return symbol.token == NUMBER
        ? "#" + symbol.id
        : (symbol.global && symbol.token != FUNCTION
            ? to_string(symbol.address)
            : (symbol.reference
                ? "*BP+" + to_string(symbol.address)
                : "BP" + to_string(symbol.address)));
}

string getPushAddress(Symbol symbol) {
    return symbol.global
        ? "#" + to_string(symbol.address)
        : symbol.reference
            ? "BP+" + to_string(symbol.address)
            : "#BP" + to_string(symbol.address);
}

void createMethodInMemoryAndDumpSymTable(int methodIndex, int _methodToken) {
    isGlobal = false;

    Symbol& method = symTable.get(methodIndex);
    method.token = _methodToken;
    method.global = true;
    if (method.token == FUNCTION) {
        method.address = 8;
        method.reference = true;
        method.argumentsAddress = 12;
    } else if (method.token == PROCEDURE) {
        method.argumentsAddress = 8;
    }

    dumpedTable = symTable.deepCopy();

    actualMethodLabel = method.id;
}

void fillFunctionReturnType(int functionIndex, int _returnType) {
    Symbol& function = symTable.get(functionIndex);
    Symbol& dumpFunction = dumpedTable.get(functionIndex);
    if (_returnType == INTEGER) {
        function.type = Type::Integer;
        dumpFunction.type = Type::Integer;
    } else if (_returnType == REAL) {
        function.type = Type::Real;
        dumpFunction.type = Type::Real;
    } else {
        cout << "Unsupported return type for " << function.id << " function" << endl;
        throw exception();
    }
}

int createCallMethod(Symbol method) {
    if (method.arguments.size() != identifiersVector.size()) {
        cout << "Function or procedure does not have enough arguments (name: " << method.id << ")" << endl;
        throw exception();
    }
    int incsp = 0;
    for (int i = 0; i < identifiersVector.size(); ++i) {
        Type type = method.arguments[i];
        Symbol parameter = symTable.get(identifiersVector[i]);

        if (type != parameter.type) {
            cout << "Method " << method.id
            << " has invalid type of " << i << "  parameter" << endl;
        }

        createTempParameterIfNumber(parameter, type);

        string pushAddress = getPushAddress(parameter);
        displayPush(pushAddress);
        incsp += 4;
    }

    int returnIndex = pushReturnTempIfFunction(method, incsp);

    displayMethod(MethodType::Call, method.id);
    if (incsp != 0) {
        displayIncsp(incsp);
    }

    return returnIndex;
}

void createTempParameterIfNumber(Symbol& parameter, Type parameterType) {
    if (parameter.token == NUMBER) {
        Symbol temp = symTable.insertTemp(parameterType);
        string leftValue = getAddressOrIdIfNumber(parameter);
        string rightValue = getAddressOrIdIfNumber(temp);

        displayMov(parameter.type, leftValue, rightValue);

        parameter = temp;
    }
}

int pushReturnTempIfFunction(Symbol method, int& incsp) {
    if (method.token == FUNCTION) {
        Symbol returnTemp = symTable.insertTemp(method.type);
        string pushAddress = getPushAddress(returnTemp);
        displayPush(pushAddress);
        incsp += 4;
        return symTable.find(returnTemp.id);
    }
    return 0;
}

void validNoArgsMethod(Symbol method) {
    if (method.token == FUNCTION || method.token == PROCEDURE) {
        if (method.arguments.size() > 0) {
            cout << "Function or procedure has arguments (name: " << method.id << ")" << endl;
            throw exception();
        }
    }
}

bool isSupportedMethod(string methodName) {
    return find(
        supportedMethods.begin(),
        supportedMethods.end(),
        methodName) != supportedMethods.end();
}

void createRelopJump(int _relopToken, int leftSideIndex, int rightSideIndex, string label) {
    Symbol leftSymbol = symTable.get(leftSideIndex);
    Symbol rightSymbol = symTable.get(rightSideIndex);

    castTypeIfNeeded(leftSymbol, rightSymbol);

    string leftValue = getAddressOrIdIfNumber(leftSymbol);
    string rightValue = getAddressOrIdIfNumber(rightSymbol);

    displayRelopJump(_relopToken, leftSymbol.type, leftValue, rightValue, label);
}