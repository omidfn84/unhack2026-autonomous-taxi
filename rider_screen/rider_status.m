function code = rider_status(v, stopFlag, phase, dObs, dSign)
% RIDER_STATUS  Decide what the car is doing, as a number (Simulink-friendly).
% Inputs: v = speed (m/s), stopFlag = stop_logic output (1 = stopped at a goal),
%         phase = 1 heading to pickup / 2 heading to drop-off,
%         dObs = distance to obstacle (m), dSign = distance to stop line (m).
% Codes: 1 arrived, 2 picked up, 3 waiting for pedestrian, 4 slowing for pedestrian,
%        5 stopped at stop sign, 6 slowing for stop sign, 7 all clear, 8 on the way to pickup.

if isnan(dObs),  dObs  = inf; end   % NaN means nothing detected, so treat it as far away
if isnan(dSign), dSign = inf; end   % same for the stop line
stopped = v < 0.02;                 % below 2 cm/s counts as stopped

if stopFlag && phase == 2           % stopped at the drop-off point
    code = 1;
elseif stopFlag && phase == 1       % stopped at the pickup point
    code = 2;
elseif dObs < 0.5 && stopped        % someone close in front and the car is waiting
    code = 3;
elseif dObs < 1.0                   % someone ahead and the car is slowing
    code = 4;
elseif dSign < 0.3 && stopped       % stopped at a stop line
    code = 5;
elseif dSign < 0.8                  % stop line coming up
    code = 6;
elseif phase == 1                   % normal driving, rider not on board yet
    code = 8;
else                                % normal driving with the rider on board
    code = 7;
end
end
