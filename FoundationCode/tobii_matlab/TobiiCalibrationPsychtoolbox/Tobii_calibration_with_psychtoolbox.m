global EXPWIN %Psychtoolbox window
global KEYBOARD 
global SPACEKEY 
global CENTER %Center of psychtoolbox window 
global WHITE 
global BLACK 

eyetrackerhost = 'XL060-31500295.local.';

%**************************
% Open Psychtoolbox window
%**************************
Screen('Preference','SkipSyncTests',1);

%Open settings for screen & tracker
Calib=SetCalibParams;

%Window variables
CENTER = [round((Calib.screen.width - Calib.screen.x)/2) ...
    round((Calib.screen.height -Calib.screen.y)/2)];
BLACK = BlackIndex(EXPWIN); 
WHITE = WhiteIndex(EXPWIN);

% Map keys to Mac-OSX naming scheme
KbName('UnifyKeyNames');
KEYBOARD=max(GetKeyboardIndices);
% SPACEKEY = 32;%Windows system key code
SPACEKEY = KbName('space');

%****************************
% Connect to eye tracker
%****************************

disp('Initializing tetio...');
tetio_init();
fprintf('Connecting to tracker "%s"...\n', eyetrackerhost);
tetio_connectTracker(eyetrackerhost)

%Wait until the synchronization of ET and Matlab clock is finished
tic; 
while tetio_clockSyncState() == 0
    pause(0.25)
    if toc > 5
        tetio_cleanUP()
        error('Error: Unable to synchronize Eye Tracker and computer clocks, retrying');
    end
end  	

%Get and print the Frame rate of the current ET
fprintf('Frame rate: %d Hz.\n', tetio_getFrameRate);

%*********************
% TrackStatus
%*********************
TrackStatus(Calib);

%*********************
% Calibration
%*********************
disp('Starting Calibration workflow');
[pts, CalibError] = HandleCalibWorkflow(Calib);
disp('Calibration workflow stopped');
Screen('FillRect',EXPWIN,BLACK);
Screen(EXPWIN,'Flip');
 
%*********************
% Calibration finished
%********************
disp('Displaying point by point error:')
disp('[Mean StandardDev]')
CalibError


disp('Starting Validation')
mOrder = randperm(Calib.points.n);
tetio_startTracking;
ValidationError=TestEyeTrackerError(Calib,mOrder);

disp('End of Validation Validation, displaying Error:')
disp('Displaying point by point error, Left Eye:')
disp('[Median StandardDev]')
ValidationError.Left

disp('Displaying point by point error, Left Eye:')
disp('[Median StandardDev]')
ValidationError.Right
disp('Click button to exit & start simple experiment example')


disp('Starting simple Experiment')
%---run simple example of experiment loop
SimpleExp


tetio_cleanUp()
Screen('Close',EXPWIN)
