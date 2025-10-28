%% mek_sports01_04_EPO_SME.m
%
%
%  Description:
%  This script processes EEG data to generate SME (subsequent memory effect)
%  epochs for each participant. It loads ICA-corrected EEG datasets, assigns
%  event types based on recall performance (hit vs. miss), cuts epochs around
%  triggers, applies baseline correction, artifact rejection, and
%  re-referencing. The processed epochs are saved for further analysis.
%
%  Special adjustments are included for participants with missing or
%  corrupted pre/post blocks.
%
%  ------------------------------------------------------------------------
%  INPUTS:
%   • SUB_PT.mat    - Participant metadata with fields:
%                     .ID, .RECALL.PERFORMANCE
%   • ICA-corrected EEG .set files in:
%                     derivatives/ana_03_ICA/<participant>/CorrectedFiles/
%
%  OUTPUTS:
%   • SME epoch datasets (.set) for each participant and condition in:
%       derivatives/ana_04_epo-sme/<participant>/
%
%  ------------------------------------------------------------------------
%  PARAMETERS:
%   • REJ = 5          % threshold for joint probability and kurtosis artifact rejection
%   • FROM = -0.2      % epoch start time (s)
%   • TO = 1.2         % epoch end time (s)
%   • COND = {'pre','post'} % conditions (modified per participant if needed)
%
%  ------------------------------------------------------------------------
%  REQUIREMENTS:
%   • MATLAB R2021b or newer
%   • EEGLAB toolbox (for EEG data handling and pop_ functions)
%   • Preprocessed ICA datasets must exist in the specified paths
%
%


%% preparations

clear all; close all; clc;                                                                          % clear workspace

MAINPATH = 'Q:\Neuro\data\projects\mek_sports01\eegl\BIDS\';                                             % define mainpath

PATHOUT = [MAINPATH,'derivatives\'];                                                                % path for saving data
ICAPATH = [PATHOUT, 'ana_03_ICA\'];                                                        % path for ICA-related data
EPOSME = [PATHOUT, 'ana_04_epo-sme\'];                                                     % path for SME epoch data 

if ~isfolder(EPOSME)                                                                                % if the path doesn't exist yet, create it
    mkdir(EPOSME)
end

COND = {'pre', 'post'};

REJ = 5;
FROM = -0.2;
TO = 1.2;

load([PATHOUT,'SUB_PT.mat']);

all_folders = dir(MAINPATH);
sub_folders = all_folders(11:100);

%%

for sub = 88:length(SUB)

    SUBICAPATH = [ICAPATH, sub_folders(sub).name, '\CorrectedFiles\'];

    cd(SUBICAPATH)                                                                                    % set filepath
    files = dir(fullfile(SUBICAPATH, '*.set'));                                                       % get access to data sets
  
    SUBEPOSME = [EPOSME, sub_folders(sub).name, '\'];
    mkdir(SUBEPOSME)

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
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );                            % store data set = ALLEEG(1)

        nchan = EEG.nbchan;


        % edit the types from the words to hit and miss + conditions -----------------------------
        % for first round ------------------------------------------------------------------------

        if file == 2
            file_idx = 3;
        elseif file == 1
            file_idx = 1;
        end

        counter = 1;

        for idx = 1:floor(length(EEG.event) / 2)-50
            if contains(EEG.event(idx).type(1), '3') && ~contains(EEG.event(idx).type, '33') && ~contains(EEG.event(idx).type, 'block')

                if SUB(sub).RECALL.PERFORMANCE{file_idx}(counter) == 1
                    EEG.event(idx).type = [COND{file}, '_hit'];
                elseif SUB(sub).RECALL.PERFORMANCE{file_idx}(counter) == 0
                    EEG.event(idx).type = [COND{file}, '_miss'];
                end
                counter = counter + 1;
            end

        end

        % for second round -----------------------------------------------------------------------

        counter = 1;
        for idx = floor(length(EEG.event) / 2)-50 : length(EEG.event)
            if contains(EEG.event(idx).type(1), '3') && ~contains(EEG.event(idx).type, '33') && ~contains(EEG.event(idx).type, 'block')

                if SUB(sub).RECALL.PERFORMANCE{file_idx+1}(counter) == 1
                    EEG.event(idx).type = [COND{file}, '_hit'];
                elseif SUB(sub).RECALL.PERFORMANCE{file_idx+1}(counter) == 0
                    EEG.event(idx).type = [COND{file}, '_miss'];
                end
                counter = counter + 1;
            end

        end
        

        % cut epochs around triggers

        EVENTS = {[COND{file}, '_hit'] , [COND{file},'_miss']};

        refchans = strmatch('TP', {EEG.chanlocs.labels});                                           % find mastoid electrodes
        EEG = pop_epoch( EEG, EVENTS, [FROM TO], 'epochinfo', 'yes');                           % cut SME-epochs from -.2 to 1.1 s
        EEG = pop_rmbase( EEG, [FROM*1000 0] ,[]);                                                  % baseline correction                                                 % baseline correction
    
        EEG = pop_jointprob(EEG,1,[1:nchan] ,REJ,REJ,0,1,0,[],0);                                   % artefact correction using joint probabilities
        EEG = pop_rejkurt(EEG,1,[1:nchan] ,REJ,REJ,0,1,0,[],0);                                     % artefact correction using channel kurtosis
        EEG = pop_reref(EEG, refchans);                                                             % re-reference data to TP9 and TP10
        EEG.setname = [SUB(sub).ID, '_block-', num2str(file), COND{file} , '_epochs-sme'];          % new set name
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);                                           % save as new set (ALLEEG)


         for e = 1:length(EVENTS)                                                            % go through event names
    
            EEG = pop_selectevent(ALLEEG(2), 'latency','-2<=2','type',...                    % select events
                {EVENTS{e}},'deleteevents','off','deleteepochs','on','invertepochs','off');

            [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);                                   % save as new set (ALLEEG)
            EEG.setname = [SUB(sub).ID, '_block-', num2str(file), COND{file} , '_epochs-sme', '-', EVENTS{e}];  % store as separate set
            EEG = pop_saveset(EEG, 'filename', [EEG.setname], 'filepath', SUBEPOSME);      % save data set

        
         end

    end
end


%% 