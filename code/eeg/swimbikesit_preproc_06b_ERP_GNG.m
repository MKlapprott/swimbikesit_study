%% mek_sports01_07_ERP_GNG.m
% 
% Goal: Take epoched data for ERP calculation
% Steps:
%   - epoched data files
%   - plot grand average
%   - get the grand average for the N1 and P3 across conditions
%       - N2: search in 220ms - 300ms
%       - P3: search in 300ms - 500ms (?)
%   - plot that in detail (later)
%
%   - loop across subjects and epochs
%   - calculate average for N2 in electrode Fz (220ms - 300ms)
%   - store in matrix (also take labels, might be useful later)
%   - take NoGo file
%   - calculate average for P3 in electrode Pz (300ms - 500ms)
%   - for all tar epochs separately, calculate mean amplitude in time window (+/- 50ms around peak)
%   - calculate the latency until the peak
%   - store the information in a matrix
%   - take the same time window to calculate mean amplitude in sta
%   - also store that information in a matrix
%   - combine all matrices to a table (= input for statistics!!!)
%   - plots -> extra script!
%
%
% Melanie, Dec 2023

%% Preparations

clear all; close all; clc;                                                                          % clear workspace

MAINPATH = 'Q:\Neuro\data\projects\mek_sports01\eegl\BIDS\';                                             % define mainpath
PATHOUT = [MAINPATH,'derivatives\'];                                                                % path for saving data
EPOGNG = [PATHOUT, 'ana_05_epo-gng\'];                                                     % path for SME epoch data 

% Parameters for ERP calculation -----------------------------------------------------------------

RUNS = {'pre', 'post'};
EVENTS = {'circle', 'square'};
ANSWERS = {'7', '77'};

ROI_N2 = {'Fz'};
ROI_P3 = {'Pz'};
NOCHANS = {'FP1', 'FP2', 'FT9', 'FT10'};

load([PATHOUT,'SUB_PT.mat']);
load([PATHOUT,'GA.mat']);

N2_st = 220;
N2_sp = 300;
P3_st = 300;
P3_sp = 600;

all_folders = dir(MAINPATH);
sub_folders = all_folders(11:100);

%% look at grand averages to correct for search space

for sub = 1:length(SUB)

    % first, load epoched data ------------------------------------------------------------------
    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;                                                     % start EEGLAB

    SUBEPOGNG = [EPOGNG, sub_folders(sub).name, '\'];                                                          % define path to current subject
    cd(SUBEPOGNG)                                                                                  % set filepath

    files = dir(fullfile(SUBEPOGNG, '*.set'));                                                     % get access to data sets

    for file = 1:length(files)

        % Preparations ---------------------------------------------------------------------------

        file_name = files(file).name;                                                               % get file name

        if contains(file_name, 'circle')                                                            % = NOGO
            event_count = 1;
        elseif contains(file_name, 'square')                                                        % = GO
            event_count = 2;
        end
        
        if contains(file_name, 'pre')
            cond_count = 1;
        elseif contains(file_name, 'post')
            cond_count = 2;
        end

        EEG = pop_loadset([SUBEPOGNG, file_name]);                                                 % load data set
        EEG.setname = file_name;                                                                    % give file a namne
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );                                    % store in ALLEEG

        % last preparations & sorting stuff ------------------------------------------------------

        if strcmp(SUB(sub).ID, 'sports_01') && file == 1
            chanlocs_swim = EEG.chanlocs;                                                           % chanlocs for later topoplots

        elseif strcmp(SUB(sub).ID, 'sports_43') && file == 1
            chanlocs = EEG.chanlocs;                                                                % chanlocs for later topoplots
        end

        EEG = pop_select( EEG, 'nochannel', NOCHANS);                                               % exclude channels missing in swim

        N2_start_pos = find(EEG.times == N2_st);                                                    % N2 start timepoint on EEG.times
        N2_stop_pos = find(EEG.times==N2_sp);                                                       % N2 stop timepoint on EEG.times

        ROI_chans_N2 = find(strcmp(ROI_N2{1}, {EEG.chanlocs.labels}));


        
        % PRE - NOGO      
        if event_count == 1 && cond_count == 1 

            % N2
            ROI_ERP_pre_nogo = squeeze(mean(mean(EEG.data(ROI_chans_N2,:,:),3),1));    
            chanERP = ROI_ERP_pre_nogo(N2_start_pos:N2_stop_pos);                                    % ERP

            GA_pre_nogo(:,:,sub) = ROI_ERP_pre_nogo;
            TOPO_pre_nogo(:,:,sub) = squeeze(mean(mean(EEG.data(:,N2_start_pos:N2_stop_pos,:),3),2));

            n2_peak = mean(chanERP);
            SUB(sub).lat_pre_nogo = GA.timevec(find(ROI_ERP_pre_nogo == n2_peak));

        
        % POST - NOGO
        elseif event_count == 1 && cond_count == 2

            % N2
            ROI_ERP_post_nogo = squeeze(mean(mean(EEG.data(ROI_chans_N2,:,:),3),1));    
            chanERP = ROI_ERP_post_nogo(N2_start_pos:N2_stop_pos);                                    % ERP

            GA_post_nogo(:,:,sub) = ROI_ERP_post_nogo;
            TOPO_post_nogo(:,:,sub) = squeeze(mean(mean(EEG.data(:,N2_start_pos:N2_stop_pos,:),3),2));

            n2_peak = mean(chanERP);
            SUB(sub).lat_post_nogo = GA.timevec(find(ROI_ERP_post_nogo == n2_peak));

        
        end
       
    end
    
end


GA = squeeze(mean(GA_pre_nogo,3));

figure;
plot(EEG.times, GA)

[n2_peak p2_pos] = min(GA);
n2_lat = EEG.times(p2_pos);


%% save latencies

ID = extractfield(SUB, 'ID')';
group = extractfield(SUB, 'GROUP')';

all_go_pre = nan(1, numel(SUB));  % Preallocate with NaN
for i = 1:numel(SUB)
    if ~isempty(SUB(i).lat_pre_go)
        all_go_pre(i) = SUB(i).lat_pre_go;
    end
end

all_nogo_pre = nan(1, numel(SUB));  % Preallocate with NaN
for i = 1:numel(SUB)
    if ~isempty(SUB(i).lat_pre_nogo)
        all_nogo_pre(i) = SUB(i).lat_pre_nogo;
    end
end

all_go_post = nan(1, numel(SUB));  % Preallocate with NaN
for i = 1:numel(SUB)
    if ~isempty(SUB(i).lat_post_go)
        all_go_post(i) = SUB(i).lat_post_go;
    end
end

all_nogo_post = nan(1, numel(SUB));  % Preallocate with NaN
for i = 1:numel(SUB)
    if ~isempty(SUB(i).lat_post_nogo)
        all_nogo_post(i) = SUB(i).lat_post_nogo;
    end
end


T = table(ID, group, all_go_pre', all_nogo_pre', all_go_post', all_nogo_post');
T.Properties.VariableNames = {'ID', 'Group', 'Go_Pre', 'NoGo_Pre', 'Go_Post', 'NoGo_Post' } ;
writetable(T, [PATHOUT,'Latencies_GNG.txt']);


%% Analysis

N2_st = 244;
N2_sp = 324;

for sub = 1:length(SUB)

    % first, load epoched data ------------------------------------------------------------------
    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;                                                     % start EEGLAB

    SUBEPOGNG = [EPOGNG, sub_folders(sub).name, '\'];                                                          % define path to current subject
    cd(SUBEPOGNG)                                                                                  % set filepath

    files = dir(fullfile(SUBEPOGNG, '*.set'));                                                     % get access to data sets

    for file = 1:length(files)

        % Preparations ---------------------------------------------------------------------------

        file_name = files(file).name;                                                               % get file name

        if contains(file_name, 'circle')                                                            % = NOGO
            event_count = 1;
        elseif contains(file_name, 'square')                                                        % = GO
            event_count = 2;
        end
        
        if contains(file_name, 'pre')
            cond_count = 1;
        elseif contains(file_name, 'post')
            cond_count = 2;
        end

        EEG = pop_loadset([SUBEPOGNG, file_name]);                                                 % load data set
        EEG.setname = file_name;                                                                    % give file a namne
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );                                    % store in ALLEEG

        % last preparations & sorting stuff ------------------------------------------------------

        if strcmp(SUB(sub).ID, 'sports_01') && file == 1
            chanlocs_swim = EEG.chanlocs;                                                           % chanlocs for later topoplots

        elseif strcmp(SUB(sub).ID, 'sports_43') && file == 1
            chanlocs = EEG.chanlocs;                                                                % chanlocs for later topoplots
        end

        EEG = pop_select( EEG, 'nochannel', NOCHANS);                                               % exclude channels missing in swim

        P3_start_pos = find(EEG.times == P3_st);                                                    % P3 start timepoint on EEG.times
        P3_stop_pos = find(EEG.times==P3_sp);                                                       % P3 stop timepoint on EEG.times

        N2_start_pos = find(EEG.times == N2_st);                                                    % N2 start timepoint on EEG.times
        N2_stop_pos = find(EEG.times==N2_sp);                                                       % N2 stop timepoint on EEG.times

        ROI_chans_N2 = find(strcmp(ROI_N2{1}, {EEG.chanlocs.labels}));
        ROI_chans_P3 = find(strcmp(ROI_P3{1}, {EEG.chanlocs.labels}));

        
        % PRE - NOGO      
        if event_count == 1 && cond_count == 1 

            % N2
            ROI_ERP_pre_nogo = squeeze(mean(mean(EEG.data(ROI_chans_N2,:,:),3),1));    
            chanERP = ROI_ERP_pre_nogo(N2_start_pos:N2_stop_pos);                                    % ERP
            SUB(sub).amp_pre_nogo = mean(chanERP);                                                   % amplitude mean, in accordance with Maria

            SUB(sub).ERP_pre_nogo = ROI_ERP_pre_nogo;
            GA_pre_nogo(:,:,sub) = ROI_ERP_pre_nogo;
            TOPO_pre_nogo(:,:,sub) = squeeze(mean(mean(EEG.data(:,N2_start_pos:N2_stop_pos,:),3),2));

            n2_peak = min(chanERP);
            SUB(sub).lat_pre_nogo = GA.timevec(find(ROI_ERP_pre_nogo == n2_peak));

        
        % PRE - GO    
        elseif event_count == 2 && cond_count == 1 

            % P3
            ROI_ERP_pre_go = squeeze(mean(mean(EEG.data(ROI_chans_P3,:,:),3),1));    
            chanERP = ROI_ERP_pre_go(P3_start_pos:P3_stop_pos);                                    % ERP
            SUB(sub).amp_pre_go = mean(chanERP);                                                   % amplitude mean, in accordance with Maria

            SUB(sub).ERP_pre_go = ROI_ERP_pre_go;
            GA_pre_go(:,:,sub) = ROI_ERP_pre_go;
            TOPO_pre_go(:,:,sub) = squeeze(mean(mean(EEG.data(:,P3_start_pos:P3_stop_pos,:),3),2));

            p3_peak = max(chanERP);
            SUB(sub).lat_pre_go = GA.timevec(find(ROI_ERP_pre_go == p3_peak));

        
        % POST - NOGO
        elseif event_count == 1 && cond_count == 2

            % N2
            ROI_ERP_post_nogo = squeeze(mean(mean(EEG.data(ROI_chans_N2,:,:),3),1));    
            chanERP = ROI_ERP_post_nogo(N2_start_pos:N2_stop_pos);                                    % ERP
            SUB(sub).amp_post_nogo = mean(chanERP);                                                   % amplitude mean, in accordance with Maria

            SUB(sub).ERP_post_nogo = ROI_ERP_post_nogo;
            GA_post_nogo(:,:,sub) = ROI_ERP_post_nogo;
            TOPO_post_nogo(:,:,sub) = squeeze(mean(mean(EEG.data(:,N2_start_pos:N2_stop_pos,:),3),2));

            n2_peak = min(chanERP);
            SUB(sub).lat_post_nogo = GA.timevec(find(ROI_ERP_post_nogo == n2_peak));


        % POST - GO
        elseif event_count == 2 && cond_count == 2

            % P3
            ROI_ERP_post_go = squeeze(mean(mean(EEG.data(ROI_chans_P3,:,:),3),1));    
            chanERP = ROI_ERP_post_go(P3_start_pos:P3_stop_pos);                                    % ERP
            SUB(sub).amp_post_go = mean(chanERP);                                                   % amplitude mean, in accordance with Maria

            SUB(sub).ERP_post_go = ROI_ERP_post_go;
            GA_post_go(:,:,sub) = ROI_ERP_post_go;
            TOPO_post_go(:,:,sub) = squeeze(mean(mean(EEG.data(:,P3_start_pos:P3_stop_pos,:),3),2));

            p3_peak = max(chanERP);
            SUB(sub).lat_post_go = GA.timevec(find(ROI_ERP_post_go == p3_peak));
        
        end
       
    end
    
end


%% save

save([PATHOUT,'SUB_PT'],'SUB');

GA.pre_go = GA_pre_go;
GA.pre_nogo = GA_pre_nogo;
GA.post_go = GA_post_go;
GA.post_nogo = GA_post_nogo;

GA.topo_pre_go = TOPO_pre_go;
GA.topo_pre_nogo = TOPO_pre_nogo;
GA.topo_post_go = TOPO_post_go;
GA.topo_post_nogo = TOPO_post_nogo;


save([PATHOUT,'GA'],'GA');

%% get an overview for values

all_go_pre = extractfield(SUB, 'amp_pre_go');
mean_go_pre = mean(cell2mat(all_go_pre(~cellfun('isempty',all_go_pre))));

all_nogo_pre = extractfield(SUB, 'amp_pre_nogo');
mean_nogo_pre = mean(cell2mat(all_nogo_pre(~cellfun('isempty',all_nogo_pre))));

all_go_post = extractfield(SUB, 'amp_post_go');
mean_go_post = mean(cell2mat(all_go_post(~cellfun('isempty',all_go_post))));

all_nogo_post = extractfield(SUB, 'amp_post_nogo');
mean_nogo_post = mean(cell2mat(all_nogo_post(~cellfun('isempty',all_nogo_post))));


%% preliminary plots

pre_hit = mean(GA_pre_go, 3);
pre_miss = mean(GA_pre_nogo, 3);
post_hit = mean(GA_post_go, 3);
post_miss = mean(GA_post_nogo, 3);

figure;
plot(EEG.times, pre_hit);
hold on
plot(EEG.times, pre_miss);
%ylim([-2, 4])
legend('pre_go', 'pre_nogo')

figure;
plot(EEG.times, post_hit);
hold on
plot(EEG.times, post_miss);
%ylim([-2, 4])
legend('post_go', 'post_nogo')


figure;
subplot(221)
topoplot(squeeze(mean(TOPO_pre_go, 3)), chanlocs_swim);
colorbar;
clim([-1.5 1.5])
title('Pre Go')

subplot(222)
topoplot(squeeze(mean(TOPO_pre_nogo, 3)), chanlocs_swim);
colorbar;
clim([-1.5 1.5])
title('Pre NoGo')

subplot(223)
topoplot(squeeze(mean(TOPO_post_go, 3)), chanlocs_swim);
colorbar;
clim([-1.5 1.5])
title('Post Go')

subplot(224)
topoplot(squeeze(mean(TOPO_post_nogo, 3)), chanlocs_swim);
colorbar;
clim([-1.5 1.5])
title('Post NoGo')





