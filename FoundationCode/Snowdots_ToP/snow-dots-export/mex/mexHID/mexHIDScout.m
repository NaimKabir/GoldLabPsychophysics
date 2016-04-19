function mexHIDScout
% Give a grapical summary and comparison of connected HID devices.
% @details
% mexHIDScout() shows a summary of the proerties for each HID device
% connected to the computer.  It uses the mexHID() mex function to access
% the devices.  Buttons at the top of the figure allow the user to view
% each device and its inputs, live.  Each "open" button simply opens a
% device and invokes the mexHIDPlotter() viewing function for that device.
% Each "exclusive" button attempts to open a device and prevents other
% programs, including the operating system from receiving inputs from the
% device as long as the mexHIDPlotter() is still open.  Exclusive access
% may be most useful for mouse and keyboard devices, which can cause
% confusion when used by multiple programs.

% get info about all devices
%  sort by usage page and usage
mexHID('initialize');
devices = mexHID('summarizeDevices');
usageTotal = 256*[devices.PrimaryUsagePage] + [devices.PrimaryUsage];
[sorted, order] = sort(usageTotal);
devices = devices(order);

% supplement device properties with some usage names
for jj = 1:length(devices)
    devices(jj).PrimaryUsagePageName = mexHIDUsage.nameForPageNumber( ...
        devices(jj).PrimaryUsagePage);
    
    devices(jj).PrimaryUsageName = mexHIDUsage.nameForUsageNumberOnPage( ...
        devices(jj).PrimaryUsage, devices(jj).PrimaryUsagePage);
end

% organize property names and values for display in a table
props = fieldnames(devices);
[props order] = sort(props);
values = squeeze(struct2cell(devices));
values = values(order,:);

% reforman values to be table-friendly
nValues = numel(values);
strValues = cell(size(values));
for ii = 1:nValues
    val = values{ii};
    strVal = evalc('disp(val)');
    start = find(~isspace(strVal), 1, 'first');
    strValues{ii} = strVal(start:end);
end

% present device properties in a table and buttons for viewing each device
figData.devices = devices;
figData.whichDevice = 1;
f = figure( ...
    'NumberTitle', 'off', ...
    'Name', mfilename, ...
    'ToolBar', 'none', ...
    'MenuBar', 'none', ...
    'UserData', figData, ...
    'DeleteFcn', @terminateOnFigureClose);

table = uitable( ...
    'Parent', f, ...
    'Units', 'normalized', ...
    'Position', [0 .1 1 .9], ...
    'ColumnName', 'numbered', ...
    'RowName', props, ...
    'Data', strValues, ...
    'CellSelectionCallback', @chooseDeviceByTableSelect);

openButton = uicontrol( ...
    'Style', 'pushbutton', ...
    'String', 'open selected', ...
    'HorizontalAlignment', 'center', ...
    'Units', 'normalized', ...
    'Position', [0 0 .5 .1], ...
    'Callback', ...
    @(button, event)openMatchingDeviceAndPlotter(button, event, false));

exclusiveButton = uicontrol( ...
    'Style', 'pushbutton', ...
    'String', 'open selected exclusively', ...
    'HorizontalAlignment', 'center', ...
    'Units', 'normalized', ...
    'Position', [.5 0 .5 .1], ...
    'Callback', ...
    @(button, event)openMatchingDeviceAndPlotter(button, event, true));

% User may click to "open" different devices and view their element
% values live.  All viewing figures can update concurrently, as long as we
% keep calling mexHID('check').  Keep calling it while the mexHIDScout
% figure is open.
while ishandle(f)
    mexHID('check');
    drawnow();
    pause(0.05);
end

function chooseDeviceByTableSelect(table, event)
% only for single-selections, choose the table row
if size(event.Indices, 1) == 1
    column = event.Indices(2);
    fig = get(table, 'Parent');
    figData = get(fig, 'UserData');
    figData.whichDevice = column;
    set(fig, 'UserData', figData);
end


function openMatchingDeviceAndPlotter(button, event, isExclusive)
% ask the figure which device to open
fig = get(button, 'Parent');
figData = get(fig, 'UserData');
matching = figData.devices(figData.whichDevice);

% open the device in a plotter figure
deviceID = mexHID('openMatchingDevice', matching, isExclusive);
if deviceID < 0
    disp(sprintf('could not open device(%d)', deviceID));
else
    plotFig = mexHIDPlotter(deviceID);
    set(plotFig, 'DeleteFcn', {@closeDeviceOnPlotterClose, deviceID});
end


function closeDeviceOnPlotterClose(fig, event, deviceID)
mexHID('stopQueue', deviceID);
mexHID('closeQueue', deviceID);
mexHID('closeDevice', deviceID);


function terminateOnFigureClose(fig, event)
mexHID('terminate');