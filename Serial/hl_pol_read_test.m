% test bl_pol_read with multiple points in continuous mode
s = 10;                                                         % samples to record
data = zeros(s,pol.receivers,pol.data_len+1);                   % samples x receivers x data_length
bl_pol_clear;                                                   % clear buffer
tstart = tic;                                                   % start timer
bl_pol_trigger;                                                 % trigger continuous mode
for p = 1:s;                                                    % for p samples
    pol.data = zeros(pol.receivers,pol.data_len);               % clear old data
    for n = find(pol.receiver == 1);                            % for active receivers
        bl_pol_read_line;                                       % get a line of text
        pol.latency = toc(tstart);                              % record latency
        while pol.data(n,1) ~= n;                               % read again if wrong
            bl_pol_read_line;                                   % get a line of text
            pol.latency = toc(tstart);
        end;
        data(p,n,1:pol.data_len) = pol.data(n,1:pol.data_len);  % record data
        data(p,n,pol.data_len+1:pol.data_len+1) = toc(tstart);  % record time
    end;
end;
bl_pol_untrigger;                                               % stop continuous mode