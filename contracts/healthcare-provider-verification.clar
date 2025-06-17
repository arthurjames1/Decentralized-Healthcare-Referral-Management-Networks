(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-REGISTERED (err u101))
(define-constant ERR-NOT-REGISTERED (err u102))
(define-constant ERR-ALREADY-VERIFIED (err u103))
(define-constant ERR-NOT-VERIFIED (err u104))

(define-data-var admin principal tx-sender)
(define-map Providers
  { provider: principal }
  {
    is-verified: bool,
    name: (string-ascii 100),
    license: (string-ascii 50),
    specialty: (string-ascii 50),
    registration-timestamp: uint,
    verification-timestamp: (optional uint)
  }
)

(define-public (register-provider (name (string-ascii 100)) (license (string-ascii 50)) (specialty (string-ascii 50)))
  (let ((provider-entry (map-get? Providers { provider: tx-sender })))
    (asserts! (is-none provider-entry) ERR-ALREADY-REGISTERED)
    (map-set Providers
      { provider: tx-sender }
      {
        is-verified: false,
        name: name,
        license: license,
        specialty: specialty,
        registration-timestamp: block-height,
        verification-timestamp: none
      }
    )
    (ok true)
  )
)

(define-public (verify-provider (provider principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-AUTHORIZED)
    (let ((provider-entry (unwrap! (map-get? Providers { provider: provider }) ERR-NOT-REGISTERED)))
      (asserts! (not (get is-verified provider-entry)) ERR-ALREADY-VERIFIED)
      (map-set Providers
        { provider: provider }
        (merge provider-entry { is-verified: true, verification-timestamp: (some block-height) })
      )
      (ok true)
    )
  )
)

(define-read-only (get-provider-info (provider principal))
  (map-get? Providers { provider: provider })
)

(define-public (update-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-AUTHORIZED)
    (var-set admin new-admin)
    (ok true)
  )
)
