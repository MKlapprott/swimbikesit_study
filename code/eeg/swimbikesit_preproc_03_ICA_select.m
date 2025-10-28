%% mek_sports01_03_ICArun.m
%
%  PURPOSE:
%  This script visualizes and classifies ICA components from preprocessed EEG data.
%  It either:
%    - Runs ICLabel classification and saves plots (for SIT and BIKE groups)
%    - Opens interactive plots for manual IC rejection (for SWIM group)
%
%  INPUTS:
%    - Subject structure (SUB_PT.mat) containing ID, GROUP, etc.
%    - ICA-decomposed EEG datasets in ana_03_ICA/ per subject
%
%  OUTPUTS:
%    - Updated EEG datasets including the field "EEG.badics"
%    - PNG plots for ICLabel or topography visualization
%
%  DEPENDENCIES:
%    - EEGLAB (v2022.x or newer)
%    - ICLabel plugin (for automatic classification)
%
%  NOTES:
%    - Some subjects require manual correction:
%        * swim_11: channel 14 was additionally interpolated and appears as noisy IC #1
%        * swim_04: channels O2 and TP10 are excluded due to noise and insufficient neighbours
%
%
% Melanie, 2025

%% Preparation
clear all; close all; clc;                                                                          % clear workspace

MAINPATH = 'Q:\Neuro\data\projects\mek_sports01\eegl\BIDS\';                                        % define mainpath
RAWPATH = [MAINPATH,'rawdata\'];                                                                    % define path for raw data
PATHOUT = [MAINPATH,'derivatives\'];                                                                % path for saving data
ICAPATH = [PATHOUT, 'ana_03_ICA\'];


load([PATHOUT,'SUB_PT.mat']);                                                                       % load subject structure

all_folders = dir(MAINPATH);
sub_folders = all_folders(11:100);

%% ICA plots and decision


for sub = 82:length(SUB)
    
    % prepare data load & load it ----------------------------------------------------------------

    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;                                                     % start EEGLAB

    FILEPATH = [ICAPATH, sub_folders(sub).name, '\'];
    cd(FILEPATH)

    files = dir(fullfile(FILEPATH, '*.set'));                                                       % get access to data sets
    file_name = files.name;                                                                         % get name of the current file

    EEG = pop_loadset([FILEPATH, file_name]);                                                       % load data set
    EEG.setname = file_name;                                                                        % give data set a name
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
    
    if isfield(EEG, 'badics')                                                                       % if this field exists...
        EEG = rmfield(EEG, 'badics');                                                               % throw it out
    end

    if strcmp(SUB(sub).GROUP, 'sit') || strcmp(SUB(sub).GROUP, 'bike') 

        % ICLABEL path ---------------------------------------------------------------------------
    
        EEG = pop_iclabel(EEG, 'default');
        pop_viewprops(EEG, 0, [1:EEG.nbchan], {'freqrange', [2 80]}, {}, 1, 'ICLabel')              % for component properties
        saveas(gca, [SUB(sub).ID, '-ICLabel.png']);                                                 % save plot
    
        badICs_muscle = find(EEG.etc.ic_classification.ICLabel.classifications(:,2) >= 0.8);        % look for muscle components
        badICs_eye = find(EEG.etc.ic_classification.ICLabel.classifications(:,3) >= 0.8);           % look for eye components
        badICs_chans = find(EEG.etc.ic_classification.ICLabel.classifications(:,6) >= 0.8);         % look for bad channel components
    
        badICs_all = [badICs_muscle; badICs_eye; badICs_chans]';                                    % gather them
        badICs_all = sort(badICs_all);                                                              % sort them
    
        EEG.badics = badICs_all;                                                                    % save in EEG structure
        SUB(sub).badics = EEG.badics;                                                               % save in SUB structure, doesn't hurt

    elseif strcmp(SUB(sub).GROUP, 'swim') 

    % Manual path --------------------------------------------------------------------------------

        pop_eegplot(EEG, 0,0,0)                                                                     % plot component time course  
        
        pop_topoplot(EEG, 0, [1:EEG.nbchan], ['Component Topographies for Subject ', SUB(sub).ID]...
            , [6 6], 0, 'electrodes', 'on');                                                        % standard ICA topoplot
        saveas(gca, [SUB(sub).ID, '-ICA-Topos.png']);                                           % save plot

        EEG.badics = input('Enter bad component indices: ');                                        % save in EEG structure
        SUB(sub).badics = EEG.badics;                                                               % save in SUB structure, doesn't hurt
        

    end
    
    % save plots and data set --------------------------------------------------------------------

    EEG.setname = [SUB(sub).ID, '_preproc-BadICs'];                                                 % new set name
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);                                               % save as new set
    EEG = pop_saveset(EEG, 'filename', EEG.setname, 'filepath', FILEPATH);                          % save data set

    close all;

end


%% 
% save struct!

save([PATHOUT,'SUB_PT'],'SUB');