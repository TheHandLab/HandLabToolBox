% function [d,v,a,j,s,on,off,pv,pa,pd,path,rms]=hl_kinematics(input [,sampfreq] [,onset] [,offset] [,plotdata] [, samplerange])
% from an input of sequential samples of kinematic data, from before the movement onset until after movement offset
% calculates a number of kinematic parameters (listed below).
% Data input can be from 1D to 6D (columns of zeros are fine), and will be padded with zeros up to 6D
% output 'location' is 6D or 8D (see below).
% Onset and offset velocities, if not specified, default to 5% of maximum velocity
%
% INPUTS
% INPUT: samples in different rows, dimensions (x,y,z,az,el,rl) in different columns
% SAMPFREQ: optional, sampling frequency in Hz, defaults to 1000
% ONSET: optional, [onset criterion, samples to skip, onset sample]
%   1: velocity criterion defaults to 5% of the velocity range
%   2: If two arguments given, first is velocity criterion, second specifies how many initial samples to skip
%   3: If three arguments given, third specifies which sample to use as onset (e.g. when using another channel for onset and offset)
% OFFSET: optional, CELL ARRAY, [offset 3D velocity criterion, number of samples, offset sample, minimum movement time, target location]
%   1: defaults to the onset velocity criterion and 50ms worth of samples
%   2: specifies how many samples below the criterion before offset
%   3: specifies which sample to use as offset (e.g. when using another channel for onset and offset)
%   4: specifies min offset time relative to onset (e.g., 250ms, when tracker already moving at start)
%   5: If given, specifies target location and tolerance [x,y,z,az,el,rl,3Dp,3Da; cx,cy,cz,caz,cel,crl,c3p,c3o] - only accept end points within c units from x,y,z,az,el,rl,3Dp,3Da
% PLOTDATA: optional, [1 1 1] to plot position, velocity, acceleration figures, 0 to suppress plotting, defaults to [0 0 0]
% SAMPLERANGE: [a b]: range over which to extract kinematics, default=full range
%
% OUTPUTS: 
% 1: displacement [location]
% 2: velocity [location: X,Y,Z,az,el,rl,3Dpos,3Dang]
% 3: acceleration [location]
% 4: jerk [location]
% 5: snap [location]
% 6: start of movement [sample,time,velocity,location(6D)]
% 7: peak acceleration [peak_a,sample,time,velocity,location(6D)] (from onset to peak velocity)
% 8: peak velocity [peak_v,sample,time,velocity,location(6D)] (across whole sample)
% 9: peak deceleration [peak_d,sample number,location(6D)] (after peak velocity)
% 10: end of movement [sample number, samples in criterion,time,velocity,location(6D)] (after time of peak deceleration)
% 11: path length [location] (from onset to offset, unsigned sum of all displacements)
% 12: rms: root mean square of position, velocity, acceleration, jerk, and snap, between onset and offset
%
% LOCATION OUTPUTS ARE 8-DIMENSIONAL: (x,y,z,az,el,rl,tangential position,tangential orientation)
% SAMPLE NUMBER IS IN MILLISECONDS IF A SAMPLE FREQUENCY IS PROVIDED.
% PARAMETERS ARE CALCULATED RELATIVE TO 3D TANGENTIAL POSITIONAL VELOCITY (onset, peak vel, peak acc, peak dec, offset)
%
% TO COME: ALLOW VECTOR INPUT FOR VELOCITY ONSETS, AND CALCULATE STATS PER DIMENSION e.g.: [0 0 Z AZ 0 0];
function [d,v,a,j,s,on,off,pv,pa,pd,path,rms]=hl_kinematics(input,sampfreq,onset,offset,plotdata,samplerange)
    %% PROCESS THE INPUTS__________________________________________________________________________
    if nargin<1 || nargin>6
        error('hl_kinematics: [d,v,a,j,s,on,off,pv,pa,pd,path,rms]=hl_kinematics(input [,sampfreq] [,onset] [,offset] [,plotdata] [,samplerange])');
    end
    if size(input,2)>size(input,1) && size(input,1)<7
        data=input';                                                                                % flip rows and columns if necessary
    else
        data=input;
    end
    if size(data,2)>6
        error('hl_kinematics: too many columns in the input matrix, max 6 allowed [X,Y,Z,AZ,EL,RL]');
    end
    if size(data,2)<6
        data(:,size(data,2)+1:6)=0;                                                                 % pad data with zeros if necessary
    end
    samples=size(data,1);
    if nargin==1 || isempty(sampfreq) || sampfreq==0
        sampfreq=1000;                                                                              % acceleration and velocity output in raw form
    end
    mspersample=(1000./sampfreq);                                                                   % milliseconds per sample
    if nargin<5
        plotdata=[0,0,0];
    end
    if nargin<6
        samplerange=[1,size(data,1)];
    end
    if isempty(samplerange)
        samplerange=[1,size(data,1)];
    end

    %% INITIALISE VARIABLES________________________________________________________________________
    on=struct();
    off=struct();
    pa=struct();
    pv=struct();
    pd=struct();
    path=struct;
    rms=struct();

    %% DISPLACEMENT________________________________________________________________________________
    d(2:samples,1:6)=diff(data(:,1:6));                                                             % displacment from samples 2 to end
    d(1,:)=d(2,:);                                                                                  % displacment 0:1 = displacement 1:2
    d(:,7)=sqrt(sum(d(:,1:3).^2,2));                                                                % 3D displacement in position (unsigned, sample-to-sample)
    d(:,8)=sqrt(sum(d(:,4:6).^2,2));                                                                % 3D displacement in orientation (unsigned, sample-to-sample)
    d(2:samples,9)=diff(sqrt(sum(data(:,1:3).^2,2)));                                               % 3D displacement in position (signed relative to origin)
    d(2:samples,10)=diff(sqrt(sum(data(:,4:6).^2,2)));                                              % 3D displacement in orientation (signed relative to origin)
    
    %% VELOCITY____________________________________________________________________________________
    v=d.*sampfreq;                                                                                  % velocity = displacement per sample * sample frequency
    if nargin<3 || isempty(onset(1))
        onset(1)=min(v(:,7))+(max(v(:,7))-min(v(:,7)))./20;                                         % velocity onset criterion = 5% of 3D velocity range
    end
    if onset(1)>=max(v(:,7))./2
        warning('hl_kinematics: onset velocity criterion too high, defaulting to 5% of range');
        onset(1)=min(v(:,7))+(max(v(:,7))-min(v(:,7)))./20;                                         % onset velocity too high: return to default
    end
    onsetacc=100;                                                                                   % set onset acceleration criterion to 20*velocity criterion (default: 100cm/s/s)
    if length(onset)>1 && onset(2)<samples                                                          % if samples to skip given and fewer than max samples
        if onset(2)==0
            on.skip=0;                                                                              % don't skip any if none requested
        else
            on.skip=onset(2)-1;                                                                     % skip the first n samples, start searching after
	    samplerange(1)=on.skip;                                                                     % reset the samplerange
        end
    else
        on.skip=0;                                                                                  % default to 0
    end
    if length(onset)>2 && ~isempty(onset(3))                                                        % if a third argument given for onset sample
       on.sample=onset(3);                                                                          % set onset sample
    else
       on.sample=[];                                                                                % else set variable to be empty
    end
    if nargin<4 || isempty(offset)
        offset(1)=onset(1);                                                                         % offset velocity is the same as onset if not specified
        off.samples=round(sampfreq./20);                                                            % samples for offset criterion (50ms)
    end
    if length(offset{1})==1 || offset{2}==0
        off.samples=round(sampfreq./20);                                                            % samples for offset criterion (50ms)
    else
        off.samples=offset{2};                                                                      % number of samples for offset velocity
    end
    if length(offset{1})>2 && offset{3}>0                                                           % if third argument given for offset sample
        off.sample=offset{3};                                                                       % set offset sample
    else
        off.sample=[];                                                                              % else set variable to be empty
    end
    if offset{1}>=max(v(:,7))./2                                                                    % if offset velocity greater than max velocity
        warning('hl_kinematics: offset velocity criterion too high, defaulting to 5% of range');
        offset{1}=min(v(:,7))+(max(v(:,7))-min(v(:,7)))./20;                                        % onset velocity too high: return to default 5%
    end

    %% ACCELERATION________________________________________________________________________________
    a(2:samples,:)=v(2:samples,:)-v(1:samples-1,:);                                                 % acceleration from sample 2 to last sample
    a(1,:)=a(2,:);                                                                                  % acceleration 1 = acceleration 2
    a=a.*sampfreq;                                                                                  % acceleration = velocity per sample * sample frequency

    %% JERK________________________________________________________________________________________
    j(2:samples,:)=a(2:samples,:)-a(1:samples-1,:);                                                 % jerk from sample 2 to last sample
    j(1,:)=j(2,:);                                                                                  % jerk 1 = jerk 2
    j=j.*sampfreq;                                                                                  % jerk = acceleration per sample * sample frequency

    %% SNAP________________________________________________________________________________________
    s(2:samples,:)=j(2:samples,:)-j(1:samples-1,:);                                                 % snap from sample 2 to last sample
    s(1,:)=s(2,:);                                                                                  % snap 1 = snap 2
    s=s.*sampfreq;                                                                                  % snap = jerk per sample * sample frequency

    %% ONSET_______________________________________________________________________________________
    if isempty(on.sample)
        on.sample=find(a(on.skip+1:samplerange(2),7)>=onsetacc,1)+on.skip;                          % find first point greater than 3D acceleration onset criterion
        if isfinite(on.sample) 
            on.sample=find(v(on.sample:samplerange(2),7)>=onset(1),1)+on.sample-1;                  % find first point greater than (3D) velocity onset criterion
        end
    end
    if isempty(on.sample)
        on.sample=samples;                                                                          % if no onset, use maximum time
        warning('hl_kinematics: no movement onset found, defaulting to last sample');               % warning
    end
    on.time=on.sample.*mspersample;                                                                 % onset in milliseconds
    on.velocity=v(on.sample,:);                                                                     % velocity at onset
    on.location=data(on.sample,:);                                                                  % location at onset

    %% OFFSET______________________________________________________________________________________
    if isempty(off.sample)
        offlog=ones(samples,10);                                                                    % for logical array combining across offset criteria (0=not offset)
        if ~isempty(offset{5})                                                                      % if a target location and tolerance was specified
            targoff=abs(data(:,1:3)-repmat(offset{5}(1,1:3),samples,1));                            % subtract target location from x, y, z
            if ~isempty(offset{5}(2,1))
                offlog(targoff(:,1)>offset{5}(2,1),1)=0;                                            % logical index of x-positions within target zone
            end
            if ~isempty(offset{5}(2,2))
                offlog(targoff(:,2)>offset{5}(2,2),2)=0;                                            % logical index of y-positions within target zone
            end	    
            if ~isempty(offset{5}(2,3))
                offlog(targoff(:,3)>offset{5}(2,3),3)=0;                                            % logical index of z-positions within target zone
            end	   	    
            if ~isempty(offset{5}(2,7))                                                             % if a 3D distance criterion given
                targoff(:,7)=sqrt(sum((targoff(:,1:3).^2),2));                                      % 3D distance from target
                offlog(targoff(:,7)>offset{5}(2,7),7)=0;                                            % logical index of 3D distances within target zone
            end
            [off.mindistance,off.minsample]=min(sqrt(sum(targoff(:,1:3).^2,2)));                    % nearest point to target
            off.minlocation=data(off.minsample,1:3);                                                % coordinates of nearest point
            %if ~isempty(offset{5}(1,5))							    % if a target orientation and tolerance was specified
                %targoff(:,4:6)=data(:,4:6)-repmat(offset{5}(1,4:6),samples,1);			    % subtract target orientation from az, el, rl
                %if ~isempty(offset{5}(2,8))							    % if a 3D angular criterion given
                %targoff(8,:)=sqrt(sum((targoff(:,4:6).^2),2));				    % 3D 'distance' from target
            %end
            %end
        else
            off.mindistance=NaN;
            off.minsample=NaN;
            off.minlocation=[NaN,NaN,NaN];
        end
        if samplerange(1)>1
            offlog(1:samplerange(1),9)=0;                                                           % not possible velocity offset before start
        end
        if samplerange(2)>2
            offlog(samplerange(2):end,9)=0;                                                         % not possible velocity offset after end
        end
        if ~isempty(offset{4})                                                                      % if a min offset time requested (after onset time)
            minoff=round(offset{4}./(1000./sampfreq));                                              % convert to samples
        else
            minoff=0;
        end
        firstoff=find(v(on.sample+minoff:samplerange(2),7)>=offset{1},1)+on.sample+minoff;  	    % first point ABOVE offset criterion (after minimum possible)
        offlog(1:firstoff,9)=0;                                                                     % set minimum delay before looking for velocity
        minvel=min(v(firstoff:samplerange(2),7));                                                   % minimum velocity after first point above offset velocity
        %offvel=find(v(firstoff:samplerange(2),7)<=offset{1});                                      % velocity samples below the offset criterion
        offlog(v(:,7)>offset{1},10)=0;                                                              % logical index of low 3D velocities
        offvel2=prod(offlog,2);                                                                     % product of all columns in offset array
        offvel2=find(offvel2==1);                                                                   % find possible offset points
        if isempty(offvel2)                                                                         % if no velocities found below criterion
            warning('hl_kinematics: velocity offset criterion not reached, reporting minimum velocity');
            off.sample=samplerange(2);                                                              % offset not found, so use last sample
        else
            off.sample=offvel2(find(offvel2(off.samples:end)-offvel2(1:end-off.samples+1)==off.samples-1,1));% first point below offset criterion for n successive points (set by second argument)
            if isempty(off.sample)
                n=off.samples-1;
                while isempty(off.sample)
                    off.sample=offvel2(find(offvel2(n:end)-offvel2(1:end-n+1)==n-1,1));
                    n=n-1;
                end
                warning('hl_kinematics: velocity offset time criterion not reached, reporting maximum offset samples'); % warning
                off.samples=samplerange(2);                                                         % set offset sample to max
            end
            %off.sample=off.sample+firstoff-1;                                                      % correct for first offset time
        end
        if off.sample<1
            off.sample=1;                                                                           % some fudge
        end
    end
    off.time=off.sample.*mspersample;                                                               % offset in milliseconds
    off.velocity=v(off.sample,:);                                                                   % velocity at offset
    off.location=data(off.sample,:);                                                                % location at offset
    [off.maxdistance,off.maxsample]=max(sqrt(sum((data(:,1:3)-repmat(data(1,1:3),samples,1)).^2,2)));% furthest point from start
    off.maxlocation=data(off.maxsample,1:3);                                                        % coordinates of furthest point

    %% IF SUFFICIENT DATA, PROCESS FURTHER_________________________________________________________
    if off.sample-on.sample>2
        %% PEAK VELOCITY___________________________________________________________________________
        [pv.velocity,pv.sample]=max((v(samplerange(1):off.sample,:)));                              % first max velocity and sample numbers
        pv.sample=pv.sample+samplerange(1)-1;                                                       % correct for onset time
        pv.time=pv.sample.*mspersample;                                                             % time at maximum velocities
        pv.location=data(pv.sample,:);                                                              % locations at maximum velocities
        pv.meanv=mean(v(on.sample:off.sample,:),1);                                                 % mean velocity
        pv.symmetry=(pv.sample-on.sample)./(off.sample-on.sample);                                  % pv symmetry, 0.5=symmetrical
        pv.shape=abs(pv.velocity./pv.meanv);                                                        % pv shape, variability is useful
	
        %% AND MINIMUM VELOCITIES
        [pv.minvelocity,pv.minsample]=min((v(samplerange(1):off.sample,:)));                        % first min velocity and sample numbers
        pv.minsample=pv.minsample+samplerange(1)-1;                                                 % correct for onset time
        pv.mintime=pv.minsample.*mspersample;                                                       % time at min velocities
        pv.minlocation=data(pv.minsample,:);                                                        % locations at min velocities
	
        %% PEAK ACCELERATION_______________________________________________________________________
        [pa.acceleration,pa.sample]=max((a(samplerange(1):pv.sample(7),:)));                        % max accelerations and sample numbers
        pa.sample=pa.sample+samplerange(1)-1;                                                       % correct for onset time
        pa.time=pa.sample.*mspersample;                                                             % time at maximum accelerations
        pa.location=data(pa.sample,:);                                                              % locations at maximum accelerations

        %% PEAK DECELERATION_______________________________________________________________________
        [pd.deceleration,pd.sample]=min(a(pv.sample(7):off.sample,:),[],1);                         % max decelerations and sample numbers
        pd.sample=pd.sample+pv.sample(7)-1;                                                         % correct for peak velocity time
        pd.time=pd.sample.*mspersample;                                                             % time at maximum accelerations
        if on.sample~=samples
            pd.location=data(pd.sample,:);                                                          % locations at maximum accelerations
        else
            pd.location=data(samples,:);
        end

        %% RMS_____________________________________________________________________________________
        rms.v=sqrt(mean(v(on.sample:off.sample,:).^2));                                             % rms velocity
        rms.a=sqrt(mean(a(on.sample:off.sample,:).^2));                                             % rms acceleration	
        if off.sample-on.sample>3
            rms.j=sqrt(mean(j(on.sample:off.sample,:).^2));                                         % rms jerk
            if off.sample-on.sample>4
                rms.s=sqrt(mean(s(on.sample:off.sample,:).^2));                                     % rms snap
            end
        end
	
        %% PATH LENGTH_____________________________________________________________________________
        path.length=sum(abs(d(on.sample:off.sample,:)),1);                                          % path length
        path.straight=sqrt(sum(squeeze((data(off.sample,1:3)-data(on.sample,1:3)).^2)));            % straight line between start and end
        path.ratio=path.length./path.straight;                                                      % how efficient is this path	

        % points
        x1=data(on.sample:off.sample,1);
        y1=data(on.sample:off.sample,2);
        z1=data(on.sample:off.sample,3);
        % line origin
        x2=data(on.sample,1);
        y2=data(on.sample,2);
        z2=data(on.sample,3);
        % line direction
        x0=data(off.sample,1)-data(on.sample,1);
        y0=data(off.sample,2)-data(on.sample,2);
        z0=data(off.sample,3)-data(on.sample,3);	
        path.deviation=sqrt(((z0.*(y2-y1)-y0.*(z2-z1)).^2+(x0.*(z2-z1)-z0.*(x2-x1)).^2+(y0.*(x2-x1)-x0.*(y2-y1)).^2 )./(x0.^2+y0.^2+z0.^2));
        path.deviationstd=path.deviation./path.straight;                                            % standardised to proportion of path length
        path.curvature=max(path.deviationstd);                                                      % curvature index
	
    else                                                                                            % set all variables to empty to prevent mis-information
        warning('hl_kinematics: movement length less than 3 samples, not calculating vel, accel, decel, jerk, snap, path, rms');
        pv.velocity=[];
        pv.meanv=[];
        pv.sample=[];
        pv.time=[];
        pv.location=[];
        pv.symmetry=[];
        pv.shape=[];
        pa.acceleration=[];
        pa.sample=[];
        pa.time=[];
        pa.location=[];
        pd.deceleration=[];
        pd.sample=[];
        pd.time=[];
        pd.location=[];
        path=[];
        rms=[];
    end

    %% PLOT DATA FOR SANITY-CHECKS_________________________________________________________________
    if off.sample-on.sample>2
        if plotdata(1)==1
            figure;
                hold on;
                subplot(4,1,1);
                    hold on;
                    plot(data(:,1),'k-');
                    ax=axis;
                    plot([on.sample on.sample],[ax(3) ax(4)],'g-');
                    plot([off.sample off.sample],[ax(3) ax(4)],'r-');
                    %plot(pa.sample(1),data(pa.sample(1),1),'b^');
                    %plot(pv.sample(1),data(pv.sample(1),1),'ks');
                    %plot(pd.sample(1),data(pd.sample(1),1),'bv');
                    ylabel('X position');
                    title('Position');  
                subplot(4,1,2);
                    hold on;
                    plot(data(:,2),'k-');
                    ax=axis;
                    plot([on.sample on.sample],[ax(3) ax(4)],'g-');
                    plot([off.sample off.sample],[ax(3) ax(4)],'r-');
                    %plot(pa.sample(2),data(pa.sample(2),2),'b^');
                    %plot(pv.sample(2),data(pv.sample(2),2),'ks');
                    %plot(pd.sample(2),data(pd.sample(2),2),'bv');
                    ylabel('Y position');
                subplot(4,1,3);
                    hold on;
                    plot(data(:,3),'k-');
                    ax=axis;
                    plot([on.sample on.sample],[ax(3) ax(4)],'g-');
                    plot([off.sample off.sample],[ax(3) ax(4)],'r-');
                    %plot(pa.sample(3),data(pa.sample(3),3),'b^');
                    %plot(pv.sample(3),data(pv.sample(3),3),'ks');
                    %plot(pd.sample(3),data(pd.sample(3),3),'bv');
                    ylabel('Z position');
                subplot(4,1,4);
                    hold on;
                    plot(d(:,7),'k-');
                    ax=axis;
                    plot([on.sample on.sample],[ax(3) ax(4)],'g-');
                    plot([off.sample off.sample],[ax(3) ax(4)],'r-');
                    plot(pa.sample(7),d(pa.sample(7),7),'b^');
                    plot(pv.sample(7),d(pv.sample(7),7),'ks');
                    plot(pd.sample(7),d(pd.sample(7),7),'bv');
                    xlabel('Sample number');
                    ylabel('3D displacement');
        end	
 
        %% velocity data as well___________________________________________________________________
        if plotdata(2)==1
            figure;
                hold on;
                subplot(4,1,1);
                    hold on;
                    plot(v(:,1),'k-');
                    ax=axis;
                    plot([on.sample on.sample],[ax(3) ax(4)],'g-');
                    plot([off.sample off.sample],[ax(3) ax(4)],'r-');
                    %plot(pa.sample(1),v(pa.sample(1),1),'b^');
                    %plot(pv.sample(1),v(pv.sample(1),1),'ks');
                    %plot(pd.sample(1),v(pd.sample(1),1),'bv');
                    ylabel('X velocity');
                    title('Velocity');
                subplot(4,1,2);
                    hold on;
                    plot(v(:,2),'k-');
                    ax=axis;
                    plot([on.sample on.sample],[ax(3) ax(4)],'g-');
                    plot([off.sample off.sample],[ax(3) ax(4)],'r-');
                    %plot(pa.sample(2),v(pa.sample(2),2),'b^');
                    %plot(pv.sample(2),v(pv.sample(2),2),'ks');
                    %plot(pd.sample(2),v(pd.sample(2),2),'bv');
                    ylabel('Y velocity');
                subplot(4,1,3);
                    hold on;
                    plot(v(:,3),'k-');
                    ax=axis;
                    plot([on.sample on.sample],[ax(3) ax(4)],'g-');
                    plot([off.sample off.sample],[ax(3) ax(4)],'r-');
                    %plot(pa.sample(3),v(pa.sample(3),3),'b^');
                    %plot(pv.sample(3),v(pv.sample(3),3),'ks');
                    %plot(pd.sample(3),v(pd.sample(3),3),'bv');
                    ylabel('Z velocity');
                subplot(4,1,4);
                    hold on;
                    plot(v(:,7),'k-');
                    ax=axis;
                    plot([on.sample on.sample],[ax(3) ax(4)],'g-');
                    plot([off.sample off.sample],[ax(3) ax(4)],'r-');
                    plot(pa.sample(7),v(pa.sample(7),7),'b^');
                    plot(pv.sample(7),v(pv.sample(7),7),'ks');
                    plot(pd.sample(7),v(pd.sample(7),7),'bv');
                    plot([ax(1) pv.sample(7)],[onsetvel(1) onsetvel(1)],'g-');
                    plot([pv.sample(7) ax(2)],[offsetvel(1) offsetvel(1)],'r-');
                    xlabel('Sample number');
                    ylabel('3D velocity');
        end
        if plotdata(3)==1
            %% acceleration data as well___________________________________________________________
            figure;
                hold on;
                subplot(4,1,1);
                    hold on;
                    plot(a(:,1),'k-');
                    ax=axis;
                    plot([on.sample on.sample],[ax(3) ax(4)],'g-');
                    plot([off.sample off.sample],[ax(3) ax(4)],'r-');
                    %plot(pa.sample(1),a(pa.sample(1),1),'b^');
                    %plot(pv.sample(1),a(pv.sample(1),1),'ks');
                    %plot(pd.sample(1),a(pd.sample(1),1),'bv');
                    ylabel('X acceleration');
                    title('Acceleration');
                subplot(4,1,2);
                    hold on;
                    plot(a(:,2),'k-');
                    ax=axis;
                    plot([on.sample on.sample],[ax(3) ax(4)],'g-');
                    plot([off.sample off.sample],[ax(3) ax(4)],'r-');
                    %plot(pa.sample(2),a(pa.sample(2),2),'b^');
                    %plot(pv.sample(2),a(pv.sample(2),2),'ks');
                    %plot(pd.sample(2),a(pd.sample(2),2),'bv');
                    ylabel('Y acceleration');
                subplot(4,1,3);
                    hold on;
                    plot(a(:,3),'k-');
                    ax=axis;
                    plot([on.sample on.sample],[ax(3) ax(4)],'g-');
                    plot([off.sample off.sample],[ax(3) ax(4)],'r-');
                    %plot(pa.sample(3),a(pa.sample(3),3),'b^');
                    %plot(pv.sample(3),a(pv.sample(3),3),'ks');
                    %plot(pd.sample(3),a(pd.sample(3),3),'bv');
                    ylabel('Z acceleration');
                subplot(4,1,4);
                    hold on;
                    plot(a(:,7),'k-');
                    ax=axis;
                    plot([on.sample on.sample],[ax(3) ax(4)],'g-');
                    plot([off.sample off.sample],[ax(3) ax(4)],'r-');
                    plot(pa.sample(7),a(pa.sample(7),7),'b^');
                    plot(pv.sample(7),a(pv.sample(7),7),'ks');
                    plot(pd.sample(7),a(pd.sample(7),7),'bv');
                    xlabel('Sample number');  
                    ylabel('3D acceleration');
                    hold off;
        end
    end
end                                                                                                 % end of function