function [msg, color] = status_text(code, dObs, dSign)
% STATUS_TEXT  Turn a status code into the rider message and a lamp colour.
green = [0.20 0.80 0.40];  amber = [1.00 0.70 0.10];  blue = [0.30 0.60 1.00];  % lamp colours

switch code
    case 1, msg = "You've arrived. Take your time getting out.";          color = blue;
    case 2, msg = "Welcome! We'll leave once you're settled.";            color = blue;
    case 3, msg = "Waiting for a pedestrian to cross.";                   color = amber;
    case 4, msg = sprintf("Pedestrian ahead (%.1f m). Slowing down gently.", dObs);  color = amber;
    case 5, msg = "Stopped at stop sign. Checking it's clear.";           color = amber;
    case 6, msg = sprintf("Stop sign ahead (%.1f m). Slowing down.", dSign);         color = amber;
    case 8, msg = "On the way to pick you up.";                           color = green;
    otherwise, msg = "All clear. Driving to your destination.";           color = green;
end
end
