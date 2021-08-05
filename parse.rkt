#lang racket

#| Parser |#

#| GRAMMAR:
program     := exprList
exprList    := expr optExprList
optExprList := ɛ | exprList
expr        := atom | invocation | let | define | lambda
let         := LET OPAREN NAME expr CPAREN expr
define      := DEFINE NAME expr
lambda      := LAMBDA OPAREN NAME CPAREN expr
atom        := NAME | STRING | number
number      := INT | FLOAT
invocation  := OPAREN exprList CPAREN
|#

#|
    NOTE: This parsing program relies on the use of a global mutable variable holding the remaining
    tokens to be parsed. This approach is not necessarily best-practice, but simplifies parser implementation
    sufficiently enough in this case to warrant its use. As such, though, some of the "functions" below are
    not technically "pure", as they may mutate the global token stream variable.
|#


(provide parse)


; Import lexer function "lex" from lex.rkt
(require (only-in (file "lex.rkt") lex))


; Set input token stream global variable
(define tokens (make-parameter null))


; "parse" - the parsing program's high-level function for parsing sourcecode,
; which makes use of "lex" to create a stream of tokens and the built-in
; "parameterize" to set the stream of tokens to be a "global" (dynamically
; scoped) variable.
(define (parse code)
  (parameterize ([tokens (lex code)])
    (parse-program)))


;; Production rule "parsing" functions
;;; These functions are used for the parsing of a given non-terminal based on its
;;; corresponding production rule.

;;; "parse-program" - parser function for the starting production rule (the rule
;;; whose left-side is the non-terminal 'program').
(define (parse-program)
  (list 'program (parse-exprList)))

;;; "parse-exprList" - parser function for the production rule whose left-side
;;; is the non-terminal 'exprList'.
(define (parse-exprList)
  (list 'exprList (parse-expr) (parse-optExprList)))

;;; "parse-optExprList" - parser function for the production rule whose left-side
;;; is the non-terminal 'optExprList'.
(define (parse-optExprList)
  (if (exprList-pending?)
      (list 'optExprList (parse-exprList))
      (list 'optExprList)))

;;; "parse-expr" - parser function for the production rule whose left-side is
;;; the non-terminal 'expr'.
(define (parse-expr)
  (cond
    [(atom-pending?) (list 'expr (parse-atom))]
    [(invocation-pending?) (list 'expr (parse-invocation))]
    [(let-pending?) (list 'expr (parse-let))]
    [(define-pending?) (list 'expr (parse-define))]
    [else (list 'expr (parse-lambda))]))

;;; "parse-let" - parser function for the production rule whose left-side is
;;; the non-terminal 'let'.
(define (parse-let)
  (list 'let
        (consume 'LET)
        (consume 'OPAREN)
        (consume 'NAME)
        (parse-expr)
        (consume 'CPAREN)
        (parse-expr)))

;;; "parse-define" - parser function for the production rule whose left-side is
;;; the non-terminal 'define'.
(define (parse-define)
  (list 'define
        (consume 'DEFINE)
        (consume 'NAME)
        (parse-expr)))

;;; "parse-lambda" - parser function for the production rule whose left-wise is
;;; the non-terminal 'lambda'.
(define (parse-lambda)
  (list 'lambda
        (consume 'LAMBDA)
        (consume 'OPAREN)
        (consume 'NAME)
        (consume 'CPAREN)
        (parse-expr)))

;;; "parse-atom" - parser function for the production rule whose left-side is
;;; the non-terminal 'atom'.
(define (parse-atom)
  (if (check 'NAME)
      (list 'atom (consume 'NAME))
      (if (check 'STRING)
          (list 'atom (consume 'STRING))
          (list 'atom (parse-number)))))

;;; "parse-number" - parser function for the production rule whose left-side is
;;; the non-terminal 'number'.
(define (parse-number)
  (if (check 'INT)
      (list 'number (consume 'INT))
      (list 'number (consume 'FLOAT))))
  
;;; "parse-invocation" - parser function for the production rule whose left-side
;;; is the non-terminal 'invocation'.
(define (parse-invocation)
  (list 'invocation (consume 'OPAREN) (parse-exprList) (consume 'CPAREN)))


;; Production rule "pending" functions
;;; In cases where a non-terminal resolves alternation for a given production rule, these functions are
;;; used to test whether a given non-terminal is a viable derivation given the remaining tokens
;;; in the token stream.

;;; "exprList-pending?" - determines whether a 'exprList' non-terminal is a viable derivation
;;; for a given non-terminal based on the next token input in the token input stream.
(define (exprList-pending?)
  (expr-pending?))

;;; "expr-pending?" - determines whether a 'expr' non-terminal is a viable derivation
;;; for a given non-terminal based on the next token input in the token input stream.
(define (expr-pending?)
  (or (atom-pending?)
      (invocation-pending?)
      (let-pending?)
      (define-pending?)
      (lambda-pending?)))

;;; "let-pending?" - determines whether a 'let' non-terminal is a viable derivation
;;; for a given non-terminal based on the next token input in the token input stream.
(define (let-pending?)
  (check 'LET))

;;; "define-pending?" - determines whether a 'define' non-terminal is a viable derivation
;;; for a given non-terminal based on the next token input in the token input stream.
(define (define-pending?)
  (check 'DEFINE))

;;; "lambda-pending?" - determines whether a "lambda" non-terminal is a viable derivation
;;; for a given non-terminal based on the next token input in the token input stream.
(define (lambda-pending?)
  (check 'LAMBDA))

;;; "atom-pending?" - determines whether an 'atom' non-terminal is a viable derivation
;;; for a given non-terminal based on the next token input in the token input stream.
(define (atom-pending?)
  (or (check 'NAME)
      (check 'STRING)
      (number-pending?)))

;;; "number-pending?" - determines whether a 'number' non-terminal is a viable derivation
;;; for a given non-terminal based on the next token input in the token input stream.
(define (number-pending?)
  (or (check 'INT)
      (check 'FLOAT)))

;;; "invocation-pending?" - determines whether a 'invocation' non-terminal is a viable derivation
;;; for a given non-terminal based on the next token input in the token input stream.
(define (invocation-pending?)
  (check 'OPAREN))


;; General helper functions - "check" and "consume"

;;; "check" - checks (1) whether another token remains in the stream of tokens to be parsed and
;;; (2) that the token is of type 'type'. Handles the 1-token look-ahead functionality necessary
;;; for LL(1) grammar parsers in cases of alternation within the grammar's production rules.
(define (check type)
  (if (empty? (tokens))
      #f
      (equal? type (first (first (tokens))))))

;;; "consume" - removes the token from the head of the global token stream and returns it. Checks
;;; both that there are tokens remaining in the token stream and that the token is of the expected type,
;;; throwing respective errors if these conditions are not satisfied. 
(define (consume type)
  (when (empty? (tokens))
    (error (~a "expected token of type " type " but no remaining tokens")))
  (let ([token (first (tokens))])
    (when (not (equal? type (first token)))
      (error (~a "expected token of type " type " but actual token was " token)))
    (tokens (rest (tokens)))  ; update global "tokens" variable by removing the first token
    token))
