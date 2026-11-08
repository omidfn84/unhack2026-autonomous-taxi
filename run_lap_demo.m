% RUN_LAP_DEMO  Mac-friendly demo: simulate a ride and play it on the rider screen.
% Uses the provided model's speed logic and Setup_Real_Scenario.m signs (see simulate_lap.m).
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, 'taxi'), fullfile(here, 'rider_screen'), fullfile(here, 'calm_ride'));  % RideTune code
addpath(genpath(fullfile(here, 'baseline')));                          % SDCS_Paths_7.mat lives here

base = simulate_lap('base');        % provided stack: stops 2 s for every red sign, no pickup
ours = simulate_lap('ours', 'route', 'fastest', 'feel', 1);   % fastest route, turtle ride feel
replay_ride(ours, 2);               % watch it at 2x speed (close the window to stop)

% Try the other choices:
% replay_ride(simulate_lap('ours', 'route', 'scenic', 'feel', 5), 2);        % scenic, rabbit
% replay_ride(simulate_lap('ours', 'helpAt', 5, 'safeAt', 20), 2);           % "Ask for help", then "I'm safe" after 20 s
% replay_ride(simulate_lap('ours', 'helpAt', 5), 4);                         % no reply: calls the contact twice, then 911
% replay_ride(base, 2);                                                      % the provided stack
