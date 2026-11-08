function fig = rider_controls(model)
% RIDER_CONTROLS  The rider's buttons for a live QLabs run (Windows).
%   rider_controls('your_model_name')   % open after pressing Run
% Needs four Constant blocks at the top level of the model, wired to taxi_controller:
%   RideTune_feel (1-5), RideTune_confirm, RideTune_help, RideTune_safe (0 or 1).
% Each control writes the block's value with set_param, so the car reacts while it drives.
if nargin < 1, model = bdroot; end
blk = @(name) [model '/' name];                           % full block path
put = @(name, val) set_param(blk(name), 'Value', num2str(val));   % change a Constant during the run
put('RideTune_feel', 3); put('RideTune_confirm', 0); put('RideTune_help', 0); put('RideTune_safe', 0);

fig = uifigure('Name', 'RideTune: rider controls', 'Position', [60 80 380 330]);
g = uigridlayout(fig, [6 1], 'RowHeight', {'fit', 'fit', 'fit', 'fit', 'fit', 'fit'}, 'Padding', [16 16 16 16]);
uilabel(g, 'Text', 'Ride feel: turtle (gentle) to rabbit (quick)', 'FontWeight', 'bold');
sl = uislider(g, 'Limits', [1 5], 'Value', 3, 'MajorTicks', 1:5, ...
    'MajorTickLabels', {'Turtle', 'Gentle', 'Normal', 'Brisk', 'Rabbit'});
sl.ValueChangedFcn = @(s, ~) setFeel(round(s.Value));     % snap to a level and send it
uibutton(g, 'Text', 'I''m in, I''m alone: lock my route', 'ButtonPushedFcn', @(~, ~) put('RideTune_confirm', 1));
uibutton(g, 'Text', 'Ask for help', 'ButtonPushedFcn', @(~, ~) press('RideTune_help', 'RideTune_safe'));
uibutton(g, 'Text', 'I''m safe', 'ButtonPushedFcn', @(~, ~) press('RideTune_safe', 'RideTune_help'));
uilabel(g, 'Text', 'The car never leaves the pickup before you confirm, and stays pulled over until you tap "I''m safe".', 'WordWrap', 'on');

    function setFeel(level)
        sl.Value = level;                                 % show the snapped level
        put('RideTune_feel', level);
    end
    function press(on, off)
        put(off, 0); put(on, 1);                          % the controller reacts to a 0 -> 1 change
    end
end
