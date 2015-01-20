{
module Compiler.Parser where
import Compiler.Type
import Compiler.Lexer
import Control.Monad.Except
}

%name parse
%tokentype { Token }
%monad { Pipeline } { >>= } { return }
%error { parseError }

%token
    '('             { Token TokLParen _ }
    ')'             { Token TokRParen _ }
    ';'             { Token TokSemicolon _ }
    ':'             { Token TokColon _ }
    '.'             { Token TokPeriod _ }
    ','             { Token TokComma _ }
    '['             { Token TokLSB _ }
    ']'             { Token TokRSB _ }
    id              { Token (TokID _) _ }
    num             { Token (TokNum $$) _ }
    string          { Token TokTypeStr _ }
    integer         { Token TokTypeInt _ }
    real            { Token TokTypeReal _ }
    progtok         { Token TokProgram _ }
    function        { Token TokFunction _ }
    procedure       { Token TokProc _ }
    begin           { Token TokBegin _ }
    end             { Token TokEnd _ }
    var             { Token TokVar _ }
    array           { Token TokArr _ }
    of              { Token TokOf _ }
    if              { Token TokIf _ }
    then            { Token TokThen _ }
    else            { Token TokElse _ }
    while           { Token TokWhile _ }
    do              { Token TokDo _ }
    ':='            { Token TokAssign _ }
    '<'             { Token TokS _ }
    '>'             { Token TokL _ }
    '<='            { Token TokSE _ }
    '>='            { Token TokLE _ }
    '='             { Token TokEq _ }
    '!='            { Token TokNEq _ }
    '+'             { Token TokPlus _ }
    '-'             { Token TokMinus _ }
    '*'             { Token TokTimes _ }
    '/'             { Token TokDiv _ }
    not             { Token TokNot _ }
    '..'            { Token TokTo _ }

%%


program
    : progtok id '(' identifier_list ')' ';' variable_declarations subprogram_declarations compound_statement '.' {
        ProgramNode (toSym $2) (reverse $4) (reverse $7) (reverse $8) (CompoundStmtNode $9)
    }


identifier_list
    : id                            { toSym $1 : [] }
    | identifier_list ',' id        { toSym $3 : $1 }


variable_declarations
    : {- empty -}                                               { [] }
    | variable_declarations var identifier_list ':' type ';'    { VarDecNode (reverse $3) $5 : $1 }


type
    : standard_type                          { BaseTypeNode $1 }
    | array '[' num '..' num ']' of type     { ArrayTypeNode ($3, $5) $8 }


standard_type
    : integer       { IntTypeNode }
    | real          { RealTypeNode }
    | string        { StringTypeNode }


subprogram_declarations
    : {- empty -}                                           { [] }
    | subprogram_declarations subprogram_declaration ';'    { $2 : $1 }


subprogram_declaration
    : function id ':' standard_type ';' variable_declarations compound_statement
        { FuncDecNode (toSym $2) [] $4 $6 (CompoundStmtNode $7) }
    | function id '(' parameter_list ')' ':' standard_type ';' variable_declarations compound_statement
        { FuncDecNode (toSym $2) $4 $7 $9 (CompoundStmtNode $10) }
    | procedure id ';' variable_declarations compound_statement
        { ProcDecNode (toSym $2) [] $4 (CompoundStmtNode $5) }
    | procedure id '(' parameter_list ')' ';' variable_declarations compound_statement
        { ProcDecNode (toSym $2) $4 $7 (CompoundStmtNode $8) }

parameter_list
    : identifier_list ':' type                      { ParameterNode $1 $3 : [] }
    | parameter_list ';' identifier_list ':' type   { ParameterNode $3 $5 : $1  }


compound_statement
    : begin statement_list end  { reverse $2 }

statement_list
    : {- empty -}                   { [] }
    | statement                     { [$1] }
    | statement_list ';' statement  { $3 : $1 }


statement
    : variable ':=' expression                      { AssignStmtNode $1 $3 }
    | id                                            { SubprogInvokeStmtNode (toSym $1) [] }
    | id '(' expression_list ')'                    { SubprogInvokeStmtNode (toSym $1) $3 }
    | compound_statement                            { CompStmtNode (CompoundStmtNode $1) }
    | if expression then statement else statement   { BranchStmtNode $2 $4 $6 }
    | while expression do statement                 { LoopStmtNode $2 $4 }


variable
    : id tail  { VariableNode (toSym $1) $2 }

tail
    : {- empty -}                   { [] }
    | '[' expression ']' tail       { $2 : $4 }

expression_list : expression                        { $1 : [] }
                | expression_list ',' expression    { $3 : $1 }


expression
    : simple_expression                         { UnaryExprNode $1 }
    | simple_expression relop simple_expression { BinaryExprNode $1 $2 $3 }


simple_expression
    : term                              { SimpleExprTermNode $1 }
    | simple_expression addop term      { SimpleExprOpNode $1 $2 $3 }


term
    : factor            { FactorTermNode $1 }
    | '-' factor        { NegTermNode $2  }
    | term mulop factor { OpTermNode $1 $2 $3 }


factor
    : id tail                       { ArrayAccessFactorNode (toSym $1) $2 }
    | id '(' expression_list ')'    { SubprogInvokeFactorNode (toSym $1) $3 }
    | num                           { NumFactorNode $1 }
    | '(' expression ')'            { SubFactorNode $2 }
    | not factor                    { NotFactorNode $2 }


addop
    : '+'   { Plus }
    | '-'   { Minus }


mulop
    : '*'   { Mul }
    | '/'   { Div }



relop
    : '<'   { S }
    | '>'   { L }
    | '='   { E }
    | '<='  { SE }
    | '>='  { LE }
    | '!='  { NE }

{
parseError :: [Token] -> Pipeline a
parseError tokens = throwError (SyntaxErrorClass (maybeHead tokens))
    where   maybeHead [] = Nothing
            maybeHead (x:_) = Just x
}
