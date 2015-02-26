module Compiler.Class.Scope where

import Compiler.Type
import Compiler.Class.Type

--------------------------------------------------------------------------------
-- helper functions

toSymbol :: Type -> (String, Position) -> Symbol
toSymbol t (i, p) = Symbol t i p

--------------------------------------------------------------------------------
-- Class & Instances of HasScope

class HasScope a where
    getScope :: a -> Scope

instance HasScope ProgramNode where
    getScope p@(ProgramNode sym _ _ subprogs stmts) = Scope scopeType scopes vars
        where
            scopeType = ProgramScope (fst sym)
            vars = getDeclaration p
            scopes = map getScope subprogs ++ [getScope stmts]

instance HasScope SubprogDecNode where
    getScope p@(FuncDecNode sym _ _ _ stmts) = Scope scopeType scopes vars
        where
            scopeType = RegularScope (toSymbol (getType p) sym)
            vars = getDeclaration p
            scopes = [getScope stmts]
    getScope p@(ProcDecNode sym _ _ stmts) = Scope scopeType scopes vars
        where
            scopeType = RegularScope (toSymbol (getType p) sym)
            vars = getDeclaration p
            scopes = [getScope stmts]

instance HasScope CompoundStmtNode where
    getScope p@(CompoundStmtNode stmts) = Scope CompoundStmtScope [] []

--------------------------------------------------------------------------------
-- Class & Instances of HasDeclaration

class HasDeclaration a where
    getDeclaration :: a -> [Symbol]

instance HasDeclaration ProgramNode where
    getDeclaration (ProgramNode _ params vars subprogs _) =
        (params   >>= fromParams) ++
        (vars     >>= fromVars) ++
        (subprogs >>= fromSubprogs)
        where
            fromParams n = [toSymbol (FO ProgramParamType) n]
            fromVars (VarDecNode ids t) = map (toSymbol (getType t)) ids
            fromSubprogs n@(FuncDecNode sym _ ret _ _) = [toSymbol (getType n) sym]
            fromSubprogs n@(ProcDecNode sym _     _ _) = [toSymbol (getType n) sym]

instance HasDeclaration SubprogDecNode where
    getDeclaration (FuncDecNode sym params ret vars stmt) =
        (params >>= fromParams) ++
        (vars >>= fromVars)
        where
            fromParams (ParameterNode ids t) = map (toSymbol (getType t)) ids
            fromVars (VarDecNode ids t) = map (toSymbol (getType t)) ids
    getDeclaration (ProcDecNode sym params vars stmt) =
        (params >>= fromParams) ++
        (vars >>= fromVars)
        where
            fromParams (ParameterNode ids t) = map (toSymbol (getType t)) ids
            fromVars (VarDecNode ids t) = map (toSymbol (getType t)) ids
