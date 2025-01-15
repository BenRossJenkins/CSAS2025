library(data.table)
library(survival)
library(ggplot2)
library(scales)  # For percent formatting
library(dplyr)
library(fastDummies)
library(broom)  # For tidy model outputs

# Load the dataset
data <- fread('/Users/benjenkins/Downloads/data-5/statcast_pitch_swing_data_20240402_20241030_with_arm_angle.csv')

# Replace NAs in bat_speed and swing_length with 0
data[, bat_speed := ifelse(is.na(bat_speed), 0, bat_speed)]
data[, swing_length := ifelse(is.na(swing_length), 0, swing_length)]

# Remove duplicate rows based on 'game_pk', 'batter', and 'pitch_number'
data <- unique(data, by = c("game_pk", "batter", "pitch_number"))

# Calculate 'at_bats' by grouping by 'game_pk' and 'batter'
data[, at_bats := seq_len(.N), by = .(game_pk, batter)]

# **Remove** rows where 'at_bats' > 6
data <- data[at_bats <= 6]

# Define swung_outside_zone: Binary outcome
data[, swung_outside_zone := ifelse(zone >= 11 & type == "S", 1, 0)]

# Create a survival object
surv_object <- Surv(time = data$at_bats, event = data$swung_outside_zone)

# Fit Kaplan-Meier survival model
km_fit <- survfit(surv_object ~ 1)

# Convert survival fit to data frame for ggplot
km_data <- data.frame(
  time = c(1, km_fit$time),  # Start at 1
  surv = c(1, km_fit$surv),  # Survival starts at 1
  upper = c(1, km_fit$upper),
  lower = c(1, km_fit$lower)
)

# Plot the Kaplan-Meier curve using ggplot2
ggplot(km_data, aes(x = time, y = surv)) +
  geom_step(color = "#2C3E50", size = 1.2) +  # Darker blue, thicker line
  geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.15, fill = "#3498DB") +  # Subtle CI shading
  labs(
    title = "Likelihood of Avoiding Swings Outside the Strike Zone Over Plate Appearances",
    subtitle = "Kaplan-Meier Survival Analysis of MLB Batters",
    x = "Number of Plate Appearances",
    y = "Survival Probability"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(hjust = 0.5, size = 12, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5, size = 12, face = "italic"),
    axis.title.x = element_text(size = 13, face = "bold"),
    axis.title.y = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 11),
    panel.grid.major = element_line(color = "gray90"),
    panel.grid.minor = element_blank()
  ) +
  scale_x_continuous(breaks = seq(1, max(km_data$time), by = 1)) +  # X-axis increments of 1
  scale_y_continuous(labels = percent_format(accuracy = 1))  # Show percentages on Y-axis

# Create a 'count' column to represent the current strike count (balls-strikes)
data[, count := paste0(balls, "-", strikes)]

# One-hot encode the 'count' column
data <- fastDummies::dummy_cols(data, select_columns = "count", remove_first_dummy = TRUE)

# Remove 'count_4-2' column if it exists
if ("count_4-2" %in% colnames(data)) {
  data <- data[, !("count_4-2"), with = FALSE]
}

# Prepare the data for Cox regression
# Select relevant columns including one-hot encoded 'count' columns
count_cols <- grep("^count_", names(data), value = TRUE)
model_data <- data[, c("at_bats", "swung_outside_zone", "bat_speed", "swing_length", "release_speed", count_cols), with = FALSE]

# Remove rows with missing values in the selected columns
model_data <- na.omit(model_data)

# Fit the Cox proportional hazards model
cox_model <- coxph(Surv(at_bats, swung_outside_zone) ~ bat_speed + swing_length + release_speed + ., data = model_data)

# Print the summary of the Cox regression results
summary(cox_model)

# Tidy the model output for plotting
cox_tidy <- broom::tidy(cox_model, exponentiate = TRUE, conf.int = TRUE)

# Filter out intercept if present
cox_tidy <- cox_tidy[!is.na(cox_tidy$estimate), ]

# Create a forest plot for the coefficients
ggplot(cox_tidy, aes(x = term, y = estimate)) +
  geom_point(color = "blue", size = 3) +  # Points for hazard ratios
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.2, color = "darkgray") +  # Error bars for 95% CI
  geom_hline(yintercept = 1, linetype = "dashed", color = "red") +  # Reference line at HR = 1
  coord_flip() +  # Flip axes for better readability
  labs(
    title = "Hazard Ratios from Cox Proportional Hazards Model",
    x = "Variables",
    y = "Hazard Ratio (HR)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 10)
  ) +
  scale_y_continuous(trans = "log10")  # Log scale for hazard ratios


model_data <- data[, c("at_bats", "swung_outside_zone", "bat_speed", "swing_length", "release_speed", "player_name", count_cols), with = FALSE]

# Fit the Cox Proportional Hazards model stratified by player_name
cox_model_strata <- coxph(Surv(at_bats, swung_outside_zone) ~ bat_speed + swing_length + release_speed + 
                            strata(player_name) + ., data = model_data)

# Tidy the model output for plotting
cox_tidy_strata <- broom::tidy(cox_model_strata, exponentiate = TRUE, conf.int = TRUE)

# Sort the coefficients by hazard ratio in ascending order
cox_tidy_strata <- cox_tidy_strata %>%
  arrange(estimate)

# Convert 'term' to a factor for ordered plotting
cox_tidy_strata$term <- factor(cox_tidy_strata$term, levels = cox_tidy_strata$term)

# Filter out any NA estimates
cox_tidy_strata <- cox_tidy_strata[!is.na(cox_tidy_strata$estimate), ]

# Create a forest plot for the stratified model coefficients
ggplot(cox_tidy_strata, aes(x = term, y = estimate)) +
  geom_point(color = "darkgreen", size = 3) +  # Points for hazard ratios
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.2, color = "darkgray") +  # Error bars for 95% CI
  geom_hline(yintercept = 1, linetype = "dashed", color = "red") +  # Reference line at HR = 1
  coord_flip() +  # Flip axes for better readability
  labs(
    title = "Hazard Ratios from Cox Proportional Hazards Model",
    x = "Variables",
    y = "Hazard Ratio (HR)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 10)
  ) +
  scale_y_continuous(trans = "log10")  # Log scale for hazard ratios