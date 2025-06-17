;; Map to store alumni data
(define-map alumni-directory
  {user: principal}  ;; key
  {name: (string-ascii 50), grad-year: uint}) ;; value

(define-constant err-empty-name (err u100))
(define-constant err-invalid-year (err u101))

;; Public function to register/update alumni info
(define-public (register-alumni (name (string-ascii 50)) (grad-year uint))
  (begin
    (asserts! (> (len name) u0) err-empty-name)
    (asserts! (>= grad-year u1950) err-invalid-year) ;; Example range check
    (map-set alumni-directory 
             {user: tx-sender} 
             {name: name, grad-year: grad-year})
    (ok true)))

;; Read-only function to get caller's alumni record
(define-read-only (get-my-alumni-info)
  (let ((entry (map-get? alumni-directory {user: tx-sender})))
    (ok (match entry
         val (some {
           name: (get name val), 
           grad-year: (get grad-year val)
         })
         none))))
