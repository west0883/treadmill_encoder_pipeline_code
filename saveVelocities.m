function [] = saveVelocities(parameters)

    % Give parameters their original names
    mice_all = parameters.mice_all;
    dir_dataset_name = parameters.dir_dataset_name;
    input_data_name = parameters.input_data_name;
    dir_exper = parameters.dir_exper; 
    k = parameters.k; 
    digitNumber = parameters.digitNumber; 
    skip = parameters.skip; 
    wheel_Hz = parameters.wheel_Hz;
    fps = parameters.fps; 
    channelNumber = parameters.channelNumber;
    skip = parameters.skip;
    frames = parameters.frames;
    
    % Establish base input directory
    dir_in_base=[dir_exper 'behavior\formatted encoder data\'];
    
    dir_out_base=[dir_exper 'behavior\velocity trace per stack\'];
   
    % Tell user where data is being saved
    disp(['Data saved in ' dir_out_base]); 
    
    % Convert the skip from brain imaging frames to wheel sampling time
    % points. Divide by brain sampling rate to get seconds to skip,
    % multiply by wheel sampling to get to number of wheel timepoints to
    % skip. Extra parentheses written for clarity.
    skip_converted = (skip / (fps * channelNumber)) * wheel_Hz; 
    
    % For each mouse 
    for mousei=1:size(mice_all,2)
        mouse=mice_all(mousei).name;
        
        % For each day
        for dayi=1:size(mice_all(mousei).days, 2)
            
            % Get the day name.
            day=mice_all(mousei).days(dayi).name; 
            
            % Create data input directory and cleaner output directory. 
            dir_in = [dir_in_base mouse '\' day '\'];
            dir_out=[dir_out_base mouse '\' day '\']; 
            mkdir(dir_out); 
            
            % Get the stack list
            [stackList]=GetStackList(mousei, dayi, mice_all, dir_in, input_data_name, digitNumber);
            
            % For each stack, 
            for stacki=1:size(stackList.filenames,1)
                
                % Get the stack number and filename for the stack.
                stack_number = stackList.numberList(stacki, :);
                filename = stackList.filenames(stacki, :);
                
                % Load the stack. 
                load([dir_in filename]);
                
                % Remove the skip period, if any.
                trial.position = trial.position(skip_converted + 1 : end); 
                
                % Smooth the postition data of the wheel 
                smooth=movmean(trial.position,k); 
             
                % Take the derivative of the smoothed position data to get
                % velocity (cm/s). 
                % Multiply by 1000 (the wheel_Hz)because the dt (sampling rate is 1000 Hz
                % so not multiplying by 1000 would give you cm / ms. 
                vel.uncorrected=diff(smooth)*wheel_Hz;  
               
                % Also correct the trace 
                % correct the velocity
                correcting_timeseries=(0:(frames-1)).*wheel_Hz./fps; 
                correcting_timeseries(1)=1; % don't let it be a 0

                if correcting_timeseries(end)>size(vel.uncorrected,1)
                    ind=find((correcting_timeseries-size(vel.uncorrected,1))<=0,1, 'last'); % find the closest values of correcting_timeseries that matches the size of vel (without going over) and stop correcting_timeseries at that point
                    correcting_timeseries=correcting_timeseries(1:ind);  
                end 
                vel.corrected=[vel.uncorrected(correcting_timeseries)]; 
                
                % Save velocity trace. 
                save([dir_out 'vel' stack_number '.mat'], 'vel'); 
                
            end
        end
    end
end