# FlockSense Architecture & Engineering Design

This document details the architectural principles, domain model boundaries, and telemetry evaluation pipelines of the **FlockSense** platform.

---

## 1. Architectural Principles

FlockSense adopts **Domain-Driven Design (DDD)** combined with **Feature-First modularization** in Flutter:

1. **Feature Separation**: Each module in `features/` encapsulates its own:
   - `data/` (Repositories, REST/Firestore services, Data models)
   - `domain/` (Entities, state providers, business validators)
   - `presentation/` (Screens, reactive widgets, state consumers)

2. **Unidirectional Data Flow**:
   - UI triggers user intent / actions via Riverpod / StateNotifier providers.
   - Domain providers invoke services to fetch/mutate data in Firestore / Local Cache.
   - Cloud Functions react asynchronously to Firestore triggers for background intelligence.

3. **Offline Resilience**:
   - All daily log entries support local caching and opportunistic sync to prevent data loss in remote farm environments.

---

## 2. Cloud AI & Risk Engine Pipeline

```
[ Farm Log Submitted ]
        │
        ▼
[ Firestore 'daily_records' Trigger ]
        │
        ▼
[ riskEngine.ts ] ──► Calculates FCR deviation, THI stress index, Mortality delta
        │
        ▼
[ aiAssessmentEngine.ts ] ──► Evaluates symptom patterns & risk scores (Low/Med/High/Critical)
        │
        ▼
[ escalationEngine.ts ] ──► If Critical, dispatches urgent notifications to Farm Vet & Manager
```

---

## 3. Core Domain Equations

- **Feed Conversion Ratio (FCR)**:
  $$\text{FCR} = \frac{\text{Total Cumulative Feed Consumed (kg)}}{\text{Total Live Weight (kg)}}$$

- **European Production Efficiency Factor (EPEF)**:
  $$\text{EPEF} = \frac{\text{Livability (\%)} \times \text{Average Live Weight (kg)}}{\text{Age (Days)} \times \text{FCR}} \times 100$$

- **Temperature Humidity Index (THI)**:
  $$\text{THI} = 0.8 \times T + \left(\frac{\text{RH}}{100}\right) \times (T - 14.4) + 46.4$$
