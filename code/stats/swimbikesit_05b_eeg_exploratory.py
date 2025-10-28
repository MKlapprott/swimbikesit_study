#%% Preparations

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


file_path = 'Q:/data/projects/mek_sports01/eegl/derivatives/'
pathout = 'Q:/data/projects/mek_sports01/stats/results/gng/'
os.chdir(file_path)

sns.set(style="ticks", rc={"lines.linewidth": 1})
palette = ["#C0C0C0", "#CC3D3D","#1E90FF" ]


################################################################################################
#%% SME Metrics
################################################################################################
df = pd.read_csv(os.path.join(file_path, 'Amplitudes_SME.txt'), sep=",")

# exclude outliers!!!
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


df['SME_Pre'] = df['Hit_Pre'] - df['Miss_Pre']
df['SME_Post'] = df['Hit_Post'] - df['Miss_Post']
#%%
df_long = pd.melt(df, id_vars=["ID", "Group"], value_vars=["SME_Pre", "SME_Post"], var_name="Block", value_name="Amplitude")
df_long['Group'] = pd.Categorical(df_long['Group'], categories=['sit', 'bike', 'swim'], ordered=True)

# test for general SME
my_ttest = scipy.stats.ttest_1samp(df_long['Amplitude'], 0, nan_policy = 'omit', alternative = 'greater')
my_ttest

#%% TtestResult(statistic=np.float64(4.26), pvalue=np.float64(1.7e-05), df=np.int64(151))
# SME is generally present


my_aov = pg.mixed_anova(data = df_long, dv = 'Amplitude', within = 'Block', between = 'Group', subject = 'ID')
my_aov.round(3)

#%% plot

fig3 = plt.figure(figsize=(3.25,2.5))
sns.set_style("ticks")
ax = sns.pointplot(data = df_long, x = 'Block' ,y = 'Amplitude',
            hue = 'Group', errorbar = 'se', palette = palette, dodge = True)
sns.despine()
sns.move_legend(ax, 'lower center',
                bbox_to_anchor=(.5, -0.35), ncol=3, title=None, frameon=False)
plt.setp(ax.get_legend().get_texts(), fontsize='8') 

# Add labels and title
ax.set_ylim(-0.5, 1.5)
plt.xlabel(" ")
plt.ylabel("Amplitude [µV]", fontsize=10)
plt.title("SME P300", x = 0.2, fontsize=12, fontweight="bold")
plt.xticks(fontsize=8)
plt.yticks(fontsize=8)
ax.set_xticklabels(['Pre','Post'])

plt.show()
#pathout = 'Q:/data/projects/mek_sports01/stats/results/sme/'
#os.chdir(pathout)
#fig1.savefig("recall.png", dpi=300, bbox_inches='tight')


################################################################################################
#%% Go / NoGo Metrics
################################################################################################

#%% load & prepare data

os.chdir(file_path)
df = pd.read_csv(os.path.join(file_path, 'Amplitudes_GNG.txt'), sep=",")
df = df.drop([10, 13, 28, 56, 61, 67, 76, 88]) 


df_long = pd.melt(df, id_vars=["ID", "Group"], value_vars=["NoGo_Pre", "NoGo_Post"],
                  var_name="Block_Condition", value_name="Amplitude")

df_long['Group'] = pd.Categorical(df_long['Group'], categories=['sit', 'bike', 'swim'], ordered=True)
df_long[['Condition', 'Block']] = df_long['Block_Condition'].str.split('_', expand=True)

# Drop the original 'Block_Condition' column
df_long = df_long.drop(columns=['Block_Condition'])
df_long = df_long[['ID', 'Group', 'Block', 'Condition', 'Amplitude']]

#%% test

my_aov = pg.mixed_anova(data = df_long, dv = 'Amplitude', within = 'Block', between = 'Group', subject = 'ID')
my_aov.round(3)


#%% plot

fig1 = plt.figure(figsize=(3.25,2.5))
sns.set_style("ticks")
ax = sns.pointplot(data = df_long, x = 'Block' ,y = 'Amplitude',
            hue = 'Group', errorbar = 'se', palette = palette, dodge = True)
sns.despine()
sns.move_legend(ax, 'lower center',
                bbox_to_anchor=(.5, -0.35), ncol=3, title=None, frameon=False)
plt.setp(ax.get_legend().get_texts(), fontsize='8') 

# Add labels and title
#ax.set_ylim(-0.5, 1.5)
plt.xlabel(" ")
plt.ylabel("Amplitude [µV]", fontsize=10)
plt.title("NoGo Amplitude")
plt.xticks(fontsize=8)
plt.yticks(fontsize=8)
ax.set_xticklabels(['Pre','Post'])

plt.show()

#pathout = 'Q:/data/projects/mek_sports01/stats/results/gng/'
#os.chdir(pathout)

#fig1.savefig("nogo_amp.png", dpi=300, bbox_inches='tight')

# -> Go Amplitude decreases in bike & control, but not in swim

# separate for groups --------------------------------------------------------


#%% NoGo N2 latencies

os.chdir(file_path)
df = pd.read_csv(os.path.join(file_path, 'Latencies_GNG.txt'), sep=",")
df = df.drop([10, 13, 28, 56, 61, 67, 76, 88])

df_long = pd.melt(df, id_vars=["ID", "Group"], value_vars=["NoGo_Pre", "NoGo_Post"],
                  var_name="Block_Condition", value_name="Latency")
df_long['Group'] = pd.Categorical(df_long['Group'], categories=['sit', 'bike', 'swim'], ordered=True)

# Split 'Block_Condition' into 'Condition' and 'Block'
df_long[['Condition', 'Block']] = df_long['Block_Condition'].str.split('_', expand=True)

# Drop the original 'Block_Condition' column
df_long = df_long.drop(columns=['Block_Condition'])
df_long = df_long[['ID', 'Group', 'Block', 'Condition', 'Latency']]

#%%

my_aov = pg.mixed_anova(data = df_long, dv = 'Latency', within = 'Block', between = 'Group', subject = 'ID')
my_aov.round(3)


#%% post hoc tests - planned comparisons --------------------------------------

# Create a difference score
df['Change'] = df['NoGo_Post'] - df['NoGo_Pre']

# Encode Group as binary (0 = Control, 1 = Treatment)
df['Group_code'] = df['Group'].map({'sit': 0, 'bike': 1})

# Group-wise change scores
change_control = df[df['Group'] == 'sit']['Change'].dropna()
change_treatment = df[df['Group'] == 'bike']['Change'].dropna()


# Independent t-test on change scores
tstat, pval, df_ = ttest_ind(change_treatment, change_control, usevar='unequal')
print(f"t = {tstat:.3f}, p = {pval:.3f}, , df = {df_:.0f}")

'''t = -0.099, p = 0.922, , df = 30  -> accomodated for missing values!'''


# Cohens d

# Means and standard deviations
mean_diff = np.mean(change_treatment) - np.mean(change_control)
pooled_sd = np.sqrt(((len(change_control) - 1) * np.var(change_control, ddof=1) +
                     (len(change_treatment) - 1) * np.var(change_treatment, ddof=1)) /
                     (len(change_control) + len(change_treatment) - 2))
cohen_d = mean_diff / pooled_sd

print(f"Cohen's d = {cohen_d:.3f}")

# Cohen's d = 0.567, medium effect size!


#%% group effect for noGO

fig4 = plt.figure(figsize=(3.25,2.5))
sns.set_style("ticks")
ax = sns.pointplot(data = df_long, x = 'Block' ,y = 'Latency',
            hue = 'Group', errorbar = 'se', palette = palette, dodge = True)
sns.despine()
sns.move_legend(ax, 'lower center',
                bbox_to_anchor=(.5, -0.35), ncol=3, title=None, frameon=False)
plt.setp(ax.get_legend().get_texts(), fontsize='8') 

# Add labels and title
#ax.set_ylim(-1, 1)
plt.xlabel(" ")
plt.ylabel("z score", fontsize=10)
plt.title("NoGo Latency")
plt.xticks(fontsize=8)
plt.yticks(fontsize=8)
#ax.set_xticklabels(['Pre','Post'])

plt.show()
#%%
pathout = 'Q:/Neuro/data/projects/mek_sports01/stats/results/gng/'
os.chdir(pathout)

fig4.savefig("nogo_lat.png", dpi=300, bbox_inches='tight')

