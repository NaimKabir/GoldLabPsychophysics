function [nSamples, reportNumbers] = MCCSampleCountFromUpdates( ...
    mcc, updates)

nSamples = 0;
reportNumbers = [];

% HID timestamps are not meaningful per se, but they are monotonic with
% MCC report numbers, which are meaningful.
%   Can I think of a good way to sort online?
%   Why can I only see the first byte of my report number?
allUpdates = cat(1, updates{:});
if ~isempty(allUpdates)
    isReportNumber = allUpdates(:,1) == mcc.countCookie;
    if any(isReportNumber)
        reportNumbers = allUpdates(isReportNumber,2);
        nSamples = (max(reportNumbers)+1) * mcc.samplesPerReport;
    end
end