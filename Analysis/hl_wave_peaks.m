% measures peak amplitudes and latencies of a waveform (e.g. MEPs from electrical or magnetic nervous stimulation)
% Input=(data [,stimulus] [,baseline] [,duration] [, plot_wave])
%   A: data=1D-2D vector
%   B: stimulus (optional) default=0 samples
%   C: baseline prior to stimulus (optional) default=0 samples or stimulus duration, if two values, then the onset and offset sample, if three values, last specifies whether to subtract baseline (0=no, 1=yes)
%   D: duration (optional), default=from stimulus to max time after stimulus, if two values, then offset and onset sample after stimulus
%   E: plot_wave (optional), default=0(no)
%
% Outputs:
%   A: prestim structure containing measures of the baseline period, with fields:
%       .time - start of pre-stimulus period
%       .n    - number of samples
%       .mean - of baseline
%       .sd   - of baseline
%       .min  - of baseline
%       .max  - of baseline
%
%   B: peaks, with columns:
%       1: index (sample number)
%       2: amplitude
%       3: area under curve between start or previous peak and this peak
%       4: SD between start or previous peak and this peak
%       5: normalised amplitude in SDs (i.e. Z-value) relative to the pre-stimulus baseline (nan if no baseline specified)
%
% EXAMPLE: [prestim peaks]=hl_wave_peaks(data,100,[100 50],[20 50],0);
% - The baseline is measured from 100 to 50 samples before the stimulus
% - The stimulus is given at sample 100
% - The peaks are recorded between sample 20 and 50 after the stimulus
% - No figures are plotted

function [prestim peaks]=hl_wave_peaks(data,stimulus,baseline,duration,plot_wave)
    %% check input parameters______________________________________________
    if nargin==0                                                            % if no input parameters
        error('hl_wave_peaks: Too few input arguments (data [, stimulus] [, baseline] [, duration] [, plot_wave])');% give error
    else                                                                    % if some data sent...
        if size(data,1)==1                                                  % if data in one row
            data=data';                                                     % convert to one column
        end
        if size(data,1)<3                                                   % if data too short
            error('hl_wave_peaks: Input data too short (fewer than 3 rows)');% give error
        end
    end
    if nargin==1                                                            % data input only
        stimulus=0;                                                         % sample time of stimulus
        baseline=0;                                                         % default baseline samples
        duration=0;                                                         % default duration samples
        plot_wave=0;                                                        % default plot
    end
    if nargin==2                                                            % data and stimulus time input only
        baseline=0;                                                         % default baseline samples
        duration=0;                                                         % default duration samples
        plot_wave=0;                                                        % default plot
    end
    if nargin==3                                                            % data, stimulus time and baseline only
        duration=0;                                                         % default duration samples
        plot_wave=0;                                                        % default plot
    end
    if nargin==4                                                            % data, stimulus time, baseline and duration only
        plot_wave=0;                                                        % default plot
    end
    if nargin>5                                                             % too many input parameters
        error('hl_wave_peaks: Too many input arguments (data [, stimulus] [, baseline] [, duration] [, plot_wave])');
    end
    if isempty(stimulus)                                                    % if empty stimulus time passed
        stimulus=0;                                                         % set to default
    end    
    if isempty(baseline)                                                    % if empty baseline passed
        baseline=0;                                                         % set to default
    end
    if stimulus>0 & baseline==0                                             % if stimulus present, but no baseline
        baseline=stimulus;                                                  % default to stimulus time
    end
    if numel(baseline)>1                                                    % if 2 baseline arguments given
        if baseline(2)>baseline(1)
            baseline([1 2])=baseline([2 1]);                                % reverse order of baselien
        end
        if baseline(1)==0                                                   % if first is 0
            baseline(1)=1;                                                  % default to 1
        end
        if baseline(1)==baseline(2)                                         % if baseline 0 samples long
            baseline(2)=0;                                                  % set end of baseline to zero
            warning('hl_wave_peaks: Baseline end set to 0');                % give warning
        end
    end
    if isempty(duration)                                                    % if empty duration passed
        duration=0;                                                         % set to default
    end
    if duration<0                                                           % if duration negative
        duration=0;                                                         % set to default
        warning('hl_wave_peaks: Negative durations (arg 3) not allowed, set to 0)');% give warning
    end
    if numel(duration)>1
        if duration(2)>duration(1)                                          % first should be last time, second first
            duration([1 2])=duration([2 1]);                                % reverse order of baselien
        end
        if duration(1)==duration(2)                                         % if duration 0 samples long
            duration(2)=0;                                                  % set start of duration to zero
            warning('hl_wave_peaks: Duration start set to 0');              % give warning
        end        
    end
    if isempty(plot_wave)                                                   % if empty plot passed
        plot_wave=0;                                                        % set to default
    end
    if baseline>stimulus                                                    % if baseline is longer than pre-stimulus period
        error('hl_wave_peaks: Baseline period is longer than pre-stimulus period');% give error
    end
    samples=size(data,1);                                                   % samples=number of rows in data
    channels=size(data,2);                                                  % channels=number of rows
    npeaks=0;                                                               % initialise variable
    if numel(baseline)==1                                                   % if only 1 baseline argument
        if baseline==0                                                      % if no duration variable or 0 passed
            baseline=[stimulus 0];                                          % then use all available samples
        else
            baseline(2)=0;                                                  % fix to immediately before stimulus
        end
    end
    if numel(duration)==1
        if duration==0                                                      % if no duration variable or 0 passed
            duration=[samples-stimulus 0];                                  % then use all available samples
        else
            duration(2)=0;                                                  % fix to immediately after stimulus
        end
    end
    if duration(1)+stimulus>samples                                         % if duration requested too long
        warning('hl_wave_peaks: Duration too long, defaulting to max');     % give warning
        duration(1)=samples-stimulus;                                       % reset duration
    end
    if stimulus>samples-3
        error('hl_wave_peaks: Stimulus (arg 2) is too late to calculate peaks');% give error
    end
    
    %% create output variables_____________________________________________
    peaks=nan(samples,5,channels);                                          % define main output variable

    %% extract baseline data_______________________________________________
    if baseline(1)>0
        on=stimulus-baseline(1)+1;                                          % first input is start of baseline
        if numel(baseline)==2                                               % if a baseline off sample given
            off=stimulus-baseline(2)+1;                                     % second is end
        else            
            off=stimulus-1;                                                 % baseline end time
        end
        if on==0                                                            % in case 0
            on=1;                                                           % use first sample
        end
        prestim.time=on;                                                    % pre-stimulus time (used in plotting later)
        prestim.n=off-on+1;                                                 % pre-stimulus number of samples
        prestim.mean=mean(data(on:off,:));                                  % pre-stimulus baseline mean
        prestim.sd=std(data(on:off,:),0,1);                                 % pre-stimulus baseline SD
        [prestim.min,prestim.mint]=min(data(on:off,:),[],1);                % pre-stimulus baseline min
        [prestim.max,prestim.maxt]=max(data(on:off,:),[],1);                % pre-stimulus baseline max
        if numel(baseline)==3 && baseline(3)==1                             % remove baseline from data?
            for c=1:channels                                                % for each channel
                data(:,c)=data(:,c)-prestim.mean(c);                        % remove baseline from all data
            end
        end
    else
        prestim.time=1;                                                     % set to default
        prestim.n=0;                                                        % no samples
        prestim.mean=nan;                                                   % set to nan
        prestim.sd=nan;                                                     % set to nan
        prestim.min=nan;                                                    % set to nan
        prestim.mint=nan;                                                   % set to nan
        prestim.max=nan;                                                    % set to nan
        prestim.maxt=nan;                                                   % set to nan
    end
    
    %% differentiate data to find changes in direction of data_____________
    on=stimulus+duration(2);                                                % onset sample after stimulus
    off=stimulus+duration(1);                                               % offset sample after stimulus
    if on==0                                                                % in case 0
        on=1;                                                               % use first sample
    end    
    data2=diff(data(on:off,:))./abs(diff(data(on:off,:)));                  % find increasing(+1), decreasing(-1), static(0) periods
    %% extract peaks per channel of data___________________________________
    for c=1:channels                                                        % for each channel
        zc=find(abs(diff(data2(:,c)))>0);                                   % find transitions (zero-crossings) (+1 later to account for diff offset)
        zcs=size(zc,1);                                                     % number of zero-crossings
        if zcs>0                                                            % if some zero crossings found
            peaks(1:zcs,1,c)=zc+1;                                          % 1 LATENCY of peaks
            peaks(1:zcs,2,c)=data(zc+on,c);                                 % 2 AMPLITUDE of peaks
            peaks(1,3,c)=sum(abs(data(on:zc(1)+on,c)));                     % 3 AREA UNDER CURVE between start and first peak
            peaks(1,4,c)=std(data(on:zc(1)+on,c));                          % 4 SD between start and first peak
            if baseline(1)>0                                                % if baseline used
                if numel(baseline)==3 && baseline(3)==1                     % if baseline subtracted
                    peaks(:,5,c)=peaks(:,2,c)./prestim.sd(c);               % 5 AMPLITUDE RELATIVE to baseline SD
                else
                    peaks(:,5,c)=(peaks(:,2,c)-prestim.mean(c))./prestim.sd(c);% 5 AMPLITUDE RELATIVE to baseline SD
                end
            end
            for p=2:zcs                                                     % for each peak in the data
                peaks(p,3,c)=sum(abs(data(on+zc(p-1):on+zc(p),c)));         % 3 AREA UNDER CURVE between previous peak and this peak
                peaks(p,4,c)=std(data(on+zc(p-1):on+zc(p),c));              % 4 SD between previous peak and this peak
            end
            peaks(p+1,3,c)=sum(abs(data(on+zc(p):off,c)));                  % 3 AREA UNDER CURVE between last peak and end
            peaks(p+1,4,c)=std(data(on+zc(p):off,c));                       % 4 SD between last peak and end
            if zcs+1>npeaks                                                 % if more peaks than previously found
                npeaks=zcs+1;                                               % update number of peaks
            end
        else
            warning('hl_wave_peaks: No peaks found');                       % give warning
        end
        %% plot the wave___________________________________________________
        if plot_wave==1                                                     % if plotting...
            figure(c);                                                      % create figure for this channel
            subplot(3,1,1);                                                 % for all peaks
                plot(stimulus-1+duration(2)+peaks(1:zcs,1,c),peaks(1:zcs,2,c),'bo');% all peaks
                hold on;                                                    % over-write lines                
                z=find(abs(peaks(1:zcs,5,c))>=2.807);                       % peaks sig above baseline (p<=.005)
                plot(stimulus-1+duration(2)+peaks(z,1,c),peaks(z,2,c),'ro');% sig peaks amplitude vs latency
                plot(stimulus-baseline(1)+1:duration(1)+stimulus,data(prestim.time:off,c),'k-');% raw data
                if baseline(1)>0                                            % if baseline required
                    plot([stimulus-baseline(1)+1 stimulus-baseline(2)+1],[prestim.mean(c) prestim.mean(c)],'g-');% plot baseline mean
                    plot([stimulus-baseline(1)+1 stimulus-baseline(2)+1],[prestim.mean(c)+prestim.sd(c) prestim.mean(c)+prestim.sd(c)],'g:');% plot baseline mean+sd
                    plot([stimulus-baseline(1)+1 stimulus-baseline(2)+1],[prestim.mean(c)-prestim.sd(c) prestim.mean(c)-prestim.sd(c)],'g:');% plot baseline mean-sd
                end
                ylabel('Peaks');                                            % y-axis label
                axis([stimulus-baseline(1)+1 duration(1)+stimulus 0 1]);    % scale axis the same
                axis 'auto y';                                              % auto-scale y-axis                             
                hold off;                                                   % clear over-write
            subplot(3,1,2);                                                 % for area under curve
                plot(stimulus-1+duration(2)+peaks(1:zcs,1,c),peaks(1:zcs,3,c),'k-');% area vs latency
                hold on;                                                    % over-write lines                
                ylabel('Area under curve');                                 % y-axis label
                axis([stimulus-baseline(1)+1 duration(1)+stimulus 0 1]);    % scale axis the same
                axis 'auto y';                                              % auto-scale y-axis           
                hold off;                                                   % clear over-write                
            subplot(3,1,3);                                                 % for SD
                plot(stimulus-1+duration(2)+peaks(1:zcs,1,c),peaks(1:zcs,4,c),'k-');% SD vs latency
                hold on;                                                    % over-write lines                
                xlabel('Samples after stimulus');                           % x-axis label
                ylabel('SD between peaks');                                 % y-axis label
                axis([stimulus-baseline(1)+1 duration(1)+stimulus 0 1]);    % scale axis the same
                axis 'auto y';                                              % auto-scale y-axis
                hold off;                                                   % clear over-write                
        end                                                                 % end of plotting
    end                                                                     % end of channel
    peaks=peaks(1:npeaks,:,:);                                              % restrict output data to peaks
end                                                                         % end of function