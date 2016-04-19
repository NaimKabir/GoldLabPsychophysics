function f = mexHIDPlotter(deviceID)
% Open a figure to display live data for HID, with opened with mexHID.
% @details
% mexHIDPlotter() is used by mexHIDScout() in order to display and check on
% HID devices that are attached to the computer.

% info about device and its elements
deviceProps = mexHID('getDeviceProperties', deviceID);
allElements = mexHID('summarizeElements', deviceID);
title = sprintf('%s %s', deviceProps.Manufacturer, deviceProps.Product);
f = figure( ...
    'NumberTitle', 'off', ...
    'Name', title, ...
    'ToolBar', 'none', ...
    'MenuBar', 'none');

% info about element types, with readable names
types.misc = mexHIDUsage.numberForElementTypeName('Input_Misc');
types.button = mexHIDUsage.numberForElementTypeName('Input_Button');
types.axis = mexHIDUsage.numberForElementTypeName('Input_Axis');
types.scancode = mexHIDUsage.numberForElementTypeName('Input_ScanCodes');
types.output = mexHIDUsage.numberForElementTypeName('Output');
types.feature = mexHIDUsage.numberForElementTypeName('Feature');
%types.collection = mexHIDUsage.numberForElementTypeName('Collection');

% make input ranges easy to view in [0,1]
rangeSet.CalibrationMin = 0;
rangeSet.CalibrationMax = 1;
mexHID('setElementProperties', deviceID, [allElements.ElementCookie], rangeSet);
allElements = mexHID('summarizeElements', deviceID);
allCookies = [allElements.ElementCookie];

% look for elements of each type, prepare to plot them in groups
t = fieldnames(types);
group = struct;
nGroups = 0;
for ii = 1:length(t)
    groupSelector = [allElements.Type] == types.(t{ii});
    if any(groupSelector)
        nGroups = nGroups + 1;
        group(nGroups).type = t{ii};
        group(nGroups).cookies = sort([allElements(groupSelector).ElementCookie]);
        group(nGroups).min = min([allElements(groupSelector).CalibrationMin]);
        group(nGroups).max = max([allElements(groupSelector).CalibrationMax]);
    end
end

% subplot for each group of elements
lineLookup = zeros(1, max(allCookies));
for ii = 1:nGroups
    group(ii).ax = subplot(nGroups, 1, ii, ...
        'Parent', f, ...
        'YLim', [-1, 1]+[group(ii).min, group(ii).max], ...
        'YTick', unique([group(ii).min, group(ii).max]), ...
        'XTick', group(ii).cookies);
    ylabel(group(ii).ax, group(ii).type);
    
    % separate line object for each element
    %   indexed by cookie
    for cc = group(ii).cookies
        group(ii).line(cc) = line(cc, 0, ...
            'Marker', '.', ...
            'LineStyle', 'none', ...
            'Parent', group(ii).ax);
        lineLookup(cc) = group(ii).line(cc);
    end
    
    cookieLim = get(group(ii).ax, 'XLim');
    set(group(ii).ax, 'XLimMode', 'manual', 'XLim', cookieLim);
end
xlabel(group(end).ax, 'cookie');

% setup a queue to hold values changes from device elements
%   give "context" hints to the queue callback to update plots
%       lookup table of line handle by cookie
%       lookup table of line xdata index by cookie
%   the plots should update during each mexHID('check')
plotInfo.deviceID = deviceID;
plotInfo.allCookies = allCookies;
plotInfo.lineLookup = lineLookup;
queueCallback = {@plotQueueData, plotInfo};
queueDepth = 100;
queueStatus = mexHID('openQueue', ...
    deviceID, allCookies, queueCallback, queueDepth);
queueStatus = mexHID('startQueue', deviceID);

% Read recently queued data and update the plot.
function plotQueueData(plotInfo, data)
cookies = data(:,1);
lines = plotInfo.lineLookup(cookies);
values = data(:,2);
set(lines, {'YData'}, num2cell(values));
