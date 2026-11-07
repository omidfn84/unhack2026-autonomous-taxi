function rider_screen_tick(x, y, h, v, phase, dGoal, status, det, depth, shape, t)
% RIDER_SCREEN_TICK  Called by rider_screen_live during a QLabs run. Opens the screen on
% the first call and keeps it between calls.
persistent H
if isempty(H) || ~isvalid(H.fig) || t < H.lastT          % first call, closed, or a new run
    H = rider_screen_qlabs('ours');
end
types = {'', 'stop', 'yield', ''};
st = struct('t', t, 'x', x, 'y', y, 'h', h, 'v', v, 'phase', phase, 'dGoal', dGoal, ...
    'status', status, 'det', det > 0.5, 'z', depth, 'shape', shape, 's', NaN, 'area', 0, ...
    'sx', NaN, 'sy', NaN, 'signType', types{shape + 1});
H = rider_screen_update(H, st);
end
