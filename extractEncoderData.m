% extractEncoderData.m
% Sarah West
% 10/11/21

% Extracts rotary encoder data from .txt or PUTTY .log files and saves them 
% as .mat files. 

function [] = extractEncoderData(parameters)

    % Give parameters their original names
    mice_all = parameters.mice_all;
    dir_dataset_name = parameters.dir_dataset_name;
    input_data_name = parameters.input_data_name;
    dir_exper = parameters.dir_exper; 
    wheel_Hz = parameters.wheel_Hz;
    putty_flag = parameters.putty_flag;
    wheel_radius = parameters.wheel_radius;
    digitNumber = parameters.digitNumber; 
    
    % Establish base output directory
    dir_out_base=[dir_exper 'behavior\extracted encoder data\'];
    
    % Tell user where data is being saved
    disp(['Data saved in ' dir_out_base]); 
    
    % For each mouse 
    for mousei=1:size(mice_all,2)
        mouse=mice_all(mousei).name;
        
        % For each day
        for dayi=1:size(mice_all(mousei).days, 2)
            
            % Get the day name.
            day=mice_all(mousei).days(dayi).name; 
            
            % Create data input directory and cleaner output directory. 
            dir_in=CreateFileStrings(dir_dataset_name, mouse, day, [], [], false);
            parameters.dir_in = dir_in;
            dir_out=[dir_out_base mouse '\' day '\']; 
            mkdir(dir_out); 
            
            % Get the stack list
            [stackList]=GetStackList(mousei, dayi, parameters);
            
            % If not using PUTTY
            if ~putty_flag 
                
                % Cycle through the stack files. 
                for stacki=1:size(stackList.filenames,1)

                    % Get the stack number and filename for the stack.
                    stack_number = stackList.numberList(stacki, :);
                    filename = stackList.filenames(stacki, :);
                    
                    % Need to import and convert these, too. 

                end
            
            % If using PUTTY 
            else 
                
                % Find the PUTTY log file name. 
                filelist = dir([dir_in input_data_name{1}]);
                logFile = convertCharsToStrings([dir_in filelist.name]);
                % Run convertEnc2Cm.m function
                [converted] = convertEnc2Cm(logFile, 'True', wheel_radius);
                
                % Separate into separate trial files to match later
                % processing
                
                for stacki = 1:size(converted,2)
                    
                    trial.stack_number = sprintf(['%0' num2str(digitNumber) 'd'], converted(stacki).trialNum); 
                    trial.trialTime = converted(stacki).trialTime; 
                    trial.positions = converted(stacki).positions; 
                    trial.velocities = converted(stacki).velocities;
                    trial.totalDist = converted(stacki).totalDist; 
                    
                    % Save each trial. 
                    save([dir_out 'trial' trial.stack_number '.mat'], 'trial'); 
                    
                end     
                
            end
        end
    end 

end 