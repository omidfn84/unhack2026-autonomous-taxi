function build_calm_ride_test()
% BUILD_CALM_RIDE_TEST  Builds calm_ride_test.slx: the Calm Ride subsystem plus a
% stand-in car, so Calm Ride can be tuned on a Mac without QLabs.
% When it looks right, copy the "Calm Ride" subsystem block into the real model.
mdl = 'calm_ride_test';                                   % model name
if bdIsLoaded(mdl), close_system(mdl, 0); end             % start fresh if already open
new_system(mdl); open_system(mdl);                        % create and show the model
here = fileparts(mfilename('fullpath'));                  % folder this script lives in

% ---- Calm Ride subsystem (this is the part that goes into the real model) ----
sub = [mdl '/Calm Ride'];
add_block('simulink/Commonly Used Blocks/Subsystem', sub, 'Position', [300 90 420 190]);
delete_line(sub, 'In1/1', 'Out1/1');                      % remove the default pass-through wire
set_param([sub '/In1'], 'Name', 'v_base');                % input 1: base speed
add_block('simulink/Sources/In1', [sub '/d_goal'], 'Position', [40 110 70 124]);    % input 2
add_block('simulink/Sources/In1', [sub '/stop_flag'], 'Position', [40 170 70 184]); % input 3
set_param([sub '/Out1'], 'Name', 'v_cmd');                % output: speed command
add_block('simulink/User-Defined Functions/MATLAB Function', [sub '/calm_speed'], ...
    'Position', [140 50 260 190]);                        % the braking-curve code
rt = sfroot;                                              % Stateflow root (holds MATLAB Function code)
chart = rt.find('-isa', 'Stateflow.EMChart', 'Path', [sub '/calm_speed']);
chart.Script = fileread(fullfile(here, 'calm_speed.m'));  % paste calm_speed.m into the block
add_block('simulink/Discontinuities/Rate Limiter', [sub '/Rate Limiter'], ...
    'RisingSlewLimit', '0.2', 'FallingSlewLimit', '-0.4', 'Position', [300 105 350 135]);
add_block('simulink/Continuous/Transfer Fcn', [sub '/Jerk filter'], ...
    'Numerator', '1', 'Denominator', '[0.15 1]', 'Position', [390 100 470 140]);
set_param([sub '/v_base'], 'Position', [40 50 70 64]);
set_param([sub '/v_cmd'], 'Position', [520 113 550 127]);
add_line(sub, 'v_base/1', 'calm_speed/1', 'autorouting', 'on');      % wire inputs in
add_line(sub, 'd_goal/1', 'calm_speed/2', 'autorouting', 'on');
add_line(sub, 'stop_flag/1', 'calm_speed/3', 'autorouting', 'on');
add_line(sub, 'calm_speed/1', 'Rate Limiter/1', 'autorouting', 'on'); % curve -> rate limit
add_line(sub, 'Rate Limiter/1', 'Jerk filter/1', 'autorouting', 'on'); % -> smoothing
add_line(sub, 'Jerk filter/1', 'v_cmd/1', 'autorouting', 'on');        % -> output

% ---- Stand-in car and test route (only for testing on the Mac) ----
add_block('simulink/Sources/Constant', [mdl '/Base speed'], 'Value', '0.4', ...
    'Position', [60 80 110 110]);                         % baseline cruise speed
add_block('simulink/Sources/Constant', [mdl '/Start distance'], 'Value', '1.2', ...
    'Position', [20 140 70 170]);                         % car starts 1.2 m from the goal
add_block('simulink/Math Operations/Sum', [mdl '/Distance left'], 'Inputs', '+-', ...
    'Position', [130 140 150 170]);                       % distance left = start - travelled
add_block('simulink/Sources/Constant', [mdl '/Stop radius'], 'Value', '0.1', ...
    'Position', [120 230 160 250]);                       % stop radius R (m)
add_block('simulink/Commonly Used Blocks/Relational Operator', [mdl '/At stop?'], ...
    'Operator', '<=', 'Position', [190 200 230 240]);     % inside the stop radius?
add_block('simulink/Continuous/Transfer Fcn', [mdl '/Car speed loop'], ...
    'Numerator', '1', 'Denominator', '[0.1 1]', 'Position', [470 125 550 155]); % car lags 0.1 s
add_block('simulink/Continuous/Integrator', [mdl '/Position'], ...
    'Position', [600 200 630 230]);                       % speed -> distance travelled
add_block('simulink/Continuous/Derivative', [mdl '/Braking'], ...
    'Position', [600 60 630 90]);                         % acceleration (negative = braking)
add_block('simulink/Continuous/Derivative', [mdl '/Jerk'], ...
    'Position', [660 60 690 90]);                         % how suddenly braking changes
add_block('simulink/Sinks/Scope', [mdl '/Scope'], 'NumInputPorts', '3', ...
    'Position', [740 100 780 180]);                       % speed, braking, jerk
add_line(mdl, 'Base speed/1', 'Calm Ride/1', 'autorouting', 'on');
add_line(mdl, 'Start distance/1', 'Distance left/1', 'autorouting', 'on');
add_line(mdl, 'Position/1', 'Distance left/2', 'autorouting', 'on');
add_line(mdl, 'Distance left/1', 'Calm Ride/2', 'autorouting', 'on');
add_line(mdl, 'Distance left/1', 'At stop?/1', 'autorouting', 'on');
add_line(mdl, 'Stop radius/1', 'At stop?/2', 'autorouting', 'on');
add_line(mdl, 'At stop?/1', 'Calm Ride/3', 'autorouting', 'on');
add_line(mdl, 'Calm Ride/1', 'Car speed loop/1', 'autorouting', 'on');
add_line(mdl, 'Car speed loop/1', 'Position/1', 'autorouting', 'on');
add_line(mdl, 'Car speed loop/1', 'Scope/1', 'autorouting', 'on');
add_line(mdl, 'Car speed loop/1', 'Braking/1', 'autorouting', 'on');
add_line(mdl, 'Braking/1', 'Scope/2', 'autorouting', 'on');
add_line(mdl, 'Braking/1', 'Jerk/1', 'autorouting', 'on');
add_line(mdl, 'Jerk/1', 'Scope/3', 'autorouting', 'on');

set_param(mdl, 'StopTime', '8', 'SolverType', 'Fixed-step', 'Solver', 'ode4', 'FixedStep', '0.002');  % 8 s fixed-step run
save_system(mdl, fullfile(here, [mdl '.slx']));           % save next to this script
disp('Built calm_ride_test.slx. Press Run, then open the Scope.');
end
