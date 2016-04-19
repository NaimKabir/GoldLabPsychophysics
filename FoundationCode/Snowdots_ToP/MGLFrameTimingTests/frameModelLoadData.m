% load frameModel* verification data from disk and review it
clear
clear classes
close all
clc

%% 10 frames with one skip
dataPath = '/Users/ben/Desktop/Labs/Gold/Fancy Graphics/mglTiming/figs and data/2011071603';
dataFile = 'verifyData.mat';
doReprocess = true;
frameModelReview(fullfile(dataPath, dataFile), doReprocess);

%% 10 frames with one skip
dataPath = '/Users/ben/Desktop/Labs/Gold/Fancy Graphics/mglTiming/figs and data/2011071605';
dataFile = 'verifyData.mat';
doReprocess = true;
frameModelReview(fullfile(dataPath, dataFile), doReprocess);

%% 35 frames with one skip and incorrect frame model
dataPath = '/Users/ben/Desktop/Labs/Gold/Fancy Graphics/mglTiming/figs and data/2011072001';
dataFile = 'verifyData.mat';
doReprocess = true;
frameModelReview(fullfile(dataPath, dataFile), doReprocess);

%% revised model, "easy" test
dataPath = '/Users/ben/Desktop/Labs/Gold/Fancy Graphics/mglTiming/figs and data/2011072301';
dataFile = 'shortDelayData.mat';
doReprocess = true;
frameModelReview(fullfile(dataPath, dataFile), doReprocess);

%% revised model, "titrating" test
dataPath = '/Users/ben/Desktop/Labs/Gold/Fancy Graphics/mglTiming/figs and data/2011072301';
dataFile = 'increasingDelayData.mat';
doReprocess = true;
frameModelReview(fullfile(dataPath, dataFile), doReprocess);

%% revised model, "fuzz" test
dataPath = '/Users/ben/Desktop/Labs/Gold/Fancy Graphics/mglTiming/figs and data/2011072301';
dataFile = 'randomDelayData.mat';
doReprocess = true;
frameModelReview(fullfile(dataPath, dataFile), doReprocess);

%%
h=gcf;
set(h, 'Position', [100 100 800 650])
set(h,'PaperOrientation','portrait');
set(h,'PaperType','A');
set(h,'PaperUnits','normalized');
set(h,'PaperPosition', [0 0 1 1]);
print(gcf, '-dpng', 'MGLEasyTest.png');