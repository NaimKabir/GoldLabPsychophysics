%Quick Analysis
load('RKumar_Oddball_(000).mat')

ld = list{'Eye'}{'Right'};
ld = ld(:,3);
eyetime = list{'Eye'}{'Time'};
eyetime = double(eyetime);

%clean
ld = pupilclean(ld);

%find sound time stamps in terms of idx
playtimes = list{'Stimulus'}{'Playtimes'}*(1e6); %in microseconds
stim_idx = arrayfun(@(x) max(find(eyetime <= x)), playtimes', 'UniformOutput', 1);
stim_times = eyetime(stim_idx);

%plot
% figure
% plot(eyetime, ld); hold on; plot(stim_times, 5, 'r*'); hold off


%Get mean waveform:
% Setting window sizes for pre and post stimulus clips of the pupil 
% waveform.
prewindow = 60;
postwindow = 120;

% Collecting pre and postpackets from 2:end-1, to avoid over-indexing
pre = zeros(length(stim_idx), prewindow);
post = zeros(length(stim_idx), postwindow);
for i = 2:length(stim_idx)-2
    pre(i,:) = ld(stim_idx(i)-prewindow:stim_idx(i)-1,1);
    post(i,:) = ld(stim_idx(i):stim_idx(i) + postwindow - 1,1);
end

% Standardize each row

% Getting mean waveforms for pre and post-stimulus windows
prewave = mean(pre);
postwave = mean(post);

%Plot
figure
plot(prewave); hold on; plot(postwave);
xlabel('Time (in Samples)');
ylabel('Pupil Diameter');
legend('Pre-Stimulus', 'Post-Stimulus');
title('Opposite-Input Task')

%%
%Now for something a little more interesting...
%
standardfreq = list{'Stimulus'}{'StandardFreq'};
playfreqs = list{'Stimulus'}{'Playfreqs'};

standard_idx = playfreqs == standardfreq;

standardprewave = mean(pre(standard_idx,:));
standardpostwave = mean(post(standard_idx,:));

oddprewave = mean(pre(~standard_idx,:));
oddpostwave = mean(post(~standard_idx,:));

%Plot
figure
plot(standardprewave, 'Color', [1 0 0]); 
hold on; 
plot(standardpostwave, 'Color', [0.8, 0, 0.5]);
plot(oddprewave, 'Color', [0, 0, 1])
plot(oddpostwave, 'Color', [0, 0.5, 0.8])
xlabel('Time (in Samples)');
ylabel('Pupil Diameter');
legend('Standard Frequency, Pre-Stim', 'Standard Frequency, Post-Stim', ...
    'Odd Frequency, Pre-Stim', 'Odd Frequency, Post-Stim')
title('Opposite-Input Task')

%% Getting multiple timewindows of postwave stuff
window = 20;
shift = 5;
timebins = (postwindow-window)/shift;
postmatrix = zeros(length(post), window, timebins);

%Get 3D matrix with individual timebins in 3rd dimension
%Each row is a different trial
%Each column is a sample
%Each 3rd dimension is a time bin
counter = 0;
for i = 1:timebins
    postmatrix(:,:,i) = post(:, counter*shift + 1 : counter*shift + window);
    counter = counter + 1;
end

%% Plotting maxes of post-stimulus dilation timebins vs. means of baseline
 
premeans = mean(pre,2);
feature = @(x) max(x);

postfeatures = zeros(length(post), 1, timebins);
for i = 1:timebins
    for j = 1:length(post) %for every row, grab a feature
        postfeatures(j,:,i) = feature(postmatrix(j,:,i));
    end
end

% %%
% %Create premeans with intercept:
% X = [ones(length(premeans),1), premeans];
% 
% %Collect betas for ALL trials just for curiosity's sake
% betas.all = zeros(timebins, 2);
% for i = 1:timebins
%     %plot(premeans,postfeatures(:,:,i), '*', 'Color', [0 + i/timebins,1, 1 - i/timebins])
%     betas.all(i,:) = (X'*X)\X'*postfeatures(:,:,i);
%     %hold on;
%     fitx = linspace(min(premeans),max(premeans));
%     fity = betas.all(i,1) + betas.all(i,2)*fitx;
%     %plot(fitx, fity, 'Color',[0 + i/timebins, 1 - i/timebins, 1] );
%     %input('meow') 
%     %hold off
% end
% 
% %% Collect betas for just odd-frequency trials
% playfreqs = list{'Stimulus'}{'Playfreqs'};
% odds = playfreqs ~= list{'Stimulus'}{'StandardFreq'};
% premeansodd = premeans(odds);
% 
% X = [ones(length(premeansodd),1), premeansodd];
% betas.odd = zeros(timebins, 2);
% for i = 1:timebins
% %     plot(premeansodd,postfeatures(odds,:,i), '*', 'Color', [0 + i/timebins,1, 1 - i/timebins])
%     betas.odd(i,:) = (X'*X)\X'*postfeatures(odds,:,i);
%    % hold on;
%     fitx = linspace(min(premeansodd),max(premeansodd));
%     fity = betas.odd(i,1) + betas.odd(i,2)*fitx;
% %     plot(fitx, fity, 'Color',[0 + i/timebins, 1 - i/timebins, 1] );
% %     input('meow') 
% %     hold off
% end
% 
% %% Standard freqs
% stnds = ~odds;
% premeansstds = premeans(stnds);
% 
% X = [ones(length(premeansstds),1), premeansstds];
% betas.standardsM = zeros(timebins, 2);
% for i = 1:timebins
%     betas.standardsM(i,:) = (X'*X)\X'*postfeatures(stnds,:,i);
% %     fitx = linspace(min(premeansstds),max(premeansstds));
% %     fity = betas.standards(i,1) + betas.standards(i,2)*fitx;
% end
% 
% figure
% plot(betas.odd(:,1)); hold on; plot(betas.standardsM(:,1)); plot(betas.all(:,1));
% xlabel('Timebin');
% ylabel('Linear Regression Offset');
% legend('Only Odd Freq Trials', 'Only Standard w/ Motor Trials', 'All trials')

%% Load up (001) data 
%clear list
%load('RKumar_Oddball_(001).mat')

%% MultiRegression Dopeness

%Set up my features matrix: [Intercepts, Motor, Odd, Standard, Distractor, Adaptive_on]
