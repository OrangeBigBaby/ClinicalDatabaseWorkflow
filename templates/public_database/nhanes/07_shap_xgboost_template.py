"""Template: XGBoost SHAP interpretation for optional ML extension."""

from pathlib import Path
import warnings

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, confusion_matrix, roc_auc_score, roc_curve
from xgboost import XGBClassifier
import shap


warnings.filterwarnings("ignore")

PROJECT_DIR = Path.cwd()
DATA_PATH = PROJECT_DIR / "03_data_processed" / "nhanes_clean.csv"
TABLE_DIR = PROJECT_DIR / "05_results" / "tables"
FIGURE_DIR = PROJECT_DIR / "05_results" / "figures"
MANUSCRIPT_DIR = PROJECT_DIR / "06_manuscript"
for folder in [TABLE_DIR, FIGURE_DIR, MANUSCRIPT_DIR]:
    folder.mkdir(parents=True, exist_ok=True)

RANDOM_STATE = 2026


def save_current_plot(path, width=8, height=6, dpi=300):
    fig = plt.gcf()
    fig.set_size_inches(width, height)
    fig.tight_layout()
    fig.savefig(path, dpi=dpi, bbox_inches="tight")
    plt.close(fig)


def specificity_score(y_true, y_pred):
    tn, fp, fn, tp = confusion_matrix(y_true, y_pred, labels=[0, 1]).ravel()
    return tn / (tn + fp) if (tn + fp) else np.nan


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
            ("num", SimpleImputer(strategy="median"), continuous_features),
            ("cat", Pipeline([("imputer", SimpleImputer(strategy="most_frequent")), ("encoder", encoder)]), categorical_features),
        ],
        remainder="drop",
        verbose_feature_names_out=False,
    )

    X_train_proc = preprocess.fit_transform(X_train)
    X_test_proc = preprocess.transform(X_test)
    feature_names = [str(x).replace("[", "(").replace("]", ")").replace("<", "lt").replace(">", "gt") for x in preprocess.get_feature_names_out()]
    X_train_proc = pd.DataFrame(X_train_proc, columns=feature_names)
    X_test_proc = pd.DataFrame(X_test_proc, columns=feature_names)

    n_negative = int((y_train == 0).sum())
    n_positive = int((y_train == 1).sum())
    scale_pos_weight = n_negative / n_positive if n_positive else 1

    model = XGBClassifier(
        n_estimators=500,
        max_depth=3,
        learning_rate=0.02,
        subsample=0.85,
        colsample_bytree=0.85,
        min_child_weight=5,
        reg_lambda=2.0,
        objective="binary:logistic",
        eval_metric="auc",
        scale_pos_weight=scale_pos_weight,
        random_state=RANDOM_STATE,
        n_jobs=-1,
    )
    model.fit(X_train_proc, y_train)

    prob = model.predict_proba(X_test_proc)[:, 1]
    pred = (prob >= 0.5).astype(int)
    auc = roc_auc_score(y_test, prob)

    pd.DataFrame([{
        "model": "XGBoost",
        "n_train": len(y_train),
        "n_test": len(y_test),
        "events_train": int(y_train.sum()),
        "events_test": int(y_test.sum()),
        "AUC": auc,
        "Accuracy": accuracy_score(y_test, pred),
        "Specificity": specificity_score(y_test, pred),
        "scale_pos_weight": scale_pos_weight,
        "shap_output_unit": "raw log-odds",
    }]).to_csv(TABLE_DIR / "shap_xgboost_model_performance.csv", index=False, encoding="utf-8-sig")

    fpr, tpr, thresholds = roc_curve(y_test, prob)
    pd.DataFrame({"model": "XGBoost", "fpr": fpr, "sensitivity": tpr, "threshold": thresholds}).to_csv(TABLE_DIR / "shap_xgboost_roc_curve_values.csv", index=False, encoding="utf-8-sig")

    explainer = shap.TreeExplainer(model)
    shap_values = explainer(X_test_proc)

    shap_importance = pd.DataFrame({
        "feature": feature_names,
        "mean_abs_shap": np.abs(shap_values.values).mean(axis=0),
        "mean_shap": shap_values.values.mean(axis=0),
    }).sort_values("mean_abs_shap", ascending=False)
    shap_importance.to_csv(TABLE_DIR / "shap_xgboost_feature_importance.csv", index=False, encoding="utf-8-sig")

    shap.plots.bar(shap_values, max_display=20, show=False)
    save_current_plot(FIGURE_DIR / "shap_xgboost_bar.png", width=8, height=7)

    shap.plots.beeswarm(shap_values, max_display=20, show=False)
    save_current_plot(FIGURE_DIR / "shap_xgboost_beeswarm.png", width=9, height=7)

    for feature in ["age", "exposure_1", "exposure_2", "sbp", "dbp"]:
        if feature in X_test_proc.columns:
            shap.plots.scatter(shap_values[:, feature], show=False)
            save_current_plot(FIGURE_DIR / f"shap_dependence_{feature}.png", width=7, height=5)

    summary = f"""# SHAP Analysis Summary

An XGBoost classifier was trained with a 70/30 stratified split. The test-set AUC was {auc:.3f}. SHAP values are reported on the raw log-odds scale, so positive values increase predicted risk and negative values decrease predicted risk.

Interpret feature rankings as prediction contributions, not causal effects.
"""
    (MANUSCRIPT_DIR / "shap_summary.md").write_text(summary, encoding="utf-8")


if __name__ == "__main__":
    main()

