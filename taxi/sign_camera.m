function c = sign_camera(x, y, h, O, cfg)
% SIGN_CAMERA  Mac-only stand-in for the RealSense + HSV pipeline, used by simulate_lap.
% Projects every red sign from Setup_Real_Scenario.m into a 640x480 pinhole camera and
% applies the model's HSV rule: largest red blob >= 100 px and depth <= 1.2 m.
% On a real QLabs run this function is NOT used: the model's own HSV blocks do this.

SIGN_W = struct('stop', 0.075, 'yield', 0.09);   % ASSUMPTION: face width at the 0.1 spawn scale (m)
FILL = struct('stop', 0.828, 'yield', 0.433);    % face area / width^2 (octagon, triangle)
EXTENT = struct('stop', 0.83, 'yield', 0.50);    % idealised blob fill of its bounding box

f = (cfg.cam.w / 2) / tand(cfg.cam.hfov / 2);    % focal length in pixels
hd = [cos(h), sin(h)]; left = [-hd(2), hd(1)];   % camera forward and left axes
cx = x + hd(1) * cfg.cam.ahead; cy = y + hd(2) * cfg.cam.ahead;   % camera position

c = struct('found', false, 'detected', false, 'type', '', 'z', NaN, 'xl', NaN, ...
           'area', 0, 'facing', 0, 'extent', 0, 'aspect', 0, 'shape', 0, 'sx', NaN, 'sy', NaN);
for k = 1:numel(O.signs)
    s = O.signs(k);
    if ~ismember(s.type, {'stop', 'yield'}), continue; end        % only red signs pass the HSV filter
    v = [s.x - cx, s.y - cy];
    z = v * hd';  xl = v * left';                                  % depth and sideways offset
    if z < 0.05 || abs(atan2d(xl, z)) > cfg.cam.hfov / 2, continue; end   % behind or outside the view
    n = [cosd(s.yaw), sind(s.yaw)];                                % direction the sign face points
    facing = (n * (-v)') / norm(v);                                % 1 = facing the camera
    if facing <= 0, continue; end                                  % back of the sign is not red
    area = FILL.(s.type) * SIGN_W.(s.type)^2 * (f / z)^2 * facing; % red pixels
    if area > c.area                                               % keep the largest blob
        c.found = area >= cfg.minBlob;
        c.detected = c.found && z <= cfg.maxDepth;                 % stopSignDetection
        c.type = s.type; c.z = z; c.xl = xl; c.area = area; c.facing = facing;
        c.extent = EXTENT.(s.type); c.aspect = facing; c.sx = s.x; c.sy = s.y;
    end
end
% same thresholds as classify_red_sign.m
if c.found
    if c.aspect < cfg.minAspect
        c.shape = 3;
    elseif c.extent >= cfg.stopFillMin
        c.shape = 1;
    elseif c.extent <= cfg.yieldFillMax
        c.shape = 2;
    end
end
end
