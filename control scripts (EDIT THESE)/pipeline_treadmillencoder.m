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
parameters.experiment_name='Inhibitory Neurons';

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

parameters.mice_all(1).days = mice_all(1).days(6:9); 

% **********************************************************************8
% Input Directories

% Establish the format of the daily/per mouse directory and file names of 
% the collected data. Will be assembled with CreateFileStrings.m Each piece 
% needs to be a separate entry in a cell  array. Put the string 'mouse 
% number', 'day', or 'stack number' where the mouse, day, or stack number 
% will be. If you concatenated this as a sigle string, it should create a 
% file name, with the correct mouse/day/stack name inserted accordingly. 
parameters.dir_dataset_name={'Y:\Sarah\Data\', parameters.experiment_name, '\', 'day', '\','m', 'mouse number', '\'};
parameters.input_data_name={'ArduinoOutput*.log' }; 

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
% How the animal needs to be at rest or walking for it to count, in seconds
parameters.time_window_seconds=3; 

parameters.time_window_frames=parameters.time_window_seconds*parameters.fps; % how long the animal needs to be at rest or walking, in frames
parameters.time_window_hz=parameters.time_window_seconds*parameters.wheel_Hz; % how long the animal needs to be at rest or walking, in wheel sampled time points

% Do you want full transitions? (These are rare)
% "true" if you want "full onsets" and "full offsets" calculated; false if
% not.
parameters.full_transition_flag = true;  
parameters.periods_full_transition={'full_onset';
                         'full_offset'}; 

% In seconds, the amount of time into the continued rest and walk that should be included in the full transition                         
parameters.full_transition_extra_time=1;                  
parameters.full_transition_extra_hz=parameters.full_transition_extra_time*parameters.wheel_Hz;                                          
             
%% Extract data and save as .mat file.  (Can take awhile).
% From .log if PUTTY was used, from .txt files if it wasn't. 
parameters.input_data_name={'ArduinoOutput*.log' }; 
extractEncoderData(parameters);

%% Clean and format data. (Can take awhile).

% For now, change the input data name--> might do something different later
parameters.input_data_name={'trial', 'stack number', '.mat'}; 

% Run code.
formatEncoderData(parameters);

%% Calculate smoothed and corrected velocity.
% Also removes the skip period here.
% For now, change the input data name--> might do something different later
parameters.input_data_name={'trial', 'stack number', '.mat'}; 

saveVelocities(parameters); 

%% Pull out locomotion periods.

% For now, change the input data name--> might do something different later
parameters.input_data_name={'vel', 'stack number', '.mat'}; 

encoderFindBehaviorPeriods(parameters);

%% Segment velocities.
segmentVelocities(parameters); 

%% Concatenate velocities per behavior period per mouse. 
% Also finds the average and std.
concatenateVelocities(parameters);

%% Concatenate velocities per behavior periods across mice.
% Also finds the average and std.
averageVelocitiesAcrossMice(parameters);

%% Plot average velocities. 

