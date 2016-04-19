function [chans, values, times, uints] = MCCWaveformsFromUpdates( ...
    mcc, updates, baseElementCache)

chans = [];
values = [];
times = [];
uints = [];
nHelpers = numel(mcc.helperIDs);

% HID timestamps are not meaningful per se, but they are monotonic with
% MCC report numbers, which are meaningful.
%   Can I think of a good way to sort online?
%   Why can I only see the first byte of my report number?
allUpdates = cat(1, updates{:});
timestamps = unique(allUpdates(:,3));
nTimestamps = numel(timestamps);

runningCache = baseElementCache;
for ii = 1:nTimestamps
    isThisTimestamp = allUpdates(:,3) == timestamps(ii);
    
    cacheCols = allUpdates(isThisTimestamp,1);
    cacheRows = allUpdates(isThisTimestamp,4);
    cacheIndexes = cacheRows + (cacheCols-1)*nHelpers;
    runningCache(cacheIndexes) = allUpdates(isThisTimestamp,2);
    
    % fudge the report number
    numberLSB = runningCache(cacheRows(1), mcc.countCookie);
    numberFixed = numberLSB + 256*floor((ii-1)/256);
    runningCache(cacheRows(1), mcc.countCookie) = numberFixed;
    
    [c, v, t, u] = MCCChannelsFromElements( ...
        mcc, runningCache(cacheRows(1),:));
    chans = cat(2, chans, c);
    values = cat(2, values, v);
    times = cat(2, times, t);
    uints = cat(2, uints, u);
end

nData = numel(chans);
if isfinite(mcc.nSamples) && nData > mcc.nSamples
    limit = 1:mcc.nSamples;
    chans = chans(limit);
    values = values(limit);
    times = times(limit);
    uints = uints(limit);
end