{-# LANGUAGE DeriveFunctor #-}

module Compiler.Type.DSL.Statement where

import Compiler.Class.Serializable
import Compiler.Type.Symbol
import Compiler.Type.DSL.Expression

--------------------------------------------------------------------------------
-- Statement

data Statement a = Assignment a (Expression a)
                 | Return (Expression a)
                 | Invocation a [Expression a]
                 | Compound [Statement a]
                 | Branch (Expression a) (Statement a) (Statement a)
                 | Loop (Expression a) (Statement a)
                 deriving Functor

instance (Serializable a, Sym a) => Serializable (Statement a) where
    serialize (Assignment v e) = serialize v ++ " := " ++ serialize e
    serialize (Return e) = "return " ++ serialize e
    serialize (Invocation sym []) = serialize sym
    serialize (Invocation sym exprs) = serialize sym ++ "(" ++ exprs' ++ ")"
        where   exprs' = intercalate' ", " exprs
    serialize (Compound stmts) = paragraph $ compound stmts
    serialize (Branch e s t) = paragraph $
            0 >>>> ["if " ++ serialize e]
        ++  1 >>>> ["then " ++ serialize s]
        ++  1 >>>> ["else " ++ serialize s]
    serialize (Loop e s) = paragraph $
            0 >>>> ["while " ++ serialize e ++ " do"]
        ++  1 >>>> [s]
