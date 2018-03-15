%% AUDITORY SETTINGS (AUDITORY STIMULI AND VOCAL RESPONSES)
vocal.samplehz=8000;                                                        % vocal recording frequency
vocal.duration=1;							    % recording duration in seconds
vocal.filter=1000;                                                          % low-pass cutoff for filter
vocal.Z=3.09;								    % Z-value cutoff to define RT
[vocal.B vocal.A]=butter(2,vocal.filter./(vocal.samplehz./2),'low');        % response filter (low-pass)
vocal.baseline=[0.125 100];                                                 % baseline period in ms
vocal.baseline_samples=vocal.baseline.*auditory.samplehz./1000;             % convert to samples
vocal.onset_SDs=10;                                                         % SDs from baseline mean for response onset
data=zeros(e.trial_len.*auditory.samplehz,1);             		    % matrix to store vocal response data
rectified=zeros(vocal.duration.*vocal.samplehz,1);                          % rectified vocal data
filtered=zeros(vocal.duration.*vocal.samplehz,1);                           % filtered vocal data

%% RECORD VOICE AND PRESENT STIMULI
% CHANGE THIS TO USE audiorecorder in Matlab - very easy...
%data(:,1)=input;                                                            % save vocal data data
data(:,1)=data(:,1)-mean(data(1:vocal.baseline_samples,1));   		    % subtract baseline
rectified(:,1)=squeeze(abs(data(:,1)));                                     % rectify vocal data
filtered(:,1)=filtfilt(vocal.B,vocal.A,rectified(:,1));                     % low-pass filter vocal data

%% FIND RT
vocal.baselinemean=mean(filtered(vocal.baseline_samples,1));               % measure the mean of the baseline
vocal.baselinesd=std(filtered(vocal.baseline_samples,1));                  % measure the SD of the baseline
vocal.criterion=vocal.baselinemean+(vocal.baselinesd.*vocal.Z;             % response criterion
start=vocal.baseline_samples+1;                                            % where to start looking for reaction time
RT=find(filtered(start+1:end,1)>vocal.criterion,1)+start;                  % find first sample above threshold
if size(RT,1)==0
   RT=vocal.duration.*vocal.samplehz;					   % defaults to max if no RT found
end

%% PLOT DATA FOR THIS TRIAL
yrange=[0 0.5];								   % y=axis range
plot(filtered(:,1));                                                       % vocal data
hold on;
ylabel('Vocal');
plot([vocal.baseline_samples(1) vocal.baseline_samples(1)],[yrange],'k:'); % start of baseline
plot([vocal.baseline_samples(2) vocal.baseline_samples(2)],[yrange],'k:'); % end of baseline
plot([1 vocal.duration.*vocal.samplehz],[vocal.baselinemean vocal.baselinemean],'k-');% mean baseline level
plot([1 vocal.duration.*vocal.samplehz],[vocal.criterion vocal.criterion],'r-');% threshold level
plot([start start],[yrange],'g:');                                         % RT search begins here
plot([RT RT],[yrange],'g-');                                               % RT found here
axis([1 vocal.duration.*vocal.samplehz yrange]);		           % reset axis
hold off;    
drawnow();
