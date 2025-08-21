;; Title: Aurelius Protocol - Fractional NFT Finance
;;
;; Summary:
;; Aurelius is a pioneering NFT financial protocol that bridges collectible culture
;; with institutional-grade DeFi mechanics. It introduces collateral-backed minting,
;; programmable fractionalization, and automated staking rewards for long-term value
;; creation. Designed for high-value asset holders and community investors alike.
;;
;; Description:
;; Aurelius reshapes NFT ownership by fusing digital collectibles with advanced
;; financial instruments. Each asset is minted with mandatory collateralization,
;; tradable as a whole or in fractionalized shares, and capable of generating yield
;; through an integrated staking engine. The protocol enforces fee-efficient trading,
;; automated yield accrual, and verifiable ownership transfers with robust safeguards.
;; This design enables both individual collectors and institutional actors to access
;; secure, transparent, and liquid NFT markets with built-in income potential.
;;

;; CORE CONSTANTS & ERROR CODES

(define-constant contract-owner tx-sender)

;; Error codes for precise failure handling
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-invalid-token (err u103))
(define-constant err-listing-not-found (err u104))
(define-constant err-invalid-price (err u105))
(define-constant err-insufficient-collateral (err u106))
(define-constant err-already-staked (err u107))
(define-constant err-not-staked (err u108))
(define-constant err-invalid-percentage (err u109))
(define-constant err-invalid-uri (err u110))
(define-constant err-invalid-recipient (err u111))
(define-constant err-overflow (err u112))

;; PROTOCOL CONFIGURATION

(define-data-var min-collateral-ratio uint u150) ;; Collateralization: 150%
(define-data-var protocol-fee uint u25) ;; 2.5% platform fee in basis points
(define-data-var total-staked uint u0) ;; Counter for all staked assets
(define-data-var yield-rate uint u50) ;; Annual yield = 5% (basis points)
(define-data-var total-supply uint u0) ;; NFT supply tracker

;; DATA STRUCTURES

;; Token registry containing metadata & state
(define-map tokens
  { token-id: uint }
  {
    owner: principal,
    uri: (string-ascii 256),
    collateral: uint,
    is-staked: bool,
    stake-timestamp: uint,
    fractional-shares: uint,
  }
)

;; Marketplace listing registry
(define-map token-listings
  { token-id: uint }
  {
    price: uint,
    seller: principal,
    active: bool,
  }
)

;; Fractional ownership ledger
(define-map fractional-ownership
  {
    token-id: uint,
    owner: principal,
  }
  { shares: uint }
)

;; Staking reward accumulator
(define-map staking-rewards
  { token-id: uint }
  {
    accumulated-yield: uint,
    last-claim: uint,
  }
)

;; INTERNAL VALIDATION UTILITIES

;; Validate metadata URI
(define-private (validate-uri (uri (string-ascii 256)))
  (let ((uri-len (len uri)))
    (and (> uri-len u0) (<= uri-len u256))
  )
)

;; Prevent transfers to contract itself
(define-private (validate-recipient (recipient principal))
  (not (is-eq recipient (as-contract tx-sender)))
)

;; Overflow-safe addition
(define-private (safe-add
    (a uint)
    (b uint)
  )
  (let ((sum (+ a b)))
    (asserts! (>= sum a) err-overflow)
    (ok sum)
  )
)

;; NFT CORE OPERATIONS

;; Mint collateral-backed NFT
(define-public (mint-nft
    (uri (string-ascii 256))
    (collateral uint)
  )
  (let (
      (token-id (+ (var-get total-supply) u1))
      (collateral-requirement (/ (* (var-get min-collateral-ratio) collateral) u100))
    )
    (asserts! (validate-uri uri) err-invalid-uri)
    (asserts! (>= (stx-get-balance tx-sender) collateral-requirement)
      err-insufficient-collateral
    )

    ;; Lock collateral
    (try! (stx-transfer? collateral-requirement tx-sender (as-contract tx-sender)))

    ;; Register NFT
    (map-set tokens { token-id: token-id } {
      owner: tx-sender,
      uri: uri,
      collateral: collateral,
      is-staked: false,
      stake-timestamp: u0,
      fractional-shares: u0,
    })

    (var-set total-supply token-id)
    (ok token-id)
  )
)

;; Transfer entire NFT ownership
(define-public (transfer-nft
    (token-id uint)
    (recipient principal)
  )
  (let ((token (unwrap! (get-token-info token-id) err-invalid-token)))
    (asserts! (validate-recipient recipient) err-invalid-recipient)
    (asserts! (is-eq tx-sender (get owner token)) err-not-token-owner)
    (asserts! (not (get is-staked token)) err-already-staked)

    (map-set tokens { token-id: token-id } (merge token { owner: recipient }))
    (ok true)
  )
)

;; MARKETPLACE MODULE

;; Create NFT sale listing
(define-public (list-nft
    (token-id uint)
    (price uint)
  )
  (let ((token (unwrap! (get-token-info token-id) err-invalid-token)))
    (asserts! (> price u0) err-invalid-price)
    (asserts! (is-eq tx-sender (get owner token)) err-not-token-owner)
    (asserts! (not (get is-staked token)) err-already-staked)

    (map-set token-listings { token-id: token-id } {
      price: price,
      seller: tx-sender,
      active: true,
    })
    (ok true)
  )
)

;; Buy NFT with auto fee distribution
(define-public (purchase-nft (token-id uint))
  (let (
      (listing (unwrap! (get-listing token-id) err-listing-not-found))
      (price (get price listing))
      (seller (get seller listing))
      (fee (/ (* price (var-get protocol-fee)) u1000))
    )
    (asserts! (get active listing) err-listing-not-found)

    ;; Payment routing
    (try! (stx-transfer? price tx-sender seller))
    (try! (stx-transfer? fee tx-sender (as-contract tx-sender)))

    ;; Ownership transfer
    (try! (transfer-nft token-id tx-sender))

    ;; Close listing
    (map-set token-listings { token-id: token-id } {
      price: u0,
      seller: seller,
      active: false,
    })
    (ok true)
  )
)

;; FRACTIONAL OWNERSHIP MODULE

(define-public (transfer-shares
    (token-id uint)
    (recipient principal)
    (share-amount uint)
  )
  (let (
      (sender-shares (unwrap! (get-fractional-shares token-id tx-sender)
        err-insufficient-balance
      ))
      (recipient-current (default-to { shares: u0 } (get-fractional-shares token-id recipient)))
      (recipient-new (unwrap! (safe-add (get shares recipient-current) share-amount)
        err-overflow
      ))
    )
    (asserts! (validate-recipient recipient) err-invalid-recipient)
    (asserts! (>= (get shares sender-shares) share-amount)
      err-insufficient-balance
    )

    ;; Update balances
    (map-set fractional-ownership {
      token-id: token-id,
      owner: tx-sender,
    } { shares: (- (get shares sender-shares) share-amount) }
    )

    (map-set fractional-ownership {
      token-id: token-id,
      owner: recipient,
    } { shares: recipient-new }
    )
    (ok true)
  )
)

;; STAKING & YIELD MODULE

;; Stake NFT
(define-public (stake-nft (token-id uint))
  (let ((token (unwrap! (get-token-info token-id) err-invalid-token)))
    (asserts! (is-eq tx-sender (get owner token)) err-not-token-owner)
    (asserts! (not (get is-staked token)) err-already-staked)

    (map-set tokens { token-id: token-id }
      (merge token {
        is-staked: true,
        stake-timestamp: stacks-block-height,
      })
    )

    (map-set staking-rewards { token-id: token-id } {
      accumulated-yield: u0,
      last-claim: stacks-block-height,
    })

    (var-set total-staked (+ (var-get total-staked) u1))
    (ok true)
  )
)

;; Unstake NFT
(define-public (unstake-nft (token-id uint))
  (let (
      (token (unwrap! (get-token-info token-id) err-invalid-token))
      (rewards (unwrap! (get-staking-rewards token-id) err-not-staked))
    )
    (asserts! (is-eq tx-sender (get owner token)) err-not-token-owner)
    (asserts! (get is-staked token) err-not-staked)

    (try! (claim-staking-rewards token-id))

    (map-set tokens { token-id: token-id }
      (merge token {
        is-staked: false,
        stake-timestamp: u0,
      })
    )

    (var-set total-staked (- (var-get total-staked) u1))
    (ok true)
  )
)

;; READ-ONLY VIEWS

(define-read-only (get-token-info (token-id uint))
  (map-get? tokens { token-id: token-id })
)

(define-read-only (get-listing (token-id uint))
  (map-get? token-listings { token-id: token-id })
)

(define-read-only (get-fractional-shares
    (token-id uint)
    (owner principal)
  )
  (map-get? fractional-ownership {
    token-id: token-id,
    owner: owner,
  })
)

(define-read-only (get-staking-rewards (token-id uint))
  (map-get? staking-rewards { token-id: token-id })
)

;; REWARDS ENGINE

(define-read-only (calculate-rewards (token-id uint))
  (let (
      (token (unwrap! (get-token-info token-id) err-invalid-token))
      (rewards (unwrap! (get-staking-rewards token-id) err-not-staked))
      (blocks-staked (- stacks-block-height (get stake-timestamp token)))
      (yield-per-block (/ (var-get yield-rate) u52560)) ;; ~ blocks/year
      (new-rewards (* blocks-staked yield-per-block))
    )
    (ok (+ (get accumulated-yield rewards) new-rewards))
  )
)

(define-private (claim-staking-rewards (token-id uint))
  (let (
      (rewards (unwrap! (calculate-rewards token-id) err-not-staked))
      (token (unwrap! (get-token-info token-id) err-invalid-token))
    )
    (asserts! (get is-staked token) err-not-staked)

    (map-set staking-rewards { token-id: token-id } {
      accumulated-yield: u0,
      last-claim: stacks-block-height,
    })

    (as-contract (stx-transfer? rewards (as-contract tx-sender) (get owner token)))
  )
)
