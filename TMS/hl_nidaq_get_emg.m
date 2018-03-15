% collect emg data from nidaq
function bl_collect_emg(src,event)
global t d;
t=event.TimeStamps;
d=event.Data;
end