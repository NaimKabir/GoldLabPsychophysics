function [baseElementCache, mcc] = MCCPrepareScan(mcc)
% Returns cache of initial values for allInputCookies, from each
% helperDevice.  Columns of baseElementCache correspond to element cookies
% in allInputCookies (actial cookies values, not indexes).  Rows of
% baseElementCache correspond to elements of mcc.helperIDs.

% Configure scan for given channels and gains
aConf = MCCFormatReport(mcc, 'AInSetup', ...
    mcc.chans, mcc.gains);
[status, configTiming] = mexHID('writeDeviceReport', ...
    mcc.primaryID, aConf);
mcc.channelConfig = aConf.other;

% Read all cached values for each helper device
%   essentially one complete report per device
%   don't care about timestamps here
nHelpers = numel(mcc.helperIDs);
allInputCookies = [mcc.valueCookie, mcc.countCookie];
baseElementCache = zeros(nHelpers, max(allInputCookies));
for jj = 1:nHelpers
    [helperData, readTiming] = mexHID('readElementValues', ...
        mcc.helperIDs(jj), allInputCookies);
    baseElementCache(jj,helperData(:,1)) = helperData(:,2);
end