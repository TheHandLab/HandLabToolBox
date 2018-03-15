function [response,A,B,T,RC,ready,arm,post]=hl_tms_magstim_get_status(machine)% get status
    command=hex2dec('4A');                                                  % get status command
    arg=hex2dec('40');                                                      % padding byte
    bitsum=command+arg;                                                     % addup all the bits
    CRC=bitxor(bitand(bitsum,255),255);                                     % checksum figure
    fprintf(machine,[command,'',arg,'',CRC]);                               % execute
    while machine.BytesAvailable==0                                         % wait until data arrives
    end
    response=fscanf(machine,'%c%c %1d%1d%1d %1d%1d%1d %1d%1d%1d %1c',12);   % read current full status properly
    if numel(response)==12                                                  % should be 12 output responses. Usually there are 13, but occasionally the linefeed ? is missing
        A=response(3)*100+response(4)*10+response(5);                       % intensity of unit A
        B=response(6)*100+response(7)*10+response(8);                       % intensity of unit B
        T=response(9)*100+response(10)*10+response(11);                     % delay between units
        %disp(dec2bin(response(2),8));
        switch response(2)
            case 8                                                          % Manual, armed, just after TMS pulse
                RC=0;
                ready=0;
                arm=1;
                post=1;
            case 9                                                          % Manual, unarmed
                RC=0;
                ready=0;
                arm=0;
                post=0;
            case 10                                                         % Manual, armed, not ready
                RC=0;
                ready=0;
                arm=1;
                post=0;
            case 12                                                         % Manual, armed, ready
                RC=0;
                ready=1;
                arm=1;
                post=0;
            case 338                                                        % Remote, armed, ready
                RC=1;
                ready=1;
                arm=1;
                post=0;
            case 352                                                        % Remote, armed, not ready
                RC=1;
                ready=0;
                arm=1;
                post=0;
            case 710                                                        % Remote, armed, just after TMS pulse
                RC=1;
                ready=0;
                arm=1;
                post=0;
            case 8240                                                       % Remote, unarmed
                RC=1;
                ready=0;
                arm=0;
                post=0;
            otherwise                                                       % Not recognised
                RC=NaN;
                ready=NaN;
                arm=NaN;
                post=NaN;
        end
    else                                                                    % if response not received
        A=NaN;                                                              % set intensity A to empty
        B=NaN;                                                              % set intensity B to empty
        T=NaN;                                                              % set delay to empty
        RC=NaN;                                                             % set RC to empty
        ready=NaN;                                                          % set ready to empty
        arm=NaN;                                                            % set arm to empty
        post=NaN;                                                           % set post to empty
    end
    hl_tms_magstim_flush(machine);                                          % flush the characters away to start again
end