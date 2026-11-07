function ride = load_qlabs_run(file)
% LOAD_QLABS_RUN  Turn a logged QLabs run into a ride for replay_ride.
% In the model, Mux these 10 signals (in this order) into a To Workspace block named
% riderLog (Save format: Structure With Time, sample time 0.05), run, then save('run1.mat','out'):
%   1 x, 2 y, 3 heading      <- currentPose
%   4 v                      <- measuredSpeed
%   5 phase, 6 dGoal, 7 status  <- taxi_controller outputs
%   8 det                    <- stopSignDetection
%   9 depth                  <- distanceToSign (add a Goto inside HSVStopSignDetection)
%   10 shape                 <- classify_red_sign output
S = load(file); L = S.out.riderLog;
d = squeeze(L.signals.values);
if size(d, 1) ~= numel(L.time), d = d.'; end              % rows = samples
ride.mode = 'ours';
ride.t = L.time(:)'; ride.x = d(:, 1)'; ride.y = d(:, 2)'; ride.h = d(:, 3)'; ride.v = d(:, 4)';
ride.phase = d(:, 5)'; ride.dGoal = d(:, 6)'; ride.status = d(:, 7)';
ride.det = d(:, 8)' > 0.5; ride.z = d(:, 9)'; ride.shape = d(:, 10)';
types = {'', 'stop', 'yield', ''};
ride.signType = types(ride.shape + 1);                    % name for the status text
end
