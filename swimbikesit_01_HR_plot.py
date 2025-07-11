import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import pingouin as pg
from pathlib import Path


# Load and prepare data
df = pd.read_csv('sub_info.txt', sep = "\t")
df = df.iloc[:97, :]
df = df.drop([3, 15, 22, 27, 36, 51, 58])  # Remove excluded subjects
df = df.reset_index(drop = True)

df = df.drop([10, 13, 28, 56, 61, 67, 76, 88]) # remove the other excluded subjects

my_subs = df["ID"].tolist()
n_subs = len(my_subs)

min_length = 1112


# Initialize data structures
data_list_all_subs_pre_sit, data_list_all_subs_int_sit, data_list_all_subs_post_sit = [], [], []
data_list_all_subs_pre_bike, data_list_all_subs_int_bike, data_list_all_subs_post_bike = [], [], []
data_list_all_subs_pre_swim, data_list_all_subs_int_swim, data_list_all_subs_post_swim = [], [], []

data_dict = {
    "pre": {"sit": [], "bike": [], "swim": []},
    "int": {"sit": [], "bike": [], "swim": []},
    "post": {"sit": [], "bike": [], "swim": []},
}


sit_count = bike_count = swim_count = 0

# Statistical test: Reshape heart rate data
heart_rates = df.iloc[:, [0, 1, 8, 9, 10]]
heart_rates_long = heart_rates.melt(id_vars=["ID", "group"], 
                                    value_vars=["hr_pre", "hr_int", "hr_post"], 
                                    var_name="block", value_name="HF")


heart_rates_long["group"] = heart_rates_long["group"].astype("category").cat.reorder_categories(["sit", "bike", "swim"])
heart_rates_long["block"] = heart_rates_long["block"].astype("category").cat.reorder_categories(["hr_pre", "hr_int", "hr_post"])


# calculate ANOVA ------------------------------------------------------------

my_aov = pg.mixed_anova(data = heart_rates_long, dv = 'HF', within = 'block', between = 'group', subject = 'ID')
my_aov.round(3)

# significant main effects & interaction effect -> go for pairwise t-tests

# pairwise t-tests to make sure all potential differences are captured

# Perform pairwise comparisons
posthoc = pg.pairwise_ttests(
    dv="HF",  # Dependent variable
    between="group",  # Between-group variable
    within="block",  # Within-group variable
    subject="ID",  # Random effect (participant)
    data=heart_rates_long,
    padjust="bonferroni"
)

print(posthoc)

""" - Main effect of block for int vs. pre and int. vs. post (but not pre vs. post)
        -> HR significantly higher in int as compared to pre and post across groups
        
    - Main effect of group for sit vs. swim and bike vs. swim (but not bike vs. swim)
        -> HR significantly higher in swim and bike compaes to sit across blocks
        
    - Interaction effect for int in sit vs. swim and sit vs. bike (all p < 0.001)
        -> significant effect of physical activity in the intervention on HR 
        
    - Interaction effect for post in sit vs. swim (p < 0.01) and sit vs. bike (p < 0.05)
        -> also significant effect of PA on HR in post (participants calm down)
        
    - But write differently! No interactions here!!
"""


# Initialize an empty list to hold all participant data
all_data = []

df = df.reset_index(drop = True)

# Loop through subjects and process data
current_dir = Path.cwd()
sports_dirs = [d for d in current_dir.iterdir() if d.is_dir() and d.name.startswith("sports")]

for sub_dir in sports_dirs:
    files = sorted([f for f in sub_dir.iterdir() if f.suffix == ".csv"])
    HR_files = files[:3]

    # Check we have at least 3 files
    if len(HR_files) < 3:
        print(f"[Warning] {sub_dir.stem} has only {len(files)} CSVs; skipping.")
        continue
    
    # check if sub directory name matches the ID in df
    if sub_dir.stem not in my_subs:
        print(f"[Warning] {sub_dir.stem} not found in df; skipping.")
        continue

    # Process pre, int, post files
    for i, block in enumerate(["pre", "int", "post"]):
        heart_rate_series = pd.read_csv(HR_files[i], sep=",").dropna().iloc[:min_length, 1]
        heart_rate_data = heart_rate_series.to_frame(name="heart_rate")

        heart_rate_data["ID"] = sub_dir.stem
        idx = my_subs.index(sub_dir.stem)  # Get the index of the
        heart_rate_data["Group"] = df.loc[idx, 'group']
        heart_rate_data["Block"] = block
        heart_rate_data["time"] = range(1, len(heart_rate_data) + 1)

        all_data.append(heart_rate_data)
        
        
# Combine all data into a single DataFrame
final_df = pd.concat(all_data)

# Move the 'HR' column to the end
columns = [col for col in final_df.columns if col != "heart_rate"] + ["heart_rate"]
final_df = final_df[columns]



##############################################################################
# plot -----------------------------------------------------------------------


palette = ["#696969", "#DC143C","#1E90FF" ]
final_df['Group'] = pd.Categorical(final_df['Group'], categories=['sit', 'bike', 'swim'], ordered=True)

# Pre -----------------------------------------------------------------------

sns.set_theme(style="ticks", rc={"lines.linewidth": 0.7})

df_pre = final_df[final_df['Block'].str.contains("pre")]

fig1 = plt.figure(figsize=(2.15, 1.4))
sns.set_style("ticks")
ax = sns.lineplot(data=df_pre, x = 'time', y = 'heart_rate', hue = 'Group', palette = palette)
sns.despine()

ax.set_ylim(60, 150)
ax.legend_.remove()

plt.xticks(ticks=[], labels=[])
plt.ylabel("Heartrate [bpm]", fontsize=10)
plt.title(" ")
plt.xticks(fontsize=8)
plt.yticks(fontsize=8)

plt.show()

# Int -----------------------------------------------------------------------

df_int = final_df[final_df['Block'].str.contains("int")]

fig2 = plt.figure(figsize=(2.15, 1.4))
sns.set_style("ticks")
ax = sns.lineplot(data=df_int, x = 'time', y = 'heart_rate', hue = 'Group', palette = palette)
sns.despine()
ax.legend_.remove()

ax.set_ylim(60, 150)
plt.xticks(ticks=[], labels=[])
plt.title(" ")
plt.xticks(fontsize=8)

ax.yaxis.set_visible(False)  # This removes the entire y-axis (ticks, labels, and line)
ax.spines['left'].set_visible(False)  # This removes the left spine (y-axis line)

plt.show()


# Post -----------------------------------------------------------------------

df_post = final_df[final_df['Block'].str.contains("post")]

fig3 = plt.figure(figsize=(2.15, 1.4))
sns.set_style("ticks")
ax = sns.lineplot(data=df_post, x = 'time', y = 'heart_rate', hue = 'Group', palette = palette)
sns.despine()
sns.move_legend(ax, 'upper right',
                ncol=1, title=None, frameon=True)
plt.setp(ax.get_legend().get_texts(), fontsize='6')  

ax.set_ylim(60, 150)
plt.xticks(ticks=[], labels=[])
plt.title(" ")
plt.xticks(fontsize=8)

ax.yaxis.set_visible(False)  # This removes the entire y-axis (ticks, labels, and line)
ax.spines['left'].set_visible(False)  # This removes the left spine (y-axis line)

plt.show()


