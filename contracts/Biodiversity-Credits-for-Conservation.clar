(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_HABITAT_NOT_FOUND (err u101))
(define-constant ERR_INSUFFICIENT_CREDITS (err u102))
(define-constant ERR_INVALID_AMOUNT (err u103))
(define-constant ERR_ALREADY_EXISTS (err u104))
(define-constant ERR_NOT_VERIFIED (err u105))
(define-constant ERR_TRADE_NOT_FOUND (err u106))
(define-constant ERR_CARBON_PROJECT_NOT_FOUND (err u107))
(define-constant ERR_INVALID_CARBON_RATE (err u108))

(define-data-var next-habitat-id uint u1)
(define-data-var next-trade-id uint u1)
(define-data-var next-carbon-project-id uint u1)

(define-fungible-token biodiversity-credits)
(define-fungible-token carbon-credits)

(define-map habitats 
  {habitat-id: uint}
  {
    owner: principal,
    location: (string-ascii 100),
    size-hectares: uint,
    biodiversity-score: uint,
    verified: bool,
    credits-per-year: uint,
    last-mint-block: uint
  }
)

(define-map ngo-partnerships
  {ngo: principal}
  {
    authorized: bool,
    verification-fee: uint,
    reputation-score: uint
  }
)

(define-map user-balances
  {user: principal}
  {credits: uint}
)

(define-map carbon-projects
  {project-id: uint}
  {
    habitat-id: uint,
    carbon-rate-per-hectare: uint,
    methodology: (string-ascii 50),
    active: bool,
    last-carbon-mint: uint
  }
)

(define-map user-carbon-balances
  {user: principal}
  {carbon-credits: uint}
)

(define-map trades
  {trade-id: uint}
  {
    seller: principal,
    buyer: (optional principal),
    credits-amount: uint,
    price-per-credit: uint,
    status: (string-ascii 20),
    created-block: uint
  }
)

(define-map habitat-verifications
  {habitat-id: uint}
  {
    verifier: principal,
    satellite-data-hash: (buff 32),
    verification-block: uint,
    expiry-block: uint
  }
)

(define-public (register-habitat (location (string-ascii 100)) (size-hectares uint) (biodiversity-score uint))
  (let
    (
      (habitat-id (var-get next-habitat-id))
      (credits-per-year (* size-hectares biodiversity-score))
    )
    (asserts! (> size-hectares u0) ERR_INVALID_AMOUNT)
    (asserts! (> biodiversity-score u0) ERR_INVALID_AMOUNT)
    
    (map-insert habitats
      {habitat-id: habitat-id}
      {
        owner: tx-sender,
        location: location,
        size-hectares: size-hectares,
        biodiversity-score: biodiversity-score,
        verified: false,
        credits-per-year: credits-per-year,
        last-mint-block: stacks-block-height
      }
    )
    
    (var-set next-habitat-id (+ habitat-id u1))
    (ok habitat-id)
  )
)

(define-public (authorize-ngo (ngo principal) (verification-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (map-set ngo-partnerships
      {ngo: ngo}
      {
        authorized: true,
        verification-fee: verification-fee,
        reputation-score: u100
      }
    )
    (ok true)
  )
)

(define-public (verify-habitat (habitat-id uint) (satellite-data-hash (buff 32)))
  (let
    (
      (habitat (unwrap! (map-get? habitats {habitat-id: habitat-id}) ERR_HABITAT_NOT_FOUND))
      (ngo-data (unwrap! (map-get? ngo-partnerships {ngo: tx-sender}) ERR_NOT_AUTHORIZED))
    )
    (asserts! (get authorized ngo-data) ERR_NOT_AUTHORIZED)
    
    (map-set habitats
      {habitat-id: habitat-id}
      (merge habitat {verified: true})
    )
    
    (map-set habitat-verifications
      {habitat-id: habitat-id}
      {
        verifier: tx-sender,
        satellite-data-hash: satellite-data-hash,
        verification-block: stacks-block-height,
        expiry-block: (+ stacks-block-height u52560)
      }
    )
    (ok true)
  )
)

(define-public (mint-credits (habitat-id uint))
  (let
    (
      (habitat (unwrap! (map-get? habitats {habitat-id: habitat-id}) ERR_HABITAT_NOT_FOUND))
      (blocks-since-last-mint (- stacks-block-height (get last-mint-block habitat)))
      (credits-to-mint (/ (* (get credits-per-year habitat) blocks-since-last-mint) u52560))
    )
    (asserts! (is-eq tx-sender (get owner habitat)) ERR_NOT_AUTHORIZED)
    (asserts! (get verified habitat) ERR_NOT_VERIFIED)
    (asserts! (> blocks-since-last-mint u8760) ERR_INVALID_AMOUNT)
    
    (try! (ft-mint? biodiversity-credits credits-to-mint tx-sender))
    
    (map-set habitats
      {habitat-id: habitat-id}
      (merge habitat {last-mint-block: stacks-block-height})
    )
    
    (map-set user-balances
      {user: tx-sender}
      {credits: (+ (default-to u0 (get credits (map-get? user-balances {user: tx-sender}))) credits-to-mint)}
    )
    (ok credits-to-mint)
  )
)

(define-public (create-trade (credits-amount uint) (price-per-credit uint))
  (let
    (
      (trade-id (var-get next-trade-id))
      (user-balance (default-to u0 (get credits (map-get? user-balances {user: tx-sender}))))
    )
    (asserts! (>= user-balance credits-amount) ERR_INSUFFICIENT_CREDITS)
    (asserts! (> credits-amount u0) ERR_INVALID_AMOUNT)
    (asserts! (> price-per-credit u0) ERR_INVALID_AMOUNT)
    
    (map-insert trades
      {trade-id: trade-id}
      {
        seller: tx-sender,
        buyer: none,
        credits-amount: credits-amount,
        price-per-credit: price-per-credit,
        status: "active",
        created-block: stacks-block-height
      }
    )
    
    (map-set user-balances
      {user: tx-sender}
      {credits: (- user-balance credits-amount)}
    )
    
    (var-set next-trade-id (+ trade-id u1))
    (ok trade-id)
  )
)

(define-public (execute-trade (trade-id uint))
  (let
    (
      (trade (unwrap! (map-get? trades {trade-id: trade-id}) ERR_TRADE_NOT_FOUND))
      (total-cost (* (get credits-amount trade) (get price-per-credit trade)))
      (buyer-balance (default-to u0 (get credits (map-get? user-balances {user: tx-sender}))))
    )
    (asserts! (is-eq (get status trade) "active") ERR_TRADE_NOT_FOUND)
    (asserts! (not (is-eq tx-sender (get seller trade))) ERR_NOT_AUTHORIZED)
    
    (try! (stx-transfer? total-cost tx-sender (get seller trade)))
    
    (map-set trades
      {trade-id: trade-id}
      (merge trade {buyer: (some tx-sender), status: "completed"})
    )
    
    (map-set user-balances
      {user: tx-sender}
      {credits: (+ buyer-balance (get credits-amount trade))}
    )
    (ok true)
  )
)

(define-public (cancel-trade (trade-id uint))
  (let
    (
      (trade (unwrap! (map-get? trades {trade-id: trade-id}) ERR_TRADE_NOT_FOUND))
      (seller-balance (default-to u0 (get credits (map-get? user-balances {user: (get seller trade)}))))
    )
    (asserts! (is-eq tx-sender (get seller trade)) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status trade) "active") ERR_TRADE_NOT_FOUND)
    
    (map-set trades
      {trade-id: trade-id}
      (merge trade {status: "cancelled"})
    )
    
    (map-set user-balances
      {user: (get seller trade)}
      {credits: (+ seller-balance (get credits-amount trade))}
    )
    (ok true)
  )
)

(define-public (transfer-credits (recipient principal) (amount uint))
  (let
    (
      (sender-balance (default-to u0 (get credits (map-get? user-balances {user: tx-sender}))))
      (recipient-balance (default-to u0 (get credits (map-get? user-balances {user: recipient}))))
    )
    (asserts! (>= sender-balance amount) ERR_INSUFFICIENT_CREDITS)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    
    (map-set user-balances
      {user: tx-sender}
      {credits: (- sender-balance amount)}
    )
    
    (map-set user-balances
      {user: recipient}
      {credits: (+ recipient-balance amount)}
    )
    (ok true)
  )
)

(define-public (update-ngo-reputation (ngo principal) (new-score uint))
  (let
    (
      (ngo-data (unwrap! (map-get? ngo-partnerships {ngo: ngo}) ERR_NOT_AUTHORIZED))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (<= new-score u100) ERR_INVALID_AMOUNT)
    
    (map-set ngo-partnerships
      {ngo: ngo}
      (merge ngo-data {reputation-score: new-score})
    )
    (ok true)
  )
)

(define-public (register-carbon-project (habitat-id uint) (carbon-rate-per-hectare uint) (methodology (string-ascii 50)))
  (let
    (
      (habitat (unwrap! (map-get? habitats {habitat-id: habitat-id}) ERR_HABITAT_NOT_FOUND))
      (project-id (var-get next-carbon-project-id))
    )
    (asserts! (is-eq tx-sender (get owner habitat)) ERR_NOT_AUTHORIZED)
    (asserts! (get verified habitat) ERR_NOT_VERIFIED)
    (asserts! (> carbon-rate-per-hectare u0) ERR_INVALID_CARBON_RATE)
    
    (map-insert carbon-projects
      {project-id: project-id}
      {
        habitat-id: habitat-id,
        carbon-rate-per-hectare: carbon-rate-per-hectare,
        methodology: methodology,
        active: true,
        last-carbon-mint: stacks-block-height
      }
    )
    
    (var-set next-carbon-project-id (+ project-id u1))
    (ok project-id)
  )
)

(define-public (mint-carbon-credits (project-id uint))
  (let
    (
      (project (unwrap! (map-get? carbon-projects {project-id: project-id}) ERR_CARBON_PROJECT_NOT_FOUND))
      (habitat (unwrap! (map-get? habitats {habitat-id: (get habitat-id project)}) ERR_HABITAT_NOT_FOUND))
      (blocks-since-last-mint (- stacks-block-height (get last-carbon-mint project)))
      (carbon-per-year (* (get size-hectares habitat) (get carbon-rate-per-hectare project)))
      (carbon-to-mint (/ (* carbon-per-year blocks-since-last-mint) u52560))
    )
    (asserts! (is-eq tx-sender (get owner habitat)) ERR_NOT_AUTHORIZED)
    (asserts! (get active project) ERR_NOT_AUTHORIZED)
    (asserts! (get verified habitat) ERR_NOT_VERIFIED)
    (asserts! (> blocks-since-last-mint u8760) ERR_INVALID_AMOUNT)
    
    (try! (ft-mint? carbon-credits carbon-to-mint tx-sender))
    
    (map-set carbon-projects
      {project-id: project-id}
      (merge project {last-carbon-mint: stacks-block-height})
    )
    
    (map-set user-carbon-balances
      {user: tx-sender}
      {carbon-credits: (+ (default-to u0 (get carbon-credits (map-get? user-carbon-balances {user: tx-sender}))) carbon-to-mint)}
    )
    (ok carbon-to-mint)
  )
)

(define-public (transfer-carbon-credits (recipient principal) (amount uint))
  (let
    (
      (sender-balance (default-to u0 (get carbon-credits (map-get? user-carbon-balances {user: tx-sender}))))
      (recipient-balance (default-to u0 (get carbon-credits (map-get? user-carbon-balances {user: recipient}))))
    )
    (asserts! (>= sender-balance amount) ERR_INSUFFICIENT_CREDITS)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    
    (map-set user-carbon-balances
      {user: tx-sender}
      {carbon-credits: (- sender-balance amount)}
    )
    
    (map-set user-carbon-balances
      {user: recipient}
      {carbon-credits: (+ recipient-balance amount)}
    )
    (ok true)
  )
)

(define-public (swap-credits (bio-credits-amount uint))
  (let
    (
      (sender-bio-balance (default-to u0 (get credits (map-get? user-balances {user: tx-sender}))))
      (sender-carbon-balance (default-to u0 (get carbon-credits (map-get? user-carbon-balances {user: tx-sender}))))
      (carbon-credits-amount (/ (* bio-credits-amount u75) u100))
    )
    (asserts! (>= sender-bio-balance bio-credits-amount) ERR_INSUFFICIENT_CREDITS)
    (asserts! (> bio-credits-amount u0) ERR_INVALID_AMOUNT)

    (map-set user-balances
      {user: tx-sender}
      {credits: (- sender-bio-balance bio-credits-amount)}
    )

    (map-set user-carbon-balances
      {user: tx-sender}
      {carbon-credits: (+ sender-carbon-balance carbon-credits-amount)}
    )
    (ok carbon-credits-amount)
  )
)

(define-private (accumulate-amount (transfer {recipient: principal, amount: uint}) (acc uint))
  (+ acc (get amount transfer))
)

(define-private (process-transfer (transfer {recipient: principal, amount: uint}) (acc (response bool uint)))
  (let
    (
      (recipient-balance (default-to u0 (get credits (map-get? user-balances {user: (get recipient transfer)}))))
    )
    (begin
      (map-set user-balances
        {user: (get recipient transfer)}
        {credits: (+ recipient-balance (get amount transfer))}
      )
      acc
    )
  )
)

(define-public (batch-transfer-credits (transfers (list 10 {recipient: principal, amount: uint})))
  (let
    (
      (sender-balance (default-to u0 (get credits (map-get? user-balances {user: tx-sender}))))
      (total-amount (fold accumulate-amount transfers u0))
    )
    (asserts! (>= sender-balance total-amount) ERR_INSUFFICIENT_CREDITS)
    (asserts! (> (len transfers) u0) ERR_INVALID_AMOUNT)
    (asserts! (> total-amount u0) ERR_INVALID_AMOUNT)
    (try! (fold process-transfer transfers (ok true)))
    (map-set user-balances
      {user: tx-sender}
      {credits: (- sender-balance total-amount)}
    )
    (ok true)
  )
)

(define-read-only (get-habitat (habitat-id uint))
  (map-get? habitats {habitat-id: habitat-id})
)

(define-read-only (get-user-credits (user principal))
  (default-to u0 (get credits (map-get? user-balances {user: user})))
)

(define-read-only (get-trade (trade-id uint))
  (map-get? trades {trade-id: trade-id})
)

(define-read-only (get-ngo-status (ngo principal))
  (map-get? ngo-partnerships {ngo: ngo})
)

(define-read-only (get-habitat-verification (habitat-id uint))
  (map-get? habitat-verifications {habitat-id: habitat-id})
)

(define-read-only (calculate-credits-eligible (habitat-id uint))
  (match (map-get? habitats {habitat-id: habitat-id})
    habitat
    (let
      (
        (blocks-since-last-mint (- stacks-block-height (get last-mint-block habitat)))
        (credits-per-block (/ (get credits-per-year habitat) u52560))
      )
      (if (get verified habitat)
        (ok (* credits-per-block blocks-since-last-mint))
        (ok u0)
      )
    )
    ERR_HABITAT_NOT_FOUND
  )
)

(define-read-only (get-total-supply)
  (ft-get-supply biodiversity-credits)
)

(define-read-only (get-carbon-project (project-id uint))
  (map-get? carbon-projects {project-id: project-id})
)

(define-read-only (get-user-carbon-credits (user principal))
  (default-to u0 (get carbon-credits (map-get? user-carbon-balances {user: user})))
)

(define-read-only (calculate-carbon-credits-eligible (project-id uint))
  (match (map-get? carbon-projects {project-id: project-id})
    project
    (match (map-get? habitats {habitat-id: (get habitat-id project)})
      habitat
      (let
        (
          (blocks-since-last-mint (- stacks-block-height (get last-carbon-mint project)))
          (carbon-per-year (* (get size-hectares habitat) (get carbon-rate-per-hectare project)))
          (carbon-per-block (/ carbon-per-year u52560))
        )
        (if (and (get active project) (get verified habitat))
          (ok (* carbon-per-block blocks-since-last-mint))
          (ok u0)
        )
      )
      ERR_HABITAT_NOT_FOUND
    )
    ERR_CARBON_PROJECT_NOT_FOUND
  )
)

(define-read-only (get-contract-info)
  {
    total-habitats: (- (var-get next-habitat-id) u1),
    total-trades: (- (var-get next-trade-id) u1),
    total-carbon-projects: (- (var-get next-carbon-project-id) u1),
    total-credits-supply: (ft-get-supply biodiversity-credits),
    total-carbon-supply: (ft-get-supply carbon-credits)
  }
)
