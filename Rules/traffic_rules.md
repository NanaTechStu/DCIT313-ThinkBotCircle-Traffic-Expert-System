# Traffic Expert System — Production Rules Reference

**Project**: DCIT 313 Adaptive Traffic Signal Control
**Rules authored by**: Bilson Priscilla Essirifua (Knowledge Engineer)
**Pseudo-code by**: Adu Selina Odoi (Knowledge Engineer)

---

## Input Variables

| Variable   | Possible Values                        |
|------------|----------------------------------------|
| density    | low, medium, high                      |
| weather    | dry, light_rain, heavy_rain, cloudy    |
| time       | day, night                             |
| light      | red, yellow, green                     |
| pedestrian | yes, no                                |
| emergency  | yes, no                                |

## Output Actions

| Action                         | Meaning                                     |
|--------------------------------|---------------------------------------------|
| maintain_green(N)              | Keep green for N seconds (default)          |
| maintain_red(N)                | Keep red for N seconds (default)            |
| extend_green(N)                | Add N extra seconds to green                |
| extend_red(N)                  | Add N extra seconds to red                  |
| extend_yellow(N)               | Add N extra seconds to yellow               |
| switch_to_green                | Change signal to green immediately          |
| switch_to_red                  | Change signal to red immediately            |
| activate_pedestrian_crossing   | *(additive)* Enable pedestrian crossing     |
| give_emergency_priority        | *(additive)* Clear path for emergency       |
| display_warning(Msg)           | *(additive)* Show warning message           |

**Default timings**: Green = 30 s, Yellow = 5 s, Red = 30 s.

**Additive actions** are always included alongside the main signal action.
**Signal-timing actions** compete; the highest-priority rule wins.

---

## Priority Order (highest → lowest)

`emergency > pedestrian > weather > time > density > basic`

Ties within the same priority: **more conditions (specificity) wins**, then **lower rule ID**.

---

## Rules

### A. Basic Signal Operation

| # | Conditions | Action |
|---|-----------|--------|
| 1 | light=green, density=low | maintain_green(30) |
| 2 | light=red, density=low   | maintain_red(30)   |
| 3 | light=yellow             | switch_to_red      |

### B. Traffic Density Adaptation

| # | Conditions | Action |
|---|-----------|--------|
| 4 | density=medium, light=green | extend_green(15) |
| 5 | density=high, light=green   | extend_green(20) |
| 6 | density=high, light=red     | switch_to_green  |

### C. Weather-Based Adjustments

| # | Conditions | Action |
|---|-----------|--------|
| 7  | weather=light_rain, light=yellow         | extend_yellow(5)                                  |
| 8  | weather=heavy_rain, density=high         | extend_green(25)                                  |
| 9  | weather=heavy_rain                       | display_warning('Slippery road; Drive carefully') |
| 10 | weather=cloudy, density=medium           | maintain_green(30)                                |

### D. Time-Based Safety

| # | Conditions | Action |
|---|-----------|--------|
| 11 | time=night, density=low    | maintain_green(30) |
| 12 | time=night, pedestrian=yes | extend_red(10)     |

### E. Pedestrian Protection

| # | Conditions | Action |
|---|-----------|--------|
| 13 | pedestrian=yes, light=red          | activate_pedestrian_crossing |
| 14 | pedestrian=yes, weather=heavy_rain | extend_red(15)               |

### F. Emergency Vehicle Priority

| # | Conditions | Action |
|---|-----------|--------|
| 15 | emergency=yes             | give_emergency_priority |
| 16 | emergency=yes, light=red  | switch_to_green         |

### G. Combined Intelligent Rules

| # | Conditions | Action | Note |
|---|-----------|--------|------|
| 17 | weather=heavy_rain, density=high, time=day      | extend_green(35) | Beats Rule 8 (more specific) |
| 18 | density=low, time=day                           | maintain_green(30) | |
| 19 | weather=dry, density=medium                     | maintain_green(30) | Beats Rule 4 (higher priority tier) |
| 20 | weather=heavy_rain, pedestrian=yes, light=red   | extend_red(25) | Beats Rule 14 (more specific) |

---

## Example Scenarios

| Scenario | Inputs | Expected Actions |
|----------|--------|-----------------|
| Normal day, low traffic | density=low, weather=dry, time=day, light=green, pedestrian=no, emergency=no | maintain_green(30) |
| Rush hour, heavy rain | density=high, weather=heavy_rain, time=day, light=green, pedestrian=no, emergency=no | extend_green(35), display_warning(...) |
| Pedestrian at red, light rain | density=low, weather=light_rain, time=day, light=red, pedestrian=yes, emergency=no | activate_pedestrian_crossing, maintain_red(30) |
| Emergency vehicle at red | density=medium, weather=dry, time=day, light=red, pedestrian=no, emergency=yes | give_emergency_priority, switch_to_green |
| Night, low traffic, pedestrian | density=low, weather=dry, time=night, light=red, pedestrian=yes, emergency=no | activate_pedestrian_crossing, extend_red(10) |
