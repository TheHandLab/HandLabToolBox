% bl_process_eog(data,elec,ref,samplehz [,filter])
% data: 5 columns of EOG data
% elec: vector indicating the column numbers for left, right, inferior, and superior electrodes
% ref: column index for the reference electrode data
% samplehz: sample frequency of the data
% filter: optional 2-component filter specification [high pass low pass], default is [1 20] Hz, 4th order Butterworth
% output is a matrix of filtered EOG data with columns:
% 1,2,3,4: left, right, inferior, superior electrodes with the reference subtracted
% 5, 6: HEOG (left-right) and VEOG (inferior-superior) differentials
function output=hl_eog_process(data,elec,ref,samplehz,filter)
if nargin<4 || nargin>5 || isempty(data) || isempty(elec) || isempty(ref) || isempty(samplehz)
 error('bl_process_eog(data, elec, ref, samplehz [, filter])');
end
if nargin==4
 filter=[1 20];
end
[b,a]=butter(2,filter./(samplehz./2));                                  % 4th order zero-lag bandpass Butterworth filter
samples=size(data,1);
output=zeros(samples+200,6);
output(101:end-100,elec)=hl_subtract_ref(data(:,elec),data(:,ref));		% subtract reference electrode data
for c=elec
 output(1:101,c)=output(102,c);                                         % pad the beginning with non-zeros, for filtering
 output(end-100:end,c)=output(end-101,c);                               % and pad the end
end
output(:,elec)=filtfilt(b,a,output(:,elec));                            % filter the data
output=output(101:end-100,:);                                           % reduce to the real data
output(:,5)=output(:,elec(1))-output(:,elec(2));                        % HEOG differential data
output(:,6)=output(:,elec(3))-output(:,elec(4));                        % VEOG differential data
end