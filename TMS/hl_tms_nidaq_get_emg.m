%% collect emg data from nidaq
function hl_tms_nidaq_get_emg(~,event)
    global t d;
    t=event.TimeStamps;
    d=event.Data;
end