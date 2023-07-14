
% Input data 
% parameters.velocity -- treadmill velocity calculated from raw rotary
% encoder output (velocity calculated with the "diff" function"

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

% Amount of time inseconds  to count as a transition. (for prewalk, startwalk,
% stopwalk, postwalk)
parameters.time_window_seconds = 3; 

% How long the animal needs to be at rest or walking for it to count, in seconds
parameters.time_window_seconds_continued = 1;

parameters.time_window_frames = parameters.time_window_seconds*parameters.fps; % how long the animal needs to be at rest or walking, in frames
parameters.time_window_hz = parameters.time_window_seconds*parameters.wheel_Hz; % how long the animal needs to be at rest or walking, in wheel sampled time points
parameters.time_window_frames_continued =  parameters.time_window_seconds_continued*parameters.fps;
parameters.time_window_hz_continued = parameters.time_window_seconds_continued *parameters.wheel_Hz;

% Do you want full transitions? (These are rare)
% "true" if you want "full onsets" and "full offsets" calculated; false if
% not.
parameters.full_transition_flag = false;  
parameters.periods_full_transition={'full_onset';
                         'full_offset'}; 

% In seconds, the amount of time into the continued rest and walk that should be included in the full transition                         
parameters.full_transition_extra_time=1;                  
parameters.full_transition_extra_frames=parameters.full_transition_extra_time*parameters.fps;                                          

periods = [parameters.periods_long; parameters.periods_transition; parameters.periods_full_transition];