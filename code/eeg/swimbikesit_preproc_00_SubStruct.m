%% mek_sports01_subject_structure
%
% first part of data analysis (real version). Goal: to set sub a struct
% containing all the information about the subjects.
%
% Setps:
%   - loop across subjects
%   - take the recall file
%   - take the info file (incl. list order!)
%   - search for xdf files
%   - loop across xdf files (pre vs. post), be aware that both contain two trials!
%   - take out information about events
%   - store info about words (contained in triggers)
%   - sort words as hit, miss and intrusions
%   - save everything and all information in the structure
%
% excl because of exlusion criteria:
%   - S04
%   - S38
% excl because at least 2 measurements are corrupted:
%   - S16
%   - S29
%   - S53
%   - S60
%   - S24
%
% Incomplete data (intervention missing / shit) -> 4x. No problem for word analysis!
%   - S22
%   - S23
%   - S30
%   - S39
% Incomplete data (pre missing) -> 1x file non-existent. 2x isempty(EEG.event)
%   - S06 file non-existent
%   - S28 events missing
%   - S32 events missing
% Incomplete data (post missing) -> 2x recording only for 2nd half. 2x isempty(EEG.event). 1x length(EEG.event) < 30
%   - S05 half
%   - S14 post very short
%   - S21 events in post missing
%   - S42 events in post missing
%   - S89 events in post missing
%   - S94 post very short
%
% To DO: adjust code for weird things that happened. For those where behavioural is there, but
% not EEG: make a separate skript to check for congruency of word lists and
% recalled lists!


%% preparation (paths etc.)


clear all; close all; clc;                                                                          % clear workspace

MAINPATH = 'Q:\Neuro\data\projects\mek_sports01\eegl\BIDS\';                                             % define mainpath
PATHOUT = [MAINPATH,'derivatives\'];                                                                % path for saving data


cd(MAINPATH);                                                                                         % set directory to raw path
subs_info = readtable([MAINPATH, 'mek_sports01_sub_info_excl.xlsx']);                                      % read the big info file
[~, ~, lists] = xlsread([MAINPATH, 'stimuli\lists.xlsx'],'Tabelle1');                                        % import the lists
lists = lists(2:end, 1:4);
subs = table2cell(subs_info(:,1));                                                                  % extract subject names

sub_struct_idx = 1;    

all_folders = dir(MAINPATH);
sub_folders = all_folders(10:99);

%% set up struc
for sub = 11:length(subs)                                                                            % loop over subjects

    le_time = {'pre', 'post'};                                                                      % time-wise conditions
    sub_folder = sub_folders(sub).name;
    SUBPATHIN = [MAINPATH, sub_folder, '\'];                                                          % create sub-specific path
   
    % collection of general info -----------------------------------------------------------------

    files = dir(fullfile([SUBPATHIN, 'beh\'], '*.tsv'));
    recall_perf = readtable([SUBPATHIN, 'beh\', files.name], "FileType","text",'Delimiter', '\t'); % info about recalled words
    recall_perf = table2cell(recall_perf);

    % Initialize subject structure
    sub_struct.ID = subs{sub};
    sub_struct.SEX = subs_info{sub, 'sex'}{1};
    sub_struct.AGE = subs_info{sub, 'age'};
    sub_struct.GROUP = subs_info{sub, 'group'};
    sub_struct.YOT = subs_info{sub, 'yot'};
    sub_struct.DIST = subs_info{sub, 'dist'};
    sub_struct.LIST_ORDER = subs_info{sub, 22:25};
    sub_struct.HR.PRE = subs_info{sub, 'hr_pre'};
    sub_struct.HR.INT = subs_info{sub, 'hr_int'};
    sub_struct.HR.POST = subs_info{sub, 'hr_post'};
    sub_struct.REMARK = subs_info{sub, 'comments'}{1};
    sub_struct.TIME = {'pre', 'pre', 'post', 'post'};

    conds = {'pre', 'post'};
    list_idx = {[1 2], [3 4]}; % List_1 & 2 for pre, List_3 & 4 for post
    recall_col = {[1 2], [3 4]}; % columns in recall_perf


    % Loop through pre/post
    for c = 1:2
        for list = 1:2
            idx_list = subs_info(sub, sprintf('List_%d', list_idx{c}(list)));
            curr_list = lists(:, idx_list{1,1});
            curr_col = recall_col{c}(list);

            recall_perf_order = zeros(1,36);
            intrusions = {};

            for r = 1:size(recall_perf,1)
                if sum(strcmp(curr_list(:), recall_perf(r, curr_col))) < 1
                    if ~strcmp(recall_perf(r, curr_col), '')
                        intrusions{end+1} = recall_perf(r, curr_col);
                    end
                else
                    recall_perf_order(strcmp(curr_list(:), recall_perf(r, curr_col))) = 1;
                end
            end

            sub_struct.WORDS{curr_col} = curr_list;
            sub_struct.RECALL.PERFORMANCE{curr_col} = recall_perf_order;
            sub_struct.RECALL.INTRUSIONS{curr_col} = intrusions;
        end
    end

    SUB(sub_struct_idx) = sub_struct;
    sub_struct_idx = sub_struct_idx + 1;
    

end	                                                                                                % ends the loop across subjects


save([PATHOUT,'SUB_PT'],'SUB');                                                                     % save struct

%% end



