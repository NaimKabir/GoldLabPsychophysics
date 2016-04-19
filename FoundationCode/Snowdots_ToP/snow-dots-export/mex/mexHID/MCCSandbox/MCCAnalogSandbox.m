function updates = MCC1208FSAnalogSandbox
% I'm working on implementation details for receiving analod input samples.
% The Psychtoolbox approach is:
%   - configure the 1208FS for channels, gains, and frequency
%   - tell the 1208FS to start sampling (for some number of samples)
%   - run CFRunLoop often enough to handle incoming reports asynchronously
%   - pass the reports to Matlab
%   - decode the reports
% According to DaqAInScan comments, the "often enough" part can be tricky
% and sometimes reports can be lost!
%
% I would like to avoid working with raw input reports and work with
% elements and queues instead.  This turns out to present different
% difficulties:
%   - IOKit only enqueues value changes
%   - value changes may be just the LSB of a sample (!)
%   - I'm not sure yet to what channel (or byte) to assign a value change
% But it would be great to work these out.  Letting IOKit take care of
% value changes would alleviate the "often enough" problem in cases with
% infrequent value changes.
%
% To make elements and queues work, I'll need to work out a few things:
%   - I think value change timestamps are as good as report serial numbers,
%   as long as I know the first one and the interval.
%   - I think element numbers are as good as report byte-indexes, as
%   long as I know how to align them
%   - I think the combination of deviceID, report serial number, and
%   byte-index is enough to assign a value change to a byte and a channel.
%   - I will need to get the absolute value of each element before starting
%   the queue.  The timestamps here may solve the "first" problem of
%   converting timestamps to report serial numbers.
%   - Empirically, it seems that the report timestamp interval T is
%       T = (nDev * nRep) / f
%   where nDev is the number of helper devices (=3 for the 1208FS) and nRep
%   is the number of samples per report (=31 for the 1208FS).
%   - Just a darn minute!  The input element with cookie 65 seems to be an
%   explicit report counter.  So that problem is not a problem.  It the
%   explicit reanslation between timestamp and report number.
%   - so the report byte-indexes seem to go like this:
%       - cookies 1-2 are unknown and cause a crash when read from
%       - cookies 3-64 are pairs of samples, 31 in all
%       - cookie 65 is the report number
%   - given that I have the explicit report number, I don't think I care
%   about device ID after all
%   - so I think I have what I need!
%
% My approach would go like this:
%   - configure the 1208FS for channels, gains, and frequency
%   - read the initial values of all input elements, as a baseline
%   - deal the element values into channel as LSB or MSB
%   - add the input elements to a queue
%   - tell the 1208FS to start sampling (for some number of samples)
%   - run CFRunLoop often enough to handle incoming *value changes*
%   asynchronously
%       - values passed to Matlab at this time
%       - deal the element value changes into channels as LSB or MSB
%
% So I need a function to convert report numbers and element cookies into
% channel LSB or MSB.  It will depend on
%   - how many channels are being sampled
%   - which channels are being sampled
%   - sample endianness
% My vision/recollection is:
%   - nRep * serial -> grand byte index
%   - floor(grand byte index / 2) -> grand sample index
%   - grand sample index / number of channels -> channel index
%   - which channels(channel index) -> channel ID
%
% A concern might be that when only looking at value changes, it would be
% impossible to know whether samples had been dropped.  However, I think
% this is solved:
%   - in a fuzzy way, it seems more reasonable to expect IOKit to observe
%   all reports and decode element values, as opposed to expecting a mex
%   funciton under m-code control to observe all reports.
%   - in a concrete way, since report number is explicitly reported as a
%   value change, it's possible to say whether a report was lost.
%   - counting reports should be as good as counting samples, since samples
%   only come in reports.

% OK, so I need to test this.
%
% Test 1
% Write and read timestampped values on two channels
%
% My approach right now is too ambitious.  I need to step back and make
% sure I understand the decoding of element values.  Forget the queue.
% Just set, read, and plot.  I want three subplots, all with comparable
% timestamp x-axes:
%   - output transaction times and integer values
%   - input polling transaction times and integer values
%   - input sample times and interger values
% The first two should look right and be aligned, then the third one should
% follow.

% It's a real trick to establish baseline data.  I can always get old
% bytes, but I can't always know how to assign them to reports.  I can
% always generate reports, but these will be filtered through the IOKit
% change reporting.
%   - I could guess at baseline data.
%   - I could tell people to unplug the device.
%   - I could tell people to toggle their values a few times.
%   - I could try to read a raw report.
%   - Can I do a reset without stalling the device?
%   - Can I flush the values buffered in the kernel?
%   - Am I just using the wrong zero time?  Maybe I should just use
%   different zeros for hashing and alignment.

% Well, I've been wasting my time!  Or at least barking up the wrong tree.
% It is not meaningful to add elements to a queue and get notified when
% they change, for two intractible reasons:
%   - IOKit reports when element values change, but in this case elements
%   are report bytes, not all of which change when a channel changes, and
%   whose channel associations change periodically.  So channel changes are
%   not reported per se.  Spurious changes will be reported as channel
%   associations change, and real changes may be missed if bytes values
%   from different channels happen to coincide.
%   - The 1208FS comprises a primary and three helper devices, so sample
%   bytes are spread across three different devices, and therefore three
%   redundant sets of elements, repeating all of the above problems
%   threefold.
% So element value changes in this case are guaranteed to cause noise and
% loss of data, at some rate.
%
% So I'm forced to implement asynchronous report handling.
%
% Or not.  Damnit.
%
% I must maintain a cache of element values for each device.
%   - so my callback context needs to indicate device
% I must update each cache 

clear
clear mex
clc

% locate the 1208FS.
mexHID('initialize');
matching.VendorID = 2523;
matching.ProductID = 130;

deviceIDs = mexHID('openAllMatchingDevices', matching);
if all(deviceIDs < 0)
    disp('no device matched')
    return
end

nDevices = numel(deviceIDs);
deviceProps = mexHID('getDeviceProperties', deviceIDs);
primaryID = [];
helperIDs = [];
for ii = 1:nDevices
    if deviceProps(ii).MaxFeatureReportSize > 0
        primaryID = deviceIDs(ii);
    else
        helperIDs(end+1) = deviceIDs(ii);
    end
end
nHelpers = length(helperIDs);

% from experimentation, I know which element cookies do what
reportCountCookie = 65;
reportValueCookie = 3:64;
allInputCookies = [reportValueCookie, reportCountCookie];
nInputCookies = length(allInputCookies);
bytesPerSample = 2;

% analog sampling frequency, same for each channel
frequency = 10000;

% before doing tests, set both analog outs to low values
aOutID = 20;
aOutChan = 0;

%% Test 1

% If I reset the device, can I get fresh value changes from each element?
% [resetReport, resetID] = formatMCCReport('Reset');
% [status, resetTiming] = mexHID('writeDeviceReport', ...
%     primaryID, resetID, 2, resetReport);
% pause(.1)

% configure channels 0 and 1 for +/- 5V, with the primary device
chans = 8:9;
gains = 2*ones(size(chans));
[aConfReport, aConfID] = formatMCCReport('AInSetup', ...
    chans, gains);
[status, configTiming] = mexHID('writeDeviceReport', ...
    primaryID, aConfID, 2, aConfReport);

% sample for whole report(s)
samplesPerReport = 31;
nChans = length(chans);
nReports = 3;
nScans = floor(samplesPerReport * nReports / nChans);

[aScanReport, aScanID] = formatMCCReport('AInScan', ...
    chans, frequency, nScans);

%%
f = figure(1);
clf(f)
ax = subplot(2,1,1,  ...
    'XLim', allInputCookies([1,end]), ...
    'XTick', allInputCookies, ...
    'YLim', [0 255]);
isFirstByte = mod(allInputCookies,2)==1;
firsts = repmat(allInputCookies(isFirstByte), 1, nHelpers);
firstByte = line(firsts, zeros(size(firsts)), ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '.', ...
    'Color', 'b');
isSecondByte = mod(allInputCookies,2)==0;
seconds = repmat(allInputCookies(isSecondByte), 1, nHelpers);
secondByte = line(seconds, zeros(size(seconds)), ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '.', ...
    'Color', 'r');

ax = subplot(2,1,2, ...
    'XLim', chans([1 end]) + [-1 1], ...
    'XTick', chans, ...
    'YLim', [0 2^16]);
madeValues = line(chans, zeros(size(chans)), ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '*', ...
    'Color', 'r');

channelBytes = zeros(nChans, bytesPerSample);
readData = cell(1,nHelpers);
for jj = 1:nHelpers
    % no go on the flushing input element values
    [status, flushTiming] = mexHID('writeElementValues', ...
        helperIDs(jj), allInputCookies, 0);
    
    [values, readTiming] = mexHID('readElementValues', ...
        helperIDs(jj), allInputCookies);
    readData{jj} = values;
end


firstByteAllHelpers = repmat(isFirstByte, 1, nHelpers);
secondByteAllHelpers = repmat(isSecondByte, 1, nHelpers);
while ishandle(f)
    drawnow;
    [status, writeTiming] = mexHID('writeDeviceReport', ...
        primaryID, aScanID, 2, aScanReport);
    zeroTime = writeTiming(1,5);
    pause(.1);
    
    for jj = 1:nHelpers
        [values, readTiming] = mexHID('readElementValues', ...
            helperIDs(jj), allInputCookies);
        readData{jj} = values;
    end
    
    updateData = cat(1, readData{:});
    [channelUpdates, updateTimes] = updateChannelBytes( ...
        channelBytes, chans, frequency, updateData, zeroTime);
    if ~isempty(channelUpdates)
        channelBytes = channelUpdates(:,:,end);
        channelValues = valuesFromChannelBytes(channelBytes);
        
        %disp(updateTimes - zeroTime)
        
        if ishandle(f)
            set(firstByte, 'YData', updateData(firstByteAllHelpers,2));
            set(secondByte, 'YData', updateData(secondByteAllHelpers,2));
            set(madeValues, 'YData', channelValues);
        end
    end
end

[aStopReport, aStopID] = formatMCCReport('AInStop');
[status, timing] = mexHID('writeDeviceReport', ...
    primaryID, aStopID, 2, aStopReport);


%%
mexHID('terminate');

function [channelUpdates, updateTimes] = updateChannelBytes( ...
    channelStates, chans, frequency, updateData, zeroTime)

nChans = numel(chans);

% magic knowledge
firstCookie = 3;
reportCookie = 65;
samplesPerReport = 31;
bytesPerSample = 2;

% look up report serial number from value timestamp
%   requires transforming the timestamps to integers
timeHashes = 1 + floor(frequency*(updateData(:,3) - zeroTime));

isNew = timeHashes > 0;
isReportNumber = updateData(:,1) == reportCookie;
isNewReportNumber = isNew & isReportNumber;

% create(will need to update) the table with any new report numbers
persistent reportHashTable
if isempty(reportHashTable)
    reportHashTable = zeros(1, frequency, 'uint32');
end
reportHashTable(timeHashes(isNewReportNumber)) = ...
    updateData(isNewReportNumber,2);

isNewData = isNew & ~isReportNumber;
nUpdates = sum(isNewData);

% convert report bytes to sample values and times
reportNumber = double(reportHashTable(timeHashes(isNewData)));
reportByte = updateData(isNewData, 1)' - firstCookie;
reportSampleNumber = floor(reportByte/bytesPerSample);
grandSampleNumber = reportNumber*samplesPerReport + reportSampleNumber;

channelSub = mod(grandSampleNumber, nChans);
byteSub = mod(reportByte, bytesPerSample);
linearIndex = 1 + channelSub + nChans*byteSub;

channelUpdates = zeros(nChans, bytesPerSample, nUpdates);
updateBytes = updateData(isNewData,2)';
updateTimes = zeros(1, nUpdates);
for ii = 1:nUpdates
    channelStates(linearIndex(ii)) = updateBytes(ii);
    channelUpdates(:,:,ii) = channelStates;
    updateTimes(ii) = (grandSampleNumber(ii)/frequency) + zeroTime;
    
    %disp([reportNumber', reportByte', reportSampleNumber', ...
    %%grandSampleNumber', channelSub', byteSub', updateBytes'])
end


function channelValues = valuesFromChannelBytes(channelBytes)
nChans = size(channelBytes, 1);
bytesPerSample = size(channelBytes, 2);
bytePlaceValues = 2.^(8*(0:bytesPerSample-1));
channelPlaceValues = ones(nChans,1)*bytePlaceValues;
channelValues = sum(channelPlaceValues .* channelBytes, 2);