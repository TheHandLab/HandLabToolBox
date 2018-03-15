% serial port for TMS MagStim contol requres 9600 bps, 8 data bits, no parity, 1 stop bit, no flow control
function hl_tms_magstim_close(machine)
    if ~isempty(machine)
        fclose(machine);
        delete(machine);       
    end
end