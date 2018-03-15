% function hl_kinematics_plot_trial(input,linestyle,linewidth,overwrite,grip)
% input should be 3 or 6 columns of data for each channel
% linestyle and linewidth arguments as standard
% grip=0 (default) - plot 3D trajectory
% grip=1 - plot 3D difference
function hl_kinematics_plot_trial(input,linestyle,linewidth,overwrite,grip,target)
    if nargin==1
        linestyle='b-';
        linewidth=1;
        overwrite=0;
        grip=0;
        target=[];
    end
    if nargin==2
        linewidth=1;
        overwrite=0;
        grip=0;
        target=[];
    end
    if nargin==3
        overwrite=0;
        grip=0;
        target=[];
    end
    if nargin==4
        grip=0;
        target=[];
    end   
    if nargin==5
        target=[];
    end       
    if nargin>6
        error('hl_kinematics_plot_trial(input[,linestyle] [,linewidth] [,grip] [,target]): too many input arguments');
    end
    channels=size(input,3);
    for c=1:channels
        if strcmp(linestyle,'b-')
            switch c
                case 2
                    linestyle='r-';
                case 3
                    linestyle='g-';
                case 4
                    linestyle='m-';
            end
        end    
        if c==1
            if overwrite==1
                subplot(2,2,1);
                    hold on;
                subplot(2,2,2);
                    hold on;
                subplot(2,2,3);
                    hold on;
                subplot(2,2,4);
                    hold on;
            end
        end
        subplot(2,2,1);
            switch grip;
                case {0};
                    plot3(input(:,1,c),input(:,2,c),input(:,3,c),linestyle,'linewidth',linewidth);% plot 3D trajectory
                    hold on;
                    plot3(input(1,1,c),input(1,2,c),input(1,3,c),[linestyle(1),'o']);% plot start point
                    if ~isempty(target)
                        plot3(target(1),target(2),target(3),[linestyle(1),'s']);
                    end
                    xlabel('x');
                    ylabel('y');
                    zlabel('z');
                    grid on;
                    view(90,-45);
                case {1};
                    plot(sqrt(input(:,1,c).^2+input(:,2,c).^2+input(:,3,c).^2),linestyle,'linewidth',linewidth);% plot 3D grip aperture
                    hold on;
            end
            set (gca,'Color',[ .8 .8 .8]);
        subplot(2,2,2);
            plot(input(:,1,c),linestyle,'linewidth',linewidth);
            hold on;
            if ~isempty(target) && grip==0
                plot([0,size(input,1)],[target(1),target(1)],linestyle,'linewidth',linewidth./2);
            end
            xlabel('sample');
            ylabel('x');
            set (gca,'Color',[ .8 .8 .8]);
        subplot(2,2,3);
            plot(input(:,2,c),linestyle,'linewidth',linewidth);
            hold on;
            if ~isempty(target) && grip==0
                plot([0,size(input,1)],[target(2),target(2)],linestyle,'linewidth',linewidth./2);
            end
            xlabel('sample');
            ylabel('y');
            set (gca,'Color',[ .8 .8 .8]);
        subplot(2,2,4);
            plot(input(:,3,c),linestyle,'linewidth',linewidth);
            hold on;
            if ~isempty(target) && grip==0
                plot([0,size(input,1)],[target(3),target(3)],linestyle,'linewidth',linewidth./2);
            end
            xlabel('sample');
            ylabel('z');
            set (gca,'Color',[ .8 .8 .8]);
    end
        drawnow;
end