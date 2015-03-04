module Compiler where

import Compiler.Syntax.Lexer
import Compiler.Syntax.Parser
import Compiler.Class.Serializable
import Compiler.Pipeline

main :: IO ()
main = pipeline $ do
    readSource "./test/semantics/test.p"
        >>= scan
        >>= parse
        >>= checkBinding
        >>= checkType
        >>= draw
