% post-hoc simulations for expts
% Inputs:
% 1: numbers of datapoints at which p-values were peeked: [n1; n2;... nm]
% 2: p-criterion used (0.05, 0.01)
% 3: (optional): number of iterations (defaults to 100,000)
%
% Outputs:
% 1 column for each of the following per row:
% 1: n in sample
% 2: false positive probability, 1-tail
% 3: false positive probability, 2-tails
% 4: theoretical critical t-value, 1-tail
% 5: theoretical critical t-value, 2-tails
% 6: actual critical t-value, 1-tail
% 7: actual critical t-value, 2-tails

function adjustedp=hl_p_stopping(levels,alpha,iterations)
	if nargin==0
		error('hl_p_stopping: No input arguments given');			% no arguments given
	elseif nargin==1
		warning('hl_p_stopping: No p-value input, defaulting to alpha=.05');	% no p-value given
		alpha=.05;
	elseif nargin==2
		iterations=100000;							% number of simulations
	end
	if size(levels,2)~=1 && size(levels,1)~=1
		error('hl_p_stopping: Input data wrong size: nx1 array required');	% wrong size data input
	end
	if size(levels,2)>size(levels,1)						% if wrong shape
		levels=levels';								% swap dims
	end
	ps=max(levels(:,1));								% max number of participants to simulate
	les=size(levels,1);								% number of levels
	data=randn(ps,iterations);							% create random data
	stats=zeros(iterations,5);							% summary statistics (mean, SD, t, 1-tailed sig, 2-tailed sig)
	adjustedp=nan(les,7);								% output data (n, 1-tail, 2-tail)
	adjustedp(:,1)=levels;								% save levels
	for l=1:les 									% for each level
		stats(:,1)=mean(data(1:levels(l),:),1);					% means up to each participant number
		stats(:,2)=std(data(1:levels(l),:),0,1)./sqrt(levels(l,1));		% SEs up to each participant number
		stats(:,3)=stats(:,1)./stats(:,2);					% t-value up to each part
		stats=sortrows(stats,3);						% sort rows by t-value
		for t=1:2
			sig=find(stats(:,3)>hl_t_thresh(levels(l,1),alpha,t));		% 'significant' samples
			stats(sig,3+t)=1;						% ones for significant samples
			adjustedp(l,t+1)=sum(stats(:,3+t))./iterations;			% percentage of simulations exceeding criterion
			adjustedp(l,t+3)=hl_t_thresh(levels(l,1),alpha,t);		% traditional 1-tailed t-threshold
			cutoff=iterations-((alpha.*iterations./t).^2./(iterations.*adjustedp(l,t+1)));% cutoff for this tail
			adjustedp(l,t+5)=stats(round(cutoff),3);			% actual t-threshold required		
		end
	end
end
