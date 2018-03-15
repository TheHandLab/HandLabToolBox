% Serial port commands
pp([2:6],[1 1 1 1 1],false,0,888);                                          % turn on all lights to avoid single light flash
pause(0.25);
hl_pol_open;                                                                % open polhemus device
pol.device='fastrak';                                                       % set device
hl_pol_initialise;                                                          % set up standard parameters
hl_pol_clear;                                                               % clear any lines of data remaining
hl_pol_read_point;                                                          % collect single point
hl_pol_read_test;                                                           % collect data in continuous mode
data1=data;                                                                 % copy data
pause(2);                                                                   % wait inter-trial interval
hl_pol_read_test;                                                           % collect a second trial
data2=data;                                                                 % copy data
hl_pol_close;                                                               % close up