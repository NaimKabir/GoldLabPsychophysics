function MedianEyeError=TestEyeTrackerError(Calib,mOrder)

global EXPWIN
DrawFormattedText(EXPWIN,'Click mouse to Start Calibration Check','Center',...
    Calib.screen.height/3, [255 255 255]);
Screen(EXPWIN,'Flip');

clickToStart=1;
while (clickToStart) % wait for press
    [x,y,buttons] = GetMouse(Calib.screenNumber);
    if(any(buttons))
        clickToStart=0;
    end
end

errorTestDat=TrackErrorTest(Calib,mOrder);
[MedianEyeError, RawEyeError] = PlotTrackError(mOrder, Calib, errorTestDat);

clickToStart=1;
while (clickToStart) % wait for press
    [x,y,buttons] = GetMouse(Calib.screenNumber);
    if(any(buttons))
        clickToStart=0;
    end
end

return