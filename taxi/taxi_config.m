function cfg = taxi_config()
% TAXI_CONFIG  One place for every number our taxi uses.
% Values marked MODEL come from the provided Simulink model / setup scripts.
% Values marked MEASURE must be replaced with QLabs Coordinate Helper readings.

% ---- route (MODEL: pathPlanner uses path 4, the outer lap) ----
P = load('SDCS_Paths_7.mat', 'path_x4', 'path_y4');      % lane path the stack follows
cfg.path_x = P.path_x4(:);                                % x of every path point (m)
cfg.path_y = P.path_y4(:);                                % y of every path point (m)
cfg.hub = [-1.205, -0.83, -44.7];                         % MODEL: taxi hub spawn [x y heading(deg)]

% ---- pickup / drop-off (MEASURE: read these off the Coordinate Helper) ----
cfg.pickup  = [1.25, -1.09];                              % estimated from the team's annotated screenshot
cfg.dropoff = cfg.hub(1:2);                               % placeholder: back at the taxi hub
cfg.dwell   = 5;                                          % seconds the rider has to get in / out

% ---- speed logic (MODEL) ----
cfg.targetSpeed = 0.5;                                    % root Constant 'targetSpeed' (m/s)
cfg.stopHold    = 2;                                      % stopSignDetectionSpeedAdjust: 2 s stop
cfg.armTime     = 6;                                      % Initialization_Time (5 s) + 1 s before steering starts

% ---- HSV stop-sign detection (MODEL: HSVStopSignDetection) ----
cfg.hueTol   = 20;                                        % red hue 0 +/- 20 degrees
cfg.satMin   = 100;  cfg.valMin = 100;                    % saturation / value lower limits (0-255)
cfg.minBlob  = 100;                                       % largest red blob must be >= 100 px
cfg.maxDepth = 1.2;                                       % detection when depth at blob centre <= 1.2 m

% ---- our sign shape check (CALIBRATE with calibrate_sign_shapes.m) ----
cfg.stopFillMin  = 0.55;                                  % octagon fills more of its bounding box ...
cfg.yieldFillMax = 0.50;                                  % ... than a triangle (ring) does
cfg.minAspect    = 0.60;                                  % width/height below this = sign faces another road
cfg.yieldSpeed   = 0.25;                                  % m/s while passing a yield sign

% ---- Calm Ride (our calm_speed.m numbers) ----
cfg.calm.a    = 0.15;                                     % braking rate (m/s^2)
cfg.calm.lead = 0.02;                                     % start braking 2 cm early
cfg.calm.vmin = 0.03;                                     % creep speed so the car never stalls short
cfg.calm.up   = 0.2;                                      % max speed-up rate (m/s^2)
cfg.calm.down = -0.4;                                     % max slow-down rate (m/s^2)
cfg.calm.tauF = 0.15;                                     % jerk filter time constant (s)

% ---- camera geometry (MODEL constants + one ASSUMPTION) ----
cfg.cam.w = 640; cfg.cam.h = 480;                         % RealSense RGB size used by the model
cfg.cam.hfov = 69.4; cfg.cam.vfov = 42.5;                 % MODEL: field-of-view gains in findStopSignDistance
cfg.cam.ahead = 0.2;                                      % ASSUMPTION: camera 0.2 m ahead of the pose
end
