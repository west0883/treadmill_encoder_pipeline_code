% segmentVelocities.m
% Sarah West
% 10/13/21

% Segments velocities by calling the SegmentData function.

function [] = segmentVelocities(parameters)

    % Give parameters their original name
    dir_exper = parameters.dir_exper;     
    periods_long = parameters.periods_long;   
    periods_transition = parameters.periods_transition;
    full_transition_flag = parameters.full_transition_flag;  
    periods_full_transition =parameters.periods_full_transition;                 

    % Establish input directory for velocity
    parameters.dir_in_data_base = [dir_exper 'behavior\velocity trace per stack\'];
    
    % Input data name for velocity
    parameters.input_data_name= {'vel', 'stack number', '.mat'}; 
    
    % Input variable name for velocity
    parameters.input_data_variable= 'vel.corrected'; 
    
    % Establish input directory for behavior segments
     parameters.dir_in_segment_base = [dir_exper 'behavior\encoder segmented behavior periods\'];
    
    % Input data name for behavior segments
     parameters.input_segment_name = {'behavior_periods_', 'stack number', '.mat'}; 
    
    % Input variable name for behavior segments
     parameters.input_segment_variable = {'period name', '_periods_correct'}; 
  
    % Establish base output directory
    parameters.dir_out_base=[dir_exper 'behavior\encoder velocity segmented by behavior\'];
    
    % Output file name. 
    parameters.output_filename = {'segmented_velocities_', 'stack number', '.mat'}; 
    
    % Output variable name
    parameters.output_variable = {'vel_', 'period name'}; 
  
    % Establish segmentation dimension.
    parameters.segmentDim = 1;
    
    % Establish concatenation dimension.
    parameters.concatDim = 2;
    
    % Say that you want the time segmentation to be set to a pre-defined
    % length
    parameters.use_set_window = true;
    
    % Tell user where data is being saved
    disp(['Data saved in '  parameters.dir_out_base]); 
    
    % Put all periods into a single cell array. 
    % If user asked for full onsets/full offsets, add those to the save list, too. 
    if full_transition_flag
        periods_all = [periods_long; periods_transition; periods_full_transition];

    else
        periods_all = [periods_long; periods_transition]; 
    end
    
    SegmentTimeseriesData(periods_all, parameters);
    
  
end 