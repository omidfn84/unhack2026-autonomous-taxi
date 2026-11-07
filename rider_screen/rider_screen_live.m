function rider_screen_live(x, y, h, v, phase, dGoal, status, det, depth, shape, t)
%#codegen
% RIDER_SCREEN_LIVE  Paste into a MATLAB Function block to update the rider screen
% while the QLabs run is going (Normal simulation mode). Updates at 5 Hz.
coder.extrinsic('rider_screen_tick');            % runs in MATLAB, outside generated code
persistent lastT
if isempty(lastT), lastT = -1; end
if t - lastT >= 0.2
    lastT = t;
    rider_screen_tick(x, y, h, v, phase, dGoal, status, det, depth, shape, t);
end
end
