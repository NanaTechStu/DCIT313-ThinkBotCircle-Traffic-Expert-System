# Traffic Expert System — Production Rules Reference

**Project**: DCIT 313 — Adaptive Traffic Signal Control
**Rules authored by**: Bilson Priscilla Essirifua (Knowledge Engineer)
**Pseudo-code by**: Adu Selina Odoi (Knowledge Engineer)
**Prolog code by**: Stephen Edem Kwame Doe-lawson (Programmer – Prolog Owner)
**Source**: Knowledge Base Document — *Expert System for Adaptive Traffic Signal Control*

---

## Input Variables

| Variable   | Possible Values                     |
|------------|-------------------------------------|
| density    | `low` \| `medium` \| `high`         |
| weather    | `dry` \| `light_rain` \| `heavy_rain` \| `cloudy` |
| time       | `day` \| `night`                    |
| light      | `red` \| `yellow` \| `green`        |
| pedestrian | `yes` \| `no`                       |
| emergency  | `yes` \| `no`                       |

## Output Actions

| Action | Meaning |
|--------|---------|
| `maintain_green(N)` | Keep green for N seconds (default = 30 s) |
| `maintain_red(N)` | Keep red for N seconds (default = 30 s) |
| `extend_green(N)` | Add N extra seconds to green phase |
| `extend_red(N)` | Add N extra seconds to red phase |
| `extend_yellow(N)` | Add N extra seconds to yellow phase |
| `switch_to_green` | Change signal to green immediately |
| `switch_to_red` | Change signal to red immediately |
| `activate_pedestrian_crossing` | *(additive)* Enable pedestrian crossing signal |
| `give_emergency_priority` | *(additive)* Clear path for emergency vehicle |
| `display_warning(Msg)` | *(additive)* Show warning message to drivers |

**Default timings**: Green = 30 s, Yellow = 5 s, Red = 30 s.

**Additive actions** (`give_emergency_priority`, `activate_pedestrian_crossing`, `display_warning`) always fire alongside the main signal action — they are never in conflict.

**Signal-timing actions** compete; only one wins per evaluation cycle.

---

## Priority Order (highest → lowest)

`emergency(7) > combined(6) > pedestrian(5) > weather(4) > time(3) > density(2) > basic(1)`

**Tie-breaking**: more conditions (specificity) wins → then lower rule ID wins.

`combined` is used for Rule 20, which needs to outrank single-category pedestrian rules when all its conditions hold.

---

## Production Rules

### A. Basic Signal Operation

| # | Conditions (Prolog) | Action |
|---|---------------------|--------|
| 1 | `light=green, density=low` | `maintain_green(30)` |
| 2 | `light=red, density=low` | `maintain_red(30)` |
| 3 | `light=yellow` | `switch_to_red` |

### B. Traffic Density Adaptation

| # | Conditions (Prolog) | Action |
|---|---------------------|--------|
| 4 | `density=medium, light=green` | `extend_green(15)` |
| 5 | `density=high, light=green` | `extend_green(20)` |
| 6 | `density=high, light=red` | `switch_to_green` |

### C. Weather-Based Adjustments

| # | Conditions (Prolog) | Action |
|---|---------------------|--------|
| 7 | `weather=light_rain, light=yellow` | `extend_yellow(5)` |
| 8 | `weather=heavy_rain, density=high, light=green` | `extend_green(25)` |
| 9 | `weather=heavy_rain` | `display_warning('Slippery road; Drive carefully')` *(additive)* |
| 10 | `weather=cloudy, density=medium, light=green` | `maintain_green(30)` |

### D. Time-Based Safety

| # | Conditions (Prolog) | Action |
|---|---------------------|--------|
| 11 | `time=night, density=low, light=green` | `maintain_green(30)` |
| 12 | `time=night, pedestrian=yes, light=red` | `extend_red(10)` |

### E. Pedestrian Protection

| # | Conditions (Prolog) | Action |
|---|---------------------|--------|
| 13 | `pedestrian=yes, light=red` | `activate_pedestrian_crossing` *(additive)* |
| 14 | `pedestrian=yes, weather=heavy_rain, light=red` | `extend_red(15)` |

### F. Emergency Vehicle Priority

| # | Conditions (Prolog) | Action |
|---|---------------------|--------|
| 15 | `emergency=yes` | `give_emergency_priority` *(additive)* |
| 16 | `emergency=yes, light=red` | `switch_to_green` |

### G. Combined Intelligent Rules

| # | Conditions (Prolog) | Action | Note |
|---|---------------------|--------|------|
| 17 | `weather=heavy_rain, density=high, time=day, light=green` | `extend_green(35)` | Beats Rule 8 (4 vs 3 conditions) |
| 18 | `density=low, time=day, light=green` | `maintain_green(30)` | |
| 19 | `weather=dry, density=medium, light=green` | `maintain_green(30)` | Beats Rule 4 (weather > density priority) |
| 20 | `weather=heavy_rain, pedestrian=yes, light=red` | `extend_red(25)` | `combined` priority beats Rule 14 |

---

## Implementation Notes

Rules 8, 10, 11, 12, 14, 17, 18, 19 in the KB document do not specify a light state, but their actions are only meaningful for a specific light (e.g. `extend_green` requires `light=green`). An explicit `light=` condition has been added to each in the Prolog code to prevent those rules from firing in the wrong light state.

---

## Example Scenarios

| Scenario | Inputs | Expected Output |
|----------|--------|-----------------|
| Normal day, low traffic | `density=low, weather=dry, time=day, light=green, pedestrian=no, emergency=no` | `maintain_green(30)` |
| Rush hour, heavy rain | `density=high, weather=heavy_rain, time=day, light=green, pedestrian=no, emergency=no` | `extend_green(35)` + warning |
| Pedestrian at red, light rain | `density=low, weather=light_rain, time=day, light=red, pedestrian=yes, emergency=no` | `activate_pedestrian_crossing` + `maintain_red(30)` |
| Emergency vehicle at red | `density=medium, weather=dry, time=day, light=red, pedestrian=no, emergency=yes` | `give_emergency_priority` + `switch_to_green` |
| Night, pedestrian at red | `density=low, weather=dry, time=night, light=red, pedestrian=yes, emergency=no` | `activate_pedestrian_crossing` + `extend_red(10)` |
| Heavy rain, pedestrian at red | `density=medium, weather=heavy_rain, time=day, light=red, pedestrian=yes, emergency=no` | warning + `activate_pedestrian_crossing` + `extend_red(25)` |
