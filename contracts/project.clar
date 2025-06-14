;; Alumni Directory Contract
;; A decentralized alumni network for keeping graduates connected

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-alumni-not-found (err u103))
(define-constant err-invalid-data (err u104))

;; Data structures
(define-map alumni-profiles 
  principal 
  {
    name: (string-ascii 64),
    graduation-year: uint,
    degree: (string-ascii 32),
    contact-email: (string-ascii 64),
    current-company: (string-ascii 64),
    is-active: bool,
    registration-block: uint
  })

(define-map alumni-connections
  {from: principal, to: principal}
  {
    connected-at: uint,
    connection-type: (string-ascii 20)
  })

;; Contract state variables
(define-data-var total-alumni uint u0)
(define-data-var contract-active bool true)

;; Function 1: Register Alumni Profile
(define-public (register-alumni 
  (name (string-ascii 64))
  (graduation-year uint)
  (degree (string-ascii 32))
  (contact-email (string-ascii 64))
  (current-company (string-ascii 64)))
  (begin
    ;; Validate inputs
    (asserts! (> (len name) u0) err-invalid-data)
    (asserts! (> graduation-year u1900) err-invalid-data)
    (asserts! (> (len degree) u0) err-invalid-data)
    (asserts! (> (len contact-email) u0) err-invalid-data)
    
    ;; Check if alumni is already registered
    (asserts! (is-none (map-get? alumni-profiles tx-sender)) err-already-registered)
    
    ;; Register the alumni profile
    (map-set alumni-profiles tx-sender
      {
        name: name,
        graduation-year: graduation-year,
        degree: degree,
        contact-email: contact-email,
        current-company: current-company,
        is-active: true,
        registration-block: block-height
      })
    
    ;; Update total alumni count
    (var-set total-alumni (+ (var-get total-alumni) u1))
    
    ;; Print registration event
    (print {
      event: "alumni-registered",
      alumni: tx-sender,
      name: name,
      graduation-year: graduation-year,
      block: block-height
    })
    
    (ok true)))

;; Function 2: Connect with Alumni
(define-public (connect-with-alumni 
  (target-alumni principal)
  (connection-type (string-ascii 20)))
  (begin
    ;; Validate that both sender and target are registered alumni
    (asserts! (is-some (map-get? alumni-profiles tx-sender)) err-not-authorized)
    (asserts! (is-some (map-get? alumni-profiles target-alumni)) err-alumni-not-found)
    
    ;; Validate connection type is not empty
    (asserts! (> (len connection-type) u0) err-invalid-data)
    
    ;; Cannot connect to yourself
    (asserts! (not (is-eq tx-sender target-alumni)) err-invalid-data)
    
    ;; Create bidirectional connection
    (map-set alumni-connections 
      {from: tx-sender, to: target-alumni}
      {
        connected-at: block-height,
        connection-type: connection-type
      })
    
    (map-set alumni-connections 
      {from: target-alumni, to: tx-sender}
      {
        connected-at: block-height,
        connection-type: connection-type
      })
    
    ;; Print connection event
    (print {
      event: "alumni-connected",
      from: tx-sender,
      to: target-alumni,
      connection-type: connection-type,
      block: block-height
    })
    
    (ok true)))

;; Read-only functions for querying data

;; Get alumni profile
(define-read-only (get-alumni-profile (alumni principal))
  (map-get? alumni-profiles alumni))

;; Get connection between two alumni
(define-read-only (get-connection (from principal) (to principal))
  (map-get? alumni-connections {from: from, to: to}))

;; Get total registered alumni
(define-read-only (get-total-alumni)
  (var-get total-alumni))

;; Check if alumni is registered
(define-read-only (is-alumni-registered (alumni principal))
  (is-some (map-get? alumni-profiles alumni)))

;; Get contract status
(define-read-only (get-contract-status)
  (var-get contract-active))

;; Admin function to deactivate contract (only owner)
(define-public (toggle-contract-status)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set contract-active (not (var-get contract-active)))
    (ok (var-get contract-active))))