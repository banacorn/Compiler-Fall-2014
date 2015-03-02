module Compiler.Type.Type where

import Compiler.Type.Token
import Compiler.Class.Serializable

import Data.List (intercalate)
import Data.Monoid

-- first order
data Domain = IntegerType
            | RealType
            | StringType
            | ArrayType (String, String) Domain
            | ProgramParamType
            | UnitType                          -- ()
            deriving (Eq)

data Type = Type [Domain] deriving (Eq)

instance Serializable Domain where
    serialize IntegerType = "Int"
    serialize RealType = "Real"
    serialize StringType = "String"
    serialize (ArrayType (from, to) t) = "Array [" ++ from ++ " .. " ++ to ++"] " ++ serialize t
    serialize ProgramParamType = "ProgArg"
    serialize UnitType = "()"

instance Serializable Type where
    serialize (Type domains) = intercalate " → " (map serialize domains)

instance Monoid Type where
    mempty = Type []
    mappend (Type a) (Type b) = Type (a ++ b)

order :: Type -> Int
order (Type domains) = length domains

firstOrder :: Type -> Bool
firstOrder = (== 1) . order

higherOrder :: Type -> Bool
higherOrder = (> 1) . order
