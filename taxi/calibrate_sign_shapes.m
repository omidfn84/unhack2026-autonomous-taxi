% CALIBRATE_SIGN_SHAPES  Measure real blob fill and aspect from a QLabs run.
% 1. In HSVStopSignDetection/findStopSignLocation, send imageBinary, blobLocation and
%    blobFound? to three To Workspace blocks named maskLog, blobLog, foundLog
%    (Save format: Array, sample time = RealSense_Sample_Time).
% 2. Drive past one stop sign and one yield sign, stop the model, then run this script.
% 3. Set STOP_FILL_MIN / YIELD_FILL_MAX in classify_red_sign.m (and taxi_config.m)
%    between the two groups it prints.

masks = out.maskLog;                                 % 480 x 640 x N
blobs = out.blobLog;                                 % N x 2
found = out.foundLog(:);                             % N x 1
fprintf('frame  fill   aspect  shape\n');
for k = find(found)'                                 % only frames with a red blob
    [shape, fillRatio, aspect] = classify_red_sign(masks(:, :, k), blobs(k, :), true);
    fprintf('%5d  %.2f   %.2f    %d\n', k, fillRatio, aspect, shape);
end
