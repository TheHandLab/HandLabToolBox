%% hl_kinematics_plot_trial2(input,target,grip,samplehz,holdon,titlestr,fignum)
%% INPUTS:
% input     nx3 data (X,Y,Z)
% target    1x3 data (X,Y,Z)    (default=(0,0,0))
% grip      0=not grip, 1=grip  (default=0)
% samplehz  samples per second  (default =100)
% holdon    -1=hold off; 0=do nothing; 1=hold on
% titlestr  string to use for graph title
% fignum    figure number to write to
function hl_kinematics_plot_trial2(input,target,grip,samplehz,holdon,titlestr,fignum)
    %% PROCESS INPUTS______________________________________________________
    if nargin==1
        target=[0,0,0];                                                     % default target location
        grip=0;                                                             % default is not grip
        samplehz=100;                                                       % default sample frequency
        holdon=0;                                                           % default is do nothing (1=hold on, -1=hold off?)
        titlestr='';                                                        % default is no title
        fignum=1;                                                           % default is figure 1
    elseif nargin==2
        grip=0;
        samplehz=100;
        holdon=0;
        titlestr='';
        fignum=1;
    elseif nargin==3
        samplehz=100;
        holdon=0;
        titlestr='';
        fignum=1;
    elseif nargin==4
        holdon=0;
        titlestr='';
        fignum=1;
    elseif nargin==5
        titlestr='';
        fignum=1;
    elseif nargin==6
        fignum=1;
    end        
    if size(input,2)>3
        error('hl_kinematics_plot_trial2: input data should be nx3');       % need nx3 data
    end
    if isempty(target)
        target=[0,0,0];                                                     % replace empty target with [0,0,0];
    end
    if numel(target)>3
        error('hl_kinematics_plot_trial2: target coordinates should be 1x3');% need 1x3 target coordinates
    end
    samples=size(input,1);                                                  % number of samples
    d=diff(input);                                                          % differentiate the input data
    %% START PLOTTING THE DATA_____________________________________________
    figure(fignum);                                                         % select the figure
        subplot(4,2,1);                                                     % X position
            plot(1:samples,input(:,1));                                     % plot X position
            if holdon==1                                                    % if over-lay required
                hold on;                                                    % plot all channels on top
            end						    
            title(titlestr);                                                % add title to figure
            ylabel('X');                                                    % X data label
            plot([1,samples],[target(1),target(1)],'r-');                   % target X location
        subplot(4,2,2);                                                     % X velocity
            plot(1:samples-1,d(:,1).*samplehz);                             % plot X velocity
            if holdon==1                                                    % if over-lay required
                hold on;                                                    % plot all channels on top
            end							    
            ylabel('X Vel');                                                % X velocity label
        subplot(4,2,3);                                                     % Y position
            plot(input(:,2));                                               % plot Y position
            if holdon==1                                                    % if over-lay required
                hold on;                                                    % plot all channels on top
            end					    
            ylabel('Y');                                                    % X position label
            plot([1,samples],[target(2),target(2)],'r-');                   % target Y
        subplot(4,2,4);                                                     % Y velocity
            plot(1:samples-1,d(:,2).*samplehz);                             % plot Y velocity
            if holdon==1                                                    % if over-lay required
                hold on;                                                    % plot all channels on top
            end					    
            ylabel('Y Vel');                                                % Y velocity label
        subplot(4,2,5);                                                     % Z position
            plot(1:samples,input(:,3));                                     % plot Z position
            if holdon==1                                                    % if over-lay required
                hold on;                                                    % plot all channels on top
            end					    
            ylabel('Z');                                                    % Z position label
            plot([1,samples],[target(3),target(3)],'r-');                   % target Z position
        subplot(4,2,6);
            plot(1:samples-1,d(:,3).*samplehz);                             % plot Z velocity
            if holdon==1                                                    % if over-lay required
                hold on;                                                    % plot all channels on top
            end					    
            ylabel('Z Vel');                                                % Z velocity label
        subplot(4,2,7);                                                     % 3D position (distance from origin)
            plot(1:samples,sqrt(sum(input(:,1:3).^2,2)));                   % plot 3D position
            if holdon==1                                                    % if over-lay required
                hold on;                                                    % plot all channels on top
            end					    
            ylabel('D');                                                    % 3D position label				    
        subplot(4,2,8);                                                     % 3D velocity
            if grip==0
                plot(1:samples-1,[sqrt(sum(d.^2,2)).*samplehz]);            % plot 3D velocity
            elseif grip==1
                plot(1:samples-1,[diff(sqrt(sum(input(:,1:3).^2,2))).*samplehz]);% plot 3D grip velocity
            end
            if holdon==1                                                    % if over-lay required
                hold on;                                                    % plot all channels on top
            end
            ylabel('3D Vel');                                               % 3D velocity label
end                                                                         % end of function