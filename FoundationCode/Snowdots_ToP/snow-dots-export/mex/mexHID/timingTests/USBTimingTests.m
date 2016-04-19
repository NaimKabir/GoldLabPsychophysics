function USBTimingTests(n)
% I want to characterize a few things from USB and mexHID:
%   - How tightly can I squeeze input and output setting between frame
%   numbers?  What are the latencies seen from mexHID and Matlab?  I think
%   it's OK that there are latencies, but how tightly can I sqeeze them
%   down to get a sense of their importance?
%       - read from an input
%       - read from an output
%       - write to an output
%
%   - Can I get a sense of when a value actually changes?  For all
%   combinations of writing and reading, how close are the frame numbers?
%       - write an output value and read it immediately
%       - add an output to a queue(?), write a value to it, and see when it
%       changed
%       - with the 1208FS, wire an output to an input.  Add the input to a
%       queue and write to the output.  When does the input value change?
%
%   - For a continuously varying value, like a moving mouse, do I see a
%   timestamp corresponding to every possible USB frame?  Can value change
%   timestamps fall between polling calls?
%       - add a mouse axis to a queue, give instructions to move it, and
%       record for a while.
%       - what if busy writing to an output element?  Do inputs continue
%       to get updated and do timestamps fall between write transaction
%       times?
%
% And a lingering issue, which is quite important:
%
% There is likely to be some uncontrollble jitter latency in when Matlab or
% mexHID is allowed to actually get data out of the USB bus or when it is
% actually allowed to read data that came in.  We have to live with this.
% It should be OK, as long as we have unjittered timestamps.  The OS X HID
% implementation does give us timestamps for value changes.  The question
% is, when do the timestamps occur?
%   - The best scenario would be that OS X assigns them during the most
%   current USB frame.  In that case it's fine that we have access timing
%   jitter because we have reliable "when did that happen" timestamps.
%   - But even if that's true, there's an off-bu one question: since input
%   interrupts have to be polled from the host side, and since polling is
%   supposed to happen once per frame, each timestamp would be expected to
%   be have a frame old, on average. Does OS X make any adjustment for
%   this? Should mexHID make any adjustment?
%   - And what if the best scenario isn't true?  It's possible that the
%   timestamp could be taken at some later time, even after a value is
%   available on the host side.  We would not know the bias or variance of
%   the timestampping!


%% Get a device and elements to use.
clear
clear mexHID
clear classes
clc

% test iterations, reused by all tests below
if nargin < 1
    n = 100;
end

% Set up criteria for locating the mouse and its x-axis
desktopPage = mexHIDUsage.numberForPageName('GenericDesktop');
mouseUsage = mexHIDUsage.numberForUsageNameOnPage('Mouse', desktopPage);
xAxisUsage = mexHIDUsage.numberForUsageNameOnPage('X', desktopPage);
mouseMatching.PrimaryUsagePage = desktopPage;
mouseMatching.PrimaryUsage = mouseUsage;
xAxisMatching.UsagePage = desktopPage;
xAxisMatching.Usage = xAxisUsage;

% may need to narrow the search for a mouse
%   try mexHIDScout to see connected HID devices.
% mouseMatching.VendorID = 6127;

% Access the mouse and its x-axis
mexHID('initialize');
deviceID = mexHID('openMatchingDevice', mouseMatching);
xAxisCookie = mexHID('findMatchingElements', deviceID, xAxisMatching);
deviceInfo = mexHID('getDeviceProperties', deviceID);
disp(sprintf('%s by %s', deviceInfo.Product, deviceInfo.Manufacturer))

elementsInfo = mexHID('summarizeElements', deviceID);
inputs = elementsInfo([elementsInfo.Type] == 1 | [elementsInfo.Type] == 2);
outputs = elementsInfo([elementsInfo.Type] == 129);
features = elementsInfo([elementsInfo.Type] == 513);
xAxis = elementsInfo([elementsInfo.ElementCookie] == xAxisCookie);

%% Hammer on the inputs and outputs for reading and writing
% record the latencies seen by mexHID, and the USB frame numbers
% plot latencies
% plot timestamps as a function of frame number to look at jitter

% input values are cached on the host side, so reading from them should be
% like a no-op test of overhead.
inputReads = zeros(n,5);
inputCookie = xAxis.ElementCookie;
for ii = 1:n
    [data, inputReads(ii,:)] = ...
        mexHID('readElementValues', deviceID, inputCookie);
end

% ouputs values may not be cached on the host side(?), so reading from them
% should require a bus transaction and encounter latency
outputReads = zeros(n,5);
outputWrites = zeros(n,5);
if ~isempty(outputs)
    outputReads = zeros(n,5);
    outputCookie = outputs(1).ElementCookie;
    for ii = 1:n
        [data, outputReads(ii,:)] = ...
            mexHID('readElementValues', deviceID, outputCookie);
    end
    
    % ouputs writing should require a bus transaction and encounter latency
    
    writeValue = data(1,2);
    for ii = 1:n
        [status, outputWrites(ii,:)] = ...
            mexHID('writeElementValues', deviceID, outputCookie, writeValue);
    end
end

%%
f = figure(1);
clf(f)
ax = subplot(2,2,1);
title(ax, 'How long do different operations take?')
ylabel(ax, 'delta-frame number')
line(1:n, inputReads(:,4)-inputReads(:,2), ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '*', ...
    'color', 'g')
line(1:n, outputReads(:,4)-outputReads(:,2), ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '.', ...
    'color', 'b')
line(1:n, outputWrites(:,4)-outputWrites(:,2), ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '+', ...
    'color', 'r')

ax = subplot(2,2,3);
ylabel(ax, 'delta-timestamp')
xlabel(ax, 'test iteration')
line(1:n, inputReads(:,5)-inputReads(:,3), ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '*', ...
    'color', 'g')
line(1:n, outputReads(:,5)-outputReads(:,3), ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '.', ...
    'color', 'b')
line(1:n, outputWrites(:,5)-outputWrites(:,3), ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '+', ...
    'color', 'r')
legend(ax, 'read input', 'read output', 'write output', ...
    'Location', 'southwest');

ax = subplot(2,2,2);
title(ax, 'How does each timestamp fall on a frame number?')
ylabel(ax, 'timestamp')
grand = cat(1, inputReads, outputReads, outputWrites);
frameNumbers = grand(:,[2,4]);
timestamps = grand(:,[3,5]);
line(frameNumbers(1:n,:), timestamps(1:n,:), ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '*', ...
    'color', 'g')
line(frameNumbers([1:n]+n,:), timestamps([1:n]+n,:), ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '.', ...
    'color', 'b')
line(frameNumbers([1:n]+2*n,:), timestamps([1:n]+2*n,:), ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '+', ...
    'color', 'r')

ax = subplot(2,2,4);
ylabel(ax, 'mean-subtracted timestamp')
xlabel(ax, 'frame number')
uniqueFrames = unique(frameNumbers);
m = length(uniqueFrames);
zeroedTimestamps = timestamps;
for ii = 1:m
    thisFrame = frameNumbers == uniqueFrames(ii);
    thisMean = mean(timestamps(thisFrame));
    zeroedTimestamps(thisFrame) = ...
        zeroedTimestamps(thisFrame) - thisMean;
end
line(frameNumbers(1:n,:), zeroedTimestamps(1:n,:), ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '*', ...
    'color', 'g')
line(frameNumbers([1:n]+n,:), zeroedTimestamps([1:n]+n,:), ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '.', ...
    'color', 'b')
line(frameNumbers([1:n]+2*n,:), zeroedTimestamps([1:n]+2*n,:), ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '+', ...
    'color', 'r')

%% Try to read and write quickly, and compare frame numbers
outputWrites = zeros(n,5);
inputReads = zeros(n,5);
inputData = zeros(n,3);
if ~isempty(outputs)
    outputCookie = outputs(1).ElementCookie;
    inputCookie = outputCookie;
    
    writeValue = 0;
    for ii = 1:n
        [status, outputWrites(ii,:)] = ...
            mexHID('writeElementValues', deviceID, outputCookie, writeValue);
        [inputData(ii,:), inputReads(ii,:)] = ...
            mexHID('readElementValues', deviceID, inputCookie);
    end
end

%%
f = figure(2);
clf(f)
ax = axes;
title(ax, 'How do write, value change, and read timestamps align?')
ylabel(ax, 'start-subtracted timestamp')
xlabel(ax, 'test iteration')
line(1:n, inputData(:,3), ... - outputWrites(:,3), ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '*', ...
    'color', 'g')
line(1:n, outputWrites(:,3) - outputWrites(:,3), ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '.', ...
    'color', 'y')
line(1:n, outputWrites(:,5) - outputWrites(:,3), ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '.', ...
    'color', 'b')
line(1:n, inputReads(:,3) - outputWrites(:,3), ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '+', ...
    'color', 'r')
line(1:n, inputReads(:,5) - outputWrites(:,3), ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '+', ...
    'color', 'c')
legend(ax, 'value timestamp', ...
    'pre-write', 'post-write', 'pre-read', 'post-read', ...
    'Location', 'southwest');


%% Move the mouse and try to observe every frame
inputCookie = xAxisCookie;
queueMap = containers.Map(0,0, 'uniformValues', false);
queueMap.remove(queueMap.keys);
callback = {@recordMovement, queueMap};
mexHID('openQueue', deviceID, inputCookie, callback, n)

outputWrites = zeros(n,5);
writeValue = 0;
if ~isempty(outputs)
    outputCookie = outputs(1).ElementCookie;
    
    disp('Please move the mouse left or right, continuously...')
    mexHID('startQueue', deviceID);
    while queueMap.length < 1
        mexHID('check');
    end
    
    disp('...keep going...')
    drawnow;
    queueMap.remove(queueMap.keys);
    for ii = 1:n
        [status, outputWrites(ii,:)] = ...
            mexHID('writeElementValues', deviceID, outputCookie, writeValue);
        mexHID('check');
        pause(.002);
    end
    mexHID('stopQueue', deviceID);
    disp('...thanks.')
end

% subtract queued data to each previous write call
dataPile = queueMap.values;
queuedData = cat(1, dataPile{:});
m = size(queuedData, 1);
queuedAlignment = [];
queuedSubtracted = [];
queuedDiff = [];
for ii = 1:m
    queuedAfter = outputWrites(:,3) <= queuedData(ii,3);
    if any(queuedAfter)
        alignment = find(queuedAfter, 1, 'last');
        queuedAlignment(end+1) = alignment;
        queuedSubtracted(end+1) = ...
            queuedData(ii,3) - outputWrites(alignment,3);
        if ii > 1
            queuedDiff(end+1) = queuedData(ii,3) - queuedData(ii-1,3);
        end
    end
end

%%
f = figure(3);
clf(f);
ax = subplot(2,1,1);
if length(queuedAlignment) > 1
    set(ax, 'XTick', unique(queuedAlignment), 'XGrid', 'on');
end
title(ax, 'When does a continuous signal get updated?')
ylabel(ax, 'start-subtracted timestamp')
line(1:n, outputWrites(:,3) - outputWrites(:,3), ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '+', ...
    'color', 'g');
line(1:n, outputWrites(:,5) - outputWrites(:,3), ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '+', ...
    'color', 'r');
line(queuedAlignment, queuedSubtracted, ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '*', ...
    'color', 'b');

legend(ax, 'pre-write', 'post-write', 'value change', ...
    'Location', 'northeast');

ax = subplot(2,1,2);
if length(queuedAlignment) > 1
    set(ax, 'XTick', unique(queuedAlignment), 'XGrid', 'on');
end
ylabel(ax, 'interval');
line(queuedAlignment, queuedDiff, ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '*', ...
    'color', 'b');
xlabel(ax, 'test iteration')

mexHID('terminate');

function recordMovement(queueMap, newData)
queueMap(queueMap.length+1) = newData;