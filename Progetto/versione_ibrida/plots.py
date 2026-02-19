# ── Imports ──────────────────────────────────────────────────────────────────
import os
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")                     # backend non-interattivo per salvataggio
import matplotlib.pyplot as plt
import matplotlib.transforms as transforms
import seaborn as sns
from matplotlib.patches import Ellipse
from scipy.io import loadmat
from scipy.stats import chi2
from sklearn.decomposition import PCA
from sklearn.cross_decomposition import PLSRegression
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import (
    accuracy_score,
    balanced_accuracy_score,
    confusion_matrix,
    classification_report,
    recall_score,
    roc_curve,
    auc,
)
from sklearn.model_selection import cross_val_predict, StratifiedKFold, KFold

# ============================================================================
#                        FUNZIONI  DI  UTILITÀ
# ============================================================================

def calculate_vip(model, X, y):
    """
    Variable Importance in Projection (VIP) per PLS-DA.

    Formula:  VIP_j = sqrt( p  ·  Σ_a(SS_a · w_ja²)  /  Σ_a(SS_a) )

    dove  SS_a = ||t_a||² · ||q_a||²  (varianza Y spiegata dalla comp. a)
          w_ja  = peso normalizzato della variabile j sulla componente a
    """
    T = model.x_scores_           # (n, A)
    W = model.x_weights_          # (p, A)
    Q = model.y_loadings_         # (K, A)   K = n_targets

    p = X.shape[1]
    A = T.shape[1]

    SS = np.array([np.sum(T[:, a] ** 2) * np.sum(Q[:, a] ** 2) for a in range(A)])
    SS_total = SS.sum()

    W_norm = W / np.linalg.norm(W, axis=0)          # normalizzazione colonne

    vip = np.sqrt(p * np.dot(W_norm ** 2, SS) / SS_total)
    return vip


def calculate_selectivity_ratio(model, X):
    """
    Selectivity Ratio (SR) per ogni variabile.

    SR_j  =  var(x̂_j) / var(e_j)

    dove  x̂ = T · P'  (ricostruzione del modello)  e  e = X − x̂.
    """
    T = model.x_scores_
    P = model.x_loadings_

    X_hat = T @ P.T
    var_explained = np.var(X_hat, axis=0)

    residuals = X - X_hat
    var_residual = np.var(residuals, axis=0)
    var_residual = np.maximum(var_residual, 1e-10)      # evita div/0

    return var_explained / var_residual


def compute_optimal_threshold(y_true, y_pred_cont):
    """
    Calcola la soglia ottimale tramite curva ROC (Youden's J statistic).

    Parametri
    ---------
    y_true : array-like
        Classi reali (1 = Non Biodeg, 2 = Biodeg).
    y_pred_cont : array-like
        Predizioni continue della colonna Biodeg (indice 1 del dummy).

    Restituisce
    -----------
    threshold_opt, fpr, tpr, thresholds, roc_auc
    """
    y_binary = (y_true == 2).astype(int)       # Biodeg = positivo
    fpr, tpr, thresholds = roc_curve(y_binary, y_pred_cont)
    roc_auc = auc(fpr, tpr)

    J = tpr - fpr                               # Youden's J per ogni soglia
    best_idx = np.argmax(J)
    threshold_opt = thresholds[best_idx]

    return threshold_opt, fpr, tpr, thresholds, roc_auc


def plot_roc_curve(fpr, tpr, thresholds, roc_auc, threshold_mark,
                   filename="ROC_curve.png", set_name="Training CV",
                   y_true=None, y_pred_cont=None):
    """
    Grafico della curva ROC con AUC e soglia ottimale evidenziata.

    Se vengono forniti y_true e y_pred_cont, viene aggiunto a destra un
    pannello "Predicted Responses Plot" con i valori predetti per campione.

    threshold_mark è la soglia da evidenziare sul grafico (può essere
    calcolata su un set diverso, es. CV, e riportata sul test).
    """
    has_ypred = y_true is not None and y_pred_cont is not None

    if has_ypred:
        fig, (ax, ax2) = plt.subplots(1, 2, figsize=(22, 9),
                                       gridspec_kw={"width_ratios": [1, 1.15]})
    else:
        fig, ax = plt.subplots(figsize=(12, 9))

    # ── Pannello sinistro: curva ROC ─────────────────────────────────────
    ax.plot(fpr, tpr, color="#3C60FF", lw=2, label=f"ROC (AUC = {roc_auc:.4f})")
    ax.plot([0, 1], [0, 1], color="gray", ls="--", lw=1, label="Random Classifier")

    # Punto sulla curva più vicino alla soglia indicata
    idx = np.argmin(np.abs(thresholds - threshold_mark))
    ax.scatter(fpr[idx], tpr[idx], c="#E74C3C", s=120, zorder=5,
               edgecolors="k", linewidths=0.8,
               label=f"Soglia ROC = {threshold_mark:.4f}")

    J_at_point = tpr[idx] - fpr[idx]
    ax.annotate(
        f"  FPR = {fpr[idx]:.3f}, TPR = {tpr[idx]:.3f}\n  J = {J_at_point:.4f}",
        xy=(fpr[idx], tpr[idx]),
        xytext=(fpr[idx] + 0.12, tpr[idx] - 0.12),
        fontsize=10, color="#E74C3C",
        arrowprops=dict(arrowstyle="->", color="#E74C3C", lw=1.2),
    )

    ax.set_xlabel("False Positive Rate (1 - Specificità)")
    ax.set_ylabel("True Positive Rate (Sensibilità)")
    ax.set_title(f"Curva ROC - {set_name}\n", fontsize=14, fontweight="bold")
    ax.text(0.5, -0.1,
            f"AUC = {roc_auc:.4f} | Soglia (Youden's J) = {threshold_mark:.4f}",
            fontsize=12, ha="center", transform=ax.transAxes,
            fontstyle="italic", color="#555555")
    ax.legend(loc="lower right", fontsize=9, framealpha=0.9)
    ax.grid(True, ls=":", alpha=0.4)
    ax.set_xlim([-0.02, 1.02])
    ax.set_ylim([-0.02, 1.02])

    # ── Pannello destro: Predicted Responses ────────────────────────────
    #    Sensitivity e Specificity in funzione della soglia (Y predicted)
    if has_ypred:
        y_true_arr = np.asarray(y_true).ravel()
        y_cont = np.asarray(y_pred_cont).ravel()

        y_binary = (y_true_arr == 2).astype(int)   # Biodeg = positivo

        # Calcola Sensitivity e Specificity per un range di soglie
        thr_range = np.linspace(y_cont.min() - 0.05, y_cont.max() + 0.05, 500)
        sens_arr = np.empty_like(thr_range)
        spec_arr = np.empty_like(thr_range)

        for i, t in enumerate(thr_range):
            y_cls = (y_cont >= t).astype(int)
            tp = np.sum((y_cls == 1) & (y_binary == 1))
            fn = np.sum((y_cls == 0) & (y_binary == 1))
            tn = np.sum((y_cls == 0) & (y_binary == 0))
            fp = np.sum((y_cls == 1) & (y_binary == 0))
            sens_arr[i] = tp / max(tp + fn, 1)
            spec_arr[i] = tn / max(tn + fp, 1)

        ax2.plot(thr_range, sens_arr, color="#3C60FF", lw=2, label="Sensitivity (Biodeg)")
        ax2.plot(thr_range, spec_arr, color="#FF6565", lw=2, label="Specificity (Non Biodeg)")

        # Soglia ottimale come linea verticale tratteggiata rossa
        ax2.axvline(threshold_mark, color="#FF1900", ls="--", lw=1, label=f"Soglia = {threshold_mark:.4f}")

        # Intersezione approssimata
        diff = np.abs(sens_arr - spec_arr)
        cross_idx = np.argmin(diff)
        ax2.scatter(thr_range[cross_idx], sens_arr[cross_idx], c="#FF1900", s=80, zorder=5, edgecolors="k", linewidths=0.8)

        ax2.set_xlabel("Threshold (Y predicted)")
        ax2.set_ylabel("Sensitivity / Specificity")
        ax2.set_title(f"Predicted Responses - {set_name}\n", fontsize=14, fontweight="bold")
        ax2.set_ylim([-0.05, 1.05])
        ax2.legend(loc="best", fontsize=9, framealpha=0.9)
        ax2.grid(True, ls=":", alpha=0.4)

    plt.tight_layout()
    plt.savefig(filename, dpi=300, bbox_inches="tight")
    plt.close()
    print(f"  ✓ Salvato: {filename}")


# ── Grafici PCA ──────────────────────────────────────────────────────────────
def plot_pca_scores(scores, labels, explained_var, filename="PCA_scores.png"):
    fig, ax = plt.subplots(figsize=(12, 9))

    colors  = {1: "#FF6565", 2: "#3C60FF"}
    names   = {1: "Non Biodegradabile (Classe 1)",
               2: "Biodegradabile (Classe 2)"}

    for lab in sorted(np.unique(labels)):
        mask = labels == lab
        ax.scatter(
            scores[mask, 0], scores[mask, 1],
            c=colors[lab], marker="o",
            edgecolors="k", linewidths=0.4, label=names[lab],
        )

    ax.axhline(0, color="gray", ls="--", lw=0.8, alpha=0.6)
    ax.axvline(0, color="gray", ls="--", lw=0.8, alpha=0.6)
    ax.set_xlabel(f"PC1 ({explained_var[0]:.2f}% varianza)")
    ax.set_ylabel(f"PC2 ({explained_var[1]:.2f}% varianza)")
    ax.set_title("PCA Score Plot - Training Set", fontsize=14, fontweight="bold")
    ax.legend(loc="best", framealpha=0.9, fontsize=9)
    ax.grid(True, ls=":", alpha=0.4)
    plt.tight_layout()
    plt.savefig(filename, dpi=300, bbox_inches="tight")
    plt.close()
    print(f"  ✓ Salvato: {filename}")

def plot_pca_loadings(loadings, descriptors, explained_var, filename="PCA_loadings.png"):
    fig, ax = plt.subplots(figsize=(12, 9))

    # Frecce dall'origine a ciascun loading
    for i, desc in enumerate(descriptors):
        x, y = loadings[i, 0], loadings[i, 1]
        ax.annotate(
            "",
            xy=(x, y), xytext=(0, 0),
            arrowprops=dict(arrowstyle="->", color="#2C3E50", lw=1.8, alpha=0.8),
        )

        ax.text(x, y, desc, fontsize=9, fontweight="bold", color="#2500AD")

    ax.axhline(0, color="gray", ls="--", lw=0.8, alpha=0.6)
    ax.axvline(0, color="gray", ls="--", lw=0.8, alpha=0.6)
    ax.set_xlabel(f"Loading PC1 ({explained_var[0]:.2f}%)")
    ax.set_ylabel(f"Loading PC2 ({explained_var[1]:.2f}%)")
    ax.set_title("PCA Loading Plot - Training Set", fontsize=14, fontweight="bold")
    ax.set_xlim(-0.6, 0.6)
    ax.set_ylim(-0.6, 0.6)
    ax.set_aspect("equal", adjustable="datalim")
    ax.grid(True, ls=":", alpha=0.4)
    plt.tight_layout()
    plt.savefig(filename, dpi=300, bbox_inches="tight")
    plt.close()
    print(f"  ✓ Salvato: {filename}")

def plot_biplot(scores, loadings, labels, descriptors, explained_var,
                filename="PCA_biplot.png"):
    """
    Biplot PCA: scores (campioni) + loadings (variabili) sovrapposti.
    Gli scores usano l'asse sinistro/basso, i loadings l'asse destro/alto.
    """
    fig, ax_scores = plt.subplots(figsize=(12, 9))

    # ── Scores (asse principale) ──
    colors = {1: "#FF6565", 2: "#3C60FF"}
    names  = {1: "Non Biodegradabile (Classe 1)",
              2: "Biodegradabile (Classe 2)"}
    for lab in sorted(np.unique(labels)):
        mask = labels == lab
        ax_scores.scatter(
            scores[mask, 0], scores[mask, 1],
            c=colors[lab], marker="o", alpha=0.5,
            edgecolors="k", linewidths=0.4, label=names[lab],
        )

    ax_scores.axhline(0, color="gray", ls="--", lw=0.8, alpha=0.5)
    ax_scores.axvline(0, color="gray", ls="--", lw=0.8, alpha=0.5)
    ax_scores.set_xlabel(f"PC1 ({explained_var[0]:.2f}% varianza)")
    ax_scores.set_ylabel(f"PC2 ({explained_var[1]:.2f}% varianza)")
    ax_scores.set_title("PCA Biplot - Training Set", fontsize=14, fontweight="bold")
    ax_scores.legend(loc="lower left", framealpha=0.9, fontsize=9)
    ax_scores.grid(True, ls=":", alpha=0.3)

    # ── Rendi gli assi scores simmetrici attorno a 0 ──
    #     così (0,0) scores coincide visivamente con (0,0) loadings
    sx = max(abs(ax_scores.get_xlim()[0]), abs(ax_scores.get_xlim()[1])) * 1.02
    sy = max(abs(ax_scores.get_ylim()[0]), abs(ax_scores.get_ylim()[1])) * 1.02
    ax_scores.set_xlim(-sx, sx)
    ax_scores.set_ylim(-sy, sy)

    # ── Loadings (secondo asse, scala diversa) ──
    ax_right = ax_scores.twinx()       # asse Y destro (loading PC2)
    ax_load  = ax_right.twiny()        # asse X in alto (loading PC1)

    max_l = np.max(np.abs(loadings[:, :2])) * 1.25

    # Limiti simmetrici per entrambi gli assi loading
    ax_load.set_xlim(-max_l, max_l)
    ax_right.set_ylim(-max_l, max_l)
    ax_load.set_ylim(-max_l, max_l)     # condiviso con ax_right

    # Disegna frecce + etichette sullo spazio loading
    for i, desc in enumerate(descriptors):
        x, y = loadings[i, 0], loadings[i, 1]
        ax_load.annotate(
            "",
            xy=(x, y), xytext=(0, 0),
            arrowprops=dict(arrowstyle="->", color="#2C3E50", lw=1.8, alpha=0.8),
        )
        ax_load.text(x, y, desc, fontsize=9, fontweight="bold", color="#2500AD")

    ax_load.set_xlabel("Loading PC1")
    ax_right.set_ylabel("Loading PC2")   # etichetta sul twinx
    ax_load.tick_params(axis="x", labelsize=8)
    ax_right.tick_params(axis="y", labelsize=8)

    plt.tight_layout()
    plt.savefig(filename, dpi=300, bbox_inches="tight")
    plt.close()
    print(f"  ✓ Salvato: {filename}")


def plot_t2_vs_q(scores, X_scaled, pca_model, labels, confidence=0.95, filename="PCA_T2_vs_Q.png"):
    n, A = scores.shape

    # ── T² di Hotelling ──
    eigenvalues = pca_model.explained_variance_
    T2 = np.sum((scores ** 2) / eigenvalues, axis=1)
    T2_lim = chi2.ppf(confidence, A)

    # ── Q ──
    X_hat = scores @ pca_model.components_
    Q = np.sum((X_scaled - X_hat) ** 2, axis=1)
    Q_lim = np.percentile(Q, confidence * 100)

    # ── Plot ──
    fig, ax = plt.subplots(figsize=(12, 9))

    colors  = {1: "#FF6565", 2: "#3C60FF"}
    markers = {1: "o", 2: "o"}
    names   = {1: "Non Biodegradabile (Classe 1)",
               2: "Biodegradabile (Classe 2)"}

    for lab in sorted(np.unique(labels)):
        mask = labels == lab
        ax.scatter(T2[mask], Q[mask], c=colors[lab], marker=markers[lab], s=50, edgecolors="k", linewidths=0.3, label=names[lab])

    # Soglie
    ax.axvline(T2_lim, color="#FE7D32", ls="--", lw=1, label=f"T² limite")
    ax.axhline(Q_lim, color="#F39C12", ls="--", lw=1, label=f"Q limite")
        
    # Conteggio outlier
    outlier_T2 = T2 > T2_lim
    outlier_Q  = Q > Q_lim
    outlier_both = outlier_T2 & outlier_Q
    n_out_T2 = outlier_T2.sum()
    n_out_Q  = outlier_Q.sum()
    n_out_both = outlier_both.sum()
        
    # Etichette per i campioni oltre entrambe le soglie
    both_idx = np.where(outlier_both)[0]
    for i in both_idx:
        ax.annotate(str(i), (T2[i], Q[i]), fontsize=7, alpha=0.7, xytext=(4, 4), textcoords="offset points")

    ax.set_xlabel("Hotelling T²")
    ax.set_ylabel("Q Distance")
    ax.set_title(f"T² vs Q", fontsize=16, fontweight="bold")
    ax.text(0.5, -0.1, f"Campioni oltre T²: {n_out_T2} | oltre Q: {n_out_Q} | entrambi: {n_out_both}", fontsize=12, ha='center', transform=ax.transAxes, fontstyle="italic", color="#555555")
    ax.legend(loc="best", fontsize=9, framealpha=0.9)
    ax.grid(True, ls=":", alpha=0.4)
    plt.tight_layout()
    plt.savefig(filename, dpi=300, bbox_inches="tight")
    plt.close()
    print(f"  ✓ Salvato: {filename}")
    print(f"    Campioni oltre T²: {n_out_T2},  oltre Q: {n_out_Q},  "
          f"entrambi: {n_out_both}")

    return T2, Q, T2_lim, Q_lim

def plot_contribution(sample_idx, X_scaled, scores, pca_model, descriptors, filename):
    P = pca_model.components_

    # Contributo Q per variabile: e_ij²
    X_hat = scores[sample_idx] @ pca_model.components_
    residuals = X_scaled[sample_idx] - X_hat
    contrib_Q = residuals ** 2

    fig, ax = plt.subplots(figsize=(12, 9))

    x = np.arange(len(descriptors))

    # Q contribution
    ax.bar(x, contrib_Q, color="#3498DB", edgecolor="black", lw=0.4)
    ax.set_title(f"Contributo a Q - Campione {sample_idx}", fontsize=14, fontweight="bold")
    ax.set_ylabel("Contributo a Q")
    ax.set_xticks(x)
    ax.set_xticklabels(descriptors, rotation=45, ha="right")
    ax.set_xlabel("Descrittori")
    ax.grid(axis="y", ls=":", alpha=0.4)

    plt.tight_layout()
    plt.savefig(filename, dpi=300, bbox_inches="tight")
    plt.close()
    print(f"  ✓ Salvato: {filename}")


def plot_scree(explained_var, filename="PCA_scree.png", nComponents=None):
    """Scree plot: varianza spiegata (non cumulativa)."""
    fig, ax = plt.subplots(figsize=(12, 9))
    x = range(1, len(explained_var) + 1)
    ax.plot(x, explained_var, "o-", color="#2C3E50", lw=2, ms=8, label="Varianza spiegata")
    ax.axvline(nComponents, color="#E74C3C", ls="--", lw=1, label="Numero di componenti scelte")
    ax.set_xlabel("Componenti principali")
    ax.set_ylabel("Varianza Spiegata")
    ax.set_xticks(x)
    ax.set_title("PCA Scree Plot", fontsize=14, fontweight="bold")
    ax.legend(loc="best", fontsize=9, framealpha=0.9)
    plt.tight_layout()
    plt.savefig(filename, dpi=300, bbox_inches="tight")
    plt.close()
    print(f"  ✓ Salvato: {filename}")


# ── Grafici PLS-DA ───────────────────────────────────────────────────────────

def compute_cv_scan(X, y_dummy, y_class, max_components=15, cv_folds=10):
    """
    Calcola RMSECV e Balanced Accuracy per LV = 1 … max_components
    tramite 10-Fold CV, per generare il grafico di selezione.
    """
    max_possible = min(max_components, X.shape[1])
    kf = StratifiedKFold(n_splits=cv_folds, shuffle=True, random_state=42)
    splits = list(kf.split(X, y_class))
    results = []

    for n_comp in range(1, max_possible + 1):
        pls = PLSRegression(n_components=n_comp, scale=False)
        y_pred_cv = cross_val_predict(pls, X, y_dummy, cv=splits)

        y_pred_class = np.argmax(y_pred_cv, axis=1) + 1
        bacc = balanced_accuracy_score(y_class, y_pred_class)

        residuals = y_dummy[:, 1] - y_pred_cv[:, 1]
        rmsecv = np.sqrt(np.mean(residuals ** 2))

        results.append({
            "n_components": n_comp,
            "balanced_accuracy": bacc,
            "rmsecv": rmsecv,
        })

    return pd.DataFrame(results)


def plot_cv_optimization(df, filename="CV_optimization.png", chosen_n=None):
    fig, ax1 = plt.subplots(figsize=(12, 9))
    nc = df["n_components"]

    # ── Asse sinistro: Balanced Accuracy ──
    ax1.plot(nc, df["balanced_accuracy"], "o-", color="#27AE60", lw=2, ms=7, label="Balanced Accuracy (CV)")
    ax1.axvline(chosen_n, color="#E74C3C", ls="--", lw=1, label=f"Numero di LV scelto")
    ax1.set_xlabel("Numero Componenti Latenti (LV)")
    ax1.set_ylabel("Balanced Accuracy")
    ax1.set_xticks(nc)
    ax1.grid(True, ls=":", alpha=0.4)

    # ── Asse destro: RMSECV ──
    ax2 = ax1.twinx()
    ax2.plot(nc, df["rmsecv"], "D-", color="#FFBC14", lw=2, ms=7, label="RMSECV")
    ax2.set_ylabel("RMSECV")

    ax1.set_title("PLS-DA - Ottimizzazione del Numero di Componenti Latenti (LV)", fontsize=14, fontweight="bold")
    h1, l1 = ax1.get_legend_handles_labels()
    h2, l2 = ax2.get_legend_handles_labels()
    ax1.legend(h1 + h2, l1 + l2, loc="center right", fontsize=9, framealpha=0.9)

    plt.tight_layout()
    plt.savefig(filename, dpi=300, bbox_inches="tight")
    plt.close()
    print(f"  ✓ Salvato: {filename}")


def plot_rmsecv_comparison(cv_scans, chosen_n=None, filename="RMSECV_comparison.png"):
    """
    Confronto RMSECV vs numero di LV per più modelli (completo, VIP, SR, …).

    Parametri
    ---------
    cv_scans : dict
        {"label": DataFrame con colonne 'n_components' e 'rmsecv'}
    chosen_n : int or None
        Numero di LV scelto (linea verticale).
    """
    palette = ["#3C60FF", "#E74C3C", "#27AE60", "#F39C12", "#8E44AD", "#1ABC9C"]
    markers = ["o", "D", "s", "^", "v", "P"]

    fig, ax = plt.subplots(figsize=(12, 9))

    for i, (label, df) in enumerate(cv_scans.items()):
        color = palette[i % len(palette)]
        marker = markers[i % len(markers)]
        ax.plot(df["n_components"], df["rmsecv"],
                f"{marker}-", color=color, lw=2, ms=7, label=label)

    if chosen_n is not None:
        ax.axvline(chosen_n, color="#555555", ls="--", lw=1, label=f"LV scelto = {chosen_n}")

    ax.set_xlabel("Numero Componenti Latenti (LV)")
    ax.set_ylabel("RMSECV")
    ax.set_title("Confronto RMSECV – Modello Completo vs Variabili Selezionate\n",
                 fontsize=14, fontweight="bold")
    ax.legend(loc="best", fontsize=9, framealpha=0.9)
    ax.grid(True, ls=":", alpha=0.4)

    max_nc = max(df["n_components"].max() for df in cv_scans.values())
    ax.set_xticks(range(1, int(max_nc) + 1))

    plt.tight_layout()
    plt.savefig(filename, dpi=300, bbox_inches="tight")
    plt.close()
    print(f"  ✓ Salvato: {filename}")


def plot_confusion_matrix(y_true, y_pred, title, BAcc, filename):
    cm = confusion_matrix(y_true, y_pred)
    fig, ax = plt.subplots(figsize=(12, 9))
    sns.heatmap(cm, annot=True, fmt="d", cmap="Blues",
                xticklabels=["Non Biodeg", "Biodeg"],
                yticklabels=["Non Biodeg", "Biodeg"],
                annot_kws={"size": 16}, ax=ax)
    ax.set_xlabel("Classe Predetta")
    ax.set_ylabel("Classe Vera")
    ax.text(0.5, -0.1, BAcc, fontsize=12, ha='center', transform=ax.transAxes, fontstyle="italic", color="#555555")
    ax.set_title(title, fontsize=14, fontweight="bold")
    plt.tight_layout()
    plt.savefig(filename, dpi=300, bbox_inches="tight")
    plt.close()
    print(f"  ✓ Salvato: {filename}")

def plot_plsda_scores(model, X, labels, filename="PLSDA_scores.png"):
    """
    Score Plot PLS-DA: LV1 vs LV2.
    I campioni sono colorati in base alla classe reale (class_train).
    """
    T = model.transform(X)  # scores sulle LV

    fig, ax = plt.subplots(figsize=(12, 9))

    colors = {1: "#FF6565", 2: "#3C60FF"}
    names  = {1: "Non Biodegradabile (Classe 1)",
              2: "Biodegradabile (Classe 2)"}

    for lab in sorted(np.unique(labels)):
        mask = labels == lab
        ax.scatter(
            T[mask, 0], T[mask, 1],
            c=colors[lab], marker="o",
            edgecolors="k", linewidths=0.4,
            label=names[lab], 
        )

    ax.axhline(0, color="gray", ls="--", lw=0.8, alpha=0.6)
    ax.axvline(0, color="gray", ls="--", lw=0.8, alpha=0.6)
    ax.set_xlabel("LV1")
    ax.set_ylabel("LV2")
    ax.set_title("PLS-DA - Score Plot (LV1 vs LV2) - Training Set ", fontsize=14, fontweight="bold")
    
    ax.legend(loc="best", framealpha=0.9, fontsize=9)
    ax.grid(True, ls=":", alpha=0.4)
    plt.tight_layout()
    plt.savefig(filename, dpi=300, bbox_inches="tight")
    plt.close()
    print(f"  \u2713 Salvato: {filename}")


def plot_ypred_combined(model, X_train, y_train, X_test, y_test, threshold=0.5, filename="PLSDA_ypred_combined.png"):
    """
    Y Predicted Plot combinato (Training + Test).

    Mostra entrambe le colonne dummy predette come linee continue,
    con scatter per la classe reale e una linea verticale di separazione
    tra Training e Test set.
    """
    # Predizioni continue per entrambi i set
    yp_train = model.predict(X_train)   # (n_train, 2)
    yp_test  = model.predict(X_test)    # (n_test, 2)

    n_tr = len(y_train)
    n_ts = len(y_test)
    n_tot = n_tr + n_ts

    # Concatenazione
    yp_all = np.vstack([yp_train, yp_test])   # (n_tot, 2)
    y_all  = np.concatenate([y_train, y_test])
    x_idx  = np.arange(1, n_tot + 1)

    fig, ax = plt.subplots(figsize=(12, 9))

    # ── Linee Y Predicted (colonna 0 = Non Biodeg, colonna 1 = Biodeg) ──
    ax.plot(x_idx, yp_all[:, 0], "-", color="#FF6565", lw=1.2, label="$\\hat{y}_1$  (Non Biodeg)")
    ax.plot(x_idx, yp_all[:, 1], "-", color="#3C60FF", lw=1.2, label="$\\hat{y}_2$  (Biodeg)")

    # ── Scatter per classe reale ──
    colors_class = {1: "#FF6565", 2: "#3C60FF"}
    markers_class = {1: "o", 2: "o"}
    names_class = {1: "Non Biodeg (reale)", 2: "Biodeg (reale)"}

    for lab in sorted(np.unique(y_all)):
        mask = y_all == lab
        # Piazza il marker sulla curva della propria classe dummy
        col_idx = 0 if lab == 1 else 1
        ax.scatter(x_idx[mask], yp_all[mask, col_idx],
                   c=colors_class[lab], marker=markers_class[lab],
                   s=17, edgecolors="k", linewidths=0.3, zorder=3,
                   label=names_class[lab])

    # ── Separatore Train / Test ──
    ax.axvline(n_tr + 0.5, color="black", ls="-", lw=1.5, label="Train | Test")

    # ── Soglia 0 (crossing point) ──
    ax.axhline(0, color="gray", ls="--", lw=0.8, alpha=0.6)

    # ── Annotazioni set ──
    ax.text(n_tr / 2, ax.get_ylim()[1] * 0.95, f"Training ({n_tr})", ha="center", fontsize=10, color="#2C3E50", fontstyle="italic")
    ax.text(n_tr + n_ts / 2, ax.get_ylim()[1] * 0.95, f"Test ({n_ts})", ha="center", fontsize=10, color="#2C3E50", fontstyle="italic")

    ax.set_xlabel("Campione")
    ax.set_ylabel("$\\hat{y}$  (dummy)")
    ax.set_title("PLS-DA - Y Predicted Plot (Training + Test)\n", fontsize=14, fontweight="bold")

    # Conteggio misclassificati (soglia ROC sulla colonna Biodeg)
    yp_class_all = np.where(yp_all[:, 1] >= threshold, 2, 1)
    mis = (yp_class_all != y_all).sum()
    ax.text(0.5, -0.1, f"Misclassificati: {mis} / {n_tot}", fontsize=12, ha="center", transform=ax.transAxes, fontstyle="italic", color="#555555")

    ax.legend(loc="best", fontsize=8, framealpha=0.9, ncol=2)
    ax.grid(True, ls=":", alpha=0.4)

    plt.tight_layout()
    plt.savefig(filename, dpi=300, bbox_inches="tight")
    plt.close()
    print(f"  \u2713 Salvato: {filename}")


def plot_ypred_vs_actual(model, X, y_true, threshold=0.5, filename="PLSDA_ypred_vs_actual.png"):
    """
    Grafico dei valori predetti (y_pred continuo) vs campioni.

    Usa la colonna Biodeg (indice 1) della predizione dummy:
      - y_pred ≥ threshold → Biodeg,  y_pred < threshold → Non Biodeg.
    La soglia di decisione è determinata dalla curva ROC (Youden's J).

    I campioni sono colorati per classe reale; quelli che cadono
    dal lato sbagliato della soglia sono evidenziati con un bordo rosso.
    """
    y_pred_dummy = model.predict(X)     # (n, 2)
    y_pred_cont  = y_pred_dummy[:, 1]   # colonna Biodeg: 0…1

    n = len(y_true)
    x_idx = np.arange(1, n + 1)

    # Classificazione predetta con soglia ROC
    y_pred_class = np.where(y_pred_cont >= threshold, 2, 1)
    misclass = y_pred_class != y_true

    fig, ax = plt.subplots(figsize=(12, 9))

    colors_true = {1: "#FF6565", 2: "#3C60FF"}
    names_true  = {1: "Non Biodeg (reale)", 2: "Biodeg (reale)"}

    for lab in sorted(np.unique(y_true)):
        mask = (y_true == lab) & ~misclass
        ax.scatter(x_idx[mask], y_pred_cont[mask],
                   c=colors_true[lab], marker="o",
                   edgecolors="k", linewidths=0.4,
                   label=names_true[lab])

    ax.axhline(0, color="gray", ls="--", lw=0.8, alpha=0.6)
    ax.axvline(0, color="gray", ls="--", lw=0.8, alpha=0.6)
    # Misclassificati
    if misclass.any():
        ax.scatter(x_idx[misclass], y_pred_cont[misclass],
                   c=[colors_true[y] for y in y_true[misclass]],
                   marker="X", s=60, edgecolors="red", linewidths=0.4,
                   label=f"Misclassificati")

    ax.axhline(threshold, color="#FF1900", ls="-", lw=1, label=f"Soglia ROC (Youden's J) = {threshold:.4f}")
    ax.set_xlabel("Campione")
    ax.set_ylabel("$\\hat{y}$  (colonna Biodeg)")
    plot_name = "Training Set" if "train" in filename.lower() else "Test Set"
    ax.set_title(f"PLS-DA - Valori Predetti vs Campioni - {plot_name}\n", fontsize=14, fontweight="bold")
    ax.text(0.5, -0.1, f"Misclassificati: {misclass.sum()} / {n}", fontsize=12, ha='center', transform=ax.transAxes, fontstyle="italic", color="#555555")
    ax.legend(loc="best", fontsize=9, framealpha=0.9)
    ax.grid(True, ls=":", alpha=0.4)
    plt.tight_layout()
    plt.savefig(filename, dpi=300, bbox_inches="tight")
    plt.close()
    print(f"  \u2713 Salvato: {filename}")


def plot_ypred_eval(model, X, threshold=0.5, filename="PLSDA_ypred_eval.png"):
    """
    Grafico dei valori predetti (y_pred continuo) vs campioni per Xeval.

    Non essendoci classi reali, i campioni sono colorati per classe PREDETTA
    tramite soglia ROC (Youden's J).
    """
    y_pred_dummy = model.predict(X)     # (n, 2)
    y_pred_cont  = y_pred_dummy[:, 1]   # colonna Biodeg: 0…1

    n = len(y_pred_cont)
    x_idx = np.arange(1, n + 1)

    # Classificazione predetta con soglia ROC
    y_pred_class = np.where(y_pred_cont >= threshold, 2, 1)
    n1 = (y_pred_class == 1).sum()
    n2 = (y_pred_class == 2).sum()

    fig, ax = plt.subplots(figsize=(12, 9))

    colors_pred = {1: "#FF6565", 2: "#3C60FF"}
    names_pred  = {1: f"Non Biodeg",
                   2: f"Biodeg"}

    for lab in [1, 2]:
        mask = y_pred_class == lab
        ax.scatter(x_idx[mask], y_pred_cont[mask],
                   c=colors_pred[lab], marker="o",
                   edgecolors="k", linewidths=0.4,
                   label=names_pred[lab])

    ax.axhline(0, color="gray", ls="--", lw=0.8, alpha=0.6)
    ax.axvline(0, color="gray", ls="--", lw=0.8, alpha=0.6)
    ax.axhline(threshold, color="#FF1900", ls="-", lw=1, label=f"Soglia ROC (Youden's J) = {threshold:.4f}")
    ax.set_xlabel("Campione")
    ax.set_ylabel("$\\hat{y}$  (colonna Biodeg)")
    ax.set_title(f"PLS-DA - Valori Predetti vs Campioni - Xeval Set\n", fontsize=14, fontweight="bold")
    ax.text(0.5, -0.1, f"Non Biodeg: {n1} | Biodeg: {n2} | Totale: {n}", fontsize=12, ha='center', transform=ax.transAxes, fontstyle="italic", color="#555555")
    ax.legend(loc="best", fontsize=9, framealpha=0.9)
    ax.grid(True, ls=":", alpha=0.4)

    plt.tight_layout()
    plt.savefig(filename, dpi=300, bbox_inches="tight")
    plt.close()
    print(f"  ✓ Salvato: {filename}")

def plot_vip_scores(vip, descriptors, filename="VIP_scores.png"):
    """Bar chart dei VIP scores ordinati per importanza."""
    idx = np.argsort(vip)[::-1]
    sorted_vip  = vip[idx]
    sorted_desc = [descriptors[i] for i in idx]
    cols = ["#3C60FF" if v > 1 else "#B8C5FF" for v in sorted_vip]

    fig, ax = plt.subplots(figsize=(12, 9))
    bars = ax.bar(range(len(sorted_vip)), sorted_vip, color=cols, edgecolor="black", lw=0.4)
    ax.axhline(1, color="#FF1900", ls="-", lw=1, label="Soglia VIP")
    ax.set_xticks(range(len(sorted_desc)))
    ax.set_xticklabels(sorted_desc, rotation=45, ha="right")
    ax.set_xlabel("Descrittori Molecolari")
    ax.set_ylabel("VIP Score")
    ax.set_title("PLS-DA - Variable Importance in Projection (VIP)", fontsize=14, fontweight="bold")
    ax.legend(loc="upper right", fontsize=9, framealpha=0.9)
    ax.grid(axis="y", ls=":", alpha=0.4)
    for bar, v in zip(bars, sorted_vip):
        if v > 1:
            ax.text(bar.get_x() + bar.get_width() / 2, v + 0.02,
                    f"{v:.2f}", ha="center", va="bottom",
                    fontsize=8, fontstyle="italic", color="#2C3E50")
    plt.tight_layout()
    plt.savefig(filename, dpi=300, bbox_inches="tight")
    plt.close()
    print(f"  ✓ Salvato: {filename}")


def plot_sr_scores(sr, descriptors, filename="SR_scores.png"):
    """Bar chart dei Selectivity Ratio (SR) ordinati per importanza."""
    idx = np.argsort(sr)[::-1]
    sorted_sr   = sr[idx]
    sorted_desc = [descriptors[i] for i in idx]
    cols = ["#3C60FF" if v > 1 else "#B8C5FF" for v in sorted_sr]

    fig, ax = plt.subplots(figsize=(12, 9))
    bars = ax.bar(range(len(sorted_sr)), sorted_sr, color=cols, edgecolor="black", lw=0.4)
    ax.axhline(1, color="#FF1900", ls="-", lw=1, label="Soglia SR")
    ax.set_xticks(range(len(sorted_desc)))
    ax.set_xticklabels(sorted_desc, rotation=45, ha="right")
    ax.set_xlabel("Descrittori Molecolari")
    ax.set_ylabel("Selectivity Ratio")
    ax.set_title("PLS-DA - Selectivity Ratio (SR)", fontsize=14, fontweight="bold")
    ax.legend(loc="upper right", fontsize=9, framealpha=0.9)
    ax.grid(axis="y", ls=":", alpha=0.4)
    for bar, v in zip(bars, sorted_sr):
        if v > 1:
            ax.text(bar.get_x() + bar.get_width() / 2, v + 0.02,
                    f"{v:.2f}", ha="center", va="bottom",
                    fontsize=8, fontstyle="italic", color="#2C3E50")
    plt.tight_layout()
    plt.savefig(filename, dpi=300, bbox_inches="tight")
    plt.close()
    print(f"  ✓ Salvato: {filename}")


def plot_regression_coefficients(model, descriptors, filename="Regression_coefficients.png"):
    """
    Grafico dei coefficienti di regressione PLS-DA.

    Usa model.coef_ (p, K) — colonna Biodeg (indice 1).
    Il segno indica la direzione: positivo → Biodegradabile, negativo → Non Biodeg.
    """
    # coef_ ha shape (K, p) in sklearn recenti;  riga 1 = Biodeg
    coefs = model.coef_[1, :]           # (p,)

    # Ordina per valore decrescente
    order = np.argsort(coefs)[::-1]
    coefs_sorted = coefs[order]
    desc_sorted  = [descriptors[i] for i in order]

    fig, ax = plt.subplots(figsize=(12, 9))
    colors = ["#FF6565" if v > 0 else "#3C60FF" for v in coefs_sorted]
    ax.bar(range(len(coefs_sorted)), coefs_sorted, color=colors, edgecolor="black", lw=0.4)
    ax.set_xticks(range(len(desc_sorted)))
    ax.set_xticklabels(desc_sorted, rotation=45, ha="right")
    ax.axhline(0, color="black", lw=1)
    ax.set_ylabel("Coefficiente di Regressione")
    ax.set_xlabel("Descrittori")
    ax.set_title("PLS-DA - Coefficienti di Regressione", fontsize=14, fontweight="bold")
    ax.grid(axis="both", ls=":", alpha=0.4)
    ax.legend(handles=[
        plt.Line2D([0], [0], color="#FF6565", lw=4, label="Contributo positivo (Biodegradabile)"),
        plt.Line2D([0], [0], color="#3C60FF", lw=4, label="Contributo negativo (Non Biodegradabile)"),
    ], loc="upper right", fontsize=9)

    plt.tight_layout()
    plt.savefig(filename, dpi=300, bbox_inches="tight")
    plt.close()
    print(f"  ✓ Salvato: {filename}")

# ── Metriche di classificazione ──────────────────────────────────────────────

def compute_classification_metrics(y_true, y_pred, label=""):
    """Restituisce un dict con le metriche chiave per PLS-DA."""
    acc  = accuracy_score(y_true, y_pred)
    bacc = balanced_accuracy_score(y_true, y_pred)
    sens = recall_score(y_true, y_pred, pos_label=2)          # Biodeg
    spec = recall_score(y_true, y_pred, pos_label=1)          # Non Biodeg
    return {
        "model": label,
        "accuracy": acc,
        "balanced_accuracy": bacc,
        "sensitivity": sens,     # recall classe 2 (Biodeg)
        "specificity": spec,     # recall classe 1 (Non Biodeg)
    }


# ── Grafico confronto selezione variabili ────────────────────────────────────

def plot_variable_selection_comparison(comparison_df, filename="Variable_selection_comparison.png"):
    """Bar chart raggruppato: metriche sull'asse X, barre per modello."""
    metrics = ["accuracy", "balanced_accuracy", "sensitivity", "specificity"]
    metric_labels = ["Accuracy", "Balanced\nAccuracy", "Sensitivity", "Specificity"]
    models = comparison_df["model"].tolist()
    n_models = len(models)
    n_metrics = len(metrics)

    x = np.arange(n_metrics)
    total_width = 0.7
    width = total_width / n_models
    palette = ["#3C60FF", "#E74C3C", "#27AE60",]

    fig, ax = plt.subplots(figsize=(12, 9))
    for i, model_name in enumerate(models):
        row = comparison_df[comparison_df["model"] == model_name].iloc[0]
        vals = [row[m] for m in metrics]
        offset = (i - n_models / 2 + 0.5) * width
        bars = ax.bar(x + offset, vals, width, label=model_name,
                       color=palette[i % len(palette)],
                       edgecolor="black", lw=0.4)
        for bar, v in zip(bars, vals):
            ax.text(bar.get_x() + bar.get_width() / 2, v + 0.005,
                    f"{v:.3f}", ha="center", va="bottom",
                    fontsize=8, fontstyle="italic", color="#2C3E50")

    ax.set_xticks(x)
    ax.set_xticklabels(metric_labels, fontsize=11)
    ax.set_ylabel("Valore")
    ax.set_ylim(0.5, 1.05)
    title = "Test Set" if "test" in filename.lower() else "Cross-Validation Training"
    ax.set_title(f"Confronto Strategie di Selezione Variabili - {title}\n", fontsize=14, fontweight="bold")
    ax.legend(loc="best", fontsize=9)
    ax.grid(axis="y", ls=":", alpha=0.4)
    plt.tight_layout()
    plt.savefig(filename, dpi=300, bbox_inches="tight")
    plt.close()
    print(f"  ✓ Salvato: {filename}")


# ── Applicability Domain ─────────────────────────────────────────────────────

def check_applicability_domain(model, X_train, X_new, confidence=0.99):
    """
    Calcola leverage (h) e Q residuals per i campioni X_new rispetto
    al modello PLS-DA calibrato su X_train.

    Un campione è fuori dominio se h > h* E Q > Q* (entrambi violati).

    Restituisce: (h_train, Q_train, h_new, Q_new, h_lim, Q_lim, outside_mask)
    """
    T_train = model.x_scores_
    P       = model.x_loadings_
    A       = T_train.shape[1]
    n_train = T_train.shape[0]

    TtT_inv = np.linalg.inv(T_train.T @ T_train)
    W_star  = model.x_rotations_
    T_new   = X_new @ W_star

    h_train = np.array([T_train[i] @ TtT_inv @ T_train[i]
                        for i in range(n_train)])
    h_new   = np.array([T_new[i] @ TtT_inv @ T_new[i]
                        for i in range(len(X_new))])
    h_lim   = 3 * A / n_train

    X_hat_train = T_train @ P.T
    Q_train = np.sum((X_train - X_hat_train) ** 2, axis=1)
    Q_lim   = np.percentile(Q_train, confidence * 100)

    X_hat_new = T_new @ P.T
    Q_new     = np.sum((X_new - X_hat_new) ** 2, axis=1)

    outside = (h_new > h_lim) & (Q_new > Q_lim)

    return h_train, Q_train, h_new, Q_new, h_lim, Q_lim, outside


def plot_ad_scatter(h_train, Q_train, h_test, Q_test, out_test, h_eval, Q_eval, out_eval, h_lim, Q_lim, confidence=0.95, filename="Applicability_domain.png"):
    """
    Scatter plot h vs Q con training di sfondo e Test + Xeval sovrapposti.
    Genera UN SOLO grafico per entrambi i set.
    """
    fig, ax = plt.subplots(figsize=(12, 9))

    # Training (sfondo)
    ax.scatter(h_train, Q_train, c="#5C5C5C", s=18, alpha=0.35, edgecolors="none", label="Training", zorder=1)

    # Test – dentro
    in_t = ~out_test
    if in_t.any():
        ax.scatter(h_test[in_t], Q_test[in_t], c="#5DADE2", s=35,
                   edgecolors="k", linewidths=0.3, alpha=0.7, marker="s",
                   label=f"Test - nel dominio ({in_t.sum()})", zorder=2)
    if out_test.any():
        ax.scatter(h_test[out_test], Q_test[out_test], c="#2874A6", s=55,
                   marker="X", edgecolors="k", linewidths=0.4,
                   label=f"Test - fuori dominio ({out_test.sum()})", zorder=3)

    # Xeval – dentro
    in_e = ~out_eval
    if in_e.any():
        ax.scatter(h_eval[in_e], Q_eval[in_e], c="#2ECC71", s=40,
                   edgecolors="k", linewidths=0.3, alpha=0.8,
                   label=f"Xeval - nel dominio ({in_e.sum()})", zorder=4)
    if out_eval.any():
        ax.scatter(h_eval[out_eval], Q_eval[out_eval], c="#E74C3C", s=65,
                   marker="X", edgecolors="k", linewidths=0.4,
                   label=f"Xeval - fuori dominio ({out_eval.sum()})", zorder=5)

    # Soglie
    ax.axvline(h_lim, color="#FE7D32", ls="--", lw=1, label=f"Soglia h*")
    ax.axhline(Q_lim, color="#F39C12", ls="--", lw=1, label=f"Soglia Q*")

    n_out_test = out_test.sum()
    n_out_eval = out_eval.sum()
    ax.set_xlabel("Leverage")
    ax.set_ylabel("Q Residuals")
    ax.set_title(f"Applicability Domain - Test e Xeval\n", fontsize=14, fontweight="bold")
    ax.text(0.5, -0.1,f"Test fuori: {n_out_test}/{len(out_test)} | Xeval fuori: {n_out_eval}/{len(out_eval)}", fontsize=12, ha='center', transform=ax.transAxes, fontstyle="italic", color="#555555")
    ax.legend(loc="upper right", fontsize=9, framealpha=0.9)
    ax.grid(True, ls=":", alpha=0.4)

    plt.tight_layout()
    plt.savefig(filename, dpi=300, bbox_inches="tight")
    plt.close()
    print(f"  ✓ Salvato: {filename}")


def plot_ad_sample_breakdown(h_values, Q_values, h_lim, Q_lim, set_name="Xeval", filename="AD_sample_breakdown.png"):
    """
    Grafico a due pannelli che mostra, campione per campione:
      - Pannello superiore: leverage (h) di ogni campione con soglia h*
      - Pannello inferiore: Q residuals di ogni campione con soglia Q*

    Permette di capire QUALE criterio causa l'uscita dal dominio
    e QUALI campioni specifici sono problematici.
    """
    n = len(h_values)
    sample_ids = np.arange(1, n + 1)

    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 9), sharex=True)

    # ── Pannello 1: Leverage ──
    colors_h = np.where(h_values > h_lim, "#E74C3C", "#2ECC71")
    ax1.bar(sample_ids, h_values, color=colors_h, edgecolor="k", linewidth=0.3, width=0.8)
    ax1.axhline(h_lim, color="#FE7D32", ls="--", lw=1, label=f"Soglia h*")
    ax1.set_ylabel("Leverage")
    ax1.set_title(f"Applicability Domain per campione - {set_name}", fontsize=14, fontweight="bold")
    ax1.legend(fontsize=9, loc="upper right")
    ax1.grid(axis="y", ls=":", alpha=0.4)

    out_h_idx = np.where(h_values > h_lim)[0]
    for i in out_h_idx:
        ax1.text(sample_ids[i], h_values[i], f" {sample_ids[i]}", fontsize=7, ha="center", va="bottom", color="#C0392B", fontweight="bold")

    # ── Pannello 2: Q residuals ──
    colors_q = np.where(Q_values > Q_lim, "#E74C3C", "#2ECC71")
    ax2.bar(sample_ids, Q_values, color=colors_q, edgecolor="k", linewidth=0.3, width=0.8)
    ax2.axhline(Q_lim, color="#F39C12", ls="--", lw=1, label=f"Soglia Q*")
    ax2.set_ylabel("Q Residuals")
    ax2.set_xlabel("Campione")
    ax2.legend(fontsize=9, loc="upper right")
    ax2.grid(axis="y", ls=":", alpha=0.4)

    out_q_idx = np.where(Q_values > Q_lim)[0]
    for i in out_q_idx:
        ax2.text(sample_ids[i], Q_values[i], f" {sample_ids[i]}",
                 fontsize=7, ha="center", va="bottom", color="#C0392B",
                 fontweight="bold")

    plt.tight_layout()
    plt.savefig(filename, dpi=300, bbox_inches="tight")
    plt.close()
    print(f"  ✓ Salvato: {filename}")