% function [data trigger settings]=bl_powerlab_import(filename,columns [,rows])
% INPUTS
% filename = raw data file name
% columns = columns of floating point data (e.g., 2-17, including time)
% rows (optional, if specified will speed up import, can be approximate)
% OUTPUTS
% data = columns of data, first one may be the time
% trigger = data input port readings
% settings = structure with sampling frequency, date, time, channel titles & ranges
function [data trigger settings]=bl_powerlab_import(filename,columns,rows)
 if nargin==2 || isempty(rows)
  rows=10000;
 end
 fid=fopen(filename);                                                        % open file for reading
 formatstringtitles='';
 formatstringranges='';
 formatstringdata='';
 outputstring='';
 chunksize=250000;                                                          % how large can a single chunk of the file be for reading (prevents fopen errors)
 trigger=uint32(zeros(chunksize,8));
 for n=1:columns-1
  formatstringtitles=[formatstringtitles,'%s'];                             % create titles input format (number of columns)
  formatstringranges=[formatstringranges,'%10c'];                           % create titles input format (number of columns)
 end
 for n=1:columns  
  formatstringdata=[formatstringdata,'%f '];                                % create data input format (number of columns)
 end
 C=textscan(fid,'%s',1);                                                    % read first string in file
 if strcmp(C{1},'Interval=')                                                % if it is 'Interval='...
  C=textscan(fid,['%f %*2c\nExcelDateTime=%*f %s %s %*c\n TimeFormat=%s %*c\n ChannelTitle=',formatstringtitles,' %*c\n Range=',formatstringranges]);% scan settings data
  settings.interval=C{1};                                                   % sampling interval (1/sample_hz)
  settings.date=cell2mat(C{2});                                             % date of data acquisition
  settings.time=cell2mat(C{3});                                             % time of data acquisition
  settings.timeformat=cell2mat(C{4});                                       % what date and time refer to
  for n=1:columns-1                                                         % column titles (not for time)
   settings.channeltitles(n)=C{4+n};                                        % each column title, 5th to 4+nth datapoint
  end
  for n=1:columns-1                                                         % range (not for time)
   settings.channelranges(n,:)=C{4+n+columns-1};                            % each channel range
  end
 else
  frewind(fid);                                                             % go back to start of file
  settings='';                                                              % no settings recorded
 end
 formatstringdata=[formatstringdata,'%*s%u %*s%u %*s%u %*s%u %*s%u %*s%u %*s%u %*s%u'];
 n=1;                                                                       % for first chunk
 while ~feof(fid)                                                           % until the end of the file is reached...
  outputcell=textscan(fid,formatstringdata,chunksize);                      % import data & any samples with up to 8 trigger bits
  datalength=size(outputcell{1},1);                                         % how many datapoints in this chunk?
  for c=1:columns                                                           % for each column of data
   data((n-1).*chunksize+1:(n-1).*chunksize+datalength,c)=outputcell{c};    % convert data into a matrix
  end
  for c=columns+1:columns+8
   trigger(((n-1).*chunksize)+1:((n-1).*chunksize)+datalength,c-columns)=outputcell{c}; % triggers
  end
  n=n+1;                                                                    % for next chunk
 end
 fclose(fid);
 if chunksize.*n<1000000
  %trigger=sum(trigger,2);                                                   % crashes with large files
 end