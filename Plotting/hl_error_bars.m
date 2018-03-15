% bl_error_bars
% plot error bars (Y) for a series of 2D data points (X, Y) on the current axis
%Input: 	2D data, 1D lower error [, 1D upper error],[barwidth],[linestyle],[linewidth]
%Output:	error bars added to the current figure

function bl_error_bars(a,b,c,d,e,f) % 2D data, 1D lower error, [1D upper error],[barwidth],[linestyle],[linewidth]
 % configure variables_____________________________________________________________________________
 default_d=0.25;
 default_e='k-';
 default_f=2;
 switch nargin
  case {2}
   c=b; d=default_d; e=default_e; f=default_f;
  case {3}
   d=default_d; e=default_e; f=default_f;
  case {4};
   e=default_e; f=default_f;
  case {5};
   f=default_f;
  case {6};
  otherwise
   usage('bl_error_bars(2D data (X,Y), 1D lower error (Y) [, 1D upper error (Y) (default=lower)] [, barwidth (0-1, default=0.2)] [, linestyle (default=''k-'')] [, linewidth (default=2)])');
 end
 a=squeeze(a); b=squeeze(b); c=squeeze(c); d=squeeze(d);                    % remove singleton dimensions
 if ndims(a)~=2
  error('bl_error_bars: only 2D matrices (X, Y) accepted as input data');
 end
 if(min(size(c))==0) c=b;         end                                       % if present but empty upper error argument
 if(min(size(d))==0) d=default_d; end                                       % if present but empty bar width argument
 if(min(size(e))==0) e=default_e; end                                       % if present but empty linestyle argument
 if(min(size(f))==0) f=default_e; end                                       % if present but empty linewidth argument
 if ndims(b)~=2 || min(size(b))~=1 || ndims(c)~=2  || min(size(c))~=1
  error('bl_error_bars: accepts only 1D arrays (Y) for lower and upper error values');
 end
 if(size(a,1)==2 && size(a,2)>2) a=a'; end                                 % transpose matrix if only two rows
 if(size(b,1)==1 && size(b,2)>1) b=b'; end                                 % transpose matrix if only one row
 if(size(c,1)==1 && size(c,2)>1) c=c'; end                                 % transpose matrix if only one row
 %if(size(a,1)~=size(b,1) || size(a,1)~=size(c,1))
 % error('bl_error_bars: data (Y) and error (Y) vectors are not the same length');
 %end
 d=d.*((max(a(:,1))-min(a(:,1)))./size(a,1));
 % plot the bars___________________________________________________________________________________
 hold on;
 for n=1:size(a,1)
  plot([a(n,1) a(n,1)]        ,[(a(n,2)-b(n,1)) (a(n,2)+c(n,1))],e,'linewidth',f); % vertical bar
  plot([(a(n,1)-d) (a(n,1)+d)],[(a(n,2)-b(n,1)) (a(n,2)-b(n,1))],e,'linewidth',f); % lower horizontal bar
  plot([(a(n,1)-d) (a(n,1)+d)],[(a(n,2)+c(n,1)) (a(n,2)+c(n,1))],e,'linewidth',f); % upper horizontal bar
 end
 hold off;
end