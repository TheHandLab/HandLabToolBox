% serial port for TMS MagStim control requres 9600 bps, 8 data bits, no parity, 1 stop bit, no flow control
% max 2 TMS devices
% variables machine1 and machine2 must be open and contain a string name of the tms machines (e.g., machine1='tms1';)
% COM ports defaul to 1 and 5 if the variable comports=[x,y]; does not exist
if exist('comports','var')==0                                                                                                   % if not declared
    comports=[1,5];                                                                                                             % default COM port addresses
end
if exist('machine1','var')==1                                                                                                   % if tms1 exists
    eval(['global ',machine1,';']);                                                                                             % declare global variable
    eval([machine1,'=serial(''COM',int2str(comports(1)),''');']);                                                               % upper TMS machine, red labels
    eval(['set(',machine1,',''BaudRate'',9600,''DataBits'',8,''Parity'',''none'',''StopBits'',1,''FlowControl'',''none'',''Timeout'',2);']);% open serial port object
    eval(['fopen(',machine1,');']);
end
if exist('machine2','var')==1                                                                                                   % if tms2 exists
    eval(['global ',machine2,';']);                                                                                             % declare global variable
    eval([machine2,'=serial(''COM',int2str(comports(2)),''');']);                                                               % upper TMS machine, red labels
    eval(['set(',machine2,',''BaudRate'',9600,''DataBits'',8,''Parity'',''none'',''StopBits'',1,''FlowControl'',''none'',''Timeout'',2);']);  % open serial port object
    eval(['fopen(',machine2,');']);
end