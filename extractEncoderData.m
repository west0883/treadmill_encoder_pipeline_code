% extractEncoderData.m
% Sarah West
% 10/11/21

% Extracts rotary encoder data from .txt or PUTTY .log files and saves them 
% as .mat files. 

function [parameters] = extractEncoderData(parameters)
   
    % Announce what stack you're on.
    message = ['Extracting '];
    for dispi = 1:numel(parameters.values)/2
        message = [message ', ' parameters.values{dispi}];
    end
    disp(message);

    % Look for the trial number, have to convert to a
    % number and back to remove the leading 0s. Will always be the
    % 'stack' keyword-value pair 
    stack_number = str2num(CreateStrings({'stack'}, parameters.keywords, parameters.values));

    % Run convertEnc2Cm.m function
    trial = convertEnc2Cm(parameters.log, 'True', parameters.wheel_radius, stack_number);
    
    % Tell Run Analysis not to save if empty 
    if isempty(trial)
        parameters.dont_save = true;
        MessageToUser('Could not find ', parameters);
    end 

    parameters.trial = trial; 
    
end 