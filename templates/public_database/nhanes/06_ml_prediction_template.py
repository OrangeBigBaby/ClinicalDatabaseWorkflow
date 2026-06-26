"""Template: optional machine-learning prediction module for public database analysis."""

from pathlib import Path
import warnings

import numpy as np
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.pipeline import Pipeline
from sklearn.model_selection import train_test_split
from sklearn.metrics import (
    accuracy_score,
    brier_score_loss,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
    roc_curve,
)
from sklearn.calibration import calibration_curve
from sklearn.inspection import permutation_importance
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier, ExtraTreesClassifier
from sklearn.tree import DecisionTreeClassifier
from sklearn.svm import SVC


warnings.filterwarnings("ignore")

PROJECT_DIR = Path.cwd()
DATA_PATH = PROJECT_DIR / "03_data_processed" / "nhanes_clean.csv"
TABLE_DIR = PROJECT_DIR / "05_results" / "tables"
FIGURE_DIR = PROJECT_DIR / "05_results" / "figures"
TABLE_DIR.mkdir(parents=True, exist_ok=True)
FIGURE_DIR.mkdir(parents=True, exist_ok=True)

RANDOM_STATE = 2026


def specificity_score(y_true, y_pred):
    tn, fp, fn, tp = confusion_matrix(y_true, y_pred, labels=[0, 1]).ravel()
    return tn / (tn + fp) if (tn + fp) else np.nan


def npv_score(y_true, y_pred):
    tn, fp, fn, tp = confusion_matrix(y_true, y_pred, labels=[0, 1]).ravel()
    return tn / (tn + fn) if (tn + fn) else np.nan


def model_metrics(name, y_true, prob, threshold=0.5):
    pred = (prob >= threshold).astype(int)
    tn, fp, fn, tp = confusion_matrix(y_true, pred, labels=[0, 1]).ravel()
    return {
        "model": name,
        "AUC": roc_auc_score(y_true, prob),
        "Accuracy": accuracy_score(y_true, pred),
        "Sensitivity": recall_score(y_true, pred, zero_division=0),
        "Specificity": specificity_score(y_true, pred),
        "FPR": fp / (fp + tn) if (fp + tn) else np.nan,
        "FNR": fn / (fn + tp) if (fn + tp) else np.nan,
        "PPV": precision_score(y_true, pred, zero_division=0),
        "NPV": npv_score(y_true, pred),
        "F1_Score": f1_score(y_true, pred, zero_division=0),
        "Brier": brier_score_loss(y_true, prob),
    }


def decision_curve(y_true, prob, thresholds):
    y_true = np.asarray(y_true)
    n = len(y_true)
    prevalence = y_true.mean()
    rows = []
    for pt in thresholds:
        pred = prob >= pt
        tp = np.sum(pred & (y_true == 1))
        fp = np.sum(pred & (y_true == 0))
        rows.append({
            "threshold": pt,
            "net_benefit_model": (tp / n) - (fp / n) * (pt / (1 - pt)),
            "net_benefit_all": prevalence - (1 - prevalence) * (pt / (1 - pt)),
            "net_benefit_none": 0.0,
        })
    return pd.DataFrame(rows)


def main():
    df = pd.read_csv(DATA_PATH)

    continuous_features = [
        "exposure_1", "exposure_2", "age", "bmi", "waist_cm", "sbp", "dbp",
        "glucose_mg_dl", "triglyceride_mg_dl", "hdl_mg_dl",
    ]
    categorical_features = [
        "sex", "race", "education", "pir_group", "smoking", "alcohol",
        "hypertension", "diabetes",
    ]

    X = df[continuous_features + categorical_features].copy()
    y = df["outcome"].astype(int).to_numpy()

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.30, random_state=RANDOM_STATE, stratify=y
    )

    try:
        encoder = OneHotEncoder(handle_unknown="ignore", sparse_output=False)
    except TypeError:
        encoder = OneHotEncoder(handle_unknown="ignore", sparse=False)

    preprocess = ColumnTransformer(
        transformers=[
            ("num", Pipeline([("imputer", SimpleImputer(strategy="median")), ("scaler", StandardScaler())]), continuous_features),
            ("cat", Pipeline([("imputer", SimpleImputer(strategy="most_frequent")), ("encoder", encoder)]), categorical_features),
        ],
        remainder="drop",
        verbose_feature_names_out=False,
    )

    X_train_proc = preprocess.fit_transform(X_train)
    X_test_proc = preprocess.transform(X_test)
    feature_names = preprocess.get_feature_names_out()

    models = {
        "LR": LogisticRegression(max_iter=2000, class_weight="balanced", random_state=RANDOM_STATE),
        "RF": RandomForestClassifier(n_estimators=600, class_weight="balanced_subsample", random_state=RANDOM_STATE, n_jobs=-1, min_samples_leaf=4),
        "SVM": SVC(kernel="rbf", probability=True, class_weight="balanced", random_state=RANDOM_STATE),
        "DT": DecisionTreeClassifier(class_weight="balanced", random_state=RANDOM_STATE, min_samples_leaf=20),
        "GBM": GradientBoostingClassifier(random_state=RANDOM_STATE),
        "ET": ExtraTreesClassifier(n_estimators=600, class_weight="balanced", random_state=RANDOM_STATE, n_jobs=-1, min_samples_leaf=4),
    }

    thresholds = np.linspace(0.01, 0.60, 120)
    metrics, roc_rows, calibration_rows, dca_rows = [], [], [], []
    fitted = {}

    for name, model in models.items():
        model.fit(X_train_proc, y_train)
        fitted[name] = model
        prob = model.predict_proba(X_test_proc)[:, 1]
        metrics.append(model_metrics(name, y_test, prob))

        fpr, tpr, _ = roc_curve(y_test, prob)
        roc_rows.append(pd.DataFrame({"model": name, "fpr": fpr, "sensitivity": tpr}))

        frac_pos, mean_pred = calibration_curve(y_test, prob, n_bins=8, strategy="quantile")
        calibration_rows.append(pd.DataFrame({"model": name, "mean_predicted": mean_pred, "fraction_positive": frac_pos}))

        dca = decision_curve(y_test, prob, thresholds)
        dca["model"] = name
        dca_rows.append(dca)

    perf = pd.DataFrame(metrics).sort_values("AUC", ascending=False)
    perf.to_csv(TABLE_DIR / "ml_model_performance.csv", index=False, encoding="utf-8-sig")
    pd.concat(roc_rows).to_csv(TABLE_DIR / "ml_roc_curve_values.csv", index=False, encoding="utf-8-sig")
    pd.concat(calibration_rows).to_csv(TABLE_DIR / "ml_calibration_curve_values.csv", index=False, encoding="utf-8-sig")
    pd.concat(dca_rows).to_csv(TABLE_DIR / "ml_decision_curve_values.csv", index=False, encoding="utf-8-sig")

    best_name = perf.iloc[0]["model"]
    best_model = fitted[best_name]
    if hasattr(best_model, "feature_importances_"):
        importance_values = best_model.feature_importances_
        importance_type = "model_feature_importance"
    else:
        perm = permutation_importance(best_model, X_test_proc, y_test, scoring="roc_auc", n_repeats=20, random_state=RANDOM_STATE, n_jobs=-1)
        importance_values = perm.importances_mean
        importance_type = "permutation_auc_importance"

    pd.DataFrame({
        "feature": feature_names,
        "importance": importance_values,
        "model": best_name,
        "importance_type": importance_type,
    }).sort_values("importance", ascending=False).to_csv(TABLE_DIR / "ml_variable_importance.csv", index=False, encoding="utf-8-sig")


if __name__ == "__main__":
    main()

