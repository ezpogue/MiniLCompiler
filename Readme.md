MiniL "Compiler"
========================================

This is a 3 step compiler for the "MiniL" language, written for the project portion of CS152 Compilers. 

The compiler takes a MiniL file as input. It checks it for lexical errors while tokenizing the program, then checks for semantic errors while converting it into a parse tree. Finally, it uses the generated parse tree to output MIL intermediate code. This intermediate code can be run using the interpreter provided by the instructor.

This compiler utilizes the tools Bison and Lex for the semantic and lexical analysis respectively.
