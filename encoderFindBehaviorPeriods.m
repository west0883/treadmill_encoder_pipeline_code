% encoderFindBehaviorPeriods.m
% Sarah West
% 10/11/21

function [parameters] = encoderFindBehaviorPeriods(parameters)

    % Announce what stack you're on.
    message = ['Finding '];
    for dispi = 1:numel(parameters.values)/2
       message = [message ', ' parameters.values{dispi}];
    end
    disp(message);

    % Give parameters their original names
    
    fps = parameters.fps; 
    frames = parameters.frames;
   
    periods_long_threshold = parameters.periods_long_threshold;
    periods_long = parameters.periods_long;   
    periods_transition = parameters.periods_transition;
    periods_long_searchorder = parameters.periods_long_searchorder;

    duration_place_maximum_default = parameters.duration_place_maximum_default;
    
    time_window_frames = parameters.time_window_frames;
    time_window_frames_continued = parameters.time_window_frames_continued;
    full_transition_flag = parameters.full_transition_flag;  
    periods_full_transition =parameters.periods_full_transition;                 
                    
    full_transition_extra_frames = parameters.full_transition_extra_frames;
    
    % Make yet another cell to hold names of not-broken-down long periods
    % for cycling through later. 
    periods_longname = cell(2,1);
    for i =1:size(periods_long,1)
         periods_longname{i} = [periods_long{i} '_long']; 
    end
 
    % Change the variable name for ease.
    vel = parameters.velocity.corrected;
    
    % Start getting behaviors.
    
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

     % Cycle through long periods
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

   % ***Find the "unclean periods"--> defined by distance from rest-walk transitions. ***

   % Prewalk
   prewalk_unclean_periods=[rest_to_walk-time_window_frames + 1, rest_to_walk];  

   % Startwalk
   startwalk_unclean_periods=[rest_to_walk + 1, rest_to_walk+time_window_frames]; 

   % Stopwalk
   stopwalk_unclean_periods=[walk_to_rest-time_window_frames + 1 , walk_to_rest];

   % Postwalk
   postwalk_unclean_periods=[walk_to_rest + 1, walk_to_rest+time_window_frames]; 

   % *** Now, make sure the relevant rest or walk periods actually extend far enough in each direction. *** 

   % Cycle through each instance of the relevant transition. Run the
   % within-walk periods first so you only take the outside-walk
   % periods that immediately precede/follow real walk periods at least
   % 3 seconds in length. 

   % Begin calculations for startwalk and prewalk

   % Set up variable to hold rows (instances) for removal
   startwalk_rows_todelete=[]; 
   prewalk_rows_todelete=[]; 
   walk_rows_todelete = []; 
   rest_rows_todelete = [];

   % For each rest-to-walk transition
   for rowi=1:size(rest_to_walk,1) 

        % Startwalk calculations

        % Find the walk period that begins at the same time the startwalk period does
        ind1=find(walk_periods(:,1)==startwalk_unclean_periods(rowi,1) - 1); 

        % if the walk period doesn't extend far foward enough in time,
        % mark the instance for removal from both startwalk and prewalk &
        % that walk
        if walk_periods(ind1,2)<startwalk_unclean_periods(rowi,2) 

            startwalk_rows_todelete=[startwalk_rows_todelete; rowi];
            prewalk_rows_todelete=[prewalk_rows_todelete; rowi];
            walk_rows_todelete = [walk_rows_todelete; ind1];

        % If the walk period IS long enough
        else
            % Keep the startwalk, truncate the walk period so it doesn't include the startwalk
            walk_periods(ind1,1)=startwalk_unclean_periods(rowi,2) + 1;    

            % Can now check if the corresponding prewalk in this instance is usable

            % Prewalk calculations

            % Find the rest period that ends at the same time the prewalk period does
            ind1=find(rest_periods(:,2)==prewalk_unclean_periods(rowi,2)); 

            % If the rest period doesn't extend far back enough in time, mark the instance for removal 
            if rest_periods(ind1,1)>prewalk_unclean_periods(rowi,1)
                prewalk_rows_todelete=[prewalk_rows_todelete; rowi];
                rest_rows_todelete = [rest_rows_todelete; ind1];

            % If the rest period IS long enough
            else  
                % keep the prewalk, truncate the rest period so it doesn't include the prewalk
                rest_periods(ind1,2)=prewalk_unclean_periods(rowi,1);   
            end 
        end
    end        

    % Begin calculations for stopwalk and postwalk

    % Set up variable to hold rows (instances) for removal
    stopwalk_rows_todelete=[]; 
    postwalk_rows_todelete=[]; 

   % For each walk-to-rest transition
    for rowi=1:size(walk_to_rest,1)

        % Stopwalk calculations
        % Find the walk period that ends at the same time the stopwalk period does
        ind1=find(walk_periods(:,2)==stopwalk_unclean_periods(rowi,2)); 

        % if the walk period doesn't extend far back enough in time, mark
        % the instance in stopwalk and postwalk for removal
        if walk_periods(ind1,1)>stopwalk_unclean_periods(rowi,1) 

            stopwalk_rows_todelete=[stopwalk_rows_todelete; rowi];
            postwalk_rows_todelete=[postwalk_rows_todelete; rowi];
            walk_rows_todelete = [walk_rows_todelete; ind1];
        
        % If the walk period IS long enough
        else 
            % Keep the stopwalk, truncate the walk period so it doesn't include the stopwalk
            walk_periods(ind1,2)=stopwalk_unclean_periods(rowi,1);  

            % Can now check if the corresponding postwalk in this instance is usable

            % Postwalk calculations

            % Find the rest period that begins at the same time the postwalk period does
            ind1=find(rest_periods(:,1)==postwalk_unclean_periods(rowi,1) - 1);

            % If the rest period doesn't extend far backward enough in time, mark the instance for removal
            if rest_periods(ind1,2)<postwalk_unclean_periods(rowi,2) 
                postwalk_rows_todelete=[postwalk_rows_todelete; rowi];
                rest_rows_todelete = [rest_rows_todelete; ind1];

            % If the rest period IS long enough  
            else 
                % Keep the postwalk, truncate the rest period so it doesn't include the postwalk
                rest_periods(ind1,1)=postwalk_unclean_periods(rowi,2) + 1;
            end 
        end
    end 

    % Remove "unclean" periods found above. 

    for periodi=1:size(periods_transition,1)
        period=periods_transition{periodi};
        
        % Switch to generic names
        eval(['periods_holding=' period '_unclean_periods;']);  
        eval(['rows_todelete=' period '_rows_todelete;']); 
        
        % Don't let period ranges fall above length of vel or below index 1
        [rows1, ~]=find(periods_holding>size(vel,1)); 
        [rows2, ~]=find(periods_holding<1); 
        
        rows_todelete=[rows_todelete; rows1; rows2];
        
        % remove the "unclean" intances
        periods_holding(rows_todelete,:)=[];  
        
        % Return variables to a period-specific name
        eval([period '_periods=periods_holding;']);
    end

    for periodi=1:size(periods_long,1)
        period=periods_long{periodi};
        
        % Switch to generic names
        eval(['periods_holding=' period '_periods;']);  
        eval(['rows_todelete=' period '_rows_todelete;']); 
        
        % Don't let period ranges fall above length of vel or below index 1
        [rows1, ~]=find(periods_holding>size(vel,1)); 
        [rows2, ~]=find(periods_holding<1); 
        
        rows_todelete=[rows_todelete; rows1; rows2];
        
        % remove the "unclean" intances
        periods_holding(rows_todelete,:)=[];  
        
        % Return variables to a period-specific name
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
         ind1=find(periods_lengths<time_window_frames_continued); 

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
            duration_place = [];
        else    
           holding_long=periods_holding; % will save the not-divded versions of rest/walk 
           brokendown=[];
           duration_place = [];

           % for each instance in a period
           for instancei=1:size(periods_holding,1) 

               duration_place_number = 1;

               % find the length of the instance
               period_length=periods_holding(instancei,2)-periods_holding(instancei,1)+1;
               if period_length > time_window_frames_continued   % if the walk chunk is greater than 3 seconds 
                  % find how many 3-second chunks the instance can make 
                  quotient=floor(period_length/time_window_frames_continued);

                  % make the first chunk start where the instance starts
                  new_chunk_start=periods_holding(instancei, 1); 

                  % make the first chunk end 1 time window length after the
                  % start of the instance
                  new_chunk_end=periods_holding(instancei,1)+time_window_frames_continued-1; 

                  % concatenate the first chunk into list of brokendown
                  % chunks for the stack
                  brokendown=[brokendown; new_chunk_start, new_chunk_end]; 
                  duration_place = [duration_place; 1];

                  % if the instance can create more than 1 3-second chunk
                  if quotient>1
                   
                      for quotienti=1:(quotient-1) % don't use the last one because you're cycling through the *start* of each chunk

                          % find the start of the given chunk
                          new_chunk_start=periods_holding(instancei,1)+time_window_frames_continued*quotienti;

                          % find the end of the given chunk
                          new_chunk_end=periods_holding(instancei,1)+time_window_frames_continued*quotienti+time_window_frames_continued-1;

                          % concatenate the chunk into your list of 
                          brokendown=[brokendown; new_chunk_start, new_chunk_end ] ;
                          duration_place = [duration_place; quotienti + 1];
                          duration_place_number = duration_place_number + 1; 
                      end 
                  end
               else
                   %if it isn't too long (can only happen if exactly the length of the time window)
                   %make only 1 chunk using the start and stop of the
                   %instancee
                   brokendown=[brokendown; periods_holding(instancei,:)];   
                   duration_place = [duration_place; 1];
               end

               % If the continued period starts at the beginning of the stack
               % (extends before it), make all the duration places of this
               % instance (with duration_place_number) into a default
               % maximum number.
               if instancei == 1 && periods_holding(instancei, 1) == 1

                   duration_place(end - duration_place_number + 1 : end) = duration_place_maximum_default;
                 
               end
           end

        end

        % return to period-specific name
        eval([period '_periods=brokendown;']);
        eval([period '_long_periods=holding_long;']); 
        eval([period '_duration_place = duration_place;'])
    end


    %% correct these behavior periods based on velocity
    % Because sometimes the logic above goes wrong, and this double-checks the accuracy.
    % Includes top and bottom thresholds 
    
    periods_all=[periods_long; periods_transition; periods_longname];
    
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
                    violation_flag=any(vel(periods_holding(rowi,1):(periods_holding(rowi,2)- fps))>periods_long_threshold(1,2));
    
                case 'startwalk'
                    % after the first second, the mouse must always be over the walking threshold
                    violation_flag=any(vel((periods_holding(rowi,1)+fps):periods_holding(rowi,2))<periods_long_threshold(2,1)); 
    
                case 'stopwalk'
                    % must stay above the walking threshold until the last second
                    violation_flag=any(vel(periods_holding(rowi,1):(periods_holding(rowi,2)-fps))<periods_long_threshold(2,1));
    
                case 'postwalk'
                    % allow wheel to swing backwards some (below bottom rest threshold), but don't let it go over top rest threshold 
                    violation_flag=any(vel((periods_holding(rowi,1)+fps):periods_holding(rowi,2))>periods_long_threshold(1,2));
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

         % If this is rest or walk (continued periods), also remove
         % corresponding duration place
         if strcmp(period, 'rest') || strcmp(period, 'walk')
             eval(['duration_place = ' period '_duration_place;']);
             duration_place(rows_todelete, :) = [];
             eval([period '_duration_place = duration_place;']); 

             % also put into output structure
             parameters.duration_places.(period) = duration_place;

         end
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
                        row_prewalk=find(prewalk_periods(:,2)==startwalk_periods(row_startwalk,1) - 1);  

                        if isempty(row_prewalk)==0   % if there IS a segment of prewalk

                            % find segments of rest and walk before and
                            % after and concatenate into list of segments
                            rest_onesecond_hold=[(prewalk_periods(row_prewalk,1)-full_transition_extra_frames),prewalk_periods(row_prewalk,1)-1]; 
                            walk_onesecond_hold=[(startwalk_periods(row_startwalk,2)+1),startwalk_periods(row_startwalk,2)+full_transition_extra_frames]; 

                            rest_onesecond=[rest_onesecond; rest_onesecond_hold];
                            walk_onesecond=[walk_onesecond; walk_onesecond_hold];

                            % disp('potential onset');
                        end
                    end

               case 'full_offset'
                    % for each section of startwalk data (for each onset of locomotion)
                    for row_stopwalk=1:size(stopwalk_periods,1)

                        % see if there's a full segment of postwalk after the offset
                        row_postwalk=find(postwalk_periods(:,1)==stopwalk_periods(row_stopwalk,2) + 1);

                         if isempty(row_postwalk)==0   % if there IS a segment of postwalk

                            % find segments of rest and walk before and
                            % after and concatenate into list of segments
                            rest_onesecond_hold=[(postwalk_periods(row_postwalk,2)+1),postwalk_periods(row_postwalk,2)+full_transition_extra_frames]; 
                            walk_onesecond_hold=[(stopwalk_periods(row_stopwalk,1)-full_transition_extra_frames),stopwalk_periods(row_stopwalk,1)-1]; 

                            rest_onesecond=[rest_onesecond; rest_onesecond_hold];
                            walk_onesecond=[walk_onesecond; walk_onesecond_hold];

                            % disp('potential offset');
                         end 
                    end 
           end
           % Make sure the rest_onesecond and walk_onesecond don't fall
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

           % Remove bad rows
           if isempty(rows_todelete)==0
              rest_onesecond(rows_todelete,:)=[];
              walk_onesecond(rows_todelete,:)=[];
              % disp('violation');
           end

           % Make sure the rest_onesecond and walk_onesecond always fall in
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
                    % disp('violation');
               end
           end

           % remove bad rows again
           if isempty(rows_todelete)==0
              rest_onesecond(rows_todelete,:)=[];
              walk_onesecond(rows_todelete,:)=[];
           end

           % Get the full range
           if isempty(rest_onesecond)==1   %only need to check 1, the other should also be empty
              periods_holding=[]; 
           else 
               switch period
                   case 'full_onset'
                       periods_holding = [rest_onesecond(:,1), walk_onesecond(:,2)]; 
                   case 'full_offset'
                       periods_holding = [walk_onesecond(:,1), rest_onesecond(:,2)]; 
               end
           end
           % Rename with period-specific name
            eval([period '_periods=periods_holding;']);
       end 
   end

    %% Some final checks & put into output structure

    % ***Make one big list of periods to cycle through***

    % start with the basic 3-second ones
    periods_large=periods_all; 

     % Then add in the "long" periods, which need to have the period names
     % changed
     for i=1:size(periods_long,1)
         periods_large=[periods_large; [periods_long{i} '_long']]; 
     end

     % if full transitions are included, put those in, too.
     if full_transition_flag==1
         periods_large=[periods_large; periods_full_transition];
     end

     % ***cycle through all instances***
     for periodi=1:size(periods_large,1)
         period=periods_large{periodi};

         % convert variable names to something generic to cycle through
         eval(['periods_correct=' period '_periods;']); 

         % convert time ranges to frames
       %%%%  periods_correct=round(periods_holding.*fps./wheel_Hz); 

         % correct any problems introduced by the rounding   
         if ~isempty(periods_correct) % only if periods aren't empty

             % Don't let the first frame be called "0." The indexing has to 
             % start at 1. This is still a valid intance though, so change the
             % index to "1".
             if periods_correct(1)==0   
                periods_correct(1)=1;
             end

             % Don't keep any instances indexed as negative. Something very bad 
             % probably happened in the calculations, so get rid of the whole
             % period.
             [row1,~]=find(periods_correct<1);

             % Don't keep any instances indexed as greater than the total number
             % of frames there are supposed to be. Something very bad 
             % probably happened in the calculations, so get rid of the whole
             % period.
             [row2,~]=find(periods_correct>frames);

             % remove the bad instances;
             rows_todelete=[row1; row2];
             periods_correct(rows_todelete,:)=[];
         end

         % change generic name back to period name
         parameters.behavior_periods.(period) = periods_correct;
         
     end

     parameters.long_periods.walk = walk_long_periods;
     parameters.long_periods.rest = rest_long_periods; 

end