%% Fusion script

%Access pupilsize samples: edf.Samples.pupilSize
%Access time: edf.Samples.time
%Access stimtimes: 
%        synchidx = find(strcmp(edf1.Events.Messages.info, 'SYNCTIME'))
%        stimtimes_Eye = edf1.Events.Messages.time(synchidx+1 : end)

%Pretend that filenames for first sessions actually have a 0 next to their
%name.
clear all; close all;

edf_files = dir('*.edf');

for i = 1:length(edf_files)
    edffile = edf_files(i).name; %Getting a filename
    loc_edf = Edf2Mat(edffile); %Getting edf in mat format called loc_edf
    
    edffile = edffile(1:end-4); %to capture ID without filetype
    
    %Collecting only .mat files with correct subject ID, both a list and a
    %Data .mat
    mat_files = dir([edffile '*.mat']);
    
    load(mat_files(1).name); %Load the 'list' structure, now a workspace variable
    load(mat_files(end).name); %Load the 'Data' structure. Data is now a local variable
    
    %Getting stimtimes and adding to data structure
    synchidx = find(strcmp(loc_edf.Events.Messages.info, 'SYNCTIME'));
    Data.eyelinkStimTimes = loc_edf.Events.Messages.time(synchidx+1 : end);
    
    %Getting pupilsize and adding to data structure
    Data.pupilDiameter = loc_edf.Samples.pupilSize;
    Data.pupilArea = loc_edf.Samples.pa;
    
    %Getting XY gaze coordinates
    Data.pupilX = loc_edf.Samples.gx;
    Data.pupilY = loc_edf.Samples.gy;
    
    %Getting sample timestamps
    Data.eyelinkTimeStamps = loc_edf.Samples.time;
    
    save(['0Fused_' edffile '_2AFC.mat'], 'Data')
end

