#lang racket

#| Evaluator |#

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


(provide eval)


(require (only-in (file "parse.rkt") parse))


; Environment interface functions (with the environment implemented as a hash table)
(define new-environment hash)
(define add-binding hash-set)
(define lookup-name hash-ref)


; "eval" - high-level evaluation function. Initiates evaluation by
; parsing the provided sourcecode using "parse" and calling "eval-program"
; (the evaluation function for "program", the starting production rule's
; left-hand non-terminal) with the parsed sourcecode's parse-tree and
; an empty, initial environment.
(define (eval code)
  (eval-program (parse code) (new-environment)))


;  Non-terminal and terminal (token) evaluation functions
;; These functions define how a given non-terminal's associated
;; parse-tree and/or how a given token is to be evaluated.

;; Evaluation function for the "program" non-terminal
(define (eval-program program-expr env)
  ; program     := exprList
  (let ([exprList-expr (second program-expr)])
    (last (eval-exprList exprList-expr env))))

;; Evaluation function for the "exprList" non-terminal
(define (eval-exprList exprList-expr env)
  ; exprList    := expr optExprList 
  (letrec ([expr-expr (second exprList-expr)]
           [expr-expr-type (first (second expr-expr))]
           [expr-expr-value (eval-expr expr-expr env)]
           [optExprList-expr (third exprList-expr)])
    (if (equal? 'define expr-expr-type)
        (eval-optExprList expr-expr-value
                          optExprList-expr
                          (add-binding env
                                       (second (third (second expr-expr)))
                                       expr-expr-value))
        (eval-optExprList expr-expr-value optExprList-expr env))))

;; Evaluation function for the "optExprList" non-terminal
(define (eval-optExprList expr-value optExprList-expr env)
  ; optExprList := ɛ | exprList
  (if (= 1 (length optExprList-expr))
      (cons expr-value null)
      (cons expr-value (eval-exprList (second optExprList-expr) env))))

;; Evaluation function for the "expr" non-terminal
(define (eval-expr expr-expr env)
  ; expr        := atom | invocation | let | define | lambda
  (let* ([child (second expr-expr)]
         [child-label (first child)])
    (case child-label
      [(atom) (eval-atom child env)]
      [(invocation) (eval-invocation child env)]
      [(let) (eval-let child env)]
      [(define) (eval-define child env)]
      [else (eval-lambda child env)])))

;; Evaluation function for the "let" non-terminal
(define (eval-let let-expr env)
  ; let         := LET OPAREN NAME expr CPAREN expr
  (let* ([binding-name (second (fourth let-expr))]
         [binding-value (eval-expr (fifth let-expr) env)]
         [body-expr (seventh let-expr)])
    (eval-expr body-expr (add-binding env binding-name binding-value))))

;; Evaluation function for the "define" non-terminal
(define (eval-define define-expr env)
  ; define      := DEFINE NAME expr
  (let* ([binding-name (second (third define-expr))]
         [binding-value (eval-expr (fourth define-expr) env)])
    binding-value))

;; Evaluation function for the "lambda" non-terminal
(define (eval-lambda lambda-expr env)
  ; lambda      := LAMBDA OPAREN NAME CPAREN expr
  (let* ([parameter-name (second (fourth lambda-expr))]
         [body-expr (sixth lambda-expr)])
    (list parameter-name body-expr env))) 

;; Evaluation function for the "atom" non-terminal
(define (eval-atom atom-expr env)
  ;; atom        := NAME | STRING | number
  (let* ([name-string-number-expr (second atom-expr)]
         [expr-type (first name-string-number-expr)])
    (case expr-type
      [(NAME) (eval-name name-string-number-expr env)]
      [(STRING) (eval-string name-string-number-expr env)]
      [(number) (eval-number name-string-number-expr env)])))

;; Evaluation function for the "invocation" non-terminal
(define (eval-invocation invocation-expr env)
  ; invocation  := OPAREN exprList CPAREN
  (let* ([exprList-value (eval-exprList (third invocation-expr) env)]
         [rator (first exprList-value)]
         [rands (rest exprList-value)])
    (cond
      [(list? rator) (let* ([parameter (first rator)]
                            [body-expr (second rator)]
                            [lambda-env (third rator)]
                            [argument (first rands)])
                       (eval-expr body-expr (add-binding lambda-env
                                                         parameter
                                                         argument)))]               
      [(or (equal? rator +)
            (equal? rator -)
            (equal? rator *)
            (equal? rator /)
            (equal? rator string-append)
            (equal? rator string<?)
            (equal? rator string=?)
            (equal? rator not)
            (equal? rator =)
            (equal? rator <)) (apply rator rands)]
      [else (error "invalid rator - " rator " - provided")])))

;; Evaluation function for the "number" non-terminal (and INT
;; and FLOAT tokens)
(define (eval-number number-expr env)
  ;; number      := INT | FLOAT
  (second (second number-expr)))

;; Evaluation function for the "NAME" token
(define (eval-name name-expr env)
  ;; + - * / string-append string<? string=? not = <
  (case (second name-expr)
    [(+) +]
    [(-) -]
    [(*) *]
    [(/) /]
    [(string-append) string-append]
    [(string<?) string<?]
    [(string=?) string=?]
    [(not) not]
    [(=) =]
    [(<) <]
    [else (lookup-name env (second name-expr))]))

;; Evaluation function for the "STRING" token
(define (eval-string string-expr env)
  (second string-expr))
