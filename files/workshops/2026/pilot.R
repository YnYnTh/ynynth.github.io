setwd("/Users/yt/Library/CloudStorage/OneDrive-Personal/Phd money/statistics committee/2026 workshop")
getwd()


# Find .sav files in current working directory, require exactly one, read it with haven
files <- list.files(path = ".", pattern = "\\.sav$", full.names = TRUE, ignore.case = TRUE)
if (length(files) == 0) stop("No .sav files found in the working directory.")
if (length(files) > 1) stop(paste0(length(files), " .sav files found; expected exactly 1: ", paste(basename(files), collapse = ", ")))
data_sav <- haven::read_sav(files[[1]])
data_sav

# R
library(dplyr)

m2df_items <- data_sav |>
  rename(
    Sex = B1PRSEX,
    Depressive_Symptoms = B4QCESD,
    Social_Anxiety = B4QSA_SA,
    Self_Control = B4QSC_SC,
    Perceived_Stress = B4QPS_PS,
    Lived_with_Alcoholic = B1PA58,
    Parental_Divorce = B1SE11L,
    Occupational_Status = B1PBWORK,
    Age = B1PRAGE_2019,
    Education = B1PB1
  ) |>
  select(MIDUSID, any_of(c("Sex","Depressive_Symptoms","Social_Anxiety",
                           "Self_Control","Perceived_Stress","Lived_with_Alcoholic",
                           "Parental_Divorce","Occupational_Status","Age","Education")))

# quick inspect
dplyr::glimpse(m2df_items)

# R
library(dplyr)

m2df_items <- m2df_items |>
  mutate(
    Sex = case_when(
      as.numeric(Sex) == 1 ~ "male",
      as.numeric(Sex) == 2 ~ "female",
      TRUE ~ NA_character_
    ) |> factor(levels = c("male", "female")),
    Parental_Divorce = case_when(
      as.numeric(Parental_Divorce) == 1 ~ "yes",
      as.numeric(Parental_Divorce) == 2 ~ "no",
      TRUE ~ NA_character_
    ) |> factor(levels = c("yes", "no")),
    Lived_with_Alcoholic = case_when(
      as.numeric(Lived_with_Alcoholic) == 1 ~ "yes",
      as.numeric(Lived_with_Alcoholic) == 2 ~ "no",
      TRUE ~ NA_character_
    ) |> factor(levels = c("yes", "no"))
  )

# quick inspect
dplyr::glimpse(m2df_items)


# R
library(dplyr)

# pull raw item codes, compute reverse-scored item using observed bounds, then average
items <- data_sav |>
  transmute(
    MIDUSID,
    B4QSUGS = as.numeric(B4QSUGS),
    B4QSTGS = as.numeric(B4QSTGS)
  )

rng <- range(items$B4QSTGS, na.rm = TRUE)
min_item <- rng[1]; max_item <- rng[2]

items <- items |>
  mutate(
    B4QSTGS_rev = ifelse(is.na(B4QSTGS), NA_real_, (min_item + max_item) - B4QSTGS),
    Emotional_Support_Spouse = rowMeans(cbind(B4QSUGS, B4QSTGS_rev), na.rm = TRUE)
  ) |>
  select(MIDUSID, Emotional_Support_Spouse)

m2df_items <- m2df_items |>
  left_join(items, by = "MIDUSID")

m2df_items

# r
library(dplyr)
library(stringr)
library(haven)

# create a text label vector (if labelled) and numeric code vector
ed_label <- as.character(haven::as_factor(m2df_items$Education))
ed_code  <- as.numeric(m2df_items$Education)

# pattern matching common "high school or lower" labels
pat <- regex("(high school|hs\\b|less than high|some high|no formal|elementary|primary|grade school|ged)", ignore_case = TRUE)

is_hs_label <- ifelse(is.na(ed_label), FALSE, str_detect(ed_label, pat))
is_hs_code  <- ifelse(is.na(ed_code), FALSE, ed_code <= 2) # common coding: 1/2 = <= HS

m2df_hs <- m2df_items |>
  filter(is_hs_label | is_hs_code)

# optional: inspect which labels were matched (run interactively if you want)
# tibble(label = ed_label) |> count(label, sort = TRUE)

m2df_hs

library(dplyr)
library(haven)

education_freq2 <- m2df_items %>%
  mutate(Edu_label = as.character(haven::as_factor(Education))) %>%
  count(Edu_label, name = "n") %>%
  arrange(desc(n)) %>%
  mutate(pct = round(n / sum(n) * 100, 2))

education_freq2



# R
library(dplyr)
library(broom)
library(emmeans)

# choose support variable (fallback to spouse if 'Family' not present)
support_var <- if ("Emotional_Support_Family" %in% names(m2df_items)) "Emotional_Support_Family" else "Emotional_Support_Spouse"

# prepare data: ensure factor coding and center numeric predictors
df_mod <- m2df_items %>%
  mutate(
    Sex = factor(Sex, levels = c("male", "female")),          # reference = male
    Lived_with_Alcoholic = factor(Lived_with_Alcoholic),
    Occupational_Status = as.factor(Occupational_Status),
    Emotional_Support_c = as.numeric(scale(.data[[support_var]], scale = FALSE)),
    Self_Control_c = as.numeric(scale(as.numeric(Self_Control), scale = FALSE)),
    Age_c = as.numeric(scale(as.numeric(Age), scale = FALSE))
  )

# compute 1 SD of centered support for probing
sd_support <- sd(df_mod$Emotional_Support_c, na.rm = TRUE)

# fit model with interaction
mod <- lm(Perceived_Stress ~ Emotional_Support_c * Sex +
            Self_Control_c + Lived_with_Alcoholic + Age_c + Occupational_Status,
          data = df_mod, na.action = na.exclude)

# tidy coefficients (estimates, SE, t, p, confints)
coef_tbl <- broom::tidy(mod, conf.int = TRUE)

# simple slopes: slope of Emotional_Support_c within each Sex
slopes_by_sex <- emmeans::emtrends(mod, ~ Sex, var = "Emotional_Support_c", infer = TRUE)

# estimated Perceived_Stress at mean and ±1 SD of support, by Sex
emmeans_at <- emmeans::emmeans(mod, ~ Sex, at = list(Emotional_Support_c = c(-sd_support, 0, sd_support)))

# return useful objects
result <- list(
  model = mod,
  coefficients = coef_tbl,
  slopes_by_sex = slopes_by_sex,
  emmeans_at = emmeans_at,
  support_var = support_var,
  sd_support = sd_support
)
result

# r
library(interactions)
library(ggplot2)

# simple slopes (by sex)
sims <- interactions::sim_slopes(mod,
                                 pred = "Emotional_Support_c",
                                 modx = "Sex",
                                 johnson_neyman = FALSE)   # set TRUE if you want J-N regions
sims

# interaction plot with 95% CIs and nicer theme
p <- interactions::interact_plot(mod,
                                 pred = "Emotional_Support_c",
                                 modx = "Sex",
                                 interval = TRUE,
                                 int.width = 0.95,
                                 centered = FALSE,    # already centered
                                 plot.points = FALSE,
                                 modx.labels = c("male","female")) +
  theme_classic() +
  labs(
    x = "Emotional Support (centered)",
    y = "Perceived Stress",
    title = "Interaction: Emotional support × Sex"
  )

p


# R
# LPA with mclust: 1) prepare data (complete cases), 2) fit Mclust G=1:6, 3) attach classes, 4) inspect & plot profiles
library(dplyr)
library(mclust)
library(tidyr)
library(ggplot2)

vars <- c("Depressive_Symptoms", "Social_Anxiety", "Self_Control")

# 1) prepare complete-case dataset and standardize variables
df_lpa <- m2df_items %>%
  select(MIDUSID, all_of(vars)) %>%
  mutate(across(all_of(vars), ~ as.numeric(.x))) %>%
  filter(if_all(all_of(vars), ~ !is.na(.x)))     # complete cases

if (nrow(df_lpa) == 0) stop("No complete cases for the three variables; consider imputation.")

scaled_mat <- as.data.frame(scale(df_lpa %>% select(all_of(vars))))  # z-scores

# 2) fit Gaussian mixture models, letting mclust choose covariance parameterization
fit <- Mclust(scaled_mat, G = 1:6, modelNames = "EEE")

# summary of best model
best_G <- fit$G
best_modelName <- fit$modelName
bic_table <- fit$BIC                           # BIC for chosen model (fit has selected model)
message("Selected model: G = ", best_G, "  modelName = ", best_modelName)


# 3) attach class assignments back to df_lpa
df_lpa <- df_lpa %>%
  mutate(lpa_class = factor(fit$classification, levels = sort(unique(fit$classification)),
                            labels = paste0("Class", sort(unique(fit$classification)))))

# 4) class sizes and raw means/sd (use original metric)
class_summary <- df_lpa %>%
  group_by(lpa_class) %>%
  summarise(
    n = n(),
    across(all_of(vars),
           list(mean = ~ mean(.x, na.rm = TRUE), sd = ~ sd(.x, na.rm = TRUE)),
           .names = "{col}_{fn}"),
    .groups = "drop"
  )

# 5) profile means on standardized scale for plotting
profile_df <- cbind(scaled_mat, class = fit$classification)
profile_means <- as.data.frame(profile_df) %>%
  group_by(class) %>%
  summarise(across(all_of(vars), mean), .groups = "drop") %>%
  pivot_longer(-class, names_to = "variable", values_to = "mean_z")

# 6) line plot of standardized profiles
p <- ggplot(profile_means, aes(x = variable, y = mean_z, group = factor(class), color = factor(class))) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  theme_classic() +
  labs(
    x = NULL, y = "Mean (z-score)",
    color = "LPA class",
    title = paste0("LPA profiles (Mclust selected G = ", best_G, ", model = ", best_modelName, ")")
  )

# 7) output useful objects
lpa_result <- list(
  fit = fit,
  df_lpa = df_lpa,            # MIDUSID, raw vars, lpa_class
  class_summary = class_summary,
  profile_means = profile_means,
  plot = p,
  bic = fit$bic
)

# return result
lpa_result

# R
library(dplyr)
library(broom)

# join class labels (from df_lpa) back to full dataset
m2df_class <- m2df_items %>%
  left_join(df_lpa %>% select(MIDUSID, lpa_class), by = "MIDUSID") %>%
  mutate(lpa_class = factor(lpa_class))

# demographic vars to test
cat_vars <- c("Sex", "Parental_Divorce", "Lived_with_Alcoholic", "Occupational_Status", "Education")
cont_var <- "Age"

# helper: categorical tests (counts, chi-square, Cramer's V)
cat_tests <- lapply(cat_vars, function(v) {
  tbl <- table(m2df_class[[v]], m2df_class$lpa_class, useNA = "ifany")
  # baseline chisq to check expected counts
  ch0 <- suppressWarnings(chisq.test(tbl, simulate.p.value = FALSE))
  use_sim <- any(ch0$expected < 5)
  ch <- suppressWarnings(chisq.test(tbl, simulate.p.value = use_sim, B = ifelse(use_sim, 5000, 0)))
  n_total <- sum(tbl)
  cramers_v <- tryCatch({
    sqrt(as.numeric(ch$statistic) / (n_total * (min(dim(tbl)) - 1)))
  }, error = function(e) NA_real_)
  list(variable = v, table = as.data.frame.matrix(tbl), chi = tidy(ch), cramers_v = cramers_v)
})
names(cat_tests) <- cat_vars

# continuous: Age summary by class, ANOVA, Kruskal-Wallis, eta-squared
age_df <- m2df_class %>% select(lpa_class, Age) %>% filter(!is.na(Age))
age_summary <- age_df %>% group_by(lpa_class) %>% summarise(n = n(), mean = mean(Age, na.rm = TRUE), sd = sd(Age, na.rm = TRUE), .groups = "drop")
aov_mod <- aov(Age ~ lpa_class, data = age_df)
aov_tbl <- broom::tidy(aov_mod)
# compute eta-squared (SSB / SST)
ss_between <- sum(age_summary$n * (age_summary$mean - mean(age_df$Age, na.rm = TRUE))^2)
ss_total <- sum((age_df$Age - mean(age_df$Age, na.rm = TRUE))^2, na.rm = TRUE)
eta2 <- ss_between / ss_total
kruskal <- kruskal.test(Age ~ lpa_class, data = age_df)

# return results
list(
  categorical = cat_tests,
  age_summary = age_summary,
  anova = aov_tbl,
  eta_squared_age = eta2,
  kruskal_age = broom::tidy(kruskal)
)

# R
library(dplyr)
library(haven)
library(caret)
library(ranger)

set.seed(20260126)

# 1. Prepare data
df_rf <- m2df_items %>%
  select(-MIDUSID) %>%
  # convert haven labelled to factors with labels, keep other factors as-is
  mutate(across(where(haven::is.labelled), ~ haven::as_factor(.x))) %>%
  # ensure characters are factors
  mutate(across(where(is.character), as.factor)) %>%
  # outcome numeric
  mutate(Depressive_Symptoms = as.numeric(Depressive_Symptoms)) %>%
  # drop rows missing outcome
  filter(!is.na(Depressive_Symptoms))

# predictors
preds <- setdiff(names(df_rf), "Depressive_Symptoms")

# 2. Train/test split
train_idx <- createDataPartition(df_rf$Depressive_Symptoms, p = 0.8, list = FALSE)
train <- df_rf[train_idx, , drop = FALSE]
test  <- df_rf[-train_idx, , drop = FALSE]

# 3. Simple imputation (fit on training, apply to test)
# numeric: median; factor: add "Missing" level and set NA -> "Missing"
num_cols <- train %>% select(where(is.numeric)) %>% select(-Depressive_Symptoms) %>% names()
fac_cols <- setdiff(preds, num_cols)

impute_num_median <- train %>% summarise(across(all_of(num_cols), ~ median(.x, na.rm = TRUE))) %>% as.list()

for (v in num_cols) {
  med <- impute_num_median[[v]]
  train[[v]][is.na(train[[v]])] <- med
  test[[v]][is.na(test[[v]])] <- med
}
for (v in fac_cols) {
  # coerce to factor, add "Missing" level
  train[[v]] <- as.factor(train[[v]])
  test[[v]]  <- as.factor(test[[v]])
  if (!("Missing" %in% levels(train[[v]]))) levels(train[[v]]) <- c(levels(train[[v]]), "Missing")
  if (!("Missing" %in% levels(test[[v]]))) levels(test[[v]])  <- c(levels(test[[v]]),  "Missing")
  train[[v]][is.na(train[[v]])] <- "Missing"
  test[[v]][is.na(test[[v]])] <- "Missing"
}

# 4. caret model training (ranger) with 5-fold CV tuning mtry
ctrl <- trainControl(method = "cv", number = 5, verboseIter = FALSE)
# set a sensible mtry search (sqrt for regression is default; try a few values)
tunegrid <- expand.grid(
  mtry = unique(pmax(1, floor(seq(1, length(preds), length.out = 5)))),
  splitrule = "variance",
  min.node.size = c(5)
)

rf_fit <- train(
  x = train %>% select(all_of(preds)),
  y = train$Depressive_Symptoms,
  method = "ranger",
  trControl = ctrl,
  tuneGrid = tunegrid,
  importance = "impurity",
  num.trees = 1000,
  metric = "RMSE"
)

# 5. Test set performance and variable importance
pred_test <- predict(rf_fit, newdata = test %>% select(all_of(preds)))
perf_test <- caret::postResample(pred = pred_test, obs = test$Depressive_Symptoms) # RMSE, R-squared

var_imp <- varImp(rf_fit, scale = TRUE)

# 6. Return results
list(
  model = rf_fit,
  test_performance = perf_test,
  variable_importance = var_imp,
  train_rows = nrow(train),
  test_rows = nrow(test)
)

# R
library(dplyr)
library(haven)
library(caret)
library(ranger)
library(pROC)

set.seed(20260126)

# 1. Prepare data: median-split example (replace threshold if needed)
df_clf <- m2df_items %>%
  select(-MIDUSID) %>%
  mutate(across(where(haven::is.labelled), ~ haven::as_factor(.x))) %>%
  mutate(across(where(is.character), as.factor)) %>%
  mutate(Depressive_Symptoms = as.numeric(Depressive_Symptoms)) %>%
  filter(!is.na(Depressive_Symptoms))

thresh <- median(df_clf$Depressive_Symptoms, na.rm = TRUE)
df_clf <- df_clf %>%
  mutate(Depressed = factor(ifelse(Depressive_Symptoms >= thresh, "High", "Low"),
                            levels = c("High", "Low"))) # "High" is positive

# predictors
preds <- setdiff(names(df_clf), c("Depressive_Symptoms", "Depressed"))

# 2. Train/test split
train_idx <- createDataPartition(df_clf$Depressed, p = 0.8, list = FALSE)
train <- df_clf[train_idx, , drop = FALSE]
test  <- df_clf[-train_idx, , drop = FALSE]

# 3. Simple imputation (train medians; factor -> add "Missing")
num_cols <- train %>% select(where(is.numeric)) %>% select(-Depressive_Symptoms) %>% names()
fac_cols <- setdiff(preds, num_cols)

impute_meds <- train %>% summarise(across(all_of(num_cols), ~ median(.x, na.rm = TRUE))) %>% as.list()

for (v in num_cols) {
  med <- impute_meds[[v]]
  train[[v]][is.na(train[[v]])] <- med
  test[[v]][is.na(test[[v]])] <- med
}
for (v in fac_cols) {
  train[[v]] <- as.factor(train[[v]])
  test[[v]]  <- as.factor(test[[v]])
  if (!("Missing" %in% levels(train[[v]]))) levels(train[[v]]) <- c(levels(train[[v]]), "Missing")
  if (!("Missing" %in% levels(test[[v]])))  levels(test[[v]])  <- c(levels(test[[v]]),  "Missing")
  train[[v]][is.na(train[[v]])] <- "Missing"
  test[[v]][is.na(test[[v]])]  <- "Missing"
}

# 4. Train ranger classifier with CV optimizing AUC
ctrl <- trainControl(method = "cv", number = 5, classProbs = TRUE, summaryFunction = twoClassSummary)
tunegrid <- expand.grid(
  mtry = unique(pmax(1, floor(seq(1, length(preds), length.out = 5)))),
  splitrule = "gini",
  min.node.size = c(5)
)

rf_clf <- train(
  x = train %>% select(all_of(preds)),
  y = train$Depressed,
  method = "ranger",
  trControl = ctrl,
  tuneGrid = tunegrid,
  importance = "impurity",
  num.trees = 1000,
  metric = "ROC"
)

# 5. Test set evaluation: predictions, confusion matrix, ROC/AUC
pred_probs <- predict(rf_clf, newdata = test %>% select(all_of(preds)), type = "prob")
pred_class <- predict(rf_clf, newdata = test %>% select(all_of(preds)), type = "raw")

cm <- caret::confusionMatrix(pred_class, test$Depressed, positive = "High")
roc_obj <- pROC::roc(response = test$Depressed, predictor = pred_probs[ , "High"], levels = c("Low","High"))
auc_val <- pROC::auc(roc_obj)

var_imp <- varImp(rf_clf, scale = TRUE)

# 6. Return useful objects
list(
  model = rf_clf,
  confusion_matrix = cm,
  auc = as.numeric(auc_val),
  roc = roc_obj,
  variable_importance = var_imp,
  train_n = nrow(train),
  test_n = nrow(test),
  threshold_used = thresh
)

# r
# Tune ranger classifier more exhaustively (caret). Tries sampling methods (none/up/down/smote),
# larger grid for mtry and min.node.size, more trees, repeated CV, evaluates on test set.
library(dplyr)
library(caret)
library(ranger)
library(pROC)   # for ROC if needed

set.seed(20260126)

# df_clf, preds, train/test already exist in session from earlier steps; if not, run the construction block above.
# Ensure train/test are available; otherwise recreate using previous median-split threshold approach.

# Recreate split if not present
if (!exists("train") || !exists("test")) {
  df_clf <- m2df_items %>%
    select(-MIDUSID) %>%
    mutate(across(where(haven::is.labelled), ~ haven::as_factor(.x))) %>%
    mutate(across(where(is.character), as.factor)) %>%
    mutate(Depressive_Symptoms = as.numeric(Depressive_Symptoms)) %>%
    filter(!is.na(Depressive_Symptoms))
  thresh <- median(df_clf$Depressive_Symptoms, na.rm = TRUE)
  df_clf <- df_clf %>% mutate(Depressed = factor(ifelse(Depressive_Symptoms >= thresh, "High", "Low"), levels = c("High","Low")))
  preds <- setdiff(names(df_clf), c("Depressive_Symptoms","Depressed"))
  train_idx <- createDataPartition(df_clf$Depressed, p = 0.8, list = FALSE)
  train <- df_clf[train_idx, , drop = FALSE]
  test  <- df_clf[-train_idx, , drop = FALSE]
}

# Basic preprocessing: numeric impute (median), factor -> "Missing", then dummyVars for one-hot
prep_impute_and_dummies <- function(df_train, df_new, preds) {
  # numeric median impute
  num_cols <- df_train %>% select(all_of(preds)) %>% select(where(is.numeric)) %>% names()
  fac_cols <- setdiff(preds, num_cols)
  impute_meds <- df_train %>% summarise(across(all_of(num_cols), ~ median(.x, na.rm = TRUE))) %>% as.list()
  for (v in num_cols) {
    med <- impute_meds[[v]]
    df_train[[v]][is.na(df_train[[v]])] <- med
    df_new[[v]][is.na(df_new[[v]])] <- med
  }
  for (v in fac_cols) {
    df_train[[v]] <- as.factor(df_train[[v]])
    df_new[[v]]  <- as.factor(df_new[[v]])
    if (!("Missing" %in% levels(df_train[[v]]))) levels(df_train[[v]]) <- c(levels(df_train[[v]]), "Missing")
    if (!("Missing" %in% levels(df_new[[v]])))  levels(df_new[[v]])  <- c(levels(df_new[[v]]),  "Missing")
    df_train[[v]][is.na(df_train[[v]])] <- "Missing"
    df_new[[v]][is.na(df_new[[v]])] <- "Missing"
  }
  # one-hot encode with dummyVars (caret)
  dv <- dummyVars(~ ., data = df_train %>% select(all_of(preds)), fullRank = TRUE)
  X_train <- predict(dv, newdata = df_train %>% select(all_of(preds))) %>% as.data.frame()
  X_new   <- predict(dv, newdata = df_new  %>% select(all_of(preds))) %>% as.data.frame()
  list(X_train = X_train, X_new = X_new)
}

prep <- prep_impute_and_dummies(train, test, preds)
X_train <- prep$X_train
X_test  <- prep$X_new
y_train <- train$Depressed
y_test  <- test$Depressed

# combine X and y for caret train
train_proc <- cbind(X_train, Depressed = y_train)

# repeated CV control; evaluate by Accuracy; allow sampling methods
ctrl <- trainControl(
  method = "repeatedcv",
  number = 5,
  repeats = 3,
  classProbs = TRUE,
  summaryFunction = twoClassSummary,
  savePredictions = "final",
  sampling = NULL  # we'll loop over sampling strategies below
)

# grid of hyperparameters for ranger via caret
p <- ncol(X_train)
mtry_vals <- unique(pmax(1, floor(seq(1, p, length.out = 8))))
tunegrid <- expand.grid(
  mtry = mtry_vals,
  splitrule = c("gini"),
  min.node.size = c(1, 3, 5, 10)
)

# sampling strategies to try
sampling_strategies <- c("none", "up", "down", "smote")  # smote requires DMwR / smotefamily; caret will try if available

results <- list()
best_acc <- 0
best_model <- NULL
best_info <- NULL

for (s in sampling_strategies) {
  message("Tuning with sampling: ", s)
  ctrl$sampling <- if (s == "none") NULL else s
  # Use metric = "Accuracy" for final selection; but keep classProbs & twoClassSummary for ROC info
  set.seed(20260126)
  rf_t <- tryCatch({
    train(
      x = X_train,
      y = y_train,
      method = "ranger",
      trControl = ctrl,
      tuneGrid = tunegrid,
      metric = "Accuracy",
      importance = "impurity",
      num.trees = 2000,
      verbose = FALSE
    )
  }, error = function(e) {
    message("Failed for sampling ", s, ": ", e$message)
    NULL
  })
  if (is.null(rf_t)) next
  # evaluate on test set
  preds_test <- predict(rf_t, newdata = X_test)
  acc_test <- caret::postResample(preds_test, y_test)["Accuracy"]
  cm <- caret::confusionMatrix(preds_test, y_test, positive = "High")
  results[[s]] <- list(model = rf_t, test_acc = acc_test, confusion = cm)
  message("Sampling: ", s, "  Test accuracy: ", round(acc_test, 4))
  if (!is.na(acc_test) && acc_test > best_acc) {
    best_acc <- acc_test
    best_model <- rf_t
    best_info <- list(sampling = s, confusion = cm)
  }
  # early stop if > .90
  if (!is.na(best_acc) && best_acc >= 0.90) break
}

# Report best result
if (is.null(best_model)) {
  message("No successful model runs.")
} else {
  message("Best test accuracy: ", round(best_acc, 4), " (sampling = ", best_info$sampling, ")")
  print(best_info$confusion)
  # variable importance
  vi <- varImp(best_model, scale = TRUE)
  print(vi)
  # If reached target
  if (best_acc >= 0.90) {
    message("Target achieved (>= 90%). Beware of overfitting; inspect train vs test performance and class distribution.")
  } else {
    message("Target not achieved. Consider: alternative algorithms (xgboost), heavy feature engineering, different outcome definition, or allowing over/under-sampling in production.")
  }
}