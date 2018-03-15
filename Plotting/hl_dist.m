% bl_plot_dist
% plot distribution histogram of data, and mean, median, +/-1SD upper & lower cut-offs, optional observed value(s)
%Input: 	data in columns
%Output:	figure of the distribution

function bl_plot_dist(a,b,c);					% data, observed values, percent cut-off
 switch nargin
  case {1} b = []; c = 2.5;
  case {2}
   if(isempty(b)); b = [];
   else; c = 2.5;
   end;
  case {3};
  otherwise
   usage ("bl_plot_dist(2D data [, observed value(s), (default=[])] [,% cutoff (default=2.5)])");
 end;
 if(isempty(c)); c = 2.5; end;
 a = squeeze(a); b = squeeze(b);				% remove singleton dimensions
 
 if numel(a(:,1)) < 20;
  error("bl_plot_dist: data has less than 20 elements per column");
 end;
 if ndims(a) > 2;
  error("bl_plot_dist: accepts only 2D arrays/matrices");
 end;
 if (ndims(b) > 2 || min(size(b)) > 1);
  error("bl_plot_dist: accepts only 1D arrays for observed values");
 end;
 % configure parameters____________________________________________________________________________
 r = size(a,1);							% rows
 s = size(a,2);							% columns
 if(r == 1 && s > 1); a = a'; r = size(a,1); s = size(a,2); end;% transpose matrix if only one row
 if     r <   100; d = 10;					% select number of bins to use: 10 for small dataset
 elseif r <  1000; d = round(r./10);				% 10% of sample size for medium dataset
 else              d = 100;					% 100 bins for large dataset
 end;
 % extract data and plot it________________________________________________________________________
 disp('BioLab: plotting histogram of data');			% info
 for e = 1:s;							% repeat for each column of data
  a(:,e) = sortrows(a(:,e));					% sort data in ascending order
  [n x] = hist(a(:,e),d,100);					% get data for the histogram
  n_max = max(n);						% maximum frequency (for adding annotation)
  figure(); hist(a(:,e),d,100);					% plot histogram normalised to 100
  h = findobj(gca,'Type','patch');				% get handle for the figure
  hold on;							% plot all the following on one figure
  f = mean(a(:,e));						% mean of data
  g = median(a(:,e));						% median of data
  k = std(a(:,e));						% SD of data
  i = round(r.*(c./100));					% lower cut-off sample
  j = round(r.*(1-(c./100)));					% upper cut-off sample
  plot([f f],[0 n_max],'r-');					% solid red line for mean
  plot([g g],[0 n_max],'m-');					% magenta line for median
  plot([(f+k) (f+k)], [0 n_max],'r-');				% red line for mean+SD
  plot([(f-k) (f-k)], [0 n_max],'r-');				% red line for mean-SD
  plot([a(i,e) a(i,e)],[0 n_max],'c-');				% cyan line for lower cut-off
  plot([a(j,e) a(j,e)],[0 n_max],'c-');				% cyan line for upper cut-off
  if(isempty(b));
  else;
   plot(b,n_max,'gv');						% green triangle(s) for observed value(s)
   for m = 1:max(size(b));
    text(b(m),(n_max.*0.98),num2str(m),'color','g','fontsize',8);% label for observed value m
    p = (max(find(a(:,e) < b(m))) ./ r);			% get observed p-value
    if isempty(p); p = 1./r; end;				% if obs_m lower than lowest, p = 1/datapoints
    % add list of observed p-values to side of figure
    text(a(i,e)-(max(x)-min(x))./10,(n_max.*(0.98-(m./50))),['p(',num2str(m),')=',num2str(p,3)],'color','g');
   end;
  end;
  text(f,(n_max.*1.01),['mean ',num2str(f,3)],'color','r');	% label for mean
  text((f-k),(n_max.*1.04),'M-SD','color','r');			% label for M-SD
  text((f+k),(n_max.*1.04),'M+SD','color','r');			% label for M+SD
  text((f-k),(n_max.*1.01),num2str(f-k,3),'color','r');		% value for M-SD
  text((f+k),(n_max.*1.01),num2str(f+k,3),'color','r');		% label for M+SD
  text(g,(n_max.*1.04),['median ',num2str(g,3)],'color','m');	% value for median
  text(a(i,e),(n_max.*1.04),[num2str(c),'%'],'color','c');	% label for lower cut-off
  text(a(j,e),(n_max.*1.04),[num2str((100-c)),'%'],'color','c');% label for upper cut-off
  text(a(i,e),(n_max.*1.01),num2str(a(i,e),3),'color','c');	% value for lower cut-off
  text(a(j,e),(n_max.*1.01),num2str(a(j,e),3),'color','c');	% value for upper cut-off
  xlabel('Value');						% x-axis title
  ylabel('% of observations');					% y-axis title
  axis([a(1,e) a(r,e) 0 (n_max.*1.1)]);				% scale the axes
  hold off;
 end;
end;
