function [speedCmd, phase, dGoal, status] = taxi_controller(x, y, vMeas, speedIn, signDetected, signDepth, signShape, t, dt, px, py, feel, confirmed, helpBtn, safeBtn)
%#codegen
% TAXI_CONTROLLER  RideTune's driving logic, written to sit in a MATLAB Function block.
% Put it where stopSignDetectionSpeedAdjust is now (inside speedController):
%   speedIn      = speed after turnSpeedHandler / obstacle adjust (m/s)
%   signDetected = the stopSignDetection tag (HSV blob >= 100 px and depth <= 1.2 m)
%   signDepth    = distanceToSign (m) from findStopSignDistance
%   signShape    = classify_red_sign output: 0 unknown, 1 stop, 2 yield, 3 facing another road
%   x, y         = currentPose(1:2);  vMeas = measuredSpeed;  t = time (s);  dt = sample time (s)
%   px, py       = Constant blocks path_x4 and path_y4 (after apply_route: the rider's route)
% Rider inputs (Constant blocks, changed live with rider_controls.m):
%   feel      = 1 Turtle .. 3 Normal .. 5 Rabbit: how gently it brakes and speeds up
%   confirmed = 1 once the rider taps "I'm in, I'm alone" (the car never leaves the pickup before)
%   helpBtn   = 1 when the rider taps "Ask for help": pull over at the nearest safe spot
%   safeBtn   = 1 when the rider taps "I'm safe": carry on (the car stays put until then)
% Outputs: speedCmd (m/s, smoothed), phase (1 to pickup, 2 at pickup, 3 to drop-off, 4 arrived),
%          dGoal (m to the next stop, -1 if none), status (code for the rider screen, see status_message.m).

% ---------- settings (keep in step with taxi_config.m) ----------
PICKUP = [1.25, -1.09];        % MEASURE with the Coordinate Helper
STOP_HOLD = 2;                 % s full stop at a stop sign (same as the provided model)
CAM_AHEAD = 0.2;               % m camera ahead of the pose (assumption)
YIELD_SPEED = 0.25;            % m/s while passing a yield sign
TARGET = 0.5;                  % MODEL targetSpeed, used only for the status text
LEAD = 0.02; VMIN = 0.03; TAU_F = 0.15;    % Calm Ride: brake 2 cm early, creep speed, jerk filter
STOPPED = 0.02;                % m/s counts as stopped on the real car
AFTER_CONFIRM = 3;             % s from the rider's confirm to pulling away
HELP_AHEAD = 0.9;              % m to the nearest safe spot after "Ask for help"
ESC = [15 27 39];              % s with no "I'm safe": call contact, call again, call 911
LIGHT_OFFSET = 0;              % s shift of the traffic-light cycle (see traffic_light_state.m)
LIGHTS = [1 0.6 1.55 0; 2 -0.6 1.28 90; 3 -0.37 0.3 180; 4 0.75 0.48 -90];   % MODEL [id x y yaw]

persistent ready idx sCum L sPick sDrop ph leaveAt holding holdTarget holdUntil handled vr vf ...
    lightS lightId nLights lightOn lightK helpStage helpTarget helpStoppedAt prevHelp prevSafe
if isempty(ready)
    n = numel(px);
    sCum = zeros(n, 1);                                         % arc length along the route
    for k = 2:n
        sCum(k) = sCum(k-1) + hypot(px(k) - px(k-1), py(k) - py(k-1));
    end
    L = sCum(n);                                                % route ends at the drop-off
    idx = 1;                                                    % route starts at the hub
    sPick = sCum(firstNear(px, py, PICKUP(1), PICKUP(2)));      % first pass of the pickup
    sDrop = L - 0.03;
    % traffic lights that face the route after the pickup (same test as route_guidance.m)
    lightS = zeros(4, 1); lightId = zeros(4, 1); nLights = 0;
    for j = 1:4
        nx = cosd(LIGHTS(j, 4)); ny = sind(LIGHTS(j, 4));      % way the light faces
        bestErr = 1e9; bestS = -1;
        for k = 2:n-1
            hx = px(k+1) - px(k-1); hy = py(k+1) - py(k-1); hn = hypot(hx, hy);
            if hn < 1e-9 || sCum(k) <= sPick, continue; end
            hx = hx / hn; hy = hy / hn;                         % car heading here
            vx = LIGHTS(j, 2) - px(k); vy = LIGHTS(j, 3) - py(k);
            along = vx * hx + vy * hy; side = abs(-vx * hy + vy * hx);
            if -(hx * nx + hy * ny) > 0.8 && along > 0.2 && along < 0.6 && side < 0.6 && abs(along - 0.35) < bestErr
                bestErr = abs(along - 0.35); bestS = sCum(k);   % stop 0.35 m before the light
            end
        end
        if bestS >= 0
            nLights = nLights + 1; lightS(nLights) = bestS; lightId(nLights) = LIGHTS(j, 1);
        end
    end
    ph = 1; leaveAt = -1; holding = false; holdTarget = 0; holdUntil = -1; handled = false;
    vr = 0; vf = 0; lightOn = false; lightK = 1;
    helpStage = 0; helpTarget = 0; helpStoppedAt = 0; prevHelp = false; prevSafe = false;
    ready = true;
end

% ---------- ride feel: turtle .. rabbit ----------
[A_COMF, UP, DOWN] = ride_feel(feel);

% ---------- where are we along the route? (windowed search, like the model's locator) ----------
n = numel(px); best = 1e9; bestK = idx;
for k = max(1, idx - 60):min(n, idx + 60)
    d = (x - px(k))^2 + (y - py(k))^2;
    if d < best, best = d; bestK = k; end
end
idx = bestK;
sNow = sCum(idx);
isStopped = abs(vMeas) < STOPPED;

% ---------- rider buttons (react to a new press only) ----------
helpPress = helpBtn > 0.5 && ~prevHelp; prevHelp = helpBtn > 0.5;
safePress = safeBtn > 0.5 && ~prevSafe; prevSafe = safeBtn > 0.5;
if helpPress && ph == 3 && helpStage == 0
    helpStage = 1; helpTarget = min(sDrop - 0.1, sNow + HELP_AHEAD);   % pull over at the nearest safe spot
end
if safePress && helpStage > 0
    helpStage = 0;                                              % rider is safe: carry on
end

% ---------- stop signs: stop with the front of the car at the sign ----------
if ~signDetected, handled = false; end                          % sign out of view: ready for the next one
isStopSign = signShape == 1 || signShape == 0;                  % unknown shape: stop, to be safe
if signDetected && isStopSign && ~handled && ~holding && ph ~= 2
    holding = true;
    holdTarget = sNow + signDepth + CAM_AHEAD - 0.22;           % 0.22 m: pose to front bumper, small margin
    holdUntil = -1;
end

% ---------- traffic lights: stop gently on red or yellow if there is room, go on green ----------
if lightOn && ~traffic_light_state(lightId(lightK), t, LIGHT_OFFSET)
    lightOn = false;                                            % turned green
end
if ~lightOn && ph == 3
    for j = 1:nLights
        dl = lightS(j) - sNow;
        if dl > 0.01 && dl < 1.2 && traffic_light_state(lightId(j), t, LIGHT_OFFSET) && vMeas^2 / (2 * A_COMF * 1.6) < dl
            lightOn = true; lightK = j; break;                  % room to stop calmly: stop at the line
        end
    end
end

% ---------- which stop are we heading for? (the nearest one wins) ----------
goal = -1;
if lightOn, goal = lightS(lightK); end
if holding && (goal < 0 || holdTarget < goal), goal = holdTarget; end
if goal < 0 && ph == 1, goal = sPick; end
if goal < 0 && ph == 3, goal = sDrop; end
if helpStage == 1 && (goal < 0 || helpTarget < goal), goal = helpTarget; end

% ---------- Calm Ride: constant-deceleration braking curve ----------
vGoal = speedIn;
dGoal = -1;
if goal >= 0
    dGoal = goal - sNow;
    if dGoal <= 0.012
        vGoal = 0;
    else
        vGoal = max(VMIN, min(speedIn, sqrt(2 * A_COMF * max(0, dGoal - LEAD))));
    end
end
if signDetected && signShape == 2, vGoal = min(vGoal, YIELD_SPEED); end   % yield: slow, keep going
waiting = ph == 2 || ph == 4 || (holding && holdUntil >= 0) || helpStage == 2;
if waiting, vGoal = 0; end

% rate limiter + first-order filter = smooth starts and stops
vr = vr + min(max(vGoal - vr, DOWN * dt), UP * dt);
vf = vf + (vr - vf) * dt / TAU_F;
speedCmd = vf;

% ---------- state changes ----------
if helpStage == 1 && isStopped && helpTarget - sNow < 0.1
    helpStage = 2; helpStoppedAt = t; vr = 0; vf = 0;          % pulled over: stay until "I'm safe"
end
if holding
    if holdUntil < 0 && isStopped && holdTarget - sNow < 0.1
        holdUntil = t + STOP_HOLD; vr = 0; vf = 0;              % full stop reached
    elseif holdUntil >= 0 && t >= holdUntil
        holding = false; handled = true;                        % done with this sign
    end
elseif ph == 1 && isStopped && sPick - sNow < 0.1
    ph = 2; leaveAt = -1; vr = 0; vf = 0;                       % at the curb: wait for the rider
elseif ph == 2 && leaveAt < 0 && confirmed > 0.5
    leaveAt = t + AFTER_CONFIRM;                                % rider confirmed: route locks, leave soon
elseif ph == 2 && leaveAt >= 0 && t >= leaveAt
    ph = 3;                                                     % off to the drop-off
elseif ph == 3 && isStopped && sDrop - sNow < 0.1 && helpStage == 0
    ph = 4;                                                     % arrived
end
phase = ph;

% ---------- status code for the rider screen ----------
if ph == 4
    status = 1;                                   % arrived
elseif ph == 2 && leaveAt < 0
    status = 21;                                  % waiting for the rider to confirm (code word, alone)
elseif ph == 2
    status = 2;                                   % welcome aboard, leaving soon
elseif helpStage == 1
    status = 16;                                  % pulling over for help
elseif helpStage == 2
    w = t - helpStoppedAt;
    if w >= ESC(3)
        status = 20;                              % 911 called
    elseif w >= ESC(2)
        status = 19;                              % calling the emergency contact again
    elseif w >= ESC(1)
        status = 18;                              % calling the emergency contact
    else
        status = 17;                              % stopped, waiting for "I'm safe"
    end
elseif lightOn && isStopped && lightS(lightK) - sNow < 0.05
    status = 15;                                  % waiting at the red light
elseif lightOn
    status = 14;                                  % traffic light ahead, slowing
elseif holding && holdUntil >= 0
    status = 3;                                   % stopped at the stop sign
elseif holding
    status = 4;                                   % slowing for the stop sign
elseif signDetected && signShape == 2
    status = 5;                                   % yield sign, slowing
elseif signDetected && signShape == 3
    status = 6;                                   % sign for another road
elseif ph == 1 && sPick - sNow < 0.7
    status = 7;                                   % arriving at pickup
elseif ph == 3 && sDrop - sNow < 0.7
    status = 8;                                   % arriving at drop-off
elseif speedIn < 0.9 * TARGET
    status = 9;                                   % slowing for a turn
elseif ph == 1
    status = 10;                                  % on the way to pick you up
else
    status = 11;                                  % all clear, driving to destination
end
end

function k = firstNear(px, py, x, y)
% closest point of the route's first pass by (x, y); the nearest point if it never comes within 5 cm
n = numel(px); k = 0; best = 1e9; kb = 1;
for i = 1:n
    d = hypot(x - px(i), y - py(i));
    if d < best, best = d; kb = i; end
    if k == 0 && d < 0.05, k = i; end                           % first time within 5 cm
end
if k == 0
    k = kb;
else
    while k < n && hypot(x - px(k+1), y - py(k+1)) < hypot(x - px(k), y - py(k))
        k = k + 1;                                              % slide to the closest point of that pass
    end
end
end
