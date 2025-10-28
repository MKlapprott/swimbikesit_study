%% mek_sports01_GNG_accuracy.m
%
% Goal: calculate hits, misses, FAs and CRs for the GoNoGo. Important: 2
% blocks per dataset. Always the first 9 ones are practice trials!
% Types of events:
%   - square: Go
%   - circle: NoGo
%   - 7: hit
%   - 77: false alarm
%
% Steps:
%   - load raw data
%   - extract only GNG events
%   - if square & answer -> hit
%   - if square & no answer -> miss
%   - if circle & answer -> false alarm
%   - if circle & no answer -> correct rejection
%
% Melanie, Dec 2023

%% Preparation

clear all; close all; clc;                                                                          % clear workspace

MAINPATH = 'Q:\Neuro\data\projects\mek_sports01\eegl\';                                             % define mainpath \Neuro
EEGLABPATH = [MAINPATH, 'eeglab2022.0\'];                                                           % define path for EEGLAB
PATHIN = [MAINPATH,'rawdata\'];                                                                     % define path for raw data
PATHOUT = [MAINPATH,'derivatives\'];                                                                % path for saving data
cd(PATHOUT)

% set up parameters
BLOCKS = {'pre', 'post'};


% load sub struct
load([PATHOUT,'SUB_PT.mat']);


%% Analysis


for sub = 1:length(SUB)

    SUBPATHIN = [PATHIN, SUB(sub).ID, '\'];                                                         % create sub-specific path

    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;                                                     % start EEGLAB
    files = dir(fullfile(SUBPATHIN, '*.xdf'));                                                      % get access to xdf files
    num_files = length(files);                                                                      % get number of files

    % adjustments part 1 -------------------------------------------------------------------------

    if ~strcmp(SUB(sub).GROUP , 'swim')
        files = [files(1);files(end)];                                                              % make sure only pre / post data files are in
        num_files = length(files);                                                                  % get number of files

    elseif strcmp(SUB(sub).GROUP , 'swim') && strcmp(SUB(sub).ID, 'sports_96')                      % here, swim is also an xdf file
            files = [files(1);files(2)];
           
    end

    if strcmp(SUB(sub).ID, 'sports_13') || strcmp(SUB(sub).ID, 'sports_96')                         % actually 3 files, but just need two
        num_files = 2;

    elseif strcmp(SUB(sub).ID, 'sports_21') || strcmp(SUB(sub).ID, 'sports_42') || strcmp(SUB(sub).ID, 'sports_89')
        num_files = 1;
    end

    % start looking at files ---------------------------------------------------------------------
    
    for file = 1:num_files

        % adjustments part 2 (% events in pre missing) -------------------------------------------

        if strcmp(SUB(sub).ID, 'sports_28') || strcmp(SUB(sub).ID, 'sports_32') || strcmp(SUB(sub).ID, 'sports_35') || ...
           strcmp(SUB(sub).ID, 'sports_73')
            file = 2;
        end

        my_file = files(file).name;                                                                 % get name of file
        EEG = pop_loadxdf([SUBPATHIN, my_file], 'streamtype', 'EEG', 'exclude_markerstreams', {});

        EEG.setname = [SUB(sub).ID, '-', BLOCKS{file}];                                             % give set a name
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);                                           % store in ALLEEG

        if strcmp(SUB(sub).ID, 'sports_13') && file == 2                                              % s13 has a recording for each memory block for post
    
            my_file2 = files(file+1).name;                                                          % get the second file right away
            EEG = pop_loadxdf([SUBPATHIN, my_file2], 'streamtype', 'EEG', 'exclude_markerstreams', {});

            EEG.setname = [SUB(sub).ID, '-post2'];                                                    % give set a name
            [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);                                       % store in ALLEEG

            EEG = pop_mergeset(ALLEEG(1), ALLEEG(2));                                               % combine both post files to one
             EEG.setname = [SUB(sub).ID, '-post-merged']; 

            num_files = 2;
        end                                                                                         % end if else for sub 13 

        % start calculations ---------------------------------------------------------------------

        % first, find instr_oddball_2 and only search from there on

        a = extractfield(EEG, 'event');                                                             % helper variable
        events_only = extractfield(a{1,1}, 'type')';                                                % cell of only events

        if strcmp(SUB(sub).ID, 'sports_12') && file == 2
            start_point = [1,1];
            stop_point1 = length(events_only);
            
        else
            start_point = find(strcmp('instr_oddball_2', events_only));
            stop_point1 = find(strcmp('0 pick block', events_only));
            
        end

        % accuracy 1 -----------------------------------------------------------------------------
        % find hits and false alarms

        hits1(sub,file) = sum(strcmp('7', events_only(start_point(1):stop_point1)));
        hits2(sub,file) = sum(strcmp('7', events_only(start_point(2):end)));

        false_a1(sub,file) = sum(strcmp('77', events_only(start_point(1):stop_point1)));
        false_a2(sub,file) = sum(strcmp('77', events_only(start_point(2):end)));


        % based on number of stimuli & hits / FAs, calculate misses and corr rejs

        misses1(sub, file) = sum(strcmp('square', events_only(start_point(1):stop_point1))) - hits1(sub, file);
        misses2(sub, file) = sum(strcmp('square', events_only(start_point(2):end))) - hits2(sub, file);
        
        corr_r1(sub, file) = sum(strcmp('circle', events_only(start_point(1):stop_point1))) - false_a1(sub, file);
        corr_r2(sub, file) = sum(strcmp('circle', events_only(start_point(2):end))) - false_a2(sub, file);

        % finally, compute accuracy

        accuracy1(sub, file) = (hits1(sub, file) + corr_r1(sub, file)) / (hits1(sub,file) + false_a1(sub,file) + ...
                                misses1(sub, file) + corr_r1(sub, file));

        accuracy2(sub, file) = (hits2(sub, file) + corr_r2(sub, file)) / (hits2(sub,file) + false_a2(sub,file) + ...
                                misses2(sub, file) + corr_r2(sub, file));

        hitrate1 = hits1(sub, file) / (hits1(sub,file) + misses1(sub, file));
        farate1 = false_a1(sub, file) / (false_a1(sub,file) + corr_r1(sub, file));
        hitrate2 = hits2(sub, file) / (hits2(sub,file) +  misses2(sub, file));
        farate2 = false_a2(sub, file) / (false_a2(sub,file) + corr_r2(sub, file));

        if hitrate1 == 1
            hitrate1 = (hits1(sub,file) + misses1(sub, file) - 1) / (hits1(sub,file) + misses1(sub, file));
        end

        if hitrate2 == 1
            hitrate2 = (hits2(sub,file) + misses2(sub, file) - 1) / (hits2(sub,file) + misses2(sub, file));
        end

        if farate1 == 0
            farate1 = 1 / (false_a1(sub,file) + corr_r1(sub, file));
        end

        if farate2 == 0
            farate2 = 1 / (false_a2(sub,file) + corr_r2(sub, file));
        end


        d_prime1(sub, file) = norminv(hitrate1) - norminv(farate1);
        d_prime2(sub, file) = norminv(hitrate2) - norminv(farate2);
        
        % now: reaction times 1

        rt_count = 1;
        for idx = start_point(1):stop_point1

            if strcmp(a{1,1}(idx).type, 'square') && strcmp(a{1,1}(idx+1).type, '7')
                try

                    rt_sb1(rt_count) = (a{1,1}(idx+1).latency - a{1,1}(idx).latency) / EEG.srate * 1000;
                    rt_count = rt_count +1;
                catch
                    disp('lol didnt work')
                end

            end

        end

        % now: reaction times 2

        rt_count = 1;
        for idx = start_point(2):length(a{1,1})

            if strcmp(a{1,1}(idx).type, 'square') && strcmp(a{1,1}(idx+1).type, '7')
                try

                    rt_sb2(rt_count) = (a{1,1}(idx+1).latency - a{1,1}(idx).latency) / EEG.srate * 1000;
                    rt_count = rt_count +1;
                catch
                    disp('lol didnt work')
                end

            end

        end



        rt_b1(sub, file) = median(rt_sb1);
        rt_b2(sub, file) = median(rt_sb2);

        
    end                                                                                             % end loop across files
end                                                                                                 % end loop across subjects






%% Save as table


ID = extractfield(SUB, 'ID')';
group = extractfield(SUB, 'GROUP')';

% sort accuracy metrics --------------------------------------------------------------------------

rt = [rt_b1(:,1), rt_b2(:,1), rt_b1(:,2), rt_b2(:,2)];

accuracy = [accuracy1(:,1), accuracy2(:,1), accuracy1(:,2), accuracy2(:,2)];
d_prime = [d_prime1(:,1), d_prime2(:,1), d_prime1(:,2), d_prime2(:,2)];
hits = [hits1(:,1), hits2(:,1), hits1(:,2), hits2(:,2)];
misses = [misses1(:,1), misses2(:,1), misses1(:,2), misses2(:,2)];
false_a = [false_a1(:,1), false_a2(:,1), false_a1(:,2), false_a2(:,2)];
corr_r = [corr_r1(:,1), corr_r2(:,1), corr_r1(:,2), corr_r2(:,2)];

accuracy(accuracy == 0) = NaN;
rt(rt == 0) = NaN;

rt_pre = mean(rt(:,1:2), 2, 'omitnan');
rt_post = mean(rt(:,3:4), 2, 'omitnan');

accuracy_pre = mean(accuracy(:,1:2), 2, 'omitnan');
accuracy_post = mean(accuracy(:,3:4), 2, 'omitnan');

d_prime_pre = mean(d_prime(:,1:2), 2, 'omitnan');
d_prime_post = mean(d_prime(:,3:4), 2, 'omitnan');

% save

T = table(ID, group, hits, misses, false_a, corr_r, accuracy, accuracy_pre, accuracy_post, d_prime, d_prime_pre, d_prime_post);
T.Properties.VariableNames = {'ID', 'Group', 'Hits', 'Misses', 'FalseAlarms', 'CorrRejections', 'Accuracy', 'Accuracy_pre', 'Accuracy_post', 'd_prime', 'd_prime_pre', 'd_prime_post'};

writetable(T, [PATHOUT,'GoNoGo_acc_all.xlsx']);


T_rt_blocks = table(ID, group, rt_pre, rt_post, rt);
T_rt_blocks.Properties.VariableNames = {'ID', 'Group', 'RT_pre', 'RT_post', 'RT'};
writetable(T_rt_blocks, [PATHOUT,'GoNoGo_rt.xlsx']);



