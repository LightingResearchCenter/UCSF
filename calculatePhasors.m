function calculatePhasors
%CALCULATEPHASORS Summary of this function goes here
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

xlsxName = [timestamp,' phasor.xlsx'];
xlsxPath = fullfile(tablesDir, xlsxName);

figName = [timestamp,' phasor.pdf'];
figPath = fullfile(plotDir, figName);

%% Read data from disk
T = readData(matPath,csvPaths);

%% Iterate through data
P = table; % Table to hold results
obj = d12pack.MobileData; % Dummy object that contains phasor method
for iT = numel(T):-1:1
    % Copy ID
    P.ID{iT,1} = T{iT}.ID{1};
    P.Site{iT,1} = T{iT}.SITE{1};
    % Convert text to datetime
    Time = datetime(T{iT}.ARDATETM, 'InputFormat', 'ddMMMyy:HH:mm:ss');
    % Calculate epoch
    Epoch = mode(diff(Time));
    % Extract light
    Light = T{iT}.ARWTLGHT;
    % Extract activity
    Activity = T{iT}.ARACTIV;
    % Remove any readings that are NaN
    idxNaN = isnan(Light) | isnan(Activity);
    Time(idxNaN) = [];
    Light(idxNaN) = [];
    Activity(idxNaN) = [];
    % Replace values less than 1 with 1
    Light(Light<1) = 1;
    % take the natural log of light
    lnLight = log(Light);
    % Create observation mask
    Observation = true(size(Time));
    % Calculate phasor
    Phasor = obj.computePhasor(Time,lnLight,Epoch,Activity,Observation);
    % Copy phasor results to table
    P.PhasorMagnitude(iT,1)   = Phasor.Magnitude;
    P.PhasorAngle_Hours(iT,1) = Phasor.Angle.hours;
    P.Vector(iT,1)            = Phasor.Vector;
end

%% Save results to Excel file
writetable(P,xlsxPath);

%% Plot results
fig = figure;
fig.Units = 'pixels';
fig.Position = [250 250 600 500];
ax = initPhasorAxes(fig);
% Iterate through each site
sites = unique(P.Site);
nSite = numel(sites);
legendEntries = nan(nSite+1,1);
for iSite = 1:nSite
    thisSite = sites{iSite};
    idxSite = strcmp(P.Site,thisSite);
    theseVectors = P.Vector(idxSite);
%     thisMeanVector = mean(theseVectors);
    thisColor = ax.ColorOrder(iSite,:);
    hPoints = plotPhasorPoints(ax, theseVectors, thisColor);
%     hArrow = plotPhasorArrow(ax, thisMeanVector, thisColor);
    
    % Set display name for use in legend
    hPoints.DisplayName = thisSite;
%     hArrow.DisplayName = ['Average ',thisSite];
    legendEntries(iSite,1) = hPoints;
%     legendEntries(iSite,2) = hArrow;
end
hArrow = plotPhasorArrow(ax, mean(P.Vector), 'black');
hArrow.DisplayName = 'Average';
legendEntries(end) = hArrow;
legend(legendEntries,'Location','eastoutside')
saveas(fig,figPath);

end


function ax = initPhasorAxes(fig)
rMin = 0;
rMax = 0.6;
rTicks = 6;
rInc = (rMax - rMin)/rTicks;

% Create Axes
ax = axes(fig,'Visible','off');
ax.Units = 'pixels';

% Prevent unwanted resizing of axes.
ax.ActivePositionProperty = 'position';

% Prevent axes from being erased.
ax.NextPlot = 'add';

% Make aspect ratio equal.
ax.DataAspectRatio = [1 1 1];

% Create a handle groups.
hGrid = hggroup;
set(hGrid,'Parent',ax);
hLabels = hggroup;
set(hLabels,'Parent',ax);

% Define a circle.
th = 0:pi/100:2*pi;
xunit = cos(th);
yunit = sin(th);
% Now really force points on x/y axes to lie on them exactly.
inds = 1 : (length(th) - 1) / 4 : length(th);
xunit(inds(2 : 2 : 4)) = zeros(2, 1);
yunit(inds(1 : 2 : 5)) = zeros(3, 1);

% Plot spokes.
th = (1:12)*2*pi/12;
cst = cos(th);
snt = sin(th);
cs = [zeros(size(cst)); cst];
sn = [zeros(size(snt)); snt];
hSpoke = line(rMax*cs,rMax*sn);
for iSpoke = 1:numel(hSpoke)
    hSpoke(iSpoke).HandleVisibility = 'off';
    hSpoke(iSpoke).Parent = hGrid;
    hSpoke(iSpoke).LineStyle = ':';
    hSpoke(iSpoke).Color = [0.5 0.5 0.5];
end

% Annotate spokes in hours
rt = rMax + 0.8*rInc;
pm = char(177);
hours = {' +2  ',' +4  ',' +6  ',' +8  ','+10  ',[pm,'12  '],'-10  ',' -8  ',' -6  ',' -4  ',' -2  ','  0  '};
for iSpoke = length(th):-1:1
    hSpokeLbl(iSpoke,1) = text(rt*cst(iSpoke),rt*snt(iSpoke),hours(iSpoke));
    hSpokeLbl(iSpoke,1) .FontName = 'Arial';
    hSpokeLbl(iSpoke,1).FontUnits = 'pixels';
    hSpokeLbl(iSpoke,1).FontSize = 10;
    hSpokeLbl(iSpoke,1).HorizontalAlignment = 'center';
    hSpokeLbl(iSpoke,1).HandleVisibility = 'off';
    hSpokeLbl(iSpoke,1).Parent = hLabels;
end
top = hSpokeLbl(3).Extent(2)+hSpokeLbl(3).Extent(4);
bottom = hSpokeLbl(9).Extent(2);
left = hSpokeLbl(6).Extent(1);
right = hSpokeLbl(12).Extent(1)+hSpokeLbl(12).Extent(3);
outer = max(abs([top,bottom,left,right]));
ax.YLim = [-outer,outer];
ax.XLim = [-outer,outer];


% Draw radial circles
cos105 = cos(105*pi/180);
sin105 = sin(105*pi/180);

for iTick = (rMin + rInc):rInc:rMax
    hRadial = line(xunit*iTick,yunit*iTick);
    hRadial.Color = [0.5 0.5 0.5];
    hRadial.LineStyle = ':';
    hRadial.HandleVisibility = 'off';
    hRadial.Parent = hGrid;
end
% Make outer circle balck and solid.
hRadial.Color = 'black';
hRadial.LineStyle = '-';
for iTick = (rMin + 2*rInc):2*rInc:rMax
    xText = (iTick)*cos105;
    yText = (iTick)*sin105;
    hTickLbl = text(xText,yText,num2str(iTick));
    hTickLbl.FontName = 'Arial';
    hTickLbl.FontUnits = 'pixels';
    hTickLbl.FontSize = 10;
    hTickLbl.VerticalAlignment = 'bottom';
    hTickLbl.HorizontalAlignment = 'center';
    hTickLbl.HandleVisibility = 'off';
    hTickLbl.Rotation = 15;
    hTickLbl.Parent = hLabels;
end
end % End of initPhasorAxes



function hArrow = plotPhasorArrow(ax, vector, color)

if isempty(vector)
    return
end

scale = 1;

hArrow = hggroup(ax);

% Make line slightly shorter than the vector.
th = angle(vector);
mag = abs(vector);
offset = .05*scale;
[x2,y2] = pol2cart(th,mag-offset);
% Plot the line.
hLine = line(ax,[0,x2],[0,y2]);
set(hLine,'Parent',hArrow);
hLine.LineWidth = 2;
hLine.Color = color;

% Plot the arrowhead.
% Constants that define arrowhead proportions
xC = 0.05;
yC = 0.02;

% Create arrowhead points
xx = [1,(1-xC*scale),(1-xC*scale),1].';
yy = scale.*[0,(yC*scale),(-yC*scale),0].';
arrow = xx + yy.*1i;

% Calculate new vector with same angle but magnitude of 1
th = angle(vector);
[x2,y2] = pol2cart(th,1);
vector2 = x2 + y2*1i;

% Find difference between vectors
dVec = vector2 - vector;

% Calculate arrowhead points in transformed space.
a = arrow * vector2.' - dVec;
xA = real(a);
yA = imag(a);
cA = zeros(size(a));

% Plot and format arrowhead.
hHead = patch(ax,xA,yA,cA);
set(hHead,'EdgeColor','none');
set(hHead,'FaceColor',get(hLine,'Color'));

set(hHead,'Parent',hArrow);
end % End of plotPhasorArrow


function hPoints = plotPhasorPoints(ax, vector, color)

if isempty(vector)
    return
end

th  = angle(vector);
mag = abs(vector);
[x, y] = pol2cart(th, mag);
% Plot the points.
hPoints = plot(ax, x, y, '.');
hPoints.LineWidth = 2;
hPoints.Color = color;

end % End of plotPhasorPoints