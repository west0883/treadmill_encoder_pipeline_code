% create_spontaneous_period_table.m
% Sarah West
% 5/20/22

% Make a table listing the spontaneous behavior periods with all the same
% fields as the motorized behavior periods table made in
% create_conditions_names.m in the motorized_treadmill_behavior_pipeline
% respository.
% First make as a structure, then use struct2table to make it a table.
clear all; 

experiment_name=['Random Motorized Treadmill\'];
dir_base='Y:\Sarah\Analysis\Experiments\';
dir_exper=[dir_base experiment_name '\']; 

% Load the motorized treadmill behavior table for getting correct final
% indices for index field.
load([dir_exper 'periods_nametable.mat'], 'periods');
periods_motorized = periods; 
clear periods;

% Frames per second of fluorescence recording. 
fps = 20; 

% Time window for transitions. 
time_window_seconds_transitions = 3; 

% Time window for continued
time_window_seconds_continued = 1;

% Spontaneous period names.
period_names = {'rest', 'walk', 'prewalk', 'startwalk', 'stopwalk', 'postwalk', 'full_onset', 'full_offset'};

% Put in durations -- in order of period_names. As a cell to fit with other
% entries & motorized period table.
periods(1).duration = {time_window_seconds_continued * fps};
periods(2).duration = {time_window_seconds_continued * fps}; 
periods(3).duration = {time_window_seconds_transitions * fps}; 
periods(4).duration = {time_window_seconds_transitions * fps}; 
periods(5).duration = {time_window_seconds_transitions * fps}; 
periods(6).duration = {time_window_seconds_transitions * fps}; 
periods(7).duration = {time_window_seconds_transitions * fps * 2 + time_window_seconds_continued * fps * 2}; 
periods(8).duration = {time_window_seconds_transitions * fps * 2 + time_window_seconds_continued * fps * 2}; 

for namei = 1:numel(period_names)

    % Put in "condition" (name) 
    periods(namei).condition = period_names{namei};

    % Put in "index" (will be number of motorized periods + namei)
    periods(namei).index = size(periods_motorized,1) + namei; 

    % Put in all NaN values.
    periods(namei).speed = 'NaN';
    periods(namei).accel = 'NaN';
    periods(namei).previous_speed = 'NaN';
    periods(namei).two_speeds_ago = 'NaN';
    %periods(namei).previous_accel = 'NaN';

end

periods = struct2table(periods);

save([dir_exper 'periods_nametable_spontaneous.mat'], 'periods');
