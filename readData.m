function T = readData(matPath,csvPaths)
%READDATA Summary of this function goes here
%   Detailed explanation goes here

% Check for matlab file
if exist(matPath, 'file') == 2 % Matlab file exists
    % Load data from mat file
    temp = load(matPath);
    T = temp.T;
else % Matlab file does not exist
    % Read data from CSV files and save to mat file
    T = cellfun(@(C)readtable(C,'DatetimeType','text'), csvPaths, 'UniformOutput', false);
    save(matPath, 'T');
end


end

