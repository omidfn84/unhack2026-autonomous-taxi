function [shape, fillRatio, aspect] = classify_red_sign(mask, blobLocation, blobFound)
%#codegen
% CLASSIFY_RED_SIGN  Tell a stop sign from a yield sign using the HSV red mask.
% Inputs (all already inside HSVStopSignDetection/findStopSignLocation):
%   mask         = imageBinary from colorThresholdingHSV (480x640, red pixels non-zero)
%   blobLocation = blob centre in px relative to the image centre ([row col]; the
%                  model subtracts [240 320], findStopSignDistance adds it back)
%   blobFound    = blobFound? output
% Outputs: shape 0 unknown, 1 stop (octagon), 2 yield (triangle), 3 sign faces another road
%          fillRatio = red pixels / bounding-box area, aspect = box width / height
% Thresholds must match taxi_config.m; tune them with calibrate_sign_shapes.m.

STOP_FILL_MIN = 0.55;   % an octagon fills about 83 % of its box (less with the white letters)
YIELD_FILL_MAX = 0.50;  % a yield triangle is a red ring: well under half its box
MIN_ASPECT = 0.60;      % a sign seen side-on looks narrow: it is facing another road
HALF = 90;              % search window half-size around the blob centre (px)

shape = 0; fillRatio = 0; aspect = 0;
if ~blobFound, return; end
[H, W] = size(mask);
r0 = round(H / 2 + blobLocation(1));                 % back to absolute row
c0 = round(W / 2 + blobLocation(2));                 % back to absolute column
r1 = max(1, r0 - HALF); r2 = min(H, r0 + HALF);      % window limits, kept inside the image
c1 = max(1, c0 - HALF); c2 = min(W, c0 + HALF);
win = mask(r1:r2, c1:c2) > 0;                        % red pixels near the blob
rows = find(any(win, 2)); cols = find(any(win, 1));
if isempty(rows) || isempty(cols), return; end
h = rows(end) - rows(1) + 1;                         % bounding-box height (px)
w = cols(end) - cols(1) + 1;                         % bounding-box width (px)
fillRatio = nnz(win) / (h * w);                      % how much of the box is red
aspect = w / h;                                      % 1 when the sign faces the camera

if aspect < MIN_ASPECT
    shape = 3;                                       % turned away: not for our lane
elseif fillRatio >= STOP_FILL_MIN
    shape = 1;                                       % octagon
elseif fillRatio <= YIELD_FILL_MAX
    shape = 2;                                       % triangle
end
end
