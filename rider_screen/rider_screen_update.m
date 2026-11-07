function H = rider_screen_update(H, st)
% RIDER_SCREEN_UPDATE  Draw one frame. st fields: t, x, y, h (rad), v (m/s), phase, dGoal,
% status, det, z (sign depth), area (px, optional), shape, signType, sx, sy (optional).
if ~isvalid(H.fig), return; end
R = H.R; cfg = H.cfg;

% where we are along the lap
if isfield(st, 's') && ~isnan(st.s)
    s = st.s;
else
    [~, k] = min(hypot(R.x - st.x, R.y - st.y)); s = R.s(k);          % real run: nearest lap point
end
if strcmp(H.mode, 'base'), goal = R.L - 0.03; elseif st.phase <= 1, goal = R.sPick; else, goal = R.sDrop; end

% map: driven part, route ahead, car, camera cone, detected sign
i1 = find(R.s <= s, 1, 'last'); if isempty(i1), i1 = 1; end          % lap index of the car
i2 = find(R.s <= goal, 1, 'last'); if isempty(i2), i2 = 1; end       % lap index of the next stop
[dx, dy] = H.toPx(R.x(1:i1), R.y(1:i1)); set(H.done, 'XData', dx, 'YData', dy);
if i2 > i1, [ax_, ay_] = H.toPx(R.x(i1:i2), R.y(i1:i2)); else, ax_ = NaN; ay_ = NaN; end
set(H.ahead, 'XData', ax_, 'YData', ay_);
hd = [cos(st.h), sin(st.h)]; lf = [-hd(2), hd(1)];
corners = [0.2 0.095; 0.2 -0.095; -0.2 -0.095; -0.2 0.095];             % 0.4 x 0.19 m footprint
cx = st.x + corners(:, 1) * hd(1) + corners(:, 2) * lf(1);
cy = st.y + corners(:, 1) * hd(2) + corners(:, 2) * lf(2);
[px, py] = H.toPx(cx, cy); set(H.car, 'XData', px, 'YData', py);
a = linspace(-cfg.cam.hfov/2, cfg.cam.hfov/2, 24);                      % camera fan out to 1.2 m
camx = st.x + cfg.cam.ahead * hd(1); camy = st.y + cfg.cam.ahead * hd(2);
fx = [camx, camx + cfg.maxDepth * (cosd(a) * hd(1) + sind(a) * lf(1))];
fy = [camy, camy + cfg.maxDepth * (cosd(a) * hd(2) + sind(a) * lf(2))];
[fpx, fpy] = H.toPx(fx, fy); set(H.cone, 'XData', fpx, 'YData', fpy);
if st.det && isfield(st, 'sx') && ~isnan(st.sx)
    [rx, ry] = H.toPx(st.sx, st.sy); set(H.ring, 'XData', rx, 'YData', ry);
else
    set(H.ring, 'XData', NaN, 'YData', NaN);
end

% rider text
[msg, sub, color] = status_message(st);
H.status.Text = msg; H.sub.Text = sub; H.lamp.Color = color;
[n1, n2, n3] = next_instruction(R, s, st.phase, H.mode);
H.next.Text = n1; H.dist.Text = n2; H.then.Text = n3;
kmh = round(st.v * 10 * 3.6);                                           % real-world km/h (1:10 scale)
H.trip.Text = sprintf('To go %d m   ·   Speed %d km/h', round(max(R.sDrop - s, 0) * 10), kmh);

% what the camera sees (HSV numbers from the model's pipeline)
names = {'unknown', 'STOP (octagon)', 'YIELD (triangle)', 'turned away'};
if st.det
    seen = sprintf('Red sign: depth %.2f m (limit %.1f m)', st.z, cfg.maxDepth);
    if isfield(st, 'area') && st.area > 0, seen = sprintf('%s · blob %d px', seen, round(st.area)); end
    if strcmp(H.mode, 'ours'), seen = [seen ' → ' names{st.shape + 1}]; end
else
    seen = 'No red sign within 1.2 m.';
end
H.sees.Text = ['What the car sees: ' seen];

% comfort: peak braking so far
if st.t > H.lastT
    acc = (st.v - H.lastV) / (st.t - H.lastT);
    if st.t > cfg.armTime, H.peak = max(H.peak, -acc); end
end
H.lastV = st.v; H.lastT = st.t;
H.comfort.Text = sprintf('t = %.1f s   ·   peak braking %.2f m/s^2', st.t, H.peak);
drawnow limitrate
end
