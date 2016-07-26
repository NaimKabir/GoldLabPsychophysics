function BitsPlusImagingPipelineTest(whichScreen, plotdiffs, forcesuccess, winrect, bitsSharpPortName, acceptableerror)
% BitsPlusImagingPipelineTest([whichScreen=max][,plotdiffs=0][, forcesuccess=0][, winrect=[]][, bitsSharpPortName][, acceptableerror=1])
%
% Tests correct function of Mono++ and Color++ mode with imaging pipeline...
% This test script needs to be run once after each graphics card or
% graphics driver or Psychtoolbox upgrade. 
%
% This test tests if the Psychtoolbox image processing pipeline is capable
% to correctly convert a high dynamic range image for the Cambridge
% Research Systems Bits++ / Bits# box for Mono++ and Color++ mode. This
% test script can be also used to verify proper operation with VPixx Inc.
% devices like the DataPixx, ViewPixx, and ProPixx, as they expect the same
% type of color encoding of pixeldata as the devices from CRS.
%
% It does so by generating a test stimulus, converting it into a Bits++
% image via the Matlab BitsPlusPlus toolbox and by use of the imaging
% pipeline. Then it reads back and compares the conversion results of both
% to verify that the imaging pipeline produces exactly the same results
% as the Matlab routines.
%
% If the results are the same, it will write some info file to the
% filesystem to confirm this test was successfully run.
%
% Optional parameters:
%
% whichScreen  = Screen id of display to test on. Will be the secondardy
%                display if none provided.
%
% plotdiffs    = If set to one, plot diagnostic difference images, if any
%                differences are detected. By default no such images are plotted. No
%                images will be plotted if no differences exist.
%
% forcesuccess = Set this to one if you want to force the test to succeed,
%                despite detected errors, ie., if you want the GPU
%                conversion to be used. Only use this if you really know
%                what you are doing!
%
% winrect = Optional placement rectangle for window. Defaults to fullscreen.
%
% bitsSharpPortName = Optional name of the serial port to which a Bits# device
%                     is connected. If omitted, the portName will be fetched
%                     from the global Bits# config file, or auto-detected.
%
% acceptableerror = Maximum acceptable error in absolute output intensity
%                   difference. Differences less than this value are
%                   considered a successful "pass" of the test by the GPU.
%                   The default is 1, ie., 1 unit out of 65535. On CRS
%                   Bits+ and Bits# this would cause no measureable error,
%                   as these devices only use 14 bits of the 16 bit range,
%                   ie., an error in the least significant bit of intensity
%                   won't show up anyway. On VPixx Data/View/ProPixx
%                   devices, the error will be so small that it will just
%                   disappear in the noise/error caused by other sources of
%                   error, e.g., inaccurate display calibration or gamma
%                   correction, lighting conditions, variation in display
%                   hardware due to operating temperature, voltage
%                   fluctuations etc. The default setting of 1 should be
%                   perfectly fine, even higher values (maybe up to 10)
%                   would be ok in practice.
%
% Please note that this test script can only test if the correct output to
% your systems framebuffer is generated by Psychtoolbox. It can't detect if
% the Bits++ box itself is working correctly with this data. Only visual
% inspection and a photometer/colorimeter test can really tell you if the
% whole system is working correctly!

answer = input('Test with DataPixx/ViewPixx/ProPixx (d), Bits+ (b) or Bits# (s)? ', 's');
if answer == 'd'
    % Tell BitsPlusPlus driver that this is operating on a DataPixx:
    BitsPlusPlus('SetTargetDeviceType', 1);
else
    % Tell BitsPlusPlus driver that this is operating on a Bits+ or Bits# :
    BitsPlusPlus('SetTargetDeviceType', 0);
end

% If it is a Bits#, open a connection to it:
if answer == 's'
    if nargin < 5
        bitsSharpPortName = [];
    end

    BitsPlusPlus('OpenBits#', bitsSharpPortName);
end

oldverbosity = Screen('Preference', 'Verbosity', 2);
oldsynclevel = Screen('Preference', 'SkipSyncTests', 2);

% Define screen:
if nargin < 1 || isempty(whichScreen)
    whichScreen=max(Screen('Screens'));
end

if nargin < 2 || isempty(plotdiffs)
    plotdiffs = 0;
end

if nargin < 3 || isempty(forcesuccess)
    forcesuccess = 0;
end

if nargin < 4
    winrect = [];
end

% Default to 1 absolute intensity unit of acceptable error, if none
% specified:
if nargin < 6 || isempty(acceptableerror)
    acceptableerror = 1;
end

% Generate a synthetic grating that covers the whole
% color intensity range from 0 to 16384, mapped to the 0.0 - 1.0 range:
theImage=zeros(256,256,3);
theImage(:,:,1)=reshape(double(linspace(0, 2^16 - 1, 2^16)), 256, 256)' / (2^16 - 1);
theImage(:,:,2)=theImage(:,:,1);
theImage(:,:,3)=theImage(:,:,1);

% Convert input image via Bits++ toolbox routines (Matlab code):
fprintf('Converting test stim to color++ format\n');
packedImage = BitsPlusPackColorImage(theImage, 0, 1);

% Show the image

% Make sure we run with our default color correction mode for this test:
% 'ClampOnly' is the default, but we set it here explicitely, so no state
% from previously running scripts can bleed through:
PsychColorCorrection('ChooseColorCorrection', 'ClampOnly');

% Open a double buffered fullscreen window with black background, configured for the Bits++
% Color++ Mode, i.e., with proper setup of imaging pipeline and conversion shaders:
BitsPlusPlus('ForceUnvalidatedRun');

% The correctness test for Color++/C48 mode is written for classic mode,
% ie., mode 0, so request that:
BitsPlusPlus('SetColorConversionMode', 0);
[window, screenRect] = BitsPlusPlus('OpenWindowColor++', whichScreen, 0, winrect);

% Build HDR texture: 
hdrtexIndex= Screen('MakeTexture', window, theImage, [], [], 2);

% Draw HDR image via imaging pipeline:

% Enable Bits++ Color++ output formatter:
Screen('HookFunction', window, 'Enable', 'FinalOutputFormattingBlit');

% Draw Color++ image as generated by PTB GPU imaging pipeline:
dstRect = Screen('Rect', hdrtexIndex);
Screen('DrawTexture',window,hdrtexIndex, [], dstRect, [], 0);

% Finalize image before we take a screenshot:
Screen('DrawingFinished', window, 0, 1);

% Scanning pattern for testing for possible offsets between rasterization
% path and readback path due to graphics driver bugs. We start with the
% most likely hypothesis [0 ; 0] aka no offsets:
spo = [ 0, -1, -1, -1,  0,  0, +1, +1, +1 ; ...  
        0, -1,  0, +1, -1, +1, -1,  0, +1];

fprintf('\n\n');
    
for idx = 1:size(spo, 2)
    dx = spo(1, idx);
    dy = spo(2, idx);
    
    % Take screenshot of GPU converted image:
    convImage=Screen('GetImage', window, OffsetRect(ScaleRect(dstRect, 2, 1), dx, dy),'backBuffer');

    % Compute difference images between Matlab converted packedImage and GPU converted
    % HDR image:
    diffred   = abs(double(packedImage(:,:,1)) - double(convImage(:,:,1)));
    diffgreen = abs(double(packedImage(:,:,2)) - double(convImage(:,:,2)));
    diffblue  = abs(double(packedImage(:,:,3)) - double(convImage(:,:,3)));

    % Compute maximum deviation of framebuffer raw data:
    mdr = max(max(diffred));
    mdg = max(max(diffgreen));
    mdb = max(max(diffblue));

    fprintf('ReadbackOffset (%i, %i): Maximum raw data difference: red= %f green = %f blue = %f\n', dx, dy, mdr, mdg, mdb);

    % Perfect results?
    if ((mdr == 0) && (mdg == 0) && (mdb == 0))
        % Yep. Done!
        break;
    end

    % If there is a difference, show plotted difference if requested:
    if (mdr>0 || mdg>0 || mdb>0) && plotdiffs
        % Differences detected!
        close all;
        imagesc(diffred);
        title('Undecoded pixel error in red channel (even/odd cols = high/low 8-Bits):');
        figure;
        imagesc(diffgreen);
        title('Undecoded pixel error in green channel (even/odd cols = high/low 8-Bits):');
        figure;
        imagesc(diffblue);
        title('Undecoded pixel error in blue channel (even/odd cols = high/low 8-Bits):');
    end

    if (mdr>0 || mdg>0 || mdb>0)
        % Now compute a more meaningful difference: The difference between the
        % stimulus as the Bits++ box would see it (i.e. how much do the 16 bit
        % intensity values of each color channel differ?):
        convImage = double(convImage);
        packedImage = double(packedImage);

        % For each color channel do...
        for c=1:3
            % Invert conversion: Compute 16 bpc color values from high/low byte
            % pixel data:
            deconvImage = (zeros(size(convImage,1), size(convImage,2)/2));
            deconvImage(:,:) = 256 * convImage(:, 1:2:end-1, c) + convImage(:, 2:2:end, c);

            depackImage = (zeros(size(packedImage,1), size(packedImage,2)/2));
            depackImage(:,:) = 256 * packedImage(:, 1:2:end-1, c) + packedImage(:, 2:2:end, c);

            % Difference image:
            diffImage = (deconvImage - depackImage);

            % Find locations where pixels differ:
            idxdiff = find(abs(diffImage) > 0);
            numdiff(c) = length(idxdiff); %#ok<AGROW>
            numtot(c) = size(diffImage,1)*size(diffImage,2); %#ok<AGROW>
            maxdiff(c) = max(max(abs(diffImage))); %#ok<AGROW>
            [row col] = ind2sub(size(diffImage), idxdiff);

            % Print out all pixels values which differ, and their difference:
            if plotdiffs
                figure;
                imagesc(diffImage);
                title(sprintf('Effective error in channel %i: Units of device color intensity:', c));
                if plotdiffs > 1
                    for j=1:length(row)
                        fprintf('Diff: %.2f Input Value: %.20f\n', diffImage(row(j), col(j)), theImage(row(j), col(j), c) * 65535);
                    end
                end
            end
        end

        for c=1:3
            % Summarize for this color channel:
            fprintf('Channel %i: %i out of %i pixels differ. The maximum absolute difference is %i.\n', c, numdiff(c), numtot(c), maxdiff(c));
        end
    else
        % No error: Set maxdiff to zero.
        maxdiff = 0;
    end
    
    % Compute absolute effective maximum error in color intensity over all
    % values, pixels and channels. This is the true "human visible" error.
    maxerror = max(maxdiff);
    
    % Error small enough to be acceptable for practical purposes?
    if maxerror <= acceptableerror
        % Yes. Skip further tests at different rasterizer offsets:
        break;
    end
end

% Show GPU converted image. Should obviously not make any visual difference if
% it is the same as the Matlab converted image.
vbl = Screen('Flip', window);

% Disable Bits++ Color++ output formatter:
Screen('HookFunction', window, 'Disable', 'FinalOutputFormattingBlit');

% Build and draw texture from packed image:
texpacked= Screen('MakeTexture', window, packedImage);
dstRect = Screen('Rect', texpacked);
Screen('DrawTexture', window, texpacked, [], dstRect, [], 0);

% Show it:
vbl = Screen('Flip', window, vbl + 1);

% Keep it onscreen for 2 seconds, then blank screen:
Screen('Flip', window, vbl + 2);

% Done. Close everything down:
Screen('CloseAll');
RestoreCluts;

% Best fit differs from expected result? That would be "game over":
if (mdr>0 || mdg>0 || mdb>0)
    fprintf('\n\n------------------ DIFFERENCE IN COLOR++ CONVERSION DETECTED ------------------\n');
    
    % Effective maximum error below acceptance threshold? Then we just warn
    % mildly but do not fail:
    if maxerror <= acceptableerror
        fprintf('However, the effective absolute maximal error is within the rejection threshold of %f units.\n', acceptableerror);
        fprintf('This means the error of %f intensity units out of 65535 is small enough to not matter in reality,\n', maxerror);
        fprintf('given the limited precision of your display device, calibration errors and other sources of error.\n');
        fprintf('\nTherefore i will let this test pass. You can use the "plotdiffs" flag to show a difference image\n');
        fprintf('for further assessment if you want.\n\n');
    else
        % Error too big to be acceptable.
        fprintf('The effective absolute maximal error of %f is bigger than the\nrejection threshold of %f units.\n', maxerror, acceptableerror);
        fprintf('This should not happen on properly and accurately working graphics hardware.\n');
        fprintf('Either there is a bug in the graphics driver, or something is misconfigured or\n');
        fprintf('your hardware is too old and not capable of performing the calculations in sufficient\n');
        fprintf('precision.\nYou may want to check your configuration and upgrade your driver. If that\n');
        fprintf('does not help, upgrade your graphics hardware. Alternatively you may want to use the old\n');
        fprintf('Matlab-based BitsPlusPackColorImage() function for slow conversion of color images.\n\n');
        fprintf('Please report this failure with a description of your hardware setup to the Psychtoolbox\n');
        fprintf('forum (http://psychtoolbox.org --> Link to the forum.)\n\n');
        if ~forcesuccess
            fprintf('You can force this test to succeed if you set the optional "forcesuccess" flag for this\n');
            fprintf('script to one and rerun it.\n\n');
            
            Screen('Preference', 'Verbosity', oldverbosity);
            Screen('Preference', 'SkipSyncTests', oldsynclevel);
            
            BitsPlusPlus('ResetOnWindowClose');
            error('Bits++ Color++ test failed. Results of Matlab code and GPU conversion differ too much!');
        else
            fprintf('Will continue anyway, because you set the "forcesuccess" flag to force me to continue.\n');
        end
    end
end

% Non zero readback offsets needed?
if ((dx ~= 0) || (dy ~= 0))
    % Not good.
    fprintf('\n\n----------------------------------- CAUTION -----------------------------------------\n');
    fprintf('There is an offset of dx = %i and dy = %i pixels between the detected\n', dx, dy);
    fprintf('and expected location of the pixel data in the framebuffer! This means that\n');
    fprintf('your graphics driver has a bug either in the pixel rendering path or the pixel\n');
    fprintf('readback path. A bug in the readback path would be problematic for other applications\n');
    fprintf('but not for high precision color or luminance output.\n');
    fprintf('A bug in the rendering path would be bad for high precision visual stimulus display.\n');
    fprintf('This test cannot find out by itself which of both bugs is present, the "good" one or\n');
    fprintf('the "bad" one. I will display a test pattern now after a key press. With your Bits+ box\n');
    fprintf('or Datapixx in Color++ mode, you should see a 50%% intensity gray rectangle with a 100%% white\n');
    fprintf('frame around it, in front of a black background.\n');
    fprintf('Press a key for presentation, then the key again after you verified\n');
    fprintf('if you saw what you were expected to see.\n');
    fprintf('\n');
    fprintf('Press any key to start presentation.\n');
    KbStrokeWait;
    
    PsychColorCorrection('ChooseColorCorrection', 'ClampOnly');

    % Open a double buffered fullscreen window with black background, configured for the Bits++
    % Color++ Mode, i.e., with proper setup of imaging pipeline and conversion shaders:
    BitsPlusPlus('ForceUnvalidatedRun');

    % The correctness test for Color++/C48 mode is written for classic mode,
    % ie., mode 0, so request that:
    BitsPlusPlus('SetColorConversionMode', 0);
    window = BitsPlusPlus('OpenWindowColor++', whichScreen, 0, winrect);
    Screen('FillRect', window, 0.5, CenterRect([0 0 200 200], screenRect));
    Screen('FrameRect', window, 1.0, CenterRect([0 0 200 200], screenRect), 20);
    DrawFormattedText(window, 'Press any key when done.', 'center', 100, [1 1 0]);
    Screen('Flip', window);
    KbStrokeWait;
    Screen('CloseAll');
    RestoreCluts;
    fprintf('\n\n\n');
    
    answer = input('Did you see a gray filled rectangle, with a white frame on a black background? [y/n] ', 's');
    if answer ~= 'y'
        fprintf('\n\nOk, the graphics driver bug is in the rendering path. Sad, very sad :-(\n');
        fprintf('This will not work for precision stimulus presentation. Test failed.\n\n');
        fprintf('You may want to check your configuration and upgrade your driver. If that\n');
        fprintf('does not help, upgrade your graphics hardware. Alternatively you may want to use the old\n');
        fprintf('Matlab-based BitsPlusPackColorImage() function for slow conversion of color images.\n\n');
        fprintf('Please report this failure with a description of your hardware setup to the Psychtoolbox\n');
        fprintf('forum (http://psychtoolbox.org --> Link to the forum.)\n\n');
        fprintf('You can force this test to succeed if you set the optional "forcesuccess" flag for this\n');
        fprintf('script to one and rerun it.\n\n');

        Screen('Preference', 'Verbosity', oldverbosity);
        Screen('Preference', 'SkipSyncTests', oldsynclevel);

        error('Bits++ Color++ test failed. Hardware rasterizer malfunction / graphics driver bug!');
    else
        fprintf('\n\nOk, the graphics driver bug is in the pixel readback path. That is tolerable for\n');
        fprintf('high precision stimulus display, but look out for other problems on your system\n');
        fprintf('with visual stimulus presentation etc.\n');
        fprintf('Might be a good idea to update your graphics drivers. I will classify the test so far as succeess...\n\n');
        fprintf('\n');
        fprintf('Press any key to continue to part II of the test.\n');
        KbStrokeWait;
    end
end

fprintf('\n\n------------------- Color++ test success! -------------------------------------\n\n');

% Now test Mono++ formatter:

% Reset color conversion mode to "undefined" to prevent cascading
% errors if usercode doesn't set this itself:
BitsPlusPlus('SetColorConversionMode', []);

% Generate a synthetic grating that covers the whole
% intensity range from 0 to 16384, mapped to the 0.0 - 1.0 range:
theImage=zeros(256,256,1);
theImage(:,:)=reshape(double(linspace(0, 2^16 - 1, 2^16)), 256, 256)' / (2^16 - 1);

% Convert input image via Bits++ toolbox routines (Matlab code):
fprintf('Converting test stim to mono++ format\n');
packedImage = BitsPlusPackMonoImage(theImage * (2^16 - 1));

% Show the image

% Open a double buffered fullscreen window with black background, configured for the Bits++
% Mono++ Mode, i.e., with proper setup of imaging pipeline and conversion shaders:
BitsPlusPlus('ForceUnvalidatedRun');
window = BitsPlusPlus('OpenWindowMono++', whichScreen, 0, winrect);

% Build HDR texture: 
hdrtexIndex= Screen('MakeTexture', window, theImage, [], [], 2);

% Draw HDR image via imaging pipeline:

% Enable Bits++ Mono++ output formatter:
Screen('HookFunction', window, 'Enable', 'FinalOutputFormattingBlit');

% Draw Mono++ image as generated by PTB GPU imaging pipeline:
dstRect = Screen('Rect', hdrtexIndex);
Screen('DrawTexture',window,hdrtexIndex, [], dstRect, [], 0);

% Finalize image before we take a screenshot:
Screen('DrawingFinished', window, 0, 1);

% Take screenshot of GPU converted image:
convImage=Screen('GetImage', window, OffsetRect(dstRect, dx, dy), 'backBuffer');

% Show GPU converted image. Should obviously not make any visual difference if
% it is the same as the Matlab converted image.
vbl = Screen('Flip', window);

% Disable Bits++ Mono++ output formatter:
Screen('HookFunction', window, 'Disable', 'FinalOutputFormattingBlit');

% Build and draw texture from packed image:
texpacked= Screen('MakeTexture', window, packedImage);
dstRect = Screen('Rect', texpacked);
Screen('DrawTexture', window, texpacked, [], dstRect, [], 0);

% Keep it onscreen for 2 seconds, then blank screen:
vbl = Screen('Flip', window, vbl + 2);

% Keep it onscreen for 2 seconds, then blank screen:
Screen('Flip', window, vbl + 2);

Screen('Preference', 'Verbosity', oldverbosity);
Screen('Preference', 'SkipSyncTests', oldsynclevel);

% Compute difference images between Matlab converted packedImage and GPU converted
% HDR image:
diffred   = abs(double(packedImage(:,:,1)) - double(convImage(:,:,1)));
diffgreen = abs(double(packedImage(:,:,2)) - double(convImage(:,:,2)));
diffblue  = abs(double(packedImage(:,:,3)) - double(convImage(:,:,3)));

% Compute maximum deviation of framebuffer raw data:
mdr = max(max(diffred));
mdg = max(max(diffgreen));
mdb = max(max(diffblue));

fprintf('\n\nMaximum raw data difference: red= %f green = %f blue = %f\n', mdr, mdg, mdb);

% If there is a difference, show plotted difference if requested:
if (mdr>0 || mdg>0 || mdb>0) && plotdiffs
    % Differences detected!
    close all;
    imagesc(diffred);
    title('Undecoded pixel error in red channel (high 8-Bits):');
    figure;
    imagesc(diffgreen);
    title('Undecoded pixel error in green channel (low 8-Bits):');    
    figure;
    imagesc(diffblue);
    title('Undecoded pixel error in blue channel (8-Bit overlay clut index):');    
end

if (mdr>0 || mdg>0 || mdb>0)    
    % Now compute a more meaningful difference: The difference between the
    % stimulus as the Bits++ box would see it (i.e. how much do the 16 bit
    % intensity values of each color channel differ?):
    convImage = double(convImage);
    packedImage = double(packedImage);

    % Invert conversion: Compute 16 bpc intensity values from high/low byte
    % pixel data:
    deconvImage = zeros(size(convImage,1), size(convImage,2));
    deconvImage(:,:) = 256 * convImage(:, :, 1) + convImage(:, :, 2);

    depackImage = zeros(size(packedImage,1), size(packedImage,2));
    depackImage(:,:) = 256 * packedImage(:, :, 1) + packedImage(:, :, 2);

    % Difference image:
    diffImage = (deconvImage - depackImage);

    % Find locations where pixels differ:
    idxdiff = find(abs(diffImage) > 0);
    numdiff = length(idxdiff);
    numtot = size(diffImage,1)*size(diffImage,2);
    maxdiff = max(max(abs(diffImage)));
    [row col] = ind2sub(size(diffImage), idxdiff);

    % Print out all pixels values which differ, and their difference:
    if plotdiffs
        figure;
        imagesc(diffImage);
        title('Effective error in luminance: Units of device intensity:');

        if plotdiffs > 1
            for j=1:length(row)
                fprintf('Diff: %.2f Input Value: %.20f\n', diffImage(row(j), col(j)), theImage(row(j), col(j)) * 65535);
            end
        end
    end

    % Summarize:
    fprintf('%i out of %i pixels differ. The maximum absolute difference is %i.\n', numdiff, numtot, maxdiff);
else
    % No error: Set maxdiff to zero.
    maxdiff = 0;
end
    
% Compute absolute effective maximum error in luminance intensity values,
% pixels and channels. This is the true "human visible" error.
maxerror = max(maxdiff);

if (mdr>0 || mdg>0 || mdb>0)
    fprintf('\n\n------------------ DIFFERENCE IN MONO++ CONVERSION DETECTED ------------------\n');
    % Effective maximum error below acceptance threshold? Then we just warn
    % mildly but do not fail:
    if maxerror <= acceptableerror
        fprintf('However, the effective absolute maximal error is within the rejection threshold of %f units.\n', acceptableerror);
        fprintf('This means the error of %f intensity units out of 65535 is small enough to not matter in reality,\n', maxerror);
        fprintf('given the limited precision of your display device, calibration errors and other sources of error.\n');
        fprintf('\nTherefore i will let this test pass. You can use the "plotdiffs" flag to show a difference image\n');
        fprintf('for further assessment if you want.\n\n');
    else
        % Error too big to be acceptable.
        fprintf('The effective absolute maximal error of %f is bigger than the\nrejection threshold of %f units.\n', maxerror, acceptableerror);
        fprintf('This should not happen on properly and accurately working graphics hardware.\n');
        fprintf('Either there is a bug in the graphics driver, or something is misconfigured or\n');
        fprintf('your hardware is too old and not capable of performing the calculations in sufficient\n');
        fprintf('precision.\nYou may want to check your configuration and upgrade your driver. If that\n');
        fprintf('does not help, upgrade your graphics hardware. Alternatively you may want to use the old\n');
        fprintf('Matlab-based BitsPlusPackMonoImage() function for slow conversion of luminance images.\n\n');
        fprintf('Please report this failure with a description of your hardware setup to the Psychtoolbox\n');
        fprintf('forum (http://psychtoolbox.org --> Link to the forum.)\n\n');
        if ~forcesuccess
            fprintf('You can force this test to succeed if you set the optional "forcesuccess" flag for this\n');
            fprintf('script to one and rerun it.\n\n');
            
            Screen('Preference', 'Verbosity', oldverbosity);
            Screen('Preference', 'SkipSyncTests', oldsynclevel);
            
            BitsPlusPlus('ResetOnWindowClose');
            sca;
            error('Bits++ Mono++ test failed. Results of Matlab code and GPU conversion differ too much!');
        else
            fprintf('Will continue anyway, because you set the "forcesuccess" flag to force me to continue.\n');
        end
    end
end

fprintf('\n\n------------------- Mono++ test success! -------------------------------------\n\n');

% All tests successful: Write this configuration to file as being
% validated:
BitsPlusPlus('StoreValidation', window);

% Done. Close everything down:
BitsPlusPlus('ResetOnWindowClose');
Screen('CloseAll');
RestoreCluts;

fprintf('\n\nSUMMARY: BitsPlusPlus imaging pipeline verified to work correctly. Validation info stored.\n');
fprintf('You may want to run BitsPlusIdentityClutTest next to test the path from framebuffer to output device.\n');

% Done for now.
return;