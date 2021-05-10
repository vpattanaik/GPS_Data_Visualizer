%% Designed by Vishwajeet Pattanaik (https://github.com/vpattanaik)
% The following code allows user to visualize NMEA 0183 data
% (https://www.trimble.com/OEM_ReceiverHelp/V4.44/en/NMEA-0183messages_MessageOverview.html).
% Users are required to enter the time for which they would like to visualize
% tracked satellites. The results are plotted on SKYPLOT. 

%% Clears session
close all
clear
clc
format long g
%% Loads GGA data from input file

fileName = 'sampleData\270321_1647-1749_6850_waason.txt';

ReadID = fopen(fileName,'r'); % Opens file for reading
WAA = fopen('GPGGA_holder.txt','w'); % Creates a new file for writing
line_number = 0;
while feof(ReadID) == 0 % Reads the file till the end
    line = fgets(ReadID); % Read line from the file
    matched_GGA = strfind(line, '$GPGGA'); % Finds string '$GPGGA' within the line
    if ~isempty (matched_GGA)
        fprintf(WAA, '%s', line); % If the line is found, its pasted into the file
    end
    line_number = line_number + 1; % Moves to next line
end

fclose('all'); % Closes all open files

% Reads data (in predefined format) from text file and saves it into variables
format long g

[GGA_UTC, GGA_Lat, GGA_Long, GGA_Q, GGA_NumSat, GGA_HDOP, GGA_H_geoid, GGA_Sep, GGA_end] =...
    textread('GPGGA_holder.txt', '$GPGGA,%d,%f,N,%f,E,%d,%d,%f,%f,M,%f,M,%s');

%% Plotting GSV Data and Values

usrUTC = 1; % Initializes user input

% IF YOU WOULD LIKE TO ENTER DATA FOR EACH SECOND
% REPLACE THE 100 with 1 IN THE NEXT LINE
dS = 100;

GGA_UTC_short = floor(GGA_UTC/dS); % Reduces time variable to hhmm
drMin = floor(GGA_UTC(1)/dS); % Finds min UTC value 
drMax = floor(GGA_UTC(end)/dS); % Finds max UTC value

while usrUTC ~= 0  % Runs until user enters ZERO
    fprintf('Data Range: %d - %d | Enter 0 to EXIT!\n', drMin, drMax); % Prints UTC data range
    prompt = 'Enter the time (hhmm) of data capture: '; % Asks user to enter specific UTC
    usrUTC = input(prompt);
    
    idX = find(GGA_UTC_short == usrUTC); % Finds indexes of GAA data fir given UTC
    
    if usrUTC ~= 0 % Checks if user entered NOT ZERO
        if isempty(idX)
            % If user entered incorrect UTC, asks for input again
            disp(['Incorrect time... try again!', newline]);
        else
            
            % Find GSV data points for given time
            fprintf('\nNumber of SVs in use: %d\n', unique(GGA_NumSat(idX))); % Prints SV count
            disp('HDOPs: ');
            fprintf('%f ', unique(GGA_HDOP(idX))); % Prints HDOPs
            disp(newline);
            
            % Creates text with UTC to search in input data
            txtLineStart = strcat('$GPGGA,', int2str(usrUTC));
            txtLineEnd = strcat('$GPGGA,', int2str(usrUTC + 1));

            % Extracts all lines into string array
            inputTextData = regexp(fileread(fileName), '\n', 'split');

            % Finds line numbers range in GGA for given UTC
            lineNumTxtStart = find(contains(inputTextData, txtLineStart));
            lineNumTxtEnd = find(contains(inputTextData, txtLineEnd));
            
            i = 0;
            while isempty(lineNumTxtEnd)
                if usrUTC == drMax
                    lineNumTxtEnd = length(inputTextData);
                else
                    i = i + 1;
                    txtLineEnd = strcat('$GPGGA,', int2str(usrUTC + 1 + i));
                    lineNumTxtEnd = find(contains(inputTextData, txtLineEnd));
                end
            end

            % Adjusts line numbers
            lineStart = lineNumTxtStart(1);
            lineEnd = lineNumTxtEnd(1) - 1;

            % Extracts text data from input
            selInputTextData = inputTextData(lineStart : lineEnd);
            
            % Finds indexes with GSV data
            idxGPGSV = find(contains(selInputTextData, '$GPGSV'));
            
            % Stores satellite name, elevation and Azimuth data
            satData = zeros(1, 3);
            sC = 0; % Stores satellite data point count
            
            % Find GSV data points for given time      
            for i = 1:length(idxGPGSV)
                
                GSV_data = ...
                    textscan(string(selInputTextData(idxGPGSV(i))), ...
                     '$GPGSV %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %s', ...
                     'Delimiter', ',');
                              
                % Checks satellite count in each GSV line
                if isempty(GSV_data{8})
                    sDperLine = 1;
                elseif isempty(GSV_data{12})
                    sDperLine = 2;
                elseif isempty(GSV_data{16})
                    sDperLine = 3;
                else
                    sDperLine = 4;
                end
                              
                for j = 1:sDperLine
                    sC = sC + 1;
                    satData(sC, 1) = GSV_data{4 * j};
                    satData(sC, 2) = GSV_data{(4 * j) + 1};
                    satData(sC, 3) = GSV_data{(4 * j) + 2};
                end
            end
            
            % Select unique satData by row
            satData = unique(satData, 'rows');
            satData( satData(:, 1) == 0, : ) = [];
            
            % Displays satData
            disp('satData  --> SatID  Elev  Azth');
            satData

            % Classifies GPA and WAAS satellites
            isWAAS = (satData(:, 1) > 32); 
            constellationGroup = categorical(isWAAS, [false, true], {'GPS', 'WAAS'}); 

            % Plot satellite positions
            figure
            skyplot(satData(:, 3), satData(:, 2), satData(:, 1), ...
                'GroupData',constellationGroup, ...
                'LabelFontSize', 10); % Requires MATLAB2021a and the "Navigation Toolbox"
            legend('GPS', 'WAAS')
            legend('Location', 'northeastoutside')

            % Alternatively, if using an older version of MATLAB (2020b or older)
            % Comment LINES 140 - 144, and uncomment LINES 152 - 154

%             polarplot(satData(:, 2), rad2deg(satData(:, 1)), 'o', ...
%                 'MarkerSize', 10, 'MarkerFaceColor', 'r');
        end
    else % If user entered ZERO exits program
        disp('Good bye!');
    end
end
