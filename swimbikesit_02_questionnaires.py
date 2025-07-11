import seaborn as sns
import pandas as pd
import matplotlib.pyplot as plt
from scipy.stats import mannwhitneyu
from statsmodels.stats.multitest import multipletests


df = pd.read_csv('all_questionnaires.txt', sep="\t")  # Adjust sep as needed

df = df.drop([3, 15, 22, 27, 36, 51, 58])  # Remove excluded subjects
df = df.reset_index(drop = True)


### Check for exlusion criterion ---------------------------------------------
# -> exclude subjects with accuracy < 50% in Go / NoGo task from all analyses

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


df['group'] = pd.Categorical(df['group'], categories=['sit', 'bike', 'swim'], ordered=True)

##############################################################################
# PANAS

positive_items = ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8','P9', 'P10']
negative_items = ['N1', 'N2', 'N3', 'N4', 'N5', 'N6',  'N7', 'N8',  'N9', 'N10']

df['mean_positive'] = df[positive_items].mean(axis=1)
df['mean_negative'] = df[negative_items].mean(axis=1)


df_long = pd.melt(df, id_vars=["ID", 'group'], value_vars= ['mean_positive', 'mean_negative'],
                  var_name="Question", value_name="Score")


##############################################################################
# Statistics



df_sit = df.loc[df['group'] == "sit"]
df_bike = df.loc[df['group'] == "bike"]
df_swim = df.loc[df['group'] == "swim"]
df_PE = df.loc[df['group'] != "sit"]


# Positive scale difference
u_pos, p_pos = mannwhitneyu(df_sit['mean_positive'], df_PE['mean_positive'], alternative='two-sided')
print(f"Positive scale: U={u_pos}, p={p_pos:.4f}")

# Negative scale difference
u_neg, p_neg = mannwhitneyu(df_sit['mean_negative'], df_PE['mean_negative'], alternative='two-sided')
print(f"Negative scale: U={u_neg}, p={p_neg:.4f}")

'''Positive scale: U=456.0, p=0.0033
Negative scale: U=606.5, p=0.1268'''



### plot ---------------------------------------------------------------------
# Figure 3a

palette = ["#696969", "#DC143C","#1E90FF" ]

sns.set(style="ticks", rc={"lines.linewidth": 0.7})

def add_significance(ax, x1, x2, y, text, color="black"):
    """ 
    Add a line between two bars with text for significance annotations. 
    x1, x2 : positions of bars for comparison
    y : height at which the line is drawn
    text : significance text (e.g., '*', '**', etc.)
    """
    # Add line between bars
    #ax.plot([x1, x1, x2, x2], [y, y + .2, y + .2, y], lw=1.5, color=color)
    # Add significance text above the line
    ax.text((x1 + x2) * 0.5, y , text, ha='center', va='bottom', color=color)

# Get the maximum y-value in the plot for setting annotation heights
y_max = 4



fig1 = plt.figure(figsize=(3.54,2.5))
sns.set_style("ticks")
ax = sns.barplot(data=df_long, x="Question", y="Score", hue = "group", errorbar = 'se',
                   palette = palette, width = 0.55)
sns.despine()
sns.move_legend(ax, 'upper right',
                ncol=1, title=None, frameon=True)
plt.setp(ax.get_legend().get_texts(), fontsize='8')  

add_significance(ax, x1=-0.5, x2=0.25, y=y_max, text="***")       # P1

# Add labels and title
ax.set_ylim(0.5, 5)
plt.xlabel(" ")
plt.gca().set_xticklabels(["Positive Items", "Negative Items"])
plt.ylabel("PANAS Score", fontsize=10)
plt.title(" ")
plt.xticks(fontsize=8)
plt.yticks(fontsize=8)

plt.show()

#pathout = 'Q:/Neuro/data/projects/mek_sports01/stats/results/quest/'
#os.chdir(pathout)

#fig1.savefig("panas.svg", dpi=300, bbox_inches='tight')



##############################################################################
# Nasa TLX

# reduce to items 1,2, and 4
item_names = ['tlx-1', 'tlx-2', 'tlx-4']
pvals = []
us = []

df = df.drop([12])

for item in item_names:
    u, p = mannwhitneyu(
        df[df['group'] == 'sit'][item],
        df[df['group'] != 'sit'][item],
        alternative='two-sided'
    )
    pvals.append(p)
    us.append(u)

# Apply Bonferroni correction
_, pvals_bonf, _, _ = multipletests(pvals, method='bonferroni')

# Print results
for item, raw_p, adj_p in zip(item_names, pvals, pvals_bonf):
    print(f"{item}: raw p = {raw_p:.4f}, Bonferroni-corrected p = {adj_p:.4f}")

   
''' tlx-1: raw p = 0.3949, Bonferroni-corrected p = 1.0000 -> mental demand
    tlx-2: raw p = 0.0000, Bonferroni-corrected p = 0.0000 -> physical demand
    tlx-4: raw p = 0.0000, Bonferroni-corrected p = 0.0000 -> effort '''


# plotting ------------------------------------------------------------------
# Figure 3b

df_long = pd.melt(df, id_vars=["ID", 'group'], value_vars = ['tlx-1', 'tlx-2',  # don't even consider 3
                  'tlx-4'], var_name="Question", value_name="Score")

y_max = 8

fig2 = plt.figure(figsize=(3.54,2.5))
sns.set_style("ticks")

ax = sns.barplot(data = df_long, x = "Question", y = "Score", hue = "group", palette = palette, errorbar = 'se')
sns.despine()
#sns.move_legend(ax, 'lower center',
#                bbox_to_anchor=(.5, -0.4), ncol=3, title=None, frameon=False,)
plt.setp(ax.get_legend().get_texts(), fontsize='8')  


add_significance(ax, x1= 0.6, x2=1.2, y=y_max, text="***")       # tlx 2
add_significance(ax, x1= 1.6, x2=2.2, y=y_max, text="***")          # tlx 3

# Add labels and title
ax.set_ylim(-0.5, 10)
plt.xlabel(" ")
plt.gca().set_xticklabels(["Mental demand", "Physical demand", "Effort"])
plt.ylabel("NASA-TLX Score", fontsize=10)
plt.title(" ")
plt.xticks(fontsize=8)
plt.yticks(fontsize=8)
plt.legend([],[], frameon=False)

plt.show()

#os.chdir(pathout)
#fig2.savefig("nasa-tlx.svg", dpi=300, bbox_inches='tight')



# calculate mean answers NASA tlx --------------------------------------------

# separate for groups
df_sit = df.loc[df['group'] == "sit"]
df_bike = df.loc[df['group'] == "bike"]
df_swim = df.loc[df['group'] == "swim"]

mean_sit_mental = df_sit['tlx-1'].mean()
std_sit_mental = df_sit['tlx-1'].std()

mean_sit_physical = df_sit['tlx-2'].mean()
std_sit_physical = df_sit['tlx-2'].std()

mean_sit_effort = df_sit['tlx-4'].mean()
std_sit_effort = df_sit['tlx-4'].std()


## ----------------------------------------------

mean_bike_mental = df_bike['tlx-1'].mean()
std_bike_mental = df_bike['tlx-1'].std()

mean_bike_physical = df_bike['tlx-2'].mean()
std_bike_physical = df_bike['tlx-2'].std()

mean_bike_effort = df_bike['tlx-4'].mean()
std_bike_effort = df_bike['tlx-4'].std()



## ----------------------------------------------

mean_swim_mental = df_swim['tlx-1'].mean()
std_swim_mental = df_swim['tlx-1'].std()

mean_swim_physical = df_swim['tlx-2'].mean()
std_swim_physical = df_swim['tlx-2'].std()

mean_swim_effort = df_swim['tlx-4'].mean()
std_swim_effort = df_swim['tlx-4'].std()


# calculate mean answers PANAS -----------------------------------------------

mean_sit_active = df_sit['P1'].mean()
std_sit_active = df_sit['P1'].std()

mean_sit_strong = df_sit['P4'].mean()
std_sit_strong = df_sit['P4'].std()

mean_sit_proud = df_sit['P6'].mean()
std_sit_proud = df_sit['P6'].std()

mean_sit_alert = df_sit['P8'].mean()
std_sit_alert = df_sit['P8'].std()


## ----------------------------------------------

mean_bike_active = df_bike['P1'].mean()
std_bike_active = df_bike['P1'].std()

mean_bike_strong = df_bike['P4'].mean()
std_bike_strong = df_bike['P4'].std()

mean_bike_proud = df_bike['P6'].mean()
std_bike_proud = df_bike['P6'].std()

mean_bike_alert = df_bike['P8'].mean()
std_bike_alert = df_bike['P8'].std()


## ----------------------------------------------

mean_swim_active = df_swim['P1'].mean()
std_swim_active = df_swim['P1'].std()

mean_swim_strong = df_swim['P4'].mean()
std_swim_strong = df_swim['P4'].std()

mean_swim_proud = df_swim['P6'].mean()
std_swim_proud = df_swim['P6'].std()

mean_swim_alert = df_swim['P8'].mean()
std_swim_alert = df_swim['P8'].std()












