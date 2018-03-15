%% TMS hotspot finder
% presents locations to stimulate on screen
% presents TMS pulse
% collects EMG data
% analyses MEP
% plots data
close all;
clc;
format short g;
online=1;

%% experimental parameters_________________________________________________
e.samplehz=4000;                                                            % sampling frequency
e.sampleduration=1;                                                         % sample duration
e.channels=5;                                                               % how many EMG channels+trigger channel
e.width=8;                                                                  % how many points from anterior to posterior
e.height=8;                                                                 % how many points from medial to lateral
e.lat=1;                                                                    % start location lateral to vertex
e.ant=-3;                                                                   % start location anterior to vertex
e.gridspacing=1;                                                            % how many cm between points
e.points=e.width.*e.height;                                                 % points in grid to stimulate
e.iti=5;                                                                    % seconds between TMS pulses (min)
e.triggerthreshold=4.5;                                                     % Voltage threshold for TMS trigger
e.triggerchannel=5;                                                         % channel which TMS trigger comes in on (last channel)
e.mepwindowms=[8,60];                                                       % ms after TMS to look for MEPs
e.mepwindow=round(e.mepwindowms.*(e.samplehz./1000));                       % convert to samples
e.emgthreshold=0.1;                                                         % mean level of baseline activity (threshold), per channel, mV
e.x=repmat([e.lat:1:e.lat+e.height-1]',1,e.width);                          % x-coordinate locations (lateral)
e.y=repmat([e.ant:1:e.ant+e.width-1],e.height,1);                           % y-coordinate locations (anterior)

%% set up NI data acquisition______________________________________________
daq.reset;                                                                  % reset something
daq.HardwareInfo.getInstance('DisableReferenceClockSynchronization',true);  % this disables reference clock synchronisation, an incompatibility between the PXI/PCI chassis, NI Card, and some clock
s=daq.createSession('ni');                                                  % session type
chan=s.addAnalogInputChannel('Dev1',[0,1,2,3,4],'Voltage');                 % add 5 analogue input channels (4 muscles, 1 TMS trigger)
for p=1:e.channels
    chan(p).InputType='SingleEnded';                                        % input type (Differential, SingleEnded)
    chan(p).Range=[-10,10];                                                 % voltage range
end
s.Rate=e.samplehz;                                                          % set sampling rate
s.DurationInSeconds=e.sampleduration;                                       % set sampling duration in seconds
s.NotifyWhenDataAvailableExceeds=e.samplehz.*e.sampleduration;              % get data every second
global t d;                                                                 % declare global variables
t=zeros(e.samplehz.*e.sampleduration,1);                                    % initialise time data
d=zeros(e.samplehz.*e.sampleduration,1);                                    % initiliase data
lh=s.addlistener('DataAvailable',@hl_tms_nidaq_get_emg);                    % define event listener
s.startBackground();                                                        % initialise data collection
 
%% SET UP TMS______________________________________________________________
e.TMStrigger=1;                                                             % digital code for triggering TMS
e.triggervector=dec2binvec(e.TMStrigger);                                   % setup start trigger
s2=daq.createSession('ni');                                                 % session type
s2.addDigitalChannel('Dev1','Port0/Line2','OutputOnly');                    % add digital output port for TMS trigger
s2.outputSingleScan(0);                                                     % initialise trigger vector application

%% DATA STORAGE____________________________________________________________
data=nan(e.samplehz.*e.sampleduration,e.channels+1,e.points);               % output data (samples, channels+1,points)
meps=nan(e.height,e.width,e.channels-1);                                    % mep data

%% RUN HOTSPOT FINDER______________________________________________________
e.p=str2double(cell2mat(inputdlg('HandLab ID number?')));                   % get handlab participant ID
e.tmstype=listdlg('PromptString','Select TMS setup:','ListString',{'MagStim 100mm fig8','Mag&More 100mm fig8'},'SelectionMode','single');
e.i=str2double(cell2mat(inputdlg('TMS intensity %?')));                     % get TMS intensity
e.h=listdlg('PromptString','Hemisphere?','ListString',{'Left','Right'},'SelectionMode','single');
% Muscle List (ORDER MUST BE CONSTANT, NUMBERED FROM HAND TO ARM)
e.musclelist={'1:FDI','2:APB/FPB/OP','3:ADM','4:EDC','5:FDS','6:EPB/EPL','7:ECR','8:ECU','9:FCR','10:FCU','11:Brachioradialis','12:Biceps','13:Triceps','14:Deltoid','15:Pectoralis'};
% 1: FDI (first dorsal interosseus)
% 2: APB/FPB/OP (muscles of the thenar eminence)
% 3: ADM (abductor digiti minimi)
% 4: EDC
% 5: FDS
% 6: EPB/EPL
% 7: ECR
% 8: ECU
% 9: FCR
% 10: FCU
% 11: Brachioradialis
% 12: Biceps
% 13: Triceps
% 14: Deltoid
% 15: Pectoralis
e.muscles=listdlg('PromptString','Select Muscles:','ListString',e.musclelist);% select muscle(s)
figure;
    hold on;
for f=1:e.channels-1                                                        % set up figure
    subplot(ceil((e.channels-1)./2),2,f);                                   % choose sub-plot
        hold on;                                                            % turn on hold
          title([e.musclelist{e.muscles(f)},' (V)']);                       % add title
          xlabel('Right of vertex (cm)');                                   % add x label
          ylabel('Anterior to vertex (cm)');                                % lower y-axis label
          colorbar;
end
pause(e.iti+5);                                                             % delay before first trial
n=0;
for h=1:e.gridspacing:e.height
    if h>1
        beep;                                                               % cue to switch to new column
    end
    disp(['Row ',int2str(h),'...']);                                        % on-screen progress
    for w=1:e.gridspacing:e.width                                           % for each point along the width
        n=n+1;                                                              % increment counter
        disp([' Col ',int2str(w),'...']);                                   % on-screen progress
        
        %% CHECK FOR LOW EMG BACKGROUND ACTIVITY___________________________
        s.startBackground();                                                % start collecting
        pause(e.sampleduration);                                            % wait while data collected
        emg=mean(abs(d(:,1:e.channels-1)),1);                               % mean baseline data
        while max(emg)>e.emgthreshold
            s.startBackground();                                            % start collecting
            pause(e.sampleduration);                                        % wait while data collected
            emg=mean(abs(d(:,1:e.channels-1)),1);                           % mean baseline data 
        end
        
        %% GET COIL POSITION_______________________________________________
  
        %% COLLECT DATA____________________________________________________
        s.startBackground();                                                % start collecting
        s2.outputSingleScan(1);                                             % apply trigger vector
        pause(e.sampleduration);                                            % wait while data collected
        s2.outputSingleScan(0);                                             % apply trigger vector
        tms=find(d(:,e.triggerchannel)>e.triggerthreshold,1);               % find trigger time
        if isempty(tms)                                                     % if no trigger found
            tms=1;                                                          % default to sample 1
        end
        data(1:end-tms+1,:,n)=[t(tms:end),d(tms:end,:)];                    % store data
        for f=1:e.channels-1                                                % for each data channel
            
            %% MEASURE MEP_________________________________________________
            if online   
                meps(h,w,f)=max(d(tms+e.mepwindow(1):tms+e.mepwindow(2),f))-min(d(tms+e.mepwindow(1):tms+e.mepwindow(2),f));% calculate and store MEP peak-to-peak amplitude
            end
            
            %% PLOT DATA___________________________________________________
            subplot(ceil((e.channels-1)./2),2,f);                           % choose sub-plot
            if e.h==1                                                       % LEFT HEMISPHERE DATA
                contourf(-e.x,e.y,meps(:,:,f));                             % contour plot of MEP amplitudes so far
            else                                                            % RIGHT HEMISPHERE DATA
                contourf(e.x,e.y,meps(:,:,f));                              % contour plot of MEP amplitudes so far
            end
        end
        drawnow; 
        pause(e.iti+2.*rand(1,1)-1);                                        % delay between trials (with 2s jitter
    end                                                                     % OF ROW LOOP
end                                                                         % OF COLUMN LOOP

%% CLEAR UP AND SAVE_______________________________________________________
delete(lh);                                                                 % delete listener
clear ans d f h n online t tms w;
e.file=['hotspot_#',int2str(e.p),'_',int2str(e.i),'%_',e.time];             % create filename
save(e.file);                                                               % save the file
h=gcf;                                                                      % get current axis
hgsave(h,e.file);                                                           % save the figure