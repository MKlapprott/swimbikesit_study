%% mek_sports01_06d_ERP_GNG_plots.m
%
%
%  Description:
%  This script generates ERP plots and topographic maps for the Go/NoGo task
%  (N2 and P3 components) from grand-averaged EEG data.
%
%  It loads preprocessed group-average EEG data (GA.mat) and subject metadata
%  (SUB_PT.mat), separates groups (control, bike, swim), computes condition-
%  specific averages and standard errors, and visualizes:
%       - Grand average ERPs for the full sample
%       - Group-wise ERPs (Go and NoGo, pre and post)
%       - Corresponding scalp topographies for selected time windows
%
%  The resulting figures are exported as high-resolution PNG files.
%  Additionally, mean amplitudes and latencies are saved in text files for
%  statistical analysis.
%
%  INPUTS:
%   • GA.mat   - Grand average ERP data structure with fields:
%                  .pre_go, .pre_nogo, .post_go, .post_nogo
%                  .topo_pre_go, .topo_pre_nogo, .topo_post_go, .topo_post_nogo
%                  .timevec, .chanlocs_swim
%   • SUB_PT.mat - Struct array containing participant info with fields:
%                  .ID, .GROUP, .amp_pre_go, .amp_post_go, etc.
%
%  OUTPUTS:
%   • PNG figures saved in:
%       Q:\Neuro\data\projects\mek_sports01\eegl\BIDS\derivatives\ana_05_epo-gng\plots\
%   • Text files with amplitude and latency values saved in:
%       Q:\Neuro\data\projects\mek_sports01\eegl\BIDS\derivatives\
%       → Amplitudes_GNG.txt
%       → Latencies_GNG.txt
%
%  REQUIREMENTS:
%   • MATLAB R2021b or newer
%   • EEGLAB toolbox (for topoplot function)
%   • GA.mat and SUB_PT.mat must exist in the specified derivatives folder
%
%
%  NOTE:
%   The visual output is designed for publication-ready quality.
%   Modify ROI, TOI, and color definitions as needed for specific figures.
%
%% preparations


clear all; close all; clc;                                                                          % clear workspace

MAINPATH = 'Q:\Neuro\data\projects\mek_sports01\eegl\BIDS\';                                             % define mainpath
PATHIN = [MAINPATH,'derivatives\'];
PATHOUT = [MAINPATH,'derivatives\ana_05_epo-gng\plots\'];                                           % path for saving data

if ~isfolder(PATHOUT)                                                                                % if the path doesn't exist yet, create it
    mkdir(PATHOUT)
end

load([PATHIN,'SUB_PT.mat']);
load([PATHIN,'GA.mat']);

ROI_G = 17;
ROI_N = 15;
my_clims = [-2.5 2.5];
TOI = [220 -6 380 14];
TOI_G = [300 -6 300 14];
TOI_N = [244 -6 80 14];

topo_go = [0.69 0.7 0.17 0.17];
topo_nogo = [0.69 0.28 0.17 0.17];
box_go = [0.7 0.7 0.15 0.18];
box_nogo = [0.7 0.28 0.15 0.18];

delta = 0.01;  % for boxes around topoplots


%% plots & tests - whole sample


pre_go = mean(GA.pre_go, 3);
pre_nogo = mean(GA.pre_nogo, 3);
post_go = mean(GA.post_go, 3);
post_nogo = mean(GA.post_nogo, 3);

topo_pre_go = mean(GA.topo_pre_go, 3);
topo_pre_nogo = mean(GA.topo_pre_nogo, 3);
topo_post_go = mean(GA.topo_post_go, 3);
topo_post_nogo = mean(GA.topo_post_nogo, 3);


pre_go_error = std(GA.pre_go, [], 3) / sqrt(size(GA.pre_go, 3));
pre_nogo_error = std(GA.pre_nogo, [], 3) / sqrt(size(GA.pre_nogo, 3));
post_go_error = std(GA.post_go, [], 3) / sqrt(size(GA.post_go, 3));
post_nogo_error = std(GA.post_nogo, [], 3) / sqrt(size(GA.post_nogo, 3));

% calculate error bars / shadow around GA

x = GA.timevec';

prg_lo = pre_go - pre_go_error;
prg_hi = pre_go + pre_go_error;
prn_lo = pre_nogo - pre_nogo_error;
prn_hi = pre_nogo + pre_nogo_error;

pog_lo = post_go - post_go_error;
pog_hi = post_go + post_go_error;
pon_lo = post_nogo - post_nogo_error;
pon_hi = post_nogo + post_nogo_error;

% actual figure PRE -----------------------------------------------------------------------------

figure;
% NoGo Pre
hp1 = patch([x; x(end:-1:1);x(1)], [prn_lo'; prn_hi(end:-1:1)';prn_lo(1)], 'b');                    % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', "#77AC30", 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, pre_nogo, 'color', '#77AC30');

% NOGO post
hp2 = patch([x; x(end:-1:1);x(1)], [pon_lo'; pon_hi(end:-1:1)';pon_lo(1)], 'r');       % create appearance of SEM in plot
hold on;
set(hp2, 'facecolor', "#7E2F8E", 'edgecolor', 'none');                                              % adjust,emts
hp2.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp2.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, post_nogo, 'color', '#7E2F8E');

legend('NoGo N2 Pre', 'NoGo N2 Post', 'Interpreter', 'none', 'Location', 'southoutside', 'Orientation', 'horizontal')
legend('boxoff')

% ACCESSORIES
xlim([-200 800])
yline(0,'Color',[0.5,0.5,0.5],'LineWidth',1.5, 'HandleVisibility','off');                           % line for y = 0
hold on
xline(0,'k:','linewidth',1.5,'HandleVisibility','off');                                             % line for x = 0
rectangle('Position',TOI_N, 'FaceColor',[0.5, 0.5, 0.5], 'LineStyle', 'none', 'FaceAlpha', 0.2);                    % search space

ylabel('Amplitude [µV]')
xlabel('Time [ms]')
title('Grand Average NoGo N2', 'FontSize', 12, 'FontWeight','bold')
ax = gca;
ax.TitleHorizontalAlignment = 'left';

% TOPOPLOTS
axHit = axes('Position',topo_go);  % Adjust the position/size as you like
topoplot(topo_pre_nogo, GA.chanlocs_swim, 'emarker2', {ROI_N, '.', 'k', 16});
clim(my_clims)

axMiss = axes('Position',topo_nogo);
topoplot(topo_post_nogo, GA.chanlocs_swim, 'emarker2', {ROI_N, '.', 'k', 16});
clim(my_clims)

% Draw colored boxes around topoplots
annotation('rectangle', box_go, 'EdgeColor', '#77AC30', 'LineWidth', 2);
annotation('rectangle', box_nogo, 'EdgeColor', '#7E2F8E', 'LineWidth', 2);


%cd(PATHOUT)
%exportgraphics(gcf,'GNG_GrandAverage.png','Resolution',300)


%% Calculate values for all plots

x = GA.timevec';

groups = extractfield(SUB, 'GROUP');
groups = vertcat(groups{:});

% SIT --------------------------------------------------------------------------------------------

idx_sit = find(strcmp(groups, {'sit'}));

sit_pre_go = mean(GA.pre_go(:,:,idx_sit), 3);
sit_pre_nogo = mean(GA.pre_nogo(:,:,idx_sit), 3);
sit_post_go = mean(GA.post_go(:,:,idx_sit), 3);
sit_post_nogo = mean(GA.post_nogo(:,:,idx_sit), 3);

sit_topo_pre_go = squeeze(mean(GA.topo_pre_go(:,:,idx_sit), 3));
sit_topo_pre_nogo = squeeze(mean(GA.topo_pre_nogo(:,:,idx_sit), 3));
sit_topo_post_go = squeeze(mean(GA.topo_post_go(:,:,idx_sit), 3));
sit_topo_post_nogo = squeeze(mean(GA.topo_post_nogo(:,:,idx_sit), 3));

sit_pre_go_error = std(GA.pre_go(:,:,idx_sit), [], 3) / sqrt(size(GA.pre_go(:,:,idx_sit), 3));
sit_pre_nogo_error = std(GA.pre_nogo(:,:,idx_sit), [], 3) / sqrt(size(GA.pre_miss(:,:,idx_sit), 3));
sit_post_go_error = std(GA.post_go(:,:,idx_sit), [], 3) / sqrt(size(GA.post_go(:,:,idx_sit), 3));
sit_post_nogo_error = std(GA.post_nogo(:,:,idx_sit), [], 3) / sqrt(size(GA.post_miss(:,:,idx_sit), 3));

% calculate error bars / shadow around GA

sit_prg_lo = sit_pre_go - sit_pre_go_error;
sit_prg_hi = sit_pre_go + sit_pre_go_error;
sit_prn_lo = sit_pre_nogo - sit_pre_nogo_error;
sit_prn_hi = sit_pre_nogo + sit_pre_nogo_error;

sit_pog_lo = sit_post_go - sit_post_go_error;
sit_pog_hi = sit_post_go + sit_post_go_error;
sit_pon_lo = sit_post_nogo - sit_post_nogo_error;
sit_pon_hi = sit_post_nogo + sit_post_nogo_error;


% BIKE -------------------------------------------------------------------------------------------

idx_bike = find(strcmp(groups, {'bike'}));

bike_pre_go = mean(GA.pre_go(:,:,idx_bike), 3);
bike_pre_nogo = mean(GA.pre_nogo(:,:,idx_bike), 3);
bike_post_go = mean(GA.post_go(:,:,idx_bike), 3);
bike_post_nogo = mean(GA.post_nogo(:,:,idx_bike), 3);

bike_topo_pre_go = squeeze(mean(GA.topo_pre_go(:,:,idx_bike), 3));
bike_topo_pre_nogo = squeeze(mean(GA.topo_pre_nogo(:,:,idx_bike), 3));
bike_topo_post_go = squeeze(mean(GA.topo_post_go(:,:,idx_bike), 3));
bike_topo_post_nogo = squeeze(mean(GA.topo_post_nogo(:,:,idx_bike), 3));

bike_pre_go_error = std(GA.pre_go(:,:,idx_bike), [], 3) / sqrt(size(GA.pre_go(:,:,idx_bike), 3));
bike_pre_nogo_error = std(GA.pre_nogo(:,:,idx_bike), [], 3) / sqrt(size(GA.pre_nogo(:,:,idx_bike), 3));
bike_post_go_error = std(GA.post_go(:,:,idx_bike), [], 3) / sqrt(size(GA.post_go(:,:,idx_bike), 3));
bike_post_nogo_error = std(GA.post_nogo(:,:,idx_bike), [], 3) / sqrt(size(GA.post_nogo(:,:,idx_bike), 3));

% calculate error bars / shadow around GA

bike_prg_lo = bike_pre_go - bike_pre_go_error;
bike_prg_hi = bike_pre_go + bike_pre_go_error;
bike_prn_lo = bike_pre_nogo - bike_pre_nogo_error;
bike_prn_hi = bike_pre_nogo + bike_pre_nogo_error;

bike_pog_lo = bike_post_go - bike_post_go_error;
bike_pog_hi = bike_post_go + bike_post_go_error;
bike_pon_lo = bike_post_nogo - bike_post_nogo_error;
bike_pon_hi = bike_post_nogo + bike_post_nogo_error;

% SWIM -------------------------------------------------------------------------------------------

idx_swim = find(strcmp(groups, {'swim'}));

swim_pre_go = mean(GA.pre_go(:,:,idx_swim), 3);
swim_pre_nogo = mean(GA.pre_nogo(:,:,idx_swim), 3);
swim_post_go = mean(GA.post_go(:,:,idx_swim), 3);
swim_post_nogo = mean(GA.post_nogo(:,:,idx_swim), 3);

swim_topo_pre_go = squeeze(mean(GA.topo_pre_go(:,:,idx_swim), 3));
swim_topo_pre_nogo = squeeze(mean(GA.topo_pre_nogo(:,:,idx_swim), 3));
swim_topo_post_go = squeeze(mean(GA.topo_post_go(:,:,idx_swim), 3));
swim_topo_post_nogo = squeeze(mean(GA.topo_post_nogo(:,:,idx_swim), 3));

swim_pre_go_error = std(GA.pre_go(:,:,idx_swim), [], 3) / sqrt(size(GA.pre_go(:,:,idx_swim), 3));
swim_pre_nogo_error = std(GA.pre_nogo(:,:,idx_swim), [], 3) / sqrt(size(GA.pre_nogo(:,:,idx_swim), 3));
swim_post_go_error = std(GA.post_go(:,:,idx_swim), [], 3) / sqrt(size(GA.post_go(:,:,idx_swim), 3));
swim_post_nogo_error = std(GA.post_nogo(:,:,idx_swim), [], 3) / sqrt(size(GA.post_nogo(:,:,idx_swim), 3));

% calculate error bars / shadow around GA

swim_prg_lo = swim_pre_go - swim_pre_go_error;
swim_prg_hi = swim_pre_go + swim_pre_go_error;
swim_prn_lo = swim_pre_nogo - swim_pre_nogo_error;
swim_prn_hi = swim_pre_nogo + swim_pre_nogo_error;

swim_pog_lo = swim_post_go - swim_post_go_error;
swim_pog_hi = swim_post_go + swim_post_go_error;
swim_pon_lo = swim_post_nogo - swim_post_nogo_error;
swim_pon_hi = swim_post_nogo + swim_post_nogo_error;


%% PLOT ALL NoGo N2 PRE ---------------------------------------------------------------------------

figure;
tiledlayout(6,6);
nexttile(13, [4,6])
% SIT
hp1 = patch([x; x(end:-1:1);x(1)], [sit_prn_lo'; sit_prn_hi(end:-1:1)';sit_prn_lo(1)], 'b');                    % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', "#C0C0C0", 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, sit_pre_nogo, 'color', '#C0C0C0', 'LineWidth', 1.5);

% BIKE
hp2 = patch([x; x(end:-1:1);x(1)], [bike_prn_lo'; bike_prn_hi(end:-1:1)';bike_prn_lo(1)], 'r');       % create appearance of SEM in plot
hold on;
set(hp2, 'facecolor', "r", 'edgecolor', 'none');                                              % adjust,emts
hp2.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp2.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, bike_pre_nogo,'color', '#CC3D3D', 'LineWidth', 1.5);

% SWIM
hp3 = patch([x; x(end:-1:1);x(1)], [swim_prn_lo'; swim_prn_hi(end:-1:1)';swim_prn_lo(1)], 'r');       % create appearance of SEM in plot
hold on;
set(hp3, 'facecolor', "b", 'edgecolor', 'none');                                              % adjust,emts
hp3.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp3.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, swim_pre_nogo,'color', '#1E90FF', 'LineWidth', 1.5);


legend('Sit', 'Bike', 'Swim', 'FontSize', 11)
%legend('boxoff')

% ACCESSORIES
yline(0,'Color',[0.5,0.5,0.5],'LineWidth',1.5, 'HandleVisibility','off');                           % line for y = 0
hold on
xline(0,'k:','linewidth',1.5,'HandleVisibility','off');                                             % line for x = 0
rectangle('Position',TOI_N, 'FaceColor',[0.5, 0.5, 0.5], 'LineStyle', 'none', 'FaceAlpha', 0.2);        % search space

xlim([-200 800])
ylabel('Amplitude [µV]', 'FontSize', 18)
xlabel('Time [ms]', 'FontSize', 18)
title('ERP: NoGo N200 - PRE', 'FontSize', 18, 'FontWeight','bold')
ax = gca;
ax.TitleHorizontalAlignment = 'left';
ax.FontSize = 14;

% TOPOPLOTS (placed above the ERP plot)

% SIT Topoplot (nexttile 1: spanning 2 rows x 2 columns)
axSIT = nexttile(1, [2,2]);
topoplot(sit_topo_pre_nogo, GA.chanlocs_swim, 'emarker2', {ROI_N, '.', 'k', 16});
clim(my_clims)
% Draw rectangle around this tile using its normalized position
posSIT = axSIT.Position;
posSIT_expanded = [posSIT(1)-delta, posSIT(2)-delta, posSIT(3)+2*delta, posSIT(4)+2*delta];
annotation('rectangle', posSIT_expanded, 'EdgeColor', '#C0C0C0', 'LineWidth', 2);

% BIKE Topoplot (nexttile 3: spanning 2 rows x 2 columns)
axBIKE = nexttile(3, [2,2]);
topoplot(bike_topo_pre_nogo, GA.chanlocs_swim, 'emarker2', {ROI_N, '.', 'k', 16});
clim(my_clims)
posBIKE = axBIKE.Position;
posBIKE_expanded = [posBIKE(1)-delta, posBIKE(2)-delta, posBIKE(3)+2*delta, posBIKE(4)+2*delta];
annotation('rectangle', posBIKE_expanded, 'EdgeColor', '#CC3D3D', 'LineWidth', 2);

% SWIM Topoplot (nexttile 5: spanning 2 rows x 2 columns)
axSWIM = nexttile(5, [2,2]);
topoplot(swim_topo_pre_nogo, GA.chanlocs_swim, 'emarker2', {ROI_N, '.', 'k', 16});
clim(my_clims)
posSWIM = axSWIM.Position;
posSWIM_expanded = [posSWIM(1)-delta, posSWIM(2)-delta, posSWIM(3)+2*delta, posSWIM(4)+2*delta];
annotation('rectangle', posSWIM_expanded, 'EdgeColor', '#1E90FF', 'LineWidth', 2);

%cd(PATHOUT)
exportgraphics(gcf,'GNG_pre_N2.svg','BackgroundColor', 'white','Resolution',300)


%% PLOT ALL NoGo N2 POST ---------------------------------------------------------------------------

figure;
tiledlayout(6,6);
nexttile(13, [4,6])
% SIT
hp1 = patch([x; x(end:-1:1);x(1)], [sit_pon_lo'; sit_pon_hi(end:-1:1)';sit_pon_lo(1)], 'b');                    % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', "#283747", 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, sit_post_nogo, 'color', '#C0C0C0', 'LineWidth', 1.5);

% BIKE
hp2 = patch([x; x(end:-1:1);x(1)], [bike_pon_lo'; bike_pon_hi(end:-1:1)';bike_pon_lo(1)], 'r');       % create appearance of SEM in plot
hold on;
set(hp2, 'facecolor', "r", 'edgecolor', 'none');                                              % adjust,emts
hp2.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp2.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, bike_post_nogo,'color', '#CC3D3D', 'LineWidth', 1.5);

% SWIM
hp3 = patch([x; x(end:-1:1);x(1)], [swim_pon_lo'; swim_pon_hi(end:-1:1)';swim_pon_lo(1)], 'r');       % create appearance of SEM in plot
hold on;
set(hp3, 'facecolor', "b", 'edgecolor', 'none');                                              % adjust,emts
hp3.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp3.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, swim_post_nogo,'color', '#1E90FF', 'LineWidth', 1.5);


legend('Sit', 'Bike', 'Swim', 'Fontsize', 11) 


% ACCESSORIES
yline(0,'Color',[0.5,0.5,0.5],'LineWidth',1.5, 'HandleVisibility','off');                           % line for y = 0
hold on
xline(0,'k:','linewidth',1.5,'HandleVisibility','off');                                             % line for x = 0
rectangle('Position',TOI_N, 'FaceColor',[0.5, 0.5, 0.5], 'LineStyle', 'none', 'FaceAlpha', 0.2);        % search space

xlim([-200 800])
ylabel('Amplitude [µV]', 'FontSize', 18)
xlabel('Time [ms]', 'FontSize', 18)
title('ERP: NoGo N200 - POST', 'FontSize', 18, 'FontWeight','bold')
ax = gca;
ax.TitleHorizontalAlignment = 'left';
ax.FontSize = 14;

% TOPOPLOTS (placed above the ERP plot)

% SIT Topoplot (nexttile 1: spanning 2 rows x 2 columns)
axSIT = nexttile(1, [2,2]);
topoplot(sit_topo_post_nogo, GA.chanlocs_swim, 'emarker2', {ROI_N, '.', 'k', 16});
clim(my_clims)
% Draw rectangle around this tile using its normalized position
posSIT = axSIT.Position;
posSIT_expanded = [posSIT(1)-delta, posSIT(2)-delta, posSIT(3)+2*delta, posSIT(4)+2*delta];
annotation('rectangle', posSIT_expanded, 'EdgeColor', '#C0C0C0', 'LineWidth', 2);

% BIKE Topoplot (nexttile 3: spanning 2 rows x 2 columns)
axBIKE = nexttile(3, [2,2]);
topoplot(bike_topo_post_nogo, GA.chanlocs_swim, 'emarker2', {ROI_N, '.', 'k', 16});
clim(my_clims)
posBIKE_expanded = [posBIKE(1)-delta, posBIKE(2)-delta, posBIKE(3)+2*delta, posBIKE(4)+2*delta];
annotation('rectangle', posBIKE_expanded, 'EdgeColor', '#CC3D3D', 'LineWidth', 2);

% SWIM Topoplot (nexttile 5: spanning 2 rows x 2 columns)
axSWIM = nexttile(5, [2,2]);
topoplot(swim_topo_post_nogo, GA.chanlocs_swim, 'emarker2', {ROI_N, '.', 'k', 16});
clim(my_clims)
posSWIM_expanded = [posSWIM(1)-delta, posSWIM(2)-delta, posSWIM(3)+2*delta, posSWIM(4)+2*delta];
annotation('rectangle', posSWIM_expanded, 'EdgeColor', '#1E90FF', 'LineWidth', 2);

%cd(PATHOUT)
exportgraphics(gcf,'GNG_post_N2.svg','BackgroundColor', 'white','Resolution',300)


%% REST??
figure;
% SIT
hp1 = patch([x; x(end:-1:1);x(1)], [sit_prg_lo'; sit_prg_hi(end:-1:1)';sit_prg_lo(1)], 'b');                    % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', "#283747", 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, sit_pre_go, 'color', '#283747', 'LineWidth', 1.5);

% BIKE
hp2 = patch([x; x(end:-1:1);x(1)], [bike_prg_lo'; bike_prg_hi(end:-1:1)';bike_prg_lo(1)], 'r');       % create appearance of SEM in plot
hold on;
set(hp2, 'facecolor', "r", 'edgecolor', 'none');                                              % adjust,emts
hp2.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp2.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, bike_pre_go,'color', 'r');

% SWIM
hp3 = patch([x; x(end:-1:1);x(1)], [swim_prg_lo'; swim_prg_hi(end:-1:1)';swim_prg_lo(1)], 'r');       % create appearance of SEM in plot
hold on;
set(hp3, 'facecolor', "b", 'edgecolor', 'none');                                              % adjust,emts
hp3.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp3.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, swim_pre_go,'color', 'b');


legend('Control', 'Bike', 'Swim', 'Location', 'southoutside', 'Orientation', 'horizontal')
legend('boxoff')

% ACCESSORIES
yline(0,'Color',[0.5,0.5,0.5],'LineWidth',1.5, 'HandleVisibility','off');                           % line for y = 0
hold on
xline(0,'k:','linewidth',1.5,'HandleVisibility','off');                                             % line for x = 0
rectangle('Position',TOI_G, 'FaceColor',[0.5, 0.5, 0.5], 'LineStyle', 'none');        % search space

ylabel('Amplitude [µV]')
xlabel('Time [ms]')
title('Go P3 - PRE', 'FontSize', 12, 'FontWeight','bold')
ax = gca;
ax.TitleHorizontalAlignment = 'left';

% TOPOPLOTS
axsit = axes('Position', [0.9 0.5 0.2 0.2]);  % Adjust the position/size as you like
topoplot(sit_topo_pre_go, GA.chanlocs_swim, 'emarker2', {ROI_G, '.', 'k', 16});
clim(my_clims)
axis off;

axbike =  axes('Position', [0.9 0.8 0.2 0.2]);
topoplot(bike_topo_pre_nogo, GA.chanlocs_swim, 'emarker2', {ROI_N, '.', 'k', 16});
clim(my_clims)
axis off;


% set(gcf, 'PaperPositionMode', 'manual');
% set(gcf, 'PaperPosition', [0 0 12 8]);  % Increase these numbers for extra margins
% 
% % Draw colored boxes around topoplots
% annotation('rectangle', box_go, 'EdgeColor', '#283747', 'LineWidth', 2);
% annotation('rectangle', box_nogo, 'EdgeColor', '#85929e', 'LineWidth', 2);
% 
% % SAVE
% 
% cd(PATHOUT)
% exportgraphics(gcf,'GNG_pre_topos_conrol.png','Resolution',300)
% 


%% PRE NOGO N2



%% POST P3

figure;
% SIT
hp1 = patch([x; x(end:-1:1);x(1)], [sit_pog_lo'; sit_pog_hi(end:-1:1)';sit_pog_lo(1)], 'b');                    % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', "#283747", 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, sit_post_go, 'color', '#283747', 'LineWidth', 1.5);

% BIKE
hp2 = patch([x; x(end:-1:1);x(1)], [bike_pog_lo'; bike_pog_hi(end:-1:1)';bike_pog_lo(1)], 'r');       % create appearance of SEM in plot
hold on;
set(hp2, 'facecolor', "r", 'edgecolor', 'none');                                              % adjust,emts
hp2.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp2.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, bike_post_go,'color', 'r');

% SWIM
hp3 = patch([x; x(end:-1:1);x(1)], [swim_pog_lo'; swim_pog_hi(end:-1:1)';swim_pog_lo(1)], 'r');       % create appearance of SEM in plot
hold on;
set(hp3, 'facecolor', "b", 'edgecolor', 'none');                                              % adjust,emts
hp3.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp3.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, swim_post_go,'color', 'b');


legend('Control', 'Bike', 'Swim', 'Location', 'southoutside', 'Orientation', 'horizontal')
legend('boxoff')

% ACCESSORIES
yline(0,'Color',[0.5,0.5,0.5],'LineWidth',1.5, 'HandleVisibility','off');                           % line for y = 0
hold on
xline(0,'k:','linewidth',1.5,'HandleVisibility','off');                                             % line for x = 0
rectangle('Position',TOI_G, 'FaceColor',[0.3, .4, .6 , 0.2], 'LineStyle', 'none');        % search space

ylabel('Amplitude [µV]')
xlabel('Time [ms]')
title('Go P3 - POST', 'FontSize', 12, 'FontWeight','bold')
ax = gca;
ax.TitleHorizontalAlignment = 'left';

% TOPOPLOTS
axsit = axes('Position', [0.9 0.5 0.2 0.2]);  % Adjust the position/size as you like
topoplot(sit_topo_post_go, GA.chanlocs_swim, 'emarker2', {ROI_G, '.', 'k', 16});
clim(my_clims)
axis off;

axbike =  axes('Position', [0.9 0.8 0.2 0.2]);
topoplot(bike_topo_post_nogo, GA.chanlocs_swim, 'emarker2', {ROI_N, '.', 'k', 16});
clim(my_clims)
axis off;




%% save for Stats 

ID = extractfield(SUB, 'ID')';
group = extractfield(SUB, 'GROUP')';

all_go_pre = extractfield(SUB, 'amp_pre_go');
all_nogo_pre = extractfield(SUB, 'amp_pre_nogo');
all_go_post = extractfield(SUB, 'amp_post_go');
all_nogo_post = extractfield(SUB, 'amp_post_nogo');

T = table(ID, group, all_go_pre', all_nogo_pre', all_go_post', all_nogo_post');
T.Properties.VariableNames = {'ID', 'Group', 'Go_Pre', 'NoGo_Pre', 'Go_Post', 'NoGo_Post' } ;
writetable(T, [PATHIN,'Amplitudes_GNG.txt']);


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
writetable(T, [PATHIN,'Latencies_GNG.txt']);


