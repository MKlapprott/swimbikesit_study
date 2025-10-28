%% mek_sports01_01_FirstCheck.m
%
% Description:
%   This script performs an initial preprocessing and inspection of raw EEG
%   data recorded during and around a sports intervention. It loads the raw
%   EEGLAB datasets for each participant, applies basic filtering, identifies
%   bad channels based on RMS thresholds, and allows for manual confirmation
%   or correction of automatically detected bad channels. The cleaned data and
%   diagnostic plots are saved for further analysis.
%
% Steps:
%   1. Load raw EEG data from BIDS structure
%   2. Remove non-EEG (MISC) channels
%   3. Apply bandpass filter (1–30 Hz)
%   4. For pre/post blocks, retain only Go/NoGo trials (TODO)
%   5. Compute RMS across channels and detect potential bad channels
%   6. Visualize RMS values (topo + time course)
%   7. Optionally mark additional bad channels interactively
%   8. Save cleaned dataset and updated subject information
%
% Outputs:
%   - Preprocessed EEGLAB datasets saved under:
%       derivatives/ana_01_firstCheck/<subject>/
%   - Diagnostic plots (optional)
%   - Updated 'SUB' structure containing:
%       * bad channel indices per condition
%       * total number of channels
%       * channel location metadata
%
% Requirements:
%   - EEGLAB (2022.0 or later)
%   - 'SUB_PT.mat' structure file with subject metadata
%   - BIDS-style directory structure
%
% Melanie, 2025

%% Preparations

clear all; close all; clc;                                                                          % clear workspace

MAINPATH = 'Q:\Neuro\data\projects\mek_sports01\eegl\BIDS\';                                             % define mainpath
EEGLABPATH = [MAINPATH, 'eeglab2022.0\'];                                                           % define path for EEGLAB
PATHIN = [MAINPATH];                                                                                % define path for raw data
PATHOUT = [MAINPATH,'derivatives\'];                                                                % path for saving data
CHECKPATH = [PATHOUT, 'ana_01_firstCheck\'];

PATHPLOT = [CHECKPATH, 'plots\'];                                                                   % path for saving plots
if ~isfolder(PATHPLOT)                                                                               % if the path doesn't exist yet, create it
    mkdir(PATHPLOT)
end
     

% set up parameters ------------------------------------------------------------------------------

HPF= 1;                                                                                             % high pass filter of 1 Hz
LPF= 30;                                                                                            % low pass filter of 30 Hz
rms_t = [];

load([PATHOUT,'SUB_PT.mat']);                                                                          % load subject structure

all_folders = dir(MAINPATH);
sub_folders = all_folders(11:100);

%% Analysis

for sub = 1:length(SUB)
 
    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;                                                     % start EEGLAB
    sub_folder = sub_folders(sub).name;
    SUBPATHIN = [PATHIN, sub_folder, '\eeg\'];                                                          % set path to participant

    COND = {'pre', 'int', 'post'};

    % sort some special treatments for special snowflakes ----------------------------------------

    files = dir(fullfile(SUBPATHIN, '*.set'));                                                      % get access to bdf file
    num_files = length(files);                                                                      % get number of files

    if strcmp(SUB(sub).ID, 'sports_05') || strcmp(SUB(sub).ID, 'sports_14') || strcmp(SUB(sub).ID, 'sports_24') || ...
       strcmp(SUB(sub).ID, 'sports_94') % post is missing
        num_files = 2;

    elseif strcmp(SUB(sub).ID, 'sports_06')
        COND = {'int', 'post'};
        num_files = 2;

    end

    f1 = figure('units','normalized','outerposition',[0 0 1 1]);                                    % get fullscrean figure

    % load data ----------------------------------------------------------------------------------
   
    for e = 1:num_files                                                                             % loop across files

        if strcmp(SUB(sub).GROUP, 'swim') && ~strcmp(SUB(sub).ID, 'sports_06')

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

        EEG = pop_loadset([SUBPATHIN, file_name]);
        NOCHANS = find(contains({EEG.chanlocs.type}, 'MISC'));

        EEG = pop_select( EEG, 'nochannel', NOCHANS);                                               % select relevant channels
        nchan = EEG.nbchan;                                                                         % update number of channels   

        % process data ---------------------------------------------------------------------------
         
        EEG = pop_eegfiltnew(EEG, 'locutoff', HPF);                                                 % high-pass filter
        EEG = pop_eegfiltnew(EEG, 'hicutoff', LPF);                                                 % low-pass filter

        EEG.urchanlocs = EEG.chanlocs;                                                              % save original channels
        SUB(sub).urchanlocs = EEG.chanlocs;                                                         % better be save than sorry
        
        file_name_new = SUB(sub).ID;  
        EEG.setname = [file_name_new, '_block-', COND{e}, '_preproc-badChans'];                     % give data set a proper name
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);


        % Plotting of RMS --------------------------------------------------------------------

        rms = std(EEG.data, [],2);                                                                  % calc standard deviation across channels
        thres = mean(mean(rms)+3*std(rms));                                                         % define threshold for bad channel marking (take higher threshold??)
        ind = find(rms>thres);                                                                      % find bits of data exceeding thres
        
        % create subplots, so that there is only one plot for each subject
        set(0, 'CurrentFigure', f1)                                                                 % call first figure
        subplot(4, 3, e);                                                                           % plot topo of channel stds
        topoplot(rms, EEG.chanlocs);                                                                % topography of rms
        title(['Condition: ', COND{e}]);
    
        % plot lines of channel stds with threshold
        subplot(4, 3, e+3);
        plot(rms, 'k');                                                                             % channels
        hold on;
        plot(repmat(thres,1,nchan), 'r');                                                           % threshold
        xlabel('Channels'); ylabel('rms')
        plottitle = ['Outlier chans: ', mat2str(ind)];
        title(plottitle, 'Interpreter', 'none');
        axis tight
    
        % then, additionally, plot rms over time (image plot) for each subject and each run
        % cut windows, calculate stds, plot in image
    
        sec = 10;
        LeWin = EEG.srate*sec;                                                                      % define window length
        timeVec = 0 : 1/EEG.srate : sec-1/EEG.srate;                                                % define time vector
        idx_loop = 1:LeWin:size(EEG.data,2);                                                        % check how loop index will look like
        rms_t = zeros(EEG.nbchan, length(idx_loop));                                                % pre-allocate matrix of rms over time
        row_count = 1;                                                                              % set counter
    
        for idx = 1: LeWin: size(EEG.data,2)-LeWin                                                  % go through data in steps of 10s
            
            signal = EEG.data(:,idx:idx+(LeWin-1));                                                 % get short extract from data
            rms_t(:, row_count) = std(signal, [],2);                                                % calc standard deviation across channels
            row_count = row_count +1;                                                               % update counter
    
        end
    
        % create colormap for channel stds over time
        ax1 = subplot(4, 3, e+6)                                                        
        imagesc(rms_t);
        colorbar;
        colormap(ax1, turbo);
        xlabel('Time (10s windows)'); ylabel('Channels');
        title(['Subject: ', SUB(sub).ID, ', Condition: ', COND{e}], 'Interpreter', 'none');
        
        % color code if value is > thresh or not -> include flat line here?         
        rms_ti = double(rms_t > thres);       

        ax2 = subplot(4, 3, e+9)
        imagesc(rms_ti);
        colorbar;
        colormap(ax2, turbo);
        xlabel('Time (10s windows)'); ylabel('Channels');
        title(['Threshold: ', num2str(thres)], 'Interpret', 'none');
    
        sgt = sgtitle(['Outlier Channels over time for subject: ', SUB(sub).ID], 'Interpreter', 'none'); % title for whole plot
        drawnow                                                                                     % print for inspection
        
        
        % mark and exclude bad channels ------------------------------------------------------

        EEG.badchans = [];
        nchan_ori = EEG.nbchan;

        if length(ind) > 0
            for bc = 1:length(ind)
                exl_chan = input(['Do you want to exclude channel: ', mat2str(ind(bc)), '? [1/0] ']); % ask if -after inspection- channel should be excluded

                if exl_chan == 1                                                                % if I agree with the algorithm
                    EEG.badchans(bc) = ind(bc);                                                 % define bad channels
                elseif exl_chan == 0                                                            % if I disagree with the algorithm
                    EEG.algoDis = {ind(bc), date};                                              % save info that I wanna keep a channel and which one
                    
                end
            end
            disp(['Okay! The following channels are marked as bad: ', mat2str(EEG.badchans), '.'])

            addchan = input('Do you want to exclude further channels? [1/0] ')
            if addchan == 1
                excl_ac = input('Which channel(s) do you want to exclude additionally? ')
                EEG.addbadchans = excl_ac;                                                      % note down the added bad channels
                EEG.badchans = horzcat([EEG.badchans, excl_ac]);
                disp(['Channel(s) ', mat2str(excl_ac), ' was / were added to the bad channels.'])
            elseif addchan == 0
                disp('Okay! Proceeding with saving all the information.')
            else
                warning('You entered neither 0 or 1. Gonna proceed anyways...')
            end
        else
            addchan = input('Do you want to exclude further channels? [1/0] ')
            if addchan == 1
                excl_ac = input('Which channel(s) do you want to exclude additionally? ')
                EEG.addbadchans = excl_ac;                                                      % note down the added bad channels
                EEG.badchans = horzcat([EEG.badchans, excl_ac]);
                disp(['Channel(s) ', mat2str(excl_ac), ' was / were added to the bad channels.'])
            elseif addchan == 0
                disp('Okay! Proceeding with saving all the information.')
            else
                warning('You entered neither 0 or 1. Gonna proceed anyways...')
            end
        end
            
        
        EEG.badchans = sort(EEG.badchans);
        nchan = EEG.nbchan;                                                                     % get new number of channels in data set

        disp(['Original number of channels: ', num2str(nchan_ori), '. Number of bad channels: ', ...    % inform about new number of channels
            num2str(length(EEG.badchans)), '.'])
    
        try
            SUB(sub).badchans{e} = EEG.badchans;
        end
        SUB(sub).nchans(e) = nchan;


        % write matrices with indexes, so that they can become longer while the loops run --------
    
        SUBCHECKPATH = [CHECKPATH, sub_folder, '\'];                                               % create path for subject
        mkdir(SUBCHECKPATH);
        cd(SUBCHECKPATH);
    
        EEG = pop_saveset(EEG, 'filename', [num2str(e), '-', EEG.setname], 'filepath', SUBCHECKPATH);  % save data set

    end                                                                                             % end loop across files

    cd(PATHPLOT)
    %saveas(gca, [sub_folder, '-OutlierChans.png']);                                                % save plot
    close;

end                                                                                                 % end loop across subjects

% Save SUB struct

save([PATHOUT,'SUB_PT'],'SUB');

%% end


