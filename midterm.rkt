#lang racket

#|-----------------------------------------------------------------------------
;; CS 440 Midterm Exam (Take Home)
-----------------------------------------------------------------------------|#

(provide flatten-1
         riffle
         wordle
         until
         alternately
         stride
         parse
         desugar
         eval)


;;; Part 1: Recursion and Lists

(define (flatten-1 lst)
  void)


(define (riffle . lsts)
  void)


(define (wordle sol guess)
  void)
           

;;; Part 2: HOFs

(define (until pred fn x)
  void)
      

(define (alternately fns vals)
  void)


(define-syntax-rule (stride var n lst expr)
  void)


;;; Part 3: Interpreter (case expression)

;; integer value
(struct int-exp (val) #:transparent)

;; arithmetic expression
(struct arith-exp (op lhs rhs) #:transparent)

;; variable
(struct var-exp (id) #:transparent)

;; let expression
(struct let-exp (ids vals body) #:transparent)

;; lambda expression
(struct lambda-exp (id body) #:transparent)

;; function application
(struct app-exp (fn arg) #:transparent)


;; Parser
(define (parse sexp)
  (match sexp
    ;; integer literal
    [(? integer?)
     (int-exp sexp)]

    ;; arithmetic expression
    [(list (and op (or '+ '*)) lhs rhs)
     (arith-exp (symbol->string op) (parse lhs) (parse rhs))]

    ;; identifier (variable)
    [(? symbol?)
     (var-exp sexp)]

    ;; let expressions
    [(list 'let (list (list id val) ...) body)
     (let-exp (map parse id) (map parse val) (parse body))]

    ;; lambda expression -- modified for > 1 params
    [(list 'lambda (list ids ...) body)
     (lambda-exp ids (parse body))]

    ;; function application -- modified for > 1 args
    [(list f args ...)
     (app-exp (parse f) (map parse args))]

    ;; basic error handling
    [_ (error (format "Can't parse: ~a" sexp))]))


;; Desugar-er -- i.e., syntax transformer
(define (desugar exp)
  (match exp
    ((arith-exp op lhs rhs)
     (arith-exp op (desugar lhs) (desugar rhs)))
    
    ((let-exp ids vals body)
     (let-exp ids (map desugar vals) (desugar body)))

    ((lambda-exp ids body)
     (foldr (lambda (id lexp) (lambda-exp id lexp))
            (desugar body)
            ids))

    ((app-exp f args)
     (foldl (lambda (id fexp) (app-exp fexp id))
            (desugar f)
            (map desugar args)))
    
    (_ exp)))


;; function value + closure
(struct fun-val (id body env) #:transparent)


;; Interpreter
(define (eval expr [env '()])
  (match expr
    ;; int literal
    [(int-exp val) val]

    ;; arithmetic expression
    [(arith-exp "+" lhs rhs)
     (+ (eval lhs env) (eval rhs env))]
    [(arith-exp "*" lhs rhs)
     (* (eval lhs env) (eval rhs env))]         
          
    ;; variable binding
    [(var-exp id)
     (let ([pair (assoc id env)])
       (if pair (cdr pair) (error (format "~a not bound!" id))))]

    ;; let expression
    [(let-exp (list (var-exp id) ...) (list val ...) body)
     (let ([vars (map cons id
                      (map (lambda (v) (eval v env)) val))])
       (eval body (append vars env)))]

    ;; lambda expression
    [(lambda-exp id body)
     (fun-val id body env)]

    ;; function application
    [(app-exp f arg)
     (match-let ([(fun-val id body clenv) (eval f env)]
                 [arg-val (eval arg env)])
       (eval body (cons (cons id arg-val) clenv)))]

    ;; basic error handling
    [_ (error (format "Can't evaluate: ~a" expr))]))