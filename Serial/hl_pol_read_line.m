% read a line from polhemus device
switch pol.device                                                           % get a line of text
    case {'liberty'}
        pol.line=strread(fgetl(polhemus));
        pol.data(pol.line(1),1:pol.data_len)=pol.line(1:pol.data_len);
    case {'patriot'}
        [pol.data(pol.n,1) a pol.data(pol.n,2) pol.data(pol.n,3) pol.data(pol.n,4) pol.data(pol.n,5) pol.data(pol.n,6) pol.data(pol.n,7) pol.data(pol.n,8) pol.data(pol.n,9) pol.data(pol.n,10)]=strread(fgetl(polhemus), '%u %c %6.2f %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f');
    case {'fastrak'}
        c=textscan(fgetl(polhemus),'%u %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f');% read into a cell array c
        pol.data(pol.n,1)=c{1};                                              % read each cell
        pol.data(pol.n,2)=c{2};
        pol.data(pol.n,3)=c{3};
        pol.data(pol.n,4)=c{4};
        pol.data(pol.n,5)=c{5};
        pol.data(pol.n,6)=c{6};
        pol.data(pol.n,7)=c{7};
end