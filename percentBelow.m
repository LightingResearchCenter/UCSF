function percentBelow
%PERCENTBELOW Summary of this function goes here
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

xlsxName = [timestamp,' samples under 10lux.xlsx'];
xlsxPath = fullfile(tablesDir, xlsxName);


%% Read data from disk
T = readData(matPath,csvPaths);

%% Iterate through data
H = table; % Create a structure to hold results
for iT = numel(T):-1:1
    % Copy ID
    H.ID{iT,1} = T{iT}.ID{1};
    H.Site{iT,1} = T{iT}.SITE{1};
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
    Hours = hour(Time);
    
    lightBelow10 = numel(Light(Hours >= 7 & Hours < 19 & Light <= 10));
    lightTotal = numel(Light(Hours >= 7 & Hours < 19));
    lightPercentBelow = lightBelow10/lightTotal;
    
    % Copy results to table
    H.Percent_Samples_Under_10lux_Between_7am_7pm(iT,1) = lightPercentBelow;
    
end

    % Save results to Excel file and open
    writetable(H,xlsxPath);

end

