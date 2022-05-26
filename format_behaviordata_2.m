% format_behaviordata.m
% Sarah West
% 08/15/19
% Extracts wheel/tradmill data taken from
% Arduino .txt files and formats them into a cell array.

%% make wheel data a proper timeseries. 
wheel_hz=3600; % samples the wheel encoder takes per second
dir_in='Z:\DBSdata\Sarah\Awake GCaMP\062319m13_behavior\wheel\';

files=ls([dir_in '*.mat']); 

for j=4%:length(files)
    
    wheel_file=files(j,:);
    load([dir_in wheel_file]);  % use a generic name for the wheel data
    eval(sprintf('trial=trial%02d;',j));
    wheela=table2array(trial); % convert wheel data to an array for easier use

    start=find(wheela(:,4)==0,1); % finds the first time the position of the wheel is 0. This corresponds to the start of the recording (sometimes you get extra output at the top of the text file that you don't want); 
    [r,c]=size(wheela);

    wheeld=wheela(start:end,:); % makes wheeld, which starts at the correct point in time 

    % the wheel encoder only outputs whenever the wheel moves, so you have to
    % fill in the array to make a continuous time series. 

    wheeld(1,1)=0; % the default first time point is NaN, which is obnoxious to deal with
    %find(wheel
    wheel_new=[]; % will hold wheel data that's been up-sampled 

    for i=3:r
        t=wheeld(i,1)-wheeld((i-1),1); 
        if t>1


           if t<200 
          
                dstep=(wheeld(i,1)-wheeld(i-1,1))./t ;
                
                tvect=(wheeld(i-1,1)+1):wheeld(i,1); 
               
                if wheeld(i,4)-(dstep+wheeld(i-1,4))>dstep
                pvect=(dstep+wheeld(i-1,4)):dstep:(wheeld(i,4)); %position
                      while length(pvect)<length(tvect);  % if animal doesn't move much, make it fit tvect 
                    pvect=[pvect pvect(end)];
                      end
                    while length(pvect)>length(tvect);
                    pvect=pvect(1:(end-1));   % or remove points if the mouse walks a lot 
                    end
                 
                else
                pvect=ones(1,numel(tvect)).*wheeld(i-1,4); 
                end 
                trialTime=(wheeld(i-1,3)+1):wheeld(i,3); % same procedure as tvect 
               while length(trialTime)<length(tvect);  % if there's a discrepancy in time measurement on the arduino between two columns, pad it 
                trialTime=[trialTime trialTime(end)];
               end
                while length(trialTime)>length(tvect);
                trialTime=trialTime(1:(end-1));   % or remove points to correct discrepancy
                end
                   
                   
                trialNum=repmat(wheeld(i,2), size(tvect,2), 1);
                rewCount=repmat(wheeld(i,5), size(tvect,2),1); 
               
           else
             tvect=(wheeld(i-1,1)+1):wheeld(i,1); 
             pvect=ones(1,numel(tvect)).*wheeld(i-1,4); 
           
             trialTime=(wheeld(i-1,3)+1):wheeld(i,3); % same procedure as tvect 
           
             
             trialNum=repmat(wheeld(i,2), size(tvect,2), 1);
             rewCount=repmat(wheeld(i,5), size(tvect,2),1); 
           end

           wheel_new=[wheel_new; tvect' trialNum trialTime' pvect' rewCount]; 
        else
        wheel_new=[wheel_new; wheeld(i,:)]; 
        end
    end 
end