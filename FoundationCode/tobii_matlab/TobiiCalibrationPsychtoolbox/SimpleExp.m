numberTrials=1;


for trial=1:numberTrials
    
    tetio_readGazeData;
    disp(['Start Trial: ' trial])
    Screen('FillRect',EXPWIN,BLACK);
    
    %this would be where your experimental stimulus, task, main loop etc would go
    %we'll just wait and get a little eye tracking data.
    
    screentime=[];
    trial_exit=0;
    
    while(~trial_exit)
        
        DrawFormattedText(EXPWIN,'Read this text. The tracking data will be saved to a .mat file after 5s','Center',...
            Calib.screen.height/3, [255 255 255]);
        screentime(end+1)=Screen(EXPWIN,'Flip');
        
        if( (screentime(end)-screentime(1)) > 5 )
            trial_exit=1;
        end
    end
    
    
    GazeData=GetEyeData(screentime(1), screentime(end));
end


save('eyegaze_sample.mat', 'GazeData')
Screen('FillRect',EXPWIN,BLACK);
DrawFormattedText(EXPWIN,'Tracking data captured..Exiting','Center',...
    Calib.screen.height/3, [255 255 255]);
Screen(EXPWIN,'Flip');
WaitSecs(1.5)

