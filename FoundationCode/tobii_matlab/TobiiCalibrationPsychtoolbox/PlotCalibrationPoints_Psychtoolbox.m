function [pts, TrackError] = PlotCalibrationPoints_Psychtoolbox(calibPlot, mOrder, Calib)
%PLOTCALIBRATIONPOINTS plots the calibration data for a calibration session
%   Input:
%         calibPlot: The calibration plot data, specifying the input and output calibration data
%         Calib: The calib config structure (see SetCalibParams)
%         mOrder: Vector containing indices indicating the order in which to show the calibration points, [1 2 3 4 5] to show five calibration points in order or [1 3 5 2 4] to show them in different order.
%
%   Output:
%         pts: The list of points used for calibration. These could be
%         further used for the analysis such as the variance, mean etc.
global EXPWIN BLACK

Lx_delta=[]; Ly_delta=[]; Rx_delta=[];
Ry_delta=[]; Rxy_dist =[]; Lxy_dist=[];
%degree symbol
s = sprintf('%c', char(176));

NumCalibPoints = length(calibPlot)/8;
if (NumCalibPoints == 0 )
    pts = [];
    disp('no calib point found');
    return;
end
clear OriginalPoints
clear pts
j = 1;
for i = 1:NumCalibPoints
    OriginalPoints(i,:) = [calibPlot(j) calibPlot(j+1)];
    j = j+8;
end

lp = unique(OriginalPoints,'rows');
for i = 1:length(lp)
    pts(i).origs = lp(i,:);
    pts(i).point =[];
end

j = 1;
for i = 1:NumCalibPoints
    for k = 1:length(lp)
        if ((calibPlot(j)==pts(k).origs(1)) && (calibPlot(j+1)==pts(k).origs(2)))
            n = size(pts(k).point,2);
            pts(k).point(n+1).validity = [calibPlot(j+4) calibPlot(j+7)];
            pts(k).point(n+1).left= [calibPlot(j+2) calibPlot(j+3)];
            pts(k).point(n+1).right= [calibPlot(j+5) calibPlot(j+6)];
        end
    end
    j = j+8;
end


figloc(1) =  Calib.screen.x - Calib.screen.width/4;
figloc(2) =  Calib.screen.y - Calib.screen.height/4;
figloc(3) =  Calib.screen.x + Calib.screen.width/4;
figloc(4) =  Calib.screen.y + Calib.screen.height/4;

Screen('FillRect',EXPWIN,Calib.bkcolor);

for i = 1:length(lp)
    dotLoc(1) = Calib.screen.width*pts(i).origs(1) - (Calib.SmallMark);
    dotLoc(2) = Calib.screen.height*pts(i).origs(2) - (Calib.SmallMark);
    dotLoc(3) = Calib.screen.width*pts(i).origs(1) +(Calib.SmallMark);
    dotLoc(4) = Calib.screen.height*pts(i).origs(2) + (Calib.SmallMark);
    Screen('FillOval',EXPWIN,Calib.fgcolor, dotLoc);
    
    %plot the numbers next to each point
    for n = 1:Calib.points.n
        a = strcmp(num2str(pts(i).origs(1)),num2str(Calib.points.x(mOrder(n))));
        b = strcmp(num2str(pts(i).origs(2)),num2str(Calib.points.y(mOrder(n))));
        if ( a && b)
            px = Calib.screen.width*pts(i).origs(1)+20;
            py = Calib.screen.height*pts(i).origs(2)-20;
            Screen('TextSize', EXPWIN , 30);
            Screen('DrawText', EXPWIN, num2str(mOrder(n)),px, py, BLACK);
        end
    end
    
    
    
    %calibration only uses validity ==1,
    %validity==0 good data not used, valditity==-1, bad data, not used
    %see page 32 in tobii sdk manual
    
    for j = 1:size(pts(i).point,2)
        if (pts(i).point(j).validity(2)==1) %good validity right eye
            Screen('TextSize', EXPWIN , 12);
            Screen('DrawText', EXPWIN, 'o',Calib.screen.width*pts(i).point(j).right(1), ...
                Calib.screen.height*pts(i).point(j).right(2), [255 0 0]);
            %determine distance from eye to calib point
            Rx_delta(j)=Calib.screen.width*pts(i).point(j).right(1)-Calib.screen.width*pts(i).origs(1);
            Ry_delta(j)=Calib.screen.width*pts(i).point(j).right(2)-Calib.screen.width*pts(i).origs(2);
            
        end
        if (pts(i).point(j).validity(1)==1) %good validity left eye
            Screen('TextSize', EXPWIN , 12);
            Screen('DrawText', EXPWIN, 'o',Calib.screen.width*pts(i).point(j).left(1), ...
                Calib.screen.height*pts(i).point(j).left(2), [0 255 0]);
            %determine distance from eye to calib point
            Lx_delta(j)=Calib.screen.width*pts(i).point(j).left(1)-Calib.screen.width*pts(i).origs(1);
            Ly_delta(j)=Calib.screen.width*pts(i).point(j).left(2)-Calib.screen.width*pts(i).origs(2);
            
        end
        
        %arrays to easily check x,y
        %r_eye(j,:)=[pts(i).point(j).right pts(i).point(j).validity(2)];
        %l_eye(j,:)=[pts(i).point(j).left  pts(i).point(j).validity(1)];
        
        
    end
    %Calculate mean & standard dev. of visual angle error in track signal
    Rxy_dist=sqrt(Rx_delta.^2+Ry_delta.^2)*Calib.screen.degperpix;
    Lxy_dist=sqrt(Lx_delta.^2+Ly_delta.^2)*Calib.screen.degperpix;
    err_stat= sprintf('%.2f%s +/-%.2f%s', mean([Rxy_dist Lxy_dist]), s, std([Rxy_dist Lxy_dist]),s );
    Screen('DrawText', EXPWIN, err_stat,px-85, py-40, BLACK );
    TrackError(i,:)=[mean([Rxy_dist Lxy_dist]) std([Rxy_dist Lxy_dist])];
    
end

DrawFormattedText(EXPWIN,'Accept calibration? [y]/n','Center',Calib.screen.height/4, BLACK);
DrawFormattedText(EXPWIN,'Tracker mean accuracy is shown for each point with +/- std. deviation','Center',Calib.screen.height/3, BLACK);

Screen('Flip', EXPWIN,[]);
end
