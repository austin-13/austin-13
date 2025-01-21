/*****
* Yacc parser for simple example (right recursion version)
*
* 
* wholeprogram -> globals functions program
* program -> KWPROGRAM LBRACE statements RBRACE
* functions -> function functions | empty
* function -> KWFUNCTION ID LPAREN parameters RPAREN LBRACE localvars statements RBRACE
* statements -> statement statements | empty
* statement -> funcall | assignment | ifthenelse | whileloop
* funcall -> KWCALL ID LPAREN arguments RPAREN SEMICOLON
* assignment -> ID EQUALS expression SEMICOLON | ID LBRACKET expression RBRACKET EQUALS expression SEMICOLON
* arguments -> empty | argument | argument COMMA arguments
* argument -> expression
* expression -> NUMBER | ID | ID LBRACKET expression RBRACKET | STRING | KWRETURNVAL | expression ADDOP expression
* globals -> empty | KWGLOBAL vardecl SEMICOLON globals
* vardecl -> KWINT ID | KWSTRING ID | KWINT ID LBRACKET NUMBER RBRACKET
* parameters -> empty | paramdecl | paramdecl COMMA parameters
* paramdecl -> KWINT ID | KWSTRING ID
* localvars -> empty | localdecl SEMICOLON localvars
* localdecl -> KWINT ID | KWSTRING ID
* ifthenelse -> KWIF LPAREN boolexpr RPAREN KWTHEN LBRACE statements RBRACE KWELSE LBRACE statements RBRACE
* whileloop -> KWWHILE LPAREN boolexpr RPAREN KWDO LBRACE statements RBRACE
* boolexpr -> expression RELOP expression
*
* The tokens that come from the scanner are: NUMBER, PLUS, and STRING. 
* The scanner skips all whitespace (space, tab, newline, and carriage return).
* The lexemes of the token NUMBER are strings of digits ('0'-'9'). 
* The lexeme of PLUS is only a string consisting of the plus symbol ('+').
* The lexemes of the token STRING are strings of characters that do not 
* include whitespace, digits, or the plus symbol.
* 
* Given the input "acb 42 +34 52this is", the scanner would produce 
* the tokens(/lexemes) of:
* <STRING,"abc">, <NUMBER,"42">, <PLUS,"+">, <NUMBER,"34">, <NUMBER,"52">,
* <STRING,"this">, <STRING,"is">
* 
* and this would match the grammar.
*
* This example also shows building up and returning a string
* through all the parsing rules, and then printing out when
* the grammar is done matching the input. This is VERY similar
* to how we will initially build up assembly code!
*****/

/****** Header definitions ******/
%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symtable.h"
#include "astree.h"
// function prototypes from lex
int yyerror(char *s);
extern int yylineno;
int yylex(void);
int debug=0; // set to 1 to turn on extra printing
extern Symbol** table;
extern ASTNode *astRoot;
int paramNum = 0;
int argNum = 0;
int functionNum = 1;
int addString(char *str);

/* Not used in this code, but this can be used in Compiler 1
   to save the constant strings that need output in the 
   data section of the assembly output */
char* savedStrings[100];


%}

/* token value data types */
%union { int ival; 
         char* str; 
         struct astnode_s *astnode;}

/* Starting non-terminal */
%start wholeprogram
%type <astnode> wholeprogram program statements statement funcall arguments argument functions function expression globals vardecl parameters paramdecl assignment ifthenelse whileloop boolexpr localvars localdecl

/* Token types */
%token <ival> KWPROGRAM KWCALL SEMICOLON LPAREN RPAREN LBRACE RBRACE KWFUNCTION NUMBER ADDOP COMMA EQUALS RELOP KWGLOBAL KWINT KWSTRING KWIF KWTHEN KWELSE KWWHILE KWDO KWRETURNVAL LBRACKET RBRACKET
%token <str> ID STRING

%%
/******* Rules *******/

wholeprogram: globals functions program 
      {
      if (debug) fprintf(stderr, "wholeprogram def\n");  //debug output
      $$ = (ASTNode*) newASTNode(AST_PROGRAM);  //creates a new AST node for the block
      $$->child[0] = $1;   //attaches global var
      $$->child[1] = $2;   //function definitions
      $$->child[2] = $3;   //and program(statements)
      astRoot = $$;        //sets the root of the AST
      }

program: KWPROGRAM LBRACE statements RBRACE
      {
         if (debug) fprintf(stderr, "program def\n");
         $$ = $3;
      }

functions: /* empty */ {$$ = 0; }
     | function functions
     {
        if (debug) fprintf(stderr,"functions def!\n");
        $1->next = $2;  //links the first function to the next in the liist
        $$ = $1;        //returns the head of the linked list
     }   

function: KWFUNCTION ID LPAREN parameters RPAREN LBRACE localvars statements RBRACE
     {
        if (debug) fprintf(stderr,"function def\n");
        $$ = (ASTNode*) newASTNode(AST_FUNCTION);
        $$->strval = $2;         //stores the function name
        $$->strNeedsFreed = 1;
        $$->child[0] = $4;       //parameter to the function node
        $$->child[1] = $8;       //local vars to the function node
        $$->child[2] = $7;       // statements to the function node
        delScopeLevel(table, 1);
        paramNum = 0;
     }
     
statements: statement statements
      {
         if (debug) fprintf(stderr, "statement def!\n");
         $1->next = $2;       //links the current statement to the next
         $$ = $1;             //returns the head of the linked list of statements
      }
      | /* empty */
      {
         {$$ = 0; }//returns empty string for no statements
      }

statement: funcall
      {
         if (debug) fprintf(stderr, "function call statement def!\n");
         $$ = $1; //sets the statement to be the function call
      }
      | assignment
      {
         if (debug) fprintf(stderr, "assignment statement def!\n");
         $$ = $1; //and the statement to be the assignment
      }
      | ifthenelse
      {
         if (debug) fprintf(stderr, "if then else statement def!\n");
         $$ = $1; //sets the statement as if/then/else
      }
      | whileloop
      {
         if (debug) fprintf(stderr, "while loop statement def!\n");
         $$ = $1;
      }

funcall: KWCALL ID LPAREN arguments RPAREN SEMICOLON
      {
         if (debug) fprintf(stderr, "arguments def!\n");
         $$ = (ASTNode*) newASTNode(AST_FUNCALL);
         $$->strval = $2;        //stores the function name
         $$->strNeedsFreed = 1;  //frees for memory management
         $$->child[0] = $4;      //attaches arguments
      }

assignment: ID EQUALS expression SEMICOLON
      {
         Symbol* symt;  //pointer to symbol table
         if (debug) fprintf(stderr, "expr array variable (%s)\n", $1);  //debugging
         if ((symt=findSymbol(table, $1)) == NULL) {  //checks if variable is in symbol table
            fprintf(stderr, "syntax error, line %d: variable (%s) is not defined.\n", yylineno, $1);  //error handling
            exit(1);
         }
         if (debug) fprintf(stderr, "assignment def!\n");
         $$ = (ASTNode*) newASTNode(AST_ASSIGNMENT);
         // sets the variable kind, type, and offset for assignment
         $$->varKind = symt->kind;
         $$->valType = symt->type;
         $$->ival = symt->offset;
         $$->strval = $1;  // sets the variable name
         $$->strNeedsFreed = 1;  //frees string
         $$->child[0] = $3;   // sets first child as expr on right hand side
      }
   | ID LBRACKET expression RBRACKET EQUALS expression SEMICOLON
      {
         Symbol* symt;
         if (debug) fprintf(stderr, "expr array variable (%s)\n", $1);
         if ((symt=findSymbol(table, $1)) == NULL) {
            fprintf(stderr, "syntax error, line %d: variable (%s) is not defined.\n", yylineno, $1);
            exit(1);
         }
         $$ = (ASTNode*) newASTNode(AST_ASSIGNMENT);
         $$->varKind = symt->kind;
         $$->valType = symt->type;
         $$->ival = symt->size;
         $$->strval = $1;
         $$->strNeedsFreed = 1;
         $$->child[0] = $6;      //right hand expression
         $$->child[1] = $3; 
      }

arguments: /* empty */
      {$$ = 0; }
   | argument
      {
         $$ = $1;    //single argument returned
      }
   | argument COMMA arguments
      {
         $$ = (ASTNode*) newASTNode(AST_ARGUMENT); //creates new node for the arguments list
         $1->next = $3; //links the first argument to the other ($1/$3)
         $$ = $1;       //returns the head of the linked list
      }

argument: expression
      {
         $$ = (ASTNode*) newASTNode(AST_ARGUMENT);
         $$->child[0] = $1;
      }

expression: NUMBER
      {
         $$ = (ASTNode*) newASTNode(AST_CONSTANT);
         $$->valType = T_INT; //set the type to integer
         $$->ival = $1;       //stores the int value
      }
   | ID
      {
         Symbol* symt;
         if (debug) fprintf(stderr, "expression array variable (%s)\n", $1);
         if ((symt=findSymbol(table, $1)) == NULL) {
            fprintf(stderr, "syntax error, line %d: variable (%s) is not defined.\n", yylineno, $1);
            exit(1);
         }
         $$ = (ASTNode*) newASTNode(AST_VARREF);
         $$->varKind = symt->kind;
         $$->valType = symt->type;
         $$->ival = symt->offset;
         $$->strval = $1;
         $$->strNeedsFreed = 1;
      }
   | ID LBRACKET expression RBRACKET
      {
         Symbol* symt;
         if (debug) fprintf(stderr, "expression array variable (%s)\n", $1);
         if ((symt=findSymbol(table, $1)) == NULL) {
            fprintf(stderr, "syntax error, line %d: variable (%s) is not defined.\n", yylineno, $1);
            exit(1);
         }
         $$ = newASTNode(AST_VARREF);
         $$->varKind = symt->kind;
         $$->ival = symt->size;
         $$->valType = symt->type;
         $$->child[0] = $3;
         $$->strval = $1;
         $$->strNeedsFreed = 1;
      }
   | STRING
      {
         $$ = (ASTNode*) newASTNode(AST_CONSTANT);
         int id = addString($1);
         $$ = newASTNode(AST_CONSTANT);
         $$->valType = T_STRING;
         $$->ival = id;
         $$->strval = $1;
         $$->strNeedsFreed = 1;
      }
   | KWRETURNVAL
      {
         $$ = newASTNode(AST_CONSTANT);
         $$->valType = T_RETURNVAL;
      }
   | expression ADDOP expression
      {
         $$ = (ASTNode*) newASTNode(AST_EXPRESSION);
         $$->ival = $2;
         $$->child[0] = $1;
         $$->child[1] = $3;
      }

globals: /* empty */
      {$$ = NULL; }
   | KWGLOBAL vardecl SEMICOLON globals
      {
         if (debug) fprintf(stderr, "globals def!\n");
         $2->next = $4;
         $$ = $2;
      }

vardecl: KWINT ID
      {
         addSymbol(table, $2, 0, T_INT, 0, 0, V_GLOBAL);
         $$ = newASTNode(AST_VARDECL);
         $$->strval = $2;
         $$->strNeedsFreed = 1;
         $$->valType = T_INT;
         $$->varKind = V_GLOBAL;
      }
   | KWSTRING ID 
      {
         if (debug) fprintf(stderr, " string vardecl def!\n");
         addSymbol(table, $2, 0, T_STRING, 0, 0, V_GLOBAL);
         $$ = newASTNode(AST_VARDECL);
         $$->strval = $2;
         $$->strNeedsFreed = 1;
         $$->valType = T_STRING;
         $$->varKind = V_GLOBAL;
      }
      | KWINT ID LBRACKET NUMBER RBRACKET
      {
         addSymbol(table, $2, 0, T_INT, $4, 0, V_GLARRAY);
         $$ = newASTNode(AST_VARDECL);
         $$->strval = $2;
         $$->strNeedsFreed = 1;
         $$->valType = T_INT;
         $$->ival = $4;
         $$->varKind = V_GLARRAY;         
      }

parameters: /* empty */
      {$$ = 0; }
   | paramdecl
      {
         $$ = $1;
      }
   | paramdecl COMMA parameters
      {
         $1->next = $3;
         $$ = $1;
      }

paramdecl: KWINT ID  
      {
         addSymbol(table, $2, 1, T_INT, 0, paramNum, V_PARAM);
         $$ = newASTNode(AST_VARDECL);
         $$->strval = strdup($2); //stores the parameter name
         $$->strNeedsFreed = 1;
         $$->valType = T_INT;
         $$->ival = paramNum++;
         $$->varKind = V_PARAM;
      }
   |  KWSTRING ID    
      {
         addSymbol(table, $2, 1, T_STRING, 0, paramNum, V_PARAM);
         $$ = newASTNode(AST_VARDECL);
         $$->strval = strdup($2); //stores the parameter name
         $$->strNeedsFreed = 1;
         $$->valType = T_STRING;
         $$->ival = paramNum++;
         $$->varKind = V_PARAM;
      }
   
localvars: /* empty */ {$$ = 0; }
      | localdecl SEMICOLON localvars
      {
         $1->next =$3;
         $$ = $1;
      }

localdecl: KWINT ID
      {
         addSymbol(table, $2, 1, T_INT, 0, paramNum, V_LOCAL);
         $$ = newASTNode(AST_VARDECL);
         $$->strval = $2;
         $$->strNeedsFreed = 1;
         $$->valType = T_INT;
         $$->ival = paramNum++;
         $$->varKind = V_LOCAL;
      }
      | KWSTRING ID
      {
         addSymbol(table, $2, 1, T_STRING, 0, paramNum, V_LOCAL);
         $$ = newASTNode(AST_VARDECL);
         $$->strval = $2;
         $$->strNeedsFreed = 1;
         $$->valType = T_STRING;
         $$->ival = paramNum++;
         $$->varKind = V_LOCAL;
      }

ifthenelse: KWIF LPAREN boolexpr RPAREN KWTHEN LBRACE statements RBRACE KWELSE LBRACE statements RBRACE
      {
         if (debug) fprintf(stderr, "if-then-else statement def!\n");
         $$ = (ASTNode*) newASTNode(AST_IFTHEN);
         $$->child[0] = $3;      // boolexpr
         $$->child[1] = $7;      // statements for then
         $$->child[2] = $11;     // statements for else)
      }

whileloop: KWWHILE LPAREN boolexpr RPAREN KWDO LBRACE statements RBRACE
      {
         if (debug) fprintf(stderr, "while-loop statement def!\n");
         $$ = (ASTNode*) newASTNode(AST_WHILE);
         $$->child[0] = $3;      //bool expression
         $$->child[1] = $7;      //statements
      }

boolexpr: expression RELOP expression
      {
         if (debug) fprintf(stderr, "boolean(relexpr) expression statement def!\n");
         $$ = (ASTNode*) newASTNode(AST_RELEXPR);
         $$->ival = $2;
         $$->child[0] = $1; 
         $$->child[1] = $3;
      }
     ;
%%

/******* Functions *******/
extern FILE *yyin; // from lex
#include <stdio.h>
#include <string.h>
#include "symtable.h"
#include "astree.h"

Symbol** table;
ASTNode* astRoot;

/******* Functions *******/
extern FILE *yyin; // from lex
#include <stdio.h>
#include <string.h>
#include "symtable.h"
#include "astree.h"

Symbol** table;
ASTNode* astRoot;

int main(int argc, char **argv)
{
    //checks the number of arguments
    if (argc == 1) {
        yyin = stdin; //reads from stdin if no file is given
    } 
    else if (argc == 2) {
        // checks if a file is provided
        if (strlen(argv[1]) < 3 || strcmp(argv[1] + strlen(argv[1]) - 2, ".j") != 0) {
            fprintf(stderr, "Error: filename must have a '.j'!\n");
            return 1;
        }
        yyin = fopen(argv[1], "r");  //opens the input file
        if (!yyin) {
            fprintf(stderr, "Error: unable to open file (%s)\n", argv[1]);
            return 1;
        }

        // creates output file with .s extension (assembly)
        char output_filename[strlen(argv[1]) + 2]; // .s extension
        strcpy(output_filename, argv[1]);
        output_filename[strlen(argv[1]) - 1] = 's'; // change .j to .s

        FILE *outfile = fopen(output_filename, "w");
        if (!outfile) {
            fprintf(stderr, "Error: unable to create output file (%s)\n", output_filename);
            return 1;
        }

        //create a new symbol table
        table = newSymbolTable();
        int stat = yyparse();  //start parsing with yacc
        fclose(yyin);

        if (stat) {
            fprintf(stderr, "Parsing failed.\n");
            freeAllSymbols(table);
            free(table);
            return stat;
        }

        // if AST is generated then generate code from it
        if (astRoot) {
            genCodeFromASTree(astRoot, 0, outfile);
            printf("Assembly code written to %s\n", output_filename);
        } else {
            fprintf(stderr, "AST generation failed...\n");
        }

        fclose(outfile);
        freeAllSymbols(table);
        free(table);
        freeASTree(astRoot);
        return 0;
    } 
    else if (argc == 3 && strcmp(argv[2], "-d") == 0) {
        //if -d flag is provided, displays AST for debugging
        debug = 0;
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            fprintf(stderr, "Error: unable to open file (%s)\n", argv[1]);
            return 1;
        }

        //create a new symbol table
        table = newSymbolTable();
        int stat = yyparse();
        fclose(yyin);

        if (stat) {
            fprintf(stderr, "Parsing failed.\n");
            freeAllSymbols(table);
            free(table);
            return stat;
        }

        //prints the AST if it's successful
        if (astRoot) {
            printASTree(astRoot, 0, stdout);
        } else {
            fprintf(stderr, "AST generation failed...\n");
        }

         //free symbol table
        freeAllSymbols(table);
        free(table);
        freeASTree(astRoot);
        return 0;
    } 
    else if (argc == 3 && strcmp(argv[2], "-t") == 0) {
        // if -t flag is used print AST in tree form for testing
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            fprintf(stderr, "Error: unable to open file (%s)\n", argv[1]);
            return 1;
        }

        // create/free another new symbol table
        table = newSymbolTable();
        int stat = yyparse();
        fclose(yyin);

        if (stat) {
            fprintf(stderr, "Parsing failed.\n");
            freeAllSymbols(table);
            free(table);
            return stat;
        }

        // print the AST if it's successfull
        if (astRoot) {
            printASTree(astRoot, 0, stdout);  //then prints AST in tree form
        } else {
            fprintf(stderr, "AST generation failed...\n");
        }

        freeAllSymbols(table);
        free(table);
        freeASTree(astRoot);
        return 0;
    } 
    else {
        // displays if incorrect arguments used
        fprintf(stderr, "Usage: %s <filename>.j [-t | -d]\n", argv[0]);
        return 1;
    }
}

extern int yylineno; // from lex
int yyerror(char *s)
{
    fprintf(stderr, "Error: line %d: %s\n", yylineno, s);
    return 0;
}

int yywrap()
{
    return 1; 
}