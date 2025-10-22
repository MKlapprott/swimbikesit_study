# %% Preparations

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
import statsmodels.api as sm
from patsy import dmatrix, ContrastMatrix, EvalEnvironment


file_path = 'Q:/data/projects/mek_sports01/eegl/derivatives/'
pathout = 'Q:/data/projects/mek_sports01/stats/results/words/'
#pathout = 'F:/PhD/plots/'
os.chdir(file_path)

sns.set(style="ticks", rc={"lines.linewidth": 1})
palette = ["#C0C0C0", "#CC3D3D","#1E90FF" ]

# %% load & prepare data -----------------------------------------------------------


df = pd.read_csv(os.path.join(file_path, 'performance_table.txt'), sep="\t")
df_long = pd.melt(df, id_vars=["ID", 'Group'], value_vars= ['per_list_1', 'per_list_2', 'per_list_3', 'per_list_4'], var_name="Block", value_name="Recall")


my_aov = pg.anova(data = df_long, dv = 'Recall', between = 'Block')
my_aov.round(3)

'''  Source  ddof1  ddof2      F  p-unc    np2
0  Block      3    356  1.075  0.359  0.009'''

# -> no differences between the lists!


# Check for outliers -------------------------------------------------------

os.chdir(file_path)
df = pd.read_csv(os.path.join(file_path, 'performance_behav.txt'), sep="\t")  # Adjust sep as needed
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

# separate for groups
df_sit = df.loc[df['Group'] == "sit"]
df_bike = df.loc[df['Group'] == "bike"]
df_swim = df.loc[df['Group'] == "swim"]


# %% Recalled words -------------------------------------------------------------

df_long = pd.melt(df, id_vars=["ID", 'Group', 'age'], value_vars= ['recall_pre', 'recall_post'], var_name="Block", value_name="Recall")

df_long['Block'] = pd.Categorical(df_long['Block'], categories=['recall_pre', 'recall_post'], ordered=True)
df_long['Group'] = pd.Categorical(df_long['Group'], categories=['sit', 'bike', 'swim'], ordered=True) # , 'swim'


group_order = ['sit', 'bike', 'swim']
block_order = ['recall_pre', 'recall_post']

a = df['recall_pre'] + df['recall_post']
a.max()

#%% Statistics

# 1) get pooled SD

SD_pre = math.sqrt(( (len(df_bike)-1)*np.std(df_bike["recall_pre"])**2 + (len(df_swim)-1)*np.std(df_swim["recall_pre"])**2 +
                    (len(df_sit)-1)*np.std(df_sit["recall_pre"])**2) / (len(df_bike) + len(df_swim) + len(df_sit) - 3))


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
df_long['Group'] = pd.Categorical(df_long['Group'], categories=['sit', 'bike', 'swim'], ordered=True)


#%% test for ANOVA assumptions -------------------------------------------------

# test for normality (p should be > 0.2)
# -> no normal distribution

normalitytest = pg.normality(df_long['standardized_score'])
sns.kdeplot(df_long['standardized_score'])

# test for sphericity (equal variances in within-subject var; p > 0.2)
# -> sphericity is given

boxtest = pg.sphericity(df_long, dv = "standardized_score", within = "Block", subject = "ID")


# test for homoscedasticity (equality of variance in between-subs; p > 0.2)
# -> homoscedasticity is given

homtest = pg.homoscedasticity(df_long, dv = "standardized_score", group = "Group")


#%% calculate ANOVA ------------------------------------------------------------

my_aov = pg.mixed_anova(data = df_long, dv = 'standardized_score', within = 'Block', between = 'Group', subject = 'ID')
my_aov.round(3)


'''        Source     SS  DF1  DF2     MS      F  p-unc    np2  eps
0        Group  1.964    2   79  0.982  0.445  0.643  0.011  NaN
1        Block  0.581    1   79  0.581  1.582  0.212  0.020  1.0
2  Interaction  1.964    2   79  0.982  2.672  0.075  0.063  NaN'''


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
plt.title("Word Recall", x = 0.2, fontsize=12, fontweight="bold")
plt.xticks(fontsize=8)
plt.yticks(fontsize=8)
ax.set_xticklabels(['Pre','Post'])
 
#pathout = 'Q:/Neuro/data/projects/mek_sports01/stats/results/words/'
#os.chdir(pathout)
#fig1.savefig("recall.svg", dpi=300, bbox_inches='tight')

#%% correlate change with age -------------------------------------------------

df['change_recall'] = np.array(df_long[df_long['Block'] == 'recall_post']['standardized_score']) - np.array(df_long[df_long['Block'] == 'recall_pre']['standardized_score'])
df['Group'] = pd.Categorical(df['Group'], categories=['sit', 'bike', 'swim'], ordered=True)

df_long = pd.melt(df, id_vars=["ID", 'Group', 'age'], value_vars= 'change_recall', value_name="Recall")

print(scipy.stats.pearsonr(df_long['Recall'], df_long['age']))

# PearsonRResult(r = -0.042, pvalue = 0.71)

fig2 = plt.figure(figsize=(3.25,2.5))
sns.set_style("ticks")
ax = sns.regplot(data=df_long, x="age", y="Recall", line_kws={'color': 'green'}, scatter_kws={'color': 'green'})
sns.despine()

# Add labels and title
plt.ylim(-3, 3.2)
plt.xlabel(" ")
plt.ylabel("Recall [z-score]", fontsize=10)
plt.xlabel("Age [years]", fontsize=10)
plt.title("Word Recall - Age", x = 0.2, fontsize=12, fontweight="bold")
plt.xticks(fontsize=8)
plt.yticks(fontsize=8)

 
#fig2.savefig("recall_age.svg", dpi=300, bbox_inches='tight')


# %% Accuracy ---------------------------------------------------------------

df_long = pd.melt(df, id_vars=["ID", 'Group', 'age'], value_vars= ['accuracy_pre', 'accuracy_post'], var_name="Block", value_name="Accuracy")

group_order = ['sit', 'bike', 'swim']
block_order = ['accuracy_pre', 'accuracy_post']

df_long['Block'] = pd.Categorical(df_long['Block'], categories=['accuracy_pre', 'accuracy_post'], ordered=True)
df_long['Group'] = pd.Categorical(df_long['Group'], categories=['sit', 'bike', 'swim'], ordered=True)

df_long['Accuracy'].min()


#%% prepare Statistics

# 1) get pooled SD

SD_pre = math.sqrt(((len(df_bike)-1)*np.std(df_bike["accuracy_pre"])**2 + (len(df_swim)-1)*np.std(df_swim["accuracy_pre"])**2 +
                    (len(df_sit)-1)*np.std(df_sit["accuracy_pre"])**2) / ( len(df_bike) + len(df_swim) + len(df_sit) - 3))


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
df_long['Group'] = pd.Categorical(df_long['Group'], categories=['sit', 'bike', 'swim'], ordered=True)


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

# ->Interaction effect!!!

'''        Source     SS  DF1  DF2     MS      F  p-unc    np2  eps
0        Group  1.882    2   71  0.941  0.632  0.534  0.018  NaN
1        Block  0.043    1   71  0.043  0.095  0.759  0.001  1.0
2  Interaction  2.251    2   71  1.126  2.483  0.091  0.065  NaN'''



#%% Plotting

fig3 = plt.figure(figsize=(3.25,2.5))
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
#fig3.savefig("accuracy.svg", dpi=300, bbox_inches='tight')


#%% correlate change with age -------------------------------

df['change_acc'] = np.array(df_long[df_long['Block'] == 'accuracy_post']['standardized_score']) - np.array(df_long[df_long['Block'] == 'accuracy_pre']['standardized_score'])
df['Group'] = pd.Categorical(df['Group'], categories=['sit', 'bike', 'swim' ], ordered=True)

df_long_test = pd.melt(df, id_vars=["ID", 'Group', 'age'], value_vars= 'change_acc', value_name="Acc")

# correlation between column 1 and column2
df_test = df_long_test.dropna()
print(scipy.stats.pearsonr(df_test['Acc'], df_test['age']))

# PearsonRResult(statistic=-0.244, pvalue=0.035)

fig4 = plt.figure(figsize=(3.25,2.5))
sns.set_style("ticks")
ax = sns.regplot(data=df_test, x="age", y="Acc", line_kws={'color': 'green'}, scatter_kws={'color': 'green'})
sns.despine()

# Add labels and title
plt.ylim(-3, 3.2)
plt.xlabel(" ")
plt.ylabel("Accuracy [z-score]", fontsize=10)
plt.xlabel("Age [years]", fontsize=10)
plt.title("Accuracy - Age", x = 0.2, fontsize=12, fontweight="bold")
plt.xticks(fontsize=8)
plt.yticks(fontsize=8)


plt.show()

#fig4.savefig("accuracy_age.svg", dpi=300, bbox_inches='tight')


# %% Reaction time

df_long = pd.melt(df, id_vars=["ID", 'Group', 'age'], value_vars= ['RT_pre', 'RT_post'], var_name="Block", value_name="RT")

df_long['Block'] = pd.Categorical(df_long['Block'], categories=['RT_pre', 'RT_post'], ordered=True)
df_long['Group'] = pd.Categorical(df_long['Group'], categories=['sit', 'bike', 'swim'], ordered=True)

group_order = ['sit', 'bike', 'swim']
block_order = ['RT_pre', 'RT_post']


#%% prepare Statistics

# 1) get pooled SD

SD_pre = math.sqrt(((len(df_bike)-1)*np.std(df_bike["RT_pre"])**2 + (len(df_swim)-1)*np.std(df_swim["RT_pre"])**2 +
                    (len(df_sit)-1)*np.std(df_sit["RT_pre"])**2) /  (len(df_bike) + len(df_swim) + len(df_sit) - 3))


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
df_long['Group'] = pd.Categorical(df_long['Group'], categories=['sit', 'bike', 'swim'], ordered=True)


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
# -> no homoscedasticity!


#%% ANOVA

my_aov = pg.mixed_anova(data = df_long, dv = 'standardized_score', within = 'Block', between = 'Group', subject = 'ID')
my_aov.round(3)

# main effect of block

'''        Source     SS  DF1  DF2     MS       F  p-unc    np2  eps
0        Group  0.406    2   71  0.203   0.107  0.899  0.003  NaN
1        Block  1.924    1   71  1.924  13.845  0.000  0.163  1.0
2  Interaction  0.265    2   71  0.132   0.953  0.391  0.026  NaN'''


#%% Plotting

fig5 = plt.figure(figsize=(3.25,2.5))
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

fig5.savefig("rt.svg", dpi=300, bbox_inches='tight')


#%% correlate change with age -------------------------------

df['change_rt'] = np.array(df_long[df_long['Block'] == 'RT_post']['standardized_score']) - np.array(df_long[df_long['Block'] == 'RT_pre']['standardized_score'])
df['Group'] = pd.Categorical(df['Group'], categories=['sit', 'bike', 'swim' ], ordered=True)

df_long = pd.melt(df, id_vars=["ID", 'Group', 'age'], value_vars= 'change_rt', value_name="RT")

df_test = df_long.dropna()
print(scipy.stats.pearsonr(df_test['RT'], df_test['age']))

# PearsonRResult(statistic=-0.124, pvalue=0.292)


fig6 = plt.figure(figsize=(3.25,2.5))
sns.set_style("ticks")
ax = sns.regplot(data=df_test, x="age", y="RT", line_kws={'color': 'green'}, scatter_kws={'color': 'green'})
sns.despine()

# Add labels and title
plt.ylim(-3, 3.2)
plt.xlabel(" ")
plt.ylabel("RTs [z-score]", fontsize=10)
plt.xlabel("Age [years]", fontsize=10)
plt.title("Go RT - Age", x = 0.2, fontsize=12, fontweight="bold")
plt.xticks(fontsize=8)
plt.yticks(fontsize=8)

plt.show()

#fig6.savefig("rt_age.svg", dpi=300, bbox_inches='tight')

