% get the time, save it as a string for saving data (to nearest minute)
% timestring=bl_timestring;
function timestring=bl_timestring
 starttime=clock;
 if starttime(2)<10
  month=['0',num2str(starttime(2))];
 else month=num2str(starttime(2));
 end
 if starttime(3)<10
  day=['0',num2str(starttime(3))];
 else day=num2str(starttime(3));  
 end
 if starttime(4)<10
  hour=['0',num2str(starttime(4))];
 else hour=num2str(starttime(4));  
 end
 if starttime(5)<10
  minute=['0',num2str(starttime(5))];
 else minute=num2str(starttime(5));  
 end
 timestring=[num2str(starttime(1)),'_',month,'_',day,'_',hour,'-',minute];
end