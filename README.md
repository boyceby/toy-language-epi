# toy-language-epi
Environment-passing interpreter implementing a toy language in Racket.

## Description:
The toy language implemented by this EPI (defined by the grammar below) supports a number of basic language features. Its data types include ints, floats, strings, and bools, and its keywords include "let", "define", and "lambda", which together facilitate the ability to define functions, create closures, and make use of several other interesting programmatic approaches. Additionally, the language supports a variety of rudimentary built-in functions (which behaviorally take after the functions of the same names in the Racket language). The value ultimately returned by the execution of a program in the language will be the result of the evaluation of the last "expr" in the program's "exprList".

## Grammar:
1. program := exprList
2. exprList := expr optExprList
3. optExprList := ɛ | exprList
4. expr := atom | invocation | let | define | lambda
5. let := LET OPAREN NAME expr CPAREN expr
6. define := DEFINE NAME expr
7. lambda := LAMBDA OPAREN NAME CPAREN expr
8. atom := NAME | STRING | number
9. number := INT | FLOAT
10. invocation := OPAREN exprList CPAREN

## Features:
- **Keywords:** let, define, lambda
- **Data types:** int, float, string, bool
- **Built-in functions:** +, -, *, /, =, <, string-append, string\<?, string=?, not

## Examples:

### Keywords
| Feature | Program | Output |
| - | - | - |
| let | let (num 7) num | 7 |
| define | define str "examplestring" <br/> str | "examplestring" |
| lambda | define funct lambda (n) (+ 10 n) <br/> (funct 3) | 13 |

### Built-In Functions
| Feature | Program | Output |
| - | - | - |
| + | (+ 5 7) | 12 |
| - | (- 4.75 3.25) | 1.5 |
| \* | (\* 8 2) | 16 |
| / | (/ 18 3) | 6 |
| = | (= 1 2) | #f |
| < | (< 1 100) | #t |
| string-append | (string-append "this" " and that") | "this and that" |
| string\<? | (string\<? "abc" "xyz") | #t |
| string=? | (string=? "twin" "twin") | #t |
| not | (not (= 4 4)) | #f |

### Some Further Examples
| Approach | Program | Output |
| - | - | - |
| nested "let"s | let (number_one 7) let (number_two 11) (* number_one number_two) | 77 |
| closure | define n 1 <br/> define exampleclosurefunct let (m 8) lambda (x) (+ (- m n) x) <br/> (exampleclosurefunct 3) | 10 |
| anonymous function invocation | (lambda (n) (string-append "Hello, " n) "Casper") | "Hello, Casper" |

## To Use:
To test the interpreter out, these files can be run from [DrRacket](https://racket-lang.org/), where the "eval" function from "eval.rkt" can be invoked in the interactions window with a string containing the sourcecode for a program, like so:

    (eval 
          "
           define islessthanfive lambda (n) let (m 5) (< n m)
           (islessthanfive 1)
          "
    )
    
    Output: #t


This project was partially completed in fulfillment of the requirements of COMP 524 with Dr. Jeff Terrell at the University of North Carolina at Chapel Hill in spring 2021.
