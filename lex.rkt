#lang racket

#| Lexer |#

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


(provide lex)


; "lex" - the lexing program's high-level lexer function for lexing sourecode.
; Given a sourcecode string, identifies the longest substring appearing at the
; front of the string that matches a token type (with this matching defined by the
; Lexing Rules Table below), creates a token for that substring, and returns a
; list containing that token and whatever other token(s) are recursively found
; in the remainder of the sourcecode string excluding the portion matched
; in the current invocation.
(define (lex srccode)
  (if (equal? 0 (string-length srccode))
      null
      (let* ([re-table-output (map (lambda (entry) (regexp-match (first entry) srccode)) re-table)]
             [string-lengths  (string-lengths re-table-output)]
             [max-string-length (apply max string-lengths)]
             [max-string-index (index-of string-lengths max-string-length)] 
             [max-string-list-form (item-at-index max-string-index re-table-output)] 
             [appropriate-token-gen  (second (item-at-index max-string-index re-table))])
        (if (equal? max-string-length -1)
             (list (token 'INVALID srccode))
             (if (equal? appropriate-token-gen skip-match)
                 (lex (substring srccode max-string-length))
                 (cons (appropriate-token-gen(first max-string-list-form))
                       (lex (substring srccode max-string-length))))))))


;; Token creator functions - given a string matching a regular expression,
;; returns either a token corresponding to that string's type or #f where no token
;; should be created.

;;;; Token creator helper
(define (token type [data #f])
  (list type data))

;;;; skip-match
(define (skip-match str) #f)

;;;; punctuation
(define (punctuation-token str)
  (token
    (case str
      [("(") 'OPAREN]
      [(")") 'CPAREN])))

;;;; integer (number literal)
(define (integer-token str)
  (token 'INT (string->number str)))

;;;; float (number literal)
(define (float-token str)
  (token 'FLOAT (string->number str)))

;;;; string literal
(define (string-token str)
  (token 'STRING
                (substring str 1 (- (string-length str) 1))))

;;;; name or keyword
(define (name-or-keyword-token str)
  (case str
    [("let" "define" "lambda")
     (token (string->symbol (string-upcase (string-trim str))))]
    [else (token 'NAME (string->symbol str))]))


;; Lexing Rules Table - each item in the table is a list of two elements containing:
;; (1) a regular expression to recognize at the beginning of a string a substring warranting the creation of a token, and
;; (2) a function (from those above) to take the recognized string and create a corresponding token.
(define re-table
  (list
   (list #rx"^[ \r\n\t]+" skip-match) ; whitespace
   (list #rx"^;;[^\n]+(\n|$)" skip-match) ; comment type 1 -> ;; comment
   (list #rx"^;\\*.*?\\*;" skip-match) ; comment type 2 -> ;* comment *;
   (list #rx"^[()]" punctuation-token) ; punctuation
   (list #rx"^-?[0-9]+(?=[\r\n\t (){},;.]|$)" integer-token) ; integer - (number literal type 1)
   (list #rx"^-?[0-9]+\\.[0-9]+(?=[\r\n\t (){},;.]|$)" float-token) ; float - (number literal type 2)
   (list #rx"^\".*?\"(?=[\r\n\t (){},;.]|$)" string-token) ; string literals
   (list #rx"^[^0-9\"\r\n\t (){},;.][^\"\r\n\t (){},;.]*(?=[\r\n\t (){},;.]|$)" name-or-keyword-token))) ; names or keywords


;;;; "lex" helper functions - "string-lengths" and "item-at-index"

;;;;;; "string-lengths" - given a list of unary string lists and booleans,
;;;;;; returns a list of string lengths (providing a length of -1 if boolean).
(define (string-lengths list)
  (if (empty? list)
      null
      (if (boolean? (first list))
          (cons -1 (string-lengths (rest list)))
          (cons (string-length (first (first list)))
                (string-lengths (rest list))))))

;;;;;; "item-at-index" - given an index and a list,
;;;;;; returns the item at the specified index of the list.
(define (item-at-index index list)
  (letrec ([item-at-index-rec (lambda (curridx idx li)
                                (if (equal? curridx idx)
                                    (first li)
                                    (item-at-index-rec (add1 curridx)
                                                       idx
                                                       (rest li))))])
    (item-at-index-rec 0 index list)))
