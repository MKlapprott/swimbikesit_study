%% mek_sports01_word_analysis
%
% Goal: Create a table for all 4 word lists and the fraction of subjects who recalled each word
%
% Steps:
%   - load the subjects structure and the list of all words
%   - loop over the subjects
%   - loop over the lists
%   - find the position of the first list in the list order vector in a participant
%   - go through that list
%   - find the respective words and their position in the individual subject word list
%   - if it was recalled, add a 1 to the count of that word, if not, not
%
% Melanie (based on Nadines script), Nov 2023

%% Preparations

clear all; close all; clc;                                                                          % clear workspace

MAINPATH = 'Q:\Neuro\data\projects\mek_sports01\eegl\';                                             % define mainpath \Neuro
EEGLABPATH = [MAINPATH, 'eeglab2022.0\'];                                                           % define path for EEGLAB
PATHIN = [MAINPATH,'rawdata\'];                                                                     % define path for raw data
PATHOUT = [MAINPATH,'derivatives\'];                                                                % path for saving data
cd(PATHOUT)


load([PATHOUT,'SUB_PT.mat']);                                                                          % load subject structure
[~, ~, lists] = xlsread([PATHOUT, 'lists.xlsx'],'Tabelle1');                                        % import the lists


lists = string(lists);                                                                              % make sure everything is a string
lists(ismissing(lists)) = '';                                                                       % replace missing entries with ''
lists = lists(2:end,1:4);                                                                           % ensure only the words from the list are in the string

sum_recall = zeros(36,4);                                                                           % pre-allocate matrix for summed recall across subs
word_pos = zeros(36,1);                                                                             % pre-allocate matrix for word position



%% Calculate recall performance 
for sub = 1:size(SUB, 2)                                                                              % loop throgh all subjects
    
    for L = 1:size(SUB(sub).WORDS, 2)                                                             % loop over all lists
        try
            b = find(SUB(sub).LIST_ORDER == L);                                                       % find out in which block list was presented
            for w = 1:36                                                                            % loop through the list
                if sum(strcmp(lists(w,L),SUB(sub).WORDS{b}))                                        % only check for words that were actually presented
                    word_pos = find(strcmp(lists(w,L),SUB(sub).WORDS{b}));                            % find position of the stored words inside SUB.WORDS

                    if SUB(sub).RECALL.PERFORMANCE{b}(word_pos)==1                                    % if the word was recalled by the participant
                        sum_recall(w,L) = sum_recall(w,L)+1;                                        % add 1 if the word was recalled (leave sum for 0 and nan)

                    end                                                                             % end if else to decide whether hit or miss
                end                                                                                 % end if else to check if the list is correct
            end                                                                                     % end loop across words
        end                                                                                     % end try statement
    end                                                                                         % end loop across lists

end                                                                                                 % end loop across subjects

list_perf = round(sum_recall/length(SUB),3);                                                        % get fraction of subjects who recalled resp words

%% create table
LISTS = table(lists(:,1), list_perf(:,1),lists(:,2), list_perf(:,2),lists(:,3), list_perf(:,3),...
    lists(:,4), list_perf(:,4),...
    'VariableNames', {'list_1', 'performance_1','list_2', 'performance_2','list_3', 'performance_3',...
    'list_4', 'performance_4'});

%% save table
writetable(LISTS, [PATHOUT,'word_analysis_recallPercentage.xlsx']);

