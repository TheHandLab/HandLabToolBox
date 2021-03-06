function response=hl_tms_magstim_disarm(machine)                            % ARM the TMS (must be preceded by enable RC)
    command=hex2dec('45');                                                  % command
    arg=bin2dec('01000001');                                                % bit 1=STOP, bit 2=ARM, bit 3=Trigger
    bitsum=command+sum(arg);                                                % add up the bits
    CRC=bitxor(bitand(bitsum,255),255);                                     % checksum
    fprintf(machine,[command,'',arg,'',CRC]);                               % execute
    response=fscanf(machine,'%1c %1c %1c %1c',4);                           % read 4 characters
end