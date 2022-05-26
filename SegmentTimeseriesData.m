% SegmentTimeseriesData.m
% Sarah West
% 10/13/21

% A function that segments timeseries data using a list of start and end points for each behvior. 
% Is general, so you can use with all kinds of timeseries data. 


function [] = SegmentTimeseriesData(periods_all, parameters)
    
    % Give parameters easier names. 
    dir_in_data_base = parameters.dir_in_data_base;
    input_data_name = parameters.input_data_name;
    input_data_variable = parameters.input_data_variable;
    dir_in_segment_base = parameters.dir_in_segment_base;
    input_segment_name = parameters.input_segment_name;
    input_segment_variable = parameters.input_segment_variable;
    dir_out_base = parameters.dir_out_base;
    segmentDim = parameters.segmentDim;
    concatDim = parameters.concatDim;
    output_filename = parameters.output_filename;
    output_variable = parameters.output_variable;
    mice_all = parameters.mice_all; 
    digitNumber = parameters.digitNumber;
    time_window_seconds = parameters.time_window_seconds;
    fps = parameters.fps; 
    full_transition_extra_time = parameters.full_transition_extra_time;
    
    % For each mouse 
    for mousei=1:size(mice_all,2)
        mouse=mice_all(mousei).name;
      
        % For each day
        for dayi=1:size(mice_all(mousei).days, 2)
            
            % Get the day name.
            day=mice_all(mousei).days(dayi).name; 
            
            % Create data input directory and cleaner output directory. 
            dir_in_segment = [dir_in_segment_base mouse '\' day '\'];
            dir_in_data = [dir_in_data_base mouse '\' day '\'];
            parameters.dir_in = dir_in_data;
            dir_out=[dir_out_base mouse '\' day '\']; 
            mkdir(dir_out); 
            
            % Get the velocities stack list
            [stackList]=GetStackList(mousei, dayi, parameters);
            
            % For each stack, 
            for stacki= 1:size(stackList.filenames,1)
                
                % Get the stack number and filename for the stack.
                stack_number = stackList.numberList(stacki, :);
                filename = stackList.filenames(stacki, :);
                
                % Load the timeseries stack. 
                load([dir_in_data filename]);
                
                % Change the variable name of the timeseries data to
                % something generic. 
                eval(['Timeseries= ' input_data_variable ';']);
                
                
                % Get the filename of corresponding behavior segments.
                segment_filename = CreateFileStrings(input_segment_name,[], [], stack_number, [], false);
                
                % load corresponding behavior segments. 
                load([dir_in_segment segment_filename]); 
                
                % For each period,
                for periodi = 1:size(periods_all,1)
                    period = periods_all{periodi};
                    
                    % Make an empty matrix. 
                    segmented_data = []; 
                    
                    % Get relevant segment variable name
                    variable_name = CreateFileStrings(input_segment_variable,[], [], [], period, false);
                    
                    % Change segment ranges name to something generic. 
                    eval(['segment_ranges = ' variable_name ';']);
                    
                    % Take the ranges using a flexible number of dimensions
                    % C is a holder of as many ':' indices as we need.
                    C = repmat({':'},1, ndims(timeseries));
                    
                    % Change the time window to look at if it's a full
                    % transition.
                    if strcmp (period, 'full_onset') | strcmp(period, 'full_offset')
                        time_window_use = (time_window_seconds + full_transition_extra_time)*2;
                    else
                        time_window_use = time_window_seconds;
                    end 
                       
                    % If no segment ranges, 
                    if isempty(segment_ranges)
                        % Do nothing.
                    else
                    
                        % For each instance 
                        for instancei = 1 : size(segment_ranges, 1)
                            
                            % Convert the ranges to time points. 
                            all_ranges = segment_ranges(instancei,1):segment_ranges(instancei,2);
                            
                            % Get only the number of points that fit into
                            % the time window 
                            C(segmentDim) = {all_ranges(1: fps * time_window_use )};  %This is our index into timeseries.  
                            
                            % Concatenate
                            segmented_data =cat(concatDim, segmented_data, Timeseries(C{:})); 
                        end 
                    end 
                    % Get the output variable name
                    output_variable_name = CreateFileStrings(output_variable,[], [], [], period, false);
                    
                    % Convert segmented data to the desired variable name
                    eval([output_variable_name ' = segmented_data;']);
                end 
                
                % Get the right names for saving per stack. 
                variable_searching_name = CreateFileStrings(output_variable,[], [], [], period, true);
                saving_filename = CreateFileStrings(output_filename,[], [], stack_number, [], false);
                
                % Save per stack. 
                save([dir_out saving_filename], variable_searching_name); 
            end
        end
    end
end 