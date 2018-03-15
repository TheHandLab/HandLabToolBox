% serial port for robot requres 115200 bps, 8 data bits, no parity, 1
% stopbit, no flow control and the carriage return terminator 13
if ispc
    robot=serial('COM1');                                                   % windows
elseif isunix
    a=dir('/dev/ttyUSB*');                                                  % find USB port(s) 
    b=dir('/dev/ttyUSB1*');                                                 % port assignment 1
    if ~isempty(a) & ~isempty(b)
        if datenum(a.date)>datenum(b.date)                                      % if ttyUSB0 file last modified
            USBport='/dev/ttyUSB0';                                             % then assign ttyUSB0
        else                                                                    % if ttyUSB1 file last modified
            USBport='/dev/ttyUSB1';                                             % assign ttyUSB1
        end
    else
        if isempty(b)
            USBport='/dev/ttyUSB0';
        else
            USBport='/dev/ttyUSB1';
        end
    end
    robot=serial(['/dev/',a.name]);                                         % linux (and mac)
end
set(robot,'BaudRate',57600,'DataBits',8,'Parity','none','StopBits',1,'FlowControl','none','Terminator',13); % configure port
set(robot,'Timeout',5000);
fopen(robot);                                                               % open the connection
if isunix
    pp([2:9],[0 0 0 0 0 0 0 0],false,0,888);                                % turn off parallel port line 5
end



%Command 1-24 tells the robot to navigate the shortest path to the specified mushroom
%
%TiltUp = 0x20,         32 Tilts up, engages the mushrooms
%TiltCn = 0x21,         33 Neutral position (don't use)
%TiltDn = 0x22,         34 Tilts into non-engaged position needs to be in
%this position for rotation to be active
% 
%incrTilt = 0x30,       48 (don't use)
%decrTilt = 0x31,       49 (don't use)
% 
%nextPosition = 0x41,   65 increments position on wheel
%prevPosition = 0x40,   64 decremenets position wheel
% 
%stop = 0x50,           80 stop streaming of data
%start1K = 0x51,        81 start streaming at 1kHz
%start5h = 0x52,        82 start streaming at 500Hz
%start2h = 0x53,        83 start streaming at 250Hz

%When sending data the device sends 255 as a starting character for packet
%framing, followed by the number of proceeding bytes where the first is the
%command ID and the following is data. Data is sent in a 12 (16bit) big
%endian formation

%3 215 

% to combine them 