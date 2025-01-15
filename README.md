# CSAS2025

# Plate Discipline Analysis in MLB Batters Using Survival Analysis

## Project Overview
This project analyzes Major League Baseball (MLB) batters' plate discipline by applying survival analysis techniques to Statcast pitch swing data. The goal is to evaluate how different swing characteristics, such as bat speed and swing length, influence the likelihood of swinging at pitches outside the strike zone over successive plate appearances. The analysis incorporates Kaplan-Meier survival curves and Cox Proportional Hazards models to estimate these effects.

## Dataset
The dataset used in this analysis is `statcast_pitch_swing_data_20240402_20241030_with_arm_angle.csv`, which contains Statcast pitch-level data, including:
- **Bat Speed (`bat_speed`)**: Speed of the bat during the swing.
- **Swing Length (`swing_length`)**: Total distance covered by the bat during the swing.
- **Zone (`zone`)**: Pitch location zone.
- **Pitch Type** and other pitch-specific metrics.

## Methodology
1. **Data Cleaning and Preparation:**
   - Missing values in `bat_speed` and `swing_length` were replaced with 0.
   - Duplicates were removed based on game, batter, and pitch number.
   - Plate appearances (`at_bats`) were calculated, limited to a maximum of six.

2. **Defining the Outcome:**
   - A binary variable `swung_outside_zone` was created to indicate whether a batter swung at a pitch outside the strike zone.

3. **Survival Analysis:**
   - **Kaplan-Meier Survival Curve** was plotted to estimate the survival probability of avoiding swings outside the strike zone over successive at-bats.
   - **Cox Proportional Hazards Model** was used to analyze the impact of `bat_speed`, `swing_length`, and `release_speed` on the likelihood of swinging at pitches outside the strike zone.

4. **Stratification by Player:**
   - A stratified Cox model was fitted to account for individual batter effects (`player_name`).

5. **Visualization:**
   - **Forest Plots** of hazard ratios were created for interpreting the effects of swing mechanics.
   - Survival curves were plotted for batters with varying swing characteristics.

## How to Run the Analysis

1. **Install Required Libraries:**
   ```r
   install.packages(c("data.table", "survival", "ggplot2", "scales", "dplyr", "fastDummies", "broom", "gridExtra"))
2. **Run the R Script:**
    Execute the provided R script Plate Discipline.R to perform data processing, model fitting, and visualization.

**Key Results**

- Swing Length: Longer swing lengths significantly increase the risk of swinging at pitches outside the strike zone.
- Bat Speed: Higher bat speed is associated with a reduced risk of swinging outside the strike zone.
- Player Stratification: Individual differences among batters influence plate discipline, highlighting the need for stratified models.

**Visualization Examples**

- Kaplan-Meier Survival Curve: Displays the probability of avoiding swings outside the strike zone across plate appearances.
- Forest Plot: Visualizes the hazard ratios for swing mechanics, showing which factors increase or decrease risk.

**Project Structure**
├── Plate Discipline.R  # R script for data analysis and visualization
├── statcast_pitch_swing_data_20240402_20241030_with_arm_angle.csv  # Dataset
└── README.md  # Project documentation

**Future Work**
- Incorporate additional player-specific variables such as handedness and pitch types.
- Extend analysis to predict the impact of swing mechanics on overall batting performance.
- Implement time-varying covariates for in-game adjustments.
