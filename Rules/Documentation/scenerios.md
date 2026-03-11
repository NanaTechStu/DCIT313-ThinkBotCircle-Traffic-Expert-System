# DCIT 313 — Adaptive Traffic Signal Control  
## Expert System Test Scenarios | ThinkBot Circle

This document contains the results of testing the Traffic Expert System using multiple intersection scenarios. Each scenario lists the inputs and the recommended system actions.

| Scenario | Traffic Density | Weather Condition | Time of Day | Current Light | Pedestrian | Emergency Vehicle | Recommended Signal Actions |
|----------|----------------|-----------------|------------|---------------|------------|-----------------|---------------------------|
| 1        | Low            | Light Rain      | Night      | Red           | No         | No              | Maintain Red for 30 seconds(default timing) |
| 2        | High           | Heavy Rain      | Day        | Green         | No         | No              | 1. [WARNING] Slippery road; Drive carefully<br>2. Extend Green by +35 seconds |
| 3        | Low            | Dry             | Day        | Green         | No         | No              | Maintain Green for 30 seconds (default timing)|
| 4        | Medium         | Cloudy          | Night      | Green         | Yes        | Yes             | 1. [PRIORITY] Give Emergency Vehicle Priority — clear    path<br>2. Maintain Green for 30 seconds |
| 5        | Medium         | Dry             | Night      | Yellow        | No         | Yes             | 1. [PRIORITY] Give Emergency Vehicle Priority — clear path<br>2. Switch signal to RED immediately |
| 6        | Medium         | Light Rain      | Day        | Red           | Yes        | Yes             | 1. [SAFETY] Activate Pedestrian Crossing signal<br>2. [PRIORITY] Give Emergency Vehicle Priority — clear path<br>3. Switch signal to GREEN immediately |

Outputs reflect the system’s recommended traffic light actions.

