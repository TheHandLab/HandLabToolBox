% get line of data from from polhemus (fast: < 8.3ms). data request and tstart=tic must already have been sent
for p=find(pol.receiver==1)                                                 % for active receivers
    pol.n=p;
    bl_pol_read_line;                                                       % get a line of text
    pol.latency=toc(tstart);                                                % record latency
    while pol.data(pol.n,1)~=pol.n                                          % read again if wrong
        bl_pol_read_line;                                                   % get a line of text
        pol.latency=toc(tstart);                                            % record latency
    end
end