function eyedata= TrackErrorTest(Calib,morder)
global EXPWIN
%CALIBRATE calibrate the eye tracker
%   This function is used to set and view the calibration results for the tobii eye tracker.
%
%   Input:
%         Calib: The calib structure (see CalibParams)
%         morder: Order of the calibration point
%         iter: 0/1 (0 = A new calibation call, ensure that calibration is not already started)
%                   (1 = just fixing a few Calibration points)
%         donts: Points (with one in the index) that are to be
%         recalibrated, 0 else where
%   Output:
%         calibPlotData: The calibration plot data, specifying the input and output calibration data

disp('In Tracker Test')
assert(Calib.points.n >= 2 && length(Calib.points.x)==Calib.points.n, ...
    'Err: Invalid Calibration params, Verify...');


validmat = ones(1,Calib.points.n);
step= 15; %shrinking steps (increase for powerful pcs)
Screen('FillRect',EXPWIN,Calib.bkcolor*255);
tetio_readGazeData;
WaitSecs(0.25);

for  i =1:Calib.points.n
    
    %show the big marker
    if (validmat(i)==0)
        continue;
    end
    
    mb = Calib.BigMark;
    ms = Calib.SmallMark;
    %now shrink
    for j = 1:step
        
        bigDotLoc(1) = round(Calib.screen.width*Calib.points.x(morder(i))-mb/2);
        bigDotLoc(2) = round(Calib.screen.height*Calib.points.y(morder(i))-mb/2);
        bigDotLoc(3) = round(Calib.screen.width*Calib.points.x(morder(i))+mb/2);
        bigDotLoc(4) = round(Calib.screen.height*Calib.points.y(morder(i))+mb/2);
        smallDotLoc(1) = round(Calib.screen.width*Calib.points.x(morder(i))-ms/2);
        smallDotLoc(2) = round(Calib.screen.height*Calib.points.y(morder(i))-ms/2);
        smallDotLoc(3) = round(Calib.screen.width*Calib.points.x(morder(i))+ms/2);
        smallDotLoc(4) = round(Calib.screen.height*Calib.points.y(morder(i))+ms/2);
        Screen('FillOval',EXPWIN,Calib.fgcolor*255, bigDotLoc);
        Screen('FillOval',EXPWIN,Calib.fgcolor2*255, smallDotLoc);
        
        mb = mb-ceil((Calib.BigMark - Calib.SmallMark)/step);
        WaitSecs(0.1);
        
        if(j==1);
            Screen(EXPWIN, 'Flip');
            WaitSecs(.75);
        elseif(j==2)
            t1=Screen(EXPWIN, 'Flip');
        else
            Screen(EXPWIN, 'Flip');
        end
    end
    
    t2=Screen(EXPWIN, 'Flip');
    GazeData=GetEyeData(t1, t2);
    eyedata.left(i).xy=[GazeData.left_gaze_point_2d.x GazeData.left_gaze_point_2d.y];
    eyedata.right(i).xy=[GazeData.right_gaze_point_2d.x GazeData.right_gaze_point_2d.y];
    
    %disp(['Point: ' num2str(i)])
    
end


Screen('FillRect',EXPWIN,Calib.bkcolor*255);
Screen(EXPWIN, 'Flip');
disp('Out Tracker Test')

%plot in matlab figure not in psychtoolbox
% figure(1); clf; hold on;
% for  i =1:Calib.points.n
%     plot(eyes.left(i).xy(:,1), eyes.left(i).xy(:,2),'*')
%     plot(eyes.right(i).xy(:,1), eyes.right(i).xy(:,2),'r*')
% 
% end

return