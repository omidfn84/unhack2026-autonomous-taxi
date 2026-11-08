function R = route_guidance(cfg)
% ROUTE_GUIDANCE  Build the rider's route from the provided lane paths and describe it.
% Every route starts at the taxi hub, follows path 4 to the pickup, then takes the route
% the rider picked back to the hub:
%   'cheapest' = path 4 (outer lap, no downtown fee)
%   'fastest'  = path 2 (through the centre, crosses the traffic-light intersection)
%   'scenic'   = path 7 (the long loop)
% Returns points (x, y), arc length s, heading h, turns, pickup / drop-off positions,
% the traffic lights that face the route, and an example fare.

P = load('SDCS_Paths_7.mat');                             % all the provided lane paths
[bx, by] = clean_path(P.path_x4, P.path_y4);              % path 4 = the stack's outer lap
[~, i0] = min(hypot(bx - cfg.hub(1), by - cfg.hub(2)));   % path point nearest the hub spawn
bx = [bx(i0:end); bx(1:i0-1)]; by = [by(i0:end); by(1:i0-1)];   % lap starts at the hub
[~, kp] = min(hypot(bx - cfg.pickup(1), by - cfg.pickup(2)));   % pickup along the lap

switch cfg.route                                          % which path after the pickup
    case 'fastest', pathNo = 2;
    case 'scenic',  pathNo = 7;
    otherwise,      pathNo = 4;
end
[qx, qy] = clean_path(P.(sprintf('path_x%d', pathNo)), P.(sprintf('path_y%d', pathNo)));
[~, ip] = min(hypot(qx - cfg.pickup(1), qy - cfg.pickup(2)));    % pickup on that path
[~, ih] = min(hypot(qx - cfg.dropoff(1), qy - cfg.dropoff(2)));  % drop-off on that path
if ih < ip                                                % the path is a loop: wrap past its end
    tx = [qx(ip:end); qx(1:ih)]; ty = [qy(ip:end); qy(1:ih)];
else
    tx = qx(ip:ih); ty = qy(ip:ih);
end
x = [bx(1:kp); tx(2:end)]; y = [by(1:kp); ty(2:end)];     % hub -> pickup -> drop-off
[x, y] = clean_path(x, y);                                % no repeated points

ds = hypot(diff(x), diff(y));
R.route = cfg.route; R.x = x; R.y = y;
R.s = [0; cumsum(ds)];                                    % arc length at each point (m)
R.L = R.s(end);                                           % route length
R.h = unwrap(atan2(gradient(y), gradient(x)));            % heading along the route (rad)
R.sPick = R.s(kp);                                        % pickup = end of the shared approach
R.sDrop = R.L - 0.03;                                     % drop-off = end of the route

% turns: heading changes by more than 25 deg over 0.5 m of path
n = numel(x); win = round(0.5 / median(ds)); i = 1;
R.turns = struct('start', {}, 'mid', {}, 'deg', {});
while i <= n - win
    if abs(R.h(i + win) - R.h(i)) > deg2rad(25)
        j = i;
        while j <= n - win && abs(R.h(j + win) - R.h(j)) > deg2rad(12)
            j = j + 1;                                    % extend while still turning
        end
        e = min(j + win, n);
        R.turns(end + 1) = struct('start', R.s(i), 'mid', (R.s(i) + R.s(e)) / 2, ...
                                  'deg', rad2deg(R.h(e) - R.h(i)));   % + = left, - = right
        i = e;
    else
        i = i + 1;
    end
end

% traffic lights that face this route after the pickup: stop 0.35 m before the light
O = scenario_objects();
R.lights = zeros(0, 2);                                   % rows: [light id, stop position s]
for k = 1:size(O.lights, 1)
    lt = O.lights(k, :);
    nrm = [cosd(lt(4)), sind(lt(4))];                     % direction the light faces
    hx = cos(R.h); hy = sin(R.h);                         % car heading at each point
    vx = lt(2) - x; vy = lt(3) - y;                       % car -> light
    along = vx .* hx + vy .* hy;                          % light distance ahead
    side = abs(-vx .* hy + vy .* hx);                     % light distance to the side
    faces = -(hx * nrm(1) + hy * nrm(2)) > 0.8;           % light points back at the car
    ok = find(faces & along > 0.2 & along < 0.6 & side < 0.6 & R.s > R.sPick);
    if ~isempty(ok)
        [~, b] = min(abs(along(ok) - 0.35));
        R.lights(end + 1, :) = [lt(1), R.s(ok(b))];
    end
end

% example fare a car company might set: $3 + $2 per 100 m (real size) + $3 downtown fee
after = R.L - R.sPick;                                    % metres after the pickup (model)
downtown = any(hypot(x(kp:end) - 0.2, y(kp:end) - 1.0) < 0.35);   % passes the centre
R.fare = 3 + 2 * round(after * 10) / 100 + 3 * downtown;
end

function [x, y] = clean_path(x, y)
x = x(:); y = y(:);
keep = [true; hypot(diff(x), diff(y)) > 1e-6];            % drop repeated points
x = x(keep); y = y(keep);
end
