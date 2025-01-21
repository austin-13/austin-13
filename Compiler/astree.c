//
// Abstract Syntax Tree Implementation
// - see "astree.h" for type definitions
// - the tree is made up of nodes of type ASTNode
// - the root node must be of type AST_PROGRAM
// - child nodes are linked by the "child[]" array, and
//   each type of node has its own children types
// - a special "child" node (the AST is a tree) uses
//   the "next" pointer to point to a "sibling"-type
//   node that is the next in a list (such as statements)
//
// Copyright (C) 2024 Jonathan Cook
//
#include <stdlib.h>
#include <stdio.h>
#include "astree.h"
#include <string.h>
#include "symtable.h"

// symbol table and saved strings to store
Symbol** table;
char* savedStrings[100];
int lastStringIndex = 0;
char* instr;
static int labelCount = 100;

// function to add a string to the savedStrings array and return its index
int addString(char *str) {
    savedStrings[lastStringIndex] = strdup(str);  // stores string in array
    return lastStringIndex++;  // returns current index and increments
}
void grabStrings(ASTNode* node, FILE* out) {
    if (node == NULL) {
        return;
    }

    // processes all children of the current node
    for (int i = 0; i < ASTNUMCHILDREN; i++) {
        if (node->child[i] != NULL) {
            grabStrings(node->child[i], out);
        }
    }

    // processes the current node if it's a string constant
    if (node->valType == T_STRING) {
        // check if the string is a literal string
        if (node->strval != NULL && node->strval[0] == '"') {
            int stringIndex = addString(node->strval);  // gets the index for the string
            fprintf(out, ".SC%d:\t.string \t%s\n", stringIndex, savedStrings[stringIndex]);
        }
    }

    // gets the next sibling node if it exists
    if (node->next != NULL) {
        grabStrings(node->next, out);
    }
}



// Create a new AST node 
// - allocates space and initializes node type, zeros other stuff out
// - returns pointer to new node
ASTNode* newASTNode(ASTNodeType type)
{
   int i;
   ASTNode* node = (ASTNode*) malloc(sizeof(ASTNode));
   if (node == NULL)
      return NULL;
   node->type = type;
   node->valType = T_INT;
   node->varKind = V_GLOBAL;
   node->valType = T_RETURNVAL;
   node->ival = 0;
   node->strval = 0;
   node->strNeedsFreed = 0;
   node->next = 0;
   for (i=0; i < ASTNUMCHILDREN; i++)
      node->child[i] = 0;
   return node;
}

// Generate an indentation string prefix
// - this is a helper function for use in printing the abstract
//   syntax tree with indentation used to indicate tree depth.
// - NOT thread safe! (uses a static char array to hold prefix)
#define INDENTAMT 3
static char* levelPrefix(int level)
{
   static char prefix[128]; // static so that it can be returned safely
   int i;
   for (i=0; i < level*INDENTAMT && i < 126; i++)
      prefix[i] = ' ';
   prefix[i] = '\0';
   return prefix;
}

// Free an entire ASTree, along with string data it has
// - a node must have strNeedsFreed to non-zero in order 
//   for its strval to be freed
void freeASTree(ASTNode* node)
{
   if (!node)
      return;
   freeASTree(node->child[0]);
   freeASTree(node->child[1]);
   freeASTree(node->child[2]);
   freeASTree(node->next);
   if (node->strNeedsFreed && node->strval) 
      free(node->strval);
   free(node);
}

// Print the abstract syntax tree starting at the given node
// - this is a recursive function, your initial call should 
//   pass 0 in for the level parameter
// - comments in code indicate types of nodes and where they
//   are expected; this helps you understand what the AST looks like
// - "out" is the file to output to, can be "stdout" or other file handle
void printASTree(ASTNode* node, int level, FILE *out)
{
   if (!node)
      return;
   fprintf(out,"%s",levelPrefix(level)); // note: no newline printed here!
   switch (node->type) {
    case AST_PROGRAM:
       fprintf(out,"Whole Program AST:\n");
       fprintf(out,"%s--globalvars--\n",levelPrefix(level+1));
       printASTree(node->child[0],level+1,out);  // child 0 is global var decls
       fprintf(out,"%s--functions--\n",levelPrefix(level+1));
       printASTree(node->child[1],level+1,out);  // child 1 is function defs
       fprintf(out,"%s--program--\n",levelPrefix(level+1));
       printASTree(node->child[2],level+1,out);  // child 2 is program
       break;
    case AST_VARDECL:
       fprintf(out,"Variable declaration (%s)",node->strval); // var name
       if (node->valType == T_INT)
          if (node->varKind != V_GLARRAY)
             fprintf(out," type int\n");
          else
             fprintf(out," type int array size %d\n",node->ival);
       else if (node->valType == T_LONG)
          fprintf(out," type long\n");
       else if (node->valType == T_STRING)
          fprintf(out," type string\n");
       else
          fprintf(out," type unknown (%d)\n", node->valType);
       break;
    case AST_FUNCTION:
       fprintf(out,"Function def (%s)\n",node->strval); // function name
       fprintf(out,"%s--params--\n",levelPrefix(level+1));
       printASTree(node->child[0],level+1,out); // child 0 is param list
       fprintf(out,"%s--locals--\n",levelPrefix(level+1));
       printASTree(node->child[2],level+1,out); // child 2 is local vars
       fprintf(out,"%s--body--\n",levelPrefix(level+1));
       printASTree(node->child[1],level+1,out); // child 1 is body (stmt list)
       break;
    case AST_SBLOCK:
       fprintf(out,"Statement block\n"); // we don't use this type
       printASTree(node->child[0],level+1,out);  // child 0 is statement list
       break;
    case AST_FUNCALL:
       fprintf(out,"Function call (%s)\n",node->strval); // func name
       printASTree(node->child[0],level+1,out);  // child 0 is argument list
       break;
    case AST_ARGUMENT:
       fprintf(out,"Funcall argument\n");
       printASTree(node->child[0],level+1,out);  // child 0 is argument expr
       break;
    case AST_ASSIGNMENT:
       fprintf(out,"Assignment to (%s) ", node->strval);
       if (node->varKind == V_GLARRAY) { //child[1]) {
          fprintf(out,"array var\n");
          fprintf(out,"%s--index--\n",levelPrefix(level+1));
          printASTree(node->child[1],level+1,out);
       } else  
          fprintf(out,"simple var\n");
       fprintf(out,"%s--right hand side--\n",levelPrefix(level+1));
       printASTree(node->child[0],level+1,out);  // child 1 is right hand side
       break;
    case AST_WHILE:
       fprintf(out,"While loop\n");
       printASTree(node->child[0],level+1,out);  // child 0 is condition expr
       fprintf(out,"%s--body--\n",levelPrefix(level+1));
       printASTree(node->child[1],level+1,out);  // child 1 is loop body
       break;
    case AST_IFTHEN:
       fprintf(out,"If then\n");
       printASTree(node->child[0],level+1,out);  // child 0 is condition expr
       fprintf(out,"%s--ifpart--\n",levelPrefix(level+1));
       printASTree(node->child[1],level+1,out);  // child 1 is if body
       fprintf(out,"%s--elsepart--\n",levelPrefix(level+1));
       printASTree(node->child[2],level+1,out);  // child 2 is else body
       break;
   case AST_IFTHENELSE:
      printf("If-Then-Else\n");
      printASTree(node->child[0],level+1, out); // condition
      printASTree(node->child[1],level+1, out); // then
      printASTree(node->child[2],level+1, out); // else
      break;
    case AST_EXPRESSION: // only for binary op expression
       fprintf(out,"Expression (op %d,%c)\n",node->ival,node->ival);
       printASTree(node->child[0],level+1,out);  // child 0 is left side
       printASTree(node->child[1],level+1,out);  // child 1 is right side
       break;
    case AST_RELEXPR: // only for relational op expression
       fprintf(out,"Relational Expression (op %d,%c)\n",node->ival,node->ival);
       printASTree(node->child[0],level+1,out);  // child 0 is left side
       printASTree(node->child[1],level+1,out);  // child 1 is right side
       break;
    case AST_VARREF:
       fprintf(out,"Variable ref (%s)",node->strval); // var name
       if (node->varKind == V_GLARRAY) { //child[0]) {
          fprintf(out," array ref\n");
          printASTree(node->child[0],level+1,out);
       } else 
          fprintf(out,"\n");
       break;
    case AST_CONSTANT: // for both int and string constants
       if (node->valType == T_INT)
          fprintf(out,"Int Constant = %d\n",node->ival);
       else if (node->valType == T_STRING)
          fprintf(out,"String Constant = (%s)\n",node->strval);
       else 
          fprintf(out,"Unknown Constant\n");
       break;
    default:
       fprintf(out,"Unknown AST node!\n");
   }
   // IMPORTANT: walks down sibling list (for nodes that form lists, like
   // declarations, functions, parameters, arguments, and statements)
   printASTree(node->next,level,out);
}

//
// Below here is code for generating our output assembly code from
// an AST. You will probably want to move some things from the
// grammar file (.y file) over here, since you will no longer be 
// generating code in the grammar file. You may have some global 
// stuff that needs accessed from both, in which case declare it in
// one and then use "extern" to reference it in the other.

extern void outputDataSec(FILE* out); // in main.c
extern Symbol** table;

// Used for labels inside code, for loops and conditionals
static int getUniqueLabelID()
{
   static int lid = 100; // you can start at 0, it really doesn't matter
   return lid++;
}

// Generate assembly code from AST
// - this function should look _alot_ like the print function;
//   indeed, the best way to start would be to copy over the 
//   code from printASTree() and change all the recursive calls
//   to this function; then, instead of printing info, we are 
//   going to print assembly code. Easy!
// - param node is the current node being processed
// - param hval is a helper value parameter that can be used to keep
//   track of value for you -- I use it only in two places, to keep
//   track of arguments and then to use the correct argument register
//   and to keep a label ID for conditional jumps on AST_RELEXPR 
//   nodes; otherwise this helper value can just be 0
// - param out is the output file handle. Use "fprintf(out,..." 
//   instead of printf(...); call it with "stdout" for terminal output
//   (see printASTree() code for how it uses the output file handle)
//

void genCodeFromASTree(ASTNode* node, int hval, FILE *out)
{
   int firstLabel, secondLabel;
   int level = 0;
   if (!node)
      return;
   fprintf(out,"%s",levelPrefix(hval)); // note: no newline printed here!
   switch (node->type) {
    case AST_PROGRAM:
       fprintf(out, "#\n# RISC-V assembly output\n#\n\n");
       fprintf(out, "#\n# Data section\n#\n\t.data\n\n");
       fprintf(out, "# string constants\n");

       lastStringIndex = 0;
       grabStrings(node, out);  
       
       fprintf(out, "\n# global symbols (variables)\n");
       genCodeFromASTree(node->child[0],0,out);
   
         //outputs program instructions section
       fprintf(out,"\n#\n# Program instructions\n#\n\t.text\nprogram:\n");
       genCodeFromASTree(node->child[2],0,out); 
       fprintf(out,"\tli\t\ta0, 0\n\tli\t\ta7, 93\n\tecall\n\n");
         //output library functions
       fprintf(out,"#\n# Declared Functions\n#\n\n");
       genCodeFromASTree(node->child[1],0,out);
       fprintf(out, "#\n# Library functions\n#\n\n");
       fprintf(out,"# Print a null-terminated string: arg: a0 == string address\nprintStr:\n\tli\t\ta7, 4\n\tecall\n\tret\n\n");
       fprintf(out, "# Print a decimal integer: arg: a0 == value\nprintInt:\n\tli\t\ta7, 1\n\tecall\n\tret\n\n");       
       fprintf(out, "# Read in a decimal integer: return: a0 == value\nreadInt:\n\tli\t\ta7, 1\n\tecall\n\tret\n\n");       
       break;

   case AST_VARDECL: //variable declarations
      if (node->valType == T_INT) {
         if(node->ival > 0 ) {
            fprintf(out,"%s: .space %d\n", node->strval, node->ival * 4);
         } else {
            fprintf(out, "%s: .word 0\n", node->strval);
         }
      } 
      else if (node->valType == T_STRING) {
         genCodeFromASTree(node->child[0],0,out);
         fprintf(out, " type string\n");
      } else {
         fprintf(out, "unknown type (%d)\n", node->valType);
      }
      break;

    case AST_FUNCTION:
       // implement function
       fprintf(out, "#\n# Function def for %s\n#\n", node->strval);
       fprintf(out, "%s:\n", node->strval);
       fprintf(out, "\taddi\tsp, sp, -128\n\tsw\t\tfp, 4(sp)\n\tsw\t\tra, 0(sp)\n\tmv\t\tfp, sp\n\tsw\t\ta0, 8(sp)\n\tsw\t\ta1, 12(sp)\n\tsw\t\ta2, 16(sp)\n\tsw\t\ta3, 20(sp)\n\tsw\t\ta4, 24(sp)\n\tsw\t\ta5, 28(sp)\n");
       genCodeFromASTree(node->child[1], 0, out);  // child 1 is the body -  statement list
       fprintf(out, "\tmv\t\tsp, fp\n\tlw\t\tfp, 4(sp)\n\tlw\t\tra, 0(sp)\n\taddi\tsp, sp, 128\n\tret\n\n");
       break;

    case AST_SBLOCK:
       genCodeFromASTree(node->child[0],0,out);  // child 0 is statement list
       break;

    case AST_FUNCALL:
      fprintf(out, "\t#--function call to %s--\n", node->strval);
      genCodeFromASTree(node->child[0],0,out);       //child is an argument list
      fprintf(out,"\tjal\t\t%s\n", node->strval); // function name
       break;

    case AST_ARGUMENT:
       genCodeFromASTree(node->child[0],0,out); //child 0 is a argument expression
       fprintf(out, "\tmv\t\ta%d, t0\n", node->ival);
       break;

    case AST_ASSIGNMENT:
      fprintf(out, "\t#--assignment--\n");
      genCodeFromASTree(node->child[0],level+1,out);  //child1 is right hand
      if (node->varKind == V_GLOBAL) {
         fprintf(out, "\tsw\t\tt0, %s, t1\n", node->strval);  //variable name
      } else if (node->varKind == V_PARAM || node->varKind == V_LOCAL) {
         fprintf(out, "\tsw\t\tt0, %d(fp)\n", (node->ival+2)*4); //variable name
      } else if (node->varKind == V_GLARRAY) {
         fprintf(out, "\taddi\tsp, sp, -4\n\tsw\t\tt0, 0(sp)\n");   //saves the right hand side
         genCodeFromASTree(node->child[1],level+1, out);
         fprintf(out, "\tslli\tt0, t0, 2\n\tla\t\tt1, %s\n\tadd\t\tt1, t1, t0\n\tlw\t\tt0, 0(sp)\n\taddi\tsp, sp, 4\n\tsw\t\tt0, 0(t1)\n", node->strval);
      } else {
         fprintf(out, "unknown var kind assignment\n");
      }
      break;

    case AST_WHILE:
      firstLabel = getUniqueLabelID(); //generates unique labels for the loop start adn end
      secondLabel = getUniqueLabelID();
      fprintf(out, "\t#--while-loop--\n");
      fprintf(out, "\tb\t\t.LL%d\n.LL%d:\n", secondLabel, firstLabel);  //jump to loop condition and start of loop
      fprintf(out, "\t#--loop-body--\n");
      genCodeFromASTree(node->child[1],0,out);  //loop body (child[1])
      fprintf(out,"\t#--loop-condition--\n");
      fprintf(out, ".LL%d:\n", secondLabel);    // loop condition label
      genCodeFromASTree(node->child[0], 0, out);   //condition expression (child[0])
      fprintf(out, "\t#--end-loop--\n");
      break;

    case AST_IFTHEN:
      firstLabel = getUniqueLabelID();
      secondLabel = getUniqueLabelID();
      fprintf(out, "\t#--ifthenelse--\n");
      genCodeFromASTree(node->child[0], 0, out);   //code for condition (child[0])
      fprintf(out, "\t#--else--\n");
      genCodeFromASTree(node->child[2],0,out);     // code for else body (child[2])
      fprintf(out,"\tb\t\t.LL%d\n.LL%d:\n", secondLabel, firstLabel);
      fprintf(out, "\t#--if--\n");
      genCodeFromASTree(node->child[1],0,out);     // code for then body (child[1])
      fprintf(out, ".LL%d:\n\t#--endif--\n", secondLabel);
    break;

    case AST_EXPRESSION: // only for binary op expression
      fprintf(out, "\t#--binary-op-expression--\n");
      genCodeFromASTree(node->child[0],level+1,out);  //child 0 is left hand side
      fprintf(out, "\taddi\tsp, sp, -4\n\tsw\t\tt0, 0(sp)\n");
      genCodeFromASTree(node->child[1],level+1,out);        // right hand side
      switch (node->ival) {   //switch to decide which instruction to use based on its operator
         case '+': instr = "add"; break;
         case '-': instr = "sub"; break;
         default: instr = "unknown ADDOP"; // handles unknown operator
      }
      fprintf(out, "\tlw\t\tt1, 0(sp)\n\taddi\tsp, sp, 4\n\t%s\t\tt0, t1, t0\n", instr);
      break;

    case AST_RELEXPR: // only for relational op expression
       fprintf(out,"\t# Relational Expression (op %d,%c)\n",node->ival,node->ival);
       genCodeFromASTree(node->child[0],0,out);  // child 0 is left side
       fprintf(out,"\taddi\tsp, sp, -4\n\tsw\t\tt0, 0(sp)\n");
       genCodeFromASTree(node->child[1],0,out);  // child 1 is right side
       switch (node->ival) {    // decide which instruction to use based on operator
        case '=': instr = "beq"; break;
        case '!': instr = "bne"; break;
        case '<': instr = "blt"; break;
        case '>': instr = "bgt"; break;
        default: instr = "unknown relop"; // handles unknown relational operator
       }
       fprintf(out,"\tlw\t\tt1, 0(sp)\n\taddi\tsp, sp, 4\n\t%s\t\tt1, t0, .LL%d\n",instr, labelCount);
       labelCount++;
       break;

    case AST_VARREF:
      if (node->varKind == V_GLOBAL) {
         fprintf(out, "\tlw\t\tt0, %s\n", node->strval);   // variable name(global)
      } else if (node->varKind == V_PARAM || node->varKind == V_LOCAL) {
         fprintf(out, "\tlw\t\tt0, %d(fp)\n", (node->ival+2)*4); // variable name(local)
      } else if (node->varKind == V_GLARRAY) {
         genCodeFromASTree(node->child[0],0,out);  //if index of array if referenced
         fprintf(out, "\tslli\tt0, t0, 2\n\tla\t\tt1, %s\n\tadd\t\tt1, t1, t0\n\tlw\t\tt0, 0(t1)\n", node->strval);
      } else {
         fprintf(out, "unknown var kind reference\n");   // handles unknown variable kind
      }
    break;

    case AST_CONSTANT: // for both int and string constants
      if (node->valType == T_INT) {
         fprintf(out, "\tli\t\tt0, %d\n", node->ival);   // for int constant
      } else if (node->valType == T_STRING) {
         fprintf(out, "\tla\t\tt0, .SC%d\n", node->ival);   //for string constant
      } else if (node->valType == T_RETURNVAL) {
         fprintf(out, "\tmv\t\tt0, a0\n");   //returns value
      }
       else {
          fprintf(out,"Unknown Constant\n"); //handles unknown constant
       }
       break;
    default:
       fprintf(out,"Unknown AST node!\n");
   }
    genCodeFromASTree(node->next,0,out);
}