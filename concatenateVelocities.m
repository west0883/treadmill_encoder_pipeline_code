% concatenateVelocities.m
% Sarah West
% 10/12/21

% Takes 3- second behavior periods per mouse and saves them all in the same
% matrix. 

function [] = concatenateVelocities(parameters)
    
    % Give parameters their original names
    mice_all = parameters.mice_all;
    dir_exper = parameters.dir_exper;
    digitNumber = parameters.digitNumber;
    periods_long = parameters.periods_long;   
    periods_transition = parameters.periods_transition;
    full_transition_flag = parameters.full_transition_flag;  
    periods_full_transition =parameters.periods_full_transition;                 
    
    % Specify dimension to concatenate across.
    parameters.concatDim = 2;
    
    % Establish input directory for velocity
    parameters.dir_input_base = [dir_exper 'behavior\encoder velocity segmented by behavior\'];
    
    % Input data name for velocity
    parameters.input_file_name= {'segmented_velocities_', 'stack number', '.mat'}; 
     
    % Get the input variable name ;
    parameters.input_variable_name = {'vel_', 'period name'}; 
  
    % Establish base output directory
    parameters.dir_out_base=[dir_exper 'behavior\encoder all behavior instances per mouse\'];
    
     % Output file name. 
    parameters.output_file_name = {'period name', '_all_velocities.mat'}; 
    
    % Output variable name
    parameters.output_variable_name = {'all_velocities'}; 
    
    % Tell user where data is being saved
    disp(['Data saved in ' parameters.dir_out_base]); 
    
    % Put all periods into a single cell array. 
    % If user asked for full onsets/full offsets, add those to the save list, too. 
     if isfield(parameters, 'full_transition_flag')  
        if parameters.full_transition_flag
            parameters.periods_all = [parameters.periods_long; parameters.periods_transition; parameters.periods_full_transition];
        else
            parameters.periods_all = [parameters.periods_long; parameters.periods_transition]; 
        end
    end 
    
    ConcatenateDataPerMouse(parameters.periods_all, parameters);

end 