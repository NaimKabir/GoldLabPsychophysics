function [task, list] = Audio2AFC(trials)

%% Housekeeping
load 'IRC_CUSTOM_R_HRIR.mat';

%Setting up the screen
sc=dotsTheScreen.theObject;
sc.reset('displayIndex', 0); %change display index to 0 for debug. 1 for full screen. Use >1 for external monitors.
sc.reset('backgroundColor', [110 178 233]);

%Call GetSecs just to load up the Mex files for getting time, so no delays
%later
GetSecs;

%% List Items
list = topsGroupedList();

%Setting important values
metahazard = 0.01;
hazards = [0.3, 0.05];
Adists = [1 0; 0 1];
Bdists = [0.8 0.2; 0.2 0.8];

%Creating our audio player
player = dotsPlayableNote();
player.intensity = 0.01; %Player is loud. Set to small intensity (0.01)
player.frequency = 196.00;
player.duration = 0.3;

% SUBJECT
    list{'Subject'}{'ID'} = input('Subject ID? ', 's');

% STIMULUS
    list{'Stimulus'}{'Player'} = player;
    
    %Store HRIR data from our pre-loaded .mat file
    list{'Stimulus'}{'Filters'} = {l_custom_S, r_custom_S};    

    list{'Stimulus'}{'Counter'} = 0;
    list{'Stimulus'}{'Trials'} = trials;
    list{'Stimulus'}{'Metahazard'} = metahazard;
    list{'Stimulus'}{'Hazards'} = hazards;
    list{'Stimulus'}{'Statelist'} = zeros(1, trials);
    list{'Stimulus'}{'Statespace'} = [1 2];
  
    list{'Stimulus'}{'Directionlist'} = zeros(1, trials);
    
    list{'Stimulus'}{'Dists'} = {Adists, Bdists};
    list{'Stimulus'}{'Distlist'} = zeros(1, trials);
    list{'Stimulus'}{'Distspace'} = [1 2]; %Choose bottom/distribution 

    %Generating sounds
    soundmatrix = tonegen(list);
    soundmatrix(:,:,2) = [];
    list{'Stimulus'}{'Waves'} = soundmatrix; %last argument as 1 is left, 2 is center, 3 is right
    
% TIMESTAMPS
    list{'Timestamps'}{'Stimulus'} = zeros(1,trials); 
    list{'Timestamps'}{'Choices'} = zeros(1,trials);
    
% INPUT
    list{'Input'}{'Choices'} = zeros(1,trials+1); %trials + 1 because you can't actually make a choice on the first trial
       
% EYE TRACKER                   
    list{'Eye'}{'Left'} = [];
    list{'Eye'}{'Right'} = [];
    list{'Eye'}{'Time'} = [];
    list{'Eye'}{'RawTime'} = [];
    list{'Eye'}{'SynchState'} = [];
%% Input
gp = dotsReadableHIDGamepad(); %Set up gamepad object
if gp.isAvailable
    % use the gamepad if connected
    ui = gp;
   
    % define movements, which must be held down
    %   map x-axis -1 to left and +1 to right
    isLeft =  [gp.components.ID] == 7;
    isUp = [gp.components.ID] == 4;
    isRight = [gp.components.ID] == 8;
    
    Left = gp.components(isLeft);
    Up = gp.components(isUp);
    Right = gp.components(isRight);
    
    gp.setComponentCalibration(Left.ID, [], [], [0 +2]);
    gp.setComponentCalibration(Up.ID, [], [], [0 +3]);
    gp.setComponentCalibration(Right.ID, [], [], [0 +4]);
    
    % undefine any default events
    IDs = gp.getComponentIDs();
    for ii = 1:numel(IDs)
        gp.undefineEvent(IDs(ii));
    end
    
    %Define values for button presses
    gp.defineEvent(Left.ID, 'left', 0, 0, true);
    gp.defineEvent(Up.ID, 'up', 0, 0, true);
    gp.defineEvent(Right.ID, 'right', 0, 0, true);

else

   kb = dotsReadableHIDKeyboard(); %Use keyboard as last resort
    
    % define movements, which must be held down
    %   Left = +2, Up = +3, Right = +4
    isLeft = strcmp({kb.components.name}, 'KeyboardF');
    isUp = strcmp({kb.components.name}, 'KeyboardW');
    isRight = strcmp({kb.components.name}, 'KeyboardJ');

    LeftKey = kb.components(isLeft);
    UpKey = kb.components(isUp);
    RightKey = kb.components(isRight);
    
    kb.setComponentCalibration(LeftKey.ID, [], [], [0 +2]);
    kb.setComponentCalibration(UpKey.ID, [], [], [0 +3]);
    kb.setComponentCalibration(RightKey.ID, [], [], [0 +4]);
    
    % undefine any default events
    IDs = kb.getComponentIDs();
    for ii = 1:numel(IDs)
        kb.undefineEvent(IDs(ii));
    end
    
    % define events, which fire once even if held down
    % pressing w a d keys is a 'choice' event
    kb.defineEvent(LeftKey.ID, 'left',  0, 0, true);
    kb.defineEvent(UpKey.ID, 'up',  0, 0, true);
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

% Read eyetracker data constant call
readgaze = topsCallList();
readgaze.addCall({@gazelog, list}, 'Read gaze');

%% Runnables  
    %Anonymous functions for use in state lists
    show = @(index) ensemble.setObjectProperty('isVisible', true, index); %show asset
    hide = @(index) ensemble.setObjectProperty('isVisible', false, index); %hide asset
  
    % Prepare machine, for use in antetask
    prepareMachine = topsStateMachine();
    prepList = {'name', 'entry', 'input', 'exit', 'timeout', 'next';
                'Ready', {@startsave list},      {@waitForPrepKey list},      {},     0,       'Ready';
                'Hide', {hide [ready button]}, {}, {}, 0, 'Show';
                'Show', {show [perm dot]}, {}, {}, 0, 'Finish'
                'Finish', {}, {}, {}, 0, '';};
    prepareMachine.addMultipleStates(prepList);
            
    % State Machine, for use in maintask
    Machine = topsStateMachine();
    stimList = {'name', 'entry', 'input', 'exit', 'timeout', 'next';
                 'Stimulus', {@playnote list}, {}, {}, 0.1, 'Rest';
                 'Rest', {}, {@waitForChoiceKey list}, {}, 0, 'Exit'
                 'Exit', {}, {}, {}, 0.5, ''};
    Machine.addMultipleStates(stimList);
             
    % Concurrent Composites
    conprep = topsConcurrentComposite();
    conprep.addChild(ensemble);
    conprep.addChild(prepareMachine);
    
    contask = topsConcurrentComposite();
    contask.addChild(ensemble);
    %contask.addChild(readgaze);
    contask.addChild(readui);
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
    metahazard = list{'Stimulus'}{'Metahazard'};
    statelist = list{'Stimulus'}{'Statelist'};
    statespace = list{'Stimulus'}{'Statespace'};
    hazards = list{'Stimulus'}{'Hazards'};
    dists = list{'Stimulus'}{'Dists'};
    distlist = list{'Stimulus'}{'Distlist'};
    dirlist = list{'Stimulus'}{'Directionlist'};
    
    %Rolling to see what hazard rate 'state' we're in
    if ~any(statelist) %50/50 diceroll to decide starting state
        roll = rand;
        state(roll > 0.5) = 1;
        state(roll <= 0.5) = 2;
    else %else roll to see hazard rate based on metahazard rate
        last = statelist(counter-1);
        newspace = statespace;
        newspace(newspace==last) = []; %editing statespace to disinclude last
        
        roll = rand;
        state(roll > metahazard) = last; 
        state(roll <= metahazard) = newspace(randi(length(newspace)));
    end
    
    %Updating statelist
    statelist(counter) = state;
    
    %Set hazard according to state
    H = hazards(state);
    
    %Set dists according to state
    dist = dists{state};
    
    if ~any(distlist)
        roll = rand; 
        distchoice(roll > 0.5) = 1;
        distchoice(roll <= 0.5) = 2;
        
        p = dist(distchoice,:); %Effective probability for this trial
    else
        last = distlist(counter - 1);
        newspace = statespace; 
        newspace(newspace == last) = [];
    
        roll = rand;
        distchoice(roll > H) = last; 
        distchoice(roll <= H) = newspace(randi(length(newspace)));
        
        p = dist(distchoice,:);
    end
    
    %Updating Distlist
    distlist(counter) = distchoice;
    
    %Choose sound direction based on probability distribution
    roll = rand;
    dir(roll <= p(1)) = 1;
    dir(roll > p(1)) = 2;
    
    wave = list{'Stimulus'}{'Waves'};
    wave = wave(:,:, dir);
    
    %updating dirlist
    dirlist(counter) = dir;
    
    %Play sound
    player.waveform = wave;
    player.play;
    playtimes(counter) = player.lastPlayTime; %Log audio onset time
    
    %Record stuff
    list{'Stimulus'}{'Statelist'} = statelist;
    list{'Stimulus'}{'Distlist'} = distlist;
    list{'Stimulus'}{'Directionlist'} = dirlist;
    list{'Timestamps'}{'Stimulus'} = playtimes;
end
    

function soundmatrix = tonegen(list)
    %set sampling frequency and duration of our tone
    Fs = 44100;
    duration = 0.3;
    
    dt = 1/Fs; %gives time duration of one element of our array
    N = ceil(duration*Fs); % get elementwise length of our tone
    array = (1:N)*dt; %translate elementwise array into a time stamp array

    %Setting 'pluck' amplitude envelope
    ampenv = exp(-array/(.1*duration))-exp(-array/(.05*duration));
    ampenv = ampenv/max(ampenv); %Normalize
    
    %loading HRIR data
    HRIR = list{'Stimulus'}{'Filters'};
    l_hrir_S = HRIR{1};
    r_hrir_S = HRIR{2};

    %set frequencies
    frequency = [196.00 196.00 196.00];
    
    %Find cutoff point to cut off sound signal, in case it trails off or something
    fraction = 0.75;
    cutoff = ceil(length(array)*fraction);
    
    %Initializing matrix to store sounds
    soundmatrix = zeros(2,cutoff,3);

    %creating sounds and filtering
    for i = 1:3
        note = sin(2*pi*frequency(i)*array(1:cutoff)).*ampenv(1:cutoff); %creating sound with specific frequency
        
        %filtering
        index = find(l_hrir_S.elev_v==0 & l_hrir_S.azim_v == 90*i, 1);
        cLeft = conv(note, l_hrir_S.content_m(index,:)');
        cRight = conv(note, r_hrir_S.content_m(index,:)');
        stored = [cLeft; cRight];
        stored = stored/max(abs(stored(:)));
    
        soundmatrix(:,:,i) = stored(:,1:cutoff);
    end
end

function gazelog(list)
    %Reading gaze
    [lefteye, righteye, timestamp, trigSignal] = tetio_readGazeData;

    %Storing/Organizing data
    if ~isempty(lefteye) || ~isempty(righteye)
    
        leftx = lefteye(:,7); %column 7 is 2D X eye position
        lefty = lefteye(:,8); %column 8 is 2D y eye position
        leftp = lefteye(:,12); %column 12 is eye pupil diameter
        leftv = lefteye(:,13); %this column is validity code

        rightx = righteye(:,7);
        righty = righteye(:,8);
        rightp = righteye(:,12);
        rightv = righteye(:,13);

        list{'Eye'}{'Left'} = [list{'Eye'}{'Left'}; leftx lefty leftp leftv];
        list{'Eye'}{'Right'} = [list{'Eye'}{'Right'}; rightx righty rightp rightv];
        list{'Eye'}{'Time'}= [list{'Eye'}{'Time'}; timestamp];
        list{'Eye'}{'RawTime'} = [list{'Eye'}{'RawTime'}; timestamp];  
        list{'Eye'}{'SynchState'} = [list{'Eye'}{'SynchState'}; tetio_clockSyncState]; 
    end
end

function output = waitForPrepKey(list)

    output = 'Ready';

    % Getting user input
    ui = list{'Input'}{'Controller'};
    ui.flushData
    press = '';
  
    %Waiting for keypress
    read(ui);
    [a, b, eventname, d] = ui.getHappeningEvent();
    if ~isempty(eventname)
        press = eventname;
    end
   
    if strcmp(press, 'left') || strcmp(press, 'right') 
        output = 'Hide';
    end
    
    %Getting choice timestamp
    timestamp = ui.history;
    timestamp = timestamp(timestamp(:, 2) > 1, :); %Just to make sure I get a timestamp from a pressed key/button
    timestamp = timestamp(end);
    
    timestamps = list{'Timestamps'}{'Choices'};
    timestamps(counter) = timestamp;
    list{'Timestamps'}{'Choices'} = timestamps;
            
end

function output = waitForChoiceKey(list)

    output = 'Rest';

    % Getting list items
    choices = list{'Input'}{'Choices'};
    counter = list{'Stimulus'}{'Counter'};
    ui = list{'Input'}{'Controller'};
    ui.flushData
    
    %Initializing some variables
    press = '';
  
    %Waiting for keypress
    read(ui);
    [a, b, eventname, d] = ui.getHappeningEvent();
    list{'Input'}{'Eventname'} = eventname;
    if ~isempty(eventname) && length(eventname) == 1
        press = eventname
    end
   
    if strcmp(press, 'left') || strcmp(press, 'right') 
        output = 'Exit';
    end
       
    if strcmp(press, 'left')
        choice = 1;
    else
        choice = 2;
    end
    
    %Updating choices list
    choices(counter+1) = choice;
    list{'Input'}{'Choices'} = choices;
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