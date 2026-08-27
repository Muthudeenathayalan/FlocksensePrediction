# FlockSense Firestore Database Schema

This document defines the schema, relations, and composite indexing strategy for Cloud Firestore.

---

## Collections Hierarchy

```
users/{userId}
farms/{farmId}
├── sheds/{shedId}
└── batches/{batchId}
    ├── daily_records/{recordId}
    ├── weight_records/{recordId}
    ├── vaccine_records/{recordId}
    ├── medicine_records/{recordId}
    └── sales_records/{recordId}
inventory/{itemId}
notifications/{notificationId}
disease_alerts/{alertId}
```

---

## Collection Schemas

### 1. `farms/{farmId}`
- `id` (string): Unique identifier
- `userId` (string): Farm owner / organization ID
- `name` (string): Display name of the farm
- `location` (string): Geographic location or address
- `farmType` (string): `broiler` | `layer` | `breeder`
- `capacity` (number): Total birds capacity across sheds
- `createdAt` (timestamp): Record creation time

### 2. `batches/{batchId}`
- `id` (string): Unique identifier
- `farmId` (string): Parent farm reference
- `shedId` (string): Assigned shed reference
- `breed` (string): `Cobb 500` | `Ross 308` | `Hubbard`
- `initialPopulation` (number): Day 0 bird placement count
- `currentPopulation` (number): Live bird count
- `placementDate` (timestamp): Day 0 date
- `status` (string): `active` | `harvested` | `archived`

### 3. `daily_records/{recordId}`
- `batchId` (string): Associated flock batch
- `date` (timestamp): Record date
- `ageDays` (number): Flock age in days
- `mortality` (number): Dead birds count
- `feedConsumedKg` (number): Feed consumed in kg
- `waterConsumedLiters` (number): Water consumed in liters
- `temperatureCelsius` (number): Average ambient temperature
- `humidityPercent` (number): Relative humidity
- `thi` (number): Computed Temperature-Humidity Index
