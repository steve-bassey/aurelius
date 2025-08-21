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