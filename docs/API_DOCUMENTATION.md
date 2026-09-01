# FlockSense Data API & Schema Specification

## 1. Cloud Firestore Hierarchy

```
users/{uid}
  ├── farms/{farmId}
  │     ├── sheds/{shedId}
  │     └── batches/{batchId}
  │           ├── dailyRecords/{recordDate}
  │           ├── feedTransactions/{txId}
  │           ├── medicineRecords/{recordId}
  │           ├── vaccineRecords/{recordId}
  │           ├── salesRecords/{saleId}
  │           └── weightRecords/{recordId}
  ├── inventory/{itemId}
  │     └── stockMovements/{movementId}
  └── notifications/{notifId}
```

---

## 2. Entity Schemas

### 2.1 Daily Record Document (`dailyRecords/{YYYY-MM-DD}`)
| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `string` | Unique date identifier (`2026-09-01`) |
| `batchAgeDay` | `integer` | Current flock age in days |
| `openingBirds` | `integer` | Live flock head count at start of day |
| `mortalityCount` | `integer` | Dead bird count recorded |
| `cullCount` | `integer` | Culled or condemned bird count |
| `closingBirds` | `integer` | `openingBirds - mortalityCount - cullCount` |
| `feedConsumedKg`| `double` | Total feed distributed in kg |
| `waterConsumedLiters` | `double` | Total water consumed in Liters |
| `avgWeightGrams` | `double` | Sample average bird weight in grams |
| `temperature` | `double` | Ambient shed temperature in °C |
| `humidity` | `double` | Relative humidity percentage |
| `medicineGiven` | `boolean`| Whether therapeutics were administered |
| `vaccineGiven` | `boolean`| Whether vaccines were administered |
| `dgLevelLiters` | `double` | Diesel Generator fuel level |

---

## 3. Security Rules Matrix

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /{path=**}/dailyRecords/{recordId} {
      allow read: if request.auth != null;
    }
  }
}
```
