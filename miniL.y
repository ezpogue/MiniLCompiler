
%{
#include <stdio.h>
#include <stdlib.h>
void yyerror(const char *msg);
extern int currLine;
extern int currPos;
FILE * yyin;
%}

%union{
  int		num_val;
  char*		id_val;
}

%error-verbose
%start	program 

%token  FUNCTION BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY INTEGER ARRAY ENUM OF IF THEN ENDIF ELSE WHILE FOR DO BEGINLOOP ENDLOOP CONTINUE READ WRITE TRUE FALSE SEMICOLON COLON COMMA L_PAREN R_PAREN L_SQUARE_BRACKET R_SQUARE_BRACKET ASSIGN RETURN
%token  <id_val> IDENT
%token  <num_val> NUMBER
%left   ADD SUB MOD
%left   MULT DIV 
%left	LT LTE GT GTE EQ NEQ
%right	NOT
%left 	AND OR
%right 	ASSIGN	

%%

program:            functions {printf("program -> functions\n");}
	;

functions:          /*empty*/ {printf("functions -> epsilon\n");}	
    |               function functions {printf("functions -> function functions\n");}
    ;

function:	        FUNCTION identifier SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY {printf("function -> FUNCTION identifier SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY\n");}
    ;

declarations:       /*empty*/ {printf("declarations -> epsilon\n");}
    |               declaration SEMICOLON declarations {printf("declarations -> declaration SEMICOLON declarations\n");} 
    ;

declaration:        identifiers COLON ENUM L_PAREN identifiers R_PAREN {printf("declaration -> identifiers COLON ENUM L_PAREN identifiers R_PAREN\n");}
	|               identifiers COLON INTEGER {printf("declaration -> identifiers COLON INTEGER\n");}
	|               identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER {printf("declaration -> COLON ARRAY L_SQUARE_BRACKET NUMBER %d R_SQUARE_BRACKET OF INTEGER\n", $5);}
    ;

statements: 	    statement SEMICOLON statements {printf("statements -> statement SEMICOLON statements\n");}
	|               statement SEMICOLON {printf("statements -> statement SEMICOLON\n");}
    ;

statement:	        var ASSIGN expression {printf("statement -> var ASSIGN expression\n");}
    |               IF boolexpr THEN statements ENDIF {printf("statement -> IF boolexpr THEN statements ENDIF\n");}
    |               IF boolexpr THEN statements ELSE statements ENDIF {printf("statement -> IF boolexpr THEN statements ELSE statements ENDIF\n");}
	|               WHILE boolexpr BEGINLOOP statements ENDLOOP {printf("statement -> WHILE boolexpr BEGINLOOP statements ENDLOOP\n");}
    |               DO BEGINLOOP statements ENDLOOP WHILE boolexpr {printf("statement -> DO BEGINLOOP statements ENDLOOP WHILE boolexpr\n");}
    |               READ vars {printf("statement -> READ vars\n");}
    |               WRITE vars {printf("statement -> WRITE vars\n");}
    |               CONTINUE {printf("statement -> CONTINUE\n");}
    |               RETURN expression {printf("statement -> RETURN expression\n");}
    ;

boolexpr: 	        relationandexpr {printf("boolexpr -> relationandexpr\n");}
	|               relationandexpr OR boolexpr {printf("boolexpr -> relationandexpr OR boolexpr\n");}
	;

relationandexpr:	relationexpr {printf("relationandexpr → relationexpr\n");}
	|               relationexpr AND relationandexpr {printf("relationandexpr -> relationexpr AND relationandexpr\n");}
	;

relationexpr:	    expression comp expression {printf("relationexpr -> expression comp expression\n");}
    |               TRUE {printf("relationexpr -> TRUE\n");}
    |               FALSE {printf("relationexpr -> FALSE\n");}
    |               L_PAREN boolexpr R_PAREN {printf("relationexpr -> L_PAREN boolexpr R_PAREN\n");}
    |               NOT expression comp expression {printf("relationexpr -> NOT expression comp expression\n");}
    |               NOT TRUE {printf("relationexpr -> NOT TRUE\n");}
    |               NOT FALSE {printf("relationexpr -> NOT FALSE\n");}
    |               NOT L_PAREN boolexpr R_PAREN {printf("relationexpr -> NOT L_PAREN boolexpr R_PAREN\n");}
    ;
    
comp:		        EQ {printf("comp -> EQ\n");}
    |               NEQ {printf("comp -> NEQ\n");}
	|               GT {printf("comp -> GT\n");}
    |               LT {printf("comp -> LT\n");}
	|               GTE {printf("comp -> GTE\n");}
    |               LTE {printf("comp -> LTE\n");}
	;
  
vars:               var {printf("vars -> var\n");}
    |               var COMMA vars {printf("vars -> var COMMA vars\n");}
    ;

identifiers:        identifier COMMA identifiers {printf("identifiers -> identifier COMMA identifiers\n");}
    |               identifier {printf("identifiers -> identifier\n");}
    ;

identifier:         IDENT {printf("identifier -> IDENT %s\n", $1);}
    ;

expression:         multexpr {printf("expression -> multexpr\n");}
    |               multexpr ADD expression {printf("expression -> multexpr ADD expression\n");}
    |               multexpr SUB expression {printf("expression -> multexpr SUB expression\n");}
    ;

multexpr:           term {printf("multexpr -> term\n");}
    |               term MULT multexpr {printf("multexpr -> term MULT multexpr\n");}
    |               term DIV multexpr {printf("multexpr -> term DIV multexpr\n");}
    |               term MOD multexpr {printf("multexpr -> term MOD multexpr\n");}
    ;

term:               var {printf("term -> var\n");}
    |               SUB var {printf("term -> SUB var\n");}
    |               NUMBER {printf("term -> NUMBER %d\n", $1);}
    |               SUB NUMBER {printf("term -> SUB NUMBER %d\n", $2);}
    |               L_PAREN expression R_PAREN {printf("term -> L_PAREN expression R_PAREN\n");}
    |               SUB L_PAREN expression R_PAREN {printf("term -> SUB L_PAREN expression R_PAREN\n");}
    |               identifier L_PAREN expressions R_PAREN {printf("term -> identifier L_PAREN expressions R_PAREN\n");}
    ;

var:                identifier {printf("var -> identifier\n");}
    |               identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET {printf("var -> identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET\n");}
    ;
  
expressions:        /*empty*/ {printf("expressions -> epsilon\n");}
    |               expression {printf("expressions -> expression\n");}
    |               expression COMMA expressions {printf("expressions -> expression COMMA expressions\n");}
    ;
%% 

int main(int argc, char **argv) {
  if (argc >= 2){
      yyin = fopen(argv[1], "r");
      if(yyin == NULL){
         yyin = stdin;
      }
   }
   else
      yyin = stdin;
  yyparse();
  return 0;
}

void yyerror(const char *msg) {
    printf("** Line %d, position %d: %s\n", currLine, currPos, msg);
}
