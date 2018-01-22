function [ucsfDir, csvDir, matDir, tablesDir, plotDir, csvPaths, matPath] = mapPaths(varargin)
%MAPPATHS Summary of this function goes here
%   Detailed explanation goes here

if nargin == 1
    timestamp = varargin{1};
else
    timestamp = datestr(now,'yyyy-mm-dd HHMM');
end

ucsfDir   = '\\ROOT\public\figuem\UCSF';
csvDir    = fullfile(ucsfDir, 'csv');
matDir    = fullfile(ucsfDir, 'mat');
tablesDir = fullfile(ucsfDir, 'tables');
plotDir   = fullfile(ucsfDir, 'plots');

csvListing = dir(fullfile(csvDir,'*.csv'));
csvPaths   = fullfile(csvDir,{csvListing.name}');

matName    = [timestamp,'.mat'];
matListing = dir(fullfile(matDir, '*.mat'));
if isempty(matListing)
    matPath = fullfile(matDir, matName);
else
    [~,idxMax] = max(matListing.datenum);
    matPath = fullfile(matDir, matListing(idxMax).name);
end


end

