function [msg, sub, color] = status_message(st)
% STATUS_MESSAGE  Plain-language status for the rider, from the controller's status code.
% st needs: status, t, dGoal, z (sign depth), signType, holdLeft (optional), dwellLeft (optional).
OK = [0.26 0.83 0.62]; WARN = [1.00 0.71 0.28]; INFO = [0.64 0.66 1.00];
m = @(d) sprintf('%d m', round(max(d, 0) * 10));          % real-world metres (QCar is 1:10)
switch st.status
    case 0,  msg = 'Getting ready.';                         sub = 'Finding our position on the map.';                 color = INFO;
    case 1,  msg = 'You''ve arrived. Take your time getting out.'; sub = 'Thanks for riding with Calm Ride.';          color = OK;
    case 2,  msg = 'Welcome aboard! We''ll leave once you''re settled.'; sub = 'Please buckle up.';                     color = INFO;
    case 3,  msg = 'Stopped at the stop sign.';              sub = 'Full stop at the line, then we go.';               color = WARN;
    case 4,  msg = 'Stop sign ahead. Slowing down gently.';  sub = ['Stopping at the line in ' m(st.dGoal) '.'];       color = WARN;
    case 5,  msg = 'Yield sign. Slowing down, no need to stop.'; sub = sprintf('Triangle seen %.2f m ahead.', st.z);   color = INFO;
    case 6,  msg = 'Sign for another road. Continuing.';     sub = 'It faces away from our lane, so we don''t stop.';  color = OK;
    case 7,  msg = 'Arriving at your pickup spot.';          sub = ['Stopping at the curb in ' m(st.dGoal) '.'];       color = INFO;
    case 8,  msg = 'Arriving at your drop-off.';             sub = ['Stopping in ' m(st.dGoal) '.'];                   color = INFO;
    case 9,  msg = 'Taking the turn slowly.';                sub = 'Speed eased for the curve.';                       color = INFO;
    case 10, msg = 'On the way to pick you up.';             sub = 'Lane tracked, no signs in range.';                 color = OK;
    case 11, msg = 'All clear. Driving to your destination.'; sub = 'Lane tracked, no signs in range.';                color = OK;
    case 12, msg = 'Stopped: red sign detected.';            sub = sprintf('HSV blob %.2f m away (%s). The provided stack stops 2 s for any red sign.', st.z, st.signType); color = WARN;
    case 13, msg = 'Driving the outer lap.';                 sub = 'Provided stack: no pickup or drop-off logic.';     color = OK;
    otherwise, msg = '';                                      sub = '';                                                 color = OK;
end
end
