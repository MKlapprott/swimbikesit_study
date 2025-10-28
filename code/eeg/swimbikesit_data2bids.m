%% mek_swim01_data2bids.m
%
% 
% This script converts raw EEG and motion data from a dual-layer phantom head 
% setup into BIDS format, following the BIDS Extension Proposal (BEP) for 
% motion data. The raw EEG data originates from XDF files, which are first 
% converted to EEGLAB .set format with appropriate channel metadata (EEG, Noise, MISC). 
% Motion platform data (translational and rotational movements) is processed from .txt files.
%
% The script prepares BIDS-compliant files and metadata for both EEG and motion modalities:
% - EEG data is exported via EEGLAB's bids_export function.
% - Motion data is structured following BIDS motion modality conventions using FieldTrip.
%
% Customizations:
% - Paths must be adjusted to the user's local directory structure.
% - The script assumes a specific folder naming convention (folders containing 'stim').
% - Measurement-specific metadata (e.g., condition labels) is read from an external Excel sheet.
% 
% Dataset context:
% - Simulated ERP (N1/P3 complex) measurements on a phantom head.
% - Movements include rest, translational and rotational motions at various speeds, and walking.
%
% IMPORTANT:
% - Requires EEGLAB (with bids-matlab tools) and FieldTrip (for motion BIDS export).
% - Ensure paths and filenames in the script are correct for your environment.
% - Motion data export relies on an unofficial BIDS extension (BEP motion).
%
% Script Workflow:
% 1. Load and preprocess EEG and motion data.
% 2. Save cleaned EEG (.set) and motion (.tsv) files.
% 3. Prepare BIDS metadata (dataset_description.json, README, CHANGES, participants.tsv, etc.).
% 4. Export EEG data to BIDS structure.
% 5. Export motion data to BIDS structure.
%
% Author: Melanie, 2025


%% Preparations

clear all; close all; clc;                                                                          % clear workspace

MAINPATH = 'Q:\Neuro\data\projects\mek_sports01\eegl\';                                                   % define mainpath
EEGLABPATH = [MAINPATH, 'eeglab2022.0\'];                                                           % define path for EEGLAB
PATHIN = [MAINPATH,'rawdata\'];                                                                     % define path for raw data
PATHOUT = [PATHIN, 'BIDS_prep\']; 

if ~isfolder(PATHOUT)                                                                               % if the path doesn't exist yet, create it
    mkdir(PATHOUT)
end

cd(PATHIN)
subs_info = readtable([PATHIN, 'mek_sports01_sub_info.xlsx']);                                      % read the big info file
subs = table2cell(subs_info(:,1));                                                                  % extract subject names
groups = table2cell(subs_info(:,2));                                                                % extract subject names

eeglab

%% Analysis

sub_counter = 1;
for sub = 1:length(subs)                                                                            % loop over subjects

    SUBPATHIN = [PATHIN, subs{sub} , '\'];                                                          % create sub-specific path
    conds = {'pre', 'int', 'post'};
   
    % subject exclusion & collection of general info ---------------------------------------------

    if strcmp(subs{sub}, 'sports_04') || strcmp(subs{sub}, 'sports_38')
        disp(['Excluding ', subs{sub}, ' due to exclusion criteria.'])                              % say why subject is excluded
        
        pause(2)
        
    elseif strcmp(subs{sub}, 'sports_16') || strcmp(subs{sub}, 'sports_24') || strcmp(subs{sub}, 'sports_29') ...
            || strcmp(subs{sub}, 'sports_53') || strcmp(subs{sub}, 'sports_60')
        disp(['Exlucding ', subs{sub}, ' due to issues during data collection.'])                   % say why subject is excluded
        pause(2)

    else  
    
        files = [dir(fullfile(SUBPATHIN, '*.bdf')); dir(fullfile(SUBPATHIN, '*.xdf'))];             % get access to all files

        num_files = length(files);                                                                  % get number of files

        if strcmp(subs{sub}, 'sports_05') || strcmp(subs{sub}, 'sports_14') || strcmp(subs{sub}, 'sports_24') || ...
           strcmp(subs{sub}, 'sports_94') % post is missing
            num_files = 2;

        elseif strcmp(subs{sub}, 'sports_06')
            conds = {'int', 'post'};
            num_files = 2;
        elseif strcmp(subs{sub}, 'sports_13')
            num_files = 3;
        end


        for e = 1:num_files                                                                             % loop across files

            if strcmp(groups{sub}, 'swim') && ~strcmp(subs{sub}, 'sports_06')

                if e == 1                                                                               % sort for right file order
                    file = 2;
                elseif e == 2
                    file = 1;
                elseif e == 3
                    file = 3;
                end
            else
                file = e;
            end

            file_name = files(file).name;                                                               % get name of the file

            if strcmp(file_name(end-2:end), 'bdf')                                                      % for the bdf file 
                EEG = pop_biosig([SUBPATHIN, file_name]);                                               % load the file
                EEG = pop_chanedit(EEG, 'lookup',[MAINPATH, 'standard_1020.elc']);                      % add channel info

                NOCHANS = {'FP1', 'FP2', 'FT9', 'FT10'}; 
                EEG = pop_select( EEG, 'nochannel', NOCHANS);                                           % select relevant channels

            elseif strcmp(file_name(end-2:end), 'xdf') && strcmp(groups{sub}, 'swim')                % for the xdf file -> swim
                EEG = pop_loadxdf([SUBPATHIN, file_name]);                                              % load
                EEG = pop_chanedit(EEG, 'lookup',[MAINPATH, 'standard_1020.elc']);                      % add channel info
                NOCHANS = {'FP1', 'FP2', 'FT9', 'FT10'};
                EEG = pop_select( EEG, 'nochannel', NOCHANS);                                           % select relevant channels

                if strcmp(subs{sub}, 'sports_13') && file == 3
                    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);                                       % store in ALLEEG
                end

            elseif strcmp(file_name(end-2:end), 'xdf') && ~strcmp(groups{sub}, 'swim')               % for the xdf file -> sit and bike
                EEG = pop_loadxdf([SUBPATHIN, file_name]);                                              % load
                EEG = pop_chanedit(EEG, 'lookup',[MAINPATH, 'standard_1020.elc']);                      % add channel info
            end

            EEG.setname = [subs{sub}, '_', num2str(e), '_block-', conds{e}];
            nchan = EEG.nbchan;                                                                         % update number of channels   

            if strcmp(subs{sub}, 'sports_13') && file == 3                                            % s13 has a recording for each memory block for post

                my_file2 = files(file+1).name;                                                          % get the second file right away
                EEG = pop_loadxdf([SUBPATHIN, my_file2], 'streamtype', 'EEG', 'exclude_markerstreams', {});
                EEG = pop_chanedit(EEG, 'lookup',[MAINPATH, 'standard_1020.elc']);

                EEG = pop_select( EEG, 'nochannel', NOCHANS);                                           % exclude unnecessary channels
                EEG.setname = [subs{sub}, '-post2'];                                                  % give set a name
                [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);                                       % store in ALLEEG

                EEG = pop_mergeset(ALLEEG(1), ALLEEG(2));                                               % combine both post files to one
                EEG.setname = [subs{sub}, '-post']; 


            end                                                                                         % end if else for sub 13 

            [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'Acc'))).type] = deal('MISC');           % assign the MISC label to the IMU channels
            [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'Gyro'))).type] = deal('MISC');          % assign the MISC label to the IMU channels
            [EEG.chanlocs(find(contains({EEG.chanlocs.labels}, 'Qua'))).type] = deal('MISC');           % assign the MISC label to the IMU channels

            if sub < 10
                SUBPATHOUT = [PATHOUT, 'sub-00', num2str(sub_counter), '\'];                                               % create path for subject
            else 
                SUBPATHOUT = [PATHOUT, 'sub-0', num2str(sub_counter), '\'];
            end
            mkdir(SUBPATHOUT);
            cd(SUBPATHOUT);
            EEG = pop_saveset(EEG, 'filename', [num2str(e), '-', EEG.setname], 'filepath', SUBPATHOUT);    % save data set

        end                                                                                         % end loop across files

        % Behavioural Data -------------------------------------------------------------------

        behav_data = readtable([SUBPATHIN, 'recall_', subs{sub} ,'.xlsx']);              % info about recalled words
        behav_data .Properties.VariableNames = {'List1', 'List2', 'List3', 'List4'};
        
        cd(SUBPATHOUT);
        writetable(behav_data, ['recall_', subs{sub}, '.tsv'], 'FileType', 'text', 'Delimiter', '\t');

        sub_counter = sub_counter +1;

     end                                                                                             % end exclusion if else
     
end	                                                                                                % ends the loop across subjects

%% set up actual BIDS

% link to raw data files (EEG) -------------------------------------------------------------------

excl_id = 1;

for sub = 1:length(subs)

    % subject exclusion & collection of general info ---------------------------------------------

    if sub < 10
            SUBPATHOUT = [PATHOUT, 'sub-00', num2str(sub), '\'];                                               % create path for subject
    else 
        SUBPATHOUT = [PATHOUT, 'sub-0', num2str(sub), '\'];
    end
    subj_files = dir(fullfile([SUBPATHOUT, '*.set']));

    for r = 1:length(subj_files)
        
        data(sub).file(r).file = [subj_files(r).folder filesep subj_files(r).name]; % path + filename
        data(sub).file(r).session = 1;                                    % session (if multiple [1 2])

        if contains(subj_files(r).name, 'pre')
            data(sub).file(r).run = 1;
        elseif contains(subj_files(r).name, 'int')
            data(sub).file(r).run = 2;
        elseif contains(subj_files(r).name, 'post')
            data(sub).file(r).run = 3;
        end
           
        data(sub).file(r).subject = subs{sub};                                                  % ID
        data(sub).file(r).notes = table2cell(subs_info(sub,26));                                % comments

    end                                                                                         % end loop across files
end                                                                                                 % end loop across subjects


%%

% general information for dataset_description.json file ------------------------------------------

generalInfo.Name = 'SwimBikeSit Study';
generalInfo.BIDSVersion = 'v1.10.0';
generalInfo.DatasetType = 'raw';
generalInfo.Authors = {'Melanie Klapprott';...
    'Stefan Debener'};


% Content for README file ------------------------------------------------------------------------

README = sprintf( [ 'In this experiment participants engaged in a word list learning paradigm with' ...
    'a Go/NoGo task as a distractor between the encoding and free recall, in order to measure the ' ...
    'subsequent memory effect (SME). This memory task was performed in a PRE and a POST block. In' ...
    'between, participants engaged in an intervention (INT), that could be 20 minutes of swimming,' ...
    'cycling on a cycling ergometer or sitting and watching a sports documentary. The aim was to in-' ...
    'vestigate if the different interventions would lead to different outcomes in behavioural performance' ...
    'and EEG metrics.' ...
    '- Melanie Klapprott (Fall 2025)' ]);

% Content for CHANGES file -----------------------------------------------------------------------

CHANGES = sprintf([ 'Revision history for SwimBikeSit dataset\n\n' ...
    'version 1.0 beta - Fall 2025\n' ...
    ' - Initial release\n']);


% participant information for participants.tsv file ----------------------------------------------

pInfo = [subs_info.Properties.VariableNames; table2cell(subs_info)];

pInfoDesc.gender.Description = 'gender of the participant';
pInfoDesc.gender.Levels.m = 'male';
pInfoDesc.gender.Levels.f = 'female';

pInfoDesc.participant_id.LongName = 'Participant identifier';
pInfoDesc.participant_id.Description = 'unique participant identifier';

% has to be deleted before data sharing! only used to identify
% corresponding sourcedata
pInfoDesc.original_id.LongName = 'Original Participant identifier';
pInfoDesc.original_id.Description = 'Original unique participant identifier';

pInfoDesc.age.Description = 'age of the participant';
pInfoDesc.age.Units       = 'years';


% session information for sessions.tsv file ------------------------------------------------------

sInfo = {'session_id'; ...
    '1';
    '2';
    '3'};

% Task information for xxxx-eeg.json file --------------------------------------------------------

tInfo.EEGReference = 'FCz';
tInfo.SamplingFrequency = 250;
tInfo.PowerLineFrequency = 50;
tInfo.SoftwareFilters = 'n/a';

tInfo.CapManufacturer = 'Easycap';
tInfo.CapManufacturersModelName = 'custom passive dual layer';
tInfo.AmpManufacturer = 'mbraintrain';
tInfo.AmpManufacturersModelName = 'PRO';
tInfo.EEGChannelCount = 32;
tInfo.MISCChannelCount = 10;

tInfo.TaskName = 'Subsequent Memory Effect Paradigm';
tInfo.TaskDescription = ['Participants learned a word list followed by a 2-3min distractor task (visual Go/NoGo)' ...
    'and a free recall, before and after an intervention'];

tInfo.InstitutionName = 'University of Oldenburg';
tInfo.InstitutionalDepartmentName = 'Department of Psychology';


% event column description for xxx-events.json file (only one such file)
% ----------------------------------------------------------------------
eInfoDesc.onset.Description                        = 'Event onset';
eInfoDesc.onset.Units                              = 'millisecond';

eInfoDesc.duration.Description                     = 'Event duration';
eInfoDesc.duration.Units                           = 'millisecond';

eInfoDesc.response_time.Description                = 'Response time column not used for this data';

eInfoDesc.sample.Description                       = 'Event sample starting at 0 (Matlab convention starting at 1)';

eInfoDesc.trial_type.Description                   = 'Upper hierarchy for events in the experiment. Type of event (different from EEGLAB convention)';

eInfoDesc.trial_type.Levels.pick_condition         = 'Decide on pre or post and if eye artefacts yes or no';
eInfoDesc.trial_type.Levels.instruct_text1         = 'Instruction to the experiment';
eInfoDesc.trial_type.Levels.restInstruct           = 'Explanation of the resting measurement';
eInfoDesc.trial_type.Levels.blinkInstruct          = 'Instruction to start blinking';
eInfoDesc.trial_type.Levels.blinksStart            = 'Start of blinking phase';
eInfoDesc.trial_type.Levels.blinksEnd              = 'End of blinking phase';
eInfoDesc.trial_type.Levels.EyesMoveInstruct       = 'Instruction to move the eyes from left to right';
eInfoDesc.trial_type.Levels.EyesMoveStart          = 'Start of eye movement';
eInfoDesc.trial_type.Levels.EyesMoveEnd            = 'End of eye movement';
eInfoDesc.trial_type.Levels.EyesOpenStart          = 'Start of 1min phase of sitting with eyes open';
eInfoDesc.trial_type.Levels.EyesClosedStart        = 'Start of 1min phase of sitting with eyes closed';
eInfoDesc.trial_type.Levels.EyesClosedEnd          = 'End of 1min phase of sitting with eyes closed';
eInfoDesc.trial_type.Levels.startsoon              = 'Announcement of run start (participants touched the display to start)';


eInfoDesc.trial_type.Levels.three_word             = '3 + word presented on the screen';
eInfoDesc.trial_type.Levels.circle                 = 'NoGo stimulus';
eInfoDesc.trial_type.Levels.square                 = 'Go stimulus';
eInfoDesc.trial_type.Levels.seven                  = 'hit';
eInfoDesc.trial_type.Levels.seventyseven           = 'false alarm';



%% actual conversion

target_folder = [MAINPATH, 'BIDS\'];

%eeglab

bids_export(data, ...
    'targetdir', target_folder,...
    'taskName', 'SME',...
    'README', README,...
    'CHANGES', CHANGES,...
    'gInfo', generalInfo, ... 
    'tInfo', tInfo, ... 
    'eInfoDesc', eInfoDesc,...
    'pInfo', pInfo);


%% set up BIDS - Behavioral data
all_folders = dir(target_folder);
sub_folders = all_folders(9:98);

for sub = 7:length(sub_folders)

    sub_name = sub_folders(sub).name;
    dest_beh = fullfile(target_folder, sub_name, 'beh');

    if ~exist(dest_beh, 'dir')
        mkdir(dest_beh);
    end

    % --- find and copy TSV files ---
    tsv_files = dir(fullfile(PATHOUT, sub_name, '*.tsv'));

    for f = 1:length(tsv_files)
        src = fullfile(tsv_files(f).folder, tsv_files(f).name);
        dest = fullfile(dest_beh, sprintf('%s_task-memory_beh.tsv', sub_name));
        copyfile(src, dest);
    end

    % --- create JSON sidecar ---
    json.beh = struct( ...
        'onset', 'Time (s) from experiment start', ...
        'response_time', 'Response time in seconds', ...
        'accuracy', '1 = correct, 0 = incorrect', ...
        'block', 'Experimental block (PRE, INT, POST)');

    jsonText = jsonencode(json.beh, 'PrettyPrint', true);
    fid = fopen(fullfile(dest_beh, sprintf('%s_ses-01_task-memory_beh.json', sub_name)), 'w');
    fwrite(fid, jsonText, 'char');
    fclose(fid);

end


%%  copy other folders folders to complete BIDS structure
%  -------------------
% copyfile('../stimuli', fullfile(targetFolder, 'stimuli'), 'f'); % stimuli
copyfile(fullfile(BIDSPATH,'code'), fullfile(targetFolder, 'code'), 'f'); % scripts
copyfile(fullfile(PATHIN, 'rawdata'), fullfile(targetFolder, 'sourcedata'), 'f'); %sourcedata