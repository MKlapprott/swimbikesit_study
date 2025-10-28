%% mek_sports_03_ICAapp.m
%
%   PURPOSE:
%  Apply ICA weights and remove artifactual components from all EEG blocks.
%
%  WORKFLOW:
%    1. Load ICA-decomposed data (from ana_03_ICA/)
%    2. Extract and reuse ICA weights for corresponding raw datasets
%    3. Remove previously identified bad ICs
%    4. Remove and later interpolate bad channels
%    5. Save corrected datasets per subject and block
%
%  INPUTS:
%    - SUB_PT.mat: subject structure (including badchans and badics)
%    - Preprocessed and ICA-weighted .set files for each subject
%
%  OUTPUTS:
%    - ICA-corrected datasets per block, saved in "CorrectedFiles" folders
%
%  DEPENDENCIES:
%    - EEGLAB toolbox
%    - pop_iclabel, pop_subcomp, pop_interp
%
%  NOTES:
%    - Certain subjects have missing or incomplete blocks (sports_06, 26, 39)
%    - Bad channel and component information are copied from SUB structure
%    - ICA weights are transferred from the ICA dataset to raw blocks
%
%
% Melanie, 2025

%% Preparations

clear all; close all; clc;                                                                          % clear workspace

MAINPATH = 'Q:\Neuro\data\projects\mek_sports01\eegl\BIDS\';                                             % define mainpath
PATHOUT = [MAINPATH,'derivatives\'];                                                                % path for saving data
CHECKPATH = [PATHOUT, 'ana_01_firstCheck\'];                                               % path for the first check of the data
ICAPATH = [PATHOUT, 'ana_03_ICA\'];

% set parameters ---------------------------------------------------------------------------------

load([PATHOUT,'SUB_PT.mat']);                                                                       % load subject structure

all_folders = dir(MAINPATH);
sub_folders = all_folders(11:100);

%% ICA rejection


for sub = 22:length(SUB)

    % first, load ICA-weighted data to get the weights -------------------------------------------
    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;                                                     % start EEGLAB
    
    FILEPATH = [ICAPATH, sub_folders(sub).name, '\'];                                                         % define path to current subject
    cd(FILEPATH)                                                                                    % set filepath
    files = dir(fullfile(FILEPATH, '*.set'));                                                       % get access to data sets

    file_name = files(1).name;
    
    EEG = pop_loadset([FILEPATH, file_name]);                                                       % load data set
    EEG.setname = file_name;
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );                                        % store data set = ALLEEG(1)
    
    % extract bad channel info -------------------------------------------------------------------

    if size(SUB(sub).badchans, 2) == 3

        badchans = [SUB(sub).badchans{1}, SUB(sub).badchans{2}, SUB(sub).badchans{3}];
        badchans = unique(badchans);
        badchans = nonzeros(badchans);
        badchans = sort(badchans);

    elseif size(SUB(sub).badchans, 2) == 2

        badchans = [SUB(sub).badchans{1}, SUB(sub).badchans{2}];
        badchans = unique(badchans);
        badchans = nonzeros(badchans);
        badchans = sort(badchans);
    
    end

    SUBCHECKPATH = [CHECKPATH, SUB(sub).ID, '\'];
    cd(SUBCHECKPATH)
    files = dir(fullfile(SUBCHECKPATH, '*.set'));                                                   % get access to data sets
    
    % some special treatment for my special snowflakes -------------------------------------------

    COND = {'pre', 'int', 'post'};

    if strcmp(SUB(sub).ID, 'sports_06')
        COND = {'int', 'post'};

    elseif strcmp(SUB(sub).ID, 'sports_39')
        COND = {'pre', 'post'};

    elseif strcmp(SUB(sub).ID, 'sports_26')
        COND = {'pre', 'post'};
        files = files([1,3], 1);

    end

    % start loop ---------------------------------------------------------------------------------

    for file = 1:length(files)                                                                          % loop over files within subject
        
        % load "raw" data to kick out the channels here ----------------------------------------
         
        file_name = files(file).name;                                                               % get name of data set
        
        EEG = pop_loadset([SUBCHECKPATH, file_name]);                                                   % load data set
        EEG.setname = file_name;                            % give data set a name
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
    
        EEG.badchans = badchans;                                                                    % copy bad channel info to raw data set

        % remove bad channels --------------------------------------------------------------------

        if ~isempty(badchans)  
            
            EEG = pop_select( EEG, 'nochannel', EEG.badchans);                                      % remove bad channels

        end
    
        nchan = EEG.nbchan;

        % note to self: when analysing data during swimming: ASR!!!
        
        % Apply ICA --------------------------------------------------------------------------
    
        EEG = pop_editset(EEG, 'run', [], 'icaweights', 'ALLEEG(1).icaweights', 'icasphere', 'ALLEEG(1).icasphere');
        EEG.setname = [EEG.setname, '-ICAweights'];
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
    
        % remove bad components --------------------------------------------------------------
        
        EEG.badics = ALLEEG(1).badics;                                                          % get bad ICs
        
        if ~isempty(EEG.badics)                                                                 % if bad ICs, remove them from data
            EEG = pop_subcomp( EEG,EEG.badics, 0, 0);
            disp(['Removing components: ', mat2str(EEG.badics)])
        end

        % interpolate bad channels after proper cleaning -----------------------------------------

        if ~isempty(EEG.badchans)                                                                   % if there are bad channels...

            EEG = pop_interp(EEG, EEG.urchanlocs , 'spherical');                                    % and interpolate them using urchanlocs (thanks Thorge!!)
    
        end


        EEG.setname = [SUB(sub).ID, '_block-', COND{file}, '_preproc-ICAcorrected'];                % new set name
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);                                           % save as new set
        
        CICAPATH = [FILEPATH, 'CorrectedFiles\'];
        if ~isfolder(CICAPATH)                                                                      % if the path doesn't exist yet, create it
            mkdir(CICAPATH)
        end
    
        EEG = pop_saveset(EEG, 'filename', [num2str(file),'-', EEG.setname], 'filepath', CICAPATH); % save data set
        
    
    end                                                                                             % end loop across files
end                                                                                                 % end loop across subjects  


eeglab redraw

%%

