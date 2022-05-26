% formatEncoderData.m
% Sarah West
% 10/11/21

% Formats the encoder data so the time vector is regularized. 

function [parameters] = formatEncoderData(parameters)
    
    % Announce what stack you're on.
    message = ['Formatting '];
    for dispi = 1:numel(parameters.values)/2
       message = [message ', ' parameters.values{dispi}];
    end
    disp(message);

    % Change name of variables to make coding easier
    timedata = parameters.trial.trialTime;
    positiondata = parameters.trial.positions;
    
    % Get the size of the timedata. 
    r = size(timedata, 1);
    
    % Will hold wheel data that's been up-sampled 
    wheel_new.time= cell(r, 1); 
    wheel_new.position = cell(r,1); 
    
    % For each entry, skipping the first 2,
    for i=3:r
        
        % Find how much time has passed between the entries
        t=timedata(i)-timedata(i-1); 
        
        % If there's a gap in the time,
        if t>1

           % And if that gap is really big
           if t<200 

                dstep=(timedata(i)-timedata(i-1))./t;

                tvect=(timedata(i-1)+1):timedata(i); 

                if positiondata(i)-(dstep+positiondata(i-1))>dstep
                    
                    pvect=(dstep+positiondata(i-1)):dstep:(positiondata(i)); %position
                    
                    % If animal doesn't move much, make it fit tvect 
                    while length(pvect)<length(tvect) 
                         pvect=[pvect pvect(end)];
                    end
                    
                    while length(pvect)>length(tvect)
                        pvect=pvect(1:(end-1));   % or remove points if the mouse walks a lot 
                    end

                else
                    
                pvect=ones(1,numel(tvect)).*positiondata(i-1); 
                
                end 

           else
               
             tvect=(timedata(i-1)+1):timedata(i); 
             pvect=ones(1,numel(tvect)).*positiondata(i-1); 


           end
           
           % Add data to list of data
           wheel_new.time{i} = tvect';
           wheel_new.position{i} = pvect';
          
        else
            % If no large gap in time, 
            
            % Just take next entry and add it to the list of
            % data
            wheel_new.time{i} = timedata(i);
            wheel_new.position{i} = positiondata(i); 
        
        end
        
    end
    % Concatenate new time and positions.
    wheel_new.time = vertcat(wheel_new.time{:});
    wheel_new.position = vertcat(wheel_new.position{:});
    % Find and get rid of repeating time points (often happens at the beginning of the series)
    [~,ia,~] = unique(wheel_new.time);
    wheel_new1.time = wheel_new.time(ia);  
    wheel_new1.position = wheel_new.position(ia);  
    
    % Change name of variable.
    parameters.trial_formatted = wheel_new1; 
    
end 