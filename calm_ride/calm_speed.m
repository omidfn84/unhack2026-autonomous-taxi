function v_cmd = calm_speed(v_base, d_goal, stop_flag)
% CALM_SPEED  Calm Ride speed command (constant-deceleration braking curve).
a_comf = 0.15;   % braking rate: gentlest setting that still stops accurately (m/s^2)
d_stop = 0.1;    % stop point; match stop_logic's radius R
lead   = 0.02;   % start braking 2 cm early to absorb the filter's lag
v_min  = 0.03;   % creep speed so the car never stalls short of the stop
if stop_flag                                 % stop_logic says we're in the stop/dwell state
    v_cmd = 0;                               % stay fully stopped
else
    d = max(0, d_goal - d_stop - lead);      % distance left before we need to be stopped
    v_brake = sqrt(2*a_comf*d);              % max speed that still stops in d at a_comf
    v_cmd = max(v_min, min(v_base, v_brake));  % cruise, then follow the curve, never below creep
end
end
