function H = rider_screen_qlabs(mode, route, feel)
% RIDER_SCREEN_QLABS  Build the rider screen: QLabs map on the left, rider info on the right.
%   H = rider_screen_qlabs('ours', 'fastest', 3)   then call rider_screen_update(H, st) for every frame.
%   route: 'cheapest' | 'fastest' | 'scenic' (default: the last one picked with apply_route)
%   feel:  1 Turtle .. 5 Rabbit (default 3, Normal)
if nargin < 1, mode = 'ours'; end
if nargin < 2, route = []; end
if nargin < 3, feel = 3; end
if strcmp(mode, 'base'), route = 'cheapest'; end              % the original car drives the outer lap
cfg = taxi_config(route, feel); R = route_guidance(cfg); O = scenario_objects();
here = fileparts(mfilename('fullpath'));
img = imread(fullfile(here, 'map_bg.png'));                     % QLabs top view (kickoff deck), car removed
AF = [-1e-05, -143.09531, -142.72886, -0.00041, 701.27313, 413.53501];   % world (m) -> map pixels, fitted to the lane paths
toPx = @(x, y) deal(AF(1)*x + AF(2)*y + AF(5), AF(3)*x + AF(4)*y + AF(6));
kpx = 142.9;                                                    % map pixels per metre

BG = [0.04 0.07 0.13]; PANEL = [0.09 0.13 0.23]; INK = [0.91 0.93 0.97]; MUTED = [0.55 0.61 0.72]; ACCENT = [0.37 0.77 0.96];
fig = uifigure('Name', 'RideTune rider screen', 'Position', [40 60 1360 720], 'Color', BG);
gl = uigridlayout(fig, [1 2], 'ColumnWidth', {'1.25x', '1x'}, 'BackgroundColor', BG, 'Padding', [12 12 12 12]);

% ---------- map ----------
ax = uiaxes(gl); ax.Color = BG; disableDefaultInteractivity(ax);
image(ax, img); axis(ax, 'image'); axis(ax, 'off'); hold(ax, 'on');
[lx, ly] = toPx(R.x, R.y);
plot(ax, lx, ly, '-', 'Color', [0.62 0.80 0.95], 'LineWidth', 2);                 % whole lap (path 4)
H.done  = plot(ax, NaN, NaN, '-', 'Color', [0.47 0.51 0.59], 'LineWidth', 3);     % driven part
H.ahead = plot(ax, NaN, NaN, '-', 'Color', [0.11 0.61 0.94], 'LineWidth', 4.5);  % route to the next stop
for k = 1:size(O.stoplines, 1)                                                     % stop lines
    sl = O.stoplines(k, :); d = sl(4) / 2 * [cosd(sl(3)), sind(sl(3))];
    [ax1, ay1] = toPx(sl(1) - d(1), sl(2) - d(2)); [ax2, ay2] = toPx(sl(1) + d(1), sl(2) + d(2));
    plot(ax, [ax1 ax2], [ay1 ay2], 'w-', 'LineWidth', 3);
end
for k = 1:numel(O.signs)                                                           % signs
    s = O.signs(k); [sx, sy] = toPx(s.x, s.y);
    switch s.type
        case 'stop',  plot(ax, sx, sy, 'o', 'MarkerSize', 11, 'MarkerFaceColor', [0.84 0.16 0.16], 'MarkerEdgeColor', 'w', 'LineWidth', 1.5);
        case 'yield', plot(ax, sx, sy, 'v', 'MarkerSize', 11, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', [0.84 0.16 0.16], 'LineWidth', 2.5);
        otherwise,    plot(ax, sx, sy, 'o', 'MarkerSize', 10, 'MarkerFaceColor', [0.12 0.44 0.92], 'MarkerEdgeColor', 'w', 'LineWidth', 1.5);
    end
end
H.lightDots = gobjects(size(O.lights, 1), 1);                                    % traffic lights, coloured live
for k = 1:size(O.lights, 1)
    [qx, qy] = toPx(O.lights(k, 2), O.lights(k, 3));
    H.lightDots(k) = plot(ax, qx, qy, 's', 'MarkerSize', 12, 'MarkerFaceColor', [0.18 0.66 0.42], 'MarkerEdgeColor', [0.16 0.18 0.22], 'LineWidth', 2);
end
H.ring = plot(ax, NaN, NaN, 'o', 'MarkerSize', 26, 'Color', [1 0.71 0.28], 'LineWidth', 2.5);   % detected sign
if strcmp(mode, 'ours')
    [px, py] = toPx(interp1(R.s, R.x, R.sPick), interp1(R.s, R.y, R.sPick));
    plot(ax, px, py, 'o', 'MarkerSize', 12, 'MarkerFaceColor', [0.55 0.36 0.96], 'MarkerEdgeColor', 'w', 'LineWidth', 2);
    text(ax, px + 14, py, 'Pickup', 'Color', [0.55 0.36 0.96], 'FontWeight', 'bold', 'BackgroundColor', 'w', 'Margin', 1);
end
[dx, dy] = toPx(interp1(R.s, R.x, R.sDrop), interp1(R.s, R.y, R.sDrop));
plot(ax, dx, dy, 'o', 'MarkerSize', 12, 'MarkerFaceColor', [0.06 0.73 0.51], 'MarkerEdgeColor', 'w', 'LineWidth', 2);
text(ax, dx + 14, dy, 'Drop-off', 'Color', [0.06 0.73 0.51], 'FontWeight', 'bold', 'BackgroundColor', 'w', 'Margin', 1);
H.cone = patch(ax, NaN, NaN, [0.11 0.61 0.94], 'FaceAlpha', 0.18, 'EdgeColor', [0.11 0.61 0.94], 'LineStyle', '--');  % camera view, 1.2 m
H.car  = patch(ax, NaN, NaN, [0.95 0.96 0.97], 'EdgeColor', [0.11 0.61 0.94], 'LineWidth', 2);                        % the taxi

% ---------- rider panel ----------
side = uigridlayout(gl, [8 1], 'RowHeight', {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', '1x'}, ...
    'BackgroundColor', PANEL, 'Padding', [18 16 18 16], 'RowSpacing', 10);
top = uigridlayout(side, [1 2], 'ColumnWidth', {22, '1x'}, 'BackgroundColor', PANEL, 'Padding', [0 0 0 0]);
H.lamp = uilamp(top, 'Color', [0.26 0.83 0.62]);
H.status = uilabel(top, 'Text', '', 'FontSize', 24, 'FontWeight', 'bold', 'FontColor', INK, 'WordWrap', 'on');
H.sub    = uilabel(side, 'Text', '', 'FontSize', 15, 'FontColor', MUTED, 'WordWrap', 'on');
H.next   = uilabel(side, 'Text', '', 'FontSize', 20, 'FontWeight', 'bold', 'FontColor', INK);
H.dist   = uilabel(side, 'Text', '', 'FontSize', 26, 'FontWeight', 'bold', 'FontColor', ACCENT);
H.then   = uilabel(side, 'Text', '', 'FontSize', 14, 'FontColor', MUTED);
H.trip   = uilabel(side, 'Text', '', 'FontSize', 15, 'FontColor', INK);
H.sees   = uilabel(side, 'Text', '', 'FontSize', 14, 'FontColor', INK, 'WordWrap', 'on');
H.comfort = uilabel(side, 'Text', '', 'FontSize', 14, 'FontColor', MUTED, 'WordWrap', 'on', 'VerticalAlignment', 'top');
H.lights = O.lights;                                                               % for the live light colours

H.fig = fig; H.ax = ax; H.R = R; H.cfg = cfg; H.toPx = toPx; H.kpx = kpx; H.mode = mode; H.peak = 0; H.lastV = 0; H.lastT = 0;
end
