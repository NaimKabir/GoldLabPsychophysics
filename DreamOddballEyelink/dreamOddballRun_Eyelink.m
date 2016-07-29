%dreamOddballRun
clear all, close all;

[subID, EDFfilename] = MKEyelinkCalibrate();

%%

[task, list] = dreamOddballConfig_Eyelink(0,0,1, subID);
%First argument is whether distractor is on(1) or off(0),
%Second argument is whether adapative difficulty is on(1) or off(0),
%Third argument is whether button is pressed for odd frequencies (0) or for
%standard frequencies(1)

dotsTheScreen.openWindow();
task.run
dotsTheScreen.closeWindow();

%% Saving Eyelink Data File
%Close file, stop recording
    Eyelink('StopRecording');
    Eyelink('CloseFile');

    try
        fprintf('Receiving data file ''%s''\n', EDFfilename );
        status=Eyelink('ReceiveFile', EDFfilename);
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

Data.StandardFreq = list{'Stimulus'}{'StandardFreq'};
Data.OddFreq = list{'Stimulus'}{'OddFreq'};
Data.ProbabilityOdd = list{'Stimulus'}{'ProbabilityOdd'};
Data.ResponsePattern = list{'Input'}{'ResponsePattern'}; 
Data.MotorEffort = list{'Input'}{'Effort'};
Data.StimTimestamps = list{'Stimulus'}{'Playtimes'}; %Store sound player timestamps 
Data.StimFrequencies = list{'Stimulus'}{'Playfreqs'};
Data.Choices = list{'Input'}{'Choices'}; %Storing if subject pressed the buttons required
Data.Corrects = list{'Input'}{'Corrects'}; %Storing correctness of answers. Initialized to 33 so we know if there was no input during a trial with 33.
Data.ChoiceTimestamps = list{'Timestamps'}{'Response'}; %Storing subject response timestamp

%% Saving

save([list{'Subject'}{'Savename'} '.mat'],'list')
save([ list{'Subject'}{'Savename'} '_Data' '.mat'], 'Data') 

Eyelink('Shutdown');