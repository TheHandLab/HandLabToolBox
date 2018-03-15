% bl_jackknife(data [,jack] [,n])
% resamples a parameter of a dataset by leaving out one of the datapoints on each iteration. The number of recomputations therefore equals the combinations of n in datapoints per column.
% data: minimum of 3 datapoints per column
% jack:
%  1: mean & of data (default)
%  2: SD of data
%  [a,b]: correlation between columns a and b
% n: number of datapoints to leave out to create each subsample (default = 1) NOT YET AVAILABLE
function jackknife=bl_jackknife(data,jack,n)
if nargin<1 || nargin>3 || isempty(data) usage('bl_jackknife(data [,jack] [,n])'); end
if nargin==1 || isempty(jack) jack=1; jacktype=jack; n=1; end
if nargin==2
 n=1;
 if length(jack)==1 && (jack==1 || jack==2) jacktype=jack; end
end
if nargin==3
 if length(jack)==1 && (jack==1 || jack==2) jacktype=jack; end
  if isempty(n) n=1; end
  if mod(n,1)~=0 n=floor(n); warning('bl_resample: 3rd argument (n) rounded down'); end
  if n==0 n=1; end
 end
end
if rows(data)==1 data=data'; warning('bl_jackknife: data transposed'); end
if rows(data)<3 && rows(data)<columns(data) error('bl_jackknife: too few datapoints'); end
if length(jack)==2 a=jack(1); b=jack(2); jacktype=3; end
if length(jack)>2 error('bl_jackknife: too many columns specified for correlation (2nd argument)'); end
if(jacktype<3) jackknife=zeros(rows(data),columns(data));			% create output variable
else jackknife=zeros(rows(data),1);						
end
switch jacktype
 case {1}									% mean of data
  for c=1:columns(data)								% for each column of data
   jackknife(1,c)=mean(data(2:end,c));						% leave out the first datapoint
   for r=2:rows(data)-1								% for 2nd to (n-1)th datapoint
    jackknife(r,c)=mean(data([1:r-1 r+1:end],c));				% leave out that datapoint
   end
   jackknife(rows(data),c)=mean(data(1:end-1,c));				% leave out the last datapoint
  end
 case {2}									% SD of data
  for c=1:columns(data)								% for each column of data
   jackknife(1,c)=std(data(2:end,c),0,1);					% leave out the first datapoint
   for r=2:rows(data)-1								% for 2nd to (n-1)th datapoint
    jackknife(r,c)=std(data([1:r-1 r+1:end],c),0,1);				% leave out that datapoint
   end
   jackknife(rows(data),c)=std(data(1:end-1,c),0,1);				% leave out the last datapoint
  end
 case {3}									% correlation coefficient
  jackknife(1)=corrcoef(data(2:end,a),data(2:end,b));				% leave out the first datapoint
  for r=2:rows(data)-1								% for 2nd to (n-1)th datapoint
   jackknife(r)=corrcoef(data([1:r-1 r+1:end],a),data([1:r-1 r+1:end],b));	% leave out that datapoint
  end
  jackknife(rows(data))=corrcoef(data(1:end-1,a),data(1:end-1,b));		% leave out the last datapoint
end