% function [d v a on off pv pa pd path]=bl_kinematics(input [,sampfreq] [,onsetvel] [,offsetvel] [,plotdata] [, samplerange])
% from an input of sequential samples of kinematic data, from before the movement onset until after movement offset, calculate a number of kinematic parameters (listed below). Data input can be from 1D to 6D (columns of zeros are fine), and will be padded with zeros up to 6D, output 'location' is 6D or 8D (see below). Onset and offset velocities, if not specified, default to 5% of maximum velocity
% INPUTS
% input: samples in different rows, dimensions (x,y,z,az,el,rl) in different columns
% sampfreq: optional, sampling frequency in Hz, defaults to 1000
% onsetvel: optional, onset 3D velocity criterion, defaults to 5% of the velocity range; If two arguments given, first is velocity criterion, and second specifies how many initial samples to skip
% offsetvel: optional, [offset 3D velocity criterion number of samples], defaults to the onset velocity criterion and 50ms worth of samples
% plotdata: optional, [1 1 1] to plot position, velocity, acceleration figures, 0 to suppress plotting, defaults to [0 0 0]
% samplerange: [a b]: range over which to extract kinematics, default=full range
%
% OUTPUTS: 
% 1: displacement [location]
% 2: velocity [location]
% 3: acceleration [location]
% 4: start of movement [sample, time, velocity, location(6D)]
% 5: peak acceleration [peak_a, sample, time, velocity, location(6D)] (from onset to peak velocity)
% 6: peak velocity [peak_v, sample, time, velocity, location(6D)] (across whole sample)
% 7: peak deceleration [peak_d, sample number, location(6D)] (after peak velocity)
% 8: end of movement [sample number, samples in criterion, time, velocity, location(6D)] (after time of peak deceleration)
% 9: path length [location] (from onset to offset, unsigned sum of all displacements)
%
% LOCATION OUTPUTS ARE 8-DIMENSIONAL: (x, y, z, az, el, rl, tangential position, tangential orientation)
% SAMPLE NUMBER IS IN MILLISECONDS IF A SAMPLE FREQUENCY IS PROVIDED.
% PARAMETERS ARE CALCULATED RELATIVE TO 3D TANGENTIAL POSITIONAL VELOCITY (onset, peak vel, peak acc, peak dec, offset)
%
% TO COME: ALLOW VECTOR INPUT FOR VELOCITY ONSETS, AND CALCULATE STATS PER DIMENSION e.g.: [0 0 Z AZ 0 0];
function [d v a on off pv pa pd path]=bl_kinematics(input,sampfreq,onsetvel,offsetvel,plotdata,samplerange)
if nargin<1 || nargin>6
 error('bl_kinematics: [d v a on off pv pa pd path]=bl_kinematics(input [,sampfreq] [,onsetvel] [,offsetvel] [,plotdata] [,samplerange])');
end
if size(input,2)>size(input,1) && size(input,1)<7
 data=input';                                   % flip rows and columns if necessary
else
 data=input;
end
if size(data,2)>6
 error('bl_kinematics: too many columns in the input matrix, max 6 allowed [X Y Z AZ EL RL]');
end
if size(data,2)<6
 data(:,size(data,2)+1:6)=0;                   % pad data with zeros if necessary
end
samples=size(data,1);
if nargin==1 || isempty(sampfreq) || sampfreq==0
 sampfreq=1000;                                 % acceleration and velocity output in raw form
end
mspersample=(1000./sampfreq);					% milliseconds per sample
if nargin<5
 plotdata=[0 0 0];
end
if nargin<6
 samplerange=[1 size(data,1)];
end
if isempty(samplerange)
 samplerange=[1 size(data,1)];
end
% DISPLACEMENT_____________________________________________________________________________________
d(2:samples,1:6)=data(2:samples,1:6)-data(1:samples-1,1:6);% displacment from samples 2 to end
d(1,:)=d(2,:);                                  % displacment 0:1 = displacement 1:2
d(:,7)=sqrt(sum(d(:,1:3).^2,2));				% 3D displacement in position
d(:,8)=sqrt(sum(d(:,4:6).^2,2));				% 3D displacement in orientation
 
% VELOCITY_________________________________________________________________________________________
v=d.*sampfreq;                                  % velocity = displacement per sample * sample frequency
if nargin<3 || isempty(onsetvel)
 onsetvel=min(v(:,7))+(max(v(:,7))-min(v(:,7)))./20;% velocity onset criterion = 5% of 3D velocity range
end
if onsetvel(1)>=max(v(:,7))./2
 warning('bl_kinematics: onset velocity criterion too high, defaulting to 5% of range');
 onsetvel(1)=min(v(:,7))+(max(v(:,7))-min(v(:,7)))./20;	% onset velocity too high: return to default
end
if length(onsetvel)==2 && onsetvel(2)<samples
 on.skip=onsetvel(2)-1;                         % skip the first n samples, start searching after
else
 on.skip=0;
end
if nargin<4 || isempty(offsetvel)
 offsetvel(1)=onsetvel(1);                     % offset velocity is the same as onset if not specified
 off.samples=round(sampfreq./20);				% samples for offset criterion (50ms)
end
if length(offsetvel)==1
 off.samples=round(sampfreq./20);            % samples for offset criterion (50ms)
else off.samples=offsetvel(2);                  % number of samples for offset velocity
end
if offsetvel(1)>=max(v(:,7))./2
 warning('bl_kinematics: offset velocity criterion too high, defaulting to 5% of range');
 offsetvel(1)=min(v(:,7))+(max(v(:,7))-min(v(:,7)))./20;% onset velocity too high: return to default
end

% ACCELERATION_____________________________________________________________________________________
a(2:samples,:)=v(2:samples,:)-v(1:samples-1,:);	% acceleration from sample 2 to last sample
a(1,:)=a(2,:);                                  % acceleration 1 = acceleration 2
a=a.*sampfreq;                                  % acceleration = velocity per sample * sample frequency
 
% ONSET____________________________________________________________________________________________
on.sample=min(find(v(on.skip+1:samplerange(2),7)>=onsetvel(1)))+on.skip;% first point greater than (3D) velocity onset criterion
if isempty(on.sample)
 on.sample=samples;                             % if no onset, use maximum time
 warning('bl_kinematics: no movement onset found');% warning
end
on.time=on.sample.*mspersample;                 % onset in milliseconds
on.velocity=v(on.sample,:);                     % velocity at onset
on.location=data(on.sample,:);                  % location at onset

% PEAK VELOCITY____________________________________________________________________________________
[pv.velocity,pv.sample]=max((v(samplerange(1):samplerange(2),:)));% first max velocity and sample numbers
pv.sample=pv.sample+samplerange(1)-1;           % correct for onset time
pv.time=pv.sample.*mspersample;                 % time at maximum velocities
pv.location=data(pv.sample,:);                  % locations at maximum velocities

% PEAK ACCELERATION________________________________________________________________________________
[pa.acceleration,pa.sample]=max((a(samplerange(1):pv.sample(7),:)));% max accelerations and sample numbers
pa.sample=pa.sample+samplerange(1)-1;           % correct for onset time
pa.time=pa.sample.*mspersample;                 % time at maximum accelerations
pa.location=data(pa.sample,:);                  % locations at maximum accelerations

% OFFSET___________________________________________________________________________________________
minvel=min(v(pv.sample(7):samplerange(2),7));	% minimum velocity after peak velocity
offvel=find(v(pv.sample(7):samplerange(2),7)<=offsetvel(1));% velocity samples below the offset criterion
if isempty(offvel)                              % if no velocities found below criterion
 warning('bl_kinematics: velocity offset criterion not reached, reporting minimum velocity');
 off.sample=samplerange(2);                     % offset not found, so last sample
else
 off.sample=offvel(min(find(offvel(off.samples:end)-offvel(1:end-off.samples+1)==off.samples-1)));% first point below offset criterion for 3 successive points
 if isempty(off.sample)
  n=off.samples-1;
  while isempty(off.sample)
   off.sample=offvel(min(find(offvel(n:end)-offvel(1:end-n+1)==n-1)));
   n=n-1;
  end
  warning('bl_kinematics: velocity offset time criterion not reached, reporting maximum offset samples');
  off.samples=samplerange(2);
 end
 off.sample=off.sample+pv.sample(7)-1;			% correct for peak velocity time
end
if off.sample<1 off.sample=1; end               % some fudge
off.time=off.sample.*mspersample;				% offset in milliseconds
off.velocity=v(off.sample,:);					% velocity at onset
off.location=data(off.sample,:);				% location at onset

% PEAK DECELERATION________________________________________________________________________________
[pd.deceleration,pd.sample]=min(a(pv.sample(7):off.sample,:));% max decelerations and sample numbers
pd.sample=pd.sample+pv.sample(7)-1;             % correct for peak velocity time
pd.time=pd.sample.*mspersample;                 % time at maximum accelerations
pd.location=data(pd.sample,:);                  % locations at maximum accelerations

% PATH LENGTH______________________________________________________________________________________
path=sum(abs(d(on.sample:off.sample,:)),1);

% PLOT DATA FOR SANITY-CHECKS______________________________________________________________________
if plotdata(1)==1
 figure;
 hold on;
 subplot(4,1,1);
  hold on;
  plot(data(:,1),'k-');
  ax=axis;
  plot([on.sample on.sample],[ax(3) ax(4)],'g-');
  plot([off.sample off.sample],[ax(3) ax(4)],'r-');
  %plot(pa.sample(1),data(pa.sample(1),1),'b^');
  %plot(pv.sample(1),data(pv.sample(1),1),'ks');
  %plot(pd.sample(1),data(pd.sample(1),1),'bv');
  ylabel('X position');
  title('Position');  
 subplot(4,1,2);
  hold on;
  plot(data(:,2),'k-');
  ax=axis;
  plot([on.sample on.sample],[ax(3) ax(4)],'g-');
  plot([off.sample off.sample],[ax(3) ax(4)],'r-');
  %plot(pa.sample(2),data(pa.sample(2),2),'b^');
  %plot(pv.sample(2),data(pv.sample(2),2),'ks');
  %plot(pd.sample(2),data(pd.sample(2),2),'bv');
  ylabel('Y position');
 subplot(4,1,3);
  hold on;
  plot(data(:,3),'k-');
  ax=axis;
  plot([on.sample on.sample],[ax(3) ax(4)],'g-');
  plot([off.sample off.sample],[ax(3) ax(4)],'r-');
  %plot(pa.sample(3),data(pa.sample(3),3),'b^');
  %plot(pv.sample(3),data(pv.sample(3),3),'ks');
  %plot(pd.sample(3),data(pd.sample(3),3),'bv');
  ylabel('Z position');
 subplot(4,1,4);
  hold on;
  plot(d(:,7),'k-');
  ax=axis;
  plot([on.sample on.sample],[ax(3) ax(4)],'g-');
  plot([off.sample off.sample],[ax(3) ax(4)],'r-');
  plot(pa.sample(7),d(pa.sample(7),7),'b^');
  plot(pv.sample(7),d(pv.sample(7),7),'ks');
  plot(pd.sample(7),d(pd.sample(7),7),'bv');
  xlabel('Sample number');
  ylabel('3D displacement');
end
 
% velocity data as well___________________________________________________
if plotdata(2)==1
 figure;
 hold on;
 subplot(4,1,1);
  hold on;
  plot(v(:,1),'k-');
  ax=axis;
  plot([on.sample on.sample],[ax(3) ax(4)],'g-');
  plot([off.sample off.sample],[ax(3) ax(4)],'r-');
  %plot(pa.sample(1),v(pa.sample(1),1),'b^');
  %plot(pv.sample(1),v(pv.sample(1),1),'ks');
  %plot(pd.sample(1),v(pd.sample(1),1),'bv');
  ylabel('X velocity');
  title('Velocity');
 subplot(4,1,2);
  hold on;
  plot(v(:,2),'k-');
  ax=axis;
  plot([on.sample on.sample],[ax(3) ax(4)],'g-');
  plot([off.sample off.sample],[ax(3) ax(4)],'r-');
  %plot(pa.sample(2),v(pa.sample(2),2),'b^');
  %plot(pv.sample(2),v(pv.sample(2),2),'ks');
  %plot(pd.sample(2),v(pd.sample(2),2),'bv');
  ylabel('Y velocity');
 subplot(4,1,3);
  hold on;
  plot(v(:,3),'k-');
  ax=axis;
  plot([on.sample on.sample],[ax(3) ax(4)],'g-');
  plot([off.sample off.sample],[ax(3) ax(4)],'r-');
  %plot(pa.sample(3),v(pa.sample(3),3),'b^');
  %plot(pv.sample(3),v(pv.sample(3),3),'ks');
  %plot(pd.sample(3),v(pd.sample(3),3),'bv');
  ylabel('Z velocity');
 subplot(4,1,4);
  hold on;
  plot(v(:,7),'k-');
  ax=axis;
  plot([on.sample on.sample],[ax(3) ax(4)],'g-');
  plot([off.sample off.sample],[ax(3) ax(4)],'r-');
  plot(pa.sample(7),v(pa.sample(7),7),'b^');
  plot(pv.sample(7),v(pv.sample(7),7),'ks');
  plot(pd.sample(7),v(pd.sample(7),7),'bv');
  plot([ax(1) pv.sample(7)],[onsetvel(1) onsetvel(1)],'g-');
  plot([pv.sample(7) ax(2)],[offsetvel(1) offsetvel(1)],'r-');
  xlabel('Sample number');
  ylabel('3D velocity');
end
if plotdata(3)==1
 % acceleration data as well_______________________________________________
 figure;
 hold on;
 subplot(4,1,1);
  hold on;
  plot(a(:,1),'k-');
  ax=axis;
  plot([on.sample on.sample],[ax(3) ax(4)],'g-');
  plot([off.sample off.sample],[ax(3) ax(4)],'r-');
  %plot(pa.sample(1),a(pa.sample(1),1),'b^');
  %plot(pv.sample(1),a(pv.sample(1),1),'ks');
  %plot(pd.sample(1),a(pd.sample(1),1),'bv');
  ylabel('X acceleration');
  title('Acceleration');
 subplot(4,1,2);
  hold on;
  plot(a(:,2),'k-');
  ax=axis;
  plot([on.sample on.sample],[ax(3) ax(4)],'g-');
  plot([off.sample off.sample],[ax(3) ax(4)],'r-');
  %plot(pa.sample(2),a(pa.sample(2),2),'b^');
  %plot(pv.sample(2),a(pv.sample(2),2),'ks');
  %plot(pd.sample(2),a(pd.sample(2),2),'bv');
  ylabel('Y acceleration');
 subplot(4,1,3);
  hold on;
  plot(a(:,3),'k-');
  ax=axis;
  plot([on.sample on.sample],[ax(3) ax(4)],'g-');
  plot([off.sample off.sample],[ax(3) ax(4)],'r-');
  %plot(pa.sample(3),a(pa.sample(3),3),'b^');
  %plot(pv.sample(3),a(pv.sample(3),3),'ks');
  %plot(pd.sample(3),a(pd.sample(3),3),'bv');
  ylabel('Z acceleration');
 subplot(4,1,4);
  hold on;
  plot(a(:,7),'k-');
  ax=axis;
  plot([on.sample on.sample],[ax(3) ax(4)],'g-');
  plot([off.sample off.sample],[ax(3) ax(4)],'r-');
  plot(pa.sample(7),a(pa.sample(7),7),'b^');
  plot(pv.sample(7),a(pv.sample(7),7),'ks');
  plot(pd.sample(7),a(pd.sample(7),7),'bv');
  xlabel('Sample number');
  ylabel('3D acceleration');
 hold off;
end