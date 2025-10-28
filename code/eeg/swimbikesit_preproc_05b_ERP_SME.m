%% mek_sports01_06_ERP_SME.m
% 
%  PURPOSE:
%  Compute event-related potentials (ERPs) for remembered ("hit") and forgotten
%  ("miss") words from subsequent memory effect (SME) epochs.
%
%  WORKFLOW:
%    1. Load SME epoched EEG datasets for each subject
%    2. Low-pass filter data for smoother ERP visualization
%    3. Select region of interest (ROI: P3, Pz, P4)
%    4. Compute mean ERP amplitudes within P3 window (400–800 ms)
%    5. Create grand averages (GA) across subjects and conditions:
%         - Pre-Hit, Pre-Miss, Post-Hit, Post-Miss
%    6. Compute SME difference waves (Hit – Miss)
%    7. Compute global field power (GFP) and topographies
%    8. Save subject-level data and grand averages
%
%  INPUTS:
%    - MEAS.mat: subject metadata
%    - Epoched .set files from ana_04_epo-sme/
%
%  OUTPUTS:
%    - Updated subject structure (SUB) with ERP and GFP values
%    - Grand averages (GA) for ERP, SME, and GFP
%    - Saved in derivatives/ana_06_erp-sme/
%
%  PARAMETERS:
%    - ROI: P3, Pz, P4
%    - Epoch window: -200 to 1200 ms
%    - P3 analysis window: 400–800 ms
%    - Low-pass filter: 10 Hz
%
%  DEPENDENCIES:
%    - EEGLAB toolbox
%    - pop_loadset, pop_select, pop_eegfiltnew
%
%  NOTES:
%    - "SME" = Subsequent Memory Effect (difference between remembered
%      and forgotten trials)
%    - Channels FP1, FP2, FT9, FT10 are excluded to ensure consistency
%      across all subjects and recording conditions.
%    - The script also identifies P3 peak latency from grand averages
%      to refine the search window.
%

%% preparations


clear all; close all; clc;                                                                          % clear workspace

MAINPATH = 'Q:\Neuro\data\projects\mek_sports01\eegl\BIDS\';                                             % define mainpath

PATHOUT = [MAINPATH,'derivatives\'];                                                                % path for saving data
EPOSME = [PATHOUT, 'ana_04_epo-sme\'];                                                     % path for SME epoch data 

load([MAINPATH,'MEAS.mat']);

% Parameters for ERP calculation -----------------------------------------------------------------

EVENTS= {'hit', 'miss'};
RUNS = {'pre', 'post'};
ROI = {'P3', 'Pz', 'P4'};
NOCHANS = {'FP1', 'FP2', 'FT9', 'FT10'};
P3_st = 400;
P3_sp = 800;

all_folders = dir(MAINPATH);
sub_folders = all_folders(11:100);

%% look at GA to adjust the search spacce

for sub = 1:length(SUB)

    % first, load epoched data ------------------------------------------------------------------
    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;                                                     % start EEGLAB

    SUBEPOSME = [EPOSME, sub_folders(sub).name, '\'];                                                          % define path to current subject
    cd(SUBEPOSME)                                                                                  % set filepath

    files = dir(fullfile(SUBEPOSME, '*.set'));                                                     % get access to data sets

    if strcmp(SUB(sub).ID, 'sports_01')
        files = files(2:end);                                                                       % files are weird
    end


    for file = 1:length(files)

        % Preparations ---------------------------------------------------------------------------

        file_name = files(file).name;                                                               % get file name

        if contains(file_name, 'hit')                                                               % = remembered word
            event_count = 1;
        elseif contains(file_name, 'miss')                                                          % = forgotten word
            event_count = 2;
        end
        
        if contains(file_name, 'pre')
            cond_count = 1;
        elseif contains(file_name, 'post')
            cond_count = 2;
        end

        EEG = pop_loadset([SUBEPOSME, file_name]);                                                 % load data set
        EEG.setname = file_name;                                                                    % give file a namne
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );                                    % store in ALLEEG

        EEG = pop_eegfiltnew(EEG, 'hicutoff', 10);                                                 % low-pass filter to make it smoother

        % last preparations & sorting stuff ------------------------------------------------------

        if strcmp(SUB(sub).ID, 'sports_01') && file == 1
            chanlocs_swim = EEG.chanlocs;                                                           % chanlocs for later topoplots

        elseif strcmp(SUB(sub).ID, 'sports_43') && file == 1
            chanlocs = EEG.chanlocs;                                                                % chanlocs for later topoplots
        end

        EEG = pop_select( EEG, 'nochannel', NOCHANS);                                               % exclude channels missing in swim

        P3_start_pos = find(EEG.times == P3_st);                                                    % P3 start timepoint on EEG.times
        P3_stop_pos = find(EEG.times==P3_sp);                                                       % P3 stop timepoint on EEG.times

        ROI_chans = [find(strcmp(ROI{1}, {EEG.chanlocs.labels})), find(strcmp(ROI{2}, {EEG.chanlocs.labels})), ...
            find(strcmp(ROI{3}, {EEG.chanlocs.labels}))];
        ROI_chans = sort(ROI_chans);

        % get ERP data for subjects --------------------------------------------------------------
        
        % PRE - HIT      
        if event_count == 1 && cond_count == 1 

            ROI_ERP_pre_hit = squeeze(mean(mean(EEG.data(ROI_chans,:,:),3),1));    
            chanERP = ROI_ERP_pre_hit(P3_start_pos:P3_stop_pos);                                    % ERP
            SUB(sub).amp_pre_hit = mean(chanERP);                                                   % amplitude mean, in accordance with Maria

            SUB(sub).ERP_pre_hit = ROI_ERP_pre_hit;
            GA_pre_hit(:,:,sub) = ROI_ERP_pre_hit;

        
        % PRE - MISS   
        elseif event_count == 2 && cond_count == 1 

            ROI_ERP_pre_miss = squeeze(mean(mean(EEG.data(ROI_chans,:,:),3),1));
            chanERP = ROI_ERP_pre_miss(P3_start_pos:P3_stop_pos);                                    % ERP
            SUB(sub).amp_pre_miss = mean(chanERP);                                                  % amplitude mean, in accordance with Maria

            SUB(sub).ERP_pre_miss = ROI_ERP_pre_miss;
            GA_pre_miss(:,:,sub) = ROI_ERP_pre_miss;
        
        
        % POST - HIT
        elseif event_count == 1 && cond_count == 2

            ROI_ERP_post_hit = squeeze(mean(mean(EEG.data(ROI_chans,:,:),3),1));    
            chanERP = ROI_ERP_post_hit(P3_start_pos:P3_stop_pos);                                   % ERP
            SUB(sub).amp_post_hit = mean(chanERP);                                                  % amplitude mean, in accordance with Maria

            SUB(sub).ERP_post_hit = ROI_ERP_post_hit;
            GA_post_hit(:,:,sub) = ROI_ERP_post_hit;


        % POST - MISS
        elseif event_count == 2 && cond_count == 2

            ROI_ERP_post_miss = squeeze(mean(mean(EEG.data(ROI_chans,:,:),3),1));    
            chanERP = ROI_ERP_post_miss(P3_start_pos:P3_stop_pos);                                    % ERP
            SUB(sub).amp_post_miss = mean(chanERP);                                                 % amplitude mean, in accordance with Maria

            SUB(sub).ERP_post_miss = ROI_ERP_post_miss;
            GA_post_miss(:,:,sub) = ROI_ERP_post_miss;



        end                                                                                         % end if-else statement for conditions
    end                                                                                             % end loop across files
end                                                                                                 % end loop across subjects


GA = [squeeze(mean(GA_pre_hit,3)); squeeze(mean(GA_pre_miss,3)); squeeze(mean(GA_post_hit,3)); squeeze(mean(GA_post_miss,3))];
GA = mean(GA, 1);


figure;
plot(EEG.times, GA)

[n2_peak p2_pos] = max(GA(P3_start_pos:P3_stop_pos));
sme_lat = EEG.times(find(GA == n2_peak));

sme_start = sme_lat - 200;
sme_stop = sme_lat + 200;

%% Analysis

P3_st = 440;
P3_sp = 840;

for sub = 1:length(SUB)

    % first, load epoched data ------------------------------------------------------------------
    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;                                                     % start EEGLAB

    SUBEPOSME = [EPOSME, sub_folders(sub).name, '\'];                                                          % define path to current subject
    cd(SUBEPOSME)                                                                                  % set filepath

    files = dir(fullfile(SUBEPOSME, '*.set'));                                                     % get access to data sets

    if strcmp(SUB(sub).ID, 'sports_01')
        files = files(2:end);                                                                       % files are weird
    end


    for file = 1:length(files)

        % Preparations ---------------------------------------------------------------------------

        file_name = files(file).name;                                                               % get file name

        if contains(file_name, 'hit')                                                               % = remembered word
            event_count = 1;
        elseif contains(file_name, 'miss')                                                          % = forgotten word
            event_count = 2;
        end
        
        if contains(file_name, 'pre')
            cond_count = 1;
        elseif contains(file_name, 'post')
            cond_count = 2;
        end

        EEG = pop_loadset([SUBEPOSME, file_name]);                                                 % load data set
        EEG.setname = file_name;                                                                    % give file a namne
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );                                    % store in ALLEEG

        EEG = pop_eegfiltnew(EEG, 'hicutoff', 10);                                                 % low-pass filter to make it smoother

        % last preparations & sorting stuff ------------------------------------------------------

        if strcmp(SUB(sub).ID, 'sports_01') && file == 1
            chanlocs_swim = EEG.chanlocs;                                                           % chanlocs for later topoplots

        elseif strcmp(SUB(sub).ID, 'sports_43') && file == 1
            chanlocs = EEG.chanlocs;                                                                % chanlocs for later topoplots
        end

        EEG = pop_select( EEG, 'nochannel', NOCHANS);                                               % exclude channels missing in swim

        P3_start_pos = find(EEG.times == P3_st);                                                    % P3 start timepoint on EEG.times
        P3_stop_pos = find(EEG.times==P3_sp);                                                       % P3 stop timepoint on EEG.times

        ROI_chans = [find(strcmp(ROI{1}, {EEG.chanlocs.labels})), find(strcmp(ROI{2}, {EEG.chanlocs.labels})), ...
            find(strcmp(ROI{3}, {EEG.chanlocs.labels}))];
        ROI_chans = sort(ROI_chans);

        % get ERP data for subjects --------------------------------------------------------------
        
        % PRE - HIT      
        if event_count == 1 && cond_count == 1 

            ROI_ERP_pre_hit = squeeze(mean(mean(EEG.data(ROI_chans,:,:),3),1));    
            chanERP = ROI_ERP_pre_hit(P3_start_pos:P3_stop_pos);                                    % ERP
            SUB(sub).amp_pre_hit = mean(chanERP);                                                   % amplitude mean, in accordance with Maria

            SUB(sub).ERP_pre_hit = ROI_ERP_pre_hit;
            GA_pre_hit(:,:,sub) = ROI_ERP_pre_hit;
            TOPO_pre_hit(:,:,sub) = squeeze(mean(mean(EEG.data(:,P3_start_pos:P3_stop_pos,:),3),2));

            GFP_pre_hit(:,:,sub) = std(mean(EEG.data, 3), [], 1);
            SUB(sub).GFP_pre_hit = mean(GFP_pre_hit(:,P3_start_pos:P3_stop_pos,sub),2);

        
        % PRE - MISS   
        elseif event_count == 2 && cond_count == 1 

            ROI_ERP_pre_miss = squeeze(mean(mean(EEG.data(ROI_chans,:,:),3),1));
            chanERP = ROI_ERP_pre_miss(P3_start_pos:P3_stop_pos);                                    % ERP
            SUB(sub).amp_pre_miss = mean(chanERP);                                                  % amplitude mean, in accordance with Maria

            SUB(sub).ERP_pre_miss = ROI_ERP_pre_miss;
            GA_pre_miss(:,:,sub) = ROI_ERP_pre_miss;
            TOPO_pre_miss(:,:,sub) = squeeze(mean(mean(EEG.data(:,P3_start_pos:P3_stop_pos,:),3),2));

            GFP_pre_miss(:,:,sub) = std(mean(EEG.data, 3), [], 1);
            SUB(sub).GFP_pre_miss = mean(GFP_pre_miss(:,P3_start_pos:P3_stop_pos,sub),2);
        
        
        % POST - HIT
        elseif event_count == 1 && cond_count == 2

            ROI_ERP_post_hit = squeeze(mean(mean(EEG.data(ROI_chans,:,:),3),1));    
            chanERP = ROI_ERP_post_hit(P3_start_pos:P3_stop_pos);                                   % ERP
            SUB(sub).amp_post_hit = mean(chanERP);                                                  % amplitude mean, in accordance with Maria

            SUB(sub).ERP_post_hit = ROI_ERP_post_hit;
            GA_post_hit(:,:,sub) = ROI_ERP_post_hit;
            TOPO_post_hit(:,:,sub) = squeeze(mean(mean(EEG.data(:,P3_start_pos:P3_stop_pos,:),3),2));

            GFP_post_hit(:,:,sub) = std(mean(EEG.data, 3), [], 1);
            SUB(sub).GFP_post_hit = mean(GFP_post_hit(:,P3_start_pos:P3_stop_pos,sub),2);


        % POST - MISS
        elseif event_count == 2 && cond_count == 2

            ROI_ERP_post_miss = squeeze(mean(mean(EEG.data(ROI_chans,:,:),3),1));    
            chanERP = ROI_ERP_post_miss(P3_start_pos:P3_stop_pos);                                    % ERP
            SUB(sub).amp_post_miss = mean(chanERP);                                                 % amplitude mean, in accordance with Maria

            SUB(sub).ERP_post_miss = ROI_ERP_post_miss;
            GA_post_miss(:,:,sub) = ROI_ERP_post_miss;
            TOPO_post_miss(:,:,sub) = squeeze(mean(mean(EEG.data(:,P3_start_pos:P3_stop_pos,:),3),2));

            GFP_post_miss(:,:,sub) = std(mean(EEG.data, 3), [], 1);
            SUB(sub).GFP_post_miss = mean(GFP_post_miss(:,P3_start_pos:P3_stop_pos,sub),2);


        end                                                                                         % end if-else statement for conditions
    end                                                                                             % end loop across files
    
    try
        SME_pre(:,:,sub) = GA_pre_hit(:,:,sub) - GA_pre_miss(:,:,sub);
        SUB(sub).amp_pre_SME = mean(SME_pre(:,P3_start_pos:P3_stop_pos,sub));
        TOPO_pre_sme(:,:,sub) = TOPO_pre_hit(:,:,sub) - TOPO_pre_miss(:,:,sub);
    end
    
    try    
        SME_post(:,:,sub) = GA_post_hit(:,:,sub) - GA_post_miss(:,:,sub);
        SUB(sub).amp_post_SME = mean(SME_post(:,P3_start_pos:P3_stop_pos,sub));
        TOPO_post_sme(:,:,sub) = TOPO_post_hit(:,:,sub) - TOPO_post_miss(:,:,sub);
    end

    try
        SME_GFP_pre(:,:,sub) = GFP_pre_hit(:,:,sub) - GFP_pre_miss(:,:,sub);
        SUB(sub).GFP_pre_SME = SUB(sub).GFP_pre_hit - SUB(sub).GFP_pre_miss;

        SME_GFP_post(:,:,sub) = GFP_post_hit(:,:,sub) - GFP_post_miss(:,:,sub);
        SUB(sub).GFP_post_SME = SUB(sub).GFP_post_hit - SUB(sub).GFP_post_miss;
    end

end                                                                                                 % end loop across subjects

%% save

save([PATHOUT,'SUB_PT'],'SUB');

GA.pre_hit = GA_pre_hit;
GA.pre_miss = GA_pre_miss;
GA.post_hit = GA_post_hit;
GA.post_miss = GA_post_miss;

GA.topo_pre_hit = TOPO_pre_hit;
GA.topo_pre_miss = TOPO_pre_miss;
GA.topo_post_hit = TOPO_post_hit;
GA.topo_post_miss = TOPO_post_miss;

GA.sme_pre = SME_pre;
GA.sme_post = SME_post;
GA.topo_pre_sme = TOPO_pre_sme;
GA.topo_post_sme = TOPO_post_sme;

GA.gfp_pre_hit = GFP_pre_hit;
GA.gfp_pre_miss = GFP_pre_miss;
GA.gfp_post_hit = GFP_post_hit;
GA.gfp_post_miss = GFP_post_miss;

GA.gfp_pre_sme = SME_GFP_pre;
GA.gfp_post_sme = SME_GFP_post;

GA.timevec = EEG.times;
GA.chanlocs = EEG.chanlocs;
GA.chanlocs_swim = chanlocs_swim;

save([PATHOUT,'GA'],'GA');

%% get an overview for values

all_hit_pre = extractfield(SUB, 'amp_pre_hit');
mean_hit_pre = mean(cell2mat(all_hit_pre(~cellfun('isempty',all_hit_pre))));

all_miss_pre = extractfield(SUB, 'amp_pre_miss');
mean_miss_pre = mean(cell2mat(all_miss_pre(~cellfun('isempty',all_miss_pre))));

all_hit_post = extractfield(SUB, 'amp_post_hit');
mean_hit_post = mean(cell2mat(all_hit_post(~cellfun('isempty',all_hit_post))));

all_miss_post = extractfield(SUB, 'amp_post_miss');
mean_miss_post = mean(cell2mat(all_miss_post(~cellfun('isempty',all_miss_post))));


sme_pre = extractfield(SUB, 'amp_pre_SME');
mean_sme_pre = mean(cell2mat(sme_pre(~cellfun('isempty',sme_pre))));

sme_post = extractfield(SUB, 'amp_post_SME');
mean_sme_post = mean(cell2mat(sme_post(~cellfun('isempty',sme_post))));

%% preliminary plots

pre_hit = mean(GA_pre_hit, 3);
pre_miss = mean(GA_pre_miss, 3);
post_hit = mean(GA_post_hit, 3);
post_miss = mean(GA_post_miss, 3);

figure;
plot(EEG.times, pre_hit);
hold on
plot(EEG.times, pre_miss);
ylim([-2, 4])
legend('pre_hit', 'pre_miss')

figure;
plot(EEG.times, post_hit);
hold on
plot(EEG.times, post_miss);
ylim([-2, 4])
legend('post_hit', 'post_miss')

pre_sme = mean(SME_pre, 3);
post_sme = mean(SME_post, 3);

figure;
plot(EEG.times, pre_sme);
hold on
plot(EEG.times, post_sme);
ylim([-2 4])
legend('sme pre', 'sme_post')


pre_hit = mean(GFP_pre_hit, 3);
pre_miss = mean(GFP_pre_miss, 3);
post_hit = mean(GFP_post_hit, 3);
post_miss = mean(GFP_post_miss, 3);

figure;
subplot(121)
plot(EEG.times, pre_hit);
hold on
plot(EEG.times, pre_miss);
ylim([-2, 4])
xlim([-200 1200])
legend('pre_hit', 'pre_miss')

subplot(122)
plot(EEG.times, post_hit);
hold on
plot(EEG.times, post_miss);
ylim([-2, 4])
xlim([-200 1200])
legend('post_hit', 'post_miss')

figure;
plot(EEG.times, mean(SME_GFP_pre, 3))
hold on
plot(EEG.times, mean(SME_GFP_post, 3))
ylim([0, 1])
xlim([-200 1200])
legend('SME GFP pre', 'SME GFP post')


figure;
subplot(221)
topoplot(squeeze(mean(TOPO_pre_hit, 3)), chanlocs_swim);
colorbar;
clim([-1.2 1.2])
title('Pre Hit')

subplot(222)
topoplot(squeeze(mean(TOPO_pre_miss, 3)), chanlocs_swim);
colorbar;
clim([-1.2 1.2])
title('Pre Miss')

subplot(223)
topoplot(squeeze(mean(TOPO_post_hit, 3)), chanlocs_swim);
colorbar;
clim([-1.2 1.2])
title('Post Hit')

subplot(224)
topoplot(squeeze(mean(TOPO_post_miss, 3)), chanlocs_swim);
colorbar;
clim([-1.2 1.2])
title('Post Miss')


figure;
subplot(121)
topoplot(squeeze(mean(TOPO_pre_sme, 3)), chanlocs_swim);
colorbar;
clim([-1.2 1.2])
title('Pre SME')

subplot(122)
topoplot(squeeze(mean(TOPO_pre_sme, 3)), chanlocs_swim);
colorbar;
clim([-1.2 1.2])
title('Post SME')







%% 