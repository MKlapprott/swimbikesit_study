%% mek_sports01_02_ICA.m
%
%  PURPOSE:
%  This script prepares cleaned EEG data for ICA decomposition.
%  It performs the following main steps:
%    1. Loads preprocessed data after bad channel inspection
%    2. Merges all sessions per subject
%    3. Removes bad channels
%    4. Optionally cleans data from swimmers using ASR
%    5. Runs ICA decomposition
%
%  INPUTS:
%    - BIDS structure with subject subfolders under MAINPATH
%    - SUB_PT.mat (table with columns: ID, GROUP, etc.)
%    - preprocessed .set files from ana_01_firstCheck/
%
%  OUTPUTS:
%    - Merged and interpolated datasets saved in ana_02_AfterInterp/
%    - ICA weights saved in ana_03_ICA/
%
%  DEPENDENCIES:
%    - EEGLAB (v2022.x or newer)
%    - clean_rawdata plugin (for ASR)
%
%  NOTE:
%    - Some subjects have special merging rules (sports_06, sports_26, sports_39)
%    - Update MAINPATH if running on a different system
%
% Melanie, 2025

%% Preparation
clear all; close all; clc;                                                                          % clear workspace

MAINPATH = 'Q:\Neuro\data\projects\mek_sports01\eegl\BIDS\';                                             % define mainpath
PATHOUT = [MAINPATH,'derivatives\'];                                                                % path for saving data
CHECKPATH = [PATHOUT, 'ana_01_firstCheck\'];                                               % path for the first check of the data

INTERPPATH = [PATHOUT, 'ana_02_AfterInterp\'];                                             % path for interpolated data
if ~isfolder(INTERPPATH)                                                                               % if the path doesn't exist yet, create it
    mkdir(INTERPPATH)
end

ICAPATH = [PATHOUT, 'ana_03_ICA\'];
if ~isfolder(ICAPATH)                                                                               % if the path doesn't exist yet, create it
    mkdir(ICAPATH)
end


% set parameters ---------------------------------------------------------------------------------

REJ = 3;                                                                                            % rejection parameter
asr_thresh = 70;                                                                                    % very conservative threshold
load([PATHOUT,'SUB_PT.mat']);                                                                       % load subject structure

all_folders = dir(MAINPATH);
sub_folders = all_folders(11:100);

%% Start Processing

for sub = 1:length(SUB)                                                                      % loop over subjects
    

    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;                                                     % start EEGLAB

    FILEPATH = [CHECKPATH, sub_folders(sub).name, '\'];                                                   % define path to current subject
    cd(FILEPATH)                                                                                    % set filepath
    files = dir(fullfile(FILEPATH, '*.set'));                                                       % get access to data sets
    num_files = length(files);                                                                      % update number of files

    badchans = [];

    % some special treatment for my special snowflakes -------------------------------------------

    COND = {'pre', 'int', 'post'};

    if strcmp(SUB(sub).ID, 'sports_06')
        COND = {'int', 'post'};

    elseif strcmp(SUB(sub).ID, 'sports_39')
        COND = {'pre', 'post'};

    end

    % start loop ---------------------------------------------------------------------------------

    for file = 1:num_files                                                                          % loop over files within subject
        
        % start with getting the info about bad channels -----------------------------------------
        file_name = files(file).name;                                                               % get name of the current file

        EEG = pop_loadset([FILEPATH, file_name]);                                                   % load data set
        EEG.setname = file_name;                            % give data set a name
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);

        if ~isempty(EEG.badchans)
            badchans = [badchans, EEG.badchans];                                                    % save bad channel info in variable
        end                                                                    % save bad channel info in variable

    end

    subs_badchans = unique(badchans);                                                               % create one vector with all bcs per subj
    subs_badchans = nonzeros(subs_badchans);
    SUB(sub).badchans = subs_badchans;

    for file = 1:num_files                                                                          % go through all the files available
        if ~isempty(subs_badchans)                                                                  % if there are bad channels ..
        
            ALLEEG(file).badchans = subs_badchans;                                                  % add bad channels to EEG struct
            ALLEEG(file) = pop_select(ALLEEG(file), 'nochannel', subs_badchans);                    % and remove bad channels
            
        end
    end

    % merging of all data sets available for subjects --------------------------------------------

    if num_files == 2
        EEG = pop_mergeset( ALLEEG, [1  2], 0);                                                     % in the last 2, I only have 2 data sets to merge
        EEG.setname = [SUB(sub).ID,'_preproc-Merged'];   % give set name
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG);                                        % store data set

    elseif strcmp(SUB(sub).ID, 'sports_26')
        EEG = pop_mergeset( ALLEEG, [1  3], 0);                                                     % in the last 2, I only have 2 data sets to merge
        EEG.setname = [SUB(sub).ID,'_preproc-Merged'];   % give set name
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG);                                        % store data set
        
    elseif num_files == 3
        EEG = pop_mergeset( ALLEEG, [1  2  3], 0);                                                  % merge all 3 data sets
        EEG.setname = [SUB(sub).ID, '_preproc-Merged'];   % give set name
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG);                                        % store data set
    end 

    SUBINTERPPATH = [INTERPPATH, SUB(sub).ID, '\'];
    if ~isfolder(SUBINTERPPATH)                                                                        % if the path doesn't exist yet, create it
        mkdir(SUBINTERPPATH)
    end

    EEG = pop_saveset(EEG, 'filename', EEG.setname, 'filepath', SUBINTERPPATH);  % save data set
    
    % clean swim data with ASR -------------------------------------------------------------------

    if strcmp(SUB(sub).GROUP, 'swim')

        from = round(EEG.event(strcmp({EEG.event.type}, 'EyesOpenStart')).latency);                 % extract calib data
        mybaseline = pop_select(EEG, 'point', [from:from+60*EEG.srate]);                            % 1min baseline recording
    
        to = length(EEG.data);                                                                      % border for calib data
        EEG = pop_select(EEG, 'point', [from+60*EEG.srate:to]);                                     % select calib data
        data_old = EEG.data;                                                                        % save old version just in case
        
        EEG = clean_asr(EEG,asr_thresh,[],[],[],mybaseline);                                        % clean with ASR

    end

    % continue with real preparation for ICA -----------------------------------------------------

    EEG = eeg_regepochs(EEG);                                                                       % cut in 1s epochs
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);                                             % store data set

    SUB(sub).nchans_ICA = EEG.nbchan;                                                               % update number of channels

    EEG = pop_jointprob(EEG,1,[1:EEG.nbchan] ,REJ,REJ,0,1,0,[],0);                                  % artefact correction using joint probabilities
    EEG = pop_rejkurt(EEG,1,[1:EEG.nbchan] ,REJ,REJ,0,1,0,[],0);                                    % artefact correction using channel kurtosis

    EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'interrupt','on');                      % run ICA
    EEG.setname = [SUB(sub).ID, '_preproc-ICAWeights'];                                             % give set name
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);                                               % save as new set

    SUBICAPATH = [ICAPATH, sub_folders(sub).name, '\'];
    if ~isfolder(SUBICAPATH)                                                                        % if the path doesn't exist yet, create it
        mkdir(SUBICAPATH)
    end

    EEG = pop_saveset(EEG, 'filename', EEG.setname, 'filepath', SUBICAPATH);                        % save data set


end

   
eeglab redraw



%% 


