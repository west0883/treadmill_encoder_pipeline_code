% wheel_data_analysis_5.m
% Sarah West
% 8/2/21

% A cleaner, (hopefully) easier to understand version of the wheel_data_analysis code.
% Finds the start of a bout of locomotion (by finding movement over a
% velocity threshold) and looking before that threshold to when the vel was
% 0.

clear all;

days_all=['062319m13';
    '070819m13';
    '071019m13';
    '071219m13';
    '072219m13';
    '103019m13';
    '120219m13';
    '120419m13';
];
 

% List periods that are long/will need to be cut into smaller sections.
% Rest and walk are the 2 primary behaviors detected by the encoder, and
% need to be detected first.
periods_long={'rest';
              'walk'};
          
% List periods that are transition periods that are taken from pieces of
% rest and walk. The "continued rest" and "continued walk" is the rest and
% walk that is left after the transition periods are removed. 
periods_transition={'startwalk';     % Run the within-walk periods first,so you can make sure there's a real "walking" period after the prewalk, not just a large fidget
                'prewalk'; 
                'stopwalk';
               'postwalk'}; 
                             
% List the threshold speeds of each long period (lower, upper) in cm/s;
% Values that fall between the 0.05 and 0.25 are probably twitches or
% fidgets. 
periods_long_threshold=[ -0.25 0.05;  % rest low, rest high. We don't want to count walking fast backwards.
                         0.25 Inf];   % walk low, walk high
                     
% List the search orders for finding the earliest or most recent velocity
% of 0 to define the start and stop of rest or locomotion. This makes more
% sense when you look at the code that uses it (lines 100-150 ish) 
periods_long_searchorder={'first', 'last';    % rest start, rest stop
                          'last', 'first'};   % walk start, walk stop
                      
%% list other parameters          

% recording info
wheel_hz=1000; % samples the wheel encoder takes per second
fps=20; % frames per second of brain imaging 
frames=6000; % number of frames you recorded from brain and want to keep (don't make chunks longer than this)  

% analysis info
k=100; % number of time points to smooth the vel by 
time_window_seconds=3; % how the animal needs to be at rest or walking for it to count, in seconds

time_window_frames=time_window_seconds*fps; % how long the animal needs to be at rest or walking, in frames
time_window_hz=time_window_seconds*wheel_hz; % how long the animal needs to be at rest or walking, in wheel sampled time points

% Do you want full transitions? (These are rare)
full_transition_flag=1;   % 1 if you want "full onsets" and "full offsets" calculated; 0 if not 
periods_full_transition={'full_onset';
                         'full_offset'}; 
                     
full_transition_extra_time=1; % In seconds, the amount of time into the continued rest and walk that should be included in the full transition                     
full_transition_extra_hz=full_transition_extra_time*wheel_hz; % in wheel sampled timepoints, the amount of time into the continued rest and walk that should be included in the full transition                     

%% Start 
for dayi= 1:size(days_all,1)        % for each day
    disp(['day ' num2str(dayi)]);
    day=days_all(dayi,:);
    
    % **** DIRECTORIES ****
    dir_in=['Z:\DBSdata\Sarah\Awake GCaMP\' day '_behavior\wheel\'];
    dir_save=['Y:\Sarah\Analysis\behavior analysis\test\' day '\vel periods\']; 
    mkdir(dir_save) ;

    list=dir([dir_in 'wheel*.mat']);  
    for stacki=1:size(list,1)          % for each stack 
         load([dir_in list(stacki).name]);   
         name=list(stacki).name(1:7);
         stacknum=name(6:7); 
     
         eval(['wheel_correct=[' name '(:,2)./24000*2*pi*8.5];']);  
         smooth=movmean(wheel_correct,k); % Smooth the wheel 
         vel=diff(smooth).*1000;  %time data is in first column of wheel, position data in second
     
        % find the long periods 
        for periodi=1:size(periods_long,1)
            period=periods_long{periodi}; 
            % Apply the velocity thresholds
            binary_hold1=vel>periods_long_threshold(periodi,1);
            binary_hold2=vel<periods_long_threshold(periodi,2);
            binary=binary_hold1 & binary_hold2; 

            events=diff(binary); % --> 1 =mouse started the period, -1=mouse stopped the period
            ind_start=find(events==1); % find where the period started
            ind_stop=find(events==-1); % find where the period ended
            ind_startstop={ind_start; ind_stop}; % put these together to make it easier to cycle through in a for loop
            
            % Now that you've found where the velocity crosses the
            % preferred thresholds, you need to find when the velocity
            % first/last left/entered a value of 0, which is when the
            % period actually started. 
            for startstopi=1:2
                ind_using=ind_startstop{startstopi}; % now grab ind_starts or ind_stops, but with the generic name "ind_using"
                reals=NaN(size(ind_using));
                direction=periods_long_searchorder{periodi, startstopi}; % what direction you have to look in to find the relevant "0" vel
                for i=1:size(ind_using,1)
                                  
                    % You might get more than one 0 or 0 cross point, so
                    % you have to pick the most recent or the earlier one,
                    % based on if you're looking at rest or walk or if it's a start or stop, 
                   switch direction
                       case 'last'
                          holdind1=find(vel(1:ind_using(i))==0,1,direction); % find the last time velocity was 0
                          neg_check=vel(1:(ind_using(i)-1)).*vel(2:ind_using(i));  % or see if this event has vel from negative to positive
                          holdind2=find(neg_check<0,1, direction);
                          holdind=max([holdind1 holdind2]); % choose the most recent  
                          
                       case 'first' % if the direction variable is "first"
                         holdind1=find(vel(ind_using(i):end)==0,1,'first'); 
                         neg_check=vel(ind_using(i):(end-1)).*vel((ind_using(i)+1):end); 
                         holdind2=find(neg_check<0,1, 'first');
                         holdind=min([holdind1 holdind2]); % choose the earlier one
                   end
                     
                    % if there's no 0 or 0 cross point
                    if isempty(holdind)==1 
                        switch startstopi
                            case 1  % if this is a start
                                reals(i)=1;  %  the only time this should be empty is if there was figiting at the beginning of the recording 
                            case 2 % if this is a stop
                                reals(i)=size(vel,1);  %  the only time this should be empty is if there was figiting at the end of the recording 
                        end
                    % otherwise,    
                    else
                        switch direction
                            case 'last' % rest stops, locomtion starts
                                reals(i)=holdind;   
                            case 'first' % rest starts, locomotion stops 
                                reals(i)= holdind+length(vel(1:ind_using(i))); 
                        end
                    end 
                end
                % remove any NaNs that were left over (something strange
                % happened)
              
                ind_NaN=isnan(reals);
                reals(ind_NaN)=[];
                
                if startstopi==1     % rename variables based on if it's the starts or stops
                   real_starts=reals;
                elseif startstopi==2
                   real_stops=reals;
                end
            end
               
            % Deal with the first and last values of the binary vector
            % (wouldn't be counted in the "events" vector). These will
            % count as starts and stops, based on what the animal was doing
            % at that time
            if binary(1)==1
                real_starts=[1; real_starts];
            end
            if binary(end)==1
                real_stops=[real_stops; length(binary)]; 
            end 
            real_starts=unique(real_starts);
            real_stops=unique(real_stops);     
         
            % rename based on period        
            eval([period '_real_starts=real_starts;']); 
            eval([period '_real_stops=real_stops;']); 
        end
   
     %% Check rest and walk period ranges, make "rest_periods" and "walk_periods" variables
     % Should always have a stop between two starts and vice versa
    
     % cycle through long periods
     for periodi=1:size(periods_long,1)
         period=periods_long{periodi} ;
         eval(['real_starts=' period '_real_starts;']); 
         eval(['real_stops=' period '_real_stops;']); 
         if isempty(real_starts)==1 % if empty (should only happen if the mouse walks or fidgits and stops for only less than 3 seconds)  
            periods_holding=[];  % then there are no intances for that period 
         else % if not empty
             
            % Set up a holding variable (using a holding variable of NaNs preserves the order/sequence of the instances).  
            periods_holding=NaN(size(real_starts,1),2);  

            for ii=1:(size(real_starts,1)-1)  % for each start
                % find stops that occur after this start
                matched1=find(real_stops>real_starts(ii)); 
                % find stops that occur before the next start
                matched2=find(real_stops<real_starts(ii+1)); 
                % keep only the stops that fit these criteria
                matched=intersect(matched1, matched2);
                if isempty(matched)==1
                    % if empty, do nothing; will leave this start-stop pair as NaNs
                else   % if not empty
                    periods_holding(ii,1)=real_starts(ii);
                    periods_holding(ii,2)=real_stops(matched(1)); % If more than one stop fit the criteria, keep just the first 
                end
            end 

            % now do this for the last start, which needs it's own code
            % find any stops larger than the start. 
            matched=find(real_stops>real_starts(end));
            if isempty(matched)==1
                % if empty, do nothing; Will be left as a bad NaN If the last timepoint of the trial were the corresponding stop, that would've been caught in the code above  
            else  % if not empty 
                periods_holding(end, 1)=real_starts(end); % put the start in place
                periods_holding(end,2)=real_stops(matched(1)); % put the stop in place; If more than one stop fit the criteria, keep just the first 
            end

            % check for and remove intances that were left as NaNs (bad instances) 
            [r,c]=find(isnan(periods_holding)); % find any NaNs
            if all(isempty([c r]))==1 % if none are NaN 
                %do nothing
            else    
                periods_holding(r,:)=[]; % Remove instances that were left as NaNs
            end
         end
        % rename variables back to the period-specific version
        eval([period '_periods=periods_holding;']); 
     end 
                
    %% only periods of locomotion and rest that end/start at the same point
     % will be called a true, uninterrupted state transition that can be
     % used for finding transition periods.

     rest_to_walk=intersect(rest_real_stops, walk_real_starts);  % moments that mouse goes from rest to walking
     walk_to_rest=intersect(walk_real_stops, rest_real_starts);  % moments that mouse goes from walking to rest 

    
   %% find clean periods of prewalk, startwalk, stopwalk, and postwalk 
    % Find the transition periods and remove them from the relevant long
    % periods.Calculations need to be done individually, since all the transition states are defined differently.
    
   for periodi=1:size(periods_transition,1) % for each trasition period 
       period=periods_transition{periodi};
       
       % ***Find the "unclean periods"--> defined by distance from rest-walk transitions. ***
       switch period
           case 'prewalk'
               unclean_periods=[rest_to_walk-time_window_hz , rest_to_walk];  
           case 'startwalk'
               unclean_periods=[rest_to_walk, rest_to_walk+time_window_hz]; 
           case 'stopwalk'
               unclean_periods=[walk_to_rest-time_window_hz , walk_to_rest];
           case 'postwalk'    
               unclean_periods=[walk_to_rest, walk_to_rest+time_window_hz]; 
       end
       % *** Now, make sure the relevant rest or walk periods actually extend far enough in each direction. ***
       
       % set up variable to hold rows (instances) for removal
       rows_todelete=[]; 
       
       % set up flag for removing; start with the instance not being
       % removed (flag is O)
       removal_flag=0; 
       
       % cycle through each instance of the relevant transition. Run the
       % within-walk periods first so you only take the outside-walk
       % periods that immediately precede/follow real walk periods at least
       % 3 seconds in length. 
       switch period
           case {'prewalk', 'starwalk'} 
                for rowi=1:size(rest_to_walk,1) 
                    % do the relevant calculations 
                    switch period
                        case 'startwalk'
                            % find the walk period that begins at the same time the startwalk period does
                            ind1=find(walk_periods(:,1)==unclean_periods(rowi,1)); 
                            
                            % if the walk period doesn't extend far foward enough in time, mark the instance for removal 
                            if walk_periods(ind1,2)<unclean_periods(rowi,2) 
                                removal_flag=1; 
                            else % if the walk period IS long enough
                                % keep the startwalk, truncate the walk period so it doesn't include the startwalk
                                walk_periods(ind1,1)=unclean_periods(i,2); 
                            end
                            
                        case 'prewalk'
                            % Start working on this in terms of startwalk 
                            % find the rest period that ends at the same time the prewalk period does
                             ind1=find(rest_periods(:,2)==unclean_periods(rowi,2)); 
                            
                             % if the rest period doesn't extend far back enough in time, mark the instance for removal 
                             if rest_periods(ind1,1)>unclean_periods(rowi,1)
                                 removal_flag=1;
                             else  % if the rest period IS long enough
                                 % keep the prewalk, truncate the rest period so it doesn't include the prewalk
                                 rest_periods(ind1,2)=unclean_periods(rowi,1);   
                             end 
                        
                    end
                    % if row/instance was marked for removal, add row to the list for removal 
                    if removal_flag==1
                       rows_todelete=[rows_todelete; rowi];
                    end
                end
           case {'stopwalk', 'postwalk'} 
                for rowi=1:size(walk_to_rest,1)
                    % do the relevant calculations 
                    switch period
                        case 'stopwalk'
                            % find the walk period that ends at the same time the stopwalk period does
                            ind1=find(walk_periods(:,2)==unclean_periods(rowi,2)); 
                            
                            % if the walk period doesn't extend far back enough in time, mark the instance for removal
                            if walk_periods(ind1,1)>unclean_periods(rowi,1) 
                                removal_flag=1; 
                            else  % if the rest period IS long enough
                                % keep the stopwalk, truncate the rest period so it doesn't include the stopwalk
                                walk_periods(ind1,2)=unclean_periods(rowi,1);  
                            end
                            
                        case 'postwalk'
                            % find the rest period that begins at the same time the postwalk period does
                            ind1=find(rest_periods(:,1)==unclean_periods(rowi,1));
                            
                            % if the rest period doesn't extend far foward enough in time, mark the instance for removal
                            if rest_periods(ind1,2)<unclean_periods(rowi,2) 
                               removal_flag=1; 
                            else % if the walk period IS long enough  
                                % keep the postwalk, truncate the rest period so it doesn't include the postwalk
                                rest_periods(ind1,1)=unclean_periods(rowi,2);
                            end 
                    end
                    % if row/instance was marked for removal, add row to the list for removal 
                    if removal_flag==1
                       rows_todelete=[rows_todelete; rowi];
                    end
                end 
       end
       
       % start cleaning the "unclean" periods
        periods_holding=unclean_periods; 
       % don't let them fall above length of vel or below index 1
       [rows1, columns]=find(periods_holding>size(vel,1)); 
       [rows2, columns]=find(periods_holding<1); 
       rows_todelete=[rows_todelete; rows1; rows2];
       
       % remove the "unclean" intances
       periods_holding(rows_todelete,:)=[];  
       
       % give variables a period-specific name
       eval([period '_periods=periods_holding;']);
   end
  
 
 %% find clean instances of walk, rest (at least 3 seconds)  
 % Now that you've removed the transition periods, find instances of rest 
 % and walk that are at least 3 seconds. This will let you divide those 
 % longer instances into continued rest & walk instances later. You'll remove 
 % the instances that are less than 3 seconds.

 % Cyle through the "rest" and "walk" periods
 for periodi=1:size(periods_long,1)
     period=periods_long{periodi};

     % switch to a generic name for cycling through
     eval(['periods_holding=' period '_periods;']);

     if isempty(periods_holding)==1  % if there are no intances of this period
          % Do nothing (there are no instances that are "long enough")
     else  
         % calculate how long the instances are
         periods_lengths=periods_holding(:,2)-periods_holding(:,1); 

         % find if they're shoreter than the desired length
         ind1=find(periods_lengths<time_window_hz); 

         % remove the too-short instances
         periods_holding(ind1,:)=[];

         % return to period-specific name
        eval([period '_periods=periods_holding;']); 
     end 
 end
 
 %% Break down walk and rest instances into 3s instances so you don't have to later

    for periodi=1:size(periods_long,1) % for each period 
        period=periods_long{periodi};      
        % switch to a generic name for cycling through
        eval(['periods_holding=' period '_periods;']);
        
        if isempty(periods_holding)==1 % if there are no long enough instances
            % then both the "long" and "brokendown" versions of rest/walk will be empty
            holding_long=[]; 
            brokendown=[];
        else    
           holding_long=periods_holding; % will save the not-divded versions of rest/walk 
           brokendown=[];
           
           % for each instance in a period
           for instancei=1:size(periods_holding,1) 
               % find the length of the instance
               period_length=periods_holding(instancei,2)-periods_holding(instancei,1)+1;
               if period_length > time_window_hz   % if the walk chunk is greater than 3 seconds 
                  % find how many 3-second chunks the instance can make 
                  quotient=floor(period_length/time_window_hz);
                  
                  % make the first chunk start where the instance starts
                  new_chunk_start=periods_holding(instancei, 1); 
                  
                  % make the first chunk end 1 time window length after the
                  % start of the instance
                  new_chunk_end=periods_holding(instancei,1)+time_window_hz-1; 
                  
                  % concatenate the first chunk into list of brokendown
                  % chunks for the stack
                  brokendown=[brokendown; new_chunk_start, new_chunk_end]; 
                  
                  % if the instance can create more than 1 3-second chunk
                  if quotient>1
                      for quotienti=1:(quotient-1) % don't use the last one because you're cycling through the *start* of each chunk
                          
                          % find the start of the given chunk
                          new_chunk_start=periods_holding(instancei,1)+time_window_hz*quotienti;
                          
                          % find the end of the given chunk
                          new_chunk_end=periods_holding(instancei,1)+time_window_hz*quotienti+time_window_hz-1;
                          
                          % concatenate the chunk into your list of 
                          brokendown=[brokendown; new_chunk_start, new_chunk_end ] ;
                      end 
                  end
               else
                   %if it isn't too long (can only happen if exactly the length of the time window)
                   %make only 1 chunk using the start and stop of the
                   %instancee
                   brokendown=[brokendown; periods_holding(instancei,:)];   
               end
           end
                  
        end
         % return to period-specific name
          eval([period '_periods=brokendown;']);
          eval([period '_long_periods=holding_long;']); 
    end
 
 
%% correct these behavior periods based on velocity
% Because sometimes the logic above goes wrong, and this double-checks the accuracy.
% Includes top and bottom thresholds 

periods_all=[periods_long; periods_transition];

 for periodi=1:size(periods_all,1) % for each period (all periods) 
     period=periods_all{periodi};

     % switch to a generic name for cycling through
     eval(['periods_holding=' period '_periods;']);

     % create a variable to hold all the "bad" instances for removal
     rows_todelete=[];

     for rowi=1:size(periods_holding) % for each instance of the period

        % make a variable that keeps track of if the instance/row
        % should be deleted. Always start by assuming it shouldn't be (the flag = 0). 
        violation_flag=0; 

        % find violations; will depend on which period you're looking at
        switch period
            % Rest must always stay within the rest thresholds
            case 'rest'
                % Find if any of the instance goes below the bottom rest threshold
                bottom_violation=any(vel(periods_holding(rowi,1):periods_holding(rowi,2))<periods_long_threshold(1,1));

                % Find if any of the instance goes above the top rest threshold
                top_violation=any(vel(periods_holding(rowi,1):periods_holding(rowi,2))>periods_long_threshold(1,2));

                % see if either threshold was violated.
                violation_flag=any([bottom_violation top_violation]); % change the violation flag

            case 'walk'
                % Find if any of the instance goes below the bottom walk threshold
                bottom_violation=any(vel(periods_holding(rowi,1):periods_holding(rowi,2))<periods_long_threshold(2,1));

                % Find if any of the instance goes above the top walk
                % threshold (isn;t necessary if top threshold= Inf); 
                top_violation=any(vel(periods_holding(rowi,1):periods_holding(rowi,2))>periods_long_threshold(2,2));

                % see if either threshold was violated.
                violation_flag=any([bottom_violation top_violation]); % change the violation flag

            case 'prewalk'
                % can fidget in the last second
                violation_flag=any(vel(periods_holding(rowi,1):(periods_holding(rowi,2)-20))>periods_long_threshold(1,2));
           
            case 'startwalk'
                % after the first second, the mouse must always be over the walking threshold
                violation_flag=any(vel((periods_holding(rowi,1)+wheel_hz):periods_holding(rowi,2))<periods_long_threshold(2,1)); 

            case 'stopwalk'
                % must stay above the walking threshold until the last second
                violation_flag=any(vel(periods_holding(rowi,1):(periods_holding(rowi,2)-wheel_hz))<periods_long_threshold(2,1));

            case 'postwalk'
                % allow wheel to swing backwards some (below bottom rest threshold), but don't let it go over top rest threshold 
                violation_flag=any(vel((periods_holding(rowi,1)+wheel_hz):periods_holding(rowi,2))>periods_long_threshold(1,2));
        end

        % mark if row (instance) should be deleted
        if violation_flag==1            
            rows_todelete=[rows_todelete; rowi];
        end
     end 

     % remove violating rows
     periods_holding(rows_todelete,:)=[]; 

     % return to period-specific name
     eval([period '_periods=periods_holding;']); 
 end


   %% Find sections of data that can be used for rolling correlations across transitions
   % For onset of locomotion: full time windows of prewalk, startwalk adjacent to one another, plus 1 sec before and after;
   % For offset of locomotion: full time windows of stopwalk, postwalk adjacent to one another plus 1 sec before and after. 
   
   % Only calculate if the user says to  
   if full_transition_flag==1
       
       for periodi=1:size(periods_full_transition,1)
           period=periods_full_transition{periodi}; 
           
           % make an empty variable to hold beginning and end sections of newly calculated instances
           rest_onesecond=[];
           walk_onesecond=[];
           
           switch period
               case 'full_onset' 
                    % for each section of startwalk data (for each onset of locomotion)
                    for row_startwalk=1:size(startwalk_periods,1) 
                
                        % see if there's a full segment of prewalk before the onset
                        row_prewalk=find(prewalk_periods(:,2)==startwalk_periods(row_startwalk,1));  

                        if isempty(row_prewalk)==0   % if there IS a segment of prewalk

                            % find segments of rest and walk before and
                            % after and concatenate into list of segments
                            rest_onesecond_hold=[(prewalk_periods(row_prewalk,1)-full_transition_extra_hz),prewalk_periods(row_prewalk,1)-1]; 
                            walk_onesecond_hold=[(startwalk_periods(row_startwalk,2)+1),startwalk_periods(row_startwalk,2)+full_transition_extra_hz]; 
                            
                            rest_onesecond=[rest_onesecond; rest_onesecond_hold];
                            walk_onesecond=[walk_onesecond; walk_onesecond_hold];
                            
                            disp('potential onset');
                        end
                    end
                    
               case 'full_offset'
                    % for each section of startwalk data (for each onset of locomotion)
                    for row_stopwalk=1:size(stopwalk_periods,1)
                        
                        % see if there's a full segment of postwalk after the offset
                        row_postwalk=find(postwalk_periods(:,1)==stopwalk_periods(row_stopwalk,2));

                         if isempty(row_postwalk)==0   % if there IS a segment of postwalk
                             
                            % find segments of rest and walk before and
                            % after and concatenate into list of segments
                            rest_onesecond=[(postwalk_periods(row_postwalk,2)+1),postwalk_periods(row_postwalk,2)+full_transition_extra_hz]; 
                            walk_onesecond=[(stopwalk_periods(row_stopwalk,1)-full_transition_extra_hz),stopwalk_periods(row_stopwalk,1)-1]; 
                            
                            rest_onesecond=[rest_onesecond; rest_onesecond_hold];
                            walk_onesecond=[walk_onesecond; walk_onesecond_hold];
                            
                            disp('potential offset');
                         end 
                    end 
           end
           % make sure the rest_onesecond and walk_onesecond don't fall
           % outside trial range
           rows_todelete=[];
           for rowi=1:size(rest_onesecond,1)
               violation_flag=0;
               if any(rest_onesecond(rowi,:)<1)
                   violation_flag=1;
               end
               if any(rest_onesecond(rowi,:)>size(vel,1))
                   violation_flag=1;
               end
               if any(walk_onesecond(rowi,:)<1)
                   violation_flag=1;
               end
               if any(walk_onesecond(rowi,:)>size(vel,1))
                   violation_flag=1;
               end
               if violation_flag==1
                    rows_todelete=[rows_todelete; rowi];
               end
           end
           % remove bad rows
           if isempty(rows_todelete)==0
              rest_onesecond(rows_todelete,:)=[];
              walk_onesecond(rows_todelete,:)=[];
              disp('violation');
           end
           
           % make sure the rest_onesecond and walk_onesecond always fall in
           % real rest and walk.
           
           % make a list of rows to delete
           rows_todelete=[];
           for rowi=1:size(rest_onesecond,1) % only need to cycle through one (they're the same size)
               % check the rest thresholds 
               bottom_violation=any(vel(rest_onesecond(rowi,1):rest_onesecond(rowi,2))<periods_long_threshold(1,1));
               top_violation=any(vel(rest_onesecond(rowi,1):rest_onesecond(rowi,2))>periods_long_threshold(1,2));
               rest_violation=any([bottom_violation, top_violation]); 
               
               % check the walk thresholds 
               bottom_violation=any(vel(walk_onesecond(rowi,1):walk_onesecond(rowi,2))<periods_long_threshold(2,1));
               top_violation=any(vel(walk_onesecond(rowi,1):walk_onesecond(rowi,2))>periods_long_threshold(2,2));
               walk_violation=any([bottom_violation, top_violation]); 
               
               % if either are violated, mark the row for deletion
               if any([rest_violation walk_violation])==1
                    rows_todelete=[rows_todelete; rowi];
                    disp('violation');
               end
           end
           
           % remove bad rows again
           if isempty(rows_todelete)==0
              rest_onesecond(rows_todelete,:)=[];
              walk_onesecond(rows_todelete,:)=[];
           end
           
           % calculate full range
           if isempty(rest_onesecond)==1   %only need to check 1, the other should also be empty
              periods_holding=[]; 
           else 
               switch period
                   case 'full_onset'
                       periods_holding=rest_onesecond(:,1):walk_onesecond(:,2); 
                   case 'full_offset'
                       periods_holding=walk_onesecond(:,1):rest_onesecond(:,2); 
               end
           end
           % Rename with period-specific name
            eval([period '_periods=periods_holding;']);
       end 
    end
    
 %% Convert the time periods to frames, then correct any problems from the conversion
     
    % ***make one big list of periods to cycle through***
  
    % start with the basic 3-second ones
    periods_large=periods_all; 
     
     % then add in the "long" periods, which need to have the period names
     % changed
     for i=1:size(periods_long,1)
         periods_large=[periods_large; [periods_long{i} '_long']]; 
     end
     
     % if full transitions are included, put those in, too.
     if full_transition_flag==1
         periods_large=[periods_large; periods_full_transition];
     end
 
     % ***cycle through all 3-second periods***
     for periodi=1:size(periods_large,1)
         period=periods_large{periodi};
         
         % convert variable names to something generic to cycle through
         eval(['periods_holding=' period '_periods;']); 
         
         % convert time ranges to frames
         periods_correct=round(periods_holding.*fps./wheel_hz); 
         
         % correct any problems introduced by the rounding   
         if isempty(periods_correct)==0 % only if periods aren't empty

             % Don't let the first frame be called "0." The indexing has to 
             % start at 1. This is still a valid intance though, so change the
             % index to "1".
             if periods_correct(1)==0   
                periods_correct(1)=1;
             end
             
             % Don't keep any instances indexed as negative. Something very bad 
             % probably happened in the calculations, so get rid of the whole
             % period.
             [row1,column]=find(periods_correct<1);
             
             % Don't keep any instances indexed as greater than the total number
             % of frames there are supposed to be. Something very bad 
             % probably happened in the calculations, so get rid of the whole
             % period.
             [row2,column]=find(periods_correct>frames);
             
             % remove the bad instances;
             rows_todelete=[row1; row2];
             periods_correct(rows_todelete,:)=[];
         end
         
         % change generic name back to period name
         eval([period '_periods_correct=periods_correct;']);
     end
    
    %% Save all the corrected data 
     
     save([dir_save 'behavior_periods_' name(6:7)], 'rest_periods_correct', ...
                                                    'walk_periods_correct', ...
                                                    'prewalk_periods_correct', ...
                                                    'startwalk_periods_correct', ...
                                                    'stopwalk_periods_correct', ...
                                                    'postwalk_periods_correct')
                                                    %'rest_long_periods_correct',...
                                                    %'walk_long_periods_correct'); 

      % save the full transition data, if user said "go"
      if full_transition_flag==1
          save([dir_save 'full_transitions_' stacknum], 'full_onset_periods', 'full_offset_periods');
      end
end
    
end 