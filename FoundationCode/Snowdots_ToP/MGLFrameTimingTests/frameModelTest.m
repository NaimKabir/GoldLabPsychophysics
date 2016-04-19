function dataName = frameModelTest( ...
    doFullScreen, doWaitForOnset, delays, colors, testName)
% Compare MGLFlushGauge frame onset predictions to onscreen measurements

if nargin < 1
    doFullScreen = true;
end

if nargin < 2
    doWaitForOnset = false;
end

if nargin < 3
    delays = .004*ones(1,10);
end
nFrames = numel(delays);

if nargin < 4
    grays = [.1 .1 .1; .3 .3 .3; .7 .7 .7];
    colors = grays(1+mod(1:nFrames, size(grays,1)) ,:);
end

if nargin < 5
    testName = mfilename();
end


% set up the screen
if doFullScreen
    mglOpen(1);
else
    mglOpen(0);
end
mglDisplayCursor(0);
mglScreenCoordinates();

% set up the fluch gauge
gauge = MGLFlushGauge();
if doWaitForOnset
    swapFunction = @()flushWait(gauge);
else
    swapFunction = @()flush(gauge);
end

% set up drawing
deviceRect = mglGetParam('deviceRect');
x = mean(deviceRect([1 3]));
y = mean(deviceRect([2 4]));
w = diff(deviceRect([1 3]));
h = diff(deviceRect([2 4]));
drawFunction = @(c)mglFillRect(x, y, [w h], c);

% "warm up" everything in the test.  The effect is huge.
timeData = drawAndSwap( ...
    gauge, nFrames, swapFunction, delays, drawFunction, colors);

% draw and swap while measuring light!
%   use channel "0", which compares pins 1 and 2
%   use gain "7", which expects +/-1V
aIn = AInScan1208FS();
aIn.frequency = 5000;
aIn.nSamples = inf;
aIn.queueDepth = 2000;
aIn.channels = 0;
aIn.gains = 7;
aIn.prepareToScan();
aIn.startScan();
aIn.waitForData();
timeData = drawAndSwap( ...
    gauge, nFrames, swapFunction, delays, drawFunction, colors);
mglClose();
mglDisplayCursor(1);
aIn.stopScan();
[chans, volts, times, uints] = aIn.getScanWaveform();

lightData.chans = chans;
lightData.volts = volts;
lightData.times = times;
lightData.uints = uints;

dataName = sprintf('%sData.mat', testName);
save(dataName);

function timeData = drawAndSwap( ...
    gauge, nFrames, swapFunction, delays, drawFunction, colors)
startTime = zeros(1, nFrames);
finishTime = zeros(1, nFrames);
delayedTime = zeros(1, nFrames);
drewTime = zeros(1, nFrames);
swappedTime = zeros(1, nFrames);
onsetTime = zeros(1, nFrames);
onsetFrame = zeros(1, nFrames);
isTight = false(1, nFrames);

gauge.initialize();
for ii = [1:nFrames]
    startTime(ii) = mglGetSecs();
    mexHID('check');
    mglWaitSecs(delays(ii));
    delayedTime(ii) = mglGetSecs();
    feval(drawFunction, colors(ii,:));
    drewTime(ii) = mglGetSecs();
    [onsetTime(ii), onsetFrame(ii), swappedTime(ii), isTight(ii)] = ...
        feval(swapFunction);
    finishTime(ii) = mglGetSecs();
end

timeData.startTime = startTime;
timeData.finishTime = finishTime;
timeData.delayedTime = delayedTime;
timeData.drewTime = drewTime;
timeData.swappedTime = swappedTime;
timeData.onsetTime = onsetTime;
timeData.onsetFrame = onsetFrame;
timeData.isTight = isTight;
timeData.swapFunction = swapFunction;
timeData.nFrames = nFrames;