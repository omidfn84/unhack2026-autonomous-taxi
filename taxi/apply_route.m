function R = apply_route(route)
% APPLY_ROUTE  Make the Simulink model drive the rider's route.
% Run after Virtual_Setup_Competition_Map.m and before pressing Run:
%   apply_route('fastest')     % or 'scenic' / 'cheapest'
% The model's pathPlanner reads path_x4 / path_y4 from the base workspace, so we
% swap in the hub -> pickup -> drop-off route built from the provided paths.
% The original lap comes back when you rerun the setup script.
if nargin < 1, route = 'cheapest'; end
setappdata(0, 'RideTuneRoute', route);                    % taxi_config() and the rider screen use it from now on
cfg = taxi_config(route);
R = route_guidance(cfg);
assignin('base', 'path_x4', R.x);                         % what pathPlanner follows
assignin('base', 'path_y4', R.y);
fprintf('Route "%s": %.1f m after pickup (%d m real size), %d traffic light(s), example fare $%.2f\n', ...
    route, R.L - R.sPick, round((R.L - R.sPick) * 10), size(R.lights, 1), R.fare);
end
