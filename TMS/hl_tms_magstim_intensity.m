function response=hl_tms_magstim_intensity(machine,intensity)               % set intensity
    command=hex2dec('40');                                                  % command
    arg=double(sprintf('%d%d%d',[zeros(1,3-length(int2str(intensity))) intensity]));% add leading zeros to intensity
    bitsum=command+sum(arg);                                                % add up the bits
    CRC=bitxor(bitand(bitsum,255),255);                                     % checksum
    fprintf(machine,[command,'',arg,'',CRC]);                               % execute
    response=fscanf(machine,'%1c %1c %1c %1c',4);                           % read 4 characters
end