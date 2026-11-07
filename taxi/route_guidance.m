function R = route_guidance(cfg)
% ROUTE_GUIDANCE  Turn the path-4 points into a lap the rider screen can describe.
% Returns the lap re-ordered to start at the taxi hub, its arc length, the turns,
% and where the pickup and drop-off sit along the lap.

x = cfg.path_x; y = cfg.path_y;                           % path 4 points
keep = [true; hypot(diff(x), diff(y)) > 1e-6];            % drop repeated points (start = end)
x = x(keep); y = y(keep);
[~, i0] = min(hypot(x - cfg.hub(1), y - cfg.hub(2)));     % path point nearest the hub spawn
x = [x(i0:end); x(1:i0-1)];                               % rotate so the lap starts at the hub
y = [y(i0:end); y(1:i0-1)];
ds = hypot(diff([x; x(1)]), diff([y; y(1)]));             % segment lengths, closing the loop
R.x = x; R.y = y;
R.s = [0; cumsum(ds(1:end-1))];                           % arc length at each point (m)
R.L = sum(ds);                                            % lap length (about 17.6 m)
R.h = unwrap(atan2(gradient(y), gradient(x)));            % heading along the lap (rad)

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

R.sPick = lap_position(R, cfg.pickup);                    % pickup distance along the lap
R.sDrop = lap_position(R, cfg.dropoff);                   % drop-off distance along the lap
if R.sDrop < R.sPick, R.sDrop = R.L - 0.03; end           % hub drop-off = end of the lap
end

function s = lap_position(R, xy)
[~, k] = min(hypot(R.x - xy(1), R.y - xy(2)));            % nearest lap point
s = R.s(k);
end
