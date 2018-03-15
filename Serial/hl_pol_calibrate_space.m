% calibrate polhemus space
cd 'C:\Octave\grasping';
bl_pol_open;
bl_pol_initialise;

xpoints=17;
ypoints=13;

stim.audsamplehz=44100;
stim.starttone=bl_tone(1000,stim.audsamplehz,0.25);
stim.endtone=bl_tone(500,stim.audsamplehz,0.25);

calibration_data=zeros(xpoints,7,ypoints);
for y=1:ypoints
 for x=1:xpoints
  bl_pol_read_point;
  wavplay(stim.endtone,stim.audsamplehz,'async'); % start tone for subject   
  calibration_data(x,:,y)=pol.data(1,:);
  pause(2);
 end
 disp('press space...');
 keypress=0;
 while keypress~=32
  [a,b,key]=KbWait; keypress=find(key==1);
 end
end
bl_pol_close;
mesh(squeeze(calibration_data(:,2,:)),squeeze(calibration_data(:,3,:)),squeeze(calibration_data(:,4,:)))
xlabel('x axis (far-near, cm)');
ylabel('y axis (left-right, cm)');
zlabel('z axis (down-up, cm)');
title('Polhemus calibration with table hinges removed');