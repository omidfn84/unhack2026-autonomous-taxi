function [speedCmd, phase, dGoal, status] = taxi_controller(x, y, vMeas, speedIn, signDetected, signDepth, signShape, t, dt, px, py)
%#codegen
% TAXI_CONTROLLER  Our taxi logic, written to sit in a MATLAB Function block.
% Put it where stopSignDetectionSpeedAdjust is now (inside speedController):
%   speedIn      = speed after turnSpeedHandler / obstacle adjust (m/s)
%   signDetected = the stopSignDetection tag (HSV blob >= 100 px and depth <= 1.2 m)
%   signDepth    = distanceToSign (m) from findStopSignDistance
%   signShape    = classify_red_sign output: 0 unknown, 1 stop, 2 yield, 3 facing another road
%   x, y         = currentPose(1:2);  vMeas = measuredSpeed;  t = time (s);  dt = sample time (s)
%   px, py       = Constant blocks with path_x4 and path_y4
% Outputs: speedCmd (m/s, smoothed), phase (1 to pickup, 2 at pickup, 3 to drop-off, 4 arrived),
%          dGoal (m to the next stop, -1 if none), status (code for the rider screen).

% ---------- settings (keep in step with taxi_config.m) ----------
PICKUP = [1.25, -1.09];        % MEASURE with the Coordinate Helper
DROPOFF = [-1.205, -0.83];     % placeholder: taxi hub
HUB = [-1.205, -0.83];         % MODEL: taxi hub spawn
DWELL = 5;                     % s the rider gets to climb in / out
STOP_HOLD = 2;                 % s full stop at a stop sign (same as the provided model)
CAM_AHEAD = 0.2;               % m camera ahead of the pose (assumption)
YIELD_SPEED = 0.25;            % m/s while passing a yield sign
TARGET = 0.5;                  % MODEL targetSpeed, used only for the status text
A_COMF = 0.15; LEAD = 0.02; VMIN = 0.03;   % Calm Ride braking curve
UP = 0.2; DOWN = -0.4; TAU_F = 0.15;       % Calm Ride rate limit and jerk filter
STOPPED = 0.02;                % m/s counts as stopped on the real car

persistent ready idx sCum L sStart sPick sDrop ph dwellUntil holding holdTarget holdUntil handled vr vf
if isempty(ready)
    n = numel(px);
    sCum = zeros(n, 1);                                         % arc length along path 4
    for k = 2:n
        sCum(k) = sCum(k-1) + hypot(px(k) - px(k-1), py(k) - py(k-1));
    end
    L = sCum(n) + hypot(px(1) - px(n), py(1) - py(n));          % full lap length
    idx = nearestIndex(px, py, HUB(1), HUB(2));                 % lap starts at the hub
    sStart = sCum(idx);
    sPick = mod(sCum(nearestIndex(px, py, PICKUP(1), PICKUP(2))) - sStart, L);
    sDrop = mod(sCum(nearestIndex(px, py, DROPOFF(1), DROPOFF(2))) - sStart, L);
    if sDrop < sPick, sDrop = L - 0.03; end                     % drop-off at the hub = end of lap
    ph = 1; dwellUntil = 0; holding = false; holdTarget = 0; holdUntil = -1;
    handled = false; vr = 0; vf = 0; ready = true;
end

% ---------- where are we along the lap? (windowed search, like the model's locator) ----------
n = numel(px); best = 1e9; bestK = idx;
for w = -60:60
    k = mod(idx - 1 + w, n) + 1;                                % wrap around the loop
    d = (x - px(k))^2 + (y - py(k))^2;
    if d < best, best = d; bestK = k; end
end
idx = bestK;
sNow = mod(sCum(idx) - sStart, L);
if ph == 1 && sNow > L - 0.5, sNow = sNow - L; end              % just behind the start line

% ---------- stop signs: stop with the front of the car at the sign ----------
if ~signDetected, handled = false; end                          % sign out of view: ready for the next one
isStopSign = signShape == 1 || signShape == 0;                  % unknown shape: stop, to be safe
if signDetected && isStopSign && ~handled && ~holding && ph ~= 2
    holding = true;
    holdTarget = sNow + signDepth + CAM_AHEAD - 0.22;           % 0.22 m: pose to front bumper, small margin
    holdUntil = -1;
end

% ---------- which stop are we heading for? ----------
goal = -1;
if holding
    goal = holdTarget;
elseif ph == 1
    goal = sPick;
elseif ph == 3
    goal = sDrop;
end

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
if ph == 2 || ph == 4 || (holding && holdUntil >= 0), vGoal = 0; end      % waiting

% rate limiter + first-order filter = smooth starts and stops
vr = vr + min(max(vGoal - vr, DOWN * dt), UP * dt);
vf = vf + (vr - vf) * dt / TAU_F;
speedCmd = vf;

% ---------- state changes ----------
isStopped = abs(vMeas) < STOPPED;
if holding
    if holdUntil < 0 && isStopped && holdTarget - sNow < 0.1
        holdUntil = t + STOP_HOLD; vr = 0; vf = 0;              % full stop reached
    elseif holdUntil >= 0 && t >= holdUntil
        holding = false; handled = true;                        % done with this sign
    end
elseif ph == 1 && isStopped && sPick - sNow < 0.1
    ph = 2; dwellUntil = t + DWELL; vr = 0; vf = 0;             % rider getting in
elseif ph == 2 && t >= dwellUntil
    ph = 3;                                                     % off to the drop-off
elseif ph == 3 && isStopped && sDrop - sNow < 0.1
    ph = 4;                                                     % arrived
end
phase = ph;

% ---------- status code for the rider screen ----------
if ph == 4
    status = 1;                                   % arrived
elseif ph == 2
    status = 2;                                   % welcome aboard, waiting
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

function k = nearestIndex(px, py, x, y)
best = 1e9; k = 1;
for i = 1:numel(px)
    d = (x - px(i))^2 + (y - py(i))^2;
    if d < best, best = d; k = i; end
end
end
