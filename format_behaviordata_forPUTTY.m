% format_behaviordata_forPUTTY.m
% Sarah West
% 3/26/20
% Extracts wheel/tradmill data taken from
% Putty structures that come from convertEnc2Cm_batch_Sarah.m & formats them into a cell array.

    
days_all=['031220m23';
          '031220m24';
          '031320m23';
          '031320m24';
           '031720m23';
          '031720m24'];

% record of which logs belong to which trials, because sometimes they get mixed up


%% use "importdata" function to import Arduino copy-paste output text files and save them as .mats (tables) 
% but "importdata" only works if you don't have words tr


for dayi=1 :size(days_all,1)
    
    clearvars -except dayi days_all 
    day=days_all(dayi,:)
   
    dir_in=['Y:\Sarah\Analysis\behavior analysis\' day '\'];
    list_logs=dir([dir_in 'Enc_data*.mat']);
    load([dir_in 'trial_ids.mat']); 

% make wheel data a proper timeseries. 

  
    for j=1:size(list_logs,1)
       

        load([dir_in list_logs(j).name]);  % use a generic name for the wheel data
        
        for triali=1:size(Enc_data,2)
          triali
        
%         trialmatnm=list_trialmat(j).name(6:7);
% 
%         eval(['wheela=trial' trialmatnm ';'])
        
        %wheela=table2array(trial); % convert wheel data to an array for easier use
%        if size(wheela,2)==3     % if spontaneous data
%         start=find(wheela(:,3)==0,1); % finds the first time the position of the wheel is 0. This corresponds to the start of the recording (sometimes you get extra output at the top of the text file that you don't want); 
%         time_column=2;
%         position_column=3;
%        elseif size(wheela,2)==5  % if cued data
%         start=find(wheela(:,4)==0,1);   
%         time_column=1;tri
%         position_column=4;
%        end 
        timedata=Enc_data(triali).trialTime;
        positiondata=Enc_data(triali).positions;
%         wheeld=wheela(start:end,:); % makes wheeld, which starts at the correct point in time 

        % the wheel encoder only outputs whenever the wheel moves, so you have to
        % fill in the array to make a continuous time series. 

%         wheeld(1,time_column)=0; % the default first time point is NaN, which is obnoxious to deal with
        %find(wheel
        [r,c]=size(timedata);

        wheel_new=[]; % will hold wheel data that's been up-sampled 
       
        for i=3:r
            t=timedata(i)-timedata(i-1); 
            if t>1


               if t<200 

                    dstep=(timedata(i)-timedata(i-1))./t;
                   
                    tvect=(timedata(i-1)+1):timedata(i); 

                    if positiondata(i)-(dstep+positiondata(i-1))>dstep
                    pvect=(dstep+positiondata(i-1)):dstep:(positiondata(i)); %position
                          while length(pvect)<length(tvect);  % if animal doesn't move much, make it fit tvect 
                             pvect=[pvect pvect(end)];
                          end
                        while length(pvect)>length(tvect);
                        pvect=pvect(1:(end-1));   % or remove points if the mouse walks a lot 
                        end

                    else
                    pvect=ones(1,numel(tvect)).*positiondata(i-1); 
                    end 

               else
                 tvect=(timedata(i-1)+1):timedata(i); 
                 pvect=ones(1,numel(tvect)).*positiondata(i-1); 


               end

               wheel_new=[wheel_new; tvect' pvect']; 
            else
            wheel_new=[wheel_new; timedata(i) positiondata(i)]; 
            end
        end 
        [C,ia,ic]=unique(wheel_new(:,1)); % find and get rid of repeating time points (often happens at the beginning of the series)
        wheel_new1=wheel_new(ia,:);  
        wheel_new2=wheel_new1; %(30001:end,1)-30000;                  % adjust for the extra 30 seconds taken at the beginning of some stacks 
        holding=trial_ids{j};
        nm=holding(triali); 
        trialmatnm=sprintf('%02d',nm);  
        eval(['wheel' trialmatnm '=wheel_new2;']); 
        save([dir_in 'wheel' trialmatnm '.mat'], ['wheel' trialmatnm], '-v7.3'); 
    end
    end 
end 