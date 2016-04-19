function [MedianTrackError, RawTrackError]= ...
    PlotTrackError(mOrder, Calib, testData)
%PLOTCALIBRATIONPOINTS plots the calibration data for a calibration session
%   Input:
%         calibPlot: The calibration plot data, specifying the input and output calibration data
%         Calib: The calib config structure (see SetCalibParams)
%         mOrder: Vector containing indices indicating the order in which to show
%the calibration points, [1 2 3 4 5] to show five calibration points in order or [1 3 5 2 4] to show them in different order.
%
%   Output:
%         pts: The list of points used for calibration. These could be
%         further used for the analysis such as the variance, mean etc.
global EXPWIN BLACK

Lx_delta=[]; Ly_delta=[]; Rx_delta=[]; Ry_delta=[];
%degree symbol
s = sprintf('%c', char(176));
Screen('FillRect',EXPWIN,Calib.bkcolor*255);
Screen('TextSize', EXPWIN , 12);

% figure(1); clf; hold on;
% for j =1:Calib.points.n
%     plot(testData.left(j).xy(:,1), testData.left(j).xy(:,2),'*')
%     plot(testData.right(j).xy(:,1), testData.right(j).xy(:,2),'r*')
% end

for i = 1:length(Calib.points.x)
    %alter the data streams dependent on whether it was from the calibration
    %or from a retest
    ldat=testData.left(i).xy; rdat=testData.right(i).xy;
    calib_pt_x=Calib.screen.width*Calib.points.x(mOrder(i));
    calib_pt_y=Calib.screen.height*Calib.points.y(mOrder(i));
    reye=[Calib.screen.width*rdat(:,1) Calib.screen.height*rdat(:,2)];
    leye=[Calib.screen.width*ldat(:,1) Calib.screen.height*ldat(:,2)];
    
    dotLoc(1) = calib_pt_x - Calib.SmallMark;
    dotLoc(2) = calib_pt_y - Calib.SmallMark;
    dotLoc(3) = calib_pt_x + Calib.SmallMark;
    dotLoc(4) = calib_pt_y + Calib.SmallMark;
    
    for j=1:length(reye)
        Screen('DrawText', EXPWIN, 'o',reye(j,1), reye(j,2), [255 0 0]);
    end
    
    Rx_delta=reye(:,1)-calib_pt_x;
    Ry_delta=reye(:,2)-calib_pt_y;
    
    for j=1:length(leye)
        Screen('DrawText', EXPWIN, 'o',leye(j,1), leye(j,2), [0 255 0]);
    end
    
    Lx_delta=leye(:,1)-calib_pt_x;
    Ly_delta=leye(:,2)-calib_pt_y;
    
    %NOTE this -1,-1 xy data is indicative of track loss, but you could also
    %use validity data. see tobii sdk manual pg.18. in data analysis
    %Values 0 & 1 are good, 2-4 are usually bad data
    
    Leye_TrackLoss=sum(ldat(:,1)==-1)/length(ldat);
    Reye_TrackLoss=sum(rdat(:,1)==-1)/length(rdat);
   
    %Calculate mean & standard dev. of visual angle error in track signal
    Rxy_dist=sqrt(Rx_delta.^2+Ry_delta.^2)*Calib.screen.degperpix;
    Lxy_dist=sqrt(Lx_delta.^2+Ly_delta.^2)*Calib.screen.degperpix;
    err_stat= sprintf('%0.2f%s +/-%0.2f%s', median( (Rxy_dist+Lxy_dist)/2), s, ...
        std( (Rxy_dist+Lxy_dist)/2),s );
    Screen('DrawText', EXPWIN, err_stat, calib_pt_x-85, calib_pt_y-70, BLACK );
    err_stat= sprintf('L-Loss %0.2f, R-Loss %0.2f', Leye_TrackLoss,Reye_TrackLoss);
    Screen('DrawText', EXPWIN, err_stat, calib_pt_x-185, calib_pt_y-40, BLACK );

    RawTrackError(i).Left=Rxy_dist;
    RawTrackError(i).Right=Lxy_dist;
    
    MedianTrackError.Left(i,:)=[median(Lxy_dist) std(Lxy_dist)];
    MedianTrackError.Right(i,:)=[median(Rxy_dist) std(Rxy_dist)];
    Screen('FillOval',EXPWIN,Calib.fgcolor*255, dotLoc); 
    
end


DrawFormattedText(EXPWIN,'Click mouse to continue...','Center',...
    Calib.screen.height/4, [255 255 255]);
DrawFormattedText(EXPWIN,'Median binocular accuracy (L+R)/2 is shown with +/- std. dev.','Center',Calib.screen.height/4, BLACK);
DrawFormattedText(EXPWIN,'R & L Loss are the percent of samples indicating track loss, (-1,-1)','Center',Calib.screen.height/3, BLACK);

Screen('Flip', EXPWIN,[]);

end
