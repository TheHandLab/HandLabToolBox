% function filtered=bl_emg_filter(data, samplehz [,lowhz] [,highhz])
% data = columns of emg data
% samplehz = sampling frequency of data
% lowhz = high-pass cut-off; default=25hz
% highhz = low-pass cut-off; default=250hz
function filtered=bl_emg_filter(data, samplehz, lowhz, highhz)
 if nargin==2
     lowhz=25; highhz=250;
 end
 if nargin==3
     highhz==250;
 end
 if isempty(lowhz)
     lowhz=25;
 end
 if isempty(highhz)
     highhz=250;
 end
 [b a]=butter(2,[lowhz highhz]./(samplehz./2));
 filtered=filtfilt(b,a,data);
end