% critical t = hl_t_thresh(df,p,tails)
% INPUTS
% df:    degrees of freedom (e.g., datapoints-1)
% p:     alpha (p-value) for test, default = 0.05
%        choose from: .05, .01, .005, .001, .0005, .0001
% tails: tails: 1 or 2, default=2
% OUTPUT
% critical_t: critical t-value
function critical_t = hl_t_thresh(df,p,tails)
 if nargin==1
  p=0.05;
  tails=2;
 end
 if nargin==2
  tails=2;
 end
 if nargin<1 || nargin>3
  error('hl_t_thresh(df,p,tails): incorrect number of input arguments');
 end
 if df<1
  error('hl_t_thresh(df,p,tails): degrees of freedom must be 1 or more');
 end
 if tails~=1 && tails~=2
  error('hl_t_thresh(df,p,tails): tails must be either 1 or 2)');
 end 
 switch p                                                                   % convert p-values to indices
  case {0.05};   a=1;
  case {0.01};   a=2;
  case {0.005};  a=3;
  case {0.001};  a=4;
  case {0.0005}; a=5;
  case {0.0001}; a=6;
  otherwise
   a=1;
   warning('hl_t_thresh: non-standard alpha value entered, alpha set to .05');
 end
 load('hl_t_thresh.mat');
 critical_t=t_thresh(df,a,tails);
end
