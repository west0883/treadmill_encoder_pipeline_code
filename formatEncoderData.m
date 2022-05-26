% formatEncoderData.m
% Sarah West
% 10/11/21

% Formats the encoder data so the time vector is regularized. 

function [] = formatEncoderData(parameters)

    % Give parameters their original names
    mice_all = parameters.mice_all;
    dir_exper = parameters.dir_exper;
    input_data_name = parameters.input_data_name;
    dir_exper = parameters.dir_exper; 
    wheel_Hz = parameters.wheel_Hz;
    putty_flag = parameters.putty_flag;
    digitNumber = parameters.digitNumber; 
    
    % Establish input directory
    dir_in_base = [dir_exper 'behavior\extracted encoder data\'];
    
    % Establish base output directory
    dir_out_base=[dir_exper 'behavior\formatted encoder data\'];
    
    % Tell user where data is being saved
    disp(['Data saved in ' dir_out_base]); 
    
    % For each mouse 
    for mousei=1:size(mice_all,2)
        mouse=mice_all(mousei).name;
        
        % For each day
        for dayi=1:size(mice_all(mousei).days, 2)
            
            % Get the day name.
            day=mice_all(mousei).days(dayi).name; 
            
            % Establish more specific input directory. 
            dir_in = [dir_in_base mouse '\' day '\'];
            
            % Establish output directory.
            dir_out = [dir_out_base mouse '\' day '\']; 
            mkdir(dir_out);
            
            % Get the stack list
            [stackList]=GetStackList(mousei, dayi, mice_all, dir_in, input_data_name, digitNumber);
            
            % For each stack, 
            for stacki=1:size(stackList.filenames,1)
                
                % Get the stack number and filename for the stack.
                stack_number = stackList.numberList(stacki, :);
                filename = stackList.filenames(stacki, :);
                
                disp(['mouse ' mouse ', day '  day ', stack ' stack_number]);
                
                % Load the stack. 
                load([dir_in filename])
                
                % Begin the formatting
                
                % Change name of variables to make coding easier
                timedata = trial.trialTime;
                positiondata = trial.positions;
                
                % Get the size of the timedata. 
                [r,c]=size(timedata);
                
                % Will hold wheel data that's been up-sampled 
                wheel_new.time=[]; 
                wheel_new.position=[]; 
                
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
                       wheel_new.time=[wheel_new.time; tvect'];
                       wheel_new.position =[wheel_new.position; pvect'];
                      
                    else
                        % If no large gap in time, 
                        
                        % Just take next entry and add it to the list of
                        % data
                        wheel_new.time = [wheel_new.time; timedata(i)];
                        wheel_new.position = [wheel_new.position; positiondata(i)]; 
                    
                    end
                    
                end
                
                % Find and get rid of repeating time points (often happens at the beginning of the series)
                [C,ia,ic] = unique(wheel_new.time);
                wheel_new1.time = wheel_new.time(ia);  
                wheel_new1.position = wheel_new.position(ia);  
                
                % Change name of variable.
                trial = wheel_new1; 
                
                % Save outpus
                save([dir_out 'trial' stack_number '.mat'], 'trial');
                
            end 
        end
    end
end 