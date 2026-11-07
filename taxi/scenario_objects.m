function O = scenario_objects()
% SCENARIO_OBJECTS  Signs, stop lines, crosswalks and traffic lights exactly as
% Setup_Real_Scenario.m spawns them. Used only for drawing and for the Mac
% simulation; the car itself finds signs with the camera.

O.signs = struct( ...
  'type', {'stop','stop','stop','stop','yield','yield','yield','yield','roundabout','roundabout','roundabout'}, ...
  'x',    {-1.5, -1.5, 2.410, 1.766, 0.0, 2.4, 1.1, 0.49, 2.392, 0.698, 0.007}, ...
  'y',    {3.6, 2.2, 0.206, 1.697, -1.3, 3.2, 2.8, 3.8, 2.522, 2.483, 3.973}, ...
  'yaw',  {-35, 35, -90, 90, -180, -90, -145, 135, -90, -145, 135});        % degrees

O.stoplines = [2.21 0.2 0 0.27; 1.951 1.68 0 0.27; -0.05 -1.02 90 0.38];    % [x y yaw(deg) length]
O.crosswalks = [-1.87 0.195 0; -0.5 0.95 90; 0.15 0.32 0; 0.75 0.95 90; 0.13 1.57 0; 1.45 0.95 90];  % [x y yaw]
O.lights = [1 0.6 1.55 0; 2 -0.6 1.28 90; 3 -0.37 0.3 180; 4 0.75 0.48 -90];  % [id x y yaw]
end
