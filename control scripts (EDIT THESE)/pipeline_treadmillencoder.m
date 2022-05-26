% pipeline_treadmillencoder.m
% Sarah West
% 9/9/21 

% Use "create_mice_all.m" before using this.

%% Initial setup
% Put all needed paramters in a structure called "parameters", which you
% can then easily feed into your functions. 
clear all; 

% Output Directories

% Create the experiment name. This is used to name the output folder. 
parameters.experiment_name='Random Motorized Treadmill';

% Output directory name bases
parameters.dir_base='Y:\Sarah\Analysis\Experiments\';
parameters.dir_exper=[parameters.dir_base parameters.experiment_name '\']; 

% *********************************************************
% Data to preprocess

% (DON'T EDIT). Load the "mice_all" variable you've created with "create_mice_all.m"
load([parameters.dir_exper 'mice_all.mat']);

% Add mice_all to parameters structure.
parameters.mice_all = mice_all; 

% ****Change here if there are specific mice, days, and/or stacks you want to work with**** 
% If you want to change the list of stacks, use ListStacks function.
% Ex: numberVector=2:12; digitNumber=2;
% Ex cont: stackList=ListStacks(numberVector,digitNumber); 
% Ex cont: mice_all(1).stacks(1)=stackList;

parameters.mice_all = parameters.mice_all(5:end);
%parameters.mice_all(1).days = parameters.mice_all(1).days(6:end);
% parameters.mice_all(1).days(1).spontaneous = {'01', '02', '03', '04', '05'};

% Use only stacks from a "spontaneous" field of mice_all?
%parameters.use_spontaneous_only = true;

% **********************************************************************8
% Input Directories

% Establish the format of the daily/per mouse directory and file names of 
% the collected data. Will be assembled with CreateFileStrings.m Each piece 
% needs to be a separate entry in a cell  array. Put the string 'mouse 
% number', 'day', or 'stack number' where the mouse, day, or stack number 
% will be. If you concatenated this as a sigle string, it should create a 
% file name, with the correct mouse/day/stack name inserted accordingly. 

% Give the number of digits that should be included in each stack number.
parameters.digitNumber=2; 

% *************************************************************************
% Parameters

% Sampling frequency of wheel encoder, in Hz.
parameters.wheel_Hz = 1000;

% Sampling frequency of collected brain data (per channel), in Hz or frames per
% second.
parameters.fps= 20; 

% Number of channels from brain data (need this to calculate correct
% "skip" time length).
parameters.channelNumber = 2;

% Number of frames you recorded from brain and want to keep (don't make chunks longer than this)  
parameters.frames=6000; 

% Number of initial brain frames to skip, allows for brightness/image
% stabilization of camera. Need this to know how much to skip in the
% behavior.
parameters.skip = 1200; 

% Was PUTTY used for the recording? 
parameters.putty_flag = true;

% Radius of wheel, in cm.
parameters.wheel_radius = 8.5;
                     
% List periods that are long/will need to be cut into smaller sections.
% Rest and walk are the 2 primary behaviors detected by the encoder, and
% need to be detected first.
parameters.periods_long={'rest';
              'walk'};
          
% List periods that are transition periods that are taken from pieces of
% rest and walk. The "continued rest" and "continued walk" is the rest and
% walk that is left after the transition periods are removed. 
parameters.periods_transition={'startwalk';     % Run the within-walk periods first,so you can make sure there's a real "walking" period after the prewalk, not just a large fidget
                'prewalk'; 
                'stopwalk';
               'postwalk'}; 
                             
% List the threshold speeds of each long period (lower, upper) in cm/s;
% Values that fall between the 0.05 and 0.25 are probably twitches or
% fidgets. 
parameters.periods_long_threshold=[ -0.25 0.05;  % rest low, rest high. We don't want to count walking fast backwards.
                         0.25 Inf];   % walk low, walk high
                     
% List the search orders for finding the earliest or most recent velocity
% of 0 to define the start and stop of rest or locomotion. This makes more
% sense when you look at the code that uses it (encoderFindBehaviorPeriods). Probably won't need to edit. 
parameters.periods_long_searchorder={'first', 'last';    % rest start, rest stop
                          'last', 'first'};   % walk start, walk stop
                      
% ***Analysis info ****
% Number of time points to smooth the vel by 
parameters.k=100; 

% Amount of time to count as a transition.
parameters.time_window_seconds=3; 

% How long the animal needs to be at rest or walking for it to count, in seconds
parameters.time_window_seconds_continued = 1;

parameters.time_window_frames = parameters.time_window_seconds*parameters.fps; % how long the animal needs to be at rest or walking, in frames
parameters.time_window_hz = parameters.time_window_seconds*parameters.wheel_Hz; % how long the animal needs to be at rest or walking, in wheel sampled time points
parameters.time_window_frames_continued =  parameters.time_window_seconds_continued*parameters.fps;
parameters.time_window_hz_continued = parameters.time_window_seconds_continued *parameters.wheel_Hz;

% Do you want full transitions? (These are rare)
% "true" if you want "full onsets" and "full offsets" calculated; false if
% not.
parameters.full_transition_flag = true;  
parameters.periods_full_transition={'full_onset';
                         'full_offset'}; 

% In seconds, the amount of time into the continued rest and walk that should be included in the full transition                         
parameters.full_transition_extra_time=1;                  
parameters.full_transition_extra_frames=parameters.full_transition_extra_time*parameters.fps;                                          

periods = [parameters.periods_long; parameters.periods_transition; parameters.periods_full_transition];
%% Extract data and save as .mat file.  (Can take awhile).
% From .log if PUTTY was used, from .txt files if it wasn't. 

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Was PUTTY used for the recording? 
parameters.putty_flag = true;

% Iterations.
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'day', {'loop_variables.mice_all(', 'mouse_iterator', ').days(:).name'}, 'day_iterator';
               'log', { 'dir("Y:\Sarah\Data\Random Motorized Treadmill\', 'day', '\', 'mouse', '\Arduino Output\ArduinoOutput*.log").name'}, 'log_iterator'; 
               'stack', {'loop_variables.mice_all(',  'mouse_iterator', ').days(', 'day_iterator', ').spontaneous'}, 'stack_iterator'};

parameters.loop_variables.mice_all = parameters.mice_all;

% Input values
parameters.loop_list.things_to_load.log.dir = {'Y:\Sarah\Data\Random Motorized Treadmill\', 'day', '\', 'mouse', '\Arduino Output\'};
parameters.loop_list.things_to_load.log.filename= {'log'}; 
parameters.loop_list.things_to_load.log.variable= {}; 
parameters.loop_list.things_to_load.log.level = 'log';
parameters.loop_list.things_to_load.log.load_function = @importlog;

% Output
parameters.loop_list.things_to_save.trial.dir = {[parameters.dir_exper 'behavior\spontaneous\extracted encoder data\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_save.trial.filename= {'trial', 'stack', '.mat'};
parameters.loop_list.things_to_save.trial.variable= {'trial'}; 
parameters.loop_list.things_to_save.trial.level = 'stack';

RunAnalysis({@extractEncoderData}, parameters);

%% Clean and format data. 
% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterations.
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'day', {'loop_variables.mice_all(', 'mouse_iterator', ').days(:).name'}, 'day_iterator';
               'stack', {'loop_variables.mice_all(',  'mouse_iterator', ').days(', 'day_iterator', ').spontaneous'}, 'stack_iterator'};

parameters.loop_variables.mice_all = parameters.mice_all;

% Input
parameters.loop_list.things_to_load.trial.dir = {[parameters.dir_exper 'behavior\spontaneous\extracted encoder data\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.trial.filename= {'trial', 'stack', '.mat'};
parameters.loop_list.things_to_load.trial.variable= {'trial'}; 
parameters.loop_list.things_to_load.trial.level = 'stack';

% Output.
parameters.loop_list.things_to_save.trial_formatted.dir = {[parameters.dir_exper 'behavior\spontaneous\formatted encoder data\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_save.trial_formatted.filename= {'trial', 'stack', '.mat'};
parameters.loop_list.things_to_save.trial_formatted.variable= {'trial'}; 
parameters.loop_list.things_to_save.trial_formatted.level = 'stack';

% Run code.
RunAnalysis({@formatEncoderData}, parameters);

%% Calculate smoothed and corrected velocity.
% For entire stacks. Also removes the skip period here.

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterations.
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'day', {'loop_variables.mice_all(', 'mouse_iterator', ').days(:).name'}, 'day_iterator';
               'stack', {'loop_variables.mice_all(',  'mouse_iterator', ').days(', 'day_iterator', ').spontaneous'}, 'stack_iterator'};

parameters.loop_variables.mice_all = parameters.mice_all;

% Input
parameters.loop_list.things_to_load.trial.dir = {[parameters.dir_exper 'behavior\spontaneous\formatted encoder data\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.trial.filename= {'trial', 'stack', '.mat'};
parameters.loop_list.things_to_load.trial.variable= {'trial'}; 
parameters.loop_list.things_to_load.trial.level = 'stack';

% Output.
parameters.loop_list.things_to_save.velocity.dir = {[parameters.dir_exper 'behavior\spontaneous\velocity trace per stack\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_save.velocity.filename= {'velocity_', 'stack', '.mat'};
parameters.loop_list.things_to_save.velocity.variable= {'velocity'}; 
parameters.loop_list.things_to_save.velocity.level = 'stack';

RunAnalysis({@saveVelocities}, parameters); 

%% Pull out locomotion periods.

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterations.
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'day', {'loop_variables.mice_all(', 'mouse_iterator', ').days(:).name'}, 'day_iterator';
               'stack', {'loop_variables.mice_all(',  'mouse_iterator', ').days(', 'day_iterator', ').spontaneous'}, 'stack_iterator'};

parameters.loop_variables.mice_all = parameters.mice_all;

% Input.
parameters.loop_list.things_to_load.velocity.dir = {[parameters.dir_exper 'behavior\spontaneous\velocity trace per stack\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.velocity.filename= {'velocity_', 'stack', '.mat'};
parameters.loop_list.things_to_load.velocity.variable= {'velocity'}; 
parameters.loop_list.things_to_load.velocity.level = 'stack';

parameters.loop_list.things_to_save.behavior_periods.dir = {[parameters.dir_exper 'behavior\spontaneous\segmented behavior periods\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_save.behavior_periods.filename= {'behavior_periods_', 'stack', '.mat'};
parameters.loop_list.things_to_save.behavior_periods.variable= {'behavior_periods'}; 
parameters.loop_list.things_to_save.behavior_periods.level = 'stack';

RunAnalysis({@encoderFindBehaviorPeriods}, parameters);

%% Segment velocities.

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterations.
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'day', {'loop_variables.mice_all(', 'mouse_iterator', ').days(:).name'}, 'day_iterator';
               'stack', {'loop_variables.mice_all(',  'mouse_iterator', ').days(', 'day_iterator', ').spontaneous'}, 'stack_iterator';
               'period', {'loop_variables.periods{:}'}, 'period_iterator'};

parameters.loop_variables.mice_all = parameters.mice_all;
parameters.loop_variables.periods = periods;

parameters.segmentDim = 1;
parameters.concatDim  = 2;

% Input.
parameters.loop_list.things_to_load.timeseries.dir = {[parameters.dir_exper 'behavior\spontaneous\velocity trace per stack\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.timeseries.filename= {'velocity_', 'stack', '.mat'};
parameters.loop_list.things_to_load.timeseries.variable= {'velocity.corrected'}; 
parameters.loop_list.things_to_load.timeseries.level = 'stack';

parameters.loop_list.things_to_load.time_ranges.dir = {[parameters.dir_exper 'behavior\spontaneous\segmented behavior periods\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.time_ranges.filename= {'behavior_periods_', 'stack', '.mat'};
parameters.loop_list.things_to_load.time_ranges.variable= {'behavior_periods.', 'period'}; 
parameters.loop_list.things_to_load.time_ranges.level = 'stack';

% Output
parameters.loop_list.things_to_save.segmented_timeseries.dir = {[parameters.dir_exper 'behavior\spontaneous\velocity segmented by behavior\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_save.segmented_timeseries.filename= {'segmented_velocity_', 'stack', '.mat'};
parameters.loop_list.things_to_save.segmented_timeseries.variable= {'segmented_velocity.', 'period'}; 
parameters.loop_list.things_to_save.segmented_timeseries.level = 'stack';

RunAnalysis({@SegmentTimeseriesData}, parameters); 

%% Concatenate velocities per behavior period per mouse. 

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterations.
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'period', {'loop_variables.periods{:}'}, 'period_iterator';
               'day', {'loop_variables.mice_all(', 'mouse_iterator', ').days(:).name'}, 'day_iterator';
               'stack', {'loop_variables.mice_all(',  'mouse_iterator', ').days(', 'day_iterator', ').spontaneous'}, 'stack_iterator' };

parameters.loop_variables.mice_all = parameters.mice_all;
parameters.loop_variables.periods = periods;

parameters.concatDim  = 2;

% Input
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\spontaneous\velocity segmented by behavior\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.data.filename= {'segmented_velocity_', 'stack', '.mat'};
parameters.loop_list.things_to_load.data.variable= {'segmented_velocity.', 'period'}; 
parameters.loop_list.things_to_load.data.level = 'stack';

% Output
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper 'behavior\spontaneous\concatenated velocity by behavior\'], 'mouse', '\'};
parameters.loop_list.things_to_save.concatenated_data.filename= {'segmented_velocity_', 'period', '.mat'};
parameters.loop_list.things_to_save.concatenated_data.variable= {'segmented_velocity'}; 
parameters.loop_list.things_to_save.concatenated_data.level = 'period';

RunAnalysis({@ConcatenateData}, parameters); 

%% Average velocities within mice.

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterations.
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'period', {'loop_variables.periods{:}'}, 'period_iterator'};

parameters.loop_variables.mice_all = parameters.mice_all;
parameters.loop_variables.periods = periods;

parameters.averageDim  = 2;

parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\spontaneous\concatenated velocity by behavior\'], 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename= {'segmented_velocity_', 'period', '.mat'};
parameters.loop_list.things_to_load.data.variable= {'segmented_velocity'}; 
parameters.loop_list.things_to_load.data.level = 'period';

parameters.loop_list.things_to_save.average.dir = {[parameters.dir_exper 'behavior\spontaneous\concatenated velocity by behavior\'], 'mouse', '\'};
parameters.loop_list.things_to_save.average.filename= {'average_velocity_', 'period', '.mat'};
parameters.loop_list.things_to_save.average.variable= {'average_velocity'}; 
parameters.loop_list.things_to_save.average.level = 'period';

RunAnalysis({@AverageData}, parameters);

%% Average walk period velocity per instance.
% Is for regression analysis mostly, so save in regression analysis folder.
% Use ReshapeData to flip the vectors, for concatenation later.
period = {'walk'};

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterations.
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'period', {'loop_variables.period{:}'}, 'period_iterator'};

parameters.loop_variables.mice_all = parameters.mice_all;
parameters.loop_variables.period = period;

% Reshaping instructions (useing transpose to avoid issues with ' as a
% quote)
parameters.toReshape = {'transpose(parameters.data)'};
parameters.reshapeDims = {'{size(parameters.data,2), size(parameters.data,1)}'};

% Dimension to average across after reshaping
parameters.averageDim  = 2; 

parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\spontaneous\concatenated velocity by behavior\'], 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename= {'segmented_velocity_', 'period', '.mat'};
parameters.loop_list.things_to_load.data.variable= {'segmented_velocity'}; 
parameters.loop_list.things_to_load.data.level = 'period';

parameters.loop_list.things_to_save.average.dir = {[parameters.dir_exper 'regression analysis\walk velocity\spontaneous\velocity vectors\'], 'mouse', '\'};
parameters.loop_list.things_to_save.average.filename= {'velocity_vector.mat'};
parameters.loop_list.things_to_save.average.variable= {'velocity_vector'}; 
parameters.loop_list.things_to_save.average.level = 'period';

parameters.loop_list.things_to_rename = {{'data_reshaped', 'data'}};  
RunAnalysis({@ReshapeData, @AverageData, }, parameters);

%% Plot the average walk velocity calculated above
figure; histogram(average_velocity);
xlabel('average velocity (cm/s)'); ylabel('number of instances');
title('spontaneous walk average velocity, m1087');
