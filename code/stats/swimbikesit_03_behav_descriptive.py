#%% Preparations ---------------------------------------------------------------

import pandas as pd
import numpy as np
import os
import pingouin as pg


file_path = 'Q:/Neuro/data/projects/mek_sports01/eegl/derivatives/'
pathout = 'Q:/Neuro/data/projects/mek_sports01/stats/results/'
os.chdir(file_path)

palette = ["#C0C0C0", "#CC3D3D","#1E90FF" ]


#%% Load & prepare data

df = pd.read_csv(os.path.join(file_path, 'performance_behav.txt'), sep="\t")

# Check for outliers -------------------------------------------------------

df_long = pd.melt(df, id_vars=["ID", 'Group'], value_vars= ['accuracy_pre', 'accuracy_post'], var_name="Block", value_name="Accuracy")

'Accuracy values are bounded (0–1), so the distribution is non-normal by nature, especially when values cluster near 1.'
'Standard deviation–based criteria assume a roughly symmetric, unbounded distribution — which doesn’t hold here.'

accuracy_cutoff = 0.50

# Flag outliers
df_long['Outlier'] = df_long['Accuracy'] < accuracy_cutoff

# View outliers
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


# %% collect descriptive data & store in table
### Recalled Words ###

rec_mean_pre = df['recall_pre'].mean()
rec_sd_pre = df['recall_pre'].std()
rec_min_pre = df['recall_pre'].min()
rec_max_pre = df['recall_pre'].max()

rec_mean_post = df['recall_post'].mean()
rec_sd_post = df['recall_post'].std()
rec_min_post = df['recall_post'].min()
rec_max_post = df['recall_post'].max()

# for sit
rec_sit_mean_pre = df.loc[df['Group'] == "sit"]['recall_pre'].mean()
rec_sit_sd_pre = df.loc[df['Group'] == "sit"]['recall_pre'].std()
rec_sit_min_pre = df.loc[df['Group'] == "sit"]['recall_pre'].min()
rec_sit_max_pre = df.loc[df['Group'] == "sit"]['recall_pre'].max()

rec_sit_mean_post = df.loc[df['Group'] == "sit"]['recall_post'].mean()
rec_sit_sd_post = df.loc[df['Group'] == "sit"]['recall_post'].std()
rec_sit_min_post = df.loc[df['Group'] == "sit"]['recall_post'].min()
rec_sit_max_post = df.loc[df['Group'] == "sit"]['recall_post'].max()

# for bike
rec_bike_mean_pre = df.loc[df['Group'] == "bike"]['recall_pre'].mean()
rec_bike_sd_pre = df.loc[df['Group'] == "bike"]['recall_pre'].std()
rec_bike_min_pre = df.loc[df['Group'] == "bike"]['recall_pre'].min()
rec_bike_max_pre = df.loc[df['Group'] == "bike"]['recall_pre'].max()

rec_bike_mean_post = df.loc[df['Group'] == "bike"]['recall_post'].mean()
rec_bike_sd_post = df.loc[df['Group'] == "bike"]['recall_post'].std()
rec_bike_min_post = df.loc[df['Group'] == "bike"]['recall_post'].min()
rec_bike_max_post = df.loc[df['Group'] == "bike"]['recall_post'].max()

# for swim
rec_swim_mean_pre = df.loc[df['Group'] == "swim"]['recall_pre'].mean()
rec_swim_sd_pre = df.loc[df['Group'] == "swim"]['recall_pre'].std()
rec_swim_min_pre = df.loc[df['Group'] == "swim"]['recall_pre'].min()
rec_swim_max_pre = df.loc[df['Group'] == "swim"]['recall_pre'].max()

rec_swim_mean_post = df.loc[df['Group'] == "swim"]['recall_post'].mean()
rec_swim_sd_post = df.loc[df['Group'] == "swim"]['recall_post'].std()
rec_swim_min_post = df.loc[df['Group'] == "swim"]['recall_post'].min()
rec_swim_max_post = df.loc[df['Group'] == "swim"]['recall_post'].max()


### Accuracy ###

acc_mean_pre = df['accuracy_pre'].mean()
acc_sd_pre = df['accuracy_pre'].std()

acc_mean_post = df['accuracy_post'].mean()
acc_sd_post = df['accuracy_post'].std()

# for sit
acc_sit_mean_pre = df.loc[df['Group'] == "sit"]['accuracy_pre'].mean()
acc_sit_sd_pre = df.loc[df['Group'] == "sit"]['accuracy_pre'].std()
acc_sit_min_pre = df.loc[df['Group'] == "sit"]['accuracy_pre'].min()
acc_sit_max_pre = df.loc[df['Group'] == "sit"]['accuracy_pre'].max()

acc_sit_mean_post = df.loc[df['Group'] == "sit"]['accuracy_post'].mean()
acc_sit_sd_post = df.loc[df['Group'] == "sit"]['accuracy_post'].std()
acc_sit_min_post = df.loc[df['Group'] == "sit"]['accuracy_post'].min()
acc_sit_max_post = df.loc[df['Group'] == "sit"]['accuracy_post'].max()

# for bike
acc_bike_mean_pre = df.loc[df['Group'] == "bike"]['accuracy_pre'].mean()
acc_bike_sd_pre = df.loc[df['Group'] == "bike"]['accuracy_pre'].std()
acc_bike_min_pre = df.loc[df['Group'] == "bike"]['accuracy_pre'].min()
acc_bike_max_pre = df.loc[df['Group'] == "bike"]['accuracy_pre'].max()

acc_bike_mean_post = df.loc[df['Group'] == "bike"]['accuracy_post'].mean()
acc_bike_sd_post = df.loc[df['Group'] == "bike"]['accuracy_post'].std()
acc_bike_min_post = df.loc[df['Group'] == "bike"]['accuracy_post'].min()
acc_bike_max_post = df.loc[df['Group'] == "bike"]['accuracy_post'].max()

# for swim
acc_swim_mean_pre = df.loc[df['Group'] == "swim"]['accuracy_pre'].mean()
acc_swim_sd_pre = df.loc[df['Group'] == "swim"]['accuracy_pre'].std()
acc_swim_min_pre = df.loc[df['Group'] == "swim"]['accuracy_pre'].min()
acc_swim_max_pre = df.loc[df['Group'] == "swim"]['accuracy_pre'].max()

acc_swim_mean_post = df.loc[df['Group'] == "swim"]['accuracy_post'].mean()
acc_swim_sd_post = df.loc[df['Group'] == "swim"]['accuracy_post'].std()
acc_swim_min_post = df.loc[df['Group'] == "swim"]['accuracy_post'].min()
acc_swim_max_post = df.loc[df['Group'] == "swim"]['accuracy_post'].max()


### Go RT ###

rt_mean_pre = df['RT_pre'].mean()
rt_sd_pre = df['RT_pre'].std()

rt_mean_post = df['RT_post'].mean()
rt_sd_post = df['RT_post'].std()

# for sit
rt_sit_mean_pre = df.loc[df['Group'] == "sit"]['RT_pre'].mean()
rt_sit_sd_pre = df.loc[df['Group'] == "sit"]['RT_pre'].std()
rt_sit_min_pre = df.loc[df['Group'] == "sit"]['RT_pre'].min()
rt_sit_max_pre = df.loc[df['Group'] == "sit"]['RT_pre'].max()

rt_sit_mean_post = df.loc[df['Group'] == "sit"]['RT_post'].mean()
rt_sit_sd_post = df.loc[df['Group'] == "sit"]['RT_post'].std()
rt_sit_min_post = df.loc[df['Group'] == "sit"]['RT_post'].min()
rt_sit_max_post = df.loc[df['Group'] == "sit"]['RT_post'].max()

# for bike
rt_bike_mean_pre = df.loc[df['Group'] == "bike"]['RT_pre'].mean()
rt_bike_sd_pre = df.loc[df['Group'] == "bike"]['RT_pre'].std()
rt_bike_min_pre = df.loc[df['Group'] == "bike"]['RT_pre'].min()
rt_bike_max_pre = df.loc[df['Group'] == "bike"]['RT_pre'].max()

rt_bike_mean_post = df.loc[df['Group'] == "bike"]['RT_post'].mean()
rt_bike_sd_post = df.loc[df['Group'] == "bike"]['RT_post'].std()
rt_bike_min_post = df.loc[df['Group'] == "bike"]['RT_post'].min()
rt_bike_max_post = df.loc[df['Group'] == "bike"]['RT_post'].max()

# for swim
rt_swim_mean_pre = df.loc[df['Group'] == "swim"]['RT_pre'].mean()
rt_swim_sd_pre = df.loc[df['Group'] == "swim"]['RT_pre'].std()
rt_swim_min_pre = df.loc[df['Group'] == "swim"]['RT_pre'].min()
rt_swim_max_pre = df.loc[df['Group'] == "swim"]['RT_pre'].max()

rt_swim_mean_post = df.loc[df['Group'] == "swim"]['RT_post'].mean()
rt_swim_sd_post = df.loc[df['Group'] == "swim"]['RT_post'].std()
rt_swim_min_post = df.loc[df['Group'] == "swim"]['RT_post'].min()
rt_swim_max_post = df.loc[df['Group'] == "swim"]['RT_post'].max()


### Build data frame

recall_mean = np.array([rec_sit_mean_pre, rec_sit_mean_post, rec_bike_mean_pre, rec_bike_mean_post,
                           rec_swim_mean_pre, rec_swim_mean_post])

recall_std = np.array([rec_sit_sd_pre, rec_sit_sd_post, rec_bike_sd_pre, rec_bike_sd_post,
                           rec_swim_sd_pre, rec_swim_sd_post])

recall_min = np.array([rec_sit_min_pre, rec_sit_min_post, rec_bike_min_pre, rec_bike_min_post,
                           rec_swim_min_pre, rec_swim_min_post])

recall_max = np.array([rec_sit_max_pre, rec_sit_max_post, rec_bike_max_pre, rec_bike_max_post,
                           rec_swim_max_pre, rec_swim_max_post])


accuracy_mean = np.array([acc_sit_mean_pre, acc_sit_mean_post, acc_bike_mean_pre, acc_bike_mean_post,
                           acc_swim_mean_pre, acc_swim_mean_post])

accuracy_std = np.array([acc_sit_sd_pre, acc_sit_sd_post, acc_bike_sd_pre, acc_bike_sd_post,
                           acc_swim_sd_pre, acc_swim_sd_post])

accuracy_min = np.array([acc_sit_min_pre, acc_sit_min_post, acc_bike_min_pre, acc_bike_min_post,
                           acc_swim_min_pre, acc_swim_min_post])

accuracy_max = np.array([acc_sit_max_pre, acc_sit_max_post, acc_bike_max_pre, acc_bike_max_post,
                           acc_swim_max_pre, acc_swim_max_post])



rt_mean = np.array([rt_sit_mean_pre, rt_sit_mean_post, rt_bike_mean_pre, rt_bike_mean_post,
                           rt_swim_mean_pre, rt_swim_mean_post])

rt_std = np.array([rt_sit_sd_pre, rt_sit_sd_post, rt_bike_sd_pre, rt_bike_sd_post,
                           rt_swim_sd_pre, rt_swim_sd_post])

rt_min = np.array([rt_sit_min_pre, rt_sit_min_post, rt_bike_min_pre, rt_bike_min_post,
                           rt_swim_min_pre, rt_swim_min_post])

rt_max = np.array([rt_sit_max_pre, rt_sit_max_post, rt_bike_max_pre, rt_bike_max_post,
                           rt_swim_max_pre, rt_swim_max_post])




groups = np.array(['control_pre', 'control_post', 'bike_pre', 'bike_post', 'swim_pre', 'swim_post'])

summary_array = np.array([groups, recall_mean, recall_std, recall_min, recall_max,
                          accuracy_mean, accuracy_std, accuracy_min, accuracy_max,
                          rt_mean, rt_std, rt_min, rt_max])

summary_data = pd.DataFrame(summary_array)
new_header = summary_data.iloc[0] #grab the first row for the header
summary_data = summary_data[1:] #take the data less the header row
summary_data.columns = new_header #set the header row as the df header

variables = ['recall_mean', 'recall_sd', 'recall_min', 'recall_max',
             'accuracy_mean', 'accuracy_sd', 'accuracy_min', 'accuracy_max',
             'rt_mean', 'rt_sd', 'rt_min', 'rt_max']
summary_data.insert(loc=0, column='variable', value=variables)

#os.chdir(pathout)
#summary_data.to_excel('descriptive_data.xlsx')


#%% List difficulty -----------------------------------------------------------------------------

df = pd.read_csv(os.path.join(file_path, 'performance_table.txt'), sep="\t")  # Adjust sep as needed
df = df.drop([10, 13, 28, 56, 61, 67, 76, 88])

df_long = pd.melt(df, id_vars=["ID", 'Group'], value_vars= ['per_list_1', 'per_list_2', 'per_list_3', 'per_list_4'], var_name="Block", value_name="Recall")


my_aov = pg.anova(data = df_long, dv = 'Recall', between = 'Block')
my_aov.round(3)

'''  Source  ddof1  ddof2      F  p-unc    np2
0  Block      3    324  0.992  0.397  0.009'''

# -> no differences between the lists!


