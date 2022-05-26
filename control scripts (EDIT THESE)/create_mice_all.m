% create_mice_all.m
% Sarah West
% 8/17/21

% Creates and saves the lists of data you'll use for the given experiement
% (mouse names and days of data collected). 

% Each row of the structure is a different mouse. 


%% Parameters for directories
clear all;

experiment_name='Inhibitory Neurons';

dir_base='Y:\Sarah\Analysis\Experiments\';
dir_exper=[dir_base experiment_name '\']; 

dir_out=dir_exper; 

%% List of days

mice_all(1).name='109'; 
mice_all(1).days(1).name='090721';
mice_all(1).days(1).stacks='all'; 

mice_all(1).days(2).name='091021';
mice_all(1).days(2).stacks='all'; 

mice_all(1).days(3).name='091421';
mice_all(1).days(3).stacks='all'; 

mice_all(1).days(4).name='091721';
mice_all(1).days(4).stacks='all'; 

mice_all(1).days(5).name='093021';
mice_all(1).days(5).stacks='all'; 

save([dir_out 'mice_all.mat'], 'mice_all');
            
