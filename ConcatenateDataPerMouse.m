% ConcatenateDataPerMouse.m
% Sarah West
% 10/13/21

% A function that groups together data across days and stacks per mouse. Is
% general, so you can use with all kinds of data. 

% Is inefficient in that it loads everything for each period, but I'd
% rather do that and keep the high-level processes like "eval" out of this
% function as much as possible.

% The "input variable name" should have the period specified in it.

function [concatenated_data] = ConcatenateDataPerMouse(periods_all, parameters)
    
    % Give parameters easier names. 
    dir_input_base = parameters.dir_input_base;
    input_file_name = parameters.input_file_name;
    input_variable_name = parameters.input_variable_name;
    dir_out_base = parameters.dir_out_base;
    concatDim = parameters.concatDim;
    output_file_name = parameters.output_file_name;
    output_variable_name = parameters.output_variable_name;
    mice_all = parameters.mice_all; 
    digitNumber = parameters.digitNumber;

     % For each mouse 
    for mousei=1:size(mice_all,2)
        mouse=mice_all(mousei).name;
        
        % Initialize empty matrix of each period for the mouse.
        for periodi = 1:size(periods_all, 1) 
            period = periods_all{periodi};
            
           eval([period '_concatenated_data = [];']); 
        end
        
        % Establish output directory for this mouse.
        dir_out = [dir_out_base mouse '\']; 
        mkdir(dir_out);
        
        % For each day
        for dayi=1:size(mice_all(mousei).days, 2)

            % Get the day name.
            day=mice_all(mousei).days(dayi).name; 

            % Establish more specific input directories 
            dir_in = [dir_input_base mouse '\' day '\'];

            % Get the velocity stack list
            [stackList]=GetStackList(mousei, dayi, mice_all, dir_in, input_file_name, digitNumber);

            % For each stack, 
            for stacki=1:size(stackList.filenames,1)

                % Get the stack number and filename for the stack.
                stack_number = stackList.numberList(stacki, :);
                filename = stackList.filenames(stacki, :);

                % Load the data
                load([dir_in filename]);
                
                % For each period,
                for periodi = 1:size(periods_all, 1) 
                    period = periods_all{periodi};
                    
                    % Switch concatenated data to a generic name 
                    eval(['concatenated_data = ' period '_concatenated_data;']); 

                    % Get specific name of variable
                    variable_name_input = CreateFileStrings(input_variable_name,[], [], [], period, false);

                    % Get the data that corresponds to that period
                    eval(['instances = ' variable_name_input ';']); 
                 
                    % Concatenate instances across specified dimension.
                    concatenated_data = cat(concatDim, concatenated_data, instances);
                    
                    % Switch concatenated data back to period-specific
                    % name.
                    eval([period '_concatenated_data = concatenated_data;']); 
                    
                end
            end
        end
    
         % Save matrix for each period for each mouse 
         % For each period,
         for periodi = 1:size(periods_all, 1) 
             period = periods_all{periodi};
        
             % Get specific name of variable
             variable_name_output = CreateFileStrings(output_variable_name,[], [], [], period, false);
             
             % Change matrix name to output-specific name.
             eval([variable_name_output ' = ' period '_concatenated_data;']); 
             
             % Get specific name of file.
             filename_output = CreateFileStrings(output_file_name,[], [], [], period, false);
             
             % Save
             save([dir_out filename_output], variable_name_output);
        
         end 
    end
end 