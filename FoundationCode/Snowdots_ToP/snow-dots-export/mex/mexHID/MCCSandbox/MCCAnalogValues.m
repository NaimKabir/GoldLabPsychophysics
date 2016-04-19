%function MCC1208FSAnalogValues
% Decode analog samples from the 1208FS device.
%   Using mexHID and queued HID element value changes, as opposed to
%   reading full, raw HID reports into Matlab.

clear
clear mex
clc

% Open the 1208FS device and get info struct
mcc = MCCOpen;
if isempty(mcc.primaryID)
    return
end

%% Configure
%   use channels and gains, and get a baseline data cache
%   the cache will get updated with queued value changes, below
mcc.chans = 8:11;
mcc.nChans = numel(mcc.chans);
gain = 1;
mcc.gains = gain*ones(size(mcc.chans));
mcc.frequency = 2000;
mcc.nSamples = 1000;
mcc.nScans = ceil(mcc.nSamples / mcc.nChans);

[baseElementCache, mcc] = MCCPrepareScan(mcc);

% get "start" and "stop" reports
aScan = MCCFormatReport(mcc, 'AInScan', ...
    mcc.chans, mcc.frequency, mcc.nScans);
mcc.scanInfo = aScan.other;
aStop = MCCFormatReport(mcc, 'AInStop');

%% Input Queues
%   make a queue for each input element on each helper device
mcc.queueDepth = 1000;
dataMap = containers.Map(0,0, 'uniformValues', false);
dataMap.remove(dataMap.keys);
context.dataMap = dataMap;
for ii = 1:length(mcc.helperIDs)
    context.cacheRow = ii;
    context.deviceID = mcc.helperIDs(ii);
    callback = {@MCCRecordData, context};
    mexHID('openQueue', ...
        mcc.helperIDs(ii), mcc.allInputCookies, callback, mcc.queueDepth);
end


%% Plot live data
%   the cached/updated value of each input element
%   the latest value of each configured channel
f = figure(1);
clf(f);
ax = subplot(3,1,1, ...
    'XLim', mcc.allInputCookies([1 end]) + [-1 1], ...
    'XTick', mcc.allInputCookies, ...
    'YLim', [0 255]);
for ii = 1:mcc.nHelpers
    col = dec2bin(ii,3)=='1';
    cacheLine(ii) = line(mcc.allInputCookies, zeros(size(mcc.allInputCookies)), ...
        'Parent', ax, ...
        'LineStyle', 'none', ...
        'Marker', '.', ...
        'Color', col);
end

ax = subplot(3,1,2, ...
    'XLim', mcc.chans([1 end]) + [-1 1], ...
    'XTick', mcc.chans, ...
    'YLim', [min(mcc.channelConfig.voltMin), ...
    max(mcc.channelConfig.voltMax)]);
chanelLine = line(mcc.chans, zeros(size(mcc.chans)), ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '+', ...
    'MarkerSize', 10, ...
    'Color', 'k');

%% Get live data
for ii = 1:length(mcc.helperIDs)
    mexHID('startQueue', mcc.helperIDs(ii));
end

liveElementCache = baseElementCache;
liveChannels = zeros(1,1+max(mcc.chans));

[status, startScanTiming] = mexHID('writeDeviceReport', ...
    mcc.primaryID, aScan.ID, aScan.type, aScan.bytes);
mcc.zeroTime = startScanTiming(1,5);

set(f, 'CurrentCharacter', 'w');
while ishandle(f) && ~strcmp('q', get(f, 'CurrentCharacter'))
    
    mexHID('check');
    
    updateTimes = dataMap.keys;
    if ~isempty(updateTimes)
        whichUpdate = max([updateTimes{:}]);
        
        update = dataMap(whichUpdate);
        cacheCols = update(:,1);
        cacheRows = update(:,4);
        cacheIndexes = cacheRows + (cacheCols-1)*mcc.nHelpers;
        
        liveElementCache(cacheIndexes) = update(:,2);
        [chans, values, times] = MCCChannelsFromElements( ...
            mcc, liveElementCache(cacheRows(1),:));
        liveChannels(1+chans(1:mcc.nChans)) = values(1:mcc.nChans);
        
        if ishandle(f)
            for ii = 1:mcc.nHelpers
                set(cacheLine(ii), ...
                    'YData', liveElementCache(ii,mcc.allInputCookies));
            end
            set(chanelLine, 'YData', liveChannels(1+mcc.chans));
            drawnow;
        end
    end
end

[status, stopScanTiming] = mexHID('writeDeviceReport', ...
    mcc.primaryID, aStop.ID, aStop.type, aStop.bytes);

for ii = 1:length(mcc.helperIDs)
    mexHID('stopQueue', mcc.helperIDs(ii));
    mexHID('closeQueue', mcc.helperIDs(ii));
end

%%
mexHID('terminate');

%% What did I get?
if ishandle(f)
    updates = dataMap.values;
    [chans, values, times, uints] = MCCWaveformsFromUpdates( ...
        mcc, updates, baseElementCache);
    
    ax = subplot(3,1,3, ...
        'XLim', [0, max(times) - mcc.zeroTime], ...
        'YLim', [min(mcc.channelConfig.voltMin), ...
        max(mcc.channelConfig.voltMax)]);
    
    for ii = 1:mcc.nChans
        isThisChan = chans == mcc.chans(ii);
        if any(isThisChan)
            col = dec2bin(ii,3)=='0';
            dataLine(ii) = line(times(isThisChan) - mcc.zeroTime, values(isThisChan), ...
                'Parent', ax, ...
                'LineStyle', 'none', ...
                'Marker', '.', ...
                'Color', col);
            chanName{ii} = sprintf('%d', mcc.chans(ii));
            
            line(chans(isThisChan), values(isThisChan), ...
                'Parent', subplot(3,1,2), ...
                'LineStyle', 'none', ...
                'Marker', '.', ...
                'Color', col);
        end
    end
    legend(ax, chanName{:}, 'Location', 'NorthWest');
    
    figure(f)
end
dec2bin(uints, 16);