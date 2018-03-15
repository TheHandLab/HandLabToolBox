%% TMS threshold finder____________________________________________________
% presents TMS pulses
% collects EMG data
% analyses MEP
% adjusts TMS intensity with QUEST
close all;
clear all;
clc;
format short g;
online=1;
e.timestring=hl_timestring;                                                 % set time for files
e.p=str2double(cell2mat(inputdlg('HandLab ID number?')));                   % get handlab participant ID
e.tmstype='MagStim 100mm fig8';                                             % set TMS type used
e.h=listdlg('PromptString','Hemisphere?','ListString',{'Left','Right'},'SelectionMode','single');
% Muscle List (ORDER MUST BE CONSTANT, NUMBERED FROM HAND TO ARM)
e.musclelist={'FDI','APB/FPB/OP','ADM','EDC','FDS','EPB/EPL','ECR','ECU','FCR','FCU','Brachioradialis','Biceps','Triceps','Deltoid','Pectoralis'};
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
if ispc
    cd ('C:\HandLab\P0_TMS_Thresholds');                                    % where to save data to
end

%% EXPERIMENTAL PARAMETERS_________________________________________________
e.samplehz=12000;                                                           % sampling frequency (must be enough to catch the 100us TMS trigger
e.sampleduration=1;                                                         % sample duration
e.channels=numel(e.muscles)+1;                                              % how many EMG channels+trigger channel
e.trials=38;                                                                % trials to find threshold
e.practice=2;                                                               % trials at the start without adjusting QUEST
e.pbi=5;                                                                    % pre-block interval
e.iti=5;                                                                    % seconds between TMS pulses (min)
e.triggerthreshold=4;                                                       % Voltage threshold for TMS trigger
e.triggerchannel=5;                                                         % channel which TMS trigger comes in on (last channel)
e.triggerdelay=0.25;                                                        % seconds after start to present TMS
e.mepwindowms=[8,60];                                                       % ms after TMS to look for MEPs
e.mepwindow=round(e.mepwindowms.*(e.samplehz./1000));                       % convert to samples
e.emgthreshold=1;                                                           % mean level of baseline activity (threshold), per channel
e.MEPthreshold=0.025;                                                       % minimum amplitude of MEPs (mV)
e.MEPthresholdZ=2.33;                                                       % threshold relative to SD of baseline activity
e.MEPchannel=1;                                                             % which channel to use for threshold?
e.EMGgain=10;                                                               % multiply the incoming EMG data by this

%% set up NI data acquisition______________________________________________
daq.reset;                                                                  % reset something
daq.HardwareInfo.getInstance('DisableReferenceClockSynchronization',true);  % this disables reference clock synchronisation, an incompatibility between the PXI/PCI chassis, NI Card, and some clock
s=daq.createSession('ni');                                                  % session type
chan=s.addAnalogInputChannel('Dev1',0:4,'Voltage');                         % add analogue input channels (Max 4 muscles + 1 TMS trigger)
for p=1:numel(e.muscles)
    chan(p).InputType='SingleEnded';                                        % input type (Differential, SingleEnded)
    chan(p).Range=[-10,10];                                                 % voltage range
end
chan(e.triggerchannel).InputType='Differential';                            % input type (Differential, SingleEnded)
chan(e.triggerchannel).Range=[-10,10];                                      % voltage range
s.Rate=e.samplehz;                                                          % set sampling rate
s.NumberOfScans=e.samplehz.*e.sampleduration;                               % set sampling duration in scans
s.NotifyWhenDataAvailableExceeds=e.samplehz.*e.sampleduration;              % get data every second
global t d;                                                                 % declare global variables
t=zeros(e.samplehz.*e.sampleduration,1);                                    % initialise time data
d=zeros(e.samplehz.*e.sampleduration,1);                                    % initiliase data
lh=s.addlistener('DataAvailable',@hl_tms_nidaq_get_emg);                    % define event listener
s.startBackground();                                                        % initialise data collection

%% SET UP NI TMS output____________________________________________________
s2=daq.createSession('ni');                                                 % session type
s2.addDigitalChannel('Dev1','Port0/Line2','OutputOnly');                    % add digital output port for TMS trigger
s2.outputSingleScan(0);                                                     % initialise trigger vector application

%% SET UP TMS______________________________________________________________
machine1='tms1';                                                            % name of machine1
hl_tms_magstim_open;                                                        % open serial connection to TMS machine
e.TMStrigger=1;                                                             % digital code for triggering TMS
e.TMSjitter=3;                                                              % how much to vary the TMS intensity up or down to prevent the same intensity being tested
e.triggervector=dec2binvec(e.TMStrigger);                                   % setup start trigger
e.TMSinit=[50,0,0];                                                         % initial TMS settings (intensity A, intensity B, delay)
hl_tms_magstim_initialise;                                                  % sets TMS1 to initial settings, above

%% SET UP QUEST____________________________________________________________
threshold.mean=50;                                                          % starting threshold % for QUEST
threshold.SD=threshold.mean;                                                % starting threshold SD for QUEST
threshold.min=20;                                                           % minimum reasonable intensity
threshold.max=80;                                                           % maximum reasonable intensity
threshold.p=0.69;                                                           % proportion MEPs at threshold, corresponds to d-prime=1 for 1-interval
threshold.beta=3.5;                                                         % slope of psychophysical function
threshold.delta=0.05;                                                       % not sure...
threshold.gamma=0.5;                                                        % proportion of trials blind/mistaken responses
threshold.grain=0.005;                                                      % resolution of underlying distribution
threshold.range=2.*threshold.mean;                                          % range of possible thresholds around mean
threshold.q=QuestCreate(threshold.mean,threshold.SD,threshold.p,threshold.beta,threshold.delta,threshold.gamma,threshold.grain,threshold.range); % create quest functions
threshold.q.normalizePdf=1;                                                 % otherwise pdf underflows after ~1000 trials

%% DATA STORAGE____________________________________________________________
data=nan(e.samplehz.*e.sampleduration,e.channels+1,e.trials);               % output data (samples, channels+1,points)
meps=nan(e.trials,e.channels-1);                                            % mep data

%% CREATE FIGURE___________________________________________________________
figure('color',[.7 .7 .7]);                                                 % make a grey figure
    e.fignum=gcf;                                                           % get number
    subplot(e.channels+1,1,1);                                              % upper plot = threshold
        h=gca;                                                              % get current axis
        set(h,'color',[.7 .7 .7]);                                          % set background to grey
        hold on;                                                            % hold all plotting
        axis([0,e.trials+1,0,threshold.range]);                             % optimise axis
        plot([0,e.trials+1],[0,0],'k--');                                   % draw broken black line at y=0
        plot([0,e.trials+1],[threshold.range,threshold.range],'k--');       % draw broken black line at y=max possible
        plot([0,e.trials+1],[threshold.min,threshold.min],'k-');            % draw black line at y=min threshold
        plot([0,e.trials+1],[threshold.max,threshold.max],'k-');            % draw black line at y=max threshold
        title(['Resting motor threshold, participant ',int2str(e.p)]);      % figure title
        xlabel('Trial number');                                             % x-axis label
        ylabel('Threshold (M±SD)');                                         % y-axis label
        disp('Testing resting motor threshold');                            % info on screen
    for m=1:numel(e.muscles)
        subplot(e.channels+1,1,m+1);                                        % muscle plot
            hold on;                                                        % hold all plotting
            h=gca;                                                          % get current axis
            set(h,'color',[.7 .7 .7]);                                      % set background to grey
            ylabel([e.musclelist{e.muscles(m)}]);                           % muscle name
    end
        subplot(e.channels+1,1,e.channels+1);                               % TMS plot
            hold on;                                                        % hold all plotting
            h=gca;                                                          % get current axis
            set(h,'color',[.7 .7 .7]);                                      % set background to grey
            ylabel('TMS');                                                  % TMS
            xlabel('Sample number');                                        % x label for all data
pause(e.pbi);                                                               % delay before first trial
e.start=GetSecs;
tic;

%% START THE THRESHOLD FINDER______________________________________________
for trial=1:e.trials
    
    %% CHECK FOR LOW EMG BACKGROUND ACTIVITY_______________________________
    s.startBackground();                                                    % start collecting
    trialstart=GetSecs;                                                     % set trial timer
    finish=s.IsDone;                                                        % check if session still running
    while ~finish                                                           % while still sampling...
        hl_tms_magstim_enable_rc(tms1);                                     % enable remote control
        hl_tms_magstim_arm(tms1);                                           % arm the TMS
        pause(0.25);                                                        % wait a little
        finish=s.IsDone;                                                    % check if session still running
    end
    emg=mean(abs(d(:,1:e.channels-1)),1);                                   % mean baseline data
    while max(emg)>e.emgthreshold                                           % while EMG is too high
        s.startBackground();                                                % start collecting
        start=GetSecs;                                                      % set start timer
        finish=s.IsDone;                                                    % check if session still running
        while ~finish                                                       % while still sampling...
            hl_tms_magstim_enable_rc(tms1);                                 % enable remote control
            hl_tms_magstim_arm(tms1);                                       % arm the TMS
            pause(0.25);                                                    % wait a little
            finish=s.IsDone;                                                % check if session still running
        end
        emg=mean(abs(d(:,1:e.channels-1)),1);                               % mean baseline data
    end
    
    %% GET COIL POSITION___________________________________________________
    
      
    %% SET TMS INTENSITY___________________________________________________
    threshold.level=QuestQuantile(threshold.q);                             % Recommended by Pelli (1987)
    threshold.level=round(threshold.level+(2.*e.TMSjitter.*rand(1)-e.TMSjitter));% add some variability up and down
    if threshold.level>threshold.max                                        % if threshold estimated as >max%
        threshold.level=threshold.max;                                      % set to max%
    elseif threshold.level<threshold.min                                    % if estimated to <min%
        threshold.level=threshold.min;                                      % set to min%
    end
    disp(['Trial: ',int2str(trial),' intensity: ',int2str(threshold.level),'%']);% on-screen progress
    
    %% INITIALISE TMS______________________________________________________
    hl_tms_magstim_flush(tms1);                                             % remove dangling bits
    hl_tms_magstim_enable_rc(tms1);                                         % enable remote control
    hl_tms_magstim_intensity(tms1,threshold.level);                         % set TMS intensity
    hl_tms_magstim_intensity_bi(tms1,0);                                    % set bistim intensity to zero
    hl_tms_magstim_interval_bi(tms1,0);                                     % set bistim delay to zero
    pause(0.3);                                                             % give a little time to adjust to new settings
    response=[];                                                            % clear and initialise variables
    A=NaN;                                                                  % collects intensity of first TMS machine
    B=NaN;                                                                  % collects intensity of second TMS machine
    T=NaN;                                                                  % collects the delay between two TMS pulses (BiStim)
    RC=NaN;                                                                 % collects the Remote Control status (0=no, 1=yes)
    ready=NaN;                                                              % collects ready status
    arm=NaN;                                                                % collects arming status
    n=0;                                                                    % for counting repetitions
    hl_tms_magstim_enable_rc(tms1);                                         % enable remote control
    hl_tms_magstim_arm(tms1);                                               % arm the TMS
    pause(0.3);                                                             % give a little time to adjust to new settings
    [response,A,B,T,RC,ready,arm,post]=hl_tms_magstim_get_status(tms1);     % get TMS status
      
    %% COLLECT DATA________________________________________________________
    while ready~=1                                                          % as long as TMS is not ready
        if n>1
            pause(0.45);                                                    % give it a break
        end
        hl_tms_magstim_enable_rc(tms1);                                     % enable remote control
        hl_tms_magstim_arm(tms1);                                           % arm the TMS
        [response,A,B,T,RC,ready,arm,post]=hl_tms_magstim_get_status(tms1); % keep checking
        n=n+1;                                                              % increment loop counter
    end
    s.startBackground();                                                    % start collecting data (variable onset)
    start=GetSecs;
    finish=GetSecs;
    while finish-start<e.triggerdelay
        finish=GetSecs;                                                     % wait for TMS delay
    end
    s2.outputSingleScan(1);                                                 % apply trigger vector
    finish=s.IsDone;                                                        % check if session still running
    while ~finish
        finish=s.IsDone;                                                    % check if session still running
        hl_tms_magstim_enable_rc(tms1);                                     % enable remote control
        hl_tms_magstim_arm(tms1);                                           % arm the TMS
        pause(0.1);                                                         % wait a bit
    end
    s2.outputSingleScan(0);                                                 % turn off trigger vector
    start=GetSecs;                                                          % set start timer (for ITI)
    tms=find(d(:,e.triggerchannel)>e.triggerthreshold,1);                   % find first sample above trigger threshold
    if isempty(tms)                                                         % if no trigger found
        tms=1;                                                              % default to sample 1
    end
    start=tms-(e.triggerdelay.*e.samplehz);
    if start<1
        start=1;
    end
    data(1:end-start+1,1:e.channels,trial)=[t(start:end),d(start:end,1:size(data,2)-2)];% store time and muscle data
    data(1:end-start+1,e.channels+1,trial)=d(start:end,e.triggerchannel);   % store trigger data

    %% MEASURE MEP_________________________________________________________
    for f=1:numel(e.muscles)                                                % for each muscle
        if online   
            meps(trial,f)=max(d(tms+e.mepwindow(1):tms+e.mepwindow(2),f))-min(d(tms+e.mepwindow(1):tms+e.mepwindow(2),f));% calculate and store MEP peak-to-peak amplitude
        end
    end
    if meps(trial,e.MEPchannel)>=e.MEPthreshold                             % if MEP > threshold
        e.plotcolour='g';                                                   % plot in green
        e.MEP=1;                                                            % record MEP
    else
        e.plotcolour='r';                                                   % plot in red
        e.MEP=0;                                                            % record no MEP
    end
    hl_tms_magstim_enable_rc(tms1);                                         % enable remote control
    hl_tms_magstim_arm(tms1);                                               % arm the TMS
    
    %% PLOT DATA___________________________________________________________
    figure(1);
    subplot(e.channels+1,1,1);                                              % upper plot = threshold
        plot(trial,threshold.level,[e.plotcolour,'+']);                     % plot + for the stimulus level tested
        plot(trial,QuestMean(threshold.q),[e.plotcolour,'o']);              % plot o for threshold mean
        plot([trial,trial],[QuestMean(threshold.q)-QuestSd(threshold.q),QuestMean(threshold.q)+QuestSd(threshold.q)],[e.plotcolour,'-']);% plot SD bars
        drawnow();                                                          % draw now!        
    hl_tms_magstim_enable_rc(tms1);                                         % enable remote control
    hl_tms_magstim_arm(tms1);                                               % arm the TMS
        for m=2:e.channels+1
            subplot(e.channels+1,1,m);                                      % for each available muscle
                plot(data(1:end-tms+1,m,trial),'b');                        % plot data
                drawnow;                                                    % draw now!
        end
    hl_tms_magstim_enable_rc(tms1);                                         % enable remote control
    hl_tms_magstim_arm(tms1);                                               % arm the TMS
    
    %% UPDATE QUEST DISTRIBUTION___________________________________________
    if trial>e.practice
        threshold.q=QuestUpdate(threshold.q,threshold.level,e.MEP);         % update QUEST with result of MEP
    end
    
    %% INFO FOR EXPERIMENTER_______________________________________________
    disp(['...TMS @sample: ',int2str(tms),'; MEP: ',num2str(meps(trial,1),3),'; threshold: ',num2str(QuestMean(threshold.q),2),'%']);% on-screen progress
    finish=GetSecs-start;                                                   % set finish timer
    time=e.iti+2.*rand(1,1)-1;                                              % how long to wait?
    while finish<time                                                       % while still waiting
        hl_tms_magstim_enable_rc(tms1);                                     % enable remote control
        hl_tms_magstim_arm(tms1);                                           % arm the TMS
        pause(0.25);                                                        % wait a little
        finish=GetSecs-trialstart;                                          % wait while data collected
    end    
end                                                                         % OF TRIAL LOOP

%% CLEAR UP AND SAVE_______________________________________________________
delete(lh);                                                                 % delete listener
hl_tms_magstim_close(tms1);                                                 % close TMS connection
%clear ans d f h n online t tms w;
e.file=['threshold_#',int2str(e.p),'_',e.timestring];                       % create filename
save(e.file);                                                               % save the file
h=gcf;                                                                      % get current axis
hgsave(h,e.file);                                                           % save the figure