% bl_subtract_ref(data, reference);
% data = column(s) of data from which to subtract the reference (baseline) data
% reference = single column of data to subtract from the main data, must be same length as data
% good for EOG and EEG data
function output=bl_subtract_ref(data,ref);
if nargin~=2 || (size(data,1)~=size(ref,1) && size(ref,1)~=1) || size(ref,2)~=1
 usage('bl_subtract_ref(data, ref)');
end
output=zeros(size(data,1),size(data,2));
for c=1:size(data,2)
 output(:,c)=data(:,c)-ref;
end