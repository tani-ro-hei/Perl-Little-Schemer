#lang racket


;;    Chap. 1

;; S-Exp
;;  'atom    or (quote atom)    -> Atom
;;  '(a b c) or (quote (a b c)) -> List

;; car :: List(nonempty) -> S-Exp
;;  (car '(a b c))   -> 'a
;;  (car '((a b) c)) -> '(a b)

;; cdr :: List(nonempty) -> List
;;  (cdr '(a b c))     -> '(b c)
;;  (cdr '(a (b c) d)) -> '((b c) d)

;; cons :: S-Exp List -> List
;;  (cons 'a '(b c))     -> '(a b c)
;;  (cons '(a b) '(c d)) -> '((a b) c d)

;; null? :: List -> Bool
;;  (null? '())  -> #t
;;  (null? '(a)) -> #f

;; atom? :: S-Exp -> Bool
;;  (atom? 'a)   -> #t
;;  (atom? '(a)) -> #f
(define atom?
    (lambda (x)
        (and
            (not (pair? x))
            (not (null? x))
                )))

;; eq? :: Atom(nonnumerical), Atom(nonnumerical) -> Bool
;;  (eq? 'a 'a) -> #t
;;  (eq? 'a 'b) -> #f


;;    Chap. 2

;; lat? :: List -> Bool
;;  (lat? '(a b c))   -> #t
;;  (lat? '(a (b) c)) -> #f
(define lat?
    (lambda (l)
        (cond
            ((null? l) #t)
            ((atom? (car l)) (lat? (cdr l)))
            (else #f)
                )))

;; member? :: Atom, Lat -> Bool
;;  (member? 'a '(c a b)) -> #t
;;  (member? 'a '(d c b)) -> #f
(define member?
    (lambda (a lat)
        (cond
            ((null? lat) #f)
            (else
                (or
                    (eq? (car lat) a)
                    (member? a (cdr lat))
                        )))))


;;    Chap. 3

;; rember :: Atom, Lat -> Lat
;;  (rember 'b '(a b c b d)) -> '(a c b d)
;;  (rember 'b '(a x y))     -> '(a x y)
;;  (rember 'b '())          -> '()
(define rember
    (lambda (a lat)
        (cond
            ((null? lat) '())
            ((eq? (car lat) a) (cdr lat))
            (else
                (cons
                    (car lat)
                    (rember a (cdr lat))
                        )))))

;; firsts :: List(of nonempty Lists) -> List
;;  (firsts '((a b) (c d) (e f)))  -> '(a c e)
;;  (firsts '(((a) b) (() d) (e))) -> '((a) () e)
(define firsts
    (lambda (l)
        (cond
            ((null? l) '())
            (else
                (cons
                    (car (car l))
                    (firsts (cdr l))
                        )))))

;; insertR :: Atom, Atom, Lat -> Lat
;; insertL :: Atom, Atom, Lat -> Lat
;;  (insertR 'y 'x '(a b c))     -> '(a b c)
;;  (insertR 'y 'x '(a x b x c)) -> '(a x y b x c)
;;  (insertL 'y 'x '(a x b x c)) -> '(a y x b x c)
(define insertR
    (lambda (new old lat)
        (cond
            ((null? lat) '())
            (else
                (cond
                    ((eq? (car lat) old)
                        (cons old (cons new (cdr lat)))
                            )
                    (else
                        (cons
                            (car lat)
                            (insertR new old (cdr lat))
                                )))))))
(define insertL
    (lambda (new old lat)
        (cond
            ((null? lat) '())
            (else
                (cond
                    ((eq? (car lat) old)
                        (cons new lat)
                            )
                    (else
                        (cons
                            (car lat)
                            (insertL new old (cdr lat))
                                )))))))
