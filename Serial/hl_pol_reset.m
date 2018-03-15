% Re-sets the Polhemus device after crashes, etc
fprintf(polhemus,'%c\r',25);    % reset the polhemus by sending 'control-shift-Y'
if pol.device=='patriot'
    printf(polhemus, '\r');
end
pause(10);                      % wait 10s (minimum) for system to restart