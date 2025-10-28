%% mek_sports01_ERP_illustration
%
%  Purpose:  Plot grand-average ERPs and scalp topographies (SME contrasts)
%             for all participants and by group (sit, bike, swim).
%
%  Inputs:   - SUB_PT.mat : participant information
%             - GA.mat     : grand-average EEG data structure
%
%  Outputs:  - ERP and topography figures (.png) for pre- and post-intervention
%             - Separate figures for each experimental group
%
%
%  Notes:
%  - Requires EEGLAB functions (e.g., topoplot).
%  - Assumes GA structure contains:
%       GA.pre_hit, GA.pre_miss, GA.post_hit, GA.post_miss (chan × time × subj)
%       GA.topo_pre_hit, GA.topo_post_hit, etc. (chan × 1 × subj)
%       GA.chanlocs_swim (EEGLAB chanlocs)
%       GA.timevec (ms)
%
%

%% preparations


clear all; close all; clc;                                                                          % clear workspace

MAINPATH = 'Q:\Neuro\data\projects\mek_sports01\eegl\BIDS\';                                             % define mainpath

PATHIN = [MAINPATH,'derivatives\'];
PATHOUT = [MAINPATH,'derivatives\ana_04_epo-sme\plots\'];                                  % path for saving data

load([PATHIN,'SUB_PT.mat']);
load([PATHIN,'GA.mat']);

ROI = [5,6,17];
my_clims = [-0.5 0.5];
TOI = [440 -3 400 10];

topo_hit = [0.47 0.72 0.17 0.17];
topo_miss = [0.65 0.29 0.17 0.17];
box_hit = [0.48 0.72 0.15 0.18];
box_miss = [0.66 0.29 0.15 0.18];

delta = 0.01;

eeglab
%% plots - whole sample


pre_hit = mean(GA.pre_hit, 3);
pre_miss = mean(GA.pre_miss, 3);
post_hit = mean(GA.post_hit, 3);
post_miss = mean(GA.post_miss, 3);

topo_pre_hit = mean(GA.topo_pre_hit, 3);
topo_pre_miss = mean(GA.topo_pre_miss, 3);
topo_post_hit = mean(GA.topo_post_hit, 3);
topo_post_miss = mean(GA.topo_post_miss, 3);


pre_hit_error = std(GA.pre_hit, [], 3) / sqrt(size(GA.pre_hit, 3));
pre_miss_error = std(GA.pre_miss, [], 3) / sqrt(size(GA.pre_miss, 3));
post_hit_error = std(GA.post_hit, [], 3) / sqrt(size(GA.post_hit, 3));
post_miss_error = std(GA.post_miss, [], 3) / sqrt(size(GA.post_miss, 3));

% calculate error bars / shadow around GA

x = GA.timevec';

prh_lo = pre_hit - pre_hit_error;
prh_hi = pre_hit + pre_hit_error;
prm_lo = pre_miss - pre_miss_error;
prm_hi = pre_miss + pre_miss_error;

poh_lo = post_hit - post_hit_error;
poh_hi = post_hit + post_hit_error;
pom_lo = post_miss - post_miss_error;
pom_hi = post_miss + post_miss_error;

% actual figure PRE -----------------------------------------------------------------------------

figure;
% HIT
hp1 = patch([x; x(end:-1:1);x(1)], [prh_lo'; prh_hi(end:-1:1)';prh_lo(1)], 'b');                    % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', "#229954", 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, pre_hit, 'color', '#229954', 'LineWidth', 1.5);

% MISS
hp2 = patch([x; x(end:-1:1);x(1)], [prm_lo'; prm_hi(end:-1:1)';prm_lo(1)], 'r');       % create appearance of SEM in plot
hold on;
set(hp2, 'facecolor', "#85929e", 'edgecolor', 'none');                                              % adjust,emts
hp2.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp2.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, pre_miss, 'color', '#85929e');

legend('remembered', 'not remembered', 'Interpreter', 'none', 'Location', 'southoutside', 'Orientation', 'horizontal')
legend('boxoff')

% ACCESSORIES
yline(0,'Color',[0.5,0.5,0.5],'LineWidth',1.5, 'HandleVisibility','off');                           % line for y = 0
hold on
xline(0,'k:','linewidth',1.5,'HandleVisibility','off');                                             % line for x = 0
rectangle('Position',TOI, 'FaceColor',[0.5, 0.5, 0.5], 'LineStyle', 'none', 'FaceAlpha', 0.2);                    % search space

ylabel('Amplitude [µV]')
xlabel('Time [ms]')
title('SME Grand Average PRE', 'FontSize', 12, 'FontWeight','bold')
ax = gca;
ax.TitleHorizontalAlignment = 'left';

% TOPOPLOTS
axHit = axes('Position',topo_hit);  % Adjust the position/size as you like
topoplot(topo_pre_hit, GA.chanlocs_swim, 'emarker2', {ROI, '.', 'k', 16});
clim(my_clims)

axMiss = axes('Position',topo_miss);
topoplot(topo_pre_miss, GA.chanlocs_swim, 'emarker2', {ROI, '.', 'k', 16});
clim(my_clims)

% Draw colored boxes around topoplots
annotation('rectangle', box_hit, 'EdgeColor', '#229954', 'LineWidth', 2);
annotation('rectangle', box_miss, 'EdgeColor', '#85929e', 'LineWidth', 2);


% cd(PATHOUT)
% exportgraphics(gcf,'SME_pre_topos.png','Resolution',300)


% actual figure POST -----------------------------------------------------------------------------

figure;
% HIT
hp1 = patch([x; x(end:-1:1);x(1)], [poh_lo'; poh_hi(end:-1:1)';poh_lo(1)], 'b');                    % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', "#229954", 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, post_hit,'color', '#229954', 'LineWidth', 1.5);

% MISS
hp2 = patch([x; x(end:-1:1);x(1)], [pom_lo'; pom_hi(end:-1:1)';pom_lo(1)], 'r');       % create appearance of SEM in plot
hold on;
set(hp2, 'facecolor', "#85929e", 'edgecolor', 'none');                                              % adjust,emts
hp2.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp2.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, post_miss, 'color', '#85929e');

legend('remembered', 'not remembered', 'Interpreter', 'none', 'Location', 'southoutside', 'Orientation', 'horizontal')
legend('boxoff')

% ACCESSORIES
yline(0,'Color',[0.5,0.5,0.5],'LineWidth',1.5, 'HandleVisibility','off');                           % line for y = 0
hold on
xline(0,'k:','linewidth',1.5,'HandleVisibility','off');                                             % line for x = 0
rectangle('Position',TOI, 'FaceColor',[0.5, 0.5, 0.5], 'LineStyle', 'none', 'FaceAlpha', 0.2);        % search space

ylabel('Amplitude [µV]')
xlabel('Time [ms]')
title('SME Grand Average POST', 'FontSize', 12, 'FontWeight','bold')
ax = gca;
ax.TitleHorizontalAlignment = 'left';


% TOPOPLOTS
axHit = axes('Position',topo_hit);  % Adjust the position/size as you like
topoplot(topo_post_hit, GA.chanlocs_swim, 'emarker2', {ROI, '.', 'k', 16});
clim(my_clims)

axMiss = axes('Position',topo_miss);
topoplot(topo_post_miss, GA.chanlocs_swim, 'emarker2', {ROI, '.', 'k', 16});
clim(my_clims)

% Draw colored boxes around topoplots
annotation('rectangle', box_hit, 'EdgeColor', '#229954', 'LineWidth', 2);
annotation('rectangle', box_miss, 'EdgeColor', '#85929e', 'LineWidth', 2);

% SAVE

%cd(PATHOUT)
%exportgraphics(gcf,'SME_post_topos.png','Resolution',300)


%% Plots & tests - separated by groups
% control group ----------------------------------------------------------------------------------

groups = extractfield(SUB, 'GROUP');
groups = vertcat(groups{:});
idx_sit = find(strcmp(groups, {'sit'}));

pre_hit_sit = mean(GA.pre_hit(:,:,idx_sit), 3);
pre_miss_sit = mean(GA.pre_miss(:,:,idx_sit), 3);
post_hit_sit = mean(GA.post_hit(:,:,idx_sit), 3);
post_miss_sit = mean(GA.post_miss(:,:,idx_sit), 3);

topo_pre_hit_sit = squeeze(mean(GA.topo_pre_hit(:,:,idx_sit), 3));
topo_pre_miss_sit = squeeze(mean(GA.topo_pre_miss(:,:,idx_sit), 3));
topo_post_hit_sit = squeeze(mean(GA.topo_post_hit(:,:,idx_sit), 3));
topo_post_miss_sit = squeeze(mean(GA.topo_post_miss(:,:,idx_sit), 3));

pre_hit_error_sit = std(GA.pre_hit(:,:,idx_sit), [], 3) / sqrt(size(GA.pre_hit(:,:,idx_sit), 3));
pre_miss_error_sit = std(GA.pre_miss(:,:,idx_sit), [], 3) / sqrt(size(GA.pre_miss(:,:,idx_sit), 3));
post_hit_error_sit = std(GA.post_hit(:,:,idx_sit), [], 3) / sqrt(size(GA.post_hit(:,:,idx_sit), 3));
post_miss_error_sit = std(GA.post_miss(:,:,idx_sit), [], 3) / sqrt(size(GA.post_miss(:,:,idx_sit), 3));


% calculate error bars / shadow around GA

x = GA.timevec';

prh_lo_sit = pre_hit_sit - pre_hit_error_sit;
prh_hi_sit = pre_hit_sit + pre_hit_error_sit;
prm_lo_sit = pre_miss_sit - pre_miss_error_sit;
prm_hi_sit = pre_miss_sit + pre_miss_error_sit;

poh_lo_sit = post_hit_sit - post_hit_error_sit;
poh_hi_sit = post_hit_sit + post_hit_error_sit;
pom_lo_sit = post_miss_sit - post_miss_error_sit;
pom_hi_sit = post_miss_sit + post_miss_error_sit;


% actual figure PRE -----------------------------------------------------------------------------

figure;
% HIT
hp1 = patch([x; x(end:-1:1);x(1)], [prh_lo_sit'; prh_hi_sit(end:-1:1)';prh_lo_sit(1)], 'b');                    % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', "#C0C0C0", 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, pre_hit_sit, 'color', '#C0C0C0', 'LineWidth', 1.5);

% MISS
hp2 = patch([x; x(end:-1:1);x(1)], [prm_lo_sit'; prm_hi_sit(end:-1:1)';prm_lo_sit(1)], 'b');       % create appearance of SEM in plot
hold on;
set(hp2, 'facecolor', "#CC3D3D", 'edgecolor', 'none');                                              % adjust,emts
hp2.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp2.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, pre_miss_sit,'color', '#CC3D3D');

legend('remembered', 'not remembered', 'Interpreter', 'none', 'Location', 'southoutside', 'Orientation', 'horizontal')
legend('boxoff')

% ACCESSORIES
yline(0,'Color',[0.5,0.5,0.5],'LineWidth',1.5, 'HandleVisibility','off');                           % line for y = 0
hold on
xline(0,'k:','linewidth',1.5,'HandleVisibility','off');                                             % line for x = 0
rectangle('Position',TOI, 'FaceColor',[0.5, 0.5, 0.5], 'LineStyle', 'none', 'FaceAlpha', 0.2);        % search space


ylabel('Amplitude [µV]', 'FontSize', 12)
xlabel('Time [ms]', 'FontSize', 12)
title('SME Grand Average PRE - Control', 'FontSize', 12, 'FontWeight','bold')
ax = gca;
ax.TitleHorizontalAlignment = 'left';

% TOPOPLOTS
axHit = axes('Position',topo_hit);  % Adjust the position/size as you like
topoplot(topo_pre_hit_sit, GA.chanlocs_swim, 'emarker2', {ROI, '.', 'k', 16});
clim(my_clims)

axMiss = axes('Position',topo_miss);
topoplot(topo_pre_miss_sit, GA.chanlocs_swim, 'emarker2', {ROI, '.', 'k', 16});
clim(my_clims)

% Draw colored boxes around topoplots
annotation('rectangle', box_hit, 'EdgeColor', '#283747', 'LineWidth', 2);
annotation('rectangle', box_miss, 'EdgeColor', '#85929e', 'LineWidth', 2);

% SAVE

 % cd(PATHOUT)
 % exportgraphics(gcf,'SME_pre_topos_conrol.png','Resolution',300)

% actual figure POST -----------------------------------------------------------------------------

figure;
% HIT
hp1 = patch([x; x(end:-1:1);x(1)], [poh_lo_sit'; poh_hi_sit(end:-1:1)';poh_lo_sit(1)], 'b');                    % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', "#283747", 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, post_hit_sit, 'color', '#283747', 'LineWidth', 1.5);

% MISS
hp2 = patch([x; x(end:-1:1);x(1)], [pom_lo_sit'; pom_hi_sit(end:-1:1)';pom_lo_sit(1)], 'r');       % create appearance of SEM in plot
hold on;
set(hp2, 'facecolor', "#85929e", 'edgecolor', 'none');                                              % adjust,emts
hp2.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp2.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, post_miss_sit,'color', '#85929e');

legend('remembered', 'not remembered', 'Interpreter', 'none', 'Location', 'southoutside', 'Orientation', 'horizontal')
legend('boxoff')

% ACCESSORIES
yline(0,'Color',[0.5,0.5,0.5],'LineWidth',1.5, 'HandleVisibility','off');                           % line for y = 0
hold on
xline(0,'k:','linewidth',1.5,'HandleVisibility','off');                                             % line for x = 0
rectangle('Position',TOI, 'FaceColor',[0.5, 0.5, 0.5], 'LineStyle', 'none', 'FaceAlpha', 0.2);        % search space

ylabel('Amplitude [µV]', 'FontSize', 12)
xlabel('Time [ms]', 'FontSize', 12)
title('SME Grand Average POST - Control', 'FontSize', 12, 'FontWeight','bold')
ax = gca;
ax.TitleHorizontalAlignment = 'left';

% TOPOPLOTS
axHit = axes('Position',topo_hit);  % Adjust the position/size as you like
topoplot(topo_post_hit_sit, GA.chanlocs_swim, 'emarker2', {ROI, '.', 'k', 16});
clim(my_clims)

axMiss = axes('Position', topo_miss);
topoplot(topo_post_miss_sit, GA.chanlocs_swim, 'emarker2', {ROI, '.', 'k', 16});
clim(my_clims)

% Draw colored boxes around topoplots
annotation('rectangle', box_hit, 'EdgeColor', '#283747', 'LineWidth', 2);
annotation('rectangle', box_miss, 'EdgeColor', '#85929e', 'LineWidth', 2);

% SAVE

% cd(PATHOUT)
% exportgraphics(gcf,'SME_post_topos_control.png','Resolution',300)


%% bike group -------------------------------------------------------------------------------------

groups = extractfield(SUB, 'GROUP');
groups = vertcat(groups{:});
idx_bike = find(strcmp(groups, {'bike'}));

pre_hit_bike = mean(GA.pre_hit(:,:,idx_bike), 3);
pre_miss_bike = mean(GA.pre_miss(:,:,idx_bike), 3);
post_hit_bike = mean(GA.post_hit(:,:,idx_bike), 3);
post_miss_bike = mean(GA.post_miss(:,:,idx_bike), 3);

topo_pre_hit_bike = squeeze(mean(GA.topo_pre_hit(:,:,idx_bike), 3));
topo_pre_miss_bike = squeeze(mean(GA.topo_pre_miss(:,:,idx_bike), 3));
topo_post_hit_bike = squeeze(mean(GA.topo_post_hit(:,:,idx_bike), 3));
topo_post_miss_bike = squeeze(mean(GA.topo_post_miss(:,:,idx_bike), 3));

pre_hit_error_bike = std(GA.pre_hit(:,:,idx_bike), [], 3) / sqrt(size(GA.pre_hit(:,:,idx_bike), 3));
pre_miss_error_bike = std(GA.pre_miss(:,:,idx_bike), [], 3) / sqrt(size(GA.pre_miss(:,:,idx_bike), 3));
post_hit_error_bike = std(GA.post_hit(:,:,idx_bike), [], 3) / sqrt(size(GA.post_hit(:,:,idx_bike), 3));
post_miss_error_bike = std(GA.post_miss(:,:,idx_bike), [], 3) / sqrt(size(GA.post_miss(:,:,idx_bike), 3));

% calculate error bars / shadow around GA

x = GA.timevec';

prh_lo_bike = pre_hit_bike - pre_hit_error_bike;
prh_hi_bike = pre_hit_bike + pre_hit_error_bike;
prm_lo_bike = pre_miss_bike - pre_miss_error_bike;
prm_hi_bike = pre_miss_bike + pre_miss_error_bike;

poh_lo_bike = post_hit_bike - post_hit_error_bike;
poh_hi_bike = post_hit_bike + post_hit_error_bike;
pom_lo_bike = post_miss_bike - post_miss_error_bike;
pom_hi_bike = post_miss_bike + post_miss_error_bike;

% actual figure PRE -----------------------------------------------------------------------------

figure;
% HIT
hp1 = patch([x; x(end:-1:1);x(1)], [prh_lo_bike'; prh_hi_bike(end:-1:1)';prh_lo_bike(1)], 'b');                    % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', "#e74c3c", 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, pre_hit_bike, 'color', '#e74c3c', 'LineWidth', 1.5);

% MISS
hp2 = patch([x; x(end:-1:1);x(1)], [prm_lo_bike'; prm_hi_bike(end:-1:1)';prm_lo_bike(1)], 'r');       % create appearance of SEM in plot
hold on;
set(hp2, 'facecolor', "#85929e", 'edgecolor', 'none');                                              % adjust,emts
hp2.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp2.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, pre_miss_bike,'color', '#85929e');

legend('remembered', 'not remembered', 'Interpreter', 'none', 'Location', 'southoutside', 'Orientation', 'horizontal')
legend('boxoff')


% ACCESSORIES
yline(0,'Color',[0.5,0.5,0.5],'LineWidth',1.5, 'HandleVisibility','off');                           % line for y = 0
hold on
xline(0,'k:','linewidth',1.5,'HandleVisibility','off');                                             % line for x = 0
rectangle('Position',TOI, 'FaceColor',[0.5, 0.5, 0.5], 'LineStyle', 'none', 'FaceAlpha', 0.2);        % search space

ylim([-3 6])
ylabel('Amplitude [µV]', 'FontSize', 12)
xlabel('Time [ms]', 'FontSize', 12)
title('SME Grand Average PRE - Bike', 'FontSize', 12, 'FontWeight','bold')
ax = gca;
ax.TitleHorizontalAlignment = 'left';

% TOPOPLOTS
axHit = axes('Position', topo_hit);  % Adjust the position/size as you like
topoplot(topo_pre_hit_bike, GA.chanlocs_swim, 'emarker2', {ROI, '.', 'k', 16});
clim(my_clims)

axMiss = axes('Position', topo_miss);
topoplot(topo_pre_miss_bike, GA.chanlocs_swim, 'emarker2', {ROI, '.', 'k', 16});
clim(my_clims)

% Draw colored boxes around topoplots
annotation('rectangle', box_hit, 'EdgeColor', '#e74c3c', 'LineWidth', 2);
annotation('rectangle', box_miss, 'EdgeColor', '#85929e', 'LineWidth', 2);

% SAVE

% cd(PATHOUT)
% exportgraphics(gcf,'SME_pre_topos_bike.png','Resolution',300)


% actual figure POST -----------------------------------------------------------------------------

figure;
% HIT
hp1 = patch([x; x(end:-1:1);x(1)], [poh_lo_bike'; poh_hi_bike(end:-1:1)';poh_lo_bike(1)], 'b');                    % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', "#e74c3c", 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, post_hit_bike, 'color', '#e74c3c', 'LineWidth', 1.5);

% MISS
hp2 = patch([x; x(end:-1:1);x(1)], [pom_lo_bike'; pom_hi_bike(end:-1:1)';pom_lo_bike(1)], 'r');       % create appearance of SEM in plot
hold on;
set(hp2, 'facecolor', "#85929e", 'edgecolor', 'none');                                              % adjust,emts
hp2.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp2.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, post_miss_bike,'color', '#85929e');
legend('remembered', 'not remembered', 'Interpreter', 'none', 'Location', 'southoutside', 'Orientation', 'horizontal')
legend('boxoff')


% ACCESSORIES
yline(0,'Color',[0.5,0.5,0.5],'LineWidth',1.5, 'HandleVisibility','off');                           % line for y = 0
hold on
xline(0,'k:','linewidth',1.5,'HandleVisibility','off');                                             % line for x = 0
rectangle('Position',TOI, 'FaceColor',[0.5, 0.5, 0.5], 'LineStyle', 'none', 'FaceAlpha', 0.2);        % search space

ylabel('Amplitude [µV]', 'FontSize', 12)
xlabel('Time [ms]', 'FontSize', 12)
title('SME Grand Average POST - Bike', 'FontSize', 12, 'FontWeight','bold')
ax = gca;
ax.TitleHorizontalAlignment = 'left';

% TOPOPLOTS
axHit = axes('Position', topo_hit);  % Adjust the position/size as you like
topoplot(topo_post_hit_bike, GA.chanlocs_swim, 'emarker2', {ROI, '.', 'k', 16});
clim(my_clims)

axMiss = axes('Position', topo_miss);
topoplot(topo_post_miss_bike, GA.chanlocs_swim, 'emarker2', {ROI, '.', 'k', 16});
clim(my_clims)


% Draw colored boxes around topoplots
annotation('rectangle', box_hit, 'EdgeColor', '#e74c3c', 'LineWidth', 2);
annotation('rectangle', box_miss, 'EdgeColor', '#85929e', 'LineWidth', 2);


% SAVE

% cd(PATHOUT)
% exportgraphics(gcf,'SME_post_topos_bike.png','Resolution',300)


%% swim group -------------------------------------------------------------------------------------

groups = extractfield(SUB, 'GROUP');
groups = vertcat(groups{:});
idx_swim = find(strcmp(groups, {'swim'}));

pre_hit_swim = mean(GA.pre_hit(:,:,idx_swim), 3);
pre_miss_swim = mean(GA.pre_miss(:,:,idx_swim), 3);
post_hit_swim = mean(GA.post_hit(:,:,idx_swim), 3);
post_miss_swim = mean(GA.post_miss(:,:,idx_swim), 3);

topo_pre_hit_swim = squeeze(mean(GA.topo_pre_hit(:,:,idx_swim), 3));
topo_pre_miss_swim = squeeze(mean(GA.topo_pre_miss(:,:,idx_swim), 3));
topo_post_hit_swim = squeeze(mean(GA.topo_post_hit(:,:,idx_swim), 3));
topo_post_miss_swim = squeeze(mean(GA.topo_post_miss(:,:,idx_swim), 3));

pre_hit_error_swim = std(GA.pre_hit(:,:,idx_swim), [], 3) / sqrt(size(GA.pre_hit(:,:,idx_swim), 3));
pre_miss_error_swim = std(GA.pre_miss(:,:,idx_swim), [], 3) / sqrt(size(GA.pre_miss(:,:,idx_swim), 3));
post_hit_error_swim = std(GA.post_hit(:,:,idx_swim), [], 3) / sqrt(size(GA.post_hit(:,:,idx_swim), 3));
post_miss_error_swim = std(GA.post_miss(:,:,idx_swim), [], 3) / sqrt(size(GA.post_miss(:,:,idx_swim), 3));

% calculate error bars / shadow around GA

x = GA.timevec';

prh_lo_swim = pre_hit_swim - pre_hit_error_swim;
prh_hi_swim = pre_hit_swim + pre_hit_error_swim;
prm_lo_swim = pre_miss_swim - pre_miss_error_swim;
prm_hi_swim = pre_miss_swim + pre_miss_error_swim;

poh_lo_swim = post_hit_swim - post_hit_error_swim;
poh_hi_swim = post_hit_swim + post_hit_error_swim;
pom_lo_swim = post_miss_swim - post_miss_error_swim;
pom_hi_swim = post_miss_swim + post_miss_error_swim;

% actual figure PRE -----------------------------------------------------------------------------

figure;
% HIT
hp1 = patch([x; x(end:-1:1);x(1)], [prh_lo_swim'; prh_hi_swim(end:-1:1)';prh_lo_swim(1)], 'b');                    % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', "#3498db", 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, pre_hit_swim, 'color', '#3498db', 'LineWidth', 1.5);

% MISS
hp2 = patch([x; x(end:-1:1);x(1)], [prm_lo_swim'; prm_hi_swim(end:-1:1)';prm_lo_swim(1)], 'r');       % create appearance of SEM in plot
hold on;
set(hp2, 'facecolor', "#85929e", 'edgecolor', 'none');                                              % adjust,emts
hp2.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp2.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, pre_miss_swim,'color', '#85929e');

legend('remembered', 'not remembered', 'Interpreter', 'none', 'Location', 'southoutside', 'Orientation', 'horizontal')
legend('boxoff')


% ACCESSORIES
yline(0,'Color',[0.5,0.5,0.5],'LineWidth',1.5, 'HandleVisibility','off');                           % line for y = 0
hold on
xline(0,'k:','linewidth',1.5,'HandleVisibility','off');                                             % line for x = 0
rectangle('Position',TOI, 'FaceColor',[0.5, 0.5, 0.5], 'LineStyle', 'none', 'FaceAlpha', 0.2);        % search space

ylabel('Amplitude [µV]', 'FontSize', 12)
xlabel('Time [ms]', 'FontSize', 12)
title('SME Grand Average PRE - Swim', 'FontSize', 12, 'FontWeight','bold')
ax = gca;
ax.TitleHorizontalAlignment = 'left';

% TOPOPLOTS
axHit = axes('Position',topo_hit);  % Adjust the position/size as you like
topoplot(topo_pre_hit_swim, GA.chanlocs_swim, 'emarker2', {ROI, '.', 'k', 16});
clim(my_clims)

axMiss = axes('Position', topo_miss);
topoplot(topo_pre_miss_swim, GA.chanlocs_swim, 'emarker2', {ROI, '.', 'k', 16});
clim(my_clims)

% Draw colored boxes around topoplots
annotation('rectangle', box_hit, 'EdgeColor', '#3498db', 'LineWidth', 2);
annotation('rectangle', box_miss, 'EdgeColor', '#85929e', 'LineWidth', 2);

% SAVE

% cd(PATHOUT)
% exportgraphics(gcf,'SME_pre_topos_swim.png','Resolution',300)

% actual figure POST -----------------------------------------------------------------------------

figure;
% HIT
hp1 = patch([x; x(end:-1:1);x(1)], [poh_lo_swim'; poh_hi_swim(end:-1:1)';poh_lo_swim(1)], 'b');                    % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', "#3498db", 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, post_hit_swim,'color', '#3498db', 'LineWidth', 1.5);

% MISS
hp2 = patch([x; x(end:-1:1);x(1)], [pom_lo_swim'; pom_hi_swim(end:-1:1)';pom_lo_swim(1)], 'r');       % create appearance of SEM in plot
hold on;
set(hp2, 'facecolor', "#85929e", 'edgecolor', 'none');                                              % adjust,emts
hp2.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp2.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, post_miss_swim,'color', '#85929e');

legend('remembered', 'not remembered', 'Interpreter', 'none', 'Location', 'southoutside', 'Orientation', 'horizontal')
legend('boxoff')

% ACCESSORIES
yline(0,'Color',[0.5,0.5,0.5],'LineWidth',1.5, 'HandleVisibility','off');                           % line for y = 0
hold on
xline(0,'k:','linewidth',1.5,'HandleVisibility','off');                                             % line for x = 0
rectangle('Position',TOI, 'FaceColor',[0.5, 0.5, 0.5], 'LineStyle', 'none', 'FaceAlpha', 0.2);        % search space

ylabel('Amplitude [µV]', 'FontSize', 12)
xlabel('Time [ms]', 'FontSize', 12)
title('SME Grand Average POST - Swim', 'FontSize', 12, 'FontWeight','bold')
ax = gca;
ax.TitleHorizontalAlignment = 'left';

% TOPOPLOTS
axHit = axes('Position', topo_hit);  % Adjust the position/size as you like
topoplot(topo_post_hit_swim, GA.chanlocs_swim, 'emarker2', {ROI, '.', 'k', 16});
clim(my_clims)

axMiss = axes('Position', topo_miss);
topoplot(topo_post_miss_swim, GA.chanlocs_swim, 'emarker2', {ROI, '.', 'k', 16});
clim(my_clims)

% Draw colored boxes around topoplots
annotation('rectangle', box_hit, 'EdgeColor', '#3498db', 'LineWidth', 2);
annotation('rectangle', box_miss, 'EdgeColor', '#85929e', 'LineWidth', 2);


% SAVE

% cd(PATHOUT)
% exportgraphics(gcf,'SME_post_topos_swim.png','Resolution',300)


%% save for Stats 

ID = extractfield(SUB, 'ID')';
group = extractfield(SUB, 'GROUP')';

all_hit_pre = extractfield(SUB, 'amp_pre_hit');
all_miss_pre = extractfield(SUB, 'amp_pre_miss');
all_hit_post = extractfield(SUB, 'amp_post_hit');
all_miss_post = extractfield(SUB, 'amp_post_miss');

T = table(ID, group, all_hit_pre', all_miss_pre', all_hit_post', all_miss_post');
T.Properties.VariableNames = {'ID', 'Group', 'Hit_Pre', 'Miss_Pre', 'Hit_Post', 'Miss_Post' } ;
writetable(T, [PATHOUT,'Amplitudes_SME.txt']);


%% extra plot: miss all together, hit separated by groups


% actual figure PRE -----------------------------------------------------------------------------

figure;
tiledlayout(6,6);
nexttile(13, [4,6])
% HIT SIT
hp1 = patch([x; x(end:-1:1);x(1)], [prh_lo_sit'; prh_hi_sit(end:-1:1)';prh_lo_sit(1)], 'b');                    % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', "#283747", 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, pre_hit_sit, 'color', '#808080', 'LineWidth', 1.5);

% HIT BIKE
hp1 = patch([x; x(end:-1:1);x(1)], [prh_lo_bike'; prh_hi_bike(end:-1:1)';prh_lo_bike(1)], 'b');                    % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', "r", 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, pre_hit_bike, 'color', '#8B0000', 'LineWidth', 1.5);

% HIT SWIM
hp1 = patch([x; x(end:-1:1);x(1)], [prh_lo_swim'; prh_hi_swim(end:-1:1)';prh_lo_swim(1)], 'b');                    % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', "b", 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, pre_hit_swim, 'color', '#0047AB', 'LineWidth', 1.5);

% MISS SIT
hp2 = patch([x; x(end:-1:1);x(1)], [prm_lo_sit'; prm_hi_sit(end:-1:1)';prm_lo_sit(1)], 'r');       % create appearance of SEM in plot
hold on;
set(hp2, 'facecolor', "#85929e", 'edgecolor', 'none');                                              % adjust,emts
hp2.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp2.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, pre_miss_sit,'color', '#A9A9A9', 'LineWidth', 1.5, 'LineStyle', '--');

% MISS BIKE
hp2 = patch([x; x(end:-1:1);x(1)], [prm_lo_bike'; prm_hi_bike(end:-1:1)';prm_lo_bike(1)], 'r');       % create appearance of SEM in plot
hold on;
set(hp2, 'facecolor', "#85929e", 'edgecolor', 'none');                                              % adjust,emts
hp2.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp2.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, pre_miss_bike,'color', '#E57373', 'LineWidth', 1.5, 'LineStyle', '--');

% MISS SWIM
hp2 = patch([x; x(end:-1:1);x(1)], [prm_lo_swim'; prm_hi_swim(end:-1:1)';prm_lo_swim(1)], 'r');       % create appearance of SEM in plot
hold on;
set(hp2, 'facecolor', "#85929e", 'edgecolor', 'none');                                              % adjust,emts
hp2.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp2.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, pre_miss_swim,'color', '#64B5F6', 'LineWidth', 1.5, 'LineStyle', '--');

legend('Remembered - Sit', 'Remembered - Bike', 'Remembered - Swim', 'Forgotten - Sit', 'Forgotten - Bike', ...
    'Forgotten - Swim', 'Interpreter', 'none', 'FontSize', 11)
%legend('boxoff')


% ACCESSORIES
yline(0,'Color',[0.5,0.5,0.5],'LineWidth',1.5, 'HandleVisibility','off');                           % line for y = 0
hold on
xline(0,'k:','linewidth',1.5,'HandleVisibility','off');                                             % line for x = 0
rectangle('Position',TOI, 'FaceColor',[0.5, 0.5, 0.5], 'LineStyle', 'none', 'FaceAlpha', 0.2);        % search space

ylabel('Amplitude [µV]', 'FontSize', 18)
xlabel('Time [ms]', 'FontSize', 18)
title('ERP: Memory Encoding PRE', 'FontSize', 18, 'FontWeight','bold')
ax = gca;
ax.TitleHorizontalAlignment = 'left';
ax.FontSize = 14;

ylim([-3 7])

% TOPOPLOTS
% SIT Topoplot (nexttile 1: spanning 2 rows x 2 columns)
axSIT = nexttile(1, [2,2]);
topoplot(topo_pre_hit_sit-topo_pre_miss_sit, GA.chanlocs_swim, 'emarker2', {ROI, '.', 'k', 16});
clim(my_clims)
% Draw rectangle around this tile using its normalized position
posSIT = axSIT.Position;
posSIT_expanded = [posSIT(1)-delta, posSIT(2)-delta, posSIT(3)+2*delta, posSIT(4)+2*delta];
annotation('rectangle', posSIT_expanded, 'EdgeColor', '#C0C0C0', 'LineWidth', 2);

% BIKE Topoplot (nexttile 3: spanning 2 rows x 2 columns)
axBIKE = nexttile(3, [2,2]);
topoplot(topo_pre_hit_bike-topo_pre_miss_bike, GA.chanlocs_swim, 'emarker2', {ROI, '.', 'k', 16});
clim(my_clims)
posBIKE = axBIKE.Position;
posBIKE_expanded = [posBIKE(1)-delta, posBIKE(2)-delta, posBIKE(3)+2*delta, posBIKE(4)+2*delta];
annotation('rectangle', posBIKE_expanded, 'EdgeColor', '#CC3D3D', 'LineWidth', 2);

% SWIM Topoplot (nexttile 5: spanning 2 rows x 2 columns)
axSWIM = nexttile(5, [2,2]);
topoplot(topo_pre_hit_swim-topo_pre_miss_swim, GA.chanlocs_swim, 'emarker2', {ROI, '.', 'k', 16});
clim(my_clims)
posSWIM = axSWIM.Position;
posSWIM_expanded = [posSWIM(1)-delta, posSWIM(2)-delta, posSWIM(3)+2*delta, posSWIM(4)+2*delta];
annotation('rectangle', posSWIM_expanded, 'EdgeColor', '#1E90FF', 'LineWidth', 2);

% SAVE

% cd(PATHOUT)
exportgraphics(gcf,'SME_pre_topos_allinone.svg','BackgroundColor', 'white','Resolution',300)

%% actual figure POST -----------------------------------------------------------------------------

figure;
tiledlayout(6,6);
nexttile(13, [4,6])
% HIT SIT
hp1 = patch([x; x(end:-1:1);x(1)], [poh_lo_sit'; poh_hi_sit(end:-1:1)';poh_lo_sit(1)], 'b');                    % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', "#283747", 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, post_hit_sit,'color', '#808080', 'LineWidth', 1.5);

% HIT BIKE
hp1 = patch([x; x(end:-1:1);x(1)], [poh_lo_bike'; poh_hi_bike(end:-1:1)';poh_lo_bike(1)], 'b');                    % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', "r", 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, post_hit_bike,'color', '#8B0000', 'LineWidth', 1.5);

% HIT SWIM
hp1 = patch([x; x(end:-1:1);x(1)], [poh_lo_swim'; poh_hi_swim(end:-1:1)';poh_lo_swim(1)], 'b');                    % create appearance of SEM in plot
hold on;
set(hp1, 'facecolor', "b", 'edgecolor', 'none');                                                    % adjust,emts
hp1.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp1.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, post_hit_swim,'color', '#0047AB', 'LineWidth', 1.5);

% MISS SIT
hp2 = patch([x; x(end:-1:1);x(1)], [pom_lo_sit'; pom_hi_sit(end:-1:1)';pom_lo_sit(1)], 'r');       % create appearance of SEM in plot
hold on;
set(hp2, 'facecolor', "#85929e", 'edgecolor', 'none');                                              % adjust,emts
hp2.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp2.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, post_miss_sit,'color', '#A9A9A9', 'LineWidth', 1.5, 'LineStyle', '--');

% MISS BIKE
hp2 = patch([x; x(end:-1:1);x(1)], [pom_lo_bike'; pom_hi_bike(end:-1:1)';pom_lo_bike(1)], 'r');       % create appearance of SEM in plot
hold on;
set(hp2, 'facecolor', "#85929e", 'edgecolor', 'none');                                              % adjust,emts
hp2.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp2.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, post_miss_bike,'color', '#E57373', 'LineWidth', 1.5, 'LineStyle', '--');

% MISS SWIM
hp2 = patch([x; x(end:-1:1);x(1)], [pom_lo_swim'; pom_hi_swim(end:-1:1)';pom_lo_swim(1)], 'r');       % create appearance of SEM in plot
hold on;
set(hp2, 'facecolor', "#85929e", 'edgecolor', 'none');                                              % adjust,emts
hp2.FaceAlpha = 0.1 ;                                                                               % makes the bar transparent
hp2.Annotation.LegendInformation.IconDisplayStyle = 'off';                                          % don't show it in legend
hold on
plot(GA.timevec, post_miss_swim,'color', '#64B5F6', 'LineWidth', 1.5, 'LineStyle', '--');

legend('Remembered - Sit', 'Remembered - Bike', 'Remembered - Swim', 'Forgotten - Sit', 'Forgotten - Bike', ...
    'Forgotten - Swim', 'Interpreter', 'none','FontSize', 11)
%legend('boxoff')

% ACCESSORIES
yline(0,'Color',[0.5,0.5,0.5],'LineWidth',1.5, 'HandleVisibility','off');                           % line for y = 0
hold on
xline(0,'k:','linewidth',1.5,'HandleVisibility','off');                                             % line for x = 0
rectangle('Position',TOI, 'FaceColor',[0.5, 0.5, 0.5], 'LineStyle', 'none', 'FaceAlpha', 0.2);        % search space

ylabel('Amplitude [µV]', 'FontSize', 18)
xlabel('Time [ms]', 'FontSize', 18)
title('ERP: Memory Encoding POST', 'FontSize', 18, 'FontWeight','bold')
ax = gca;
ax.TitleHorizontalAlignment = 'left';
ax.FontSize = 14;

ylim([-3 7])


% TOPOPLOTS
% SIT Topoplot (nexttile 1: spanning 2 rows x 2 columns)
axSIT = nexttile(1, [2,2]);
topoplot(topo_post_hit_sit-topo_post_miss_sit, GA.chanlocs_swim, 'emarker2', {ROI, '.', 'k', 16});
clim(my_clims)
% Draw rectangle around this tile using its normalized position
posSIT = axSIT.Position;
posSIT_expanded = [posSIT(1)-delta, posSIT(2)-delta, posSIT(3)+2*delta, posSIT(4)+2*delta];
annotation('rectangle', posSIT_expanded, 'EdgeColor', '#C0C0C0', 'LineWidth', 2);

% BIKE Topoplot (nexttile 3: spanning 2 rows x 2 columns)
axBIKE = nexttile(3, [2,2]);
topoplot(topo_post_hit_bike-topo_post_miss_bike, GA.chanlocs_swim, 'emarker2', {ROI, '.', 'k', 16});
clim(my_clims)
posBIKE = axBIKE.Position;
posBIKE_expanded = [posBIKE(1)-delta, posBIKE(2)-delta, posBIKE(3)+2*delta, posBIKE(4)+2*delta];
annotation('rectangle', posBIKE_expanded, 'EdgeColor', '#CC3D3D', 'LineWidth', 2);

% SWIM Topoplot (nexttile 5: spanning 2 rows x 2 columns)
axSWIM = nexttile(5, [2,2]);
topoplot(topo_post_hit_swim-topo_post_miss_swim, GA.chanlocs_swim, 'emarker2', {ROI, '.', 'k', 16});
clim(my_clims)
posSWIM = axSWIM.Position;
posSWIM_expanded = [posSWIM(1)-delta, posSWIM(2)-delta, posSWIM(3)+2*delta, posSWIM(4)+2*delta];
annotation('rectangle', posSWIM_expanded, 'EdgeColor', '#1E90FF', 'LineWidth', 2);


% SAVE

%cd(PATHOUT)
exportgraphics(gcf,'SME_post_topos_allinone.svg','BackgroundColor', 'white','Resolution',300)


%%






