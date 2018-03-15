%% general 2IFC vibrotactile thresholding function (1 parameter at a time)
%% NI SESSION FOR TACTILE THRESHOLD EXPERIMENT
function [e,adaptor,standard,comparison,threshold]=hl_tactile(e,adaptor,standard,comparison,threshold,tms1)
    %% CHECK INPUTS____________________________________________________________________
    if nargin<5
        error('hl_tactile: not enough input arguments');                                % error message if not enough inputs
    end
    if ~isfield(e,'iri')                                                                % interval between last interval and response interval?
        e.iri=0;
    end
    if ~isfield(e,'mintrialt')                                                          % minimum trial duration
        e.mintrialt=0;
    end
    if ~isfield(e,'fmi')                                                                % feedback marker interval
        e.fmi=e.mi;
    end
    if ~isfield(e,'mii')                                                                % marker-interval interval
        e.mii=0;
    end
    
    %% EXPAND parameters to one per interval___________________________________________
    if numel(e.mi)==1
        e.mi=e.mi.*ones(2,1);                                                           % copy marker interval into both intervals
    end
    if numel(e.mii)==1
        e.mii=e.mii.*ones(2,1);                                                         % copy marker interval into both intervals
    end
    
    %% EXPAND parameters to one per trial______________________________________________
    if numel(e.iii)==1
        e.iii=e.iii.*ones(e.trials,1);                                                  % copy inter-interval-interval into all trial locations
    end
    
    %% CHECK length of parameters is one per trial_____________________________________
    if numel(e.iii)~=e.trials
        error('hl_tactile: wrong number of e.iii');                                     % error message if not enough inputs
    end
        
    
    %% SET UP NATIONAL INSTRUMENTS CARD _______________________________________________
    daq.reset;                                                                          % reset something
    daq.HardwareInfo.getInstance('DisableReferenceClockSynchronization',true);          % this disables reference clock synchronisation, an incompatibility between the PXI/PCI chassis, NI Card, and some clock
    s=daq.createSession('ni');                                                          % setup NIDAQ session and object
    s.addDigitalChannel('Dev1','Port0/Line0:1','OutputOnly');                           % digital output for LED 1&2
    s.addDigitalChannel('Dev1',['Port0/Line2:',int2str(numel(e.triggers)+1)],'OutputOnly');% digital output(s) for trigger(s)
    s.addDigitalChannel('Dev1','Port0/Line4:5','InputOnly');                            % digital input for pedals 1&2
    if numel(e.stimuli)>1                                                               % if there are multiple stimuli...
        chanout=s.addAnalogOutputChannel('Dev1',0:numel(e.stimuli)-1,'Voltage');        % add more than 1 analogue output channel (tactile stimuli)
    else                                                                                % if there's only one stimulus
        chanout=s.addAnalogOutputChannel('Dev1',0,'Voltage');                           % add 1 analogue output channel (tactile stimuli)
    end
    for n=1:numel(e.stimuli)                                                            % for each channel
        chanout(n).Range=[-10,10];                                                      % voltage range
    end
    s.Rate=e.samplehz;                                                                  % set sampling rate
    e.feedbackvector=zeros(int64((e.fmi.*4).*e.samplehz),e.channelsout);                % feedback vector
    e.feedbackvector(1:int64((e.fmi.*e.samplehz)),e.markers)=1;                         % first LED flash
    e.feedbackvector(int64((2.*e.fmi).*e.samplehz+1):int64((3.*e.fmi).*e.samplehz),e.markers)=1;% second LED flash
    
    %% SETUP THE EXPERIMENT____________________________________________________________
    figure('color',[.7 .7 .7]);                                                         % make a grey figure
    e.fignum=gcf;                                                                       % get number
    h=gca;                                                                              % get current axis
    set(h,'color',[.7 .7 .7]);                                                          % set background to grey
    hold on;                                                                            % hold all plotting
    axis([0,e.trials+1,0,threshold.range]);                                             % optimise axis
    plot([0,e.trials+1],[0,0],'k--');                                                   % draw black line at y=0
    plot([0,e.trials+1],[threshold.range,threshold.range],'k--');                       % draw black line at y=max
    title([num2str(e.intervals),' interval ',e.type,' ',e.task,', ',int2str(standard.Hz),'Hz; I: ',num2str(standard.I,3),'; dur: ',num2str(standard.t,3),'s, d: ',int2str(e.triggerdelay.*1000),'ms; ',e.cond]);% figure title
    xlabel('Trial number');                                                             % x-axis label
    ylabel('Threshold estimate (M±SD)');                                                % y-axis label
    pause(e.pbi);                                                                       % pause before experiment
    disp(['Testing ',e.task,' threshold']);                                             % info on screen
    t=0;                                                                                % start trials

    %% IF MAGSTIM TMS REMOTE CONTROL IS BEING USED_____________________________________
    if isfield(e,'tmsremote') && e.tmsremote==1
        hl_tms_magstim_enable_rc(tms1);                                                 % enable remote control
        e.TMSinit=e.tmsarray(1,:);                                                      % TMS parameters for the first trial
        hl_tms_magstim_initialise;                                                      % initialise TMS intensity and delay
    end
    
    %% START THE EXPERIMENT____________________________________________________________
    while t<e.trials                                                                    % until enough trials have been run
        t=t+1;                                                                          % increment trial number
        switch e.intervals
            case 1
                e.samples=int64((adaptor.t+e.mi(1)+e.mii(1)+e.i+e.iri+e.ri).*e.samplehz);% number of samples to acquire (length of threshold.output vector)
            case 2
                e.samples=int64((adaptor.t+sum(e.mi)+sum(e.mii)+e.i.*2+e.iii(t)+e.iri+e.ri).*e.samplehz);
        end

        %% IF MAGSTIM TMS REMOTE CONTROL IS BEING USED_________________________________
        if isfield(e,'tmsremote') && e.tmsremote==1
            [~,~,~,~,~,ready,~,~]=hl_tms_magstim_get_status(tms1);                      % get status, initialise control variables
            e.TMSinit=e.tmsarray(t,:);                                                  % TMS parameters for this trial
            hl_tms_magstim_enable_rc(tms1);                                             % enable remote control
            hl_tms_magstim_initialise;                                                  % set these parameters
            while ready~=1                                                              % arm until ready
                pause(0.05);                                                            % wait a bit
                hl_tms_magstim_enable_rc(tms1);                                         % enable remote control
                hl_tms_magstim_arm(tms1);                                               % arm
                [~,~,~,~,~,ready,~,~]=hl_tms_magstim_get_status(tms1);                  % get status, initialise control variables
            end
        end
        
        %% SET UP OUTPUT VECTOR FOR NI CARD____________________________________________
        threshold.output=zeros(e.samples,e.channelsout);                                % Output vector for NI session (Markers, Tactile stimuli, Triggers)
        if e.intervals==1                                                               % 1 INTERVAL
            if e.mi(1)>0                                                                % if first interval should be marked
                threshold.output(adaptor.s+1:int64((e.mi(1).*e.samplehz)),1)=1;         % first LED marker (channel 1)
            end
            threshold.output(end-int64((e.ri.*e.samplehz))+1:end-1,1:2)=1;              % BOTH LEDs DURING RESPONSE INTERVAL AT END (TURN OFF ON LAST SAMPLE)
        else                                                                            % 2 INTERVALS
            if e.mi(1)>0                                                                % if first interval should be marked
                threshold.output(adaptor.s+1:int64(adaptor.s+(e.mi(1).*e.samplehz)),1)=1;% first LED marker (channel 1)
            end
            if e.mi(2)>0                                                                % if second interval should be marked
                threshold.output(int64((adaptor.t+e.mi(1)+e.mii(1)+e.i+e.iii(t)).*e.samplehz+1):int64((adaptor.t+sum(e.mi)+e.mii(1)+e.i+e.iii(t)).*e.samplehz),2)=1;% second LED marker (channel 2)
            end
            threshold.output(end-int64((e.ri.*e.samplehz))+1:end-1,1:2)=1;              % BOTH LEDs DURING RESPONSE INTERVAL AT END (TURN OFF ON LAST SAMPLE)
        end
    
        %% GET RECOMMENDED INTENSITY FROM QUEST________________________________________
        if e.quest==1
            threshold.level=QuestQuantile(threshold.q);                                 % Recommended by Pelli (1987)
        end
        
        %% SET COMPARISON STIMULUS_____________________________________________________
        switch e.task
            case 'detection'                                                            % for single-stimulus detection experiments
                comparison.I=threshold.level;                                           % comparison stimulus intensity is same as threshold level
                if comparison.I<threshold.minI                                          % if intensity too low
                    comparison.I=threshold.minI;                                        % reset to minimum
                elseif comparison.I>threshold.maxI                                      % if intensity too high
                    comparison.I=threshold.maxI;                                        % reset to maximum
                end
                e.trialarray(t,4)=threshold.level;                                      % save level used
                standard.I=0;                                                           % standard stimulus is nothing
            case 'discrimination'                                                       % for 'discrimination' experiments
                switch e.variable                                                       % depending on the stimulus feature judged
                    case 'I'                                                            % find intensity discrimination thresholds
                        comparison.I=standard.I.*(1+threshold.level);                   % comparison stimulus intensity is 1.level times the standard stimulus intensity
                        if comparison.I<threshold.minI                                  % if intensity too low
                            comparison.I=threshold.minI;                                % reset to minimum
                        elseif comparison.I>threshold.maxI                              % if intensity too high
                            comparison.I=threshold.maxI;                                % reset to maximum
                        end
                        e.trialarray(t,4)=comparison.I;                                 % save target level
                    case 'Hz'                                                           % find frequency discrimination thresholds
                        comparison.Hz=standard.Hz.*(1+threshold.level);                 % comparison stimulus frequency is 1.level times the standard stimulus frequency
                        if comparison.Hz<threshold.minHz                                % if frequncy too low
                            comparison.Hz=threshold.minHz;                              % reset to minimum
                        elseif comparison.Hz>threshold.maxHz                            % if frequncy too high
                            comparison.Hz=threshold.maxHz;                              % reset to maximum
                        end
                        e.trialarray(t,4)=comparison.Hz;                                % save target level                    
                    case 't'                                                            % find duration discrimination thresholds
                        comparison.t=standard.t.*(1+threshold.level);                   % comparison stimulus duration is 1.level times the standard stimulus duration
                        if comparison.t<threshold.mint                                  % if duration too low
                            comparison.t=threshold.mint;                                % reset to minimum
                        elseif comparison.t>threshold.maxt                              % if duration too high
                            comparison.t=threshold.maxt;                                % reset to maximum
                        end
                        e.trialarray(t,4)=comparison.t;                                 % save target level
                end
        end

        %% CREATE THE STIMULI__________________________________________________________
        if adaptor.t>0
            adaptor.waveform=hl_tone(adaptor.Hz,e.samplehz,adaptor.t,adaptor.I);        % create the adaptor stimulus waveform
        end
        standard.waveform=hl_tone(standard.Hz,e.samplehz,standard.t,standard.I);        % create the standard stimulus waveform
        comparison.waveform=hl_tone(comparison.Hz,e.samplehz,comparison.t,comparison.I);% create the comparison stimulus waveform

        %% PUT ADAPTOR INTO OUTPUT VECTOR______________________________________________
        if adaptor.t>0
            threshold.output(1:adaptor.s,adaptor.stimulus)=adaptor.waveform;            % put adaptor into vector
        end
        
        %% CHOOSE TARGET INTERVAL (1 OR 2)_____________________________________________
        if e.trialarray(t,3)==1                                                         % comparison stimulus is in interval 1
            e.start1=round((adaptor.t+e.mi(1)+e.mii(1)+comparison.delay).*e.samplehz)+1;% start of comparison
            e.finish1=round(e.start1+comparison.t.*e.samplehz)-1;                       % finish of comparison
            threshold.output(e.start1:e.finish1,e.stimuli(1))=comparison.waveform;      % put comparison stimulus in target channel (interval 1)
            if e.intervals==2                                                           % if 2-IFC design
                e.start2=round((adaptor.t+sum(e.mi)+e.mii(1)+e.i+e.iii(t)+standard.delay).*e.samplehz)+1;% start of standard
                e.finish2=e.start2+round(standard.t.*e.samplehz)-1;                     % finish of standard
                threshold.output(e.start2:e.finish2,e.stimuli(1))=standard.waveform;    % standard stimulus
            end
            if numel(e.stimuli)==2 && standard.distractorI==1                           % if a simultaneous distractor stimulus is required
                threshold.output(e.start1:e.finish1,e.stimuli(2))=comparison.waveform;  % put distractor alongside comparison stimulus in distractor channel
                if e.intervals==2
                    threshold.output(e.start2:e.finish2,e.stimuli(2))=standard.waveform;% distractor alongside standard stimulus
                end
            end       
        else                                                                            % comparison stimulus is in interval 2
            e.start1=round((adaptor.t+e.mi(1)+e.mii(1)+standard.delay).*e.samplehz)+1;  % start of standard
            e.finish1=round(e.start1+standard.t.*e.samplehz)-1;                         % finish of standard
            threshold.output(e.start1:e.finish1,e.stimuli(1))=standard.waveform;        % standard stimulus
            if e.intervals==2                                                           % if 2-IFC design
                e.start2=round((adaptor.t+sum(e.mi)+e.mii(1)+e.i+e.iii(t)+comparison.delay).*e.samplehz)+1;% start of comparison
                e.finish2=round(e.start2+comparison.t.*e.samplehz)-1;                   % finish of comparison
                threshold.output(e.start2:e.finish2,e.stimuli(1))=comparison.waveform;  % comparison stimulus (target)
            end
            if numel(e.stimuli)==2 && standard.distractorI==1                           % if a simultaneous distractor stimulus is required
                threshold.output(e.start1:e.finish1,e.stimuli(2))=standard.waveform;    % distractor alongside standard stimulus
                if e.intervals==2
                    threshold.output(e.start2:e.finish2,e.stimuli(2))=standard.waveform;% distractor alongside comparison stimulus
                end
            end
        end
        
        %% ADD STIMULUS-TIMED TRIGGERS (e.g., for TMS, EMG, other hardware)____________
         if numel(e.triggers)>0                                                         % if there are triggers...
             for trig=1:numel(e.triggers)                                               % for each one
                 for i=1:e.intervals                                                    % and each interval
                     if e.triggerintervals(i)==1
                        f=(['threshold.output(round(e.start',int2str(i),'+(e.triggerdelay.*e.samplehz)):round(e.start',int2str(i),'+(e.triggerdelay+e.triggert).*e.samplehz)-1,e.triggers(trig))=e.triggerI;']);% function to set trigger(s) to trigger intensity level
                        eval(f);                                                        % run command
                     end
                 end
             end
         end
         
        %% CHECK THAT THE PEDALS ARE DOWN______________________________________________
        pedals=s.inputSingleScan;                                                       % check pedals
        while sum(pedals)~=2.*e.pedaldown                                               % while pedals are not both down
            pedals=s.inputSingleScan;                                                   % check pedals
            pause(0.1);                                                                 % tms requires attention every ~200ms
            
            %% MAINTAIN COMMUNICATION WITH TMS MACHINES________________________________
            if isfield(e,'tmsremote') && e.tmsremote==1
                hl_tms_magstim_enable_rc(tms1);                                         % enable remote control
                hl_tms_magstim_arm(tms1);                                               % arm
            end
        end

        %% QUEUE THE DATA ACQUISITION SESSION__________________________________________
        s.queueOutputData(threshold.output);                                            % queue data for DAQ card
        if isfield(e,'tmsremote') && e.tmsremote==1
            s.NotifyWhenDataAvailableExceeds=e.samples;                                 % process data when all is collected
            global ts d;                                                                % declare global variables
            ts=zeros(e.samples,1);                                                      % initialise time data
            d=zeros(e.samples,1);                                                       % initiliase data
            lh=addlistener(s,'DataAvailable',@hl_nidaq_callback);                       % listener event for background data            
        end
        start=GetSecs;                                                                  % time that trial started
        
        if isfield(e,'tmsremote') && e.tmsremote==1
            
            %% MAINTAIN COMMUNICATION WITH TMS MACHINES________________________________
            hl_tms_magstim_enable_rc(tms1);                                             % enable remote control
            hl_tms_magstim_arm(tms1);                                                   % arm
            s.startBackground;                                                          % start stimulus & response acquisition
            finish=s.IsDone;                                                            % check if session still running
            while ~finish                                                               % while still sampling...
                hl_tms_magstim_enable_rc(tms1);                                         % enable remote control
                hl_tms_magstim_arm(tms1);                                               % arm the TMS
                pause(0.203);                                                           % wait a little
                finish=s.IsDone;                                                        % check if session still running
            end
            threshold.input=d;                                                          % get data from callback function
        else
            
            %% PRESENT STIMULI AND COLLECT RESPONSES___________________________________
            threshold.input=s.startForeground;                                          % start stimulus & response acquisition
        
        end
        
        %% END COMMUNICATION WITH TMS MACHINES, RESET TO ZERO__________________________
        if isfield(e,'tmsremote') && e.tmsremote==1
            hl_tms_magstim_enable_rc(tms1);                                             % enable remote control
            hl_tms_magstim_disarm(tms1);                                                % disarm
            e.TMSinit=[0,0,0];                                                          % new settings
            hl_tms_magstim_initialise;                                                  % set these parameters
        end
        
        if ~isempty(e.responses)                                                        % if responses are required
            
            %% PROCESS INPUTS__________________________________________________________
            if e.intervals==1                                                           % if one-interval paradigm
                e.start3=round((adaptor.t+e.mi(1)+e.mii(1)+e.i).*e.samplehz);           % start of response period    
            else                                                                        % or 2 intervals
                e.start3=round((adaptor.t+sum(e.mi)+sum(e.mii)+e.i.*2+e.iii(t)).*e.samplehz);% start of response period
            end
            e.finish3=round(e.start3+e.ri.*e.samplehz-1);                               % finish of response period
            for r=e.responses
                response=find(threshold.input(e.start3:e.finish3,r)==e.pedalup,1);      % find first response per response channel
                if isempty(response)                                                    % if no responses
                    e.trialarray(t,4+r)=e.ri.*e.samplehz;                               % response is last sample in response period
                else
                    e.trialarray(t,4+r)=response;                                       % response sample
                end
                e.trialarray(t,6+r)=sum(threshold.input(e.start3:e.finish3,r));         % find sum of responses in that response channel (0=no responses)
            end
            [e.trialarray(t,9),e.trialarray(t,10)]=min(e.trialarray(t,4+e.responses));  % get RT and response channel
            if e.trialarray(t,5)==e.trialarray(t,6)                                     % if both RTs are the same
                if e.trialarray(t,7)~=e.trialarray(t,8)                                 % and if response rates are different
                    [~,e.trialarray(t,10)]=max(e.trialarray(t,6+e.responses));          % use response with most time taken
                    e.trialarray(t,12)=1;                                               % set trial as valid            
                else                                                                    % no response given
                    e.trialarray(t,12)=0;                                               % set trial as invalid
                end
            else                                                                        % use lowest RT response
                e.trialarray(t,12)=1;                                                   % set trial as valid
            end
            e.trialarray(t,9)=e.trialarray(t,9)./e.samplehz;                            % convert RT to seconds
            if e.trialarray(t,10)==e.trialarray(t,3)                                    % if response=target interval
                e.trialarray(t,11)=1;                                                   % code as correct
            else
                e.trialarray(t,11)=0;                                                   % code as incorrect
            end

            %% FEEDBACK FOR WRONG RESPONSE_____________________________________________
            if e.trialarray(t,11)==0 || e.trialarray(t,12)==0                           % if wrong response or trial invalid
                s.queueOutputData(e.feedbackvector);                                    % queue feedback for DAQ card
                s.startForeground;                                                      % start data processing
                e.plotcolour='r';                                                       % for plotting incorrect response
            else
                e.plotcolour='g';                                                       % for plotting correct response
            end

            %% UPDATE QUEST DISTRIBUTION_______________________________________________
            if e.quest==1
                if t>e.practice                                                         % allow practice trials per block
                    if e.trialarray(t,12)==1                                            % if trial is valid...
                        threshold.q=QuestUpdate(threshold.q,threshold.level,e.trialarray(t,11));% Update the pdf with new datum (actual test intensity and observer response)
                    end
                end
                e.trialarray(t,13)=QuestMean(threshold.q);                              % Recommended by Pelli (1989) and King-Smith et al. (1994). Still our favorite.
                e.trialarray(t,14)=QuestSd(threshold.q);                                % also
            end

            %% DISPLAY RESULT ON SCREEN________________________________________________
            f=['Trial: ',int2str(t),', level: ',num2str(threshold.level,3),', d: ',int2str(e.triggerdelay.*1000),'ms'];% build command to display information
            if numel(e.iii)>1
                f=[f,', iii: ',num2str(e.iii(t),3),'s'];                                % inter-interval interval
            end
            if e.trialarray(t,12)==0                                                    % if trial was invalid
                f=[f,', invalid'];
            else                                                                        % if trial was valid
                f=[f,', valid'];
            end
            if e.trialarray(t,11)==0                                                    % if trial was incorrect
                f=[f,', incorrect'];
            else                                                                        % if trial was correct
                f=[f,', correct'];
            end
            if e.quest==1
                f=[f,', threshold: ',num2str(e.trialarray(t,13),3),'±',num2str(e.trialarray(t,14),3)];%
            end
            disp(f);                                                                    % info on screen
            
            %% PLOT FIGURE_____________________________________________________________
            if e.trialarray(t,12)==1                                                    % if a valid trial
                figure(e.fignum);                                                       % switch to the figure
                plot(t,threshold.level,[e.plotcolour,'+']);                             % plot + for the stimulus level tested
                plot(t,e.trialarray(t,13),[e.plotcolour,'o']);                          % plot o for threshold mean
                plot([t,t],[e.trialarray(t,13)-e.trialarray(t,14),e.trialarray(t,13)+e.trialarray(t,14)],[e.plotcolour,'-']);% plot SD bars
                drawnow();                                                              % draw now!
                axis 'auto y';                                                          % re-scale y-axis if needed
            else                                                                        % if an invalid trial
                t=t-1;                                                                  % re-run this trial
            end
        end
        
        %% WAIT FOR NEXT TRIAL_________________________________________________________
        while GetSecs-start<e.mintrialt                                                 % while the trial still needs to run...
        end        
        pause(e.iti);                                                                   % wait before beginning next trial
    end                                                                                 % end of trial
    
    %% FINISH__________________________________________________________________________
    figure(e.fignum);                                                                   % go to figure
    a=axis;                                                                             % get axis limits
    switch e.quest
        case 0
            disp([int2str(nansum(e.trialarray(:,11)==1)), ' correct; ',int2str(nansum(e.trialarray(:,11)==0)),' incorrect; (',int2str(100*(nansum(e.trialarray(:,11)==1)./nansum(isfinite(e.trialarray(:,11))))),'%)']);
        case 1
            text(e.trials-4,0.95.*a(4),['Threshold: ',num2str(e.trialarray(t,13),3),' +- ',num2str(e.trialarray(t,14),3)]);% write threshold on figure
            disp(['Threshold: ',num2str(e.trialarray(t,13),3),' +- ',num2str(e.trialarray(t,14),3)]);% display on screen
    end
    if isfield(e,'tmsremote') && e.tmsremote==1
        hl_tms_magstim_close(tms1);                                                     % end serial port session with TMS
    end
end                                                                                     % end of function