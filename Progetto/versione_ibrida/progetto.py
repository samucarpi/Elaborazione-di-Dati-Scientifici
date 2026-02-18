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

    # NUMERO DI COMPONENTI LATENTI
    best_n = 7

    cv_res = compute_cv_scan(X_train_s, y_train_dummy, y_train, max_components=15, cv_folds=10)
    plot_cv_optimization(cv_res, "3_PLSDA/CV_optimization.png", chosen_n=best_n)

    # ── Modello finale ──
    print(f"\n  Fitting PLS-DA finale con {best_n} LV…")
    pls_da = PLSRegression(n_components=best_n, scale=False)
    pls_da.fit(X_train_s, y_train_dummy)

    # Cross-validation confusion matrix (predizioni out-of-fold)
    skf_final = StratifiedKFold(n_splits=10, shuffle=True, random_state=42)
    splits_final = list(skf_final.split(X_train_s, y_train))
    y_cv_pred_dummy = cross_val_predict(pls_da, X_train_s, y_train_dummy, cv=splits_final)

    # Calcolo soglia ottimale tramite curva ROC (Youden's J statistic)
    y_cv_cont = y_cv_pred_dummy[:, 1]   # colonna Biodeg continua (out-of-fold)
    optimal_threshold, fpr_cv, tpr_cv, thresholds_cv, auc_cv = compute_optimal_threshold(y_train, y_cv_cont)
    print(f"\n  Soglia ottimale (ROC, Youden's J): {optimal_threshold:.4f}")
    print(f"  AUC (Cross-Validation):            {auc_cv:.4f}")

    # Classificazione CV con soglia ottimale
    y_cv_pred = np.where(y_cv_cont >= optimal_threshold, 2, 1)
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

    # ── Predizione test set (soglia da CV) ──
    y_test_cont = pls_da.predict(X_test_s)[:, 1]
    y_test_pred = np.where(y_test_cont >= optimal_threshold, 2, 1)
    test_metrics_full = compute_classification_metrics(y_test, y_test_pred, f"Completo ({n_vars} var)")

    print(f"\n  Metriche Test Set (modello completo, {best_n} LV):")
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

    # Grafico y_pred vs campioni (train + test)
    plot_ypred_vs_actual(pls_da, X_train_s, y_train, threshold=optimal_threshold, filename="3_PLSDA/PLSDA_ypred_train.png")
    plot_ypred_vs_actual(pls_da, X_test_s, y_test, threshold=optimal_threshold, filename="3_PLSDA/PLSDA_ypred_test.png")

    # Y Predicted Plot combinato (Training + Test) con entrambe le colonne dummy
    plot_ypred_combined(pls_da, X_train_s, y_train, X_test_s, y_test,
                        threshold=optimal_threshold,
                        filename="3_PLSDA/PLSDA_ypred_combined.png")

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
        # Soglia ROC ottimale per il modello ridotto
        y_cv_cont_sel = y_cv_sel[:, 1]
        thresh_sel, fpr_sel, tpr_sel, thresholds_sel, auc_sel = \
            compute_optimal_threshold(y_train, y_cv_cont_sel)

        # Classificazione CV con soglia ottimale del modello ridotto
        y_cv_sel_class = np.where(y_cv_cont_sel >= thresh_sel, 2, 1)
        m_cv = compute_classification_metrics(
            y_train, y_cv_sel_class, f"{label} ({len(idx)} var, {n_best} LV)")

        # Classificazione test con soglia ottimale del modello ridotto
        yp_cont = pls_sel.predict(Xts)[:, 1]
        yp = np.where(yp_cont >= thresh_sel, 2, 1)
        m  = compute_classification_metrics(
            y_test, yp, f"{label} ({len(idx)} var, {n_best} LV)")

        # Salva nel dizionario
        strategy_results[label] = {
            "metrics": m, "metrics_cv": m_cv, "model": pls_sel,
            "idx": idx, "n_lv": n_best,
            "bacc_cv": m_cv["balanced_accuracy"],
            "y_cv_pred": y_cv_sel_class,
            "y_cv_cont": y_cv_cont_sel,
            "optimal_threshold": thresh_sel,
            "roc_data_cv": (fpr_sel, tpr_sel, thresholds_sel, auc_sel),
        }

        return m

    # ── VIP > 1 ──
    print()
    res_vip1 = _build_and_evaluate("VIP > 1", vip_scores > 1)
    if res_vip1:
        comparison_rows.append(res_vip1)

    # ── SR > 1 ──
    res_sr1 = _build_and_evaluate("SR > 1", sr_scores > 1)
    if res_sr1:
        comparison_rows.append(res_sr1)

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
        yp_sel_cont = res_data["model"].predict(X_test_s[:, res_data["idx"]])[:, 1]
        yp_sel = np.where(yp_sel_cont >= res_data["optimal_threshold"], 2, 1)
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
        final_model  = pls_da
        final_X_eval = X_eval_s
        model_type   = "completo"
        eval_threshold = optimal_threshold
    else:
        # Cerca nel dizionario dei risultati
        found = False
        for label, res_data in strategy_results.items():
            if res_data["metrics"]["model"] == best_row["model"]:
                final_model  = res_data["model"]
                final_X_eval = X_eval_s[:, res_data["idx"]]
                model_type   = f"ridotto ({label})"
                eval_threshold = res_data["optimal_threshold"]
                # Confusion matrix del modello ridotto migliore
                y_test_pred_best_cont = final_model.predict(X_test_s[:, res_data["idx"]])[:, 1]
                y_test_pred_best = np.where(y_test_pred_best_cont >= eval_threshold, 2, 1)
                plot_confusion_matrix(
                    y_test, y_test_pred_best,
                    f"Confusion Matrix - Test (Miglior Ridotto)\n",
                    f"{best_row['model']}",
                    "5_Selezione/Confusion_matrix_best_reduced.png",
                )
                found = True
                break
        if not found:
            final_model  = pls_da
            final_X_eval = X_eval_s
            model_type   = "completo"
            eval_threshold = optimal_threshold

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

    y_eval_cont = final_model.predict(final_X_eval)[:, 1]
    y_eval_pred = np.where(y_eval_cont >= eval_threshold, 2, 1)

    # Grafico y_pred vs campioni per Xeval
    plot_ypred_eval(final_model, final_X_eval, threshold=eval_threshold,
                    filename="3_PLSDA/PLSDA_ypred_eval.png")

    n1 = int((y_eval_pred == 1).sum())
    n2 = int((y_eval_pred == 2).sum())
    print(f"\n  Modello utilizzato: {model_type}")
    print(f"\n  Previsioni Xeval ({len(y_eval_pred)} campioni):")
    print(f"    Classe 1 (Non Biodeg): {n1} ({100*n1/len(y_eval_pred):.1f}%)")
    print(f"    Classe 2 (Biodeg):     {n2} ({100*n2/len(y_eval_pred):.1f}%)")

    df_out = pd.DataFrame({
        "Sample_ID": range(1, len(y_eval_pred) + 1),
        "Predicted_Class": y_eval_pred,
        "Class_Label": np.where(y_eval_pred == 1, "Non Biodegradabile", "Biodegradabile"),
        "Dominio": np.where(out_eval, "No", "Sì"),
        "Affidabilità": np.where(out_eval, "Bassa", "Alta"),
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
            f"Soglia ROC ottimale (Youden's J) = {eval_threshold:.4f}",
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

    print("=" * 80)
    print("  ANALISI COMPLETATA CON SUCCESSO!")
    print("=" * 80)
