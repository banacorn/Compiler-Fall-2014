{-# LANGUAGE DeriveFunctor #-}

module Compiler.AST.Type.Raw where

import Compiler.Serializable
import Compiler.AST.Type.Expression
import Compiler.AST.Type.Statement
import Compiler.AST.Type.Symbol

--------------------------------------------------------------------------------
-- Raw Abstract Syntax Tree

-- Program Declaration
data RawProgram = RawProgram
    Symbol          -- program name
    [Symbol]        -- program arguments
    [VarDec]        -- variable declarations
    [RawSubprogram]    -- subprogram declarations
    [Statement Symbol] -- compound statement

instance Serializable RawProgram where
    serialize (RawProgram sym params vars subprogs stmts) = paragraph $
            0 >>>> [header]
        ++  1 >>>> vars
        ++  1 >>>> subprogs
        ++  1 >>>> compound stmts
        where
            header = "program " ++ getID sym ++ "(" ++ paramList ++ ") ;"
            paramList = intercalate' ", " (map getID params)

-- Type
data RawType = RawIntType | RawRealType | RawVoidType

instance Serializable RawType where
    serialize RawIntType = "int"
    serialize RawRealType = "real"
    serialize RawVoidType = "void"


-- Variable & Parameter Declaration
data VarDec = VarDec [Symbol] RawType
data Parameter = Parameter [Symbol] RawType

instance Serializable VarDec where
    serialize (VarDec [] _) = ""
    serialize (VarDec syms t) =
        "var " ++ ids ++ " : " ++ serialize t ++ ";"
        where
            ids = intercalate' ", " (map getID syms)

instance Serializable Parameter where
    serialize (Parameter syms t) = ids ++ ": " ++ serialize t
        where   ids = intercalate' ", " (map getID syms)


-- Subprogram Declaration
data RawSubprogram = FuncDec
    Symbol          -- function name
    [Parameter]     -- function parameters
    RawType    -- function return type
    [VarDec]        -- variable declarations
    [Statement Symbol]    -- compound statement

instance Serializable RawSubprogram where
    -- function, no parameter
    serialize (FuncDec sym [] typ vars stmts) = paragraph $
            0 >>>> ["function " ++ getID sym ++ " : " ++ serialize typ ++ ";"]
        ++  1 >>>> vars
        ++  1 >>>> compound stmts
    -- function, with parameters
    serialize (FuncDec sym params typ vars stmts) = paragraph $
            0 >>>> ["function " ++ getID sym ++ "(" ++ paramList ++ "): " ++ serialize typ ++ ";"]
        ++  1 >>>> vars
        ++  1 >>>> compound stmts
        where   paramList = intercalate' ", " params
