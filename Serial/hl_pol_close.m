% close the serial port
pol.status = polhemus.Status;
while size(pol.status,2) == 4;
    fclose(polhemus);
    pol.status = polhemus.Status;
end;
delete(polhemus);
clear polhemus;