%% standard HandLab files and directories__________________________________
e.dir=['HandLab\P',int2str(e.projnum),'_',e.projname,'\P',int2str(e.projnum),'_E',int2str(e.enum),'_',e.ename,'\data'];
if isfield(e,'file')~=1                                                     % if filename not set
    if isstr(e.cond)                                                        % if condition is used as a string
        e.file=['P',int2str(e.projnum),'_E',int2str(e.enum),'_S',int2str(e.p),'_H',int2str(e.hid),'_',e.cond,'_',e.timestring]; % set it
    else                                                                    % if a number...
        e.file=['P',int2str(e.projnum),'_E',int2str(e.enum),'_S',int2str(e.p),'_H',int2str(e.hid),'_',int2str(e.cond),'_',e.timestring]; % set it
    end
end    
if ispc
    if exist(['C:\HandLab\P',int2str(e.projnum),'_',e.projname,'\P',int2str(e.projnum),'_E',int2str(e.enum),'_',e.ename])~=7
        if exist(['D:\HandLab\P',int2str(e.projnum),'_',e.projname,'\P',int2str(e.projnum),'_E',int2str(e.enum),'_',e.ename])~=7
        else
            cd (['D:\HandLab\P',int2str(e.projnum),'_',e.projname,'\P',int2str(e.projnum),'_E',int2str(e.enum),'_',e.ename]);
        end
    else
        cd (['C:\HandLab\P',int2str(e.projnum),'_',e.projname,'\P',int2str(e.projnum),'_E',int2str(e.enum),'_',e.ename]);
    end       
    
    if exist('data')~=7                                                 % if no data directory present
        mkdir('data');                                                  % make one
    end
    if exist('data\draft')~=7                                           % if no draft data directory present
        mkdir('data\draft');                                            % make one
    end
    if exist('data\group')~=7                                           % if no draft data directory present
        mkdir('data\group');                                            % make one
    end
    if exist('data\raw')~=7                                             % if no raw data directory present
        mkdir('data\raw');                                              % make one
    end
    if exist('data\processed')~=7                                       % if no processed data directory present
        mkdir('data\processed');                                        % make one
    end        
end