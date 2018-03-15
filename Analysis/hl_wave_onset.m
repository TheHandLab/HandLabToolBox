% Finds per column the onset of a waveform, from a baseline rising to a peak (e.g., BOLD, EEG, EMG, EOG, kinematic)
% Parameters:
% 1. data
% 2. sample_hz
% 3. baseline_onset (ms)
% 4. baseline_length (ms)
% 5. event_onset (ms)
% 6. plot_solutions (optional, 0 = no, 1 = yes)
% . event_type (0 = stimulus, 1 = response)
% . cost_function (min(RMS))
%
% Outputs:
% 1. Time in ms after event that first changed from baseline via numerous techniques:
%    A) Best two linear regression lines from: a) event onset to wave onset; b) wave onset to wave peak, using minimum RMS, following the 1df method (e.g., [Mordkoff JT, & Gianaros PJ (2000). Detecting the onset of the lateralized readiness potential: A comparison of available methods and procedures. Psychophysiol, 37:347–360.])
% 2-4) Difference in baseline SDs from mean (1.64,2.33,3.09, corresponding to 95.0%,99.0%,99.9% p-levels)
% 5) Projection of the 75% & 25% max peak points onto the time-axis [Veerman MM, Brenner E, & Smeets JBJ (2008). The latency for correcting a movement depends on the visual attribute that defines the target. Exp Brain Res, 187:219-228.]

function [on_1df, on_prob, on_2575] = bl_wave_onset(data, sample_hz, base_on, base_len, event_on, plot_solutions);
 warning("off","Octave:matlab-incompatible");
 if (nargin < 5 || nargin > 6);
  usage ("bl_wave_onset(data, sample_hz, baseline_onset, baseline_length, event_onset)");
 end;
 if nargin == 5; plot_solutions = 0; end;				% default = don't plot the data
 on_1df  	= 0;							% 1-d.o.f segmented regression output
 on_prob 	= 0;							% onset from SDs from mean (95%, 99%, 99.9%)	
 on_2575 	= 0;							% onset from 25 & 75% of baseline to peak
 sd_thresh 	= [1.645 2.326 3.090];					% Z-values for probability thresholds
 if isvector(data);
  if size(data,1) == 1; data = shiftdim(data,1); end;			% transpose data matrix into columns
  samples 	= size(data,1);						% number of samples
  data_sd 	= zeros(size(data,1),size(data,2));			% for holding SD data
  on_stats 	= zeros(samples,3,size(data,2)); 			% 1: RMS to-break; 2: RMS from break; 3: RMS sum
  base_on 	= round(base_on./(1000./sample_hz));			% convert ms to sample numbers
  if base_on == 0;  base_on = 1; end;					% avoid n=0th sample
  base_len 	= round(base_len./(1000./sample_hz));			% convert ms to sample numbers
  if base_len == 0; base_len = 1; end;					% avoid 0 samples
  event_on 	= round(event_on./(1000./sample_hz));			% convert ms to sample numbers
  if event_on == 0; event_on = 1; end; 					% avoid n=0th sample

  % for each column of data________________________________________________________________________
  for n = 1:size(data,2);
   base_mean          = mean(data(base_on:base_on+base_len-1,n));	% baseline mean
   base_sd   	      =  std(data(base_on:base_on+base_len-1,n),0,1);	% baseline SD
   data(:,n) 	      = data(:,n)-base_mean;				% subtract baseline
   data_sd(:,n)	      = data(:,n)./base_sd;				% convert data to SD
   [max_x max_samp]   = max(abs(data(event_on:end,n))); max_samp = max_samp+event_on-1;% find waveform peak
   [peak_25 peak_25x] = min(abs(data(event_on:max_samp,n)-(0.25*max_x)));% 25% point
   [peak_75 peak_75x] = min(abs(data(event_on:max_samp,n)-(0.75*max_x)));% 75% point
   if peak_25x == peak_75x; peak_75x = peak_75x+1; end;			% prevent divisions by zero

   % find RMS for segments before & after all possible breakpoints_________________________________
   for s = event_on:max_samp-1;						% for each sample
    on_stats(s,1) =rms(data(event_on:s),n);				% RMS of event_onset to s
    fit 	  =data(max_samp,n).*shiftdim(([0:1/(max_samp-s):1]),1);% straight line from s to peak
    on_stats(s,2) =rms(data(s+1:max_samp,n)-fit(2:end));		% RMS of (data-straight line), from s to peak
   end;
   on_stats(:,3)  = sum(on_stats(:,1:2),2);				% sum of RMS for all models

   % find breakpoint that minimises RMS across the two segments____________________________________
   min_rms   = min(on_stats(event_on:max_samp-1,3));			% find min-RMS breakpoint
   on_1df(n) = min(find(on_stats(:,3)==min_rms));			% find first sample with this RMS
   on_1df(n) = (on_1df(n)-event_on+1).*(1000./sample_hz);		% SOLUTION 1

   % SOLUTIONS 2-4_________________________________________________________________________________
   on_prob(1) = (min(find(abs(data_sd(event_on:end,n)) >= sd_thresh(1))) + event_on-1).*(1000/sample_hz); % 95%
   on_prob(2) = (min(find(abs(data_sd(event_on:end,n)) >= sd_thresh(2))) + event_on-1).*(1000/sample_hz); % 99%
   on_prob(3) = (min(find(abs(data_sd(event_on:end,n)) >= sd_thresh(3))) + event_on-1).*(1000/sample_hz); % 99.9%

   % SOLUTION 5____________________________________________________________________________________
   slope      =(data(peak_75x,n)-data(peak_25x,n))./(peak_75x-peak_25x);% slope between 25 & 75% points
   intercept  = data(peak_25x,n)-slope.*peak_25x;			% intercept with y-axis (data)
   on_2575(n) = (-intercept./slope).*(1000./sample_hz);			% intercept with x-axis (time)

   % plot data if required_________________________________________________________________________
   if plot_solutions == 1;
    figure;
     hold on;
     plot(data(event_on:max_samp,n),'b-');				% data between event and peak
     plot(event_on,data(event_on,n),'go');				% event onset
     plot(on_stats(event_on:max_samp-1,3)./(sample_hz./1000),'r-');	% plot RMS for all breakpoints
     plot(event_on + on_1df(n), data(event_on + (on_1df(n).*(sample_hz./1000)),n),'gs');% plot 1 d.o.f onset
   end;  

  end; % end of column loop
 else; error("bl_wave_onset: expecting vector argument");		% if data is not a vector
 end;
end;
