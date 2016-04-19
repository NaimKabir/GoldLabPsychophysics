function [chans, values, times, uints] = MCCChannelsFromElements( ...
    mcc, elementCache)

reportNumber = elementCache(mcc.countCookie);
firstSampleNumber = reportNumber*mcc.samplesPerReport;
grandSampleNumber = firstSampleNumber + (0:(mcc.samplesPerReport-1));
chans = mcc.chans(1 + mod(grandSampleNumber, mcc.nChans));

elementBytes = elementCache(mcc.valueCookie);
byteMasks = mcc.channelConfig.byteMasks(:,1+chans);
byteShifts = mcc.channelConfig.byteShifts(:,1+chans);
maskedBytes = bitand(elementBytes, byteMasks(1:end));
shiftedBytes = bitshift(maskedBytes, byteShifts(1:end));
sortedBytes = reshape( ...
    shiftedBytes, mcc.bytesPerSample, mcc.samplesPerReport);

% interpret sample bits with two's complement signedness
uints = sum(sortedBytes, 1);
signedVales = uints ...
    - mcc.sampleUIntMagnitude * (uints >= mcc.sampleIntMagnitude);

values = signedVales .* mcc.channelConfig.voltScale(1+chans);

times = mcc.zeroTime + ...
    grandSampleNumber * mcc.scanInfo.attainedSampleInterval;