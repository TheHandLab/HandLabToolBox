%% standard start-up routines and variables for all lab experiments
function e=hl_startup(projnum,projname,enum,ename,cond)
    hl_randomise;
    e.timestring=hl_timestring;                                             % set time for files
    if isempty(projnum)
        e.projnum=str2num(cell2mat(inputdlg('HandLab Project number?')));   % get handlab project number if not already loaded
    else
        e.projnum=projnum;
    end
    if isempty(projname)
        e.projname=str2num(cell2mat(inputdlg('HandLab Project name?')));    % get handlab project name if not already loaded
    else
        e.projname=projname;
    end
    if isempty(enum)
        e.enum=str2num(cell2mat(inputdlg('HandLab Experiment number?')));   % get handlab experiment number if not already loaded
    else
        e.enum=enum;
    end
    if isempty(ename)
        e.ename=str2num(cell2mat(inputdlg('HandLab Experiment name?')));    % get handlab experiment name if not already loaded
    else
        e.ename=ename;
    end
    if isempty(cond)
        e.cond=[];                                                          % not required
    else
        e.cond=[cond];
    end
    e.hid=str2num(cell2mat(inputdlg('HandLab ID number?')));                % get handlab participant ID
    e.p=str2num(cell2mat(inputdlg('Participant number?')));                 % get participant number in this experiment
    hl_startup_files;                                                       % set filenames, etc
end