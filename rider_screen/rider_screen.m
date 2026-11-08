function rider_screen(ride, speedup)
% RIDER_SCREEN  Play back a ride on the passenger screen.
% Usage: rider_screen(make_fake_run())        fake ride
%        rider_screen(load_real_run('run1.mat'), 1)   real ride at real speed
if nargin < 2, speedup = 2; end                % default: play 2x faster than real time

fig = uifigure('Name','Rider Screen','Position',[100 100 560 320], ...
    'Color',[0.08 0.09 0.12]);                 % dark window, like an in-car screen
lamp = uilamp(fig,'Position',[24 236 40 40]);  % coloured light: green / amber / blue
hdr = uilabel(fig,'Position',[80 236 460 40],'FontSize',16, ...
    'FontColor',[0.6 0.65 0.75],'Text','RideTune');            % small header
statusLbl = uilabel(fig,'Position',[24 120 512 110],'FontSize',26, ...
    'FontWeight','bold','FontColor','w','WordWrap','on');      % the main message
speedLbl = uilabel(fig,'Position',[24 60 250 40],'FontSize',18, ...
    'FontColor',[0.7 0.8 1]);                                  % current speed
goalLbl = uilabel(fig,'Position',[286 60 250 40],'FontSize',18, ...
    'FontColor',[0.7 0.8 1],'HorizontalAlignment','right');    % distance to goal

dt = median(diff(ride.t));                      % time between samples
for k = 1:numel(ride.t)                         % step through the ride
    if ~isvalid(fig), return; end              % stop if the window was closed
    code = rider_status(ride.v(k), ride.stopFlag(k), ride.phase(k), ...
                        ride.dObs(k), ride.dSign(k));          % what is the car doing?
    [msg, color] = status_text(code, ride.dObs(k), ride.dSign(k));  % words + colour
    statusLbl.Text = msg;                      % show the message
    lamp.Color = color;                        % update the light
    speedLbl.Text = sprintf('Speed: %.2f m/s', ride.v(k));     % show speed
    if ride.phase(k) == 1                       % label the goal by phase
        goalLbl.Text = sprintf('Pickup in %.1f m', ride.dGoal(k));
    else
        goalLbl.Text = sprintf('Drop-off in %.1f m', ride.dGoal(k));
    end
    drawnow limitrate;                         % redraw without slowing the loop
    pause(dt/speedup);                         % wait so playback matches (sped-up) time
end
end
