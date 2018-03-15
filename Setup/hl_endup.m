%% standard end routines and variables for all lab experiments
%% SAVE DATA
if exist(e.dir)~=1                                                          % if directory not set
    e.dir=['HandLab\P',int2str(e.projnum),'_',e.projname,'\P',int2str(e.projnum),'_E',int2str(e.enum),'_',e.ename,'\data']; % set it
end
if isfield(e,'file')~=1                                                     % if filename not set
    if isstr(e.cond)                                                        % if condition is used as a string
        e.file=['P',int2str(e.projnum),'_E',int2str(e.enum),'_S',int2str(e.p),'_H',int2str(e.hid),'_',e.cond,'_',e.timestring]; % set it
    else                                                                    % if a number...
        e.file=['P',int2str(e.projnum),'_E',int2str(e.enum),'_S',int2str(e.p),'_H',int2str(e.hid),'_',int2str(e.cond),'_',e.timestring]; % set it
    end
end
save(['D:\',e.dir,'\raw\',e.file,'.mat']);                                  % save all variables to local drive

%% SAVE FIGURE(s)
for f=1:e.fignum.Number
    hgsave(f,['D:\',e.dir,'\raw\',e.file,'_fig',int2str(f),'.fig']);        % save figure to local drive
end