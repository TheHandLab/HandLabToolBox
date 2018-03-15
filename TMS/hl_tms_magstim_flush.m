function hl_tms_magstim_flush(machine)                                      % remove any lingering characters in the buffer
    while machine.BytesAvailable>0                                          % if there are some
        fscanf(machine,'%*1c',1);                                           % read them away, one at a time
    end
end