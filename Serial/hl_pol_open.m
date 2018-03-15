% serial port for polhemus requres 115200 bps, 8 data bits, no parity, 1
% stopbit, no flow control and the carriage return terminator 13
polhemus=serial('COM3');
set(polhemus,'BaudRate',115200,'DataBits',8,'Parity','none','StopBits',1,'FlowControl','none','Terminator',13);
fopen(polhemus);