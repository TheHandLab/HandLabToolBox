function response=hl_tms_magstim_enable_rc(machine)                         % enable remote control
    command=hex2dec('51');                                                  % enable RC command
    arg=hex2dec('40');                                                      % padding byte
    bitsum=command+sum(arg);                                                % addup all the bits
    CRC=bitxor(bitand(bitsum,255),255);                                     % checksum figure
    fprintf(machine,[command,'',arg,'',CRC]);                               % execute
    response=fscanf(machine,'%1c %1c %1c %1c',4);                           % read 4 characters
end