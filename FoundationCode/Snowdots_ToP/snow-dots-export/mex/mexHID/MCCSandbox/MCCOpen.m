function mcc = MCCOpen

%% Constants
% some are magical from experimentation or stolen from DaqToolbox
mcc.VendorID = 2523;
mcc.ProductID = 130;

mcc.DOutA = 0;
mcc.DOutB = 1;

mcc.valueCookie = 3:64;
mcc.countCookie = 65;
mcc.allInputCookies = [mcc.valueCookie, mcc.countCookie];

mcc.bytesPerSample = 2;
mcc.sampleIntMagnitude = 2^(8*mcc.bytesPerSample-1);
mcc.sampleUIntMagnitude = 2^(8*mcc.bytesPerSample);
mcc.samplesPerReport = 31;
mcc.sampleBytesPerReport = mcc.samplesPerReport*mcc.bytesPerSample;
mcc.bytePlaces = mod(0:mcc.sampleBytesPerReport-1, mcc.bytesPerSample);
mcc.bytePlaceValues = 2.^(8*mcc.bytePlaces);

mcc.zeroTime = 0;

mcc.primaryID = [];
mcc.outputID = [];
mcc.helperIDs = [];
mcc.nHelpers = 0;

%% The HID devices
%   locate the 1208FS device
if ~mexHID('isInitialized')
    mexHID('initialize');
end

matching.VendorID = mcc.VendorID;
matching.ProductID = mcc.ProductID;
deviceIDs = mexHID('openAllMatchingDevices', matching);
if all(deviceIDs < 0)
    disp('no device matched')
    return
end

nDevices = numel(deviceIDs);
deviceProps = mexHID('getDeviceProperties', deviceIDs);
for ii = 1:nDevices
    if deviceProps(ii).MaxFeatureReportSize > 0
        mcc.primaryID = deviceIDs(ii);
    else
        mcc.helperIDs(end+1) = deviceIDs(ii);
        if deviceProps(ii).MaxOutputReportSize > 0
            mcc.outputID = deviceIDs(ii);
        end
    end
end
mcc.nHelpers = length(mcc.helperIDs);

%% Default the digital ports to output
AOutput = MCCFormatReport(mcc, 'DSetup', mcc.DOutA, 'output');
[status, timing] = mexHID('writeDeviceReport', ...
    mcc.primaryID, AOutput);
BOutput = MCCFormatReport(mcc, 'DSetup', mcc.DOutB, 'output');
[status, timing] = mexHID('writeDeviceReport', ...
    mcc.primaryID, BOutput);
