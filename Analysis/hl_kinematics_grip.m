% bl_kinematics_grip(input,samplehz)
% INPUTS
% input: 2 columns of data sampled at samplehz
% OUTPUTS:
% grip kinematics: aperture, velocity, acceleration, peak grip, samples to
% peak grip, sample, peak location (6D), peak velocity, samples to peak velocity
function grip=bl_kinematics_grip(input,samplehz)
 if nargin~=2
  error('bl_kinematics_grip(input,samplehz) - two arguments required');
 end
 if size(input,2)~=3
  error('bl_kinematics_grip: three columns of position data required');
 end
 if size(input,3)~=2
  error('bl_kinematics_grip: two channels of position data required (3rd dimension of input)');
 end
 data=input;
 grip.ap=sqrt((data(:,1,1)-data(:,1,2)).^2 + (data(:,2,1)-data(:,2,2)).^2 + (data(:,3,1)-data(:,3,2)).^2);
 grip.ap=grip.ap-grip.ap(1); % subtract the first grip measurement (correct for finger size)
 grip.v(2:size(data,1),1)=(grip.ap(2:end)-grip.ap(1:end-1)).*samplehz;
 grip.v(1)=grip.v(2)./2;
 [grip.maxap grip.maxaptime]=max(grip.ap);  
 [grip.maxv grip.maxvtime]=max(grip.v);
 [grip.minv grip.minvtime]=min(grip.v); 
 a=find(grip.v(grip.minvtime+1:end)<0,1);
 grip.endtime=grip.minvtime+a;
 grip.end=grip.ap(grip.endtime);
end