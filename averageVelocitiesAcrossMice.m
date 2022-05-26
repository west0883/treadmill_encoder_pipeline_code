function [] = averageVelocitiesAcrossMice(parameters)
    
    % Give parameters their original names
    dir_exper = parameters.dir_exper;
    periods_long = parameters.periods_long;   
    periods_transition = parameters.periods_transition;
    full_transition_flag = parameters.full_transition_flag;  
    periods_full_transition =parameters.periods_full_transition;                 
    
    % Specify dimension to concatenate and average across
    parameters.concatDim = 2;
    
    % Establish input directory for velocity
    parameters.dir_input_base = [dir_exper 'behavior\encoder all behavior instances per mouse\'];
    
    % Input data name for velocity
    parameters.input_file_name= {'period name', '_all_velocities.mat'}; 
     
    % Get the input variable name ;
    parameters.input_variable_name = {'all_velocities'}; 
  
    % Establish base output directory
    parameters.dir_out_base=[dir_exper 'behavior\encoder average velocity across mice\'];
    
     % Output file name. 
    parameters.output_file_name = {'period name', '_velocity_across_mice.mat'}; 
    
    % Output variable name
    parameters.output_variable_name = {'velocity_across_mice'}; 
    
    % Tell user where data is being saved
    disp(['Data saved in ' parameters.dir_out_base]); 
    
    % Put all periods into a single cell array. 
    % If user asked for full onsets/full offsets, add those to the save list, too. 
    if full_transition_flag
        periods_all = [periods_long; periods_transition; periods_full_transition];

    else
        periods_all = [periods_long; periods_transition]; 
    end
    
    % Run averaging
    ConcatenateDataAcrossMice(periods_all, parameters);
    
end