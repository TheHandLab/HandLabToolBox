% resample a dataset, and plot distribution with the original mean values,
% returns the p-values associated with the mean across columns of the input data, and saves a figure of the distribution
% usage = bl_resample(data(2D), resample_type [, iterations] [,filename suffix for figure]);
% Data (cases as separate rows, conditions as separate columns)
% Resample type:
%  1: randomly resample with replacement within conditions (columns)
%  2: randomly resample with replacement across conditions (columns)
%  3: randomly resample with replacement within conditions (2 columns), then correlate between conditions
%  [a b]: distibution of pairwise differences between the two specified columns a - b, randomly resampling with replacement across conditions (columns)
% Iterations: optional, default is 10000
% Filename: optional suffix (e.g., if calling multiple times in same directory)
% options to come in the future...
% randomise data, but do not resample
% option to randomise by column (effect of condition) or row (effect of subject/session) - choose by size of input or parameter
function obs_p = bl_resample(d,r,j,f)
 if (nargin < 2 || nargin > 4)
  usage ('bl_resample(data, resample_type (1:within conditions, 2:across conditions, 3:correlation between 2 conditions, [a b] - pairwise difference between two specified columns), [,iterations (default:10000)], [, figure filename suffix])');
 end
 if nargin == 2	j = 10000; f = ''; end						% default = 10000 iterations
 if nargin == 3 f = ''; end							% default = no filename suffix
 if nargin == 4
  if size(j,1)==0 j=10000; end							% default j if j is empty
 end
 if rows(d) < 3
  error ('bl_resample: dataset is too small');					% need to specify at least 3 values per condition
 end
 if (length(r)==1 && (r < 1 || r > 3))
  error ('bl_resample: 2nd argument (randomisation) accepts only 1, 2, 3, or two column indices for paired differences [a b]'); % only 4 randomisation procedures
 end
 if length(r)==2								% set randomisation type
  if max(r) > columns(d)
   error ('bl_resample: one of the columns to randomise is larger than the number of columns in the data');
  end
  data = d(:,r);								% reduce data to selected columns
  randtype = 4;									% paired differences
 else
  data = d;									% retain all data
  randtype = r;									% unpaired differences
 end
 if randtype==3 && columns(d)>2
  error ('bl_resample: too many columns of data entered for 2nd argument (randomisation type=3: correlation)');
 end
 if j < 100
  warning('bl_resample: <100 iterations insufficient, defaulting to 100');	% <100 iterations is no good
  j = 100;
 end
 if j > 100000
  warning ('bl_resample: >100,000 iterations unnecessary, defaulting to 100,000');% >100000 is over-the-top
  j = 100000;
 end
 % configure parameters____________________________________________________________________________
 switch randtype
  case {1}
   obs_m = mean(data,1);							% observed means per condition
   obs_p = zeros(1,columns(data));						% output probabilities
   cases = rows(data);								% cases per condition
   results= zeros(j,2,columns(data));						% columns 1: Mean; 2: SD
  case {2}
   obs_m = mean(data,1);							% observed means per condition
   obs_p = zeros(1,columns(data));						% output probabilities
   cases = numel(data);								% total cases
   results= zeros(j,2);								% columns 1: Mean; 2: SD
  case {3}
   obs_m = corrcoef(data(:,1),data(:,2));					% correlation between columns
   obs_p = 0;									% output probability
   cases = rows(data);								% total cases
   results = zeros(j,1);							% output r-value
  case {4}
   obs_m = mean(data(:,1) - data(:,2));						% mean difference
   obs_p = 0;									% output probability
   cases = numel(data);								% total cases
   results= zeros(j,2);								% columns 1: Mean; 2: SD
 end
 % start the randomisation_________________________________________________________________________
 rand('state',sum(100*clock));               					% set the generator to a random state
 disp(['BioLab: Resampling data']);						% info
 disp('Completed:');								% soothing the wait
 for i = 1:j									% for each iteration
  if rem(i,(j./20)) == 0							% if divisible by 20
   disp([num2str((i./j).*100),'%']);						% print 5% progress marker to screen
  end
  switch randtype								% choose the randomisation type
   case {1} 									% resample within conditions
    for c = 1:columns(data);							% for each condition
     results(i,1,c) = mean(data(1+floor(cases.*rand(cases,1)),c));     		% mean of re-sample	
     results(i,2,c) =  std(data(1+floor(cases.*rand(cases,1)),c));		% SD of re-sample
    end
   case {2} 									% resample across conditions
    results(i,1) = mean(data(1+floor(cases*rand(cases,1))));			% mean of re-sample
    results(i,2) =  std(data(1+floor(cases*rand(cases,1))));			% SD of re-sample
   case {3}
    results(i) = corrcoef(data(1+floor(cases*rand(cases,1)),1),data(1+floor(cases*rand(cases,1)),2));% correlation of resample
   case {4} 									% resample between condition differences
    results(i,1) = mean(data(1+floor(cases*rand(cases,1)))-data(1+floor(cases*rand(cases,1))));% mean of re-sampled differences
    results(i,2) =  std(data(1+floor(cases*rand(cases,1)))-data(1+floor(cases*rand(cases,1))));% SD of re-sample    
   end										% end of randomisation type switch
 end % end of iteration loop
 for c = 1:columns(obs_m)							% for each observed mean
  switch randtype
   case {1 3}
    results(:,:,c) = sortrows(results(:,:,c),1);				% sort data by the means / correlations
    p = max(find(results(:,1,c) < obs_m(c)));					% resampled p-value
   case {2 4}
    results = sortrows(results,1);						% sort data by the means (or mean differences)
    p = max(find(results(:,1) < obs_m(c)));					% resampled p-value
  end  
  if isempty(p)
   obs_p(c) = 1;								% if obs_m is lowest value, then p=1
  else
   obs_p(c) = p; 								% else, obs_p = the iteration cutoff
  end									
 end
 obs_p = (obs_p./j);								% calculate p-value(s)
 switch randtype
  case {1}
   for c = 1:columns(data)
    bl_dist(results(:,1,c),obs_m,2.5); 						% plot the distribution
    print(['resampled_means_condition',int2str(c),'_',int2str(j),'i',f,'.gif'],'-dgif','-F:12');
   end
  case {2}
   bl_dist(results(:,1),obs_m,2.5); 						% plot the distribution
   print(['resampled_means_',int2str(j),'i',f,'.gif'],'-dgif','-F:12'); 
  case {3}
   bl_dist(results(:),obs_m,2.5); 						% plot the distribution
   print(['resampled_corrcoefs_',int2str(j),'i',f,'.gif'],'-dgif','-F:12');
  case {4}
   bl__dist(results(:,1),obs_m,2.5); 						% plot the distribution
   print(['resampled_differences_',int2str(j),'i',f,'.gif'],'-dgif','-F:12'); 
end										% end of switch and end of function