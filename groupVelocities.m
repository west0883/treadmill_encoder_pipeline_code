% groupVelocities.m
% Sarah West
% 10/12/21

% Takes 3- second behavior periods per mouse and saves them all in the same
% matrix. 

function [] = groupVelocities(parameters)
% Give parameters their original names
    mice_all = parameters.mice_all;
    dir_exper = parameters.dir_exper;
    dir_exper = parameters.dir_exper; 
    wheel_Hz = parameters.wheel_Hz;
    digitNumber = parameters.digitNumber;
    fps = parameters.fps; 
    frames = parameters.frames;
    skip = parameters.skip; 
    putty_flag = parameters.putty_flag;
    wheel_radius = parameters.wheel_radius;
    periods_long_threshold = parameters.periods_long_threshold;
    periods_long = parameters.periods_long;   
    periods_transition = parameters.periods_transition;
    periods_long_searchorder = parameters.periods_long_searchorder;
    k = parameters.k; 
    time_window_seconds = parameters.time_window_seconds;
    time_window_frames = parameters.time_window_frames;
    time_window_hz = parameters.time_window_hz;
    full_transition_flag = parameters.full_transition_flag;  
    periods_full_transition =parameters.periods_full_transition;                 
    full_transition_extra_time = parameters.full_transition_extra_time;                  
    full_transition_extra_hz = parameters.full_transition_extra_hz;
    
    % Put all 3-second periods into a single cell array. 
    periods = [periods_long; periods_transition]; 
    
    % Establish input directory for velocity
    dir_vel_base = [dir_exper 'behavior\velocity trace per stack\'];
    
    % Establish input directory for behavior periods
    dir_behavior_base = [dir_exper 'behavior\segmented behavior periods\'];
    
    % Input data name for velocity
    input_data_name= {'vel', 'stack_number', '.mat'}; 
    
    % Establish base output directory
    dir_out_base=[dir_exper 'behavior\all behavior instances per mouse\'];
    
    % Tell user where data is being saved
    disp(['Data saved in ' dir_out_base]); 
    
    % For each mouse 
    for mousei=1:size(mice_all,2)
        mouse=mice_all(mousei).name;
        
        % Establish output directory for this mouse.
        dir_out = [dir_out_base mouse '\']; 
        mkdir(dir_out);

        % Initialize empty matrices of each period for the mouse.
        for periodi = 1:size(periods, 1) 

            % Get the period 
            period = periods{periodi};
            
            % Make empty matrices; 
            eval([period '_instances_all = [];']);
        
        end 
        
        % If user asked for full onsets/full offsets, make matrices for
        % that, too. 
        if full_transition_flag
            
            for periodi = 1:size(periods_full_transition, 1) 

            % Get the period 
            period = periods_full_transition{periodi};
            
            % Make empty matrices; 
            eval([period '_instances_all = [];']);
            end 
        end
        
        % For each day
        for dayi=1:size(mice_all(mousei).days, 2)
            
            % Get the day name.
            day=mice_all(mousei).days(dayi).name; 
            
            % Establish more specific input directories 
            dir_vel = [dir_vel_base mouse '\' day '\'];
            dir_behavior = [dir_behavior_base mouse '\' day '\'];
            
            % Get the velocity stack list
            [stackList]=GetStackList(mousei, dayi, dir_vel, parameters);
            
            % For each stack, 
            for stacki=1:size(stackList.filenames,1)
                
                % Get the stack number and filename for the stack.
                stack_number = stackList.numberList(stacki, :);
                filename = stackList.filenames(stacki, :);
                
                % Load the velocity 
                load([dir_vel filename])
                
                % Load the corresponding behavior periods.
                load([dir_behavior 'behavior_periods_' stack_number '.mat']);
                
                % For each period,
                for periodi = 1:size(periods, 1) 
                    
                    % Get the period 
                    period = periods{periodi};
                    
                    % Get the velocity that corresponds to that period.
                    
                    
                    % Concatenate instances. 
                    eval([period '_instances_all = [' period '_instances_all; ' period '_periods_correct];']);
                end 
                
                % If user asked for full onsets/full offsets, concatenate
                % that, too. 
                if full_transition_flag
                    
                    % Load the behavior periods.
                    load([dir_behavior 'full_transitions_' stack_number '.mat'])
                    
                    for periodi = 1:size(periods_full_transition, 1) 

                        % Get the period 
                        period = periods_full_transition{periodi};
                        
                        % Get the velocity that corresponds to that period.
                        
                        
                        % Concatenate instances. 
                        eval([period '_instances_all = [' period '_instances_all; ' period '_periods];']);
                    end 
                end
            end
        end
        
        % Save matrices for the mouse 
        
        % If user asked for full onsets/full offsets, add those to the save list, too. 
        if full_transition_flag
            periods_all = [periods; periods_full_transition];
        
        else
            periods_all = periods;     
        end
        
        % Save matrices.
        for periodi = 1:size(periods_all, 1) 
            period = periods_all{periodi};
            
            save([dir_out period '_instances_all.mat'], [period '_instances_all']);
        end
        
    end
end 