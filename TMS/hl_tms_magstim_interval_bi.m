function response=hl_tms_magstim_interval_bi(machine,interval)              % set inter-pulse interval of second TMS device in BiStim mode
    command=hex2dec('43');                                                  % command
    arg=double(sprintf('%d%d%d',[zeros(1,3-length(int2str(interval))) interval]));  % add leading zeros to interval
    bitsum=command+sum(arg);                                                % add up the bits
    CRC=bitxor(bitand(bitsum,255),255);                                     % checksum
    fprintf(machine,[command,'',arg,'',CRC]);                               % execute
    response=fscanf(machine,'%1c %1c %1c %1c',4);                           % read 4 characters
end