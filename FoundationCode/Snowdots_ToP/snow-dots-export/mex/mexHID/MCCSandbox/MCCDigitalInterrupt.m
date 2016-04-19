function MCCDInInterrupt
% Can I get interrupt behavior for 1208FS digital input ports?
%
% Test 1
% - Configure the digital inputs A and B for "in" mode
% - Add the digital input elements to a queue
% - loop for a while
%   - mexHID check
%   - drag the +5V lead around on the input pins to provide "input data"
% - Do I see any value changes?

clear
clear all
clc

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
dInCookie = [dIns.ElementCookie];

% configure both digital ports for input
[status, timing] = mexHID('writeDeviceReport', ...
    deviceID, dConfID, 2, uint8([dConfID A in]));
[status, timing] = mexHID('writeDeviceReport', ...
    deviceID, dConfID, 2, uint8([dConfID B in]));

%% Test 1
queueMap = containers.Map(0,0, 'uniformValues', false);
queueMap.remove(queueMap.keys);
callback = {@recordData, queueMap};
mexHID('openQueue', deviceID, dInCookie, callback, 1000);
mexHID('startQueue', deviceID);


disp('Drag the lead')
drawnow
duration = 5;

% What could I set here to initiate dIn interrupts?  Anything?
%   - a different value for dInID report?
%   - a dConfID value besides in or out?
[status, timing] = mexHID('writeDeviceReport', ...
    deviceID, dInID, 2, uint8([dInID, 1]));

tic;
while toc < duration
    mexHID('check');
end

mexHID('stopQueue', deviceID);
dataPile = queueMap.values;
queuedData = cat(1, dataPile{:});
m = size(queuedData, 1);

if m == 0
    disp('Queued no values.')
    return
end

%%
f = figure(1);
clf(f)
ax = axes;
title(ax, 'Can I get digital inputs without polling?')

ax = axes;
ylabel(ax, 'digital input value')
xlabel(ax, 'timestamp')
line(queuedData(:,3)-queuedData(1,3), queuedData(:,2), ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '*', ...
    'color', 'b')

mexHID('terminate');

function recordData(queueMap, newData)
queueMap(queueMap.length+1) = newData;