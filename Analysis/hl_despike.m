% function despiked=hl_despike(input[,thresh][,interp][, verbose][, fignum])
% removes single time-point spikes from data, based on Z-score outliers in the 2nd differential, summed across all dimensions
% INPUTS
% input = column(s) of data to remove spikes from (2D matrices only)
% thresh = optional number for outlier-cutoff, defaults to the mean of positive (non-reversing) samples
% interp = how many time-points to smooth before and after each sample? default=1
% verbose = display output, default=0
% fignum = send output to a figure
% OUTPUTS
% despiked = despiked data
% s = number of spikes replaced
function [despiked,s]=hl_despike(input,thresh,interp,verbose,fignum)        % function call

    %% PROCESS INPUTS______________________________________________________
    despiked=input;                                                         % copy input data
    if nargin==1                                                            % if 1 argument passed
        thresh=[];                                                          % set threshold to default
        interp=1;                                                           % datapoints before and after for interpolation
        verbose=0;                                                          % no output
        fignum=1;                                                           % figure number
    elseif nargin==2                                                        % if 2 arguments
        interp=1;                                                           % datapoints before and after for interpolation        
        verbose=0;                                                          % no output
        fignum=1;                                                           % figure number
    elseif nargin==3                                                        % if 3 arguments   
        verbose=0;                                                          % no output
        fignum=1;                                                           % figure number
    elseif nargin==4                                                        % if 3 arguments   
        fignum=1;                                                           % figure number
    end
    if isempty(interp)                                                      % if empty interp argument given                                                
        interp=1;                                                           % set interp to default
    end
    if isempty(verbose)                                                     % if empty verbose argument give
        verbose=0;                                                          % set verbose to default
        fignum=1;                                                           % figure number
    end     
    if size(despiked,1)<size(despiked,2)                                    % if array given in wrong orientation
        despiked=despiked';                                                 % transpose array
    end
    samples=size(despiked,1);                                               % samples=number of rows
    dimensions=size(despiked,2);                                            % dimensions=number of columns                          
    
    %% FIND AND FILTER SPIKES______________________________________________
    d1=nan(samples,size(despiked,2));                                       % create new array for 1st differential
    d1(2:samples,:)=diff(despiked);                                         % calculate 1st differential
    d1p=d1./abs(d1);                                                        % polarity of velocity: large velocity reversals = potential spikes
    d1ps=nansum(d1(1:end-1,:).*d1p(2:end,:),2);                             % sum of velocity * polarity of next velocity across dimensions; large negative = potential spike
    if isempty(thresh)
        thresh=mean(d1ps(d1ps>0))./2;                                       % default to half the mean of positive (non-reversing) velocitys
    end
    spikes=find(d1ps<-thresh);
    for s=1:size(spikes)                                                    % for each spike
        for d=1:dimensions
            if spikes(s)<interp+1                                           % if the index of the spike is less than the required interpolation value...
            elseif spikes(s)>samples-interp                                 % if spike index is greater than last possible interpolation value...
            else                                                            % interpolate from interp samples before and after
                for i=1:(interp.*2)-1                                       % for each point that needs to be altered
                    start=despiked(spikes(s)-interp,d);                     % value at start of window to interpolate
                    finish=despiked(spikes(s)+interp,d);                    % value at end of window to interpolate
                    despiked(spikes(s)-interp+i,d)=start+(i.*(finish-start)./(interp.*2));%replace datapoint with interpolated point
                end
            end
        end
        if verbose>0
            disp([int2str(s),' spikes replaced']);                          % information
            if verbose>1
                figure(fignum);
                subplot(3,1,1);
                plot(input);
                ylabel('Raw');
                subplot(3,1,2);
                plot(despiked);
                ylabel('Despiked');
                subplot(3,1,3);
                plot(input-despiked);
                ylabel('Difference');
            end
        end
    end
end