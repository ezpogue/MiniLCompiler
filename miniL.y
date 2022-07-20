
%{
#define YY_NO_INPUT
#include <stdio.h>
#include <stdlib.h>
#include <map>
#include <string.h>
#include <set>

int tempCount = 0;
int labelCount = 0;
bool errorFlag = false;
char* filename = "";
extern char* yytext;
extern int currLine;
extern int currPos;
std::map<std::string, std::string> varTemp;
std::map<std::string, int> arrSize;//Keeps track of array sizes associated with 
bool mainFunc = false;//Keeps track of if main is declared or not
std::set<std::string> funcs;//Holds all function names
std::set<std::string> reserved {"FUNCTION", "BEGIN_PARAMS", "END_PARAMS", "BEGIN_LOCALS", "END_LOCALS", "BEGIN_BODY", "END_BODY", "INTEGER", "ARRAY", "ENUM", "OF", "IF", "THEN",
"ENDIF", "ELSE", "WHILE", "FOR", "DO", "BEGINLOOP", "ENDLOOP", "CONTINUE", "READ", "WRITE", "TRUE", "FALSE", "SEMICOLON", "COLON", "COMMA", "L_PAREN", "R_PAREN",
"L_SQUARE_BRACKET", "R_SQUARE_BRACKET", "ASSIGN", "RETURN", "IDENT", "NUMBER", "ADD", "SUB", "MOD", "MULT", "DIV", "LT", "LTE", "GT", "GTE", "EQ", "NEQ", "NOT", "AND", "OR",
"ASSIGN", "program", "functions", "function", "declarations", "declaration", "statements", "statement", "boolexpr", "relationandexpr", "relationexpr", "comp", "vars", "var",
"identifiers", "identifier", "expression", "multexpr", "term", "expressions"};//Holds all reserved identifiers
void yyerror(const char *msg);
int yylex();
std::string new_temp();
std::string new_label();
extern FILE * yyin;
%}

%union{
  int		num_val;
  char*		id_val;
  struct S{
      char* code;
  }statement;
  struct E{
      char* place;//Location that holds the value of E
      char* code;//Code that evaluates E
      bool arr;//Flag to show whether E is an array or not
  }expression;
}

%error-verbose
%start	program 

%token  FUNCTION BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY INTEGER ARRAY ENUM OF IF THEN ENDIF ELSE WHILE FOR DO BEGINLOOP ENDLOOP CONTINUE READ WRITE TRUE FALSE SEMICOLON COLON COMMA L_PAREN R_PAREN L_SQUARE_BRACKET R_SQUARE_BRACKET ASSIGN RETURN
%token  <id_val> IDENT
%token  <num_val> NUMBER
%type <expression> functions function declarations declaration boolexpr relationandexpr relationexpr comp vars var identifiers identifier expressions expression multexpr term
%type <statement> statements statement
%left   ADD SUB MOD
%left   MULT DIV 
%left	LT LTE GT GTE EQ NEQ
%right	NOT
%left 	AND OR
%right 	ASSIGN	

%%

program:            functions 
                    {
                        if(errorFlag){
                            exit(1);
                        }
                        else{
                            strcat(filename, ".mil");
                            FILE * output;
                            output = fopen(filename, "w");
                            if(output != NULL){
                                fputs($1.code, output);
                                fclose(output);
                            }
                        }
                    }
	  ;

functions:          /*empty*/ 
                    {
                        if(!mainFunc){
                            printf("Line %d: No main function declared", currLine);
                            errorFlag = true;
                        }
                    }	
    |               function functions 
                    {   
                        std::string temp;
                        temp.append($1.code);
                        temp.append($2.code);
                        $$.code = strdup(temp.c_str());
                    }
    ;

function:	        FUNCTION identifier SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY 
                    {
                        std::string temp = "func";
                        temp.append($2.place);
                        temp.append("\n");
                        std::string s = $2.place;
                        if (s == "main")
                            mainFunc = true;
                        funcs.insert($2.place);
                        std::string decs = $5.code;
                        int decNum = 0;
                        while(decs.find(".") != std::string::npos){
                            int pos = decs.find(".");
                            pos = decs.find(" ", pos);
                            pos++;
                            std::string ident = decs.substr(pos, (decs.find("\n", pos) - pos));
                            temp += ". " + ident + "\n";
                            temp += "= " + ident + ", $" +  std::to_string(decNum) + "\n";
                            decs = decs.substr(pos);
                            decNum++;
                        }
                        temp.append($8.code);
                        temp.append($11.code);
                        temp.append("endfunc\n");
                        if (temp.find("CONTINUE") != std::string::npos){
                            printf("Line %d: Continue used outside of loop", currLine);
                            errorFlag = true;
                        }
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup("");
                    }
    ;

declarations:       /*empty*/ 
                    {
                        $$.code = strdup("");
                        $$.place = strdup("");
                    }
    |               declaration SEMICOLON declarations 
                    {
                        std::string temp;
                        temp.append($1.code);
                        temp.append($3.code);
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup("");
                    } 
    ;

declaration:        identifiers COLON ENUM L_PAREN identifiers R_PAREN {printf("declaration -> identifiers COLON ENUM L_PAREN identifiers R_PAREN\n");}
	  |             identifiers COLON INTEGER 
                    {
                        std::string temp;
                        temp.append($1.code);
                        int pos;
                        std::string ident;
                        while(temp.find("|") != std::string::npos){
                            pos = temp.find("|");
                            temp.erase(pos, 1);
                            pos++;
                            ident = temp.substr(pos, (temp.find("\n", pos) - pos));
                            if (reserved.find(ident) != reserved.end()){
                                printf("Line %d: Invalid identifier, %s is reserved", currLine, ident.c_str());
                                errorFlag = true;
                            }
                            else if(funcs.find(ident) != funcs.end() && varTemp.find(ident) != varTemp.end()){
                                printf("Line %d: Identifier %s is doubly declared", currLine, ident.c_str());
                                errorFlag = true;
                            }
                            else {
                                varTemp[ident];
                                arrSize[ident] = 1;
                            }
                        }
                        $$.code = strdup(temp.c_str());
                    }
	  |             identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER 
                    {
                        std::string temp;
                        if($5 < 1){
                            printf("Line %d: Array cannot have size <1", currLine);
                            errorFlag = true;
                        }
                        temp.append($1.code);
                        int pos;
                        std::string ident;
                        while(temp.find("|") != std::string::npos){
                            pos = temp.find("|");
                            temp.replace(pos, 1, "[]");
                            pos += 3;
                            ident = temp.substr(pos, (temp.find("\n", pos) - pos));
                            pos = temp.find("\n", pos);
                            temp.insert(pos, ", " + std::to_string($5));
                            if (reserved.find(ident) != reserved.end()){
                                printf("Line %d: Invalid identifier, %s is reserved", currLine, ident.c_str());
                                errorFlag = true;
                            }
                            else if(funcs.find(ident) != funcs.end() && varTemp.find(ident) != varTemp.end()){
                                printf("Line %d: Identifier %s is doubly declared", currLine, ident.c_str());
                                errorFlag = true;
                            }
                            else {
                                varTemp[ident];
                                arrSize[ident] = $5;
                            }
                        }
                        $$.code = strdup(temp.c_str());
                    }
    ;

statements: 	    statement SEMICOLON statements 
                    {
                        std::string temp;
                        temp.append($1.code);
                        temp.append($3.code);
                        $$.code = strdup(temp.c_str());
                    }
  	|               statement SEMICOLON 
                    {
                        $$.code = strdup($1.code);
                    }
    ;

statement:	        var ASSIGN expression 
                    {
                        std::string temp;
                        temp.append($3.code);
                        if($1.arr)
                            temp.append("[]= ");
                        else
                            temp.append("= ");
                        temp.append($1.place);
                        temp.append(", ");
                        temp.append($3.place);
                        temp.append("\n");
                        $$.code = strdup(temp.c_str());
                    }
    |               IF boolexpr THEN statements ENDIF
                    {
                        std::string temp;
                        std::string start = new_label();
                        std::string end = new_label();
                        temp.append($2.code);
                        temp += "?:= " + start + ", " + $2.place + "\n";
                        temp += ":= " + end + "\n";
                        temp += ": " + start + "\n";
                        temp.append($4.code);
                        temp += ": " + end + "\n";
                        $$.code = strdup(temp.c_str());
                    }
    |               IF boolexpr THEN statements ELSE statements ENDIF 
                    {
                        std::string temp;
                        std::string start = new_label();
                        std::string end = new_label();
                        temp.append($2.code);
                        temp += "?:= " + start + ", " + $2.place + "\n";
			            temp.append($6.code);
                        temp += ":= " + end + "\n";
                        temp += ": " + start + "\n";
                        temp.append($4.code);
                        temp += ": " + end + "\n";
                        $$.code = strdup(temp.c_str());
                    }			
	|               WHILE boolexpr BEGINLOOP statements ENDLOOP 
                    {
                        std::string temp;
                        std::string before = new_label();
                        std::string start = new_label();
                        std::string end = new_label();
                        temp.append($2.code);
                        temp += ": " + before + "\n";
                        temp += "?:= " + start + ", " + $2.place + "\n";
                        temp += ":= " + end + "\n";
                        temp += ": " + start + "\n";
                        temp.append($4.code);
                        temp += ":= " + before + "\n";
                        temp += ": " + end + "\n";
                        while (temp.find("CONTINUE") != std::string::npos){
                            temp.replace(temp.find("CONTINUE"), 8, ":= " + before);
                        }
                        $$.code = strdup(temp.c_str());
                    }
    |               DO BEGINLOOP statements ENDLOOP WHILE boolexpr 
                    {
                        std::string temp;
                        std::string start = new_label();
                        std::string end = new_label();
                        temp.append($6.code);
                        temp += ": " + start + "\n"; 
                        temp.append($3.code);
                        temp += ": " + end + "\n"; 
                        temp += "?:= " + start + ", " + $6.place + "\n";
                        while (temp.find("CONTINUE") != std::string::npos){
                            temp.replace(temp.find("CONTINUE"), 8, ":= " + end);
                        }
                        $$.code = strdup(temp.c_str());
                    }
    |               READ vars 
                    {
                        std::string temp;
                        temp.append($2.code);
                        while(temp.find("|") != std::string::npos){
                            int pos = temp.find("|");
                            temp.replace(pos, 1, "<");
                        }
                        $$.code = strdup(temp.c_str());
                    }
    |               WRITE vars 
                    {
                        std::string temp;
                        temp.append($2.code);
                        while(temp.find("|") != std::string::npos){
                            int pos = temp.find("|");
                            temp.replace(pos, 1, "<");
                        }
                        $$.code = strdup(temp.c_str());
                    }
    |               CONTINUE 
                    {
                        std::string temp = "CONTINUE\n";
                        $$.code = strdup(temp.c_str());
                    }
    |               RETURN expression 
                    {
                        std::string temp;
                        temp.append($2.code);
                        temp.append("ret ");
                        temp.append($2.place);
                        temp.append("\n");
                        $$.code = strdup(temp.c_str()); 
                    }
    ;

boolexpr: 	        relationandexpr 
                    {
                        $$.code = strdup($1.code);
                        $$.place = strdup($1.place);
                    }
	  |             relationandexpr OR boolexpr 
                    {
                        std::string dst = new_temp();
                        std::string temp;
                        temp.append($1.code);
                        temp.append($3.code);
                        temp += ". " + dst + "\n";
                        temp += "|| " + dst + ", " + $1.place + ", " + $3.place + "\n";
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup(dst.c_str());
                    }
	  ;

relationandexpr:	relationexpr 
                    {
                        $$.code = strdup($1.code);
                        $$.place = strdup($1.place);
                    }
	  |             relationexpr AND relationandexpr 
                    {
                        std::string dst = new_temp();
                        std::string temp;
                        temp.append($1.code);
                        temp.append($3.code);
                        temp += ". " + dst + "\n";
                        temp += "&& " + dst + ", " + $1.place + ", " + $3.place + "\n";
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup(dst.c_str());
                    }
	  ;

relationexpr:	    expression comp expression
		            {
                        std::string dst = new_temp();
                        std::string temp;
                        temp.append($1.code);
                        temp.append($3.code);
                        temp += ". " + dst + "\n" + $2.place + dst + ", " + $1.place + ", " + $3.place + "\n";
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup(dst.c_str());
		            }
    |               TRUE
                    {
                        std::string temp;
                        temp.append("1");
                        $$.code = strdup("");
                        $$.place = strdup(temp.c_str());
                    }
            |       FALSE
                    {
                        std::string temp;
                        temp.append("0");
                        $$.code = strdup("");
                        $$.place = strdup(temp.c_str());
                    }
    |               L_PAREN boolexpr R_PAREN
                    {
			            $$.code = strdup($2.code);
			            $$.place = strdup($2.place);
		            }
    |               NOT expression comp expression 
                    {
                        std::string dst = new_temp();
                        std::string temp;
                        temp.append($2.code);
                        temp.append($4.code);
                        temp += ". " + dst + "\n" + $3.place + dst + ", " + $2.place + ", " + $4.place + "\n";
                        temp += "! " + dst + ", " + dst + "\n";
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup(dst.c_str());
                    }
    |               NOT TRUE 
                    {
                        std::string temp;
                        temp.append("0");
                        $$.code = strdup("");
                        $$.place = strdup(temp.c_str());
                    }
    |               NOT FALSE 
                    {
                        std::string temp;
                        temp.append("1");
                        $$.code = strdup("");
                        $$.place = strdup(temp.c_str());
                    }
    |               NOT L_PAREN boolexpr R_PAREN 
                    {
                        std::string dst = new_temp();
                        std::string temp;
                        temp.append($3.code);
                        temp += ". " + dst + "\n" + "! " + dst + ", " + $3.place + "\n";
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup(dst.c_str());
                    }
    ;
    
comp:		        EQ
		            {
			            $$.code = strdup("");
			            $$.place = strdup("== ");
		            }
    |               NEQ
                    {
                        $$.code = strdup("");
                        $$.place = strdup("!= ");
                    }
    |               GT
                    {
                        $$.code = strdup("");
                        $$.place = strdup("> ");
                    }
    |               LT
                    {
                        $$.code = strdup("");
                        $$.place = strdup("< ");
                    }
    |               GTE
                    {
                        $$.code = strdup("");
                        $$.place = strdup(">= ");
                    }
    |               LTE
                    {
                        $$.code = strdup("");
                        $$.place = strdup("<= ");
                    }

	  ;
  
vars:               var 
                    {
                        std::string temp;
                        temp.append($1.code);
                        if ($1.arr)
                            temp.append(".[]| ");
                        else
                            temp.append(".| ");
                        temp.append($1.place);
                        temp.append("\n");
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup("");
                    }
    |               var COMMA vars 
                    {
                        std::string temp;
                        temp.append($1.code);
                        if ($1.arr)
                            temp.append(".[]| ");
                        else
                            temp.append(".| ");
                        temp.append($1.place);
                        temp.append("\n");
                        temp.append($3.code);
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup("");
                    }
    ;

identifiers:        identifier COMMA identifiers 
                    {
                        std::string temp;
                        temp.append(".| ");
                        temp.append($1.place);
                        temp.append("\n");
                        temp.append($3.code);
                        $$.code = strdup(temp.c_str());

                    }
    |               identifier 
                    {
                        std::string temp;
                        temp.append(".| ");
                        temp.append($1.place);
                        temp.append("\n");
                        $$.code = strdup(temp.c_str());
                    }
    ;

identifier:         IDENT 
                    {
                        std::string temp;
                        std::string ident = $1;
                        if(funcs.find(ident) == funcs.end() && varTemp.find(ident) == varTemp.end()){
                            printf("Line %d: Identifier %s is not declared\n", currLine, ident.c_str());//Error message
                            errorFlag = true;
                        }
                        $$.code = strdup("");//No code
                        $$.place = strdup(ident.c_str());//Place is identifier name
                    }
    ;

expression:         multexpr 
		            {
			            $$.code = strdup($1.code);
			            $$.place = strdup($1.place);
		            }
    |               multexpr ADD expression 
		            {
			            std::string temp;
			            std::string dst = new_temp();
        			    temp.append($1.code);
	    	    	    temp.append($3.code);
		        	    temp += ". " + dst + "\n";
			            temp += "+ " + dst + ", ";
        			    temp.append($1.place);
		        	    temp += ", ";
			            temp.append($3.place);
			            temp += "\n";
			            $$.code = strdup(temp.c_str());
			            $$.place = strdup(dst.c_str());
		            }
    |               multexpr SUB expression
                    {
                        std::string temp;
                        std::string dst = new_temp();
                        temp.append($1.code);
                        temp.append($3.code);
                        temp += ". " + dst + "\n";
                        temp += "- " + dst + ", ";
                        temp.append($1.place);
                        temp += ", ";
                        temp.append($3.place);
                        temp += "\n";
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup(dst.c_str());
                    }

    ;

multexpr:           term 
		            {
			            $$.code = strdup($1.code);
			            $$.place = strdup($1.place);
		            }
    |               term MULT multexpr
		            {
		    	        std::string temp;
                        std::string dst = new_temp();
                        temp.append($1.code);
                        temp.append($3.code);
                        temp.append(". ");
                        temp.append(dst);
                        temp.append("\n");
                        temp += "* " + dst + ", ";
                        temp.append($1.place);
                        temp += ", ";
                        temp.append($3.place);
                        temp += "\n";
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup(dst.c_str());
		            }
    |               term DIV multexpr 
		            {
			            std::string temp;
                        std::string dst = new_temp();
                        temp.append($1.code);
                        temp.append($3.code);
                        temp.append(". ");
                        temp.append(dst);
                        temp.append("\n");
                        temp += "/ " + dst + ", ";
                        temp.append($1.place);
                        temp += ", ";
                        temp.append($3.place);
                        temp += "\n";
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup(dst.c_str());
		            }
    |               term MOD multexpr 
		            {
			            std::string temp;
                        std::string dst = new_temp();
                        temp.append($1.code);
                        temp.append($3.code);
                        temp.append(". ");
                        temp.append(dst);
                        temp.append("\n");
                        temp += "% " + dst + ", ";
                        temp.append($1.place);
                        temp += ", ";
                        temp.append($3.place);
                        temp += "\n";
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup(dst.c_str());
		            }
    ;

term:               var 
                    {
                        std::string dst = new_temp();
                        std::string temp;
                        if ($1.arr){
                            temp.append($1.code);
                            temp.append(". ");
                            temp.append(dst);//Declare new identifier
                            temp.append("\n");
                            temp += "=[] " + dst + ", ";
                            temp.append($1.place);//Assign the value from the var to the identifier
                            temp.append("\n");
                            temp.append($1.code);
                        }
                        else{
                            temp.append($1.code);
                            temp.append(". ");
                            temp.append(dst);//Declare new identifier
                            temp.append("\n");
                            temp += "= " + dst + ", ";
                            temp.append($1.place);//Assign the value from the var to the identifier
                            temp.append("\n");
                        }
                        if(varTemp.find($1.place) != varTemp.end()){
                            varTemp[$1.place] = dst;//If the identifier (+index) doesn't have an associated temp,  map to dst
                        }
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup(dst.c_str());//Value is now saved in dst
                    }
    |               SUB var 
                    {
                        std::string dst = new_temp();
                        std::string temp;
                        if ($2.arr){
                            temp.append($2.code);
                            temp.append(". ");
                            temp.append(dst);//Declare new identifier
                            temp.append("\n");
                            temp += "=[] " + dst + ", ";
                            temp.append($2.place);//Assign the value from the var to the identifier
                            temp.append("\n");
                        }
                        else{
                            temp.append($2.code);
                            temp.append(". ");
                            temp.append(dst);//Declare new identifier
                            temp.append("\n");
                            temp += "= " + dst + ", ";
                            temp.append($2.place);//Assign the value from the var to the identifier
                            temp.append("\n");
                        }
                        if(varTemp.find($2.place) != varTemp.end()){
                            varTemp[$2.place] = dst;//If the identifier (+index) doesn't have an associated temp,  map to dst
                        }
                        temp += "* " + dst + ", " + dst + ", -1\n";//Flip sign
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup(dst.c_str());//Value is now saved in dst
                    }
    |               NUMBER 
                    {
                        std::string dst = new_temp();
                        std::string temp;
                        temp.append(". ");
                        temp.append(dst);//Declare new identifier
                        temp.append("\n");
                        temp = temp + "= " + dst + ", " + std::to_string($1);//Assign value to dst
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup(dst.c_str());
                    }
    |               SUB NUMBER 
                    {
                        std::string dst = new_temp();
                        std::string temp;
                        temp.append(". ");
                        temp.append(dst);//Declare new identifier
                        temp.append("\n");
                        temp = temp + "= " + dst + ", " + std::to_string($2) + "\n";//Assign value to dst
                        temp += "* " + dst + ", " + dst + ", -1\n";//Flip sign
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup(dst.c_str());//Value is now saved in dst
                    }
    |               L_PAREN expression R_PAREN 
                    {
                        $$.code = strdup($2.code);
                        $$.place = strdup($2.place);
                    }
    |               SUB L_PAREN expression R_PAREN 
                    {
                        std::string dst = new_temp();
                        std::string temp;
                        temp.append($3.code);
                        temp.append(". ");
                        temp.append(dst);//Declare new identifier
                        temp.append("\n");
                        temp += "= " + dst + ", ";
                        temp.append($3.place);//Assign the value from the var to the identifier
                        temp.append("\n");
                        temp += "* " + dst + ", " + dst + ", -1\n";//Flip sign
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup(dst.c_str());//Value is now saved in dst
                    }
    |               identifier L_PAREN expressions R_PAREN 
                    {
                        std::string temp;
                        std::string func = $1.place;
                        if (funcs.find(func) == funcs.end()){
                            printf("Line %d: Calling undeclared function %s\n", currLine, func.c_str());//Error message
                            errorFlag = true;
                        }
                        std::string dst = new_temp();
                        temp.append($3.code);
                        temp += ". " + dst + "\ncall ";
                        temp.append($1.place);
                        temp += ", " + dst + "\n";
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup(dst.c_str());
                    }
    ;

var:                identifier 
                    {
                        std::string temp;
                        std::string ident = $1.place;
                        if (arrSize[ident] > 1){
                            printf("Line %d: Did not provide index for array identifier %s\n", currLine, ident.c_str());//Error message
                            errorFlag = true;
                        }
                        $$.code = strdup("");//No code
                        $$.place = $1.place;//
                        $$.arr = false;
                    }
    |               identifier L_SQUARE_BRACKET expression R_SQUARE_BRACKET 
                    {
                        std::string temp;
                        std::string ident = $1.place;
                        if (arrSize[ident] == 1){
                            printf("Line %d: Provided index for non array identifier %s\n", currLine, ident.c_str());
                            errorFlag = true;
                        }
                        temp.append($1.place);
                        temp.append(", ");
                        temp.append($3.place);
                        $$.code = strdup($3.code);//Inherits code from expression
                        $$.place = strdup(temp.c_str());//Place is identifier with index
                        $$.arr = true;
                    }
    ;
  
expressions:        /*empty*/ 
                    {   
                        $$.code = strdup("");
                        $$.place = strdup("");                            
                    }
    |               expression 
                    {
		    	        std::string temp;
			            temp.append($1.code);
			            temp.append("param ");
			            temp.append($1.place);
			            temp.append("\n");
                        $$.code = strdup(temp.c_str());
			            $$.place = strdup("");
		            }
    |               expression COMMA expressions {
                        std::string temp;
                        temp.append($1.code);
                        temp.append("param ");
                        temp.append($1.place);
                        temp.append("\n");
			            temp.append($3.code);
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup("");
		            }
			
    ;
%% 

int main(int argc, char **argv) {
  if (argc >= 2){
      yyin = fopen(argv[1], "r");
      if(yyin == NULL){
         yyin = stdin;
      }
      else
        filename = argv[1];
   }
   else
      yyin = stdin;
  yyparse();
  return 0;
}

void yyerror(const char *msg) {
    printf("** Line %d, position %d: %s\n", currLine, currPos, msg);
}

std::string new_temp(){
    std::string t = "t" + std::to_string(tempCount);
    tempCount++;
    return t;
}

std::string new_label(){
    std::string l = "L" + std::to_string(labelCount);
    labelCount++;
    return l;
}
