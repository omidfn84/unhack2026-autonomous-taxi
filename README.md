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
| **Pickup and drop-off** | The taxi stops at the curb, waits, then leaves | `taxi_controller.m`: approach → wait → leave (kickoff slide 17) |
| **Calm Ride** | Smooth, predictable stops and starts | Constant-deceleration braking curve (`v = √(2·a·d)`) + rate limiter + jerk filter |
| **Stop at the line** | Full stop beside the stop sign, not 1.2 m early | Uses the HSV blob's measured depth as the braking target |
| **Stop vs yield** | No needless stops at yield signs | `classify_red_sign.m`: blob fill (octagon vs triangle ring) and width/height |
| **Rider screen** | Status, next turn and distance, route, what the camera sees | `rider_screen/` driven by the controller's status code |

### What the provided stack does on a lap (from the model, `simulate_lap('base')`)
Drives path 4 (outer lap) from the taxi hub at 0.5 m/s, slows in turns by cos(steering)^10,
and stops 2 s whenever the HSV pipeline sees a red blob ≥ 100 px within 1.2 m. That includes
yield signs and a stop sign that faces another road. Peak braking about 2 m/s² in our lap simulation.

### Our taxi on the same lap (`simulate_lap('ours')`)
Picks up at the curb, stops with its front at the stop sign, slows past yield signs, drops off at
the hub. Peak braking about 0.4 m/s², 0 harsh jolts. *(Simulation from the model's numbers; re-measure in QLabs.)*

## Repo layout
```
taxi/               taxi_controller (pickup/drop-off + Calm Ride + stop at line), classify_red_sign,
                    route_guidance, scenario_objects, simulate_lap (Mac), calibrate_sign_shapes
rider_screen/       Rider screen on the QLabs map: rider_screen_qlabs/update, replay_ride,
                    load_qlabs_run, rider_screen_live (live during a run)
calm_ride/          Calm Ride braking curve + Mac-friendly Simulink test model builder
demo/               calm_ride_lap.html: the same lap as an interactive web page
baseline/           Quanser self-driving stack (unhack2026 branch) — team edits go here
setup_unhack.m      One-time setup: checks toolboxes, sets path, runs the demos
run_lap_demo.m      Simulate one lap (provided stack and ours) and play it on the rider screen
```

## Getting started
**Any OS (MATLAB R2026a recommended):**
```matlab
cd <this repo>
setup_unhack            % checks toolboxes, plays the rider screen, builds + runs calm_ride_test.slx
```
**Windows + QLabs (full stack):** follow the Quanser guide in `baseline/`, then open
`Virtual_Setup_Competition_Map.m` and run the model.

**Mac (no QLabs):** `run_lap_demo` simulates the lap and plays it on the rider screen.

## Wiring our logic into the Simulink model (Windows + QLabs)
1. **Measure the stops.** In QLabs, use the Coordinate Helper on the pickup and drop-off curbs and put
   the x, y values in `taxi_config.m` and at the top of `taxi_controller.m`.
2. **Sign shape.** Inside `HSVStopSignDetection/findStopSignLocation`, add a MATLAB Function block with
   `classify_red_sign.m`. Inputs: `imageBinary` (from colorThresholdingHSV), `blobLocation (px) [2]`,
   `blobFound?`. Send its `shape` output out with a Goto tag `signShape`.
3. **Sign depth.** Inside `HSVStopSignDetection`, add a Goto tag `distanceToSign` on the
   `findStopSignDistance` output.
4. **Taxi controller.** Inside `speedController`, replace `stopSignDetectionSpeedAdjust` with a MATLAB
   Function block holding `taxi_controller.m`. Inputs: currentPose x and y, measuredSpeed, the speed
   that used to go into stopSignDetectionSpeedAdjust, stopSignDetection, distanceToSign, signShape,
   a Clock, Constant `Controller_Sample_Time`, Constants `path_x4` and `path_y4`. Its `speedCmd` goes
   where `speedOut` went. (Goto tags are local by default: add inports to speedController, or set the
   tags' visibility to global.)
5. **Rider screen.** Either add a MATLAB Function block with `rider_screen_live.m` (live, Normal mode),
   or log a run and replay it (below).

### Logging a run for the rider screen
Mux these 10 signals, in order, into a **To Workspace** block named `riderLog` (Structure With Time,
sample time 0.05): `x, y, heading` (currentPose), `measuredSpeed`, `phase, dGoal, status`
(taxi_controller), `stopSignDetection`, `distanceToSign`, `signShape`. Run, then
`save('run1.mat','out')` and play it with `replay_ride(load_qlabs_run('run1.mat'), 1)`.

### Tuning the stop/yield check
Log `imageBinary`, `blobLocation` and `blobFound?` (see `calibrate_sign_shapes.m`), drive past one
stop sign and one yield sign, run the script, and set the fill thresholds between the two groups.

## Team workflow
- Pull before you start: `git pull`
- Commit small, clear changes: `git add . && git commit -m "Add pedestrian yield" && git push`
- `.slx` files are binary and can't be merged — **one person edits the main model at a time**; say so in the group chat.

## Team
- Omid Firouzinia — rider screen, Calm Ride controller
- _add teammates_

## Credits
Baseline self-driving stack and QLabs by [Quanser](https://github.com/quanser/student-competition-resources-matlab/tree/unhack2026).
MATLAB and Simulink by MathWorks. Files in `baseline/` and the map image in `rider_screen/map_bg.png`
(QLabs top view from the UNHACK 2026 kickoff deck) belong to Quanser.
