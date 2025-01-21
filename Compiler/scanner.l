/****
* Lex scanner for simple example
* - see the header comments in parser.y for more 
*   explanation of what this scanner does
****/

/****** Header definitions ******/
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
// The ifndef below allows this scanner definition to be
// used either with a yacc generated parser or all by
// itself (if LEXONLY is defined)
#ifndef SYMTABLE_H
#include "symtable.h"
#endif
#ifndef ASTREE_H
#include "astree.h"
#endif
// definitions are auto-created by yacc so just include them
#ifndef LEXONLY
#include "y.tab.h"
extern int debug; // declared and set in parser.y
#else
// we must have explicit definitions for standalone mode
typedef union { int ival; char* str; } yystype;
#define YYSTYPE yystype
yystype yylval;
#define KWPROGRAM 1
#define KWCALL 2
#define SEMICOLON 3
#define LPAREN 4
#define RPAREN 5
#define LBRACE 6
#define RBRACE 7
#define ID 8
#define STRING 9
#define KWFUNCTION 10
#define COMMA 11
#define NUMBER 12
#define ADDOP 13
#define KWINT 14
#define KWSTRING 15
#define KWGLOBAL 16
#define EQUALS 17
#define KWIF 18
#define KWTHEN 19
#define KWELSE 20
#define KWWHILE 21
#define KWDO 22
#define RELOP 23
#define LBRACKET 24
#define RBRACKET 25
#define KWRETURNVAL 26

int debug=1;
#endif
%}

/* This option is useful for printing out a syntax error
*  message and printing out the line # it occurred on
*/

%option yylineno

/****** Token Patterns ******/
%%
[ \t\n\r]+ { /* skipping white space */ }
\(       {
            if (debug) printf("lex: LPAREN symbol (%s)\n", yytext);
            yylval.ival = yytext[0];
            return(LPAREN);
         }
\)       {
            if (debug) printf("lex: RPAREN symbol (%s)\n", yytext);
            yylval.ival = yytext[0];
            return(RPAREN);
         }
\{       {
            if (debug) printf("lex: LBRACE symbol (%s)\n", yytext);
            yylval.ival = yytext[0];
            return(LBRACE);
         }
\}       {
            if (debug) printf("lex: RBRACE symbol (%s)\n", yytext);
            yylval.ival = yytext[0];
            return(RBRACE);
         }
\;       {
            if (debug) printf("lex: SEMICOLON symbol (%s)\n", yytext);
            yylval.ival = yytext[0];
            return(SEMICOLON);
         }
\[       {
            if (debug) printf("lex: LBRACKET symbol (%s)\n", yytext);
            yylval.ival = yytext[0];
            return(LBRACKET);
         }
\]       {
            if (debug) printf("lex: LBRACKET symbol (%s)\n", yytext);
            yylval.ival = yytext[0];
            return(RBRACKET);
         }
\"([^\"]*)\" {
               if (debug) printf("lex: STRING symbol (%s)\n", yytext);
               yylval.str = strdup(yytext);
               return (STRING);
            }
"program"  {
            if (debug) printf("lex: KWPROGRAM symbol (%s)\n", yytext);
            return(KWPROGRAM);
         }
"call"     {
            if (debug) printf("lex: KWCALL symbol (%s)\n", yytext);
            return(KWCALL);
         }
"function" {
            if (debug) printf("lex: KWFUNCTION symbol (%s)\n", yytext);
            return (KWFUNCTION);
         }
"global" {
            if (debug) printf("lex: KWGLOBAL symbol (%s)\n", yytext);
            return (KWGLOBAL);
         }
"int"    {
            if (debug) printf("lex: KWINT symbol (%s)\n", yytext);
            return (KWINT);
         }
"string" {
            if (debug) printf("lex: KWSTRING symbol (%s)\n", yytext);
            return(KWSTRING);
         }
\,       {
            if (debug) printf("lex: COMMA symbol (%s)\n", yytext);
            yylval.ival = yytext[0];
            return (COMMA);
         }
\+       {
            if (debug) printf("lex: ADDOP/PLUS symbol (%s)\n", yytext);
            yylval.ival = yytext[0];
            return(ADDOP);
         }
\-       {
            if (debug) printf("lex: ADDOP/MINUS symbol (%s)\n", yytext);
            yylval.ival = yytext[0];
            return(ADDOP);
         }
[0-9]+   {
            if (debug) printf("lex: NUMBER (%s)\n", yytext);
            yylval.ival = strtol(yytext,NULL,10);
            return(NUMBER);
         }
"if"     {
            if (debug) printf("lex: KWIF symbol (%s\n)", yytext);
            return (KWIF);
         }
"then"     {
            if (debug) printf("lex: KWTHEN symbol (%s\n)", yytext);
            return (KWTHEN);
         }
"else"     {
            if (debug) printf("lex: KWELSE symbol (%s\n)", yytext);
            return (KWELSE);
         }
"while"     {
            if (debug) printf("lex: KWWHILE symbol (%s\n)", yytext);
            return (KWWHILE);
         }
"do"     {
            if (debug) printf("lex: KWDO symbol (%s\n)", yytext);
            return (KWDO);
         }
"returnvalue"  {
                  if (debug) printf("lex: KWRETURNVAL (%s)\n", yytext);
                  yylval.ival = yytext[0];
                  return (KWRETURNVAL);
               }
[a-zA-Z_][a-zA-Z0-9_]* {
                  if (debug) printf("lex: ID symbol (%s)\n", yytext);
                  yylval.str = strdup(yytext);
                  return (ID);
                        }
\=       {
            if (debug) printf("lex: EQUALS symbol (%s)\n", yytext);
            yylval.ival = yytext[0];
            return(EQUALS);
         }
"=="     {
            if (debug) printf("lex: RELOP symbol (%s)\n", yytext);
            yylval.ival = yytext[0];
            return (RELOP);
         }
"!="     {
            if (debug) printf("lex: RELOP symbol (%s)\n", yytext);
            yylval.ival = yytext[0];
            return (RELOP);
         }
\<     {
            if (debug) printf("lex: RELOP symbol (%s)\n", yytext);
            yylval.ival = yytext[0];
            return (RELOP);
         }
\>     {
            if (debug) printf("lex: RELOP symbol (%s)\n", yytext);
            yylval.ival = yytext[0];
            return (RELOP);
         }
%%
/****** Functions (not used when used with parser) *******/

//
// Code in the ifdef block below is only for compiling the
// scanner all by itself, for testing purposes. The 
// Makefile shows how to compile it under the "ltest" rule
// (do "make ltest" to build it)
//
#ifdef LEXONLY

// A main for standalone testing (uses just stdin as input)
int main(int argc, char **argv) 
{
   do {
      yylex();
   } while (1);
   // while (!feof(stdin)); doesn't work if redirecting a file
   // in because the file is read in and buffered, and eof is
   // true too early, causing lex to stop; rather, use while(1)
   // and then do a hard exit in yywrap(); ugly, but works!
   return 0;
}

int yywrap()
{
   //exit(0); // hard exit!
   return(1);
}

#endif // LEXONLY



