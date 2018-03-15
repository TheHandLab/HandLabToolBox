% get single datapoint from polhemus (slow: 20-90ms): includes open, initialise, clear, tic, wait, toc
if exist('polhemus')==0             % open new serial port object, if polhemus doesn't exist
    bl_pol_open;
    bl_pol_initialise;
end
bl_pol_clear;                       % clear the buffer
pol.data(:,:)=0;                    % clear previous data
switch pol.device                   % send request for single data point
    case {'liberty'}
        tstart=tic;                 % start timer for latency data
        fprintf(polhemus,'%c','p'); % lowercase p and no carriage return or line feed
    case {'patriot'}
        tstart=tic;                 % start timer for latency data
        fprintf(polhemus,'%c','p'); % lowercase p and no carriage return or line feed
    case {'fastrak'}
        tstart=tic;                 % start timer for latency data
        fprintf(polhemus,'%c','P'); % uppercase p and no carriage return or line feed
end
bl_pol_wait;                        % wait until a line of bytes in polhemus
bl_pol_read;                        % read line