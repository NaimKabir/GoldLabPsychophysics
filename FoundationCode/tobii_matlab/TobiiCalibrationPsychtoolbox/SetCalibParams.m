function Calib = SetCalibParams()

global EXPWIN

screens=Screen('Screens');
%Select the screen where the stimulus is going to be presented
Calib.screenNumber=max(screens);

[EXPWIN, winRect] = Screen('OpenWindow', Calib.screenNumber);
Calib.screen.sz=[ 57.3 45];  % [Horizontal, Vertical] Dimensions of screen (cm)
Calib.screen.vdist= 60; % Observer's viewing distance to screen (cm)
disp(['Using Viewing Distance of: ' num2str(Calib.screen.vdist) ...
    'cm, with monitor width of ' num2str(Calib.screen.sz(1)) ...
    'cm and height of ' num2str(Calib.screen.sz(2)) 'cm'])
Calib.screen.x = winRect(1);
Calib.screen.y = winRect(2);
Calib.screen.width = winRect(3);
Calib.screen.height = winRect(4);

degperpix=2*((atan(Calib.screen.sz ./ (2*Calib.screen.vdist))).*(180/pi))./[Calib.screen.width Calib.screen.height];
pixperdeg=1./degperpix;
Calib.screen.degperpix = mean(degperpix);
Calib.screen.pixperdeg = mean(pixperdeg);

Calib.points.x = [0.1 0.9 0.5 0.9 0.1];  % X coordinates in [0,1] coordinate system
Calib.points.y = [0.1 0.1 0.5 0.9 0.9];  % Y coordinates in [0,1] coordinate system
Calib.points.n = size(Calib.points.x, 2); % Number of calibration points
Calib.bkcolor = [0.65 0.65 0.65]*255; % background color used in calibration process
Calib.fgcolor = [0, 0, 0]*255;
Calib.fgcolor2 = [0.65, 0.65, 0.65]*255;
% Calib.fgcolor = [0 0 1]; % (Foreground) color used in calibration process
% Calib.fgcolor2 = [1 0 0]; % Color used in calibratino process when a second foreground color is used (Calibration dot)

Calib.BigMark = 35; % the big marker
Calib.TrackStat = 25; %
Calib.SmallMark = 7; % the small marker
Calib.delta = 200; % Moving speed from point a to point b
Calib.resize = 1; % To show a smaller window
Calib.NewLocation = get(gcf,'position');


close all;
return



