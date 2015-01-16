module Compiler.Pipeline where

import Compiler.Type
import Compiler.Class.Serializable

import Control.Exception (try, IOException)
import Control.Monad.Except
import Control.Monad.State
import Data.Maybe (fromJust)
import Data.List (intercalate)
import System.Environment (getArgs)
import System.Console.ANSI

getPath :: Pipeline String
getPath = do
    args <- liftIO getArgs
    case args of
        []      -> throwError $ FileError "no input file"
        (x:_)   -> return x


testWithSource :: String -> Pipeline String
testWithSource input = do
    put (FileState (Just input) "interactive")
    return input

-- read source from file
-- Exception: throws FileError if file not found
-- State: saves source if possible
readSource :: String -> Pipeline String
readSource path = do
    result <- liftIO $ try (readFile path) :: Pipeline (Either IOException String)
    case result of
        Left  _ -> throwError $ FileError path
        Right s -> do
            put (FileState (Just s) path)
            return s

handleError :: Pipeline a -> IO ()
handleError f = do
    (result, FileState source path) <- runStateT (runExceptT f) NoFileState
    case result of
        Left    err -> case err of
            FileError path -> do
                putStrLn $ paintError "[File Error]"
                putStrLn $ "Input file " ++ paintWarn path ++ " does not exists"
            ParseError Nothing -> do
                putStrLn $ paintError "[Syntax Error]" ++ " " ++ path ++ printPos Unknown ++ "\n"
                    ++ "Unable to parse, not enough input"
            ParseError (Just (Token (TokError tok) pos)) -> do
                putStrLn $ paintError "[Syntax Error]" ++ " " ++ path ++ printPos pos ++ "\n"
                    ++ "Unrecognizable token "
                    ++ paintWarn (serialize tok)
                printSyntaxError (fromJust source) pos
            ParseError (Just (Token tok pos)) -> do
                putStrLn $ paintError "[Syntax Error]" ++ " " ++ path ++ printPos pos ++ "\n"
                    ++ "Unable to parse "
                    ++ paintWarn (serialize tok)
                printSyntaxError (fromJust source) pos
            SemanticsError _ -> print err

        Right   src -> return ()

    where
        printPos (Position o n l c) = ":" ++ show l ++ ":" ++ show c ++ ":"
        printPos Unknown = ""
        paintError s = setSGRCode [SetColor Foreground Vivid Red] ++ s ++ setSGRCode []
        paintWarn s = setSGRCode [SetColor Foreground Vivid Yellow] ++ s ++ setSGRCode []


printSyntaxError :: String -> Position -> IO ()
printSyntaxError source (Position offset len l c) = do
    putStrLn ""
    putStrLn (unlines $ zipWith addLineNo lineNos reportLines)
    where   lineNo = l - 1
            columnNo = c - 1

            sourceBeforeError = take offset source
            sourceError = take len (drop offset source)
            sourceAfterError = drop len (drop offset source)
            source' = sourceBeforeError ++ paintError sourceError ++ sourceAfterError
            sourceLines = lines source'
            rangeFrom = (lineNo - 2) `max` 0
            rangeTo = (lineNo + 2) `min` length sourceLines
            reportLines = take (rangeTo - rangeFrom + 1) (drop rangeFrom sourceLines)
            leftPadding s = let s' = show s
                                w = length s'
                            in  replicate (length (show (rangeTo + 1)) - w) ' ' ++ s'
            lineNos = map (paintLineNo . leftPadding) [rangeFrom + 1 .. rangeTo + 1]
            addLineNo n l = n ++ " " ++ l


            paintError s = setSGRCode [SetColor Foreground Vivid Yellow] ++ s ++ setSGRCode []
            paintLineNo s = setSGRCode [SetColor Foreground Vivid Green] ++ s ++ setSGRCode []


-- main :: IO ()
-- main = do
--     source <- testOne
--     let parseTree = parse (scan source)
--     print parseTree
--     draw . head $ getScope parseTree
--     draw parseTree
--
draw :: Serializable a => a -> Pipeline ()
draw = liftIO . putStrLn . serialize
