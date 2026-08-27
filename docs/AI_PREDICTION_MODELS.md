# FlockSense AI Prediction & Anomaly Detection Models

This specification outlines the telemetry inference algorithms and predictive models powering the FlockSense platform.

---

## 1. Early-Warning Mortality Anomaly Detection

### Mathematical Formulation
The daily mortality rate $M_t$ on day $t$ is monitored against a dynamic exponential moving baseline:

$$\bar{M}_t = \alpha \cdot M_t + (1 - \alpha) \cdot \bar{M}_{t-1}$$

Where:
- $\alpha = 0.3$ (Smoothing factor)
- Standard Deviation $\sigma_t = \sqrt{\frac{1}{k} \sum_{i=0}^{k-1} (M_{t-i} - \bar{M}_t)^2}$

### Spike Condition
A warning threshold is breached if:
$$M_t > \bar{M}_t + 2.5 \cdot \sigma_t$$

---

## 2. Water-to-Feed Intake Ratio (W:F)

- **Standard Expected Range**: `1.6:1` to `2.0:1`
- **Sudden Surge (> 2.3:1)**: Indicates thermal stress (high THI) or intestinal enteritis.
- **Sudden Drop (< 1.4:1)**: Indicates water line blockage, unpalatable water, or acute disease onset.

---

## 3. THI Stress Classification Matrix

| THI Value | Stress Classification | Required Farm Action |
|:---|:---|:---|
| $< 74$ | **Normal** | Standard ventilation |
| $74 - 78$ | **Alert** | Increase tunnel fan speed |
| $79 - 84$ | **Danger** | Engage evaporative cooling pads |
| $> 84$ | **Emergency** | Maximum cooling + electrolyte water replenishment |
