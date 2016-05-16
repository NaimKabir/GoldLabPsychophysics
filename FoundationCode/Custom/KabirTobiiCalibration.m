 % Script that calibrates the Tobii eye tracker from MATLAB
% for saccade - due to Kamesh 
close all
clear classes

disp('Initializing Tobii Eye Tracker\n');
tetio_init();
% Set to tracker ID to the product ID of the tracker you want to connect to.
trackerId = 'XL060-31500295.local.';
fprintf('Connecting to tracker "%s"...\n', trackerId);
tetio_connectTracker(trackerId)

currentFrameRate = tetio_getFrameRate;
fprintf('Eye Tracker Frame Rate: %d Hz.\n', currentFrameRate);


global Calib

%Kabir code start, set secondary screen for calibrations
screensize = get(0, 'MonitorPositions'); 
screensize = screensize(1,:); 
set(0, 'DefaultFigurePosition', screensize)
% code end

% screensize = [1 1  1200 1920]; Commented out MK

Calib.mondims1.x = screensize(1);
Calib.mondims1.y = screensize(2);
Calib.mondims1.width = screensize(3);
Calib.mondims1.height = screensize(4);

Calib.MainMonid = 1; 
Calib.TestMonid = 1;

Calib.points.x = [0.1 0.1 0.1 0.5 0.5 0.5 0.9 0.9 0.9];  % X coordinates in [0,1] coordinate system 
Calib.points.y = [0.1 0.5 0.9 0.1 0.5 0.9 0.1 0.5 0.9];  % Y coordinates in [0,1] coordinate system 
Calib.points.n = size(Calib.points.x, 2); % Number of calibration points
Calib.bkcolor = [0.85 0.85 0.85]; % background color used in calibration process
Calib.fgcolor = [0 0 1]; % (Foreground) color used in calibration process
Calib.fgcolor2 = [1 0 0]; % Color used in calibratino process when a second foreground color is used (Calibration dot)
Calib.BigMark = 25; % the big marker 
Calib.TrackStat = 25; % 
Calib.SmallMark = 7; % the small marker
Calib.delta = 200; % Moving speed from point a to point b
Calib.resize = 1; % To show a smaller window 



disp('Starting TrackStatus');
% Display the track status window showing the participant's eyes (to position the participant).
TrackStatus; % Track status window will stay open until user key press.
disp('TrackStatus stopped');

disp('Starting Calibration workflow');
% Perform calibration
HandleCalibWorkflow(Calib);
disp('Calibration workflow stopped');
% 

close all;


X = imread('TobiiDots.jpg');
img=X; % Remove

figure('menuBar', 'none', 'name', 'Image Display', 'keypressfcn', 'close;');
image(img);
axis equal;

axes('Visible', 'off', 'Units', 'normalized',...
    'Position', [0 0 1 1],...
    'DrawMode','fast',...
    'NextPlot','replacechildren');

Calib.mondims = Calib.mondims1;
set(gcf,'position', [Calib.mondims.x Calib.mondims.y Calib.mondims.width Calib.mondims.height]);

xlim([1,Calib.mondims.width]); ylim([1,Calib.mondims.height]);axis ij;
set(gca,'xtick',[]);set(gca,'ytick',[]);
hold on;

keyboard

% *************************************************************************
%
% Start tracking and plot the gaze data read from the tracker.
%
% *************************************************************************

tetio_startTracking;

% leftEyeAll = [];
% rightEyeAll = [];
% timeStampAll = [];

pauseTimeInSeconds = 0.01;
durationInSeconds = 1.5*1;

[leftEyeAll, rightEyeAll, timeStampAll] = DataCollect(durationInSeconds, pauseTimeInSeconds);

tetio_stopTracking; 
%tetio_disconnectTracker; 
%tetio_cleanUp;

DisplayData(leftEyeAll, rightEyeAll );


disp('Program finished.');

tetio_startTracking;