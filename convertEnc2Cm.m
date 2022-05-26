function [converted] = convertEnc2Cm(data,velocityFlag, radius, stack_number)
    % Reads in .log file (give path as string), separates file into trials
    % then returns a structure with the fields, trialNum, position, velocity
    % and time, where position has been converted to cm.
    % Conversion formula is distance = radius*angular displacement,
    % 24000 units on the rotary encoder is equal to 360 degrees,
    % distance from center to center of mouse is 8.5cm
    % Date format YYYY-MM-DD
    % Time format HHMMSS and indicates when the session started, is this
    % useful? Probably not
    % Example use 
    % data = convertEnc2Cm('C:\ExamplePath\fileName.log');
    % Example of retrieving the 100th to 1000th positions from the 3rd trial
    % example = data(3).position(100:1000);
    %Example of use with velocity calculation
    % example = convertEnc2Cm('C:\ExamplePath\fileName.log','True');
    
    %tic
    if nargin == 1
        r = 8.5;
        velFlag = 'False';
    elseif nargin == 2
        velFlag = velocityFlag;
        r = 8.5;
    elseif nargin >= 3
        velFlag = velocityFlag;
        r = radius;
    end
    
    %data = importlog(logFile);
    % n = max(data(:,1));
    converted = struct;
%     string = char(logFile);
%     date = string(end-20:end-11);
%     time = string(end-9:end-4);

    [x,~] = find(data(:,1)== stack_number);
    
    if isempty(x) == 0
%         converted(i).date = date;
%         converted(i).startTime = time;
        trial = data(x,3);
        positions = ((trial/24000))*2*pi*r;
        converted.trialNum = stack_number;
        converted.positions = positions;
        converted.trialTime = data(x,2);
        
        if strcmp(velFlag,'True')
            
            dt = diff(converted.trialTime);
            dx = diff(converted.positions);          
            converted.velocities = dx./dt;
            converted.totalDist = sum(dx);
            
        end

    else 
        converted = [];
    end
end
% toc

