function [parameters] = saveVelocities(parameters)

    % Give parameters their original names
    k = parameters.k;  
    wheel_Hz = parameters.wheel_Hz;
    fps = parameters.fps; % sampling rate of encoder
    channelNumber = parameters.channelNumber; %
    skip = parameters.skip;
    frames = parameters.frames;
    trial = parameters.trial;

    % Convert the skip from brain imaging frames to wheel sampling time
    % points. Divide by brain sampling rate to get seconds to skip,
    % multiply by wheel sampling to get to number of wheel timepoints to
    % skip. Extra parentheses written for clarity.
    skip_converted = (skip / (fps * channelNumber)) * wheel_Hz; 
    
    % Remove the skip period, if any.
    trial.position = trial.position(skip_converted + 1 : end); 
    
    % Smooth the postition data of the wheel 
    smooth=movmean(trial.position,k); 
 
    % Take the derivative of the smoothed position data to get
    % velocity (cm/s). 
    % Multiply by 1000 (the wheel_Hz)because the dt (sampling rate is 1000 Hz
    % so not multiplying by 1000 would give you cm / ms. 
    vel.uncorrected = diff(smooth)*wheel_Hz;  
   
    % Also correct the trace 
    % correct the velocity
    correcting_timeseries=(0:(frames-1)).*wheel_Hz./fps; 
    correcting_timeseries(1)=1; % don't let it be a 0

    if correcting_timeseries(end)>size(vel.uncorrected,1)
        ind=find((correcting_timeseries-size(vel.uncorrected,1))<=0,1, 'last'); % find the closest values of correcting_timeseries that matches the size of vel (without going over) and stop correcting_timeseries at that point
        correcting_timeseries=correcting_timeseries(1:ind);  
    end 
    vel.corrected=[vel.uncorrected(correcting_timeseries)]; 

    parameters.velocity = vel;
 
end