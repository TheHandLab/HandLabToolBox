% reoriented=hl_kinematics_reorient(input[, plot])
% re-orient the orientation channels of kinematic data to remove the 360-degree flips
% input: samples x channels array (i.e., 20000x3) of angular orientation data
% plot: 0 or 1 (plot one figure per channel), default = 0, no plotting
function reoriented=hl_kinematics_reorient(input,plotdata)                  % function call
    %% PROCESS THE INPUTS__________________________________________________
    if ndims(input)>2
        error('hl_kinematics_reorient: accepts only n-by-m arrays (samples x orientations)');
    end
    reoriented=input;                                                       % copy input data
    if size(reoriented,2)>size(reoriented,1)                                % in input has more columns than rows
        reoriented=reoriented';                                             % transpose the data
        warning('hl_kinematics_reorient: more columns than rows - transposing data');
    end
    if nargin==1                                                            % if only input is provided
        plotdata=0;                                                         % don't plot the data (default)
    end
    %% FIND THE TRANSITIONS________________________________________________
    d=diff(reoriented);                                                     % get differential
    for m=1:size(reoriented,2)                                              % for each column of data
        trans=find(abs(d(:,m))>180);                                        % find timepoints where angular displacement is >180 (flips over the -180/180 axis)
        if numel(trans)>0                                                   % if there are any transitions...
            if plotdata==1                                                  % if output requested
                disp(['Channel ',int2str(m),': ',int2str(numel(trans)),' flips']);% display channel number and number of transitions
            end            
            if plotdata==1                                                  % if output requested
                figure(m);                                                  % figure for this channel of data
                subplot(2,1,1);                                             % top of figure, plot raw data, transition points, and corrected data
                    hold on;                                                % overwrite lines on figure
                    title(['Transitions in channel ',int2str(m)]);          % figure title
                    ylabel('Raw, transitions, corrections');                % y-axis label
                    plot(reoriented(:,m));                                  % plot this channel of data
            end
            for t=1:numel(trans)                                            % for each one...
                start=trans(t)+1;                                           % start of epoch to reorient
                %% THIS NEEDS CHECKING - DOES IT CORRECTLY RE-ORIENT THE DATA???
                transitionjump=round((reoriented(start,m)-reoriented(start-1,m))./360);% how big is this transition
                reoriented(start:end,m)=-transitionjump.*360+reoriented(start:end,m);% fix the epoch???
            end
            if plotdata==1                                                  % if output requested            
                subplot(2,1,2);                                             % lower figure, plot corrected data
                    hold on;                                                % overwrite lines on figure
                    plot(reoriented(:,m),'g-');                             % plot corrected data
                    xlabel('Sample number');                                % x-axis label
                    ylabel('Reoriented data');                              % y-axis label
            end
        else
            if plotdata==1                                                  % if output requested
                disp(['Channel ',int2str(m),': 0 flips']);                  % display channel number and number of transitions
            end
        end
    end
end