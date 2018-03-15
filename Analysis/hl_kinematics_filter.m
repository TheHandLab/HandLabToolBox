% function filtered=bl_kinematics_filter(data, samplehz [,highhz])
% data = columns of kinematic data (single 6D position & orientation
% samplehz = sampling frequency of data
% highhz = low-pass cut-off; default=10hz
function filtered=bl_kinematics_filter(data, samplehz, highhz)
 if nargin==2 highhz=10; end
 if isempty(highhz) highhz=10; end
 [b a]=butter(2,highhz./(samplehz./2),'low');
 filtered=filtfilt(b,a,data);
end