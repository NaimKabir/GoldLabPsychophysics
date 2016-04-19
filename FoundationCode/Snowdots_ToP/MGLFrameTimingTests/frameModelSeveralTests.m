% run several frame model tests, save and review the results
clear
clear classes
close all
clc

% pick parameters common to all tests
doFullScreen = true;
doWaitForOnset = false;
nFrames = 25;
grays = [.1 .1 .1; .3 .3 .3; .7 .7 .7];
colors = grays(1+mod(1:nFrames, size(grays,1)) ,:);

%% do an easy test with only short delays
testName = 'shortDelay';
delays = .003*ones(1, nFrames);
dataName = frameModelTest( ...
    doFullScreen, doWaitForOnset, delays, colors, testName);
frameModelReview(dataName);

%% do a titrating test with increasing delays
testName = 'increasingDelay';
displayInfo = mglDescribeDisplays;
framePeriod = 1/displayInfo.refreshRate;
delays = linspace(0.5*framePeriod, 1.5*framePeriod, nFrames);
dataName = frameModelTest( ...
    doFullScreen, doWaitForOnset, delays, colors, testName);
frameModelReview(dataName);

%% do a difficult "fuzz" test with uniform random delays
testName = 'randomDelay';
displayInfo = mglDescribeDisplays;
framePeriod = 1/displayInfo.refreshRate;
delays = 2*framePeriod*rand(1, nFrames);
dataName = frameModelTest( ...
    doFullScreen, doWaitForOnset, delays, colors, testName);
frameModelReview(dataName);