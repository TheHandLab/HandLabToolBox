% get line of data from from polhemus (fast: < 8.3ms). data request and tstart=toc must already have been sent
for p=receivers%find(pol.receiver==1)                                                 % for active receivers
    pol.n=p;                                                                % set n to this receiver
    hl_pol_read_line_fastrak;                                                       % get a line of text
    %pol.latency=toc(tstart);                                                % record latency
    while pol.data(pol.n,1)~=pol.n                                          % read again if wrong
        hl_pol_read_line_fastrak;                                           % get a line of text
        %pol.latency=toc(tstart);                                            % record latency
    end
end