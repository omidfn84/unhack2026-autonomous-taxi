function [a, up, down, name] = ride_feel(level)
%#codegen
% RIDE_FEEL  The rider's turtle-to-rabbit setting -> Calm Ride limits (model car, m/s^2).
%   level 1 = Turtle (extra gentle) ... 3 = Normal ... 5 = Rabbit (quickest).
%   a    = planned braking rate on the way to a stop
%   up   = fastest the speed command may rise
%   down = fastest the speed command may fall (always more than a, so stops stay accurate)
A    = [0.08 0.11 0.15 0.22 0.30];                        % braking rate per level
UP   = [0.10 0.15 0.20 0.30 0.40];                        % speed-up limit per level
DOWN = [-0.20 -0.30 -0.40 -0.60 -0.80];                   % slow-down limit per level
k = min(max(round(level), 1), 5);                         % clamp to a valid level
a = A(k); up = UP(k); down = DOWN(k);
names = {'Turtle', 'Gentle', 'Normal', 'Brisk', 'Rabbit'};
name = names{k};                                          % label for the rider screen
end
