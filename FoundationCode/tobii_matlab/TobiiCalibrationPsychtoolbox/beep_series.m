function beep_series(specs)
%BEEP_SERIES  Create a series of beeps
%    BEEP_SERIES([FREQ_HZ, VOL, DUR_SEC, PAUSE_SEC]) creates a series of
%    beeps from an N-by-4 spec matrix, where the colums represent:
%        frequency
%        volumne (0-1)
%        beep duration
%        pause duration,

freq = specs(:,1);
volume = specs(:,2);
duration = specs(:,3);
trailingGap = specs(:,4);

SAMPLE_FREQ = 8192;
totalTime = sum(duration) + sum(trailingGap);
x = zeros(ceil(totalTime*SAMPLE_FREQ),1);

curBeepStartTime = 0;
for ix = 1:length(freq)
    numSamples = round(duration(ix)*SAMPLE_FREQ);
    x( round(curBeepStartTime*SAMPLE_FREQ + (1:numSamples))  ) = ...
        volume(ix) * sin(    (1:numSamples)  *  (2*pi*freq(ix)/SAMPLE_FREQ)   );
    curBeepStartTime = curBeepStartTime + duration(ix) + trailingGap(ix);
end

sound(x, SAMPLE_FREQ)