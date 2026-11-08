function ride = simulate_lap(mode, varargin)
% SIMULATE_LAP  Drive one ride on a Mac, with the provided model's speed logic.
%   ride = simulate_lap('base')     % provided stack: HSV stop for any red sign, outer lap, no pickup
%   ride = simulate_lap('ours')     % RideTune: taxi_controller.m on the rider's route
% Options for 'ours' (name, value):
%   'route'     'cheapest' (default) | 'fastest' | 'scenic'
%   'feel'      1 Turtle .. 3 Normal (default) .. 5 Rabbit
%   'confirmAt' s after reaching the pickup when the rider taps "I'm in, I'm alone" (default 3)
%   'helpAt'    s after leaving the pickup when the rider taps "Ask for help" (default: never)
%   'safeAt'    s after the car pulls over when the rider taps "I'm safe" (default: never)
% Example: ride = simulate_lap('ours', 'route', 'fastest', 'feel', 1, 'helpAt', 6, 'safeAt', 20);
% Model numbers used: targetSpeed 0.5, look-ahead 0.5*v+0.3, steering limit 0.6 rad,
% turn slow-down cos(steer)^10 limited to [0.3 1], 2 s stop-sign hold, 3 m/s^2 accel limit,
% 6 s start-up. Assumed: car stays on the path, speed loop ~0.15 s lag.

if nargin < 1, mode = 'ours'; end
opt = struct('route', 'cheapest', 'feel', 3, 'confirmAt', 3, 'helpAt', Inf, 'safeAt', Inf);
for k = 1:2:numel(varargin), opt.(varargin{k}) = varargin{k+1}; end   % read name/value options
if strcmp(mode, 'base'), opt.route = 'cheapest'; end      % the original car only knows the outer lap
cfg = taxi_config(opt.route, opt.feel); R = route_guidance(cfg); O = scenario_objects();
clear taxi_controller                                     % reset its persistent state
dt = 1/200; t = 0; s = 0; v = 0; vr = 0; elapsed = 0;
TAU_CAR = 0.15; ACC = 3; SDROP = R.L - 0.03;
logEvery = 0.05; nextLog = 0; k = 0;
tPick = Inf; tLeave = Inf; tStop = Inf;                   % when the rider's moments happen
ride = struct('mode', mode, 'route', opt.route, 'feel', opt.feel, 't', [], 'x', [], 'y', [], 'h', [], 'v', [], 's', [], ...
    'det', [], 'z', [], 'area', [], 'shape', [], 'facing', [], 'signType', {{}}, 'sx', [], 'sy', [], ...
    'phase', [], 'dGoal', [], 'status', [], 'atten', [], 'steer', []);

done = false;
while ~done && t < 200
    [x, y, h] = lap_pose(R, s);
    c = sign_camera(x, y, h, O, cfg);                     % what the HSV pipeline would report
    steer = steering(R, s, h, cfg.targetSpeed);           % heading error to the look-ahead point
    atten = min(1, max(0.3, cos(steer)^10));              % turnSpeedHandler
    vTurn = cfg.targetSpeed * atten;
    armed = t >= cfg.armTime;

    if strcmp(mode, 'base')
        if c.detected, elapsed = elapsed + dt; else, elapsed = 0; end   % stopSignDetectionSpeedAdjust timer
        vcmd = vTurn;
        if ~armed || (c.detected && elapsed < cfg.stopHold), vcmd = 0; end
        vr = vr + max(-ACC*dt, min(ACC*dt, vcmd - vr));   % limitAcceleration
        v = v + (vr - v) * dt / TAU_CAR;                  % car speed loop
        phase = 0; dGoal = SDROP - s;
        if ~armed, status = 0; elseif c.detected && elapsed < cfg.stopHold, status = 12; elseif atten < 0.9, status = 9; else, status = 13; end
        done = s >= SDROP;
    else
        confirmed = t >= tPick + opt.confirmAt;           % the rider's taps, at the chosen moments
        helpBtn = t >= tLeave + opt.helpAt && t < tLeave + opt.helpAt + 0.5;
        safeBtn = t >= tStop + opt.safeAt && t < tStop + opt.safeAt + 0.5;
        speedIn = vTurn * armed;
        [cmd, phase, dGoal, status] = taxi_controller(x, y, v, speedIn, c.detected, c.z, c.shape, t, dt, ...
            R.x, R.y, opt.feel, confirmed, helpBtn, safeBtn);
        v = v + (max(-ACC, min(ACC, (cmd - v) / TAU_CAR))) * dt;          % same car, same accel limit
        if ~armed, status = 0; end
        if phase == 2 && isinf(tPick), tPick = t; end     % reached the pickup
        if phase == 3 && isinf(tLeave), tLeave = t; end   % left the pickup
        if status == 17 && isinf(tStop), tStop = t; end   % pulled over after "Ask for help"
        if status == 11 || status == 9, tStop = Inf; end  % back on the road
        done = phase == 4;
    end
    v = max(v, 0);
    s = min(s + v * dt, R.L);
    t = t + dt;

    if t >= nextLog || done                               % keep a 20 Hz log for the rider screen
        k = k + 1; nextLog = nextLog + logEvery;
        ride.t(k) = t; ride.x(k) = x; ride.y(k) = y; ride.h(k) = h; ride.v(k) = v; ride.s(k) = s;
        ride.det(k) = c.detected; ride.z(k) = c.z; ride.area(k) = c.area; ride.shape(k) = c.shape;
        ride.facing(k) = c.facing; ride.signType{k} = c.type; ride.sx(k) = c.sx; ride.sy(k) = c.sy;
        ride.phase(k) = phase; ride.dGoal(k) = dGoal; ride.status(k) = status;
        ride.atten(k) = atten; ride.steer(k) = steer;
    end
end
acc = gradient(ride.v, ride.t);                          % comfort numbers for the summary
moving = ride.t > cfg.armTime;
ride.peakBraking = max(-acc(moving));
ride.lapTime = ride.t(end);
ride.fare = R.fare;
fprintf('%s (%s route, %s): %.1f s, peak braking %.2f m/s^2\n', mode, opt.route, cfg.feelName, ride.lapTime, ride.peakBraking);
end

function [x, y, h] = lap_pose(R, s)
x = interp1(R.s, R.x, s, 'linear', R.x(end));            % position along the route
y = interp1(R.s, R.y, s, 'linear', R.y(end));
h = interp1(R.s, R.h, s, 'linear', R.h(end));            % path heading
end

function e = steering(R, s, h, v)
ld = 0.5 * v + 0.3;                                       % pathPlanner look-ahead distance
[xa, ya] = lap_pose(R, s);
[xb, yb] = lap_pose(R, min(s + ld, R.L));
e = atan2(yb - ya, xb - xa) - h;
e = atan2(sin(e), cos(e));                                % wrap to [-pi, pi]
e = max(-0.6, min(0.6, e));                               % steeringSat
end
