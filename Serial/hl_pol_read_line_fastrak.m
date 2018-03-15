% read a line from polhemus device     % fastrak device
c=textscan(fgetl(polhemus),'%u %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f');% read into a cell array c
if ~isempty(c{1})
    pol.data(pol.n,1)=c{1}; % read cell 1: tracker number
end
if ~isempty(c{2})
    pol.data(pol.n,2)=c{2};     % x
end
if ~isempty(c{3})
    pol.data(pol.n,3)=c{3};     % y
end
if ~isempty(c{4})
    pol.data(pol.n,4)=c{4};     % z
end
if ~isempty(c{5})
    pol.data(pol.n,5)=c{5};     % azimuth
end
if ~isempty(c{6})
    pol.data(pol.n,6)=c{6};     % orientation
end
if ~isempty(c{7})
    pol.data(pol.n,7)=c{7};     % roll
end