# 🐔 FlockSense — Smart Poultry Disease Surveillance & Prediction Platform
> **Smart India Hackathon (SIH26128)**  
> **AI-Powered Animal Health Intelligence, Early Disease Warning & Outbreak Containment System**

---

## 🌐 1. Live Deployment & Access Links

| Environment | URL | Description |
| :--- | :--- | :--- |
| **Localhost** | [http://localhost:8080](http://localhost:8080) | Primary development & demonstration server |
| **Loopback IP** | [http://127.0.0.1:8080](http://127.0.0.1:8080) | Local loopback interface |
| **LAN / Mobile Wi-Fi** | [http://10.74.78.149:8080](http://10.74.78.149:8080) | Access from tablets, smartphones, and local devices on the same Wi-Fi |

---

## 🎯 2. Project Overview & SIH Problem Statement

**FlockSense** is an enterprise-grade, multi-tenant digital health intelligence system designed to safeguard poultry farms, veterinary field clinicians, and state animal husbandry departments from catastrophic epidemic outbreaks (e.g., Avian Influenza / Bird Flu, Newcastle Disease, Infectious Bronchitis).

### Core Problem:
- Traditional poultry mortality reporting relies on manual paper logs, causing a **5–12 day reporting lag**.
- Disease spreads rapidly before veterinary intervention or regional isolation can be initiated.
- Lack of centralized GIS outbreak mapping between local poultry sheds and state officials.

### FlockSense Solution:
1. **Real-Time IoT & Biometric Telemetry**: Tracks daily mortality vs. 7-day baselines, feed consumption, water intake deviations, and thermal index (THI).
2. **AI Anomaly Detection & Risk Scoring**: Automatically computes a dynamic Farm Health Risk score (0–100) and triggers automated syndromic alerts.
3. **Tri-Tier Coordination Engine**: Seamless, role-based workflows connecting:
   - **🧑‍🌾 Poultry Farmers** (Daily shed logging, environmental stress alerts, bio-security score).
   - **🩺 Field Veterinarians** (Clinical triage queue, differential diagnosis, RT-PCR verification, prescription tracking).
   - **🏛️ State Animal Husbandry / Government** (Situation room, GIS outbreak heatmaps, cordon isolation management, official DAHD bulletins).

---

## 🎨 3. UI Design System: Professional Light Theme

FlockSense has been designed with a high-contrast, clean **Enterprise Light Theme** engineered for clarity, readability, and zero distraction:

- **Surface Base**: Pure crisp white (`#FFFFFF`) with subtle slate borders (`#E2E8F0`).
- **Background**: Soft neutral slate (`#F8FAFC`).
- **Brand Accent**: Deep agricultural emerald green (`#166534`) and soft mint accents (`#F0FDF4`).
- **Status Indicators**:
  - 🟢 **Healthy / Normal**: `#15803D`
  - 🟡 **Warning / Elevated**: `#B45309`
  - 🔴 **Critical / Outbreak**: `#B91C1C`
- **Typography**: Clean, readable sans-serif typography with calibrated letter-spacing for high-density tabular and telemetry data.
- **Layout Rhythm**: Strict 16px section spacing, zero dead-space margins, and full edge-to-edge content expansion.

---

## 🚀 4. Live Prototype Features & Role Capabilities

### 🧑‍🌾 A. Farmer Operations Dashboard
- **Farm Switcher**: Multi-shed facility selector with instant district & status indicators.
- **Hero KPI Baseline Strip (4 Columns)**:
  - *Farm Health Risk Score* (0–100 gauge with real-time risk level).
  - *Daily Mortality vs Baseline* (birds/day compared against 7-day rolling mean).
  - *Feed Intake vs Baseline* (daily kg consumption with deviation %).
  - *Water Intake vs Baseline* (daily liters with hydration deficit alerts).
- **Fast Action Toolbar**:
  - `Log Daily Record` (Mortality, feed, water, egg production logging).
  - `Report Health Anomaly` (Symptom checklists: respiratory, digestive, neurological).
  - `Log Farm Visitor` (Sanitary biosecurity audit log).
  - `Intelligence Engine` (In-depth epidemiological drill-downs).
- **Thermal Environment & Microclimate Widget**:
  - Temperature Humidity Index (THI), ventilation stress, and heat stress indexes.
- **Nearby Corridor Exposure**:
  - Live radius monitoring for regional disease activity within 10 km.
- **Actionable AI Recommendations**:
  - Specific "What, Why, Who, Status" operational guidance.

---

### 🩺 B. Veterinarian Clinical Triage Room
- **Priority-1 Emergency Queue**: Triage cases requiring immediate quarantine or PPE dispatch.
- **Differential Diagnostic Engine**: Pathogen correlation matching symptoms to potential diseases.
- **Lab Diagnostic Tracker**: Chain-of-custody tracking for swab samples, viral RT-PCR assays, and pathogen isolation.
- **Treatment & Prescription Management**: Prescription log with active withdrawal period compliance tracking.

---

### 🏛️ C. Government & State Situation Room
- **State Command Center**: District-wide morbidity and mortality situation room.
- **Interactive GIS Outbreak Map**: Geospatial cluster visualization, quarantine perimeter rings, and farm risk markers.
- **District Risk Ranking**: Comparative velocity score to identify districts needing immediate veterinary reinforcement.
- **Official Export Engine**: Exportable PDF/CSV sanitary bulletins compliant with DAHD/WOAH standards.

---

## 💻 5. Running the Project Locally

### Prerequisites:
- **Flutter SDK**: 3.27+ (Compatible with Flutter 3.44.7 / Dart 3.12.2)
- **Node.js**: v18+ (For static file serving)

### Quick Start Commands:

```bash
# 1. Clone repository
git clone https://github.com/Muthudeenathayalan/FlocksensePrediction.git
cd FlocksensePrediction

# 2. Pull latest updates
git pull origin main

# 3. Get dependencies
flutter pub get

# 4. Build web production bundle
flutter build web

# 5. Launch live web server (Port 8080)
node server.js
```

Once running, access the application at **[http://localhost:8080](http://localhost:8080)**.

---

## 📁 6. Repository Architecture

```text
├── build/web/               # Compiled Flutter Web release bundle
├── lib/
│   ├── app/                 # Root app configuration & providers
│   ├── config/              # Routes, themes, and design tokens
│   │   ├── routes/          # App navigation routes
│   │   └── theme/           # AppColors, AppDesign, AppTheme
│   ├── core/                # Shared enterprise widgets & layouts
│   │   ├── widgets/
│   │   │   ├── adaptive_scaffold.dart  # Top prototype ribbon & web shell
│   │   │   ├── app_sidebar.dart        # Clean light collapsible sidebar
│   │   │   ├── web_header.dart         # Global header, search & role menu
│   │   │   ├── page_container.dart     # Full-width edge-to-edge responsive container
│   │   │   ├── app_button.dart         # Standardized button variants
│   │   │   └── status_badge.dart       # Healthy / Warning / Critical badges
│   ├── features/
│   │   ├── auth/            # Auth wrapper, role selector & login screen
│   │   ├── home/            # Farmer dashboard & operations
│   │   ├── health/          # Clinical symptom logging & case submission
│   │   ├── intelligence/    # AI anomaly detection, thermal index & timeline
│   │   ├── veterinary/      # Clinical triage, diagnostics & prescriptions
│   │   ├── government/      # GIS surveillance map, situation room & ranking
│   │   ├── batches/         # Flock lifecycle & breed performance
│   │   └── main_shell/      # Web layout & role switching controller
│   └── main.dart            # Flutter entry point
├── server.js                # Zero-cache high performance static web server
└── FLOCKSENSE_PROTOTYPE_GUIDE.md  # This documentation file
```

---

*Authored for Smart India Hackathon (SIH) — FlockSense Animal Health Intelligence Platform.*
