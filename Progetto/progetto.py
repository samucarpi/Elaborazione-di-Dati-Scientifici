from plots import *

if __name__ == "__main__":

    print("=" * 80)
    print("  ANALISI QSAR – CLASSIFICAZIONE BIODEGRADABILITÀ MOLECOLARE")
    print("  PCA Esplorativa  ·  PLS-DA  ·  VIP / SR  ·  Selezione Variabili")
    print("=" * 80)

    # =====================================================================
    # 1.  CARICAMENTO  DATI
    # =====================================================================
    print("\n" + "─" * 50)
    print("1. CARICAMENTO E PREPROCESSING DATI")
    print("─" * 50)

    try:
        data = loadmat("Biodeg.mat")
        print("  ✓ File Biodeg.mat caricato correttamente")
    except FileNotFoundError:
        raise SystemExit("ERRORE: 'Biodeg.mat' non trovato.")

    X_train = data["Xtrain"]
    X_test  = data["Xtest"]
    X_eval  = data["Xeval"]
    y_train = data["class_train"].flatten()
    y_test  = data["class_test"].flatten()

    # Nomi descrittori
    raw = data["descriptors_plsda"].flatten()
    descriptors = []
    for i, item in enumerate(raw):
        try:
            name = str(item[0]) if hasattr(item, "__iter__") and len(item) > 0 else str(item)
            descriptors.append(name.strip())
        except Exception:
            descriptors.append(f"Var_{i+1}")

    n_vars = X_train.shape[1]

    # Dummy encoding esplicito (robusto, non dipende da pandas)
    y_train_dummy = np.zeros((len(y_train), 2))
    y_train_dummy[y_train == 1, 0] = 1.0
    y_train_dummy[y_train == 2, 1] = 1.0

    print(f"\n  Training:  {X_train.shape[0]} x {n_vars}")
    print(f"  Test:      {X_test.shape[0]} x {n_vars}")
    print(f"  Eval:      {X_eval.shape[0]} x {n_vars}")
    print(f"\n  Classi Training:")
    print(f"    Classe 1 (Non Biodeg): {(y_train==1).sum()}"
          f"  ({100*(y_train==1).mean():.1f}%)")
    print(f"    Classe 2 (Biodeg):     {(y_train==2).sum()}"
          f"  ({100*(y_train==2).mean():.1f}%)")
    print(f"\n  Classi Test:")
    print(f"    Classe 1: {(y_test==1).sum()}   Classe 2: {(y_test==2).sum()}")

    # Autoscaling
    scaler = StandardScaler()
    X_train_s = scaler.fit_transform(X_train)
    X_test_s  = scaler.transform(X_test)
    X_eval_s  = scaler.transform(X_eval)

    # Creazione cartelle per i grafici
    for folder in ["2_PCA", "3_PLSDA", "4_VIP_SR", "5_Selezione"]:
        os.makedirs(folder, exist_ok=True)

    # =====================================================================
    # 2.  PCA  ESPLORATIVA
    # =====================================================================
    print("\n" + "─" * 50)
    print("2. PCA ESPLORATIVA SUL TRAINING SET")
    print("─" * 50)

    pca_full = PCA().fit(X_train_s)
    exp_var = pca_full.explained_variance_ratio_ * 100
    cum_var = np.cumsum(exp_var)

    # Scores e loadings (4 PC)
    nComponents = 4
    pca4 = PCA(nComponents).fit(X_train_s)
    scores_train = pca4.transform(X_train_s)
    loadings = pca4.components_.T

    # Grafici PCA
    print("\n  Generazione grafici PCA…")
    plot_pca_scores(scores_train, y_train, exp_var, "2_PCA/PCA_scores.png")
    plot_pca_loadings(loadings, descriptors, exp_var, "2_PCA/PCA_loadings.png")
    plot_biplot(scores_train, loadings, y_train, descriptors, exp_var, "2_PCA/PCA_biplot.png")
    plot_scree(exp_var[:10], "2_PCA/PCA_scree.png", nComponents)
    T2, Q, T2_lim, Q_lim = plot_t2_vs_q(
        scores_train, X_train_s, pca4, y_train,
        confidence=0.95, filename="2_PCA/PCA_T2_vs_Q.png")

    # Contribution plot dei 2 outlier più significativi
    plot_contribution(692, X_train_s, scores_train, pca4, descriptors, filename=f"2_PCA/Contribution_outlier_{692}.png")
    plot_contribution(367, X_train_s, scores_train, pca4, descriptors, filename=f"2_PCA/Contribution_outlier_{367}.png")

    # =====================================================================
    # 3.  MODELLO  PLS-DA
    # =====================================================================
    print("\n" + "─" * 50)
    print("3. PLS-DA – OTTIMIZZAZIONE COMPONENTI (Stratified 10-Fold CV)")
    print("─" * 50)


    best_n = 7

    cv_res = compute_cv_scan(X_train_s, y_train_dummy, y_train, max_components=15, cv_folds=10)

    plot_cv_optimization(cv_res, "3_PLSDA/CV_optimization.png", chosen_n=best_n)
    plot_cv_classification_error(cv_res, "3_PLSDA/CV_classification_error.png", chosen_n=best_n)

    # ── Modello finale ──
    print(f"\n  Fitting PLS-DA finale con {best_n} LV…")
    pls_da = PLSRegression(n_components=best_n, scale=False)
    pls_da.fit(X_train_s, y_train_dummy)

    # Cross-validation confusion matrix (predizioni out-of-fold)
    skf_final = StratifiedKFold(n_splits=10, shuffle=True, random_state=42)
    splits_final = list(skf_final.split(X_train_s, y_train))
    y_cv_pred_dummy = cross_val_predict(pls_da, X_train_s, y_train_dummy, cv=splits_final)

    # Curva ROC per il grafico (AUC)
    y_cv_cont = y_cv_pred_dummy[:, 1]   # colonna Biodeg continua (out-of-fold)
    _, fpr_cv, tpr_cv, thresholds_cv, auc_cv = \
        compute_optimal_threshold(y_train, y_cv_cont)
    optimal_threshold = 0.5
    print(f"\n  Criterio di classificazione: True Discriminant (argmax)")
    print(f"  AUC (Cross-Validation):      {auc_cv:.4f}")

    # Classificazione CV – True Discriminant: argmax sulle colonne dummy
    y_cv_pred = np.argmax(y_cv_pred_dummy, axis=1) + 1
    cv_metrics = compute_classification_metrics(y_train, y_cv_pred, "CV")
    print(f"\n  Metriche Cross-Validation (out-of-fold, soglia={optimal_threshold:.4f}):")
    print(f"    Accuracy:          {cv_metrics['accuracy']:.4f}")
    print(f"    Balanced Accuracy: {cv_metrics['balanced_accuracy']:.4f}")
    print(f"    Sensitivity:       {cv_metrics['sensitivity']:.4f}  (Biodeg)")
    print(f"    Specificity:       {cv_metrics['specificity']:.4f}  (Non Biodeg)")

    # ROC Curve - Training Cross-Validation
    plot_roc_curve(fpr_cv, tpr_cv, thresholds_cv, auc_cv, optimal_threshold,
                   filename="3_PLSDA/ROC_curve_CV.png",
                   set_name="Cross-Validation Training (Modello Completo)",
                   y_true=y_train, y_pred_cont=y_cv_cont)

    # ── Predizione test set con soglia ottimale determinata dal CV ──
    y_test_cont = pls_da.predict(X_test_s)[:, 1]
    y_test_pred = np.argmax(pls_da.predict(X_test_s), axis=1) + 1
    test_metrics_full = compute_classification_metrics(
        y_test, y_test_pred, f"Completo ({n_vars} var")

    print(f"\n  Metriche Test Set (modello completo, {best_n} LV, soglia={optimal_threshold:.4f}):")
    print(f"    Accuracy:          {test_metrics_full['accuracy']:.4f}")
    print(f"    Balanced Accuracy: {test_metrics_full['balanced_accuracy']:.4f}")
    print(f"    Sensitivity:       {test_metrics_full['sensitivity']:.4f}")
    print(f"    Specificity:       {test_metrics_full['specificity']:.4f}")

    # ROC Curve - Test Set (soglia determinata dal CV)
    _, fpr_test, tpr_test, thresholds_test, auc_test = \
        compute_optimal_threshold(y_test, y_test_cont)
    print(f"\n  AUC (Test Set):                    {auc_test:.4f}")
    plot_roc_curve(fpr_test, tpr_test, thresholds_test, auc_test, optimal_threshold,
                   filename="3_PLSDA/ROC_curve_test.png",
                   set_name="Test Set (Modello Completo)",
                   y_true=y_test, y_pred_cont=y_test_cont)

    # ── Stampa riepilogo modello stile PLS_Toolbox ──────────────────────────
    # Predizioni continue (dummy) per Cal, CV, Pred
    y_cal_pred_dummy  = pls_da.predict(X_train_s)          # calibrazione
    y_test_pred_dummy = pls_da.predict(X_test_s)           # predizione test
    # y_cv_pred_dummy già calcolato sopra via cross_val_predict

    # Classi predette per Cal – stessa soglia ottimale CV
    y_cal_class = np.where(y_cal_pred_dummy[:, 1] >= optimal_threshold, 2, 1)

    # Dummy Y reale per il test set
    y_test_dummy = np.zeros((len(y_test), 2))
    y_test_dummy[y_test == 1, 0] = 1.0
    y_test_dummy[y_test == 2, 1] = 1.0

    n_classes = 2
    class_labels = [1, 2]

    def _per_class_sens_spec(y_true_cls, y_pred_cls):
        """Sensitività e specificità per-classe (one-vs-all)."""
        sens, spec, cerr = [], [], []
        for k in class_labels:
            tp = np.sum((y_true_cls == k) & (y_pred_cls == k))
            fn = np.sum((y_true_cls == k) & (y_pred_cls != k))
            fp = np.sum((y_true_cls != k) & (y_pred_cls == k))
            tn = np.sum((y_true_cls != k) & (y_pred_cls != k))
            s = tp / (tp + fn) if (tp + fn) > 0 else 0.0
            p = tn / (tn + fp) if (tn + fp) > 0 else 0.0
            sens.append(s)
            spec.append(p)
            cerr.append(((1 - s) + (1 - p)) / 2)
        return sens, spec, cerr

    def _rmse_bias_r2(y_true_d, y_pred_d):
        """RMSE, Bias e R² per ogni colonna della matrice dummy."""
        rmse, bias, r2 = [], [], []
        for col in range(y_true_d.shape[1]):
            yt = y_true_d[:, col]
            yp = y_pred_d[:, col]
            res = yp - yt
            rmse.append(np.sqrt(np.mean(res ** 2)))
            bias.append(np.mean(res))
            ss_res = np.sum(res ** 2)
            ss_tot = np.sum((yt - yt.mean()) ** 2)
            r2.append(1 - ss_res / ss_tot if ss_tot > 0 else 0.0)
        return rmse, bias, r2

    # Calcolo metriche per Cal, CV, Pred
    sens_cal, spec_cal, cerr_cal = _per_class_sens_spec(y_train, y_cal_class)
    sens_cv,  spec_cv,  cerr_cv  = _per_class_sens_spec(y_train, y_cv_pred)
    sens_pred, spec_pred, cerr_pred = _per_class_sens_spec(y_test, y_test_pred)

    rmse_cal, bias_cal, r2_cal = _rmse_bias_r2(y_train_dummy, y_cal_pred_dummy)
    rmse_cv,  bias_cv,  r2_cv  = _rmse_bias_r2(y_train_dummy, y_cv_pred_dummy)
    rmse_pred, bias_pred, r2_pred = _rmse_bias_r2(y_test_dummy, y_test_pred_dummy)

    # Funzione formattazione riga
    def _fmt_row(label, values, fmt=".6g"):
        nums = "  ".join(f"{v:{fmt}}" for v in values)
        return f"  {label:<22s} {nums}"

    from datetime import datetime
    now_str = datetime.now().strftime("%d-%b-%Y %H:%M:%S")

    print("\n" + "=" * 72)
    print("  RIEPILOGO MODELLO PLS-DA  (stile PLS_Toolbox)")
    print("=" * 72)
    print(f"  This is a model of type: PLSDA_PRED")
    print(f"  Developed {now_str}")
    print()
    print(f"  X-block: X_train  {X_train.shape[0]} by {X_train.shape[1]}")
    print(f"  Included: [ 1-{X_train.shape[0]} ]  [ 1-{X_train.shape[1]} ]")
    print(f"  Preprocessing: Autoscale")
    print()
    print(f"  Y-block: Y_train  {y_train_dummy.shape[0]} by {y_train_dummy.shape[1]}")
    print(f"  Included: [ 1-{y_train_dummy.shape[0]} ]  [ 1-{y_train_dummy.shape[1]} ]")
    print(f"  Preprocessing: None")
    print(f"  Num. LVs: {best_n}")
    print()
    print(f"  Cross validation: stratified k-fold w/ 10 splits")
    print()
    print(f"  Statistics for each y-block column:")
    print(f"  {'':22s} {'Classe 1':>12s}  {'Classe 2':>12s}")
    print(f"  {'-'*50}")
    print(_fmt_row("Sensitivity (Cal):",  sens_cal,  ".4f"))
    print(_fmt_row("Specificity (Cal):",  spec_cal,  ".4f"))
    print(_fmt_row("Sensitivity (CV):",   sens_cv,   ".4f"))
    print(_fmt_row("Specificity (CV):",   spec_cv,   ".4f"))
    print(_fmt_row("Sensitivity (Pred):", sens_pred,  ".4f"))
    print(_fmt_row("Specificity (Pred):", spec_pred,  ".4f"))
    print()
    print(_fmt_row("Class. Err (Cal):",   cerr_cal,  ".6f"))
    print(_fmt_row("Class. Err (CV):",    cerr_cv,   ".6f"))
    print(_fmt_row("Class. Err (Pred):",  cerr_pred,  ".6f"))
    print()
    print(_fmt_row("RMSEC:",              rmse_cal,  ".6f"))
    print(_fmt_row("RMSECV:",             rmse_cv,   ".6f"))
    print(_fmt_row("RMSEP:",              rmse_pred, ".6f"))
    print()
    print(_fmt_row("Bias:",               bias_cal,  ".6g"))
    print(_fmt_row("CV Bias:",            bias_cv,   ".6g"))
    print(_fmt_row("Pred Bias:",          bias_pred, ".6g"))
    print()
    print(_fmt_row("R² Cal:",             r2_cal,    ".6f"))
    print(_fmt_row("R² CV:",              r2_cv,     ".6f"))
    print(_fmt_row("R² Pred:",            r2_pred,   ".6f"))
    print("=" * 72)

    plot_confusion_matrix(
        y_test, y_test_pred,
        f"Confusion Matrix - Test Set (Completo)\n",
        f"Balanced Accuracy = {test_metrics_full['balanced_accuracy']:.4f}",
        "3_PLSDA/Confusion_matrix_full.png",
    )

    plot_confusion_matrix(
        y_train, y_cv_pred,
        f"Confusion Matrix - Cross-Validation Training (Completo)\n",
        f"Balanced Accuracy = {cv_metrics['balanced_accuracy']:.4f}",
        "3_PLSDA/Confusion_matrix_CV.png",
    )

    # Score Plot PLS-DA (LV1 vs LV2)
    plot_plsda_scores(pls_da, X_train_s, y_train, "3_PLSDA/PLSDA_scores.png")

    # Grafico y_pred vs campioni (train + test) con soglia ROC ottimale
    plot_ypred_vs_actual(pls_da, X_train_s, y_train, filename="3_PLSDA/PLSDA_ypred_train.png", threshold=optimal_threshold)
    plot_ypred_vs_actual(pls_da, X_test_s, y_test, filename="3_PLSDA/PLSDA_ypred_test.png", threshold=optimal_threshold)

    # Y Predicted Plot combinato (Training + Test) con entrambe le colonne dummy
    plot_ypred_combined(pls_da, X_train_s, y_train, X_test_s, y_test,
                        filename="3_PLSDA/PLSDA_ypred_combined.png", threshold=optimal_threshold)

    # =====================================================================
    # 4.  ANALISI  DESCRITTORI  IMPORTANTI   (VIP  &  SR)
    # =====================================================================
    print("\n" + "─" * 50)
    print("4. ANALISI DESCRITTORI – VIP SCORES")
    print("─" * 50)

    vip_scores = calculate_vip(pls_da, X_train_s, y_train_dummy)
    sr_scores  = calculate_selectivity_ratio(pls_da, X_train_s)

    plot_vip_scores(vip_scores, descriptors, "4_VIP_SR/VIP_scores.png")
    plot_sr_scores(sr_scores, descriptors, "4_VIP_SR/SR_scores.png")
    
    # Grafico Loading Weights w*c
    plot_regression_coefficients(pls_da, descriptors, "4_VIP_SR/Regression_coefficients.png")

    # =====================================================================
    # 5.  SELEZIONE  VARIABILI  –  CONFRONTO  STRATEGIE
    # =====================================================================
    print("\n" + "─" * 50)
    print("5. SELEZIONE VARIABILI")
    print("─" * 50)

    comparison_rows = [test_metrics_full]      # baseline: modello completo

    # Dizionario per memorizzare modelli e indici per ogni strategia
    strategy_results = {}

    def _build_and_evaluate(label, sel_mask):
        """
        Costruisce un modello PLS-DA ridotto sulle variabili selezionate
        e restituisce le metriche sul test.
        """
        idx = np.where(sel_mask)[0]
        if len(idx) < 2:
            print(f"  ⚠  {label}: meno di 2 variabili, skip.")
            return None

        Xtr = X_train_s[:, idx]
        Xts = X_test_s[:, idx]

        n_best = min(best_n, len(idx))  # Stesso numero LV del modello completo

        pls_sel = PLSRegression(n_components=n_best, scale=False)
        pls_sel.fit(Xtr, y_train_dummy)

        # Metriche CV del modello ridotto
        skf_sel = StratifiedKFold(n_splits=10, shuffle=True, random_state=42)
        splits_sel = list(skf_sel.split(Xtr, y_train))
        y_cv_sel = cross_val_predict(pls_sel, Xtr, y_train_dummy, cv=splits_sel)
        y_cv_sel_class = np.argmax(y_cv_sel, axis=1) + 1
        m_cv = compute_classification_metrics(
            y_train, y_cv_sel_class, f"{label} ({len(idx)} var, {n_best} LV)")

        yp = np.argmax(pls_sel.predict(Xts), axis=1) + 1
        m  = compute_classification_metrics(
            y_test, yp, f"{label} ({len(idx)} var, {n_best} LV)")

        # Curva ROC per il grafico (AUC) – classificazione usa soglia fissa 0.5 (truemax)
        y_cv_cont_sel = y_cv_sel[:, 1]
        _, fpr_sel, tpr_sel, thresholds_sel, auc_sel = \
            compute_optimal_threshold(y_train, y_cv_cont_sel)

        # Salva nel dizionario
        strategy_results[label] = {
            "metrics": m, "metrics_cv": m_cv, "model": pls_sel,
            "idx": idx, "n_lv": n_best,
            "bacc_cv": m_cv["balanced_accuracy"],
            "y_cv_pred": y_cv_sel_class,
            "y_cv_cont": y_cv_cont_sel,
            "optimal_threshold": 0.5,
            "roc_data_cv": (fpr_sel, tpr_sel, thresholds_sel, auc_sel),
        }

        return m

    # ── VIP > 1 ──
    print()
    res_vip1 = _build_and_evaluate("VIP > 1", vip_scores > 1)
    if res_vip1:
        comparison_rows.append(res_vip1)

    # ── Stampa riepilogo VIP > 1 stile PLS_Toolbox ──────────────────────────
    if res_vip1 and "VIP > 1" in strategy_results:
        vip_data  = strategy_results["VIP > 1"]
        vip_model = vip_data["model"]
        vip_idx   = vip_data["idx"]
        vip_n_lv  = vip_data["n_lv"]
        n_vars_vip = len(vip_idx)

        Xtr_vip = X_train_s[:, vip_idx]
        Xts_vip = X_test_s[:, vip_idx]

        # Predizioni Cal / CV / Pred
        y_cal_vip_dummy  = vip_model.predict(Xtr_vip)
        y_cal_vip_class  = np.argmax(y_cal_vip_dummy, axis=1) + 1

        skf_vip = StratifiedKFold(n_splits=10, shuffle=True, random_state=42)
        splits_vip = list(skf_vip.split(Xtr_vip, y_train))
        y_cv_vip_dummy  = cross_val_predict(vip_model, Xtr_vip, y_train_dummy, cv=splits_vip)
        y_cv_vip_class  = np.argmax(y_cv_vip_dummy, axis=1) + 1

        y_pred_vip_dummy = vip_model.predict(Xts_vip)
        y_pred_vip_class = np.argmax(y_pred_vip_dummy, axis=1) + 1

        # Metriche per-classe
        sens_cal_v, spec_cal_v, cerr_cal_v = _per_class_sens_spec(y_train, y_cal_vip_class)
        sens_cv_v,  spec_cv_v,  cerr_cv_v  = _per_class_sens_spec(y_train, y_cv_vip_class)
        sens_pred_v, spec_pred_v, cerr_pred_v = _per_class_sens_spec(y_test, y_pred_vip_class)

        rmse_cal_v, bias_cal_v, r2_cal_v = _rmse_bias_r2(y_train_dummy, y_cal_vip_dummy)
        rmse_cv_v,  bias_cv_v,  r2_cv_v  = _rmse_bias_r2(y_train_dummy, y_cv_vip_dummy)
        rmse_pred_v, bias_pred_v, r2_pred_v = _rmse_bias_r2(y_test_dummy, y_pred_vip_dummy)

        vip_var_names = [descriptors[i] for i in vip_idx]

        print("\n" + "=" * 72)
        print("  RIEPILOGO MODELLO PLS-DA  VIP > 1  (stile PLS_Toolbox)")
        print("=" * 72)
        print(f"  This is a model of type: PLSDA_PRED (variabili selezionate VIP > 1)")
        print(f"  Developed {now_str}")
        print()
        print(f"  X-block: X_train  {X_train.shape[0]} by {n_vars_vip}  (selezionate da {n_vars})")
        print(f"  Variabili incluse ({n_vars_vip}): {', '.join(vip_var_names)}")
        print(f"  Preprocessing: Autoscale")
        print()
        print(f"  Y-block: Y_train  {y_train_dummy.shape[0]} by {y_train_dummy.shape[1]}")
        print(f"  Preprocessing: None")
        print(f"  Num. LVs: {vip_n_lv}")
        print()
        print(f"  Cross validation: stratified k-fold w/ 10 splits")
        print()
        print(f"  Statistics for each y-block column:")
        print(f"  {'':22s} {'Classe 1':>12s}  {'Classe 2':>12s}")
        print(f"  {'-'*50}")
        print(_fmt_row("Sensitivity (Cal):",  sens_cal_v,  ".4f"))
        print(_fmt_row("Specificity (Cal):",  spec_cal_v,  ".4f"))
        print(_fmt_row("Sensitivity (CV):",   sens_cv_v,   ".4f"))
        print(_fmt_row("Specificity (CV):",   spec_cv_v,   ".4f"))
        print(_fmt_row("Sensitivity (Pred):", sens_pred_v, ".4f"))
        print(_fmt_row("Specificity (Pred):", spec_pred_v, ".4f"))
        print()
        print(_fmt_row("Class. Err (Cal):",   cerr_cal_v,  ".6f"))
        print(_fmt_row("Class. Err (CV):",    cerr_cv_v,   ".6f"))
        print(_fmt_row("Class. Err (Pred):",  cerr_pred_v, ".6f"))
        print()
        print(_fmt_row("RMSEC:",              rmse_cal_v,  ".6f"))
        print(_fmt_row("RMSECV:",             rmse_cv_v,   ".6f"))
        print(_fmt_row("RMSEP:",              rmse_pred_v, ".6f"))
        print()
        print(_fmt_row("Bias:",               bias_cal_v,  ".6g"))
        print(_fmt_row("CV Bias:",            bias_cv_v,   ".6g"))
        print(_fmt_row("Pred Bias:",          bias_pred_v, ".6g"))
        print()
        print(_fmt_row("R² Cal:",             r2_cal_v,    ".6f"))
        print(_fmt_row("R² CV:",              r2_cv_v,     ".6f"))
        print(_fmt_row("R² Pred:",            r2_pred_v,   ".6f"))
        print("=" * 72)

    # ── SR > 1 ──
    res_sr1 = _build_and_evaluate("SR > 1", sr_scores > 1)
    if res_sr1:
        comparison_rows.append(res_sr1)

    # ── Stampa riepilogo SR > 1 stile PLS_Toolbox ──────────────────────────
    if res_sr1 and "SR > 1" in strategy_results:
        sr_data  = strategy_results["SR > 1"]
        sr_model = sr_data["model"]
        sr_idx   = sr_data["idx"]
        sr_n_lv  = sr_data["n_lv"]
        n_vars_sr = len(sr_idx)

        Xtr_sr = X_train_s[:, sr_idx]
        Xts_sr = X_test_s[:, sr_idx]

        y_cal_sr_dummy   = sr_model.predict(Xtr_sr)
        y_cal_sr_class   = np.argmax(y_cal_sr_dummy, axis=1) + 1

        skf_sr = StratifiedKFold(n_splits=10, shuffle=True, random_state=42)
        splits_sr = list(skf_sr.split(Xtr_sr, y_train))
        y_cv_sr_dummy    = cross_val_predict(sr_model, Xtr_sr, y_train_dummy, cv=splits_sr)
        y_cv_sr_class    = np.argmax(y_cv_sr_dummy, axis=1) + 1

        y_pred_sr_dummy  = sr_model.predict(Xts_sr)
        y_pred_sr_class  = np.argmax(y_pred_sr_dummy, axis=1) + 1

        sens_cal_sr, spec_cal_sr, cerr_cal_sr = _per_class_sens_spec(y_train, y_cal_sr_class)
        sens_cv_sr,  spec_cv_sr,  cerr_cv_sr  = _per_class_sens_spec(y_train, y_cv_sr_class)
        sens_pred_sr, spec_pred_sr, cerr_pred_sr = _per_class_sens_spec(y_test, y_pred_sr_class)

        rmse_cal_sr, bias_cal_sr, r2_cal_sr = _rmse_bias_r2(y_train_dummy, y_cal_sr_dummy)
        rmse_cv_sr,  bias_cv_sr,  r2_cv_sr  = _rmse_bias_r2(y_train_dummy, y_cv_sr_dummy)
        rmse_pred_sr, bias_pred_sr, r2_pred_sr = _rmse_bias_r2(y_test_dummy, y_pred_sr_dummy)

        sr_var_names = [descriptors[i] for i in sr_idx]

        print("\n" + "=" * 72)
        print("  RIEPILOGO MODELLO PLS-DA  SR > 1  (stile PLS_Toolbox)")
        print("=" * 72)
        print(f"  This is a model of type: PLSDA_PRED (variabili selezionate SR > 1)")
        print(f"  Developed {now_str}")
        print()
        print(f"  X-block: X_train  {X_train.shape[0]} by {n_vars_sr}  (selezionate da {n_vars})")
        print(f"  Variabili incluse ({n_vars_sr}): {', '.join(sr_var_names)}")
        print(f"  Preprocessing: Autoscale")
        print()
        print(f"  Y-block: Y_train  {y_train_dummy.shape[0]} by {y_train_dummy.shape[1]}")
        print(f"  Preprocessing: None")
        print(f"  Num. LVs: {sr_n_lv}")
        print()
        print(f"  Cross validation: stratified k-fold w/ 10 splits")
        print()
        print(f"  Statistics for each y-block column:")
        print(f"  {'':22s} {'Classe 1':>12s}  {'Classe 2':>12s}")
        print(f"  {'-'*50}")
        print(_fmt_row("Sensitivity (Cal):",  sens_cal_sr,  ".4f"))
        print(_fmt_row("Specificity (Cal):",  spec_cal_sr,  ".4f"))
        print(_fmt_row("Sensitivity (CV):",   sens_cv_sr,   ".4f"))
        print(_fmt_row("Specificity (CV):",   spec_cv_sr,   ".4f"))
        print(_fmt_row("Sensitivity (Pred):", sens_pred_sr, ".4f"))
        print(_fmt_row("Specificity (Pred):", spec_pred_sr, ".4f"))
        print()
        print(_fmt_row("Class. Err (Cal):",   cerr_cal_sr,  ".6f"))
        print(_fmt_row("Class. Err (CV):",    cerr_cv_sr,   ".6f"))
        print(_fmt_row("Class. Err (Pred):",  cerr_pred_sr, ".6f"))
        print()
        print(_fmt_row("RMSEC:",              rmse_cal_sr,  ".6f"))
        print(_fmt_row("RMSECV:",             rmse_cv_sr,   ".6f"))
        print(_fmt_row("RMSEP:",              rmse_pred_sr, ".6f"))
        print()
        print(_fmt_row("Bias:",               bias_cal_sr,  ".6g"))
        print(_fmt_row("CV Bias:",            bias_cv_sr,   ".6g"))
        print(_fmt_row("Pred Bias:",          bias_pred_sr, ".6g"))
        print()
        print(_fmt_row("R² Cal:",             r2_cal_sr,    ".6f"))
        print(_fmt_row("R² CV:",              r2_cv_sr,     ".6f"))
        print(_fmt_row("R² Pred:",            r2_pred_sr,   ".6f"))
        print("=" * 72)

    # ── Confronto RMSECV tra modelli ──
    print("\n  Calcolo RMSECV per modelli ridotti…")
    cv_scans = {f"Completo ({n_vars} var)": cv_res}
    for label, res_data in strategy_results.items():
        idx = res_data["idx"]
        max_lv = min(15, len(idx))
        cv_scan_sel = compute_cv_scan(
            X_train_s[:, idx], y_train_dummy, y_train,
            max_components=max_lv, cv_folds=10)
        cv_scans[f"{label} ({len(idx)} var)"] = cv_scan_sel
    plot_rmsecv_comparison(cv_scans, chosen_n=best_n,
                           filename="5_Selezione/RMSECV_comparison.png")

    # ── Confusion matrix per ogni modello ridotto ──
    for label, res_data in strategy_results.items():
        yp_sel = np.argmax(
            res_data["model"].predict(X_test_s[:, res_data["idx"]]), axis=1) + 1
        safe_label = label.replace(">", "gt").replace("<", "lt").replace(" ", "_").replace("&", "and")
        plot_confusion_matrix(
            y_test, yp_sel,
            f"Confusion Matrix - Test Set\n",
            f"{res_data['metrics']['model']}",
            f"5_Selezione/Confusion_matrix_{safe_label}.png",
        )
        # Confusion matrix Cross-Validation per il modello ridotto
        plot_confusion_matrix(
            y_train, res_data["y_cv_pred"],
            f"Confusion Matrix - Cross-Validation Training\n",
            f"{res_data['metrics_cv']['model']}",
            f"5_Selezione/Confusion_matrix_{safe_label}_CV.png",
        )
        # ROC Curve del modello ridotto (CV)
        fpr_r, tpr_r, thr_r, auc_r = res_data["roc_data_cv"]
        plot_roc_curve(fpr_r, tpr_r, thr_r, auc_r, res_data["optimal_threshold"],
                       filename=f"5_Selezione/ROC_curve_{safe_label}_CV.png",
                       set_name=f"Cross-Validation ({label})",
                       y_true=y_train, y_pred_cont=res_data["y_cv_cont"])

    # Tabella di confronto
    comp_df = pd.DataFrame(comparison_rows)
    print(f"\n  {'─'*80}")
    print(f"  {'TABELLA RIASSUNTIVA':^80}")
    print(f"  {'─'*80}")
    print(f"  {'Modello':<38} {'Acc':>7} {'BAcc':>7} {'Sens':>7} {'Spec':>7}")
    print(f"  {'─'*80}")
    for _, r in comp_df.iterrows():
        print(f"  {r['model']:<38} {r['accuracy']:>7.4f} "
              f"{r['balanced_accuracy']:>7.4f} "
              f"{r['sensitivity']:>7.4f} {r['specificity']:>7.4f}")
    print(f"  {'─'*80}")

    plot_variable_selection_comparison(comp_df, "5_Selezione/Variable_selection_comparison_test.png")

    # ── Stesso grafico per le metriche CV ──
    cv_comparison_rows = [compute_classification_metrics(
        y_train, y_cv_pred, f"Completo ({n_vars} var")]
    for label, res_data in strategy_results.items():
        cv_comparison_rows.append(res_data["metrics_cv"])
    comp_cv_df = pd.DataFrame(cv_comparison_rows)
    plot_variable_selection_comparison(comp_cv_df, "5_Selezione/Variable_selection_comparison_CV.png")

    # ── Scelta del modello migliore per la previsione finale ──
    best_row = comp_df.loc[comp_df["balanced_accuracy"].idxmax()]
    print(f"\n  ★ Miglior modello (per balanced accuracy): {best_row['model']}")

    # Ricostruisco il modello migliore per Xeval
    if best_row["model"] == test_metrics_full["model"]:
        final_model     = pls_da
        final_X_eval    = X_eval_s
        model_type      = "completo"
        final_threshold = optimal_threshold          # soglia del modello completo
    else:
        # Cerca nel dizionario dei risultati
        found = False
        for label, res_data in strategy_results.items():
            if res_data["metrics"]["model"] == best_row["model"]:
                final_model     = res_data["model"]
                final_X_eval    = X_eval_s[:, res_data["idx"]]
                model_type      = f"ridotto ({label})"
                final_threshold = 0.5  # true discriminant
                # Confusion matrix del modello ridotto migliore
                y_test_pred_best = np.argmax(
                    final_model.predict(X_test_s[:, res_data["idx"]]), axis=1) + 1
                plot_confusion_matrix(
                    y_test, y_test_pred_best,
                    f"Confusion Matrix - Test (Miglior Ridotto)\n",
                    f"{best_row['model']}",
                    "5_Selezione/Confusion_matrix_best_reduced.png",
                )
                found = True
                break
        if not found:
            final_model     = pls_da
            final_X_eval    = X_eval_s
            model_type      = "completo"
            final_threshold = optimal_threshold

    # =====================================================================
    # 5b.  APPLICABILITY  DOMAIN
    # =====================================================================
    print("\n" + "─" * 50)
    print("5b. VERIFICA APPLICABILITY DOMAIN")
    print("─" * 50)

    # Determina il training e test set corrispondenti al modello finale
    if model_type == "completo":
        final_X_train = X_train_s
        final_X_test  = X_test_s
    else:
        final_X_train = X_train_s
        final_X_test  = X_test_s
        for label, res_data in strategy_results.items():
            if res_data["metrics"]["model"] == best_row["model"]:
                final_X_train = X_train_s[:, res_data["idx"]]
                final_X_test  = X_test_s[:, res_data["idx"]]
                break

    # Calcolo h e Q per Test e Xeval (99° percentile per Q*)
    h_train, Q_train, h_test, Q_test, h_lim, Q_lim, out_test = \
        check_applicability_domain(final_model, final_X_train, final_X_test,
                                   confidence=0.99)
    _, _, h_eval, Q_eval, _, _, out_eval = \
        check_applicability_domain(final_model, final_X_train, final_X_eval,
                                   confidence=0.99)

    print(f"\n  Test Set: {out_test.sum()}/{len(out_test)} campioni fuori dominio")
    print(f"  Xeval:    {out_eval.sum()}/{len(out_eval)} campioni fuori dominio")

    # Grafico 1 – Scatter h vs Q (Test + Xeval insieme)
    plot_ad_scatter(h_train, Q_train,
                    h_test, Q_test, out_test,
                    h_eval, Q_eval, out_eval,
                    h_lim, Q_lim, confidence=0.95,
                    filename="3_PLSDA/Applicability_domain.png")

    # Grafico 2 – Breakdown per campione (solo Xeval)
    plot_ad_sample_breakdown(h_eval, Q_eval, h_lim, Q_lim,
                             set_name="Xeval",
                             filename="3_PLSDA/AD_breakdown_eval.png")

    if out_eval.sum() > 0:
        pct = 100 * out_eval.sum() / len(out_eval)
        print(f"  ⚠  {pct:.1f}% dei campioni Xeval è fuori dal dominio di calibrazione!")
        print(f"     Le predizioni per questi campioni sono meno affidabili.")
    else:
        print(f"  ✓ Tutti i campioni Xeval ricadono nel dominio di calibrazione.")

    # =====================================================================
    # 6.  PREVISIONE  XEVAL  +  EXPORT
    # =====================================================================
    print("\n" + "─" * 50)
    print("6. PREVISIONE SET ESTERNO (Xeval) E EXPORT EXCEL")
    print("─" * 50)

    y_eval_dummy = final_model.predict(final_X_eval)
    y_eval_cont = y_eval_dummy[:, 1]
    y_eval_pred = np.argmax(y_eval_dummy, axis=1) + 1  # True Discriminant

    # Grafico y_pred vs campioni per Xeval
    plot_ypred_eval(final_model, final_X_eval,
                    filename="3_PLSDA/PLSDA_ypred_eval.png",
                    threshold=final_threshold)

    n1 = int((y_eval_pred == 1).sum())
    n2 = int((y_eval_pred == 2).sum())
    print(f"\n  Modello utilizzato: {model_type}")
    print(f"\n  Previsioni Xeval ({len(y_eval_pred)} campioni):")
    print(f"    Classe 1 (Non Biodeg): {n1} ({100*n1/len(y_eval_pred):.1f}%)")
    print(f"    Classe 2 (Biodeg):     {n2} ({100*n2/len(y_eval_pred):.1f}%)")

    # Affidabilità graduata: campioni fuori dominio con rapporto > 3× soglia
    # sono "Altamente inaffidabile", gli altri "Poco inaffidabile"
    h_ratio = h_eval / h_lim
    q_ratio = Q_eval / Q_lim
    max_ratio = np.maximum(h_ratio, q_ratio)

    affidabilita = np.where(
        ~out_eval, "Affidabile",
        np.where(max_ratio > 3, "Altamente inaffidabile", "Poco inaffidabile")
    )

    df_out = pd.DataFrame({
        "Sample_ID": range(1, len(y_eval_pred) + 1),
        "Predicted_Class": y_eval_pred,
        "Class_Label": np.where(y_eval_pred == 1, "Non Biodegradabile", "Biodegradabile"),
        "Dominio": np.where(out_eval, "No", "Sì"),
        "Affidabilità": affidabilita,
    })

    # ── Informazioni dettagliate sul modello ──
    # Variabili usate
    if model_type == "completo":
        vars_used = descriptors
        n_vars_used = n_vars
        selection_strategy = "Nessuna (tutte le 23 variabili)"
    else:
        for label, res_data in strategy_results.items():
            if res_data["metrics"]["model"] == best_row["model"]:
                vars_used = [descriptors[i] for i in res_data["idx"]]
                n_vars_used = len(res_data["idx"])
                selection_strategy = label
                break

    model_info = pd.DataFrame({
        "Parametro": [
            "Metodo",
            "Pretrattamento",
            "Criterio discriminante",
            "N. Componenti Latenti (LV)",
            "N. Variabili",
            "Strategia selezione variabili",
            "Variabili utilizzate",
            "Cross-Validation",
            "Balanced Accuracy (CV)",
            "Balanced Accuracy (Test)",
            "Sensitivity (Test)",
            "Specificity (Test)",
            "N. campioni Training",
            "N. campioni Test",
            "N. campioni Xeval",
            "Campioni Xeval fuori dominio",
        ],
        "Valore": [
            "PLS-DA (Partial Least Squares Discriminant Analysis)",
            "Autoscaling (media=0, deviazione standard=1)",
            "True Discriminant (argmax: assegnazione alla classe con ŷ maggiore)",
            best_n,
            n_vars_used,
            selection_strategy,
            ", ".join(vars_used),
            "Stratified 10-Fold",
            f"{cv_metrics['balanced_accuracy']:.4f}",
            f"{best_row['balanced_accuracy']:.4f}",
            f"{best_row['sensitivity']:.4f}",
            f"{best_row['specificity']:.4f}",
            X_train.shape[0],
            X_test.shape[0],
            X_eval.shape[0],
            f"{out_eval.sum()} / {len(out_eval)}"
                f" ({100*out_eval.sum()/len(out_eval):.1f}%)",
        ],
    })

    out_file = "previsioni_biodeg.xlsx"
    with pd.ExcelWriter(out_file, engine="openpyxl") as writer:
        df_out.to_excel(writer, index=False, sheet_name="Previsioni")
        model_info.to_excel(writer, index=False, sheet_name="Info_Modello")

    print(f"\n  ✓ Previsioni salvate in: {out_file}")
    print(f"    Foglio 'Previsioni':  classi predette (ordine originale)")
    print(f"    Foglio 'Info_Modello': dettagli modello, pretrattamento, LV, variabili")

    # =====================================================================
    # 7.  CONFRONTO FINALE MODELLI
    # =====================================================================
    print("\n" + "=" * 80)
    print("  CONFRONTO FINALE – MODELLO COMPLETO vs VIP > 1 vs SR > 1")
    print("=" * 80)

    has_vip = "VIP > 1" in strategy_results
    has_sr  = "SR > 1" in strategy_results

    if has_vip:
        vd = strategy_results["VIP > 1"]

        # Raccogli tutte le metriche in modo compatto
        def _acc(y_true, y_pred):
            return np.mean(y_true == y_pred)

        def _bacc(y_true, y_pred):
            s1 = np.sum((y_true == 1) & (y_pred == 1)) / np.sum(y_true == 1)
            s2 = np.sum((y_true == 2) & (y_pred == 2)) / np.sum(y_true == 2)
            return (s1 + s2) / 2

        # --- Completo ---
        acc_cal_c  = _acc(y_train, y_cal_class)
        acc_cv_c   = _acc(y_train, y_cv_pred)
        acc_pred_c = _acc(y_test, y_test_pred)
        bacc_cal_c  = _bacc(y_train, y_cal_class)
        bacc_cv_c   = _bacc(y_train, y_cv_pred)
        bacc_pred_c = _bacc(y_test, y_test_pred)
        overfit_c   = bacc_cal_c - bacc_cv_c

        # --- VIP > 1 ---
        acc_cal_v  = _acc(y_train, y_cal_vip_class)
        acc_cv_v   = _acc(y_train, y_cv_vip_class)
        acc_pred_v = _acc(y_test, y_pred_vip_class)
        bacc_cal_v  = _bacc(y_train, y_cal_vip_class)
        bacc_cv_v   = _bacc(y_train, y_cv_vip_class)
        bacc_pred_v = _bacc(y_test, y_pred_vip_class)
        overfit_v   = bacc_cal_v - bacc_cv_v

        # --- SR > 1 (se presente) ---
        if has_sr:
            sd = strategy_results["SR > 1"]
            acc_cal_s   = _acc(y_train, y_cal_sr_class)
            acc_cv_s    = _acc(y_train, y_cv_sr_class)
            acc_pred_s  = _acc(y_test,  y_pred_sr_class)
            bacc_cal_s  = _bacc(y_train, y_cal_sr_class)
            bacc_cv_s   = _bacc(y_train, y_cv_sr_class)
            bacc_pred_s = _bacc(y_test,  y_pred_sr_class)
            overfit_s   = bacc_cal_s - bacc_cv_s

        # ── Helper per righe a 3 modelli ──
        def _winner3(vc, vv, vs, higher_is_better=True):
            vals = {"Completo": vc, "VIP > 1": vv, "SR > 1": vs}
            best_val = max(vals.values()) if higher_is_better else min(vals.values())
            winners = [k for k, v in vals.items() if abs(v - best_val) < 1e-9]
            return winners[0] if len(winners) == 1 else "Pari"

        def _row3(label, vc, vv, vs, higher_is_better=True):
            winner = _winner3(vc, vv, vs, higher_is_better) if has_sr else (
                "Completo" if (vc > vv + 1e-9 if higher_is_better else vc < vv - 1e-9)
                else ("VIP > 1" if (vv > vc + 1e-9 if higher_is_better else vv < vc - 1e-9)
                      else "Pari"))
            if has_sr:
                return f"  {label:<32s} {vc:>10.4f} {vv:>10.4f} {vs:>10.4f} {winner:>10s}"
            else:
                return f"  {label:<32s} {vc:>12.4f} {vv:>12.4f} {winner:>12s}"

        if has_sr:
            hdr = f"  {'Metrica':<32s} {'Completo':>10s} {'VIP > 1':>10s} {'SR > 1':>10s} {'Migliore':>10s}"
            sep = f"  {'─'*76}"
            print(f"\n  N. Variabili:  {n_vars:>4d} (Completo)  /  {len(vd['idx']):>3d} (VIP>1)  /  {len(sd['idx']):>3d} (SR>1)")
            print(f"  N. LV:         {best_n:>4d} (Completo)  /  {vd['n_lv']:>3d} (VIP>1)  /  {sd['n_lv']:>3d} (SR>1)")
        else:
            hdr = f"  {'Metrica':<32s} {'Completo':>12s} {'VIP > 1':>12s} {'Migliore':>12s}"
            sep = f"  {'─'*70}"
            print(f"\n  N. Variabili:       {n_vars:>5d}       vs  {len(vd['idx']):>5d}")
            print(f"  N. LV:              {best_n:>5d}       vs  {vd['n_lv']:>5d}")

        _s = lambda v: v if has_sr else 0.0  # shorthand per valori SR opzionali

        print()
        print(hdr)
        print(sep)
        print("  ── Calibrazione ──")
        print(_row3("Accuracy (Cal)",      acc_cal_c,  acc_cal_v,  _s(acc_cal_s)  if has_sr else 0))
        print(_row3("Bal. Accuracy (Cal)", bacc_cal_c, bacc_cal_v, _s(bacc_cal_s) if has_sr else 0))
        print(_row3("Sens. Cl.1 (Cal)",   sens_cal[0], sens_cal_v[0], _s(sens_cal_sr[0]) if has_sr else 0))
        print(_row3("Sens. Cl.2 (Cal)",   sens_cal[1], sens_cal_v[1], _s(sens_cal_sr[1]) if has_sr else 0))
        print(_row3("RMSEC (media)",      np.mean(rmse_cal), np.mean(rmse_cal_v), _s(np.mean(rmse_cal_sr)) if has_sr else 0, higher_is_better=False))
        print(_row3("R² Cal",             np.mean(r2_cal), np.mean(r2_cal_v), _s(np.mean(r2_cal_sr)) if has_sr else 0))
        print(sep)
        print("  ── Cross-Validation ──")
        print(_row3("Accuracy (CV)",      acc_cv_c,   acc_cv_v,   _s(acc_cv_s)   if has_sr else 0))
        print(_row3("Bal. Accuracy (CV)", bacc_cv_c,  bacc_cv_v,  _s(bacc_cv_s)  if has_sr else 0))
        print(_row3("Sens. Cl.1 (CV)",   sens_cv[0],  sens_cv_v[0],  _s(sens_cv_sr[0])  if has_sr else 0))
        print(_row3("Sens. Cl.2 (CV)",   sens_cv[1],  sens_cv_v[1],  _s(sens_cv_sr[1])  if has_sr else 0))
        print(_row3("RMSECV (media)",    np.mean(rmse_cv), np.mean(rmse_cv_v), _s(np.mean(rmse_cv_sr)) if has_sr else 0, higher_is_better=False))
        print(_row3("R² CV",             np.mean(r2_cv), np.mean(r2_cv_v), _s(np.mean(r2_cv_sr)) if has_sr else 0))
        print(sep)
        print("  ── Predizione (Test Set) ──")
        print(_row3("Accuracy (Pred)",      acc_pred_c,  acc_pred_v,  _s(acc_pred_s)   if has_sr else 0))
        print(_row3("Bal. Accuracy (Pred)", bacc_pred_c, bacc_pred_v, _s(bacc_pred_s)  if has_sr else 0))
        print(_row3("Sens. Cl.1 (Pred)",   sens_pred[0], sens_pred_v[0], _s(sens_pred_sr[0]) if has_sr else 0))
        print(_row3("Sens. Cl.2 (Pred)",   sens_pred[1], sens_pred_v[1], _s(sens_pred_sr[1]) if has_sr else 0))
        print(_row3("RMSEP (media)",       np.mean(rmse_pred), np.mean(rmse_pred_v), _s(np.mean(rmse_pred_sr)) if has_sr else 0, higher_is_better=False))
        print(_row3("R² Pred",             np.mean(r2_pred), np.mean(r2_pred_v), _s(np.mean(r2_pred_sr)) if has_sr else 0))
        print(sep)
        print("  ── Indicatori Generali ──")
        print(_row3("Overfitting (Cal-CV)", overfit_c, overfit_v, _s(overfit_s) if has_sr else 0, higher_is_better=False))
        auc_sr_val = sd['roc_data_cv'][3] if has_sr else 0.0
        print(_row3("AUC CV",             auc_cv, vd['roc_data_cv'][3], _s(auc_sr_val) if has_sr else 0))
        print(sep)

        # ── Verdetto finale ──
        scores_c, scores_v, scores_s = 0, 0, 0
        checks3 = [
            (bacc_cv_c,   bacc_cv_v,   bacc_cv_s   if has_sr else bacc_cv_v,   True),
            (bacc_pred_c, bacc_pred_v, bacc_pred_s  if has_sr else bacc_pred_v, True),   # peso doppio
            (bacc_pred_c, bacc_pred_v, bacc_pred_s  if has_sr else bacc_pred_v, True),
            (np.mean(rmse_cv), np.mean(rmse_cv_v), np.mean(rmse_cv_sr) if has_sr else np.mean(rmse_cv_v), False),
            (auc_cv, vd['roc_data_cv'][3], auc_sr_val, True),
            (overfit_c, overfit_v, overfit_s if has_sr else overfit_v, False),
        ]
        for vc, vv, vs, higher in checks3:
            best_val = max(vc, vv, vs) if higher else min(vc, vv, vs)
            eps = 1e-9
            if abs(vc - best_val) < eps: scores_c += 1
            if abs(vv - best_val) < eps: scores_v += 1
            if has_sr and abs(vs - best_val) < eps: scores_s += 1

        print()
        if has_sr:
            print(f"  Punteggio:  Completo = {scores_c}  |  VIP > 1 = {scores_v}  |  SR > 1 = {scores_s}")
            best_score = max(scores_c, scores_v, scores_s)
            if scores_c >= best_score and scores_c > scores_v and scores_c > scores_s:
                winner_name = f"COMPLETO ({n_vars} var, {best_n} LV)"
            elif scores_v >= best_score and scores_v > scores_c and scores_v > scores_s:
                winner_name = f"VIP > 1 ({len(vd['idx'])} var, {vd['n_lv']} LV)"
            elif scores_s >= best_score and scores_s > scores_c and scores_s > scores_v:
                winner_name = f"SR > 1 ({len(sd['idx'])} var, {sd['n_lv']} LV)"
            else:
                # Pareggio: preferisci il più semplice (meno variabili)
                candidates_tie = {}
                if scores_c == best_score: candidates_tie["COMPLETO"] = n_vars
                if scores_v == best_score: candidates_tie[f"VIP > 1"] = len(vd['idx'])
                if scores_s == best_score: candidates_tie[f"SR > 1"] = len(sd['idx'])
                simplest = min(candidates_tie, key=candidates_tie.get)
                winner_name = f"{simplest} – scelto per parsimonia"
        else:
            print(f"  Punteggio:  Completo = {scores_c}  |  VIP > 1 = {scores_v}")
            if scores_c > scores_v:
                winner_name = f"COMPLETO ({n_vars} var, {best_n} LV)"
            elif scores_v > scores_c:
                winner_name = f"VIP > 1 ({len(vd['idx'])} var, {vd['n_lv']} LV)"
            else:
                winner_name = "PAREGGIO – si preferisce il modello più semplice (VIP > 1)"

        print(f"\n  ★★★  MODELLO VINCITORE: {winner_name}  ★★★")
    else:
        print("\n  Nessun modello VIP > 1 disponibile per il confronto.")

    print()
    print("=" * 80)
    print("  ANALISI COMPLETATA CON SUCCESSO!")
    print("=" * 80)
