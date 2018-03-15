%% SET MAGSTIM BiStim SETTINGS FOR tms1____________________________________
%% must have set machine1='tms1' and run hl_tms_magstim_open.m
e.TMSinit=[50,0,0];                                                         % initial TMS settings (intensity A, intensity B, delay)
hl_tms_magstim_flush(tms1);                                                 % remove dangling bits
hl_tms_magstim_enable_rc(tms1);                                             % enable remote control
response=[];                                                                % clear and initialise variables
A=NaN;                                                                      % collects intensity of first TMS machine
B=NaN;                                                                      % collects intensity of second TMS machine
RC=NaN;                                                                     % collects the Remote Control status (0=no, 1=yes)
T=NaN;                                                                      % collects the delay between TMS machines (BiStim)
ready=NaN;                                                                  % collects ready status
arm=NaN;                                                                    % collects arming status
while A~=e.TMSinit(1)                                                       % until correct setting detected
    hl_tms_magstim_enable_rc(tms1);                                         % enable remote control
    hl_tms_magstim_intensity(tms1,e.TMSinit(1));                            % set TMS intensity to initial setting
    pause(0.25);                                                            % give a little time to adjust to new settings
    [response,A,B,T,RC,ready,arm,post]=hl_tms_magstim_get_status(tms1);     % get TMS status
end
while B~=e.TMSinit(2)                                                       % until correct setting detected
    hl_tms_magstim_enable_rc(tms1);                                         % enable remote control
    hl_tms_magstim_intensity_bi(tms1,e.TMSinit(2));                         % set bistim intensity to initial setting
    pause(0.25);                                                            % give a little time to adjust to new settings
    [response,A,B,T,RC,ready,arm,post]=hl_tms_magstim_get_status(tms1);     % get TMS status
end
while T~=e.TMSinit(3)                                                       % until correct setting detected
    hl_tms_magstim_enable_rc(tms1);                                         % enable remote control
    hl_tms_magstim_interval_bi(tms1,e.TMSinit(3));                          % set bistim delay to initial setting
    pause(0.25);                                                            % give a little time to adjust to new settings
    [response,A,B,T,RC,ready,arm,post]=hl_tms_magstim_get_status(tms1);     % get TMS status
end