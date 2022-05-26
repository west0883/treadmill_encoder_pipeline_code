% save_vel_2 
% Sarah West
%

% finds the start of a bout of locomotion (by finding movement over a
% velocity threshold) and looking before that threshold to when the vel was
% 0 .

clear all;
%  days_all=[
%              '062319m13';
%              '070819m13';
%              '071019m13';
%              '071219m13';
%              '072219m13';
%              '103019m13';
%              '120219m13';
%              '120419m13']; 
             
%  days_all=[
%              '070519m14';
%              '071119m14';
%              '071519m14';
%             '071619m14'; 
%             '071819m14';
%             '111519m14';
%             '120519m14';
%             '120619m14'];


%  days_all=[
%              '070519m15';
% 
%              '071219m15';
%               '071619m15';
%               '071719m15'; 
%              % '071819m15'; 
%               '072319m15';
%               '111519m15';
%               '120219m15'];
% 
% days_all=[
%                '070319m20'; 
%              '070819m20';
%              '071119m20'; 
%              '071519m20'; 
%              '071819m20'; 
%             '072319m20']; 


% days_all=['101019m23';
%              '102819m23';
%              '103119m23';
%              '110419m23';
%              '111119m23';
%              '111419m23';
%              '112219m23';
%              '112319m23'];

%  days_all=['100219m22';
%              '102819m22';
%              '103019m22';
%              '103119m22';
%              '110419m22';
%              '111419m22';
%              '112219m22';
%              '112319m22'];

% 
%  days_all=['100219m21';
%              '112519m21';
%              '112919m21';
%              '120519m21';
%              '120719m21';
%             '120919m21';
%              '121119m21';
%              '121219m21'];

% days_all=['101019m24';
%              '112519m24';
%              '112919m24';
%              '120619m24';
%              '120719m24';
%              '120919m24';
%              '121119m24';
%              '121219m24'];            

for dayi=1 :size(days_all,1)
    dayi
    clearvars -except days_all dayi
    day=days_all(dayi,:); 
    fprintf("This is a test of your emergency response system (%d)\n", dayi);
    
    walking_velthresh=0.25; % in cm/s Anything above this is classified as locomotion
    rest_velthresh=0.05; % in cm/s  Anything below this is classified as rest (will be used in the clean-up phases) 
                        % any movement with a peak vel that falls between these
                        % values is probably just a twitch. 
    k=100; % number of time points to smooth across
    wheel_hz=1000; % samples the wheel encoder takes per second
    time_window=60; % how long the animal needs to be at rest or walking, in frames
    fps=20; % frames per second of brain imaging 
    time_total=3;  %time_window*fps; 
    frames=6001; % number of frames you recorded from brain (don't make chunks longer than this) 


dir_in=['Z:\DBSdata\Sarah\Awake GCaMP\' day '_behavior\wheel\'];
dir_save=['Z:\DBSdata\Sarah\Analysis\behavior analysis\wheel time periods\' day '\3s\']; 
mkdir(dir_save) ;

list=dir([dir_in 'wheel*.mat']); 
    


    for stacki=1:size(list,1)

        
     load([dir_in list(stacki).name]);   
     name=list(stacki).name(1:7);
     stacknum=name(6:7); 
     eval(['wheel_correct=[' name '(:,1)./1000,' name '(:,2)/24000*2*pi*8.5];']);  
     smooth=movmean(wheel_correct,k); 
     vel=diff(smooth).*1000;  %time data is in first column of wheel, position data in second
     
     save([dir_save 'stack' stacknum '_vel'], 'vel');
          

    end 
end 


%% average vel by time period 

clear all;
dir_out='Z:\DBSdata\Sarah\Analysis\behavior analysis\average velocities\mouse 13\';
 days_all=[
             '070519m15';

             '071219m15';
              '071619m15';
              '071719m15'; 
               '071819m15'; 
              '072319m15';
              '111519m15';
              '120219m15';

'100219m21';
             '112519m21';
             '112919m21';
             '120519m21';
             '120719m21';
            '120919m21';
             '121119m21';
             '121219m21';
'101019m23';
             '102819m23';
             '103119m23';
             '110419m23';
             '111119m23';
             '111419m23';
             '112219m23';
             '112319m23';

             

             '070519m14';
             '071119m14';
             '071519m14';
            '071619m14'; 
            '071819m14';
            '111519m14';
            '120519m14';
            '120619m14';


              '062319m13';
             '070819m13';
             '071019m13';
             '071219m13';
             '072219m13';
             '103019m13';
             '120219m13';
             '120419m13'; 
             
                            '070319m20'; 
             '070819m20';
             '071119m20'; 
             '071519m20'; 
             '071819m20'; 
            '072319m20'; 

'100219m22';
             '102819m22';
             '103019m22';
             '103119m22';
             '110419m22';
             '111419m22';
             '112219m22';
             '112319m22';

'101019m24';
             '112519m24';
             '112919m24';
             '120619m24';
             '120719m24';
             '120919m24';
             '121119m24';
             '121219m24'];            


   % divide any rest and walking chunks that are longer than 3 seconds into
   % 3 second chunks
 
 walking_velthresh=0.25; % in cm/s Anything above this is classified as locomotion
    rest_velthresh=0.05; % in cm/s  Anything below this is classified as rest (will be used in the clean-up phases) 
                        % any movement with a peak vel that falls between these
                        % values is probably just a twitch. 
    k=100; % number of time points to smooth across
    wheel_hz=1000; % samples the wheel encoder takes per second
    time_window=60; % how long the animal needs to be at rest or walking, in frames
    fps=20; % frames per second of brain imaging 
    time_total=3;  %time_window*fps; 
    frames=6001; % number of frames you recorded from brain (don't make chunks longer than this) 
   
   
vel_rest_all=[];
vel_prewalk_all=[];
vel_startwalk_all=[];
vel_walk_all=[];
vel_stopwalk_all=[]; 
vel_postwalk_all=[];
vel_full_onsets_all=[];
vel_full_offsets_all=[];

time_window=61;

for dayi=1:size(days_all,1)   
   day=days_all(dayi,:) 
   dir_vel=['Z:\DBSdata\Sarah\Analysis\behavior analysis\wheel time periods\' day '\3s\']; 
   dir_behavior=['Z:\DBSdata\Sarah\Analysis\behavior analysis\wheel time periods\' day '\3s vel corrected\']; 
   list=dir([dir_behavior 'behavior_periods_*.mat']); 

   for stacki=1:size(list,1)
       load([dir_behavior list(stacki).name]); % load behavior
       stacknum=list(stacki).name(18:19); %find the stack number
       load([dir_vel 'stack' stacknum '_vel.mat']);  % load corresponding velocity 
       
     correcting_timeseries=(0:(frames-1)).*wheel_hz./fps; 
     correcting_timeseries(1)=1; % don't let it be a 0

     if correcting_timeseries(end)>size(vel,1)
         ind=find((correcting_timeseries-size(vel,1))<=0,1, 'last'); % find the closest values of correcting_timeseries that matches the size of vel (without going over) and stop correcting_timeseries at that point
         correcting_timeseries=correcting_timeseries(1:ind);  
     end 
     vel_correct=[vel(correcting_timeseries,2)]'; 
      
%        load([dir_behavior 'full_offsets_' stacknum '.mat']); 
%        load([dir_behavior 'full_onsets_' stacknum '.mat']); 
       
       walk_brokendown=walk_periods_correct; 
       for chunki=1:size(walk_periods_correct,1)
           time=walk_periods_correct(chunki,2)-walk_periods_correct(chunki,1)+1;
           if time > time_window   % if the walk chunk is greater than 3 seconds 
              quotient=floor(time/time_window);
              walk_brokendown(chunki,2)=walk_periods_correct(chunki,1)+time_window-1; % make the first chunk end after 60 frames
              if quotient>1
                  for quotienti=1:(quotient-1)
                      %a=[walk_periods_correct(chunki,1)+time_window*quotienti, walk_periods_correct(chunki,1)+time_window*quotienti+time_window-1]
                       walk_brokendown=[walk_brokendown; walk_periods_correct(chunki,1)+time_window*quotienti, walk_periods_correct(chunki,1)+time_window*quotienti+time_window-1] ;
                  end 
              end
              
             
           else  % account for if it isn't too long
             walk_brokendown(chunki,:)=walk_periods_correct(chunki,:);   
           end 
       end 

       rest_brokendown=rest_periods_correct;     
       for chunki=1:size(rest_periods_correct,1)
           time=rest_periods_correct(chunki,2)-rest_periods_correct(chunki,1)+1;
           if  time> time_window   % if the rest chunk is greater than 3 seconds 
              quotient=floor(time/time_window);
              rest_brokendown(chunki,2)=rest_periods_correct(chunki,1)+time_window-1; % make the first chunk end after time_window frames
              if quotient>1
                  for quotienti=1:(quotient-1)
                       rest_brokendown=[rest_brokendown; rest_periods_correct(chunki,1)+time_window*quotienti, rest_periods_correct(chunki,1)+time_window*quotienti+time_window-1] ;
                  end 
              end
            else  % account for if it isn't too long
             rest_brokendown(chunki,:)=rest_periods_correct(chunki,:);      
           end 
       end
       
       % up sample the behavior periods so you can directly take from wheel
       
       for i=1:size(rest_brokendown,1)
       vel_rest=vel_correct([rest_brokendown(i,1):rest_brokendown(i,2)]);
       vel_rest_all=[vel_rest_all; vel_rest];
       end
       
       for i=1:size(prewalk_periods_correct,1)
       vel_prewalk=vel_correct([prewalk_periods_correct(i,1):prewalk_periods_correct(i,2)]);
       vel_prewalk_all=[vel_prewalk_all; vel_prewalk];
       end
      
       for i=1:size(startwalk_periods_correct,1)
       vel_startwalk=vel_correct([startwalk_periods_correct(i,1):startwalk_periods_correct(i,2)]);
       vel_startwalk_all=[vel_startwalk_all; vel_startwalk];
       end
       
       for i=1:size(walk_brokendown,1)
       vel_walk=vel_correct([walk_brokendown(i,1):walk_brokendown(i,2)]);
       vel_walk_all=[vel_walk_all; vel_walk];
       end
       
       for i=1:size(stopwalk_periods_correct,1)
       vel_stopwalk=vel_correct([stopwalk_periods_correct(i,1):stopwalk_periods_correct(i,2)]);
       vel_stopwalk_all=[vel_stopwalk_all; vel_stopwalk];
       end
       
       for i=1:size(postwalk_periods_correct,1)
       vel_postwalk=vel_correct([postwalk_periods_correct(i,1):postwalk_periods_correct(i,2)]);
       vel_postwalk_all=[vel_postwalk_all; vel_postwalk];
       end
     
%         for i=1:size(full_onsets,1)
%        vel_full_onsets=vel([(full_onsets(i,1)*50):(full_onsets(i,end)*50)],2);
%        vel_full_onsets1=reshape(vel_full_onsets(1:8000),50, 160);
%        vel_full_onsets=nanmean(vel_full_onsets1,1); 
%        vel_full_onsets_all=[vel_full_onsets_all; vel_full_onsets];
%         end
%         
%           for i=1:size(full_offsets,1)
%        vel_full_offsets=vel([(full_offsets(i,1)*50):(full_offsets(i,end)*50)],2);
%        vel_full_offsets1=reshape(vel_full_offsets(1:8000),50, 160);
%        vel_full_offsets=nanmean(vel_full_offsets1,1); 
%        vel_full_offsets_all=[vel_full_offsets_all; vel_full_offsets];
%         end
       
       
   end   
       
       
end 

%    ind= find(abs(vel_rest_all)>=30); 
%    vel_rest_all(ind)=NaN; 
%    ind= find(abs(vel_prewalk_all)>=30); 
%    vel_prewalk_all(ind)=NaN; 
%    ind= find(abs(vel_startwalk_all)>=30); 
%    vel_startwalk_all(ind)=NaN; 
%    ind= find(abs(vel_walk_all)>=30); 
%    vel_walk_all(ind)=NaN; 
%    ind= find(abs(vel_stopwalk_all)>=30); 
%    vel_stopwalk_all(ind)=NaN; 
%    ind= find(abs(vel_postwalk_all)>=30); 
%    vel_postwalk_all(ind)=NaN; 
%    
%    vel_rest_mean=nanmean(vel_rest_all,1); 
%    vel_prewalk_mean=nanmean(vel_prewalk_all,1);    
%    vel_startwalk_mean=nanmean(vel_startwalk_all,1);    
%    vel_walk_mean=nanmean(vel_walk_all,1);    
%    vel_stopwalk_mean=nanmean(vel_stopwalk_all,1);    
%    vel_postwalk_mean=nanmean(vel_postwalk_all,1);    
%    
%    vel_rest_std=nanstd(vel_rest_all,0,1); 
%    vel_prewalk_std=nanstd(vel_prewalk_all,0,1);    
%    vel_startwalk_std=nanstd(vel_startwalk_all,0,1);    
%    vel_walk_std=nanstd(vel_walk_all,0,1);    
%    vel_stopwalk_std=nanstd(vel_stopwalk_all,0 ,1);    
%    vel_postwalk_std=nanstd(vel_postwalk_all, 0, 1);  
%    
%    
%    figure; 
%    plot(vel_rest_mean(3:end)); hold on;
%    plot(vel_rest_mean(3:end)+vel_rest_std(3:end));
%    plot(vel_rest_mean(3:end)-vel_rest_std(3:end));
%    title('rest'); ylim([-4 14]); xlim([1 60]); 
%    savefig([dir_out 'mean_vel_rest']);
%    saveas(gcf, [dir_out 'mean_vel_rest'], 'svg'); 
%    
%    figure; 
%    plot(vel_prewalk_mean); hold on;
%    plot(vel_prewalk_mean+vel_prewalk_std);
%    plot(vel_prewalk_mean-vel_prewalk_std);
%    title('prewalk'); ylim([-4 14]); xlim([1 60]); 
%    savefig([dir_out 'mean_vel_prewalk']);
%    saveas(gcf, [dir_out 'mean_vel_prewalk'], 'svg'); 
%    
%    figure; 
%    plot(vel_startwalk_mean); hold on;
%    plot(vel_startwalk_mean+vel_startwalk_std);
%    plot(vel_startwalk_mean-vel_startwalk_std);
%    title('startwalk'); ylim([-4 14]); xlim([1 60]); 
%    savefig([dir_out 'mean_vel_startwalk']);
%    saveas(gcf, [dir_out 'mean_vel_startwalk'], 'svg'); 
%    
%    figure; 
%    plot(vel_walk_mean); hold on;
%    plot(vel_walk_mean+vel_walk_std);
%    plot(vel_walk_mean-vel_walk_std);
%    title('walk'); ylim([-4 14]); xlim([1 60]); 
%    savefig([dir_out 'mean_vel_walk']);
%    saveas(gcf, [dir_out 'mean_vel_walk'], 'svg'); 
%    
%    figure; 
%    plot(vel_stopwalk_mean); hold on;
%    plot(vel_stopwalk_mean+vel_stopwalk_std);
%    plot(vel_stopwalk_mean-vel_stopwalk_std);
%    title('stopwalk'); ylim([-4 14]); xlim([1 60]); 
%    savefig([dir_out 'mean_vel_stopwalk']);
%    saveas(gcf, [dir_out 'mean_vel_stopwalk'], 'svg'); 
%    
%    figure; 
%    plot(vel_postwalk_mean); hold on;
%    plot(vel_postwalk_mean+vel_postwalk_std);
%    plot(vel_postwalk_mean-vel_postwalk_std);
%    title('postwalk'); ylim([-4 14]); xlim([1 60]); 
%    savefig([dir_out 'mean_vel_postwalk']);
%    saveas(gcf, [dir_out 'mean_vel_postwalk'], 'svg'); 
%    
   %% 
%    figure;
%    plot(1:160, vel_full_onsets_all);
%    
   %% calculate time spent in locomotion --> run previous section 
   
   rest_time=size(vel_rest_all,1)+size(vel_prewalk_all,1)+size(vel_postwalk_all,1); 
   walk_time=size(vel_walk_all,1)+size(vel_startwalk_all,1)+size(vel_postwalk_all,1); 
   
   walk_time_percent=walk_time/rest_time; 
   
   %% calculate time spent in locomotion --> from vel files for stack; want unclean periods as well (calculate rest, locomotion, and fidgeting) 
   
   % do by mouse 
   clear all;
   dir_save=['Z:\DBSdata\Sarah\Analysis\behavior analysis\average velocities\'];
%   mouse='13'; 
%    days_all=[
%               '062319m13';
%              '070819m13';
%              '071019m13';
%              '071219m13';
%              '072219m13';
%              '103019m13';
%              '120219m13';
%              '120419m13'];

% mouse='14';
% days_all=  ['070519m14';
%              '071119m14';
%              '071519m14';
%             '071619m14'; 
%             '071819m14';
%             '111519m14';
%             '120519m14';
%             '120619m14'];

% mouse='15';
% days_all=[
%              '070519m15';
% 
%              '071219m15';
%               '071619m15';
%               '071719m15'; 
%                '071819m15'; 
%               '072319m15';
%               '111519m15';
%               '120219m15'];

% mouse='20';
% days_all=  ['070319m20'; 
%              '070819m20';
%              '071119m20'; 
%              '071519m20'; 
%              '071819m20'; 
%             '072319m20']; 

% mouse='21'; 
% days_all=           ['100219m21';
%              '112519m21';
%              '112919m21';
%              '120519m21';
%              '120719m21';
%             '120919m21';
%              '121119m21';
%              '121219m21'];
% 

% mouse='22'; 
% 
% days_all=['100219m22';
%              '102819m22';
%              '103019m22';
%              '103119m22';
%              '110419m22';
%              '111419m22';
%              '112219m22';
%              '112319m22'];

% mouse='23';
% days_all=['101019m23';
%              '102819m23';
%              '103119m23';
%              '110419m23';
%              '111119m23';
%              '111419m23';
%              '112219m23';
%              '112319m23'];
% 
mouse='24';
days_all=['101019m24';
             '112519m24';
             '112919m24';
             '120619m24';
             '120719m24';
             '120919m24';
             '121119m24';
             '121219m24'];            



vel_all=[]; 
for dayi=1:size(days_all,1) 
    dayi
    day=days_all(dayi,:);
     dir_in=['Z:\DBSdata\Sarah\Analysis\behavior analysis\wheel time periods\' day '\3s\'];   
     list=dir([dir_in '*_vel.mat']); 
     for stacki=1:size(list,1) 
     load([dir_in list(stacki).name]);   
     vel_all=[vel_all; vel(:,2)]; 

     end 
       
end 
i_rest=intersect(find(vel_all<0.05),find(vel_all>-0.25)); 
i_loc=find(vel_all>=0.25);
i_fidg=intersect(find(vel_all>0.05),find(vel_all<0.25)); 
i_back=find(vel_all<=-0.25);
time_rest=length(i_rest);
time_loc=length(i_loc); 
time_fidg=length(i_fidg);
time_back=length(i_back);


percent_rest=time_rest/length(vel_all)*100; 
percent_loc=time_loc/length(vel_all)*100; 
percent_fidget=time_fidg/length(vel_all)*100; 
percent_back=time_back/length(vel_all)*100; 


save([dir_save 'time_locomoting_m' mouse], 'time_rest', 'time_loc', 'time_fidg', 'time_back', 'percent_rest', 'percent_loc', 'percent_fidget', 'percent_back'); 

%% mean and std of loc time 
clear all;
dir_save=['Z:\DBSdata\Sarah\Analysis\behavior analysis\average velocities\'];
mice=['13'; '14'; '15'; '20'; '21'; '22'; '23'; '24'];

percents=NaN(size(mice,1), 4); 
times=NaN(size(mice,1), 4); 
for mousei=1:size(mice,1)
    mouse=mice(mousei,:);  
    load([dir_save 'time_locomoting_m' mouse '.mat']); 
    percents(mousei,1)=percent_rest;
    percents(mousei,2)=percent_loc; 
    percents(mousei,3)=percent_fidget; 
    percents(mousei,4)=percent_back; 
    times(mousei,1)=time_rest;
    times(mousei,2)=time_loc; 
    times(mousei,3)=time_fidg; 
    times(mousei,4)=time_back; 
end 
percents_mean=mean(percents,1);
percents_std=std(percents,1); 
all_times=sum(times,1)./50./20./60; % divide by 50 to get frames, divide by 20 to get seconds, divide by 60 to get minutes
tot_times=sum(times,2); % total time per mouse 
mean_times=mean(tot_times)/50./20./60; 
std_times=std(tot_times)/50./20./60;  