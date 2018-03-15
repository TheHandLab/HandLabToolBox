%% [correct]=hl_kinematics_correction(input,start,minct,stop,minv,maxv,corrdir,samplehz)
% input = nx1 channel of data, or nx2 in which first column is corrected, second is baseline
% start = sample to start looking from, default=1
% minct = minimum reasonable correction time (starts looking after this too), default = 0
% stop = sample to stop looking at, default=end
% minv = first point on curve to use, default = 0.25
% maxv = last point on curve to use, default = 0.75
% corrdir = direction of correction (-1,1), default = direction of maximum change
% sameplehz = samples per second of data
function correct=hl_kinematics_correction(input,start,minct,stop,minv,maxv,corrdir,samplehz)

    %% PROCESS INPUT VALUES____________________________________________________________
    switch nargin
        case 1
            start=1;                                                                    % default sample to start searching from
            minct=0;                                                                    % default extra to start searching from
            stop=[];                                                                    % default sample to stop searching from (replaced with end later)
            minv=0.25;                                                                  % default to 25% of max velocity
            maxv=0.75;                                                                  % default to 75% of max velocity
            corrdir=[];                                                                 % default to direction of maximum change
            samplehz=[];                                                                % defailt to empty correct.time
        case 2
            minct=0;
            stop=[];
            minv=0.25;
            maxv=0.75;
            corrdir=[];
            samplehz=[];
        case 3
            stop=[];
            minv=0.25;
            maxv=0.75;
            corrdir=[];
            samplehz=[];
        case 4
            minv=0.25;
            maxv=0.75;
            corrdir=[];
            samplehz=[];
        case 5
            maxv=0.75;
            corrdir=[];
            samplehz=[];
        case 6
            corrdir=[];
            samplehz=[];
        case 7
            samplehz=[];
    end
    if size(input,2)>2
        error('hl_kinematics_correction: input must be max 2 columns of data');     % function needs max 2 columns of data
    end
    if size(input,2)==2                                                             % if two columns of data provided
        input(:,1)=input(:,1)-input(:,2);                                           % subtract baseline from the first column = correction velocity
        input=input(:,1);                                                           % restrict to first column
    end
    if isempty(stop)                                                                % if no stop sample provided
        stop=size(input,1);                                                         % default to last sample
    end
    if isempty(corrdir)                                                             % if no correction direction provided
        corrdir=max(input)./abs(max(input));                                        % default to direction of maximum deviation from zero
    end
        
    %% START FINDING THE CORRECTION SAMPLE_________________________________________
    [correct.maxv,correct.maxt]=nanmax(input(start+minct:stop));                    % find max velocity and time of max, in samples
    [correct.minv,correct.mint]=nanmin(input(start+minct:stop));                    % find min velocity and time of min, in samples   
    correct.maxt=correct.maxt+start+minct-1;                                        % correct for start offset
    correct.mint=correct.mint+start+minct-1;                                        % correct for start offset
    
    %% GET POSITIVE OR NEGATIVE SAMPLES AT TWO POINTS ON THE CURVE_________________
    if corrdir==1                                                                   % for positive correction velocities
        if correct.maxt>1                                                           % if the maximum sample is at least the 2nd sample
            correct.t1=find(input(1:correct.maxt)<minv.*correct.maxv,1,'last')+1;   % find last sample (before sample of max) which is less than first criterion velocity
            correct.t2=find(input(1:correct.maxt)<maxv.*correct.maxv,1,'last')+1;   % find last sample (before sample of max) which is less than second criterion velocity
            correct.mag=correct.maxv;                                               % correction magnitude = maximum correction velocity
        else
            warning('hl_kinematics_correction: no max correction velocity found');  % maximum velocity was too early
        end
    elseif corrdir==-1                                                              % for negative correction velocities
        if correct.mint>1
            correct.t1=find(input(1:correct.mint)>minv.*correct.minv,1,'last')+1;   % find last sample (before sample of min) which is greater than first criterion velocity
            correct.t2=find(input(1:correct.mint)>maxv.*correct.minv,1,'last')+1;   % find last sample (before sample of min) which is greater than second criterion velocity
            correct.mag=correct.minv;                                               % correction magnitude = maximum correction velocity
        else
            warning('hl_kinematics_correction: no min correction velocity found');  % minimum velocity was too early
        end      
    end
    
    %% GET VELOCITIES AT TWO POINTS ON THE CURVE___________________________________
    if ~(isempty(correct.maxv).*isempty(correct.minv)) && ((corrdir==1 && isfinite(correct.maxv)) || (corrdir==-1 && isfinite(correct.minv))) % IF: either maxv or minv is not empty, and the required one is finite
        correct.v1=input(correct.t1);                                               % velocity at first sample
        correct.v2=input(correct.t2);                                               % velocity at second sample
        correct.slope=(correct.v2-correct.v1)./(correct.t2-correct.t1);             % distance/sample/sample of extrapolation line
        if correct.slope~=0
            correct.sample=correct.t1-start-1-(correct.v1./correct.slope);          % calculate correction sample, RELATIVE TO START OF SEARCH
        else
            correct.sample=[];
        end
    else
        correct.v1=[];                                                              % return empty values if unsuccessful
        correct.v2=[];
        correct.slope=[];
        correct.sample=[];
    end
    if ~isempty(samplehz) && ~isempty(correct.sample)                               % if samplehz is not empty and a correction sample was found
        correct.time=correct.sample.*(1000./samplehz);                              % return correction time in ms, RELATIVE TO START OF SEARCH
    else
        correct.time=[];
    end
end