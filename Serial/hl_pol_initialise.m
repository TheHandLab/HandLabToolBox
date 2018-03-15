% initialise polhemus device
% last edit: 19/01/2011
if exist('polhemus')==0                     % open new serial port object, if polhemus doesn't exist
    hl_pol_open;
end
if exist('pol_device')==0
    pol.device='liberty';                   % default polhemus acquisition device
end
switch pol.device
    case {'fastrak'}
        fprintf(polhemus,'%c','u');         % change units to cm
        fprintf(polhemus,'O1,2,4,1');       % change output to: 2(x,y,z); 4(Az,El,Rl); 1(CR&LF)
        fprintf(polhemus,'O2,2,4,1'); 
        fprintf(polhemus,'O3,2,4,1'); 
        fprintf(polhemus,'O4,2,4,1'); 
        fprintf(polhemus,'H1,1,0,0');       % set hemispheres of operation
        fprintf(polhemus,'H2,1,0,0');
        fprintf(polhemus,'H3,1,0,0');
        fprintf(polhemus,'H4,1,0,0');
        pol.str_len=44;                     % minimum expected length of text line
        pol.data_len=7;                     % expected number of values
        pol.receivers=4;                    % available receivers
        
    case {'patriot'}
        fprintf(polhemus,'U1');             % change units to cm
        fprintf(polhemus,'O*,2,4,8,9,1');   % change output to: 2(x,y,z); 4(Az,El,Rl); 8(time); 9(frame); 1CR&LF
        fprintf(polhemus,'H*,0,0,-1');      % set hemisphere of operation
        %fprintf(polhemus,'H*,0,0,0');      % set to track the hemisphere
        pol.str_len=44;                     % minimum expected length of text line
        pol.data_len=10;                    % expected number of values
        pol.receivers=2;                    % available receivers
        pol.frequency=60;                   % recording frequency        
       
    case {'liberty'}
        fprintf(polhemus,'U1');             % change units to cm
        fprintf(polhemus,'O*,2,4,1');       % change output to: 2(x,y,z); 4(Az,El,Rl); 1(CR&LF)
        fprintf(polhemus,'H*,1,0,0');       % set hemispheres of operation
        pol.str_len=60;                     % minimum expected length of text line
        pol.data_len=7;                     % expected number of values
        pol.receivers=12;                   % available receivers      
        pol.frequency=240;                  % recording frequency        
end

if pol.device ~='liberty'
    fprintf(polhemus,'l1');                 % get status of the receivers
    a=fgetl(polhemus);
    for n=1:pol.receivers
        pol.receiver(n)=strread(a(end-pol.receivers+n));
    end
else
    fprintf(polhemus,'%c',21);                                              % get receiver status ^U
    fprintf(polhemus,'%c\r',48);                                            % 0
    [pol.present pol.active]=strread(fgetl(polhemus),'%*c %*2d %*3c %4d %4d');% get line and extract hex string
    pol.receiver(1:pol.receivers)=fliplr(dec2bin(hex2dec(num2str(pol.active)))-'0');% convert hex to binary, reverse, and store active receivers
end
if pol.device=='fastrak'
    pol.frequency=120./sum(pol.receiver);                                   % recording frequency
end
pol.data=zeros(pol.receivers,pol.data_len); % initialise pol.data variable
pol.receiverlist=find(pol.receiver==1);     % list of active trackers
pol.latency=0;                              % initialise pol.latency variable (time between request and data)
set(polhemus,'Timeout',5);                  % set timeout for communication with serial port
%__________________________________________________________________________
% Forward Hemisphere (+X) H1,1,0,0<>
% Back Hemisphere (-X) H1,-1,0,0<>
% Right Hemisphere (+Y) H1,0,1,0<> 
% Left Hemisphere (-Y) H1,0,-1,0<>
% Lower Hemisphere (+Z) H1,0,0,1<> 
% Upper Hemisphere (-Z) H1,0,0,-1<>