function [task, list] = Jae2AFCFixed_Eyelink(subID)
%written by M. Kabir for JaeHo Hur. 
%2AFC task adapted from the one designed by Chris
%Glaze. The metahazard, different hazard rates, and separate probability
%distributions simple go unused, here. Instead make sure the multiple
%hazard rates are identical, and that the probability distributions are
%identical. 


%% Housekeeping

%Setting up the screen
sc=dotsTheScreen.theObject;
sc.reset('displayIndex', 1); %change display index to 0 for debug. 1 for full screen. Use >1 for external monitors.
sc.reset('backgroundColor', [110 178 233]);

%Call GetSecs just to load up the Mex files for getting time, so no delays
%later
GetSecs;

%% List Items
list = topsGroupedList();

load('stimPilot_auditory_2AFC_071816.mat')

fixtime = 1.5; %Minimum interstimulus interval (in seconds)
list{'Eyelink'}{'Fixtime'} = fixtime;
list{'Eyelink'}{'SamplingFreq'} = 1000; %Check actual device sampling frequency
        
%Creating our audio player
player = dotsPlayableNote();
player.intensity = 0.01; %Player is loud. Set to small intensity (0.01)
player.frequency = 196.00;
player.duration = 0.3;

% SUBJECT
    list{'Subject'}{'ID'} = subID;

% STIMULUS
    list{'Stimulus'}{'Player'} = player;
    list{'Stimulus'}{'Trials'} = length(stimvc);
    
    %Store HRIR data from our pre-loaded .mat file   
    list{'Stimulus'}{'Counter'} = 0;
    list{'Stimulus'}{'Statelist'} = 0;
    list{'Stimulus'}{'Directionlist'} = stimvc;
    
% TIMESTAMPS
    list{'Timestamps'}{'Stimulus'} = zeros(1,1000); 
    list{'Timestamps'}{'Choices'} = zeros(1,1000);
    
% INPUT
    list{'Input'}{'Choices'} = zeros(1,1000+1); %trials + 1 because you can't actually make a choice on the first trial
       
% EYE TRACKER                   
    screensize = get(0, 'MonitorPositions');
    screensize = screensize(1, [3, 4]);
    centers = screensize/2;
    list{'Eyelink'}{'Centers'} = centers;
    list{'Eyelink'}{'Invalid'} = -32768;
    
    %Setting windows for fixation:
    window_width = 0.3*screensize(1);
    window_height = 0.3*screensize(2);
    
    xbounds = [centers(1) - window_width/2, centers(1) + window_width/2];
    ybounds = [centers(2) - window_height/2, centers(2) + window_height/2];
    
    list{'Eyelink'}{'XBounds'} = xbounds;
    list{'Eyelink'}{'YBounds'} = ybounds;
    
    %List items used for recording
    list{'Eyelink'}{'Playtimes'} = zeros(1,length(stimvc));
    
    
%Functions that act on List
startsave(list); %create a non-redundant savename
%% Input
gp = dotsReadableHIDGamepad(); %Set up gamepad object
gp.deviceInfo
if gp.isAvailable
    % use the gamepad if connected
    ui = gp;
   
    % define movements, which must be held down
    %   map x-axis -1 to left and +1 to right
    isLeft =  [gp.components.ID] == 7;
    isA = [gp.components.ID] == 3;
    isRight = [gp.components.ID] == 8;
    
    Left = gp.components(isLeft);
    A = gp.components(isA);
    Right = gp.components(isRight);
    
    gp.setComponentCalibration(Left.ID, [], [], [0 +7]);
    gp.setComponentCalibration(A.ID, [], [], [0 +8]);
    gp.setComponentCalibration(Right.ID, [], [], [0 +9]);
    
    % undefine any default events
    IDs = gp.getComponentIDs();
    for ii = 1:numel(IDs)
        gp.undefineEvent(IDs(ii));
    end
    
    %Define values for button presses
    gp.defineEvent(Left.ID, 'left', 0, 0, true);
    gp.defineEvent(A.ID, 'continue', 0, 0, true);
    gp.defineEvent(Right.ID, 'right', 0, 0, true);

else

   kb = dotsReadableHIDKeyboard(); %Use keyboard as last resort
    
    % define movements, which must be held down
    %   Left = +2, Up = +3, Right = +4
    isLeft = strcmp({kb.components.name}, 'KeyboardF');
    isSpace = strcmp({kb.components.name}, 'KeyboardSpacebar');
    isRight = strcmp({kb.components.name}, 'KeyboardJ');

    LeftKey = kb.components(isLeft);
    SpaceKey = kb.components(isSpace);
    RightKey = kb.components(isRight);
    
    kb.setComponentCalibration(LeftKey.ID, [], [], [0 +7]);
    kb.setComponentCalibration(SpaceKey.ID, [], [], [0 +8]);
    kb.setComponentCalibration(RightKey.ID, [], [], [0 +9]);
    
    % undefine any default events
    IDs = kb.getComponentIDs();
    for ii = 1:numel(IDs)
        kb.undefineEvent(IDs(ii));
    end
    
    % define events, which fire once even if held down
    % pressing w a d keys is a 'choice' event
    kb.defineEvent(LeftKey.ID, 'left',  0, 0, true);
    kb.defineEvent(SpaceKey.ID, 'continue',  0, 0, true);
    kb.defineEvent(RightKey.ID, 'right',  0, 0, true);
    
ui = kb;
end

    %Making sure the UI is running on the same clock as everything else!
    %Using Operating System Time as absolute clock
    ui.clockFunction = @GetSecs;

    %Storing ui in a List bin to access from functions!
    ui.isAutoRead = 1;
    list{'Input'}{'Controller'} = ui;
    
%% Graphics

    % Fixation point
    fix = dotsDrawableTargets();
    fix.colors = [1 1 1];
    fix.pixelSize = 10;
    fix.isVisible = false;
    
    %Permanent cursor
    permcursor = dotsDrawableTargets();
    permcursor.colors = [0.75 0.75 0.75];
    permcursor.width = 0.3;
    permcursor.height = 0.3;
    permcursor.isVisible = false;
    
    readyprompt = dotsDrawableText();
    readyprompt.string = 'Ready?';
    readyprompt.fontSize = 42;
    readyprompt.typefaceName = 'Calibri';
    readyprompt.isVisible = true;
    
    buttonprompt = dotsDrawableText();
    buttonprompt.string = 'press the A button to get started';
    buttonprompt.fontSize = 24;
    buttonprompt.typefaceName = 'Calibri';
    buttonprompt.y = -2;
    buttonprompt.isVisible = true;
    
    %Graphical ensemble
    ensemble = dotsEnsembleUtilities.makeEnsemble('Fixation Point', false);
    dot = ensemble.addObject(fix);
    perm = ensemble.addObject(permcursor);
    ready = ensemble.addObject(readyprompt);
    button = ensemble.addObject(buttonprompt);
    
    list{'Graphics'}{'Ensemble'} = ensemble;
    list{'Graphics'}{'Dot Index'} = dot;
    list{'Graphics'}{'Perm Index'} = perm;
    
    % tell the ensembles how to draw a frame of graphics
    %   the static drawFrame() takes a cell array of objects
    ensemble.automateObjectMethod(...
    'draw', @dotsDrawable.drawFrame, {}, [], true);

%% Constant Calls

% Read User Interface constant call
readui = topsCallList();
readui.addCall({@read, ui}, 'Read the UI');

%% Runnables  
    %Anonymous functions for use in state lists
    show = @(index) ensemble.setObjectProperty('isVisible', true, index); %show asset
    hide = @(index) ensemble.setObjectProperty('isVisible', false, index); %hide asset
  
    % Prepare machine, for use in antetask
    prepareMachine = topsStateMachine();
    prepList = {'name', 'entry', 'input', 'exit', 'timeout', 'next';
                'Ready', {},      {},      {@waitForCheckKey list},     0,       'Hide';
                'Hide', {hide [ready  button]}, {}, {}, 0, 'Show';
                'Show', {show [perm dot]}, {}, {}, 0, 'Finish'
                'Finish', {}, {}, {}, 0, '';};
    prepareMachine.addMultipleStates(prepList);
            
    % State Machine, for use in maintask
        checkfunc = @(x) checkFixation(x);
    
    Machine = topsStateMachine();
    stimList = {'name', 'entry', 'input', 'exit', 'timeout', 'next';
                'CheckReady', {}, {}, {checkfunc list}, 0, 'Stimulus';
                 'Stimulus', {@playnote list}, {}, {}, 0, 'Rest';
                 'Rest', {@waitForChoiceKey list}, {}, {}, 0, 'Exit'
                 'Exit', {}, {}, {}, 0, ''};
    Machine.addMultipleStates(stimList);
             
    % Concurrent Composites
    conprep = topsConcurrentComposite();
    conprep.addChild(ensemble);
    conprep.addChild(prepareMachine);
    
    contask = topsConcurrentComposite();
    contask.addChild(ensemble);

    contask.addChild(Machine);
    
    % Top Level Runnables    
    antetask = topsTreeNode();
    antetask.addChild(conprep);
    
    maintask = topsTreeNode();
    maintask.addChild(contask);
    maintask.iterations = list{'Stimulus'}{'Trials'};
    
    task = topsTreeNode();
    task.addChild(antetask);
    task.addChild(maintask);

end

%% Accessory Functions

function playnote(list)
    %Adding this iteration to counter
    counter = list{'Stimulus'}{'Counter'};
    counter = counter + 1;
    list{'Stimulus'}{'Counter'} = counter;

    %Importing list items
    player = list{'Stimulus'}{'Player'};
    playtimes = list{'Timestamps'}{'Stimulus'};
    eyeplaytimes = list{'Eyelink'}{'Playtimes'};
    
    %Seeing which direction it should play from this trial
    dirlist = list{'Stimulus'}{'Directionlist'};
    dir = dirlist(counter);
    
    %Play sound
    player.prepareToPlay;
    if dir == 1
        player.waveform = [player.waveform(1,:); zeros(1, length(player.waveform))];
    elseif dir == 2
        player.waveform = [zeros(1, length(player.waveform)); player.waveform(1,:)];
    end
    
    %Play sound
    Eyelink('Message', num2str(mglGetSecs)); %Send timestamp to Eyelink before playing
    player.play;
    
    playtimes(counter) = player.lastPlayTime; %Log audio onset time

    %Record stuff
    list{'Timestamps'}{'Stimulus'} = playtimes;
end
    

function waitForCheckKey(list)
    % Getting list items
    ui = list{'Input'}{'Controller'};
    ui.flushData;
    
    %Initializing variable
    press = '';
  
    %Waiting for keypress
    while ~strcmp(press, 'continue')
        press = '';
        read(ui);
        [a, b, eventname, d] = ui.getHappeningEvent();
        if ~isempty(eventname) && length(eventname) == 1
            press = eventname;
        end
    end
end

function waitForChoiceKey(list)
    % Getting list items
    choices = list{'Input'}{'Choices'};
    counter = list{'Stimulus'}{'Counter'};
    ui = list{'Input'}{'Controller'};
    ui.flushData
    
    %Initializing variable
    press = '';
    
    %Waiting for keypress
    while ~strcmp(press, 'left') && ~strcmp(press, 'right')
        press = '';
        read(ui);
        [a, b, eventname, d] = ui.getHappeningEvent();
        if ~isempty(eventname) && length(eventname) == 1
            press = eventname;
        end
    end
    
    fprintf('Trial %d\n', list{'Stimulus'}{'Counter'})
    
    if strcmp(press, 'left')
        choice = 1;
    elseif strcmp(press, 'right')
        choice = 2;
    else
        choice = NaN;
    end
    
    %Updating choices list
    choices(counter+1) = choice; %counter + 1, because this is a prediction task
    list{'Input'}{'Choices'} = choices;
    
    %Getting choice timestamp
    timestamp = ui.history;
    timestamp = timestamp(timestamp(:, 2) > 3, :); %Just to make sure I get a timestamp from a pressed key/button
    if ~isempty(timestamp)
        timestamp = timestamp(end);
    else
        timestamp = -100;
    end
    
    timestamps = list{'Timestamps'}{'Choices'};
    timestamps(counter) = timestamp;
    list{'Timestamps'}{'Choices'} = timestamps;
end

function startsave(list)
    %creates a viable savename for use outside of function, to save file
    ID = list{'Subject'}{'ID'};
    savename = [ID '_Audio2AFC_list.mat'];
    
    %Checking if file already exists, if so, changes savename by appending
    %a number
    appendno = 1;
    while exist(savename)
        savename = [ID num2str(appendno) '_Audio2AFC_list.mat'];
        appendno = appendno + 1;
    end
    
    list{'Subject'}{'Savename'} = savename;
end
    
function checkFixation(list)
    %Import values
    fixtime = list{'Eyelink'}{'Fixtime'};
    fs = list{'Eyelink'}{'SamplingFreq'};
    invalid = list{'Eyelink'}{'Invalid'};
    xbounds = list{'Eyelink'}{'XBounds'};
    ybounds = list{'Eyelink'}{'YBounds'};
    
    fixms = fixtime*fs; %Getting number of fixated milliseconds needed
    
    %Initializing the structure that temporarily holds eyelink sample data
    eyestruct = Eyelink( 'NewestFloatSample');
    
    fixed = 0;
    while fixed == 0
        %Ensuring eyestruct does not get prohibitively large. 
        %After 30 seconds it will clear and restart. This may cause longer
        %than normal fixation time required in the case that a subject
        %begins fixating close to this 30 second mark. 
        if length(eyestruct) > 30000
            eyestruct = Eyelink( 'NewestFloatSample');
        end
        
        %Adding new samples to eyestruct
        newsample = Eyelink( 'NewestFloatSample');
        if newsample.time ~= eyestruct(end).time %Making sure we don't get redundant samples
            eyestruct(end+1) = newsample;
        end
        
        %Program cannot collect data as fast as Eyelink provides, so it's
        %necessary to check times for samples to get a good approximation
        %for how long a subject is fixating
        endtime = eyestruct(end).time;
        start_idx = find(([eyestruct.time] <= endtime - fixms), 1, 'last');
        
        if ~isempty(start_idx)
            lengthreq = length(start_idx:length(eyestruct));
            start_idx
        else
            lengthreq = Inf;
        end
        
        whicheye = ~(eyestruct(end).gx == invalid); %logical index of correct eye
        
        if sum(whicheye) < 1
            whicheye = 1:2 < 2; %Defaults to collecting from left eye if both have bad data
        end
        
        xcell = {eyestruct.gx};
        ycell = {eyestruct.gy};
        
        xgaze = cellfun(@(x) x(whicheye), xcell);
        ygaze = cellfun(@(x) x(whicheye), ycell);
        
        
        if length(xgaze) >= lengthreq;
            if all(xgaze(start_idx :end)  >= xbounds(1) & ... 
                    xgaze(start_idx :end) <= xbounds(2)) && ...
                    all(ygaze(start_idx :end) >= ybounds(1) & ...
                    ygaze(start_idx :end) <= ybounds(2))
                
                fixed = 1;
                eyestruct = [];
            end
        end
        
    end
    
end

