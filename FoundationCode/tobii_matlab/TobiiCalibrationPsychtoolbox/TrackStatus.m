function TrackStatus(Calib)
%TrackStatus script. Will show one dot per eye when the user positions himself in front of the eye tracker.
%Use spacebar (or any other) key press to continue.
%   Input:
%         Calib: The calib config structure (see SetCalibParams)

%global CENTER
global KEYBOARD SPACEKEY EXPWIN BLACK

Screen('FillRect',EXPWIN,Calib.bkcolor);

if Calib.resize
    figloc(1) =  round(Calib.screen.x + Calib.screen.width/4);
    figloc(2) =  round(Calib.screen.y + Calib.screen.height/4);
    figloc(3) =  round(Calib.screen.width - Calib.screen.width/4);
    figloc(4) =  round(Calib.screen.height - Calib.screen.height/4);
    
    figlocWidth = figloc(3) - figloc (1);
    figlocHeight = figloc(4) - figloc (2);
    
else
    figloc(1) =  Calib.screen.x;
    figloc(2) =  Calib.screen.y;
    figloc(3) =  Calib.screen.width;
    figloc(4) =  Calib.screen.height;
end


Screen('FillRect',EXPWIN,[0 0 100], figloc);
Screen(EXPWIN, 'Flip');

updateFrequencyInHz = 60;

tetio_startTracking;

pause(1)

while 1
    
    pause(1/updateFrequencyInHz);
    
    [lefteye, righteye] = tetio_readGazeData;
    
    
    if (isempty(lefteye) || isempty(righteye) )
        Screen('FillRect',EXPWIN,[0 0 100], figloc);
        DrawFormattedText(EXPWIN, 'Eyes not detected. Reposition Participant',...
            'Center', Calib.screen.height*.2,BLACK);
        Screen(EXPWIN, 'Flip');
        continue;
    end
    
    GazeData = ParseGazeData(lefteye(end,:), righteye(end,:)); % Parse last gaze data.
    
    %Calculate participant's distance to ET
    if lefteye((end),3) > 0 && righteye((end),3) > 0
        ET_Distance = round(((lefteye((end),3) + righteye((end),3))/2)/10);
    elseif lefteye((end),3) == 0 && righteye((end),3) > 0
        ET_Distance = round(righteye((end),3)/10);
    elseif lefteye((end),3) > 0 && righteye((end),3) == 0
        ET_Distance = round(lefteye((end),3)/10);
    else
        ET_Distance = [];
    end
    
    
    %draw eyes
    %decide color for indication of validity
    % These color scheme & code is taken from the Talk2Tobii software
    % http://www.cbcd.bbk.ac.uk/people/affiliated/fani/talk2tobii
    % developed by Fani Deligianni
    
    switch GazeData.left_validity
        case 0,
            Left_eyeDotColor = [0 255 0];
        case 1,
            Left_eyeDotColor = [64 192 0];
        case 2,
            Left_eyeDotColor = [128 128 0];
        case 3,
            Left_eyeDotColor = [192 64 0];
        otherwise,
            Left_eyeDotColor = [255 0 0];
    end
    
    switch GazeData.right_validity
        case 0,
            Right_eyeDotColor = [0 255 0];
        case 1,
            Right_eyeDotColor = [64 192 0];
        case 2,
            Right_eyeDotColor = [128 128 0];
        case 3,
            Right_eyeDotColor = [192 64 0];
        otherwise,
            Right_eyeDotColor = [255 0 0];
    end
    
    %[GazeData.left_validity GazeData.right_validity]
    
    validLeftEyePos = GazeData.left_validity <= 2;
    validRightEyePos = GazeData.right_validity < 2; % If both left and right validities are 2 then only draw left.
    Screen('FillRect',EXPWIN,[0 0 100], figloc)
    if ~isempty(ET_Distance)
        DrawFormattedText(EXPWIN, ['Tracker Distance: ' int2str(ET_Distance) 'cm'],...
            'Center', Calib.screen.height*.2,BLACK);
    end
    
    
    DrawFormattedText(EXPWIN,...
        'Make sure eyes are visibile and stable green. Press space to start calibration',...
        'Center',Calib.screen.height*.8, BLACK);
    
    if validLeftEyePos || validRightEyePos
        if validLeftEyePos
            sLeft(1) = (1-GazeData.left_eye_position_3d_relative.x) * figlocWidth + figlocWidth/2- 15 ;
            sLeft(2) = GazeData.left_eye_position_3d_relative.y * figlocHeight + figlocHeight/2  - 15 ;
            sLeft(3) = (1-GazeData.left_eye_position_3d_relative.x) * figlocWidth + figlocWidth/2 + 15 ;
            sLeft(4) = GazeData.left_eye_position_3d_relative.y * figlocHeight + figlocHeight/2 + 15;
            
            Screen('FillOval',EXPWIN,Right_eyeDotColor, sLeft);
        end
        
        if validRightEyePos
            sRight(1) = (1-GazeData.right_eye_position_3d_relative.x) * figlocWidth + figlocWidth/2 - 15 ;
            sRight(2) = GazeData.right_eye_position_3d_relative.y * figlocHeight + figlocHeight/2 - 15 ;
            sRight(3) = (1-GazeData.right_eye_position_3d_relative.x) * figlocWidth + figlocWidth/2 + 15 ;
            sRight(4) = GazeData.right_eye_position_3d_relative.y * figlocHeight + figlocHeight/2 + 15;
            
            Screen('FillOval',EXPWIN,Left_eyeDotColor, sRight);
        end
        
        %Screen('DrawingFinished',EXPWIN);
        Screen(EXPWIN, 'Flip');
    end
    
%     [~,~,keyCode]=PsychHID('KbCheck', KEYBOARD);
    [keyIsDown, secs, keyCode] = KbCheck();
    if keyCode(SPACEKEY)
        break;
    end
    
end

tetio_stopTracking;
end
