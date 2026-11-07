% RUN_LAP_DEMO  Mac-friendly demo: simulate one lap and play it on the rider screen.
% Uses the provided model's speed logic and Setup_Real_Scenario.m signs (see simulate_lap.m).
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, 'taxi'), fullfile(here, 'rider_screen'), fullfile(here, 'calm_ride'));  % our code
addpath(genpath(fullfile(here, 'baseline')));                          % SDCS_Paths_7.mat lives here

base = simulate_lap('base');        % provided stack: stops 2 s for every red sign, no pickup
ours = simulate_lap('ours');        % our taxi: pickup, Calm Ride, stop at the line, shape check
replay_ride(ours, 2);               % watch our lap at 2x speed (close the window to stop)
% replay_ride(base, 2);             % uncomment to watch the provided stack
