% ConcatenateDataAcrossMice.m
% Sarah West
% 10/15/21
% Averages and takes stndard devaiation of data per mouse. 

function [] =ConcatenateDataAcrossMice(periods_all, parameters)
    
    % Give parameters easier names. 
    dir_input_base = parameters.dir_input_base;
    input_file_name = parameters.input_file_name;
    input_variable_name = parameters.input_variable_name;
    dir_out_base = parameters.dir_out_base;
    concatDim = parameters.averageDim;
    output_file_name = parameters.output_file_name;
    output_variable_name = parameters.output_variable_name;
    mice_all = parameters.mice_all; 
    
    
    % Establish output directory.
    dir_out = [dir_out_base '\']; 
    mkdir(dir_out);
        
    % For each period,
    for periodi = 1:size(periods_all, 1) 
        period = periods_all{periodi};

        % Initialize empty matrix for holding pre-concatenated data 
        concatenated_data = [];
        
        % Make a matrix to hold on to the names of each mouse.
        mice_labels = cell(size(mice_all,2), 1);
        
        % For each mouse 
        for mousei=1:size(mice_all,2)
            mouse=mice_all(mousei).name;
           
            mice_labels{mousei} = mouse;
            
            % Get the input directory
            dir_in = [dir_input_base '\' mouse '\'];
            
            % Get specific name of input filename.
            file_name_input = CreateFileStrings(input_file_name,[], [], [], period, false);
            
            % Load the data.
            load([dir_in file_name_input]); 

            % Get specific name of input variable
            variable_name_input = CreateFileStrings(input_variable_name,[], [], [], period, false);
           
            % Get the data that corresponds to that period, assign it
            % a generic name.
            eval(['mouse_instances = ' variable_name_input ';']); 

            % Concatenate data (ONLY THE MEAN OF EACH)
            concatenated_data = cat(concatDim, concatenated_data, mouse_instances.mean);
            
        end
        % Take mean and std. You want to take it of the MEAN per
        % animal. 
        holder.mean = nanmean(concatenated_data, concatDim); 
        holder.std = std(concatenated_data, [], concatDim, 'omitnan');

        % Put data into same structure.
        holder.all_mice =concatenated_data;
        holder.mouse = mice_labels;

        % Get specific name of output variable
        variable_name_output = CreateFileStrings(output_variable_name,[], [], [], period, false);

        % Change matrix name to output-specific name.
        eval([variable_name_output ' = holder;']); 

        % Get specific name of file.
        filename_output = CreateFileStrings(output_file_name,[], [], [], period, false);

        % Save
        save([dir_out filename_output], variable_name_output);

    end
end 