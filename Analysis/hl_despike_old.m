% function despiked=hl_despike(input,sds,threeD)
% removes single time-point spikes from data, based on Z-score outliers in the 2nd differential
% does each channel separately, then 3D data as follows:
% if 2-3 columns, then
% hl_despike(input [,SDs] [,threeD])
% input = column(s) of data to remove spikes from (2D matrices only)
% SDs = optional number of SDs for outlier-cutoff, defaults to 3
% threeD: 0=don't calculate 3D data, 1=do; for 3D or 6D data only
function despiked=hl_despike(input,sds,threeD)
    if nargin==1
        sds=3;
        threeD=0;
    end
    if nargin==2
        threeD=0;
    end
    if isempty(sds)
        sds=3;
    end
    if isempty(threeD)
        threeD=0;
    end
    samples=size(input,1);
    channels=size(input,2);
    despiked=input;
    if threeD==1
        switch channels
            case 1
                a=input;   
            case 3
                a=zeros(samples,channels+1);
                a(:,1:channels)=input;
                a(:,channels+1)=sqrt(sum(a(:,1:3).^2,2));                           % 3D data
            case 6
                a=zeros(samples,channels+2);
                a(:,1:channels)=input;
                a(:,channels+1)=sqrt(sum(a(:,1:3).^2,2));                           % 3D data
                a(:,channels+2)=sqrt(sum(a(:,4:6).^2,2));                           % 3D data
            otherwise
                a=input;
        end
    else
        a=input;
    end
    a(2:samples,1:channels)=input(2:samples,:)-input(1:samples-1,:); a(1,:)=a(2,:); % 1st differential
    a(2:samples,:)=a(2:samples,:)-a(1:samples-1,:); a(1,:)=a(2,:);                  % 2nd differential
    for n=1:channels
        a(:,n)=(a(:,n)-mean(a(:,n)))./std(a(:,n));                                  % Z-score
        spikes=find(abs(a(:,n))>sds);                                               % outliers
        for s=1:size(spikes)
            switch spikes(s)
                case 1
                    despiked(1,n)=despiked(2,n);                                    % if first sample, replace with second
                case 2
                    sdespiked(2,n)=mean(despiked([1,3],n),1);                       % if second sample, replace with mean of first and third         
                case 3
                    sdespiked(3,n)=mean(despiked([2,4],n),1);                       % if third sample, replace with mean of second and fourth
                case samples
                    despiked(samples,n)=despiked(samples-1,n);                      % if last sample, replace with penultimate
                otherwise
                    for n=1:3                                                       % interpolate the 3 points around the spike, for this channel only
                        despiked(spikes(s)-3+n,n)=despiked(spikes(s)-3,n)+((despiked(spikes(s)+1,n)-despiked(spikes(s)-3,n)).*(n./4));
                    end        
            end
        end
    end
    if threeD==1
        for n=channels+1:size(a,2)
            a(2:samples,n)=a(2:samples,n)-a(1:samples-1,n); a(1,n)=a(2,n);          % 1st differential
            a(2:samples,n)=a(2:samples,n)-a(1:samples-1,n); a(1,n)=a(2,n);          % 2nd differential   
            a(:,n)=(a(:,n)-mean(a(:,n)))./std(a(:,n));                              % Z-score
            spikes=find(abs(a(:,n))>sds);                                           % outliers
            for s=1:size(spikes)
                switch spikes(s)
                    case 1
                        despiked(1,:)=despiked(2,:);                                % if first sample, replace with second
                    case 2
                        sdespiked(2,:)=mean(despiked([1,3],:),1);                   % if second sample, replace with mean of first and third 
                    case 3
                        sdespiked(3,:)=mean(despiked([2,4],:),1);                   % if third sample, replace with mean of second and fourth
                    case samples
                        despiked(samples,:)=despiked(samples-1,:);                  % if last sample, replace with penultimate
                    otherwise
                        for p=1:3                                                   % interpolate 3 points around the spike, in ALL channels
                            despiked(spikes(s)-3+p,:)=despiked(spikes(s)-3,:)+((despiked(spikes(s)+1,:)-despiked(spikes(s)-3,:)).*(p./4));
                        end
                end
            end
        end
    end
end