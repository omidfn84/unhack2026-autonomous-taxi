function replay_ride(ride, speedup)
% REPLAY_RIDE  Play a ride on the rider screen.
%   replay_ride(simulate_lap('ours'))            % Mac, no QLabs needed
%   replay_ride(load_qlabs_run('run1.mat'), 1)   % a logged QLabs run
if nargin < 2, speedup = 2; end
route = []; feel = 3;                                     % rides from simulate_lap carry their route and feel
if isfield(ride, 'route'), route = ride.route; end
if isfield(ride, 'feel'), feel = ride.feel; end
H = rider_screen_qlabs(ride.mode, route, feel);
t0 = tic;                                                 % wall clock for playback
k = 1; n = numel(ride.t);
while k <= n && isvalid(H.fig)
    st = frame(ride, k);
    H = rider_screen_update(H, st);
    target = toc(t0) * speedup;                           % ride time we should be showing
    while k < n && ride.t(k) < target, k = k + 1; end     % skip frames if drawing is slow
    if k == n, H = rider_screen_update(H, frame(ride, n)); break; end
    pause(0.02);
end
end

function st = frame(ride, k)
st.t = ride.t(k); st.x = ride.x(k); st.y = ride.y(k); st.h = ride.h(k); st.v = ride.v(k);
st.phase = ride.phase(k); st.dGoal = ride.dGoal(k); st.status = ride.status(k);
st.det = ride.det(k); st.z = ride.z(k); st.shape = ride.shape(k);
st.s = NaN; if isfield(ride, 's'), st.s = ride.s(k); end
st.area = 0; if isfield(ride, 'area'), st.area = ride.area(k); end
st.sx = NaN; st.sy = NaN; if isfield(ride, 'sx'), st.sx = ride.sx(k); st.sy = ride.sy(k); end
st.signType = ''; if isfield(ride, 'signType') && ~isempty(ride.signType{k}), st.signType = ride.signType{k}; end
end
