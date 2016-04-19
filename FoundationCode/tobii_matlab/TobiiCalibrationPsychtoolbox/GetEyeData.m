function GazeData=GetEyeData(StimShownTime, StimEndTime)


[lefteye, righteye, timestamp, ~] = tetio_readGazeData;

if ~tetio_clockSyncState()
    disp('No data collected: Clocks are not synchronized');
    return;
end


numStamps = size(timestamp); %Numer of samples collected
timestamp64 = int64(timestamp); %The function remoteToLocalTime() requires a int64 format

%Convert the timestamps collected to local time

for i=1:numStamps
    remoteToLocalTime(i,1) = tetio_remoteToLocalTime(timestamp64(i,1));
end

[~,startIdx]=min(abs(remoteToLocalTime-int64(StimShownTime*10e5)));
[~,endIdx]=min(abs(remoteToLocalTime-int64(StimEndTime*10e5)));
range=startIdx:endIdx;


GazeData=ParseGazeData(lefteye(range,:), righteye(range,:));


return