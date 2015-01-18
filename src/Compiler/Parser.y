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
        ProgramNode (toSym $2) (reverse $4) (reverse $7) (reverse $8) $9
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
    : subprogram_head variable_declarations compound_statement { SubprogDec $1 $2 $3 }

subprogram_head
    : function id ':' standard_type ';'                         { SubprogHeadFunc (toSym $2) [] $4 }
    | function id '(' parameter_list ')' ':' standard_type ';'  { SubprogHeadFunc (toSym $2) $4 $7 }
    | procedure id ';'                                          { SubprogHeadProc (toSym $2) []}
    | procedure id '(' parameter_list ')' ';'                   { SubprogHeadProc (toSym $2) $4}

parameter_list
    : identifier_list ':' type                      { ParameterNode $1 $3 : [] }
    | parameter_list ';' identifier_list ':' type   { ParameterNode $3 $5 : $1  }


compound_statement
    : begin statement_list end  { CompoundStmt (reverse $2) }

statement_list
    : {- empty -}                   { [] }
    | statement                     { [$1] }
    | statement_list ';' statement  { $3 : $1 }


statement
    : variable ':=' expression                      { VarStmtNode $1 $3 }
    | procedure_statement                           { ProcStmtNode $1 }
    | compound_statement                            { CompStmtNode $1 }
    | if expression then statement else statement   { BranchStmtNode $2 $4 $6 }
    | while expression do statement                 { LoopStmtNode $2 $4 }


variable
    : id tail  { Variable (toSym $1) $2 }

tail
    : {- empty -}                   { [] }
    | '[' expression ']' tail       { $2 : $4 }

procedure_statement
    : id                            { ProcedureStmtOnlyID (toSym $1) }
    | id '(' expression_list ')'    { ProcedureStmtWithExprs (toSym $1) $3 }

expression_list : expression                        { $1 : [] }
                | expression_list ',' expression    { $3 : $1 }


expression
    : simple_expression                         { UnaryExpr $1 }
    | simple_expression relop simple_expression { BinaryExpr $1 $2 $3 }


simple_expression
    : term                              { SimpleExprTerm $1 }
    | simple_expression addop term      { SimpleExprOp $1 $2 $3 }


term
    : factor            { FactorTerm $1 }
    | '-' factor        { NegTerm $2  }
    | term mulop factor { OpTerm $1 $2 $3 }


factor
    : id tail                       { IDSBFactor (toSym $1) $2 }
    | id '(' expression_list ')'    { IDPFactor (toSym $1) $3 }
    | num                           { NumFactor $1 }
    | '(' expression ')'            { PFactor $2 }
    | not factor                    { NotFactor $2 }


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
parseError tokens = throwError (ParseError (maybeHead tokens))
    where   maybeHead [] = Nothing
            maybeHead (x:_) = Just x
}
