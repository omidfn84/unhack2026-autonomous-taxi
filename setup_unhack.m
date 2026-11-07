% SETUP_UNHACK  Run once: checks your MATLAB, sets the path, and tries everything.
here = fileparts(mfilename('fullpath'));                  % this folder
addpath(fullfile(here, 'calm_ride'));                     % Calm Ride controller files
addpath(fullfile(here, 'rider_screen'));                  % rider screen files
addpath(fullfile(here, 'taxi'));                          % taxi controller, sign shape check, lap simulation
addpath(genpath(fullfile(here, 'baseline')));             % Quanser baseline (for reading/testing)

rel = version('-release');                                % e.g. '2026a'
fprintf('\nMATLAB release: R%s\n', rel);
if str2double(rel(1:4)) < 2026                            % baseline .slx was saved in R2026a
    fprintf(['  NOTE: the baseline model was saved in R2026a. You can still build and test\n' ...
             '  here, but to open the baseline .slx you need R2026a or newer.\n']);
end

v = ver; have = string({v.Name});                         % installed products
need = ["Simulink", "Control System Toolbox"];            % needed for Calm Ride / baseline
nice = ["Computer Vision Toolbox", "Deep Learning Toolbox", "Image Processing Toolbox"];  % only for vision work
for p = need
    fprintf('  [%s] %s (needed)\n', ifelse(any(have == p)), p);
end
for p = nice
    fprintf('  [%s] %s (optional: vision on saved frames)\n', ifelse(any(have == p)), p);
end

fprintf('\n1) One lap on the QLabs map, rider screen...\n');
replay_ride(simulate_lap('ours'), 2);                     % our taxi, simulated from the model's logic

if any(have == "Simulink")
    fprintf('\n2) Building the Calm Ride test model...\n');
    build_calm_ride_test();                               % creates calm_ride_test.slx
    sim('calm_ride_test');                                % run it once
    open_system('calm_ride_test/Scope');                  % show speed, braking, jerk
else
    fprintf('\n2) Skipped Calm Ride test: install Simulink first.\n');
end

function s = ifelse(ok)                                   % tick or cross for the checklist
if ok, s = 'OK'; else, s = 'MISSING'; end
end
