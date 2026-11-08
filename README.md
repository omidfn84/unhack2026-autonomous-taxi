# RideTune: the rider-trust layer for self-driving taxis

**UNHACK 2026 · YSpace Lassonde × MathWorks × Quanser · Nov 7–8, 2026**

**Live demo (no login):** https://claude.ai/artifact/6rtbs1FW5k4RfgAC1W249C

## The problem
Many riders feel unsafe in regular taxis and rideshares, especially women riding alone at night, and most
people are still nervous about self-driving cars. Removing the driver isn't enough: someone still has to check
you're in the right car, know where you are, and help if something feels wrong.

**How Might We:** help early adopters who feel unsafe in conventional riding systems feel comfortable
riding in autonomous taxis, so they kickstart adoption and increase the availability, safety and
accessibility of autonomous taxis?

## What RideTune is
RideTune is not a taxi company. It's software that self-driving car companies add to their own cars.
We built it on top of the Quanser QCar 2 self-driving stack (MATLAB, Simulink, QLabs) to show it plugs into an
existing stack.

| Feature | What the rider gets | Where it lives |
|---|---|---|
| **Verified pickup** | Code word on the door; the car never leaves until the rider taps "I'm in, I'm alone" | `taxi_controller.m` (input `confirmed`) |
| **Route choice + lock** | Fastest, scenic or cheapest, each a real lane path; locked once confirmed | `route_guidance.m`, `apply_route.m` |
| **Ride feel: turtle to rabbit** | Rider sets how gently the car brakes and speeds up, live | `ride_feel.m`, `taxi_controller.m` (input `feel`) |
| **Quiet help** | Car pulls over and stays put until "I'm safe"; no reply → call contact twice → 911 | `taxi_controller.m` (inputs `helpBtn`, `safeBtn`) |
| **Calm Ride** | Smooth, early, even braking and starts | Braking curve `v = √(2·a·d)` + rate limiter + jerk filter |
| **Stop at the line** | Full stop beside the stop sign, not 1.2 m early | Uses the HSV blob's measured depth as the braking target |
| **Stop vs yield** | No needless stops at yield signs or signs for another road | `classify_red_sign.m`: blob fill + width/height |
| **Traffic lights** | Stops gently on red/yellow, goes on green | `traffic_light_state.m` + `taxi_controller.m` |
| **Rider screen** | Status, next turn, distance, route, what the camera sees | `rider_screen/` |

**Routes** (all start at the taxi hub, go to the same pickup, end at the hub):

| Choice | Lane path | After pickup (real size) | Traffic lights | Example fare |
|---|---|---|---|---|
| Cheapest | path 4, the outer lap | 151 m | 0 | $6.02 |
| Fastest | path 2, through the centre | 84 m | 1 | $7.68 |
| Scenic | path 7, the long loop | 175 m | 2 | $9.50 |

Fares are examples a car company might set ($3 + $2 per 100 m + $3 downtown fee). RideTune shows the
company's prices; it doesn't set them.

**Ride feel levels** (model car, m/s²): Turtle 0.08 / 0.10 / 0.20, Gentle 0.11 / 0.15 / 0.30, Normal 0.15 / 0.20 / 0.40,
Brisk 0.22 / 0.30 / 0.60, Rabbit 0.30 / 0.40 / 0.80 (planned braking / max speed-up / max slow-down).

### What the provided stack does on a lap (`simulate_lap('base')`)
Drives path 4 (outer lap) from the taxi hub at 0.5 m/s, slows in turns by cos(steering)^10,
and stops 2 s whenever the HSV pipeline sees a red blob ≥ 100 px within 1.2 m. That includes
yield signs and a stop sign that faces another road.

### RideTune on the same lap (`simulate_lap('ours')`)
Picks up at the curb, waits for the rider, stops with its front at the stop sign, slows past yield signs,
drops off at the hub, with gentle braking and no sudden speed changes. *(Simulation from the model's numbers; re-measure in QLabs.)*

## Repo layout
```
taxi/               taxi_controller (pickup/drop-off, Calm Ride, stop at line, lights, ride feel, help),
                    route_guidance (3 routes), apply_route (send a route to the model), ride_feel,
                    traffic_light_state, classify_red_sign, scenario_objects, simulate_lap (Mac),
                    sign_camera (Mac), calibrate_sign_shapes
rider_screen/       Rider screen on the QLabs map: rider_screen_qlabs/update, replay_ride,
                    load_qlabs_run, rider_screen_live (live during a run), rider_controls (rider buttons, live)
calm_ride/          Calm Ride braking curve + Mac-friendly Simulink test model builder
demo/               The interactive web demo (same as the live link)
baseline/           Quanser self-driving stack (unhack2026 branch)
setup_unhack.m      One-time setup: checks toolboxes, sets path, runs the demos
run_lap_demo.m      Simulate a ride (any route / ride feel / help) and play it on the rider screen
```

## Getting started
**Any OS (MATLAB R2026a recommended):**
```matlab
cd <this repo>
setup_unhack            % checks toolboxes, plays the rider screen, builds + runs calm_ride_test.slx
run_lap_demo            % fastest route, turtle ride feel, on the rider screen
```
More rides on a Mac:
```matlab
replay_ride(simulate_lap('ours', 'route', 'scenic', 'feel', 5), 2)      % scenic route, rabbit
replay_ride(simulate_lap('ours', 'helpAt', 5, 'safeAt', 20), 2)         % "Ask for help", "I'm safe" 20 s later
replay_ride(simulate_lap('ours', 'helpAt', 5), 4)                       % no reply: contact twice, then 911
```

**Windows + QLabs (full stack):** follow the Quanser guide in `baseline/`, then open
`Virtual_Setup_Competition_Map.m` and run the model.

## Wiring RideTune into the Simulink model (Windows + QLabs)
1. **Measure the stops.** In QLabs, use the Coordinate Helper on the pickup and drop-off curbs and put
   the x, y values in `taxi_config.m` and at the top of `taxi_controller.m`.
2. **Pick the route.** After `Virtual_Setup_Competition_Map.m`, run `apply_route('fastest')` (or `'scenic'`,
   `'cheapest'`). It replaces `path_x4` / `path_y4` in the base workspace, so the model's pathPlanner and the
   controller follow the rider's route. Rerun the setup script to get the original lap back.
3. **Sign shape.** Inside `HSVStopSignDetection/findStopSignLocation`, add a MATLAB Function block with
   `classify_red_sign.m`. Inputs: `imageBinary` (from colorThresholdingHSV), `blobLocation (px) [2]`,
   `blobFound?`. Send its `shape` output out with a Goto tag `signShape`.
4. **Sign depth.** Inside `HSVStopSignDetection`, add a Goto tag `distanceToSign` on the
   `findStopSignDistance` output.
5. **Rider inputs.** Add four Constant blocks at the top level: `RideTune_feel` (3), `RideTune_confirm` (0),
   `RideTune_help` (0), `RideTune_safe` (0).
6. **Taxi controller.** Inside `speedController`, replace `stopSignDetectionSpeedAdjust` with a MATLAB
   Function block holding `taxi_controller.m`. Inputs, in order: currentPose x and y, measuredSpeed, the speed
   that used to go into stopSignDetectionSpeedAdjust, stopSignDetection, distanceToSign, signShape,
   a Clock, Constant `Controller_Sample_Time`, Constants `path_x4` and `path_y4`, then the four rider
   Constants (feel, confirm, help, safe). Its `speedCmd` goes where `speedOut` went. (Goto tags are local by
   default: add inports to speedController, or set the tags' visibility to global.)
7. **Run it.** Press Run, then `rider_controls('your_model_name')` opens the rider's slider and buttons. The car
   waits at the pickup until you click "I'm in, I'm alone".
8. **Rider screen.** Either add a MATLAB Function block with `rider_screen_live.m` (live, Normal mode),
   or log a run and replay it (below).

### Logging a run for the rider screen
Mux these 10 signals, in order, into a **To Workspace** block named `riderLog` (Structure With Time,
sample time 0.05): `x, y, heading` (currentPose), `measuredSpeed`, `phase, dGoal, status`
(taxi_controller), `stopSignDetection`, `distanceToSign`, `signShape`. Run, then
`save('run1.mat','out')` and play it with `replay_ride(load_qlabs_run('run1.mat'), 1)`.

### Tuning the stop/yield check
Log `imageBinary`, `blobLocation` and `blobFound?` (see `calibrate_sign_shapes.m`), drive past one
stop sign and one yield sign, run the script, and set the fill thresholds between the two groups.

## Honest limits
- Not yet run in QLabs: numbers come from `simulate_lap`, which uses the model's own speed logic and the real scenario objects.
- Pickup at (1.25, −1.09) is estimated; replace it with the organisers' coordinates.
- Traffic-light colour comes from the scenario's fixed 20 s cycle (`traffic_light_state.m`, shift it with
  `lightOffset`); a real car would use its own light detection.
- The pathPlanner was written for the closed outer lap; check it follows an open route end to end in QLabs.
- The code word, live trip sharing, support chat and calls are app and service features. The car side is
  the inputs above (confirm, help, I'm safe) and the status codes it sends to the rider screen.
- Pedestrians are not handled: the obstacle-detection part of the given model is switched off.

## Team workflow
- Pull before you start: `git pull`
- Commit small, clear changes: `git add . && git commit -m "Add pedestrian yield" && git push`
- `.slx` files are binary and can't be merged — **one person edits the main model at a time**; say so in the group chat.

## Team
- Omid Firouzinia — rider screen, RideTune controller
- _add teammates_

## Credits
Baseline self-driving stack and QLabs by [Quanser](https://github.com/quanser/student-competition-resources-matlab/tree/unhack2026).
MATLAB and Simulink by MathWorks. Files in `baseline/` and the map image in `rider_screen/map_bg.png`
(QLabs top view from the UNHACK 2026 kickoff deck) belong to Quanser.
