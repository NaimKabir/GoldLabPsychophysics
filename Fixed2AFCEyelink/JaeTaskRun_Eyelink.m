%% Run Jae2AFCFixed --WITH EYELINK!

[subID, EDFfilename] = MKEyelinkCalibrate();


[task, list] = Jae2AFCFixed_Eyelink(subID);

dotsTheScreen.openWindow();
task.run
dotsTheScreen.closeWindow();

%% Saving Eyelink Data File
%Close file, stop recording
    Eyelink('StopRecording');
    Eyelink('CloseFile');

    try
        fprintf('Receiving data file ''%s''\n', EDFfilename );
        status=Eyelink('ReceiveFile');
        if status > 0
            fprintf('ReceiveFile status %d\n', status);
        end
        if 2==exist(EDFfilename, 'file')
            fprintf('Data file ''%s'' can be found in ''%s''\n', EDFfilename, pwd );
        end
    catch rdf
        fprintf('Problem receiving data file ''%s''\n', EDFfilename );
        rdf;
    end


%% Post-Processing

%Sorting/manipulating data that requires Tobii connection
% 
% Data.EyeTime = list{'Eye'}{'RawTime'};
% 
% Data.EyeTime = int64(Data.EyeTime);
% 
% for i = 1:length(Data.EyeTime)
% 
% Data.EyeTime(i) = tetio_remoteToLocalTime(Data.EyeTime(i));
% 
% end
% 
% list{'Eye'}{'Time'} = Data.EyeTime;
% 
% Data.EyeL = list{'Eye'}{'Left'};
% Data.EyeR = list{'Eye'}{'Right'};
% Data.RawTime = list{'Eye'}{'RawTime'};

Data.Choices = list{'Input'}{'Choices'};
Data.ChoiceTimes = list{'Timestamps'}{'Choices'};
Data.StimTimes = list{'Timestamps'}{'Stimulus'};
Data.StimList = list{'Stimulus'}{'Directionlist'}; 
Data.StateList = list{'Stimulus'}{'Statelist'};   

%% Saving

save(list{'Subject'}{'Savename'},'list')
save(['Data_' list{'Subject'}{'Savename'}], 'Data') 

    Eyelink('Shutdown');