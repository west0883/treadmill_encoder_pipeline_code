function [] = saveVelocities(parameters)

    % Give parameters their original names
    mice_all = parameters.mice_all;
    dir_dataset_name = parameters.dir_dataset_name;
    input_data_name = parameters.input_data_name;
    dir_exper = parameters.dir_exper; 
    k = parameters.k; 
    digitNumber = parameters.digitNumber; 
    
    % Establish base input directory
    dir_in_base=[dir_exper 'behavior\formatted encoder data\'];
    
    dir_out_base=[dir_exper 'behavior\velocity trace per stack\'];
   
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
            dir_in = [dir_in_base mouse '\' day '\'];
            dir_out=[dir_out_base mouse '\' day '\']; 
            mkdir(dir_out); 
            
            % Get the stack list
            [stackList]=GetStackList(mousei, dayi, dir_in, parameters);
            
            % For each stack, 
            for stacki=1:size(stackList.filenames,1)
                
                % Get the stack number and filename for the stack.
                stack_number = stackList.numberList(stacki, :);
                filename = stackList.filenames(stacki, :);
                
                % Load the stack. 
                load([dir_in filename])
            
                % Smooth the postition data of the wheel 
                smooth=movmean(trial.position,k); 
             
                % Take the derivative of the smoothed position data to get
                % velocity (cm/s). 
                % Multiply by 1000 because the dt (sampling rate is 1000 Hz
                % so not multiplying by 1000 would give you cm / ms. 
                vel=diff(smooth)*1000;  
               
                % Save velocity trace. 
                save([dir_out 'vel' stack_number '.mat'], 'vel'); 
                
            end
        end
    end
end