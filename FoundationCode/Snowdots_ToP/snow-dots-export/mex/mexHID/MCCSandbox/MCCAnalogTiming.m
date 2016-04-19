function MCC1208FSAnalogTiming
% Characterize analog timing for the 1208FS device from Measurement
% Computing.
%
% Test 1
% Look at output-input round trip timing
%   - Wire analog outputs A and B to inputs 8 and 9
%   - Wire +5V to input 10
%   - Wire analog ground to 11
%   - Add all the input report elements to a queue
%   - Acquire channels 8:11 continuously at medium-high frequency
%       - write many different values to outputs A and B
%   - Are all the written outputs reflected in the inputs 8 and 9?
%   - Do inputs 10 and 11 hold steady?
%   - Do the reconstructed input sample times agree with the output
%   transaction times?  Which transaction timestamps look the most stable?

% Test 2
% Look at jitter of "coincident" read and write
%   - Look again at the data from Test 1
%   - There are 2x2 ways to line up timestamps: output times may use the
%   pre- or post-write transaction timestamps, and input values may be
%   reconstructed with the pre- or post-scan transaction timestamp.
%   - For each combination, what is the jitteryness (cloud size, variance,
%   whatever) of the supposedly conincident write and read events?
%   - "supposedly coincident" means:
%       - for each output writing, take the earliest input sample that:
%           - is later than the previous ouput writing
%           - has a value between the previous and next values, within some
%           margin for error.

% Test 3
% Look at completeness of sample accounting
%   - For a finite number of samples and several scan frequencies f
%   - Are all the input report numbers consecutive?  How does completeness
%   depend on f?

%% Get the 1208FS and configure it
clear
clear mex
clc

nValues = 50;
nRepeats = 10;
nTotal = nValues * nRepeats;

mcc = MCCOpen;
if isempty(mcc.primaryID)
    return
end

mcc.chans = 8:11;
mcc.nChans = numel(mcc.chans);
mcc.gains = ones(size(mcc.chans));
mcc.frequency = 2500;
mcc.nSamples = inf;
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

%% Test 1
%   Write some outputs while scanning
A = 0;
B = 1;

outputMax = (2^16)-1;
outputMin = 2^14;
valuesA = floor(linspace(outputMin, outputMax, nValues));
valuesB = floor(linspace(outputMax, outputMin, nValues));
outputA = repmat(valuesA, 1, nRepeats);
outputB = repmat(valuesB, 1, nRepeats);

writeATiming = zeros(nTotal,5);
writeBTiming = zeros(nTotal,5);

mexHID('startQueue', mcc.helperIDs);

[status, startScanTiming] = mexHID('writeDeviceReport', ...
    mcc.primaryID, aScan);

for ii = 1:nTotal
    writeA = MCCFormatReport(mcc, 'AOut', A, outputA(ii));
    writeB = MCCFormatReport(mcc, 'AOut', B, outputB(ii));
    
    [status, writeATiming(ii,:)] = mexHID('writeDeviceReport', ...
        mcc.primaryID, writeA);
    
    [status, writeBTiming(ii,:)] = mexHID('writeDeviceReport', ...
        mcc.primaryID, writeB);
    
    mexHID('check');
end

[status, stopScanTiming] = mexHID('writeDeviceReport', ...
    mcc.primaryID, aStop);
tic;
while toc < .1
    mexHID('check');
end

mexHID('stopQueue', mcc.helperIDs);

updates = dataMap.values;
mcc.zeroTime = startScanTiming(1,3);
[chans, values, preSampleTimes, uints] = MCCWaveformsFromUpdates( ...
    mcc, updates, baseElementCache);

mcc.zeroTime = startScanTiming(1,5);
[chans, values, postSampleTimes, uints] = MCCWaveformsFromUpdates( ...
    mcc, updates, baseElementCache);

A = 1;
B = 2;
chanName = {'A', 'B'};
outputVoltScale = 4/outputMax;
writeValues{A} = outputA*outputVoltScale;;
writeValues{B} = outputB*outputVoltScale;;
sampleValues{A} = values(chans==8);
sampleValues{B} = values(chans==9);

preWrite = 1;
postWrite = 2;
writeName = {'pre-write', 'post-write'};
writeTimes{A, preWrite} = writeATiming(:,3);
writeTimes{B, preWrite} = writeBTiming(:,3);
writeTimes{A, postWrite} = writeATiming(:,5);
writeTimes{B, postWrite} = writeBTiming(:,5);

preScan = 1;
postScan = 2;
sampleName = {'pre-scan', 'post-scan'};
sampleTimes{A, preScan} = preSampleTimes(chans==8);
sampleTimes{B, preScan} = preSampleTimes(chans==9);
sampleTimes{A, postScan} = postSampleTimes(chans==8);
sampleTimes{B, postScan} = postSampleTimes(chans==9);

%%
% Channels 8 and 9 reflect outputs A and B at each step.  Channels 10 and
% 11 hold steady.  Sample times based on the start-scan pre-transaction
% timestamp line up pretty well with the output writing pre-transaction
% timestamps.  Likewise for both types of post-transaction timesamps.
%
% For longer tests, there is significant drift between host-side
% transaction times and scan times in the 1208FS.

f = figure(1);
clf(f);
scanTimes = [startScanTiming([3,5]), stopScanTiming([3,5])];
referenceTime = scanTimes(1);
ax = axes( ...
    'XLim', scanTimes([1,end]) - referenceTime, ...
    'XTick', scanTimes([1,end]) - referenceTime, ...
    'YLim', [0 5]);
title(ax, 'How do input samples and output writing line up?');
xlabel(ax, 'sample time or transaction timestamp (s)');
ylabel(ax, 'input sample or output value (V)')
lineName = {};
for ii = 1:mcc.nChans
    isThisChan = chans == mcc.chans(ii);
    if any(isThisChan)
        col = .8*(dec2bin(ii,3)=='1');
        line(preSampleTimes(isThisChan) - referenceTime, values(isThisChan), ...
            'Parent', ax, ...
            'LineStyle', 'none', ...
            'Marker', 'o', ...
            'Color', col);
        lineName{ii} = sprintf('%d', mcc.chans(ii));
        
        line(postSampleTimes(isThisChan) - referenceTime, values(isThisChan), ...
            'Parent', ax, ...
            'HandleVisibility', 'off', ...
            'LineStyle', 'none', ...
            'Marker', '+', ...
            'Color', col);
    end
end

line(writeTimes{A, preWrite} - referenceTime, writeValues{A}, ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', 'o', ...
    'Color', 'y');
line(writeTimes{A, postWrite} - referenceTime, writeValues{A}, ...
    'Parent', ax, ...
    'HandleVisibility', 'off', ...
    'LineStyle', 'none', ...
    'Marker', '+', ...
    'Color', 'y');

line(writeTimes{B, preWrite} - referenceTime, writeValues{B}, ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', 'o', ...
    'Color', 'm');
line(writeTimes{B, postWrite} - referenceTime, writeValues{B}, ...
    'Parent', ax, ...
    'HandleVisibility', 'off', ...
    'LineStyle', 'none', ...
    'Marker', '+', ...
    'Color', 'm');

line(-1, -1, ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', 'o', ...
    'Color', 'k');
line(-1, -1, ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '+', ...
    'Color', 'k');

legend(ax, lineName{:}, ...
    'A', 'B', ...
    'pre-transaction', 'post-transaction', ...
    'Location', 'southoutside');

%% Test 2
% "Coincidence interval" is the time between an output write timestamp and
% the first corresponding input sample.  Since these are measured with
% different clocks, I had to choose how to align them.  Write timestamps
% can be either pre- or post-write-transaction.  Likewise, input sample
% times can be aligned to either pre- or post-scan-transaction.
%
% Coincidence intervals based on post-write and post-read are the most
% consistent and least biased--about 0 +/1 .5ms.  This is great.  Pre-write
% timestamps seem to have the most jitter, probably because that's when
% Matlab is least synchronized the USB host frames.  Indeed, channel A, the
% first used, seems to have worse pre-write jitter than channel B.
%
% There is significant clock drift between the host and 1208FS.  Correcting
% for drift significantly imporoves the tightness of coincidence interval
% distributions, and accentuates the difference between pre- and
% post-transaction timestamps.

f = figure(2);
clf(f);

axDrift = subplot(2,1,1, ...
    'XLim', scanTimes([1,end]) - referenceTime, ...
    'XTick', scanTimes([1,end]) - referenceTime, ...
    'XGrid', 'on', ...
    'YGrid', 'on');
title(axDrift, 'Host vs 1208FS clock drift');
xlabel(axDrift, 'host timestamp (s)');
ylabel(axDrift, 'coincidence interval (s)');

pInterest = [25 75];
axRaw = subplot(2,2,3, ...
    'YGrid', 'on', ...
    'XTick', []);
title(axRaw, 'Pre- vs post-');
xlabel(axRaw, '(raw sample times)');
ylabel(axRaw, ...
    sprintf('[min max%s] - 50%% (s)', sprintf(' %d%%', pInterest)));
axCorrected = subplot(2,2,4, ...
    'YGrid', 'on', ...
    'XTick', []);
title(axCorrected, 'transaction timestamps?');
xlabel(axCorrected, '(drift-corrected sample times)');
lineName = {};
lineMarkers = '+o';
for ww = [preWrite postWrite]
    for ss = [preScan postScan]
        for cc = [A B]
            times = writeTimes{cc,ww}-referenceTime;
            intervals = compareOutputToCoincidentInput( ...
                writeTimes{cc,ww}, writeValues{cc}, ...
                sampleTimes{cc,ss}, sampleValues{cc});
            
            % drift
            lineColor = [ww-1 0 ss-1];
            linePlace = 2*ww + ss + .1*cc;
            lineName{end+1} = sprintf('%s %s %s', ...
                writeName{ww}, sampleName{ss}, chanName{cc});
            line(times, intervals, ...
                'Parent', axDrift, ...
                'HandleVisibility', 'on', ...
                'LineStyle', 'none', ...
                'Marker', lineMarkers(cc), ...
                'Color', lineColor);
            
            % raw intervals
            median = prctile(intervals, 50);
            percentiles = prctile(intervals, pInterest);
            minMax = [min(intervals), max(intervals)];
            line(linePlace*ones(size(minMax)), minMax-median, ...
                'Parent', axRaw, ...
                'HandleVisibility', 'off', ...
                'LineStyle', '-', ...
                'Marker', 'none', ...
                'Color', lineColor);
            line(linePlace*ones(size(percentiles)), percentiles-median, ...
                'Parent', axRaw, ...
                'HandleVisibility', 'on', ...
                'LineStyle', 'none', ...
                'Marker', lineMarkers(cc), ...
                'Color', lineColor);
            
            % corrected intervals
            [first, whereFirst] = min(times);
            [last, whereLast] = max(times);
            driftRate = (intervals(whereLast) - intervals(whereFirst))  ...
                / (last-first);
            corrected = intervals - driftRate*(times - times(1))';
            median = prctile(corrected, 50);
            percentiles = prctile(corrected, pInterest);
            minMax = [min(corrected), max(corrected)];
            line(linePlace*ones(size(minMax)), minMax-median, ...
                'Parent', axCorrected, ...
                'HandleVisibility', 'off', ...
                'LineStyle', '-', ...
                'Marker', 'none', ...
                'Color', lineColor);
            line(linePlace*ones(size(percentiles)), percentiles-median, ...
                'Parent', axCorrected, ...
                'HandleVisibility', 'on', ...
                'LineStyle', 'none', ...
                'Marker', lineMarkers(cc), ...
                'Color', lineColor);
        end
    end
end
legend(axDrift, lineName{:}, 'Location', 'eastoutside');
set(axCorrected, 'YLim', get(axRaw, 'YLim'))

%% Test 3
%   Reconfigure for one channel and several frequencies
%   Account for reports received

mcc.chans = 8;
mcc.nChans = numel(mcc.chans);
mcc.gains = ones(size(mcc.chans));
mcc.nSamples = mcc.samplesPerReport*10*nRepeats;
mcc.nScans = ceil(mcc.nSamples / mcc.nChans);
[baseElementCache, mcc] = MCCPrepareScan(mcc);

expectedLastNumber = ceil(mcc.nSamples / mcc.samplesPerReport) - 1;
expectedNumbers = 0:expectedLastNumber;

mexHID('startQueue', mcc.helperIDs);

frequency = linspace(1000, 55000, nValues);
attainedFrequency = zeros(size(frequency));
for ii = 1:nValues
    disp(sprintf('%d/%d: %d samples at %.1fHz', ...
        ii, nValues, mcc.nSamples, frequency(ii)))
    mexHID('check');
    dataMap.remove(dataMap.keys);
    
    mcc.frequency = frequency(ii);
    aScan = MCCFormatReport(mcc, 'AInScan', ...
        mcc.chans, mcc.frequency, mcc.nScans)
    mcc.scanInfo = aScan.other;
    attainedFrequency(ii) = mcc.scanInfo.attainedFrequency;
    
    numberIsIn = false(1, expectedLastNumber+1);
    nSamples = 0;
    stuck = 0;
    [status, startScanTiming] = mexHID('writeDeviceReport', ...
        mcc.primaryID, aScan);
    while ~all(numberIsIn) && stuck < 100
        mexHID('check');
        updates = dataMap.values;
        nSamplesOld = nSamples;
        [nSamples, reportNumbers] = MCCSampleCountFromUpdates( ...
            mcc, updates);
        numberIsIn(reportNumbers+1) = true;
        if nSamples == nSamplesOld
            stuck = stuck + 1;
            pause(.001);
        else
            stuck = 0;
        end
    end
    reportAccount{ii} = reportNumbers;
end

mexHID('stopQueue', mcc.helperIDs);

%%
% At hight frequencies, some reports go missing and some report numbers
% (and presumably data as well) are non-sensical.  In general, for sampling
% frequencies less than 45kHz, all reports arrive
f = figure(3);
clf(f);
kHz = attainedFrequency / 1000;
ax = axes( ...
    'XLim', [-1 expectedLastNumber+1], ...
    'YLim', [min(kHz), max(kHz)]);
title(ax, 'How does sample frequency affect reporting completeness?')
xlabel(ax, 'report number')
ylabel(ax, 'sample frequency (kHz)')
for ii = 1:nValues
    line(expectedNumbers, kHz(ii)*ones(size(expectedNumbers)), ...
        'Parent', ax, ...
        'LineStyle', 'none', ...
        'Marker', '.', ...
        'Color', 'r');
    
    countedReports = reportAccount{ii};
    line(countedReports, kHz(ii)*ones(size(countedReports)), ...
        'Parent', ax, ...
        'LineStyle', 'none', ...
        'Marker', '*', ...
        'Color', 'b');
end

%%
mexHID('closeQueue', mcc.helperIDs);

mexHID('terminate');

function diffs = compareOutputToCoincidentInput( ...
    outTimes, outValues, inTimes, inValues)

nOuts = numel(outTimes);
diffs = nan(1,nOuts);

valueMargin = .5*prctile(abs(diff(outValues)), 50);

previousTimes = zeros(size(outTimes));
previousTimes(1) = -inf;
previousTimes(2:end) = outTimes(1:(end-1));

for ii = 1:nOuts
    isLateEnough = inTimes > previousTimes(ii);
    
    smallValue = outValues(ii) - valueMargin;
    bigValue = outValues(ii) + valueMargin;
    isBigEnough = inValues > smallValue;
    isSmallEnough = inValues < bigValue;
    isRoughValue = isBigEnough & isSmallEnough;
    
    isCoincident = isLateEnough & isRoughValue;
    if any(isCoincident)
        inCoincidence = min(inTimes(isCoincident));
        diffs(ii) = inCoincidence - outTimes(ii);
    end
    
    %     f = figure(10);
    %     clf(f)
    %     ax = subplot(3,1,1, ...
    %         'XLim', [-1 +1]*.01+outTimes(ii), ...
    %         'YLim', [-1 +1]*.5+outValues(ii));
    %     line(inTimes(isLateEnough), inValues(isLateEnough), ...
    %         'Parent', ax, ...
    %         'LineStyle', 'none', ...
    %         'Marker', 'o', ...
    %         'Color', 'g');
    %     line(inTimes(~isLateEnough), inValues(~isLateEnough), ...
    %         'Parent', ax, ...
    %         'LineStyle', 'none', ...
    %         'Marker', 'o', ...
    %         'Color', 'r');
    %     line(outTimes(ii), outValues(ii), ...
    %         'Parent', ax, ...
    %         'LineStyle', 'none', ...
    %         'Marker', '*', ...
    %         'Color', 'k');
    %     line(previousTimes(ii), outValues(ii), ...
    %         'Parent', ax, ...
    %         'LineStyle', 'none', ...
    %         'Marker', '*', ...
    %         'Color', 'b');
    %     ax = subplot(3,1,2, ...
    %         'XLim', [-1 +1]*.01+outTimes(ii), ...
    %         'YLim', [-1 +1]*.5+outValues(ii));
    %     line(inTimes(isRoughValue), inValues(isRoughValue), ...
    %         'Parent', ax, ...
    %         'LineStyle', 'none', ...
    %         'Marker', 'o', ...
    %         'Color', 'g');
    %     line(inTimes(~isRoughValue), inValues(~isRoughValue), ...
    %         'Parent', ax, ...
    %         'LineStyle', 'none', ...
    %         'Marker', 'o', ...
    %         'Color', 'r');
    %     line(outTimes(ii), outValues(ii), ...
    %         'Parent', ax, ...
    %         'LineStyle', 'none', ...
    %         'Marker', '*', ...
    %         'Color', 'k');
    %     line(outTimes(ii), smallValue, ...
    %         'Parent', ax, ...
    %         'LineStyle', 'none', ...
    %         'Marker', '*', ...
    %         'Color', 'b');
    %     line(outTimes(ii), bigValue, ...
    %         'Parent', ax, ...
    %         'LineStyle', 'none', ...
    %         'Marker', '*', ...
    %         'Color', 'b');
    %     ax = subplot(3,1,3, ...
    %         'XLim', [-1 +1]*.01+outTimes(ii), ...
    %         'YLim', [-1 +1]*.5+outValues(ii));
    %     line(inTimes(isCoincident), inValues(isCoincident), ...
    %         'Parent', ax, ...
    %         'LineStyle', 'none', ...
    %         'Marker', 'o', ...
    %         'Color', 'g');
    %     line(inTimes(~isCoincident), inValues(~isCoincident), ...
    %         'Parent', ax, ...
    %         'LineStyle', 'none', ...
    %         'Marker', 'o', ...
    %         'Color', 'r');
    %     line(inCoincidence, inValues(find(inTimes==inCoincidence, 1)), ...
    %         'Parent', ax, ...
    %         'LineStyle', 'none', ...
    %         'Marker', '*', ...
    %         'Color', 'k');
    %     pause(.25)
end