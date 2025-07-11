# README

## Overview

This repository contains Python scripts for behavioral and performance analyses from the "swimbikesit" study. The scripts process questionnaire, performance, and heart rate data, and generate statistical results and plots.

## Installation

1. **Clone the repository**  
   Download or clone the repository to your local machine.

2. **Install Python**  
   Ensure you have Python 3.11+ installed.

3. **Install dependencies**  
   The recommended way is to use [Poetry](https://python-poetry.org/):

   ```powershell
   # In the project directory
   poetry install --no-root
   ```

   Alternatively, install dependencies manually:

   ```powershell
   pip install pandas numpy seaborn matplotlib pingouin statsmodels
   ```

## How to Run Each Script

All scripts are run from the command line in the project directory:

```powershell
python swimbikesit_01_HR_plot.py
python swimbikesit_02_questionnaires.py
python swimbikesit_03_behav_descriptive.py
python swimbikesit_04_behav_confirmatory.py
python swimbikesit_04b_behav_exploratory.py
```

## Script Descriptions

### `swimbikesit_01_HR_plot.py`
- **Purpose:** Plots heart rate data for each participant.
- **Inputs:** CSV files in `sports_01/` to `sports_98/`.
- **Outputs:** Heart rate plots (PNG or shown interactively).

### `swimbikesit_02_questionnaires.py`
- **Purpose:** Processes and visualizes questionnaire data.
- **Inputs:** `all_questionnaires.txt`
- **Outputs:** Descriptive statistics and plots for questionnaire responses.

### `swimbikesit_03_behav_descriptive.py`
- **Purpose:** Computes and visualizes descriptive statistics for behavioral performance.
- **Inputs:** `performance_behav.txt`
- **Outputs:** Summary statistics and plots for accuracy, recall, and reaction times.

### `swimbikesit_04_behav_confirmatory.py`
- **Purpose:** Performs confirmatory statistical analyses (ANOVA, t-tests) on behavioral data.
- **Inputs:** `performance_behav.txt`
- **Outputs:**
  - **Plots:**
    - Word Recall (z-score, pre/post, by group)
    - Accuracy (z-score, pre/post, by group)
    - Reaction Times (z-score, pre/post, by group)
  - **Statistics:**
    - Mixed ANOVA results for recall, accuracy, and reaction time
    - Post-hoc t-tests and Cohen's d effect sizes
    - Assumption tests (normality, sphericity, homoscedasticity)

### `swimbikesit_04b_behav_exploratory.py`
- **Purpose:** Performs exploratory analyses on behavioral data.
- **Inputs:** `performance_behav.txt`
- **Outputs:** Additional plots and statistics (details in script).

## Output Files

- Plots are displayed interactively and can be saved as PNG files (see commented lines in scripts).
- Statistical results are printed to the console.

## Notes

- Data files must be present in the project directory.
- For saving plots, uncomment the `fig.savefig(...)` lines in each script and specify your