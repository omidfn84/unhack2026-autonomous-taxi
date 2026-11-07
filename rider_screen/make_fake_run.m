function ride = make_fake_run()
% MAKE_FAKE_RUN  A made-up 40 s ride so the screen can be built before real data exists.
t = (0:0.1:40)';  n = numel(t);       % one sample every 0.1 s
ride.t = t;                            % time (s)
ride.v = 0.4*ones(n,1);                % cruising at base speed by default
ride.stopFlag = zeros(n,1);            % not stopped at a goal
ride.phase = ones(n,1);                % 1 = heading to pickup
ride.dObs = nan(n,1);                  % NaN = no obstacle detected
ride.dSign = nan(n,1);                 % NaN = no stop line detected

in = @(a,b) t >= a & t < b;           % helper: samples between a and b seconds

ride.v(in(3,5)) = linspace(0.4,0,nnz(in(3,5)));          % slow into the pickup
ride.v(in(5,10)) = 0;  ride.stopFlag(in(5,10)) = 1;       % stopped at pickup for 5 s
ride.v(in(10,12)) = linspace(0,0.4,nnz(in(10,12)));      % gentle pull-away
ride.phase(t >= 10) = 2;                                 % rider on board: heading to drop-off

ride.dSign(in(14,17)) = linspace(0.9,0.15,nnz(in(14,17)));   % stop line getting closer
ride.v(in(14,17)) = linspace(0.4,0,nnz(in(14,17)));          % slowing for it
ride.dSign(in(17,20)) = 0.15;  ride.v(in(17,20)) = 0;         % waiting at the stop sign
ride.v(in(20,22)) = linspace(0,0.4,nnz(in(20,22)));          % pulling away

ride.dObs(in(25,28)) = linspace(1.2,0.4,nnz(in(25,28)));     % pedestrian getting closer
ride.v(in(25,28)) = linspace(0.4,0,nnz(in(25,28)));          % slowing for them
ride.dObs(in(28,31)) = 0.4;  ride.v(in(28,31)) = 0;           % waiting while they cross
ride.v(in(31,33)) = linspace(0,0.4,nnz(in(31,33)));          % pedestrian gone, pull away

ride.v(in(34,36)) = linspace(0.4,0,nnz(in(34,36)));          % slow into drop-off
ride.v(t >= 36) = 0;  ride.stopFlag(t >= 36) = 1;             % arrived

ride.dGoal = zeros(n,1);                                      % distance left to current goal
ride.dGoal(t < 5) = linspace(1.5,0,nnz(t < 5));               % to pickup
ride.dGoal(in(10,36)) = linspace(6,0,nnz(in(10,36)));         % to drop-off
end
