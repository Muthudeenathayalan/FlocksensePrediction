# Security and Biosecurity Compliance

FlockSense incorporates rigorous security practices to protect farm telemetry, financial accounts, and disease surveillance data.

---

## 1. Authentication & Role-Based Access Control (RBAC)

FlockSense defines strict user roles:
- **`farmer`**: Full control over farm assets, daily logging, and financial ledgers.
- **`veterinarian`**: Read access to farm health metrics, write access to medical prescriptions and lab diagnostic results.
- **`government_surveillance`**: Aggregated epidemiological view of regional outbreaks without exposing commercial financial data.

---

## 2. Cloud Firestore Security Rules

All Firestore read and write operations are enforced server-side:
- Access to `farms/{farmId}` requires `request.auth.uid == resource.data.userId`.
- Medical records can only be signed or modified by authenticated users with role `veterinarian`.

---

## 3. Reporting a Vulnerability

If you discover a security vulnerability, please submit a report to `security@flocksense.io` or open a confidential security advisory on GitHub.
