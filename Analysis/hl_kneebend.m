%% y=hl_kneebend(x,a,b,c[,d])
%% fits a two-straight-line model to data where a linear increase is expected after a flat plateau
%% INPUTS
%% x = single column of data
%% a = kneepoint of curve
%% b = intercept / plateau of curve
%% c = slope of curve
%% d = direction of slope: -1=before, 1=after the plateau; default=1
function y=hl_kneebend(x,a,b,c,d)
    if nargin==4 || isempty(d)                                              % if no direction argument is given
        d=1;
    end
    if abs(d)~=1                                                            % if non-unit direction, convert to unit, preserving sign
        d=d/abs(d);
    end
    if d==1
        y=b+double(x>a).*((x-a).*c);                                        % slope occurs after the plateau
    elseif d==-1
        y=b+double(x<a).*((x-a).*c);                                        % slope occurs before the plateau
    end
end