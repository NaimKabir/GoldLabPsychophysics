%dreamOddballRun
[subID, EDFfilename] = MKEyelinkCalibrate();

[task, list] = dreamOddballConfig(0,0,0, subID);
%First argument is whether distractor is on(1) or off(0),
%Second argument is whether adapative difficulty is on(1) or off(0),
%Third argument is whether button is pressed for odd frequencies (1) or for
%standard frequencies(0)

dotsTheScreen.openWindow();
task.run
dotsTheScreen.closeWindow();

%% Post processing
%Getting synchronized times
%Sorting/manipulating data that requires Tobii connection


%% Saving data
