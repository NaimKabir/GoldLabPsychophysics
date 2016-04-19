% Demonstrate drawing strings of text, allow visual inspection.
%
% @ingroup dotsDemos
function demoDrawableText(delay)

if nargin < 1
    delay = 2;
end

% get a drawing window
dotsTheScreen.reset();
dotsTheScreen.openWindow();

% create a text object
tx = dotsDrawableText();

% draw the text object with an arbitrary string and settings
tx.string = 'Juniper juice';
tx.color = [0 128 64];
dotsDrawable.drawFrame({tx});
pause(delay);

% draw the text object with a new string
tx.string = 'helicopter helicopter helicopter helicopter';
tx.color = [0 0 192];
tx.rotation = 30;
tx.isItalic = true;
tx.isFlippedVertical = true;
tx.isStrikethrough = true;
dotsDrawable.drawFrame({tx});
pause(delay);

% resize the text and draw it again
tx.string = 'No Way!';
tx.rotation = 0;
tx.isItalic = false;
tx.isFlippedVertical = false;
tx.fontSize = 64;
tx.isStrikethrough = false;
tx.color = [128 64 0];
dotsDrawable.drawFrame({tx});
pause(delay);

% close the OpenGL drawing window
dotsTheScreen.closeWindow();