function MCC1208FSDigitalTiming
% Characterize digital timing for the 1208FS device from Measurement
% Computing.
%
% Test 1
% Look at digital inputs and outputs:
%   - In a loop
%       - write a digital output to port A
%       - wait a delay, d
%       - trigger the device to send a digital input report
%       - wait a delay, d, again
%       - read the value of digital port A
%   - how big does the delay d need to be before input report triggering
%   succeeds?
%   - are the input timestamps pegged to the digital writing time (seems
%   unlikely) or the trigger input report time (seems likely)
%
% Test 2
% Look at the granularity of timestamps:
%   - Add the digital input A element to a queue
%   - In a loop
%       - write a digital output to port A
%       - trigger the device to send a digital input report
%   - plot all the timestamp diffs
%   - what is the apparent temporal resolution of the input value
%   timestamps?  Is it a multiple of the device report interval?
%   - is the resolution only tied to the input report triggering?


clear
clear all
clc

n = 50;

% locate the 1208FS.
%   IOKit won't match on all my criteria, so I'll keep looking for devices
%   until I get the 1208FS interface that has elemets with non-zero
%   reportID.
mexHID('initialize');
matching.VendorID = 2523;
matching.ProductID = 130;

matched = false;
while ~matched
    deviceID = mexHID('openMatchingDevice', matching);
    if deviceID >= 0
        elements = mexHID('summarizeElements', deviceID);
        matched = any([elements.ReportID] > 0);
        if ~matched
            mexHID('closeDevice', deviceID);
        end
    else
        disp('no matching device')
        return
    end
end

% constants for reports and digital ports
dConfID = 1;
dOutID = 4;
dInID = 3;
A = 0;
B = 1;
out = 0;
in = 1;

AOrB = A;

% digital input elements
inType = mexHIDUsage.numberForElementTypeName('Input_Misc');
dIns = elements([elements.Type]==inType & [elements.ReportID]==dInID);
dInCookie = dIns(AOrB+1).ElementCookie;

% configure the digital ports for input and output
dConf.type = 2;
dConf.ID = dConfID;
dConf.bytes = uint8([dConfID AOrB out]);
[status, timing] = mexHID('writeDeviceReport', deviceID, dConf);


% I don't understand digital port configuration yet.  As it is above, the
% correct outputs get set and I can measure them on port A or B with my
% voltmeter.  But I can only read correct values back when using port A.

%% Test 1
dOutReports = zeros(n,5);
dTriggerReports = zeros(n,5);
dInReads = zeros(n,5);
dInData = zeros(n,3);
pauses = linspace(0,.005,n);;
for ii = 1:n
    dValue = mod(ii,256);
    dOut.type = 2;
    dOut.ID = dOutID;
    dOut.bytes = uint8([dOutID AOrB dValue]);
    [status, dOutReports(ii,:)] = mexHID('writeDeviceReport', ...
        deviceID, dOut);
    
    tickPause(pauses(ii));
    
    dIn.type = 2;
    dIn.ID = dInID;
    dIn.bytes = uint8(dInID);
    [status, dTriggerReports(ii,:)] = mexHID('writeDeviceReport', ...
        deviceID, dIn);
    
    tickPause(pauses(ii));
    
    [dInData(ii,:), dInReads(ii,:)] = ...
        mexHID('readElementValues', deviceID, dInCookie);
end

%%
% Timestamps are clearly related to the trigger report time, not the output
% value set time.  Yet the physical voltage change is related to the output
% value set time (voltage reading does not depend on sending a trigger
% report at all).
%
% Most timestamps get assigned just before the end of the trigger
% transaction.  Some are about one frame (1ms) later.  Suring short pause
% times, some are so late that the never get read and instead the previous
% timestamps shows up again as a negative value.
%
% Report writing end times are saw-toothed with an amplitude of about 1ms,
% which I take to be one frame.  This must be because the report writing
% start time may happen anywhere within a frame, but the end time is pegged
% to a frame boundary.  What if I align to the end time?
f = figure(1);
clf(f)
ax = axes;
title(ax, 'How do digital IO times line up?')
ylabel(ax, 'post-write-subtracted timestamp')
xlabel(ax, 'pause time')
%alignTimes = dOutReports(:,3);
alignTimes = dOutReports(:,5);
line(pauses, dOutReports(:,3)-alignTimes, ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '+', ...
    'color', 'g')
line(pauses, dOutReports(:,5)-alignTimes, ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '+', ...
    'color', 'r')
line(pauses, dTriggerReports(:,3)-alignTimes, ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '.', ...
    'color', 'g')
line(pauses, dTriggerReports(:,5)-alignTimes, ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '.', ...
    'color', 'r')
line(pauses, dInData(:,3)-alignTimes, ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '*', ...
    'color', 'c')
line(pauses, dInReads(:,5)-alignTimes, ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '*', ...
    'color', 'b')
legend('pre-write', 'post-write', 'pre-trig', 'post-trig', ...
    'value timestamp', 'value read', 'Location', 'northwest')

%% Test 2
dOutReports = zeros(n,5);
dTriggerReports = zeros(n,5);

queueMap = containers.Map(0,0, 'uniformValues', false);
queueMap.remove(queueMap.keys);
callback = {@recordData, queueMap};
mexHID('openQueue', deviceID, dInCookie, callback, n);
mexHID('startQueue', deviceID);

for ii = 1:n
    dValue = mod(ii,256);
    dOut.type = 2;
    dOut.ID = dOutID;
    dOut.bytes = uint8([dOutID AOrB dValue]);
    [status, dOutReports(ii,:)] = mexHID('writeDeviceReport', ...
        deviceID, dOut);
    
    dIn.type = 2;
    dIn.ID = dInID;
    dIn.bytes = uint8(dInID);
    [status, dTriggerReports(ii,:)] = mexHID('writeDeviceReport', ...
        deviceID, dIn);
    
    mexHID('check');
end
mexHID('stopQueue', deviceID);
dataPile = queueMap.values;
queuedData = cat(1, dataPile{:});
m = size(queuedData, 1);

if n~=m
    disp(sprintf('Queued %d out of %d timestamps, which is wrong.', ...
        m,n))
end

%%
% I can only write outputs and request input transactions with limited
% frequency, about every 3-5ms.  But there doesn't appear to be any
% additional granularity imposed on the value change timestamps.  They show
% up consistently just before the post-trig timestamps, or one frame later,
% and have 1ms granularity.  They are not constrained by the device report
% interval, which is 8000 (microseconds?).
f = figure(2);
clf(f)
ax = subplot(2,1,1);
title(ax, 'What is the granularity of digital IO times?')
ylabel(ax, 'timestamp interval')
line(2:m, diff(queuedData(:,3)), ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '*', ...
    'color', 'b')

ax = subplot(2,1,2);
ylabel(ax, 'post-trig-subtracted timestamp')
xlabel(ax, 'test iteration')
alignTimes = dTriggerReports(:,5);
line(1:n, dOutReports(:,3) - alignTimes, ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '+', ...
    'color', 'g')
line(1:n, dOutReports(:,5) - alignTimes, ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '+', ...
    'color', 'r')
line(1:n, dTriggerReports(:,3) - alignTimes, ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '.', ...
    'color', 'g')
line(1:n, dTriggerReports(:,5) - alignTimes, ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '.', ...
    'color', 'r')
line(1:m, queuedData(:,3) - alignTimes, ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '*', ...
    'color', 'b')
legend('pre-write', 'post-write', ...
    'pre-trig', 'post-trig', ...
    'value change', 'Location', 'northwest')

mexHID('terminate');

function recordData(queueMap, newData)
queueMap(queueMap.length+1) = newData;

function tickPause(seconds)
tic;
endToc = toc+seconds;
while toc < endToc
end