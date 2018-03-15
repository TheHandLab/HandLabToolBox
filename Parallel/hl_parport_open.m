% set up a parallel port, using all data lines
warning('off', 'daq:digitalio:adaptorobsolete');    % disable 2010b warning
parport=digitalio('parallel','LPT1');               % name the new port
hwinfo=daqhwinfo(parport);                          % get information about this port
parport_out=addline(parport,0:7,0,'out');           % add 8 data output lines to port 0
parport.Line(1).LineName='Pin1';                    % and name each one for easy reference
parport.Line(2).LineName='Pin2';
parport.Line(3).LineName='Pin3';
parport.Line(4).LineName='Pin4';
parport.Line(5).LineName='Pin5';
parport.Line(6).LineName='Pin6';
parport.Line(7).LineName='Pin7';
parport.Line(8).LineName='Pin8';

parport_in_ttl=addline(parport,0:3,1,'in');         % add 4 data lines to port 1 (ttl)
parport.Line(9).LineName='TTLin1';                  % and name each one for easy reference
parport.Line(10).LineName='TTLin2';
parport.Line(11).LineName='TTLin3';
parport.Line(12).LineName='TTLin4';

parport_out_ttl=addline(parport,0:3,2,'out');       % add 4 data lines to port 2 (ttl)
parport.Line(9).LineName='TTLout1';                 % and name each one for easy reference
parport.Line(10).LineName='TTLout2';
parport.Line(11).LineName='TTLout3';
parport.Line(12).LineName='TTLout4';
putvalue(parport_out,0);                            % clear the first port values
putvalue(parport_out_ttl,0);                        % and the second port values

% HELP_____________________________________________________________________
% WRITING DIGITAL VALUES TO THE PORT
% write single digital value across the 8 lines
% data=23; putvalue(parport,data);

% write single digital value to a single line
% putvalue(parport.Line(1:8),data);

% convert to binary vector before writing
% bvdata=dec2binvec(data,8); putvalue(dio,bvdata);

% or

% putvalue(dio.Line(1:8),bvdata);

% or

% bvdata=logical([1 1 1 0 1 0 0 0]); putvalue(dio,bvdata);

% READING DIGITAL VALUES FROM THE PORT_____________________________________
% portval=getvalue(parport);            % outputs all (8) lines
% lineval=getvalue(parport.Line(1:5));  % outputs chosen lines only
