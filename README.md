# toy-epi-language
Environment-passing interpreter implementing a toy language in Racket.

## Description:
This toy language (defined by the grammar below) supports a number of basic language features. Its built-in data-types include ints, floats, strings, and bools, and, being implemented by an environment-passing interpreter, the language also provides support for "let", "define", and "lambda" keywords, which together facilitate the use of closures and a number of other interesting programmatic approaches. The value returned by the execution of a program will be the value associated with the evaluation of the last "expr" in the program's "exprList".

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
- **Built-in data types:** int, float, string, bool
- **Built-in function names:** +, -, *, /, =, <, string-append, string\<?, string=?, not

## Examples:

### Keywords
| Feature | Program | Output |
| - | - | - |
| let | let (num 7) num | 7 |
| define | define str "examplestring" <br/> str | "examplestring" |
| lambda | (lambda (n) (+ 10 n) 3) | 13 |

### Built-In Functions
| Feature | Program | Output |
| - | - | - |
| + | (+ 5 7) | 12 |
| - | (- 5 3) | 2 |
| \* | (\* 8 2) | 16 |
| / | (/ 18 3) | 6 |
| = | (= 1 2) | #f |
| < | (< 1 100) | #t |
| string-append | (string-append "this" " and that") | "this and that" |
| string\<? | (string\<? "abc" "xyz") | #t |
| String=? | (string=? "twin" "twin") | #t |
| not | (not (= 4 4)) | #f |

### Further Examples
| Approach | Program | Output |
| - | - | - |
| nested "let"s | let (number_one 7) let (number_two 11) (* number_one number_two) | 77 |

This project was partially completed in fulfillment of the requirements of COMP 524 with Dr. Jeff Terrell at the University of North Carolina at Chapel Hill in spring 2021.
