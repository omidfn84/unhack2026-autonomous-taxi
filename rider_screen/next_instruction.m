function [mainText, distText, thenText] = next_instruction(R, s, phase, mode)
% NEXT_INSTRUCTION  "Turn left in 40 m, then drop-off in 120 m" from the lap geometry.
% R from route_guidance, s = distance along the lap (m), phase from taxi_controller.
m = @(d) sprintf('%d m', round(max(d, 0) * 10));         % real-world metres (QCar is 1:10)
if strcmp(mode, 'base')
    goal = R.L - 0.03; goalName = 'end of lap';
elseif phase <= 1
    goal = R.sPick; goalName = 'pickup';
else
    goal = R.sDrop; goalName = 'drop-off';
end
if strcmp(mode, 'ours') && phase == 4, mainText = 'Ride complete'; distText = ''; thenText = ''; return; end
if strcmp(mode, 'ours') && phase == 2, mainText = 'Picking you up'; distText = ''; thenText = ['Then drop-off in ' m(R.sDrop - s)]; return; end

starts = [R.turns.start];
k = find(starts > s + 0.02 & starts < goal, 1);           % next turn before the goal
if ~isempty(k)
    deg = R.turns(k).deg;
    if abs(deg) > 60, verb = 'Turn'; else, verb = 'Bear'; end
    if deg > 0, side = 'left'; else, side = 'right'; end
    mainText = [verb ' ' side];
    distText = ['in ' m(starts(k) - s)];
    thenText = ['Then ' goalName ' in ' m(goal - s)];
else
    mainText = [upper(goalName(1)) goalName(2:end) ' ahead'];
    distText = ['in ' m(goal - s)];
    thenText = '';
end
end
