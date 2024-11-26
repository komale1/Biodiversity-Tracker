;; Biodiversity Tracking Contract
;; Tracks and manages biodiversity data across different ecosystems

;; Constants
(define-constant contract-administrator tx-sender)
(define-constant ERR_OWNER_ONLY (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_INVALID_DATA (err u102))
(define-constant ERR_ALREADY_EXISTS (err u103))
(define-constant ERR_UNAUTHORIZED (err u104))
(define-constant ERR_INVALID_STATUS (err u105))
(define-constant ERR_ZERO_VALUE (err u106))

;; Data structures
(define-map biodiversity-ecosystems 
    { ecosystem-identifier: uint }
    {
        ecosystem-name: (string-ascii 50),
        geographic-location: (string-ascii 100),
        total-area-hectares: uint,
        ecosystem-creation-block: uint,
        last-update-block: uint
    }
)

(define-map biodiversity-species
    { species-identifier: uint }
    {
        common-name: (string-ascii 50),
        taxonomic-name: (string-ascii 100),
        current-population: uint,
        ecosystem-identifier: uint,
        species-conservation-status: (string-ascii 20),
        last-census-block: uint
    }
)

(define-map ecosystem-biodiversity-metrics
    { ecosystem-identifier: uint }
    {
        total-species-count: uint,
        ecosystem-diversity-index: uint,
        threatened-species-count: uint,
        last-assessment-block: uint
    }
)

;; Data storage
(define-data-var next-available-ecosystem-id uint u1)
(define-data-var next-available-species-id uint u1)
(define-data-var ecosystem-registration-count uint u0)
(define-data-var species-registration-count uint u0)

;; Authorization check
(define-private (is-contract-administrator)
    (is-eq tx-sender contract-administrator)
)

;; Ecosystem management functions
(define-public (register-new-ecosystem (ecosystem-name (string-ascii 50)) 
                                     (geographic-location (string-ascii 100)) 
                                     (total-area-hectares uint))
    (let
        (
            (new-ecosystem-id (var-get next-available-ecosystem-id))
        )
        (asserts! (is-contract-administrator) ERR_OWNER_ONLY)
        (asserts! (> (len ecosystem-name) u0) ERR_INVALID_DATA)
        (asserts! (> total-area-hectares u0) ERR_ZERO_VALUE)
        
        (map-insert biodiversity-ecosystems
            { ecosystem-identifier: new-ecosystem-id }
            {
                ecosystem-name: ecosystem-name,
                geographic-location: geographic-location,
                total-area-hectares: total-area-hectares,
                ecosystem-creation-block: block-height,
                last-update-block: block-height
            }
        )
        
        (map-insert ecosystem-biodiversity-metrics
            { ecosystem-identifier: new-ecosystem-id }
            {
                total-species-count: u0,
                ecosystem-diversity-index: u0,
                threatened-species-count: u0,
                last-assessment-block: block-height
            }
        )
        
        (var-set next-available-ecosystem-id (+ new-ecosystem-id u1))
        (var-set ecosystem-registration-count (+ (var-get ecosystem-registration-count) u1))
        (ok new-ecosystem-id)
    )
)

(define-public (update-ecosystem-data (ecosystem-identifier uint)
                                    (updated-name (string-ascii 50))
                                    (updated-location (string-ascii 100))
                                    (updated-area-hectares uint))
    (let
        (
            (existing-ecosystem-data (unwrap! (map-get? biodiversity-ecosystems { ecosystem-identifier: ecosystem-identifier }) ERR_NOT_FOUND))
        )
        (asserts! (is-contract-administrator) ERR_OWNER_ONLY)
        (asserts! (> (len updated-name) u0) ERR_INVALID_DATA)
        (asserts! (> updated-area-hectares u0) ERR_ZERO_VALUE)
        
        (map-set biodiversity-ecosystems
            { ecosystem-identifier: ecosystem-identifier }
            {
                ecosystem-name: updated-name,
                geographic-location: updated-location,
                total-area-hectares: updated-area-hectares,
                ecosystem-creation-block: (get ecosystem-creation-block existing-ecosystem-data),
                last-update-block: block-height
            }
        )
        (ok true)
    )
)

;; Species management functions
(define-public (register-new-species (common-name (string-ascii 50))
                                   (taxonomic-name (string-ascii 100))
                                   (initial-population uint)
                                   (ecosystem-identifier uint)
                                   (conservation-status (string-ascii 20)))
    (let
        (
            (new-species-id (var-get next-available-species-id))
            (current-ecosystem-metrics (unwrap! (map-get? ecosystem-biodiversity-metrics { ecosystem-identifier: ecosystem-identifier }) ERR_NOT_FOUND))
        )
        (asserts! (is-contract-administrator) ERR_OWNER_ONLY)
        (asserts! (> (len common-name) u0) ERR_INVALID_DATA)
        (asserts! (> initial-population u0) ERR_ZERO_VALUE)
        (asserts! (or (is-eq conservation-status "threatened")
                     (is-eq conservation-status "stable")
                     (is-eq conservation-status "endangered")
                     (is-eq conservation-status "extinct")) ERR_INVALID_STATUS)
        
        (map-insert biodiversity-species
            { species-identifier: new-species-id }
            {
                common-name: common-name,
                taxonomic-name: taxonomic-name,
                current-population: initial-population,
                ecosystem-identifier: ecosystem-identifier,
                species-conservation-status: conservation-status,
                last-census-block: block-height
            }
        )
        
        ;; Update ecosystem metrics
        (map-set ecosystem-biodiversity-metrics
            { ecosystem-identifier: ecosystem-identifier }
            {
                total-species-count: (+ (get total-species-count current-ecosystem-metrics) u1),
                ecosystem-diversity-index: (+ (get ecosystem-diversity-index current-ecosystem-metrics) u1),
                threatened-species-count: (if (is-eq conservation-status "threatened")
                                         (+ (get threatened-species-count current-ecosystem-metrics) u1)
                                         (get threatened-species-count current-ecosystem-metrics)),
                last-assessment-block: block-height
            }
        )
        
        (var-set next-available-species-id (+ new-species-id u1))
        (var-set species-registration-count (+ (var-get species-registration-count) u1))
        (ok new-species-id)
    )
)

(define-public (update-species-census-data (species-identifier uint)
                                         (updated-population uint)
                                         (updated-conservation-status (string-ascii 20)))
    (let
        (
            (current-species-data (unwrap! (map-get? biodiversity-species { species-identifier: species-identifier }) ERR_NOT_FOUND))
            (current-ecosystem-metrics (unwrap! (map-get? ecosystem-biodiversity-metrics 
                { ecosystem-identifier: (get ecosystem-identifier current-species-data) }) ERR_NOT_FOUND))
        )
        (asserts! (is-contract-administrator) ERR_OWNER_ONLY)
        (asserts! (>= updated-population u0) ERR_INVALID_DATA)
        (asserts! (or (is-eq updated-conservation-status "threatened")
                     (is-eq updated-conservation-status "stable")
                     (is-eq updated-conservation-status "endangered")
                     (is-eq updated-conservation-status "extinct")) ERR_INVALID_STATUS)
        
        (map-set biodiversity-species
            { species-identifier: species-identifier }
            {
                common-name: (get common-name current-species-data),
                taxonomic-name: (get taxonomic-name current-species-data),
                current-population: updated-population,
                ecosystem-identifier: (get ecosystem-identifier current-species-data),
                species-conservation-status: updated-conservation-status,
                last-census-block: block-height
            }
        )
        
        ;; Update threatened species count if status changed
        (if (not (is-eq (get species-conservation-status current-species-data) updated-conservation-status))
            (map-set ecosystem-biodiversity-metrics
                { ecosystem-identifier: (get ecosystem-identifier current-species-data) }
                {
                    total-species-count: (get total-species-count current-ecosystem-metrics),
                    ecosystem-diversity-index: (get ecosystem-diversity-index current-ecosystem-metrics),
                    threatened-species-count: (if (is-eq updated-conservation-status "threatened")
                                             (+ (get threatened-species-count current-ecosystem-metrics) u1)
                                             (- (get threatened-species-count current-ecosystem-metrics) u1)),
                    last-assessment-block: block-height
                }
            )
            true
        )
        (ok true)
    )
)

;; Read-only functions
(define-read-only (get-ecosystem-data (ecosystem-identifier uint))
    (map-get? biodiversity-ecosystems { ecosystem-identifier: ecosystem-identifier })
)

(define-read-only (get-species-data (species-identifier uint))
    (map-get? biodiversity-species { species-identifier: species-identifier })
)

(define-read-only (get-ecosystem-biodiversity-data (ecosystem-identifier uint))
    (map-get? ecosystem-biodiversity-metrics { ecosystem-identifier: ecosystem-identifier })
)

(define-read-only (get-total-registered-ecosystems)
    (ok (var-get ecosystem-registration-count))
)

(define-read-only (get-total-registered-species)
    (ok (var-get species-registration-count))
)

;; Helper functions
(define-read-only (is-ecosystem-registered (ecosystem-identifier uint))
    (is-some (map-get? biodiversity-ecosystems { ecosystem-identifier: ecosystem-identifier }))
)

(define-read-only (is-species-registered (species-identifier uint))
    (is-some (map-get? biodiversity-species { species-identifier: species-identifier }))
)