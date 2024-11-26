# Biodiversity Tracking Smart Contract

## Overview
The Biodiversity Tracking Smart Contract is a Clarity-based solution for tracking and managing biodiversity data across different ecosystems. This contract enables organizations to monitor species populations, conservation statuses, and ecosystem health metrics in a decentralized and transparent manner.

## Features
- Ecosystem registration and management
- Species tracking and population monitoring
- Conservation status tracking
- Biodiversity metrics calculation
- Automated threatened species counting
- Secure administrator-only access control

## Contract Structure

### Data Maps
1. **biodiversity-ecosystems**
   - Stores ecosystem information
   - Fields: ecosystem-name, geographic-location, total-area-hectares, ecosystem-creation-block, last-update-block

2. **biodiversity-species**
   - Tracks individual species data
   - Fields: common-name, taxonomic-name, current-population, ecosystem-identifier, species-conservation-status, last-census-block

3. **ecosystem-biodiversity-metrics**
   - Maintains aggregated ecosystem metrics
   - Fields: total-species-count, ecosystem-diversity-index, threatened-species-count, last-assessment-block

### Key Functions

#### Ecosystem Management
```clarity
(register-new-ecosystem (ecosystem-name (string-ascii 50)) 
                       (geographic-location (string-ascii 100)) 
                       (total-area-hectares uint))
```
- Registers a new ecosystem in the system
- Returns: ecosystem identifier (uint)

```clarity
(update-ecosystem-data (ecosystem-identifier uint)
                      (updated-name (string-ascii 50))
                      (updated-location (string-ascii 100))
                      (updated-area-hectares uint))
```
- Updates existing ecosystem information
- Returns: boolean success status

#### Species Management
```clarity
(register-new-species (common-name (string-ascii 50))
                     (taxonomic-name (string-ascii 100))
                     (initial-population uint)
                     (ecosystem-identifier uint)
                     (conservation-status (string-ascii 20)))
```
- Registers a new species in the system
- Returns: species identifier (uint)

```clarity
(update-species-census-data (species-identifier uint)
                           (updated-population uint)
                           (updated-conservation-status (string-ascii 20)))
```
- Updates species population and conservation status
- Returns: boolean success status

#### Read-Only Functions
```clarity
(get-ecosystem-data (ecosystem-identifier uint))
(get-species-data (species-identifier uint))
(get-ecosystem-biodiversity-data (ecosystem-identifier uint))
(get-total-registered-ecosystems)
(get-total-registered-species)
(is-ecosystem-registered (ecosystem-identifier uint))
(is-species-registered (species-identifier uint))
```

## Error Codes
- ERR_OWNER_ONLY (u100): Unauthorized access attempt
- ERR_NOT_FOUND (u101): Requested resource not found
- ERR_INVALID_DATA (u102): Invalid data provided
- ERR_ALREADY_EXISTS (u103): Resource already exists
- ERR_UNAUTHORIZED (u104): Unauthorized operation
- ERR_INVALID_STATUS (u105): Invalid conservation status
- ERR_ZERO_VALUE (u106): Zero or negative value provided

## Conservation Status Values
Valid conservation status values:
- "threatened"
- "stable"
- "endangered"
- "extinct"

## Usage Examples

### Registering a New Ecosystem
```clarity
(contract-call? 
    .biodiversity-tracking 
    register-new-ecosystem 
    "Amazon Rainforest" 
    "Brazil, South America" 
    u550000000)
```

### Adding a New Species
```clarity
(contract-call? 
    .biodiversity-tracking 
    register-new-species 
    "Jaguar"
    "Panthera onca"
    u173000
    u1
    "threatened")
```

### Updating Species Census Data
```clarity
(contract-call? 
    .biodiversity-tracking 
    update-species-census-data 
    u1
    u170000
    "endangered")
```

## Security Considerations
1. Only the contract administrator can modify data
2. All numerical inputs are validated for non-zero values
3. Conservation status values are strictly validated
4. Ecosystem existence is verified before species registration
5. Population updates maintain data integrity

## Best Practices
1. Regularly update species census data
2. Verify ecosystem existence before adding species
3. Maintain accurate conservation status information
4. Monitor threatened species counts
5. Keep geographic location data specific and accurate