% Write a bunch of digital words to Plexon, try to assess clock alignment.

%% drop some codes on Plexon
clear all
clear classes
clc

localFile = 'awesome.mat';

codes = 0:(2^15-1);
n = numel(codes);

meanPause = .050;
writeTime = .008;
pauses = exprnd(meanPause, 1, n);
expectedSeconds = writeTime*n + sum(pauses);
expectedMinutes = expectedSeconds/60;
disp(sprintf('expect to take %.0fs (%.2f min)', ...
    expectedSeconds, expectedMinutes))

mexHID('initialize');
mcc = MCCOpen;

allInfo = cell(1,n);
for ii = 1:n
    allInfo{ii} = MCCPlexonCode(mcc, codes(ii));
    pause(pauses(ii));
end

mexHID('terminate');
save(localFile);

%% Get Plexon's data
plexonMount = '/Volumes/BenHTests/';
plexonFile = 'awesomePlex.mat';
plexData = load(fullfile(plexonMount, plexonFile));

strobeValue = plexData.values';
[sorted, strobeOrder] = sort(strobeValue);

disp(sprintf('%d codes, %d strobed values', ...
    numel(codes), numel(strobeValue)))

strobeTime = plexData.stamps';
strobeZero = strobeTime(1);
strobeDuration = strobeTime(end) - strobeZero;

%% Get local data
localFile = 'awesome.mat';
load(localFile);
codeTime = zeros(1,n);
for ii = 1:n
    codeTime(ii) = allInfo{ii}(3).timing(5);
end
codeZero = codeTime(1);
codeDuration = codeTime(end) - codeTime(1);
[sorted, codeOrder] = sort(codes);

% Correct Drift
pointDriftRate = (strobeTime(strobeOrder)-strobeZero) ...
    ./ (codeTime(codeOrder)-codeZero);
nearEnd = floor(.9*n):n;
strobeDrift = mean(pointDriftRate(nearEnd));

disp(sprintf('Plexon averaged %fs per host s', strobeDrift))

expectedDrift = (codeTime - codeZero) * (strobeDrift - 1);
strobeTimeCorrected = strobeTime - expectedDrift;

coincidenceInterval = (strobeTimeCorrected(strobeOrder) - strobeZero) ...
    - (codeTime(codeOrder) - codeZero);
[counts, bins] = hist(coincidenceInterval, 25);

minMax = [min(coincidenceInterval), max(coincidenceInterval)];
pInterest = [5 95];
percentiles = prctile(coincidenceInterval, pInterest);
median = prctile(coincidenceInterval, 50);

disp(sprintf('coincidence interval %s %.2e', ...
    sprintf('%d%%-', pInterest), abs(diff(percentiles))))

%%
f = figure(1);
clf(f);
ax = subplot(3,1,1);
title('Strobed values over time')
xlabel(ax, 'host time or drift-corrected Plexon time(s)')
ylabel(ax, 'code sent or Plexon strobe value');
line(codeTime - codeZero, codes, ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', 'o', ...
    'Color', 'b');
line(strobeTimeCorrected - strobeZero, strobeValue, ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '.', ...
    'Color', 'r');
legend(ax, 'codes from host', 'Plexon strobe values', ...
    'Location', 'northwest')

ax = subplot(3,1,2, ...
    'YLim', [-1 +1]*2e-3, ...
    'YGrid', 'on');
title('Coincidence intervals over time')
xlabel(ax, 'host time (s)')
ylabel(ax, 'interval (s)');
line(codeTime - codeZero, coincidenceInterval, ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '.', ...
    'Color', 'g')

ax = subplot(3,1,3);
title('Coincidence interval distribution')
xlabel(ax, 'host time - Plexon time interval (s)')
ylabel(ax, 'count');
line(bins, counts, ...
    'Parent', ax, ...
    'HandleVisibility', 'off', ...
    'LineStyle', ':', ...
    'Marker', '.', ...
    'Color', 'g');
line(percentiles, 0.75*max(counts)*ones(size(percentiles)), ...
    'Parent', ax, ...
    'LineStyle', '-', ...
    'Marker', '+');
line(minMax, 0.5*max(counts)*ones(size(minMax)), ...
    'Parent', ax, ...
    'LineStyle', ':', ...
    'Marker', 'none');

width = abs(diff(minMax));
pWidth = abs(diff(percentiles));
legend(ax, ...
    sprintf('%d%%-%d%% = %.2e', pInterest(1), pInterest(end), pWidth), ...
    sprintf('min-max = %.2e', width), ...
    'Location', 'northeast')