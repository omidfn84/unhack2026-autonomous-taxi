function ride = load_real_run(file)
% LOAD_REAL_RUN  Read a logged QLabs ride into the format rider_screen expects.
% The Windows teammate muxes [speed, stopFlag, phase, dObs, dSign, dGoal] into one
% To Workspace block named riderLog (Structure With Time, sample time 0.1), runs the
% model, then saves:  save('run1.mat','out')
S = load(file);                           % load the saved simulation output
L = S.out.riderLog;                       % the To Workspace block's data
d = squeeze(L.signals.values);            % one row per sample, one column per signal
if size(d,1) ~= numel(L.time), d = d'; end  % make sure rows line up with time
ride.t = L.time(:);                        % time (s)
ride.v = d(:,1);                           % speed (m/s)
ride.stopFlag = d(:,2);                    % stop_logic output
ride.phase = d(:,3);                       % 1 pickup, 2 drop-off
ride.dObs = d(:,4);                        % distance to obstacle (m)
ride.dSign = d(:,5);                       % distance to stop line (m)
ride.dGoal = d(:,6);                       % distance to current goal (m)
end
