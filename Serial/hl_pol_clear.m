% removes polhemus data currently in the serial buffer
while polhemus.BytesAvailable>=pol.str_len      % while there's a line or more of text in the buffer
    fgetl(polhemus);                            % read it
end