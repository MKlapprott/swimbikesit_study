# %% Preparations ---------------------------------------------------------------

import seaborn as sns
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.legend_handler import HandlerTuple
import os
import scipy
import pingouin as pg
import math
from matplotlib.collections import PolyCollection
from matplotlib.colors import to_rgb
from statsmodels.stats.weightstats import ttest_ind
import statsmodels.formula.api as smf


file_path = 'Q:/data/projects/mek_sports01/eegl/derivatives/'
pathout = 'Q:/data/projects/mek_sports01/stats/results/words/'
os.chdir(file_path)

palette = ["#C0C0C0", "#CC3D3D","#1E90FF" ]
sns.set(style="ticks", rc={"lines.linewidth": 0.7})

# %% Load & Prepare data -----------------------------------------------------------

### Check for outliers

os.chdir(file_path)
df = pd.read_csv(os.path.join(file_path, 'performance_behav.txt'), sep="\t")
df_long = pd.melt(df, id_vars=["ID", 'Group'], value_vars= ['accuracy_pre', 'accuracy_post'], var_name="Block", value_name="Accuracy")


'Accuracy values are bounded (0–1), so the distribution is non-normal by nature, especially when values cluster near 1.'
'Standard deviation–based criteria assume a roughly symmetric, unbounded distribution — which doesn’t hold here.'


accuracy_cutoff = 0.50

# Flag & view outliers
df_long['Outlier'] = df_long['Accuracy'] < accuracy_cutoff
outliers = df_long[df_long['Outlier']]
print(outliers)

''' 

ACCURACY
            ID Group          Block  Accuracy  Outlier
13   sports_15  swim   accuracy_pre      0.33     True
28   sports_34  bike   accuracy_pre      0.34     True
61   sports_70  bike   accuracy_pre      0.44     True
88   sports_97  swim   accuracy_pre      0.34     True
100  sports_12  swim  accuracy_post      0.40     True
118  sports_34  bike  accuracy_post      0.33     True
146  sports_65   sit  accuracy_post      0.46     True
157  sports_76   sit  accuracy_post      0.34     True
166  sports_85   sit  accuracy_post      0.38     True
178  sports_97  swim  accuracy_post      0.33     True

'''

df = df.drop([10, 13, 28, 56, 61, 67, 76, 88])

# additionally exclude swim group as they are only analyzed exploratorily
df = df.loc[df['Group'] != "swim"] 

# separate for groups
df_sit = df.loc[df['Group'] == "sit"]
df_bike = df.loc[df['Group'] == "bike"]


# %% Recalled words -------------------------------------------------------------


df_long = pd.melt(df, id_vars=["ID", 'Group'], value_vars= ['recall_pre', 'recall_post'], var_name="Block", value_name="Recall")

df_long['Block'] = pd.Categorical(df_long['Block'], categories=['recall_pre', 'recall_post'], ordered=True)
df_long['Group'] = pd.Categorical(df_long['Group'], categories=['sit', 'bike'], ordered=True) # , 'swim'


group_order = ['sit', 'bike']
block_order = ['recall_pre', 'recall_post']

#%% prepare Statistics

# 1) get pooled SD

SD_pre = math.sqrt(((len(df_bike)-1)*np.std(df_bike["recall_pre"])**2 +
                    (len(df_sit)-1)*np.std(df_sit["recall_pre"])**2) / (len(df_bike) + len(df_sit) - 2))


# 2) Standardize scores using pooled SD

# Filter only pretest scores
pretest_data = df_long[df_long['Block'] == 'recall_pre']

# Calculate the mean pretest score per group
group_means = pretest_data.groupby('Group')['Recall'].mean()

# Merge the group means back into the original DataFrame
df_long = df_long.merge(group_means, on='Group', suffixes=('', '_pre_mean'))

# Standardize scores
df_long['standardized_score'] = (df_long['Recall'] - df_long['Recall_pre_mean']) / SD_pre


# Define 'time' and 'group' as categorical with a specific reference
df_long['Block'] = pd.Categorical(df_long['Block'], categories=['recall_pre', 'recall_post'], ordered=True)
df_long['Group'] = pd.Categorical(df_long['Group'], categories=['sit', 'bike'], ordered=True)


#%% test for ANOVA assumptions -------------------------------------------------

normalitytest = pg.normality(df_long['standardized_score'])
sns.kdeplot(df_long['standardized_score'])

# test for normality (p should be > 0.2)
# -> normal distribution

boxtest = pg.sphericity(df_long, dv = "standardized_score", within = "Block", subject = "ID")

# test for sphericity (equal variances in within-subject var; p > 0.2)
# -> sphericity is given

homtest = pg.homoscedasticity(df_long, dv = "standardized_score", group = "Group")

# test for homoscedasticity (equality of variance in between-subs; p > 0.2)
# -> homoscedasticity is given


#%% calculate ANOVA ------------------------------------------------------------

my_aov = pg.mixed_anova(data = df_long, dv = 'standardized_score', within = 'Block', between = 'Group', subject = 'ID')
my_aov.round(3)

# -> Significant Interaction

'''      Source   SS    DF1  DF2   MS      F   p-unc    np2  eps
0        Group  1.495    1   57  1.495  0.653  0.422  0.011  NaN
1        Block  0.138    1   57  0.138  0.430  0.515  0.007  1.0
2  Interaction  1.495    1   57  1.495  4.657  0.035  0.076  NaN'''


# post hoc tests - planned comparisons --------------------------------------

# Create a difference score
df_wide = df_long.pivot(index='ID', columns='Block', values='standardized_score').reset_index()
df_wide['Change'] = df_wide['recall_post'] - df_wide['recall_pre']

# Merge back with group info
group_info = df.drop_duplicates(subset='ID')[['ID', 'Group']]
df_wide = df_wide.merge(group_info, on='ID')

# Encode Group as binary (0 = Control, 1 = Treatment)
df_wide['Group_code'] = df_wide['Group'].map({'sit': 0, 'bike': 1})


# Group-wise change scores
change_control = df_wide[df_wide['Group'] == 'sit']['Change']
change_treatment = df_wide[df_wide['Group'] == 'bike']['Change']

# Independent t-test on change scores
tstat, pval, df_ = ttest_ind(change_treatment, change_control, usevar='unequal')
print(f"t = {tstat:.3f}, p = {pval:.3f}, , df = {df_:.0f}")

'''t = 2.153, p = 0.036, , df = 56'''

# Cohens d

# Means and standard deviations
mean_diff = np.mean(change_treatment) - np.mean(change_control)
pooled_sd = np.sqrt(((len(change_control) - 1) * np.var(change_control, ddof=1) +
                     (len(change_treatment) - 1) * np.var(change_treatment, ddof=1)) /
                     (len(change_control) + len(change_treatment) - 2))
cohen_d = mean_diff / pooled_sd

print(f"Cohen's d = {cohen_d:.3f}")

# Cohen's d = 0.563, medium effect size!


#%% Plotting

def add_significance(ax, x1, x2, y, text, color="black"):
    """ 
    Add a line between two bars with text for significance annotations. 
    x1, x2 : positions of bars for comparison
    y : height at which the line is drawn
    text : significance text (e.g., '*', '**', etc.)
    """
    # Add line between bars
    ax.plot([x1, x1, x2, x2], [y, y + .2, y + .2, y], lw=1.5, color=color)
    # Add significance text above the line
    ax.text((x1 + x2) * 0.5, y + 0.3, text, ha='center', va='bottom', color=color)


df_recall = df_long


fig1 = plt.figure(figsize=(3.54,2.5))
sns.set_style("ticks")
ax = sns.pointplot(data = df_long, x = 'Block' ,y = 'standardized_score',
            hue = 'Group', errorbar = 'se', palette = palette, dodge = True)
sns.despine()
sns.move_legend(ax, 'lower center',
                bbox_to_anchor=(.5, -0.35), ncol=3, title=None, frameon=False)
plt.setp(ax.get_legend().get_texts(), fontsize='8') 

# Add labels and title
ax.set_ylim(-1.1, 1.1)
plt.xlabel(" ")
plt.ylabel("z-score", fontsize=10)
plt.title("Word Recall", x = 0.2, fontsize=12, fontweight="bold")
plt.xticks(fontsize=8)
plt.yticks(fontsize=8)
ax.set_xticklabels(['Pre','Post'])

plt.show()
 
#pathout = 'Q:/Neuro/data/projects/mek_sports01/stats/results/words/'
#os.chdir(pathout)
#fig1.savefig("recall.png", dpi=300, bbox_inches='tight')



# %% Accuracy -----------------------------------------------------------------

df_long = pd.melt(df, id_vars=["ID", 'Group', 'age'], value_vars= ['accuracy_pre', 'accuracy_post'], var_name="Block", value_name="Accuracy")

group_order = ['sit', 'bike']
block_order = ['accuracy_pre', 'accuracy_post']

df_long['Block'] = pd.Categorical(df_long['Block'], categories=['accuracy_pre', 'accuracy_post'], ordered=True)
df_long['Group'] = pd.Categorical(df_long['Group'], categories=['sit', 'bike', 'swim'], ordered=True)


#%% prepare Statistics

# 1) get pooled SD

SD_pre = math.sqrt(((len(df_bike)-1)*np.std(df_bike["accuracy_pre"])**2 +
                    (len(df_sit)-1)*np.std(df_sit["accuracy_pre"])**2) / ( len(df_bike) + len(df_sit) - 2))


# 2) Standardize scores using pooled SD

# Filter only pretest scores
pretest_data = df_long[df_long['Block'] == 'accuracy_pre']

# Calculate the mean pretest score per group
group_means = pretest_data.groupby('Group')['Accuracy'].mean()

# Merge the group means back into the original DataFrame
df_long = df_long.merge(group_means, on='Group', suffixes=('', '_pre_mean'))

# Standardize scores
df_long['standardized_score'] = (df_long['Accuracy'] - df_long['Accuracy_pre_mean']) / SD_pre

# Define 'time' and 'group' as categorical with a specific reference
df_long['Block'] = pd.Categorical(df_long['Block'], categories=['accuracy_pre', 'accuracy_post'], ordered=True)
df_long['Group'] = pd.Categorical(df_long['Group'], categories=['sit', 'bike'], ordered=True)


#%% test for ANOVA assumptions -------------------------------------------------

normalitytest = pg.normality(df_long['standardized_score'])
sns.kdeplot(df_long['standardized_score'])

# test for normality (p should be > 0.2)
# -> no normal distribution, but sample size large, soo it's okay

boxtest = pg.sphericity(df_long, dv = "standardized_score", within = "Block", subject = "ID")

# test for sphericity (equal variances in within-subject var; p > 0.2)
# -> sphericity is given

homtest = pg.homoscedasticity(df_long, dv = "standardized_score", group = "Group")

# test for homoscedasticity (equality of variance in between-subs; p > 0.2)
# -> homoscedasticity!

#%% calculate ANOVA ------------------------------------------------------------

my_aov = pg.mixed_anova(data = df_long, dv = 'standardized_score', within = 'Block', between = 'Group', subject = 'ID')
my_aov.round(3)

# ->Interaction effect

'''        Source     SS  DF1  DF2     MS      F  p-unc    np2  eps
0        Group  1.094    1   50  1.094  1.143  0.290  0.022  NaN
1        Block  0.087    1   50  0.087  0.265  0.609  0.005  1.0
2  Interaction  1.365    1   50  1.365  4.177  0.046  0.077  NaN'''


# post hoc tests - planned comparisons --------------------------------------

# Create a difference score
df_wide = df_long.pivot(index='ID', columns='Block', values='standardized_score').reset_index()
df_wide['Change'] = df_wide['accuracy_post'] - df_wide['accuracy_pre']

# Merge back with group info
group_info = df.drop_duplicates(subset='ID')[['ID', 'Group']]
df_wide = df_wide.merge(group_info, on='ID')

# Encode Group as binary (0 = Control, 1 = Treatment)
df_wide['Group_code'] = df_wide['Group'].map({'sit': 0, 'bike': 1})


# Group-wise change scores
change_control = df_wide[df_wide['Group'] == 'sit']['Change'].dropna()
change_treatment = df_wide[df_wide['Group'] == 'bike']['Change'].dropna()


# Independent t-test on change scores
tstat, pval, df_ = ttest_ind(change_treatment, change_control, usevar='unequal')
print(f"t = {tstat:.3f}, p = {pval:.3f}, , df = {df_:.0f}")

'''t = 2.031, p = 0.048, , df = 47  -> accomodated for missing values!'''


# Cohens d

# Means and standard deviations
mean_diff = np.mean(change_treatment) - np.mean(change_control)
pooled_sd = np.sqrt(((len(change_control) - 1) * np.var(change_control, ddof=1) +
                     (len(change_treatment) - 1) * np.var(change_treatment, ddof=1)) /
                     (len(change_control) + len(change_treatment) - 2))
cohen_d = mean_diff / pooled_sd

print(f"Cohen's d = {cohen_d:.3f}")

# Cohen's d = 0.567, medium effect size!


#%% Plotting

fig1 = plt.figure(figsize=(3.25,2.5))
sns.set_style("ticks")
ax = sns.pointplot(data = df_long, x = 'Block' ,y = 'standardized_score',
            hue = 'Group', errorbar = 'se', palette = palette, dodge = True)

sns.despine()
sns.move_legend(ax, 'lower center',
                bbox_to_anchor=(.5, -0.35), ncol=3, title=None, frameon=False)
plt.setp(ax.get_legend().get_texts(), fontsize='8') 

# Add labels and title
ax.set_ylim(-1.1, 1.1)
plt.xlabel(" ")
plt.ylabel("z-score", fontsize=10)
plt.title("Accuracy", x = 0.15, fontsize=12, fontweight="bold")
plt.xticks(fontsize=8)
plt.yticks(fontsize=8)
ax.set_xticklabels(['Pre','Post'])

plt.show()

#pathout = 'Q:/Neuro/data/projects/mek_sports01/stats/results/gng/'
#os.chdir(pathout)

#fig1.savefig("accuracy.png", dpi=300, bbox_inches='tight')


#%% check for covariation with age

# Step 1: Baseline model (replicates mixed ANOVA: Group × Time)

df_long = df_long.dropna()

model1 = smf.mixedlm("standardized_score ~ Group * Block",
                     data=df_long,
                     groups=df_long["ID"])
res1 = model1.fit()
print(res1.summary())

# Step 2: Add Age as covariate (confounder check)
model2 = smf.mixedlm("standardized_score ~ Group * Block + age",
                     data=df_long,
                     groups=df_long["ID"])
res2 = model2.fit()
print(res2.summary())

# Step 3: Test moderation (Age × Group × Time)
model3 = smf.mixedlm("standardized_score ~ Group * Block * age",
                     data=df_long,
                     groups=df_long["ID"])
res3 = model3.fit()
print(res3.summary())


# %% Reaction time

df = pd.read_csv(os.path.join(file_path, 'performance_behav.txt'), sep="\t")  # Adjust sep as needed
df = df.loc[df['Group'] != "swim"]                                              # exclude swim group


# Convert from wide to long format
df_long = pd.melt(df, id_vars=["ID", 'Group'], value_vars= ['RT_pre', 'RT_post'], var_name="Block", value_name="RT")
df_long = df_long.loc[df_long['Group'] != "swim"] 

# Define 'time' and 'group' as categorical with a specific reference
df_long['Block'] = pd.Categorical(df_long['Block'], categories=['RT_pre', 'RT_post'], ordered=True)
df_long['Group'] = pd.Categorical(df_long['Group'], categories=['sit', 'bike', 'swim'], ordered=True)


group_order = ['sit', 'bike']
block_order = ['RT_pre', 'RT_post']


##############################################################################
# prepare Statistics

# 1) get pooled SD

SD_pre = math.sqrt(((len(df_bike)-1)*np.std(df_bike["RT_pre"])**2 +
                    (len(df_sit)-1)*np.std(df_sit["RT_pre"])**2) /  len(df_bike) + len(df_sit) - 2)


# 2) Standardize scores using pooled SD

# Filter only pretest scores
pretest_data = df_long[df_long['Block'] == 'RT_pre']

# Calculate the mean pretest score per group
group_means = pretest_data.groupby('Group')['RT'].mean()

# Merge the group means back into the original DataFrame
df_long = df_long.merge(group_means, on='Group', suffixes=('', '_pre_mean'))

# Standardize scores
df_long['standardized_score'] = (df_long['RT'] - df_long['RT_pre_mean']) / SD_pre

# Define 'time' and 'group' as categorical with a specific reference
df_long['Block'] = pd.Categorical(df_long['Block'], categories=['RT_pre', 'RT_post'], ordered=True)
df_long['Group'] = pd.Categorical(df_long['Group'], categories=['sit', 'bike'], ordered=True)


# test for ANOVA assumptions -------------------------------------------------

normalitytest = pg.normality(df_long['standardized_score'])
sns.kdeplot(df_long['standardized_score'])

# test for normality (p should be > 0.2)
# -> no normal distribution, but sample size large, soo it's okay

boxtest = pg.sphericity(df_long, dv = "standardized_score", within = "Block", subject = "ID")

# test for sphericity (equal variances in within-subject var; p > 0.2)
# -> sphericity is given

homtest = pg.homoscedasticity(df_long, dv = "standardized_score", group = "Group")

# test for homoscedasticity (equality of variance in between-subs; p > 0.2)
# -> no homoscedasticity!


#%% ANOVA

my_aov = pg.mixed_anova(data = df_long, dv = 'standardized_score', within = 'Block', between = 'Group', subject = 'ID')
my_aov.round(3)

# main effect of block 

'''        Source     SS  DF1  DF2     MS      F  p-unc    np2  eps
0        Group  0.362    1   50  0.362  0.361  0.551  0.007  NaN
1        Block  0.951    1   50  0.951  7.658  0.008  0.133  1.0
2  Interaction  0.182    1   50  0.182  1.469  0.231  0.029  NaN'''


#%% Plotting


fig2 = plt.figure(figsize=(3.25,2.5))
sns.set_style("ticks")
ax = sns.pointplot(data = df_long, x = 'Block' ,y = 'standardized_score',
            hue = 'Group', errorbar = 'se', palette = palette, dodge = True)
sns.despine()
sns.move_legend(ax, 'lower center',
                bbox_to_anchor=(.5, -0.35), ncol=3, title=None, frameon=False)
plt.setp(ax.get_legend().get_texts(), fontsize='8') 

# Add labels and title
ax.set_ylim(-1.1, 1.1)
plt.xlabel(" ")
plt.ylabel("z-score", fontsize=10)
plt.title("Reaction Times", x = 0.25, fontsize=12, fontweight="bold")
plt.xticks(fontsize=8)
plt.yticks(fontsize=8)
ax.set_xticklabels(['Pre','Post'])

plt.show()

#fig2.savefig("rt.png", dpi=300, bbox_inches='tight')



