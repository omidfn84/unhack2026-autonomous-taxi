function red = traffic_light_state(id, t, offset)
%#codegen
% TRAFFIC_LIGHT_STATE  Is light `id` red or yellow at time t (s)?
% The scenario runs every light on a fixed 20 s cycle, 5 s per state:
%   lights 1 and 3: red, red, green, yellow     lights 2 and 4: green, yellow, red, red
% offset (s) shifts the cycle to line up with your QLabs run (0 if unknown).
% On a real car this would come from the car's own traffic-light detection.
if nargin < 3, offset = 0; end
st = mod(floor((t + offset) / 5), 4);                     % 0..3: which 5 s state we are in
if id == 1 || id == 3
    red = st ~= 2;                                        % green only in state 2
else
    red = st ~= 0;                                        % green only in state 0
end
end
