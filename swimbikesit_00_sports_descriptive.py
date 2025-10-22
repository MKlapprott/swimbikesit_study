#%% Preparations
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import os

palette = ["#C0C0C0", "#CC3D3D","#1E90FF" ]

#%% load & prepare data

df = pd.read_csv("Q:/data/projects/mek_sports01/eegl/rawdata/mek_sports01_sub_info.txt", sep='\t')

df = df.drop([3, 11, 14,15,22,27,32,36,63,68,74,83,95])
df['group'] = pd.Categorical(df['group'], categories=['sit', 'bike', 'swim'], ordered=True)

#%% Define sport categories
categories = ["swim", "run", "gym", "yoga", "footb.", "bike", "tennis", "volleyb.", "climb", "dance", "handb."]
def categorize_sport(sport):
    sport = sport.strip().lower()
    if sport in categories:
        return sport
    return "etc"


# Split sports into lists
df["sport_list"] = df["sport"].str.split(",")

# Split sports into lists (handle NaN safely)
df["sport_list"] = df["sport"].fillna("").apply(lambda x: x.split(",") if x else [])

# Normalize and categorize
df["sport_list"] = df["sport_list"].apply(
    lambda x: [categorize_sport(s.strip()) for s in x]
)

#%% One-hot encode participants' sports ---
rows = []
for _, row in df.iterrows():
    for s in set(row["sport_list"]):  # set() avoids double-counting per person
        rows.append({"ID": row["ID"], "group": row["group"], "sport": s})

long_df = pd.DataFrame(rows)

# Count per group & sport
counts = long_df.groupby(["group", "sport"])["ID"].nunique().reset_index(name="count")
group_order = ["sit", "bike", "swim"]
counts["group"] = pd.Categorical(counts["group"], categories=group_order, ordered=True)


# Convert to percentages
group_sizes = df.groupby("group")["ID"].nunique().rename("total")
counts = counts.merge(group_sizes, on="group")
counts["percentage"] = 100 * counts["count"] / counts["total"]


#%% Plot

fig1 = plt.figure(figsize=(7,2.5))
sns.set_style("ticks")
ax = sns.barplot(data=counts, x="sport", y="percentage", hue = "group",
                   palette = palette, order=['swim', 'gym', 'run',
                                                           'footb.', 'bike',
                                                           "dance",'tennis','yoga',
                                                           "volleyb.", "climb",
                                                           'handb.', 'etc'])
sns.despine()
sns.move_legend(ax, 'upper right',
                ncol=1, title=None, frameon=True)
plt.setp(ax.get_legend().get_texts(), fontsize='8')  


# Add labels and title
ax.set_ylim(0, 100)
plt.xlabel(" ")
plt.ylabel("% Participants", fontsize=10)
plt.title(" ")
plt.xticks(fontsize=8)
plt.yticks(fontsize=8)

plt.show()

pathout = 'Q:/data/projects/mek_sports01/stats/results/'
os.chdir(pathout)

fig1.savefig("sports.svg", dpi=300, bbox_inches='tight')

#%% Summary statistics about years of training and frequency

summary = df.groupby("group")[["yot", "regular"]].agg(
    mean=("yot", "mean"),
    sd=("yot", "std"),
    min=("yot", "min"),
    max=("yot", "max")
)

summary_regular = df.groupby("group")["regular"].agg(
    mean="mean",
    sd="std",
    min="min",
    max="max"
)

# Combine into one table
summary_all = pd.concat([summary, summary_regular], axis=1)
print(summary_all)






