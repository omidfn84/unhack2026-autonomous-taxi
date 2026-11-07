# Calm Ride: an autonomous taxi that drives calmly and explains itself

**UNHACK 2026 · YSpace Lassonde × MathWorks × Quanser · Nov 7–8, 2026**

## The problem
Many riders feel unsafe in conventional ride-hailing, and most people are still nervous about
self-driving cars. Hard braking, sudden starts and not knowing *why* the car is doing something
make that fear worse.

**How Might We:** help early adopters who feel unsafe in conventional riding systems feel comfortable
riding in autonomous taxis, so they kickstart adoption and increase the availability, safety and
accessibility of autonomous taxis?

## Our solution
Built on top of the Quanser QCar2 self-driving stack (MATLAB, Simulink, QLabs):

| Feature | What the rider gets | How it works |
|---|---|---|
| **Calm Ride** | Smooth, predictable stops and starts | Constant-deceleration braking curve (`v = √(2·a·d)`) + rate limiter + low-pass filter for jerk limiting |
| **Pedestrian yield** | The car visibly slows, waits and resumes for people | Depth-camera obstacle distance feeds the Calm Ride braking curve |
| **"Why am I stopping?" screen** | Plain-language status: what the car sees and why it is stopping | Status logic turns live vehicle signals into rider messages |

### Results (simulation)
Compared with the baseline on/off stop logic, Calm Ride cut peak braking ~16× (3.96 → 0.25 m/s²)
and peak jerk ~240×, while still stopping within ~1 cm of the target. *(Python model; re-measure in QLabs.)*

## Repo layout
```
calm_ride/          Calm Ride braking controller + Mac-friendly Simulink test model builder
rider_screen/       Rider status screen (MATLAB uifigure) + fake and real ride loaders
baseline/           Quanser self-driving stack (unhack2026 branch) — team edits go here
setup_unhack.m      One-time setup: checks toolboxes, sets path, runs the demos
```

## Getting started
**Any OS (MATLAB R2026a recommended):**
```matlab
cd <this repo>
setup_unhack            % checks toolboxes, plays the rider screen, builds + runs calm_ride_test.slx
```
**Windows + QLabs (full stack):** follow the Quanser guide in `baseline/`, then open
`Virtual_Setup_Competition_Map.m` and run the model.

### Logging a real run for the rider screen
Mux `[speed, stop_flag, phase, distanceToObstacle, stopLineDistance, distanceToGoal]` into a
**To Workspace** block named `riderLog` (Structure With Time, sample time 0.1), run, then
`save('run1.mat','out')`. Play it with `rider_screen(load_real_run('run1.mat'), 1)`.

## Team workflow
- Pull before you start: `git pull`
- Commit small, clear changes: `git add . && git commit -m "Add pedestrian yield" && git push`
- `.slx` files are binary and can't be merged — **one person edits the main model at a time**; say so in the group chat.

## Team
- Omid Firouzinia — rider screen, Calm Ride controller
- _add teammates_

## Credits
Baseline self-driving stack and QLabs by [Quanser](https://github.com/quanser/student-competition-resources-matlab/tree/unhack2026).
MATLAB and Simulink by MathWorks. Files in `baseline/` belong to Quanser.
