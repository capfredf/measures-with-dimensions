#lang racket/base

(provide m: m+ m- m1/ mexpt m* m*/scalar m*/vector (rename-out [m: m]))

(require (submod "../dimensions/dimension-struct.rkt" untyped)
         (submod "../dimensions/dimension-operations.rkt" untyped)
         (submod "../units/unit-struct.rkt" untyped)
         (submod "../units/unit-operations.rkt" untyped)
         (submod "measure-struct.rkt" untyped)
         (submod "physical-constants.rkt" untyped)
         (submod "typed-operations-1.rkt" untyped)
         (only-in typed/racket/base assert : ann)
         typed/untyped-utils
         (for-syntax racket/base
                     syntax/parse
                     typed/untyped-utils
                     ))

(module+ test
  (require rackunit
           (submod "../units/units.rkt" untyped)))

(begin-for-syntax
  (define-syntax-class mexpr #:description "non-operation expression"
    #:attributes (norm) #:literals (:) #:datum-literals (+ - * / ^ =)
    [pattern (~and expr:expr (~not (~or + - * / ^ = :)))
             #:with norm #'expr])
  (define-splicing-syntax-class mwith #:description "a math expression"
    #:attributes (norm) #:datum-literals (=)
    [pattern (~seq #:with a:m-ann #:as id:id (~optional #:in) b:mwith)
             #:with norm #'(let ([id a.norm]) b.norm)]
    [pattern (~seq #:let id:id = a:m-ann #:in b:mwith)
             #:with norm #'(let ([id a.norm]) b.norm)]
    [pattern (~seq a:m-ann) #:with norm #'a.norm])
  (define-splicing-syntax-class m-ann #:description "a math expression"
    #:attributes (norm) #:literals (:)
    [pattern (~seq a:msum : t:expr) #:when (syntax-local-typed-context?)
             #:with norm #'(ann a.norm : t)]
    [pattern (~seq a:msum) #:with norm #'a.norm])
  (define-splicing-syntax-class msum #:description "a math expression"
    #:attributes (norm)
    [pattern (~seq (~or a:mproduct a:+-mproduct)) #:with norm #'a.norm]
    [pattern (~seq (~or a:mproduct a:+-mproduct) b:+-mproduct ...+)
             #:with norm #'(m+ a.norm b.norm ...)])
  (define-splicing-syntax-class mproduct #:description "a math expression without + or -"
    #:attributes (norm)
    [pattern (~seq) #:with norm #'1-measure]
    [pattern (~seq a:mexpt) #:with norm #'a.norm]
    [pattern (~seq a:mexpt b:*/mexpt ...) #:with norm #'(m* a.norm b.norm ...)])
  (define-splicing-syntax-class mexpt #:description "a math expression without +, -, *, or /"
    #:attributes (norm) #:datum-literals (^)
    [pattern (~seq a:mexpr) #:with norm #'a.norm]
    [pattern (~seq a:mexpr ^ b:mexpr) #:with norm #'(mexpt a.norm b.norm)])
  
  (define-splicing-syntax-class +-mproduct #:description "an expression with a + or -"
    #:attributes (norm) #:datum-literals (+ -)
    [pattern (~seq + a:mproduct) #:with norm #'a.norm]
    [pattern (~seq - a:mproduct) #:with norm #'(m- a.norm)])
  (define-splicing-syntax-class */mexpt #:description "an expression with a * or /"
    #:attributes (norm) #:datum-literals (* /)
    [pattern (~seq a:mexpt) #:with norm #'a.norm]
    [pattern (~seq * a:mexpt) #:with norm #'a.norm]
    [pattern (~seq / a:mexpt) #:with norm #'(m1/ a.norm)])
  )

(define-syntax m:
  (syntax-parser
    [(m a:mwith) #'a.norm]))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(module+ test
  (define-check (check-m=? m1 m2)
    (check m=? m1 m2))
  (check-m=? (m:) 1-measure)
  (check-m=? (m: 1 meter) (make-Measure 1 meter))
  (check-m=? (convert (m: 1 meter) centimeter) (m: 100 centimeter))
  (check-m=? (m: 1 meter + 50 centimeter) (m: (+ 1 1/2) meter))
  (check-m=? (m: 1 meter - 50 centimeter) (m: 1/2 meter))
  (check-m=? (m: 1 meter ^ 2) (m: 1 square-meter))
  (check-m=? (m: 2 meter ^ 2) (m: 2 square-meter))
  (check-m=? (m: (m: 2 meter) ^ 2) (m: 4 square-meter))
  (check-m=? (m: 1 kilogram meter / second ^ 2) (m: 1 newton))
  (check-m=? (m: 1 newton meter) (m: 1 joule))
  (check-m=? (m: #:with 1 + 2 #:as a
                 #:with 3 + 4 #:as b
                 a + b)
             10)
  (check-m=? (m: #:with 1 + 2 #:as a
                 #:let b = 3 + 4 #:in
                 a + b)
             10)
  
  )