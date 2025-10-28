%% mek_sports01_05_EPO_GNG
%
%
%  PURPOSE:
%  Create Go/No-Go (GNG) epochs from ICA-corrected EEG data for each subject.
%
%  WORKFLOW:
%    1. Load ICA-corrected EEG datasets (from ana_03_ICA/CorrectedFiles)
%    2. Handle subject-specific exceptions for missing or corrupted blocks
%    3. Epoch the data around GNG events (-200 to 1200 ms)
%    4. Apply baseline correction and artifact rejection
%    5. Re-reference to mastoid electrodes (TP9, TP10)
%    6. Save separate GNG-epoch files for "circle" and "square" events
%
%  INPUTS:
%    - SUB_PT.mat: subject structure with IDs and metadata
%    - ICA-corrected .set files (one or more per subject)
%
%  OUTPUTS:
%    - Epoched datasets per event and block, stored in:
%         derivatives/ana_05_epo-gng/<subject>/
%
%  PARAMETERS:
%    - Epoch window: FROM = -0.2 s, TO = 1.2 s
%    - Rejection threshold (jointprob & kurtosis): REJ = 5
%
%  DEPENDENCIES:
%    - EEGLAB toolbox
%    - pop_epoch, pop_rmbase, pop_jointprob, pop_rejkurt, pop_reref
%
%  NOTES:
%    - Certain participants (e.g., sports_05, _06, _26, _39, etc.)
%      require special handling due to missing or corrupted data blocks.
%    - Epochs are created separately for each GNG stimulus type
%      ("circle" and "square").
% 

%% preparations

clear all; close all; clc;                                                                          % clear workspace

MAINPATH = 'Q:\Neuro\data\projects\mek_sports01\eegl\';                                             % define mainpath

PATHOUT = [MAINPATH,'derivatives\'];                                                                % path for saving data
ICAPATH = [PATHOUT, 'ana_03_ICA\'];                                                                 % path for ICA-related data
EPOGNG = [PATHOUT, 'ana_05_epo-gng\'];                                                              % path for SME epoch data 

if ~isfolder(EPOGNG)                                                                                % if the path doesn't exist yet, create it
    mkdir(EPOGNG)
end

COND = {'pre', 'post'};

REJ = 5;
FROM = -0.2;
TO = 1.2;

load([PATHOUT,'SUB_PT.mat']);

CONDS= {'hit pre', 'hit post', 'miss pre', 'miss post'};
RUNS = {'pre', 'int', 'post'};
EVENTS = {'circle', 'square'};
ANSWERS = {'7', '77'};

all_folders = dir(MAINPATH);
sub_folders = all_folders(11:100);


%% Analysis


for sub = 1:length(SUB)

    SUBICAPATH = [ICAPATH, sub_folders(sub).name, '\CorrectedFiles\'];

    cd(SUBICAPATH)                                                                                    % set filepath
    files = dir(fullfile(SUBICAPATH, '*.set'));                                                       % get access to data sets
  
    SUBEPOGNG = [EPOGNG, sub_folders(sub).name, '\'];
    mkdir(SUBEPOGNG)

    % adjustment for our special snowflakes ------------------------------------------------------

    if strcmp(SUB(sub).ID, 'sports_05') || strcmp(SUB(sub).ID, 'sports_14') || strcmp(SUB(sub).ID, 'sports_21') || ...
            strcmp(SUB(sub).ID, 'sports_42') || strcmp(SUB(sub).ID, 'sports_89') || strcmp(SUB(sub).ID, 'sports_94') ||...
            strcmp(SUB(sub).ID, 'sports_96')

        COND = {'pre'};                                                                             % something is wrong with post 
        files = files(1); 
        

    elseif strcmp(SUB(sub).ID, 'sports_06') || strcmp(SUB(sub).ID, 'sports_28') || strcmp(SUB(sub).ID, 'sports_32') || ...
            strcmp(SUB(sub).ID, 'sports_35') || strcmp(SUB(sub).ID, 'sports_73') 

        COND = {'post'};                                                                            % something is wrong with pre  

        if strcmp(SUB(sub).ID, 'sports_06')
            files = files(2);                                                                               
        else
            files = files(3);
        end

    elseif strcmp(SUB(sub).ID, 'sports_26') || strcmp(SUB(sub).ID, 'sports_39')
        COND = {'pre', 'post'};                                                                     % something went wrong with int
        files = [files(1), files(2)];
    
    else
        COND = {'pre', 'post'};                                                                     % the normal case :')
        files = [files(1), files(3)];
    end


    % start sorting out epochs -------------------------------------------------------------------
    
    for file = 1:size(files, 2)

        file_name = files(file).name;
    
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
        EEG = pop_loadset('filename',file_name,'filepath',SUBICAPATH);
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );                                    % store data set = ALLEEG(1)
        
        nchan = EEG.nbchan;

        refchans = strmatch('TP', {EEG.chanlocs.labels});                                           % find mastoid electrodes
        EEG = pop_epoch( EEG, EVENTS, [FROM TO], 'epochinfo', 'yes');                               % cut GNG-epochs from -.2 to 0.8 s
        EEG = pop_rmbase( EEG, [FROM*1000 0] ,[]); 

        EEG = pop_jointprob(EEG,1,[1:nchan] ,REJ,REJ,0,1,0,[],0);                                   % artefact correction using joint probabilities
        EEG = pop_rejkurt(EEG,1,[1:nchan] ,REJ,REJ,0,1,0,[],0);                                     % artefact correction using channel kurtosis
        EEG = pop_reref(EEG, refchans);                                                             % re-reference data to TP9 and TP10
        EEG.setname = [SUB(sub).ID, '_block-', num2str(file), COND{file} , '_epochs-gng'];          % new set name
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);                                           % save as new set (ALLEEG(2))

        nchan = EEG.nbchan; 


         for e = 1:length(EVENTS)                                                                   % go through event names
    
            EEG = pop_selectevent(ALLEEG(2), 'latency','-2<=2','type',...                           % select events
                {EVENTS{e}},'deleteevents','off','deleteepochs','on','invertepochs','off');
            
            [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);                                       % save as new set (ALLEEG(2))
            EEG.setname = [SUB(sub).ID, '_block-', num2str(file), COND{file} , '_epochs-gng', '-', EVENTS{e}];  % store as separate set
            EEG = pop_saveset(EEG, 'filename', [EEG.setname], 'filepath', SUBEPOGNG);               % save data set

        
         end

    end
end



%% 
