[task list] = AudRTTaskT();

dotsTheScreen.openWindow()
task.run
dotsTheScreen.closeWindow();

%% Post-Processing
savename = list{'Subject'}{'Savename'};
save(savename, 'list');


%Sorting/manipulating data that requires Tobii connection
% Data.EyeTime = list{'Eye'}{'RawTime'};
% Data.EyeTime = int64(Data.EyeTime);
%  
% for i = 1:length(Data.EyeTime)
% Data.EyeTime(i) = tetio_remoteToLocalTime(Data.EyeTime(i));
% end
% 
% list{'Eye'}{'Time'} = Data.EyeTime;
% 
% Data.Playtimes = list{'Stimulus'}{'PlayTimes'}*1e6;
% Data.LEye = list{'Eye'}{'Left'};
% Data.REye = list{'Eye'}{'Right'};
% Data.Statelist = list{'Stimulus'}{'Statelist'};
% Data.Distlist = list{'Stimulus'}{'Distlist'};
% Data.Dirlist = list{'Stimulus'}{'Directionlist'};