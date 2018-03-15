function hl_nidaq_callback(~,event)
    global d ts;
    d=event.Data;                                                           % data from event listener
    ts=event.TimeStamps;                                                    % timestamps from event listener
end