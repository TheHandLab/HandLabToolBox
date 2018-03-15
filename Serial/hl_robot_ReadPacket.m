function packet = hl_robot_ReadPacket(robot)

startflag = 0;
while startflag == 0    
    A = fread(robot, 1);
    if(A == 255)
    startflag = 1;
    end
end

    numbytes = fread(robot, 1);                                             %Number of bytes (61)
    command = fread(robot,1);                                               %CommandID (1 not used)
    
    data = fread(robot, numbytes-1);                                        %Read actual data
    packet = zeros(((numbytes-1)/2),1);                                     %Start empty packet
    
    for i = 1 : 2 : (numbytes-1)                                            %cycle through data and format
         packet((i+1)/2) = data(i)*256 + data(i+1);
    end
end