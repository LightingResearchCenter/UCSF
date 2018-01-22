function averageHourly
%AVERAGEHOURLY Summary of this function goes here
%   Detailed explanation goes here

close all
clear
clc


timestamp = datestr(now,'yyyy-mm-dd HHMM');

%% Enable dependencies
[githubDir,~,~] = fileparts(pwd);
d12packDir = fullfile(githubDir,'d12pack');
addpath(d12packDir);

%% Map file paths
[ucsfDir, csvDir, matDir, tablesDir, plotDir, csvPaths, matPath] = mapPaths(timestamp);

xlsxName = [timestamp,' hourly.xlsx'];
xlsxPath = fullfile(tablesDir, xlsxName);


%% Read data from disk
T = readData(matPath,csvPaths);

%% Iterate through data
H = struct; % Create a structure to hold results
for iT = numel(T):-1:1
    % Copy ID
    H(iT,1).ID = T{iT}.ID{1};
    H(iT,1).Site = T{iT}.SITE{1};
    % Convert text to datetime
    Time = datetime(T{iT}.ARDATETM, 'InputFormat', 'ddMMMyy:HH:mm:ss');
    % Extract light
    Light = T{iT}.ARWTLGHT;
    % Extract activity
    Activity = T{iT}.ARACTIV;
    % Remove any readings that are NaN
    idxNaN = isnan(Light) | isnan(Activity);
    Time(idxNaN) = [];
    Light(idxNaN) = [];
    Activity(idxNaN) = [];
    % Shift time to hours
    Hours = dateshift(Time,'start','hour');
    unqHours = unique(Hours);
    
    lightMean = arrayfun(@(x)mean(Light(Hours == x)),unqHours);
    activityMean = arrayfun(@(x)mean(Activity(Hours == x)),unqHours);
    
    % Copy results to table
    S = table;
    S.Time = unqHours;
    S.Average_Light = lightMean;
    S.Average_Acticity = activityMean;
    H(iT,1).Table = S;
    
    % Save results to Excel file and open
    writetable(S,xlsxPath,'Sheet',H(iT,1).ID);
end


end

