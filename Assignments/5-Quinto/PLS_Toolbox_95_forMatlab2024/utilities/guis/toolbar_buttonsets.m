function btnlist = toolbar_buttonsets(analysis)
%TOOLBAR_BUTTONSETS Defines standard button sets for analysis methods.
% This is a helper function for TOOLBAR and is called to retrieve a list of
% buttons and assocaited information appropriate for a given analysis mode.
%
%I/O: btnlist = toolbar_buttonsets(analysis)
%
%See also: GETTBICONS TOOLBAR TOOLBAR_BUTTONSETS

% Copyright © Eigenvector Research, Inc. 2007
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin<1 || ~ischar(analysis) || isempty(analysis)
  analysis = '';
end

if exist(['toolbar_' analysis])
  %check for "toolbar_zzz" function (where zzz = analysis method
  %specified) If found, call that for button list.
  btnlist = feval(['toolbar_' analysis]);
  
else
  %no special toolbar_zzz function found, use one of the standard methods
  
  switch lower(analysis)
    
    case {'pca' 'mcr'}
      btnlist = {
        'evri'   'evri'       'browse'                                                    'enable'  'View Workspace Browser'             'off'  'push'
        'options' 'setopts'   'analysis(''editoptions'',gcbo,[],guidata(gcbo))'           'enable'  'Edit Analysis Method Options'       'on'   'push'
        'snapshot' 'snapshot' 'modeloptimizergui(''clientsnapshot'',gcbf)'     'enable'  'Take snapshot of current Analysis settings.'     'on'   'push'
        'calc'   'calcmodel'  'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'    'disable' 'Calculate/Apply Model'              'on'   'push'
        'stats'  'ploteigen'  'pca_guifcn(''ploteigen_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot Eigenvalues/Cross-validation results'            'off'  'push'
        'scores' 'plotscores' 'pca_guifcn(''plotscores_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Plot scores and sample statistics'  'off'  'push'
        'loads'  'plotloads'  'pca_guifcn(''plotloads_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot loads and variable statistics' 'off'  'push'
        'biplot' 'biplot'     'pca_guifcn(''biplot_Callback'',gcbo,[],guidata(gcbo))'     'disable' 'Scores and loadings biplots'        'off'  'push'
        'xhat'     'plotxhat'     'pca_guifcn(''plotdatahat_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot data estimate and residuals'   'off'  'push'
        };
      
    case 'pls'
      btnlist = {
        'evri'   'evri'       'browse'                                                    'enable'  'View Workspace Browser'           'off'  'push'
        'options' 'setopts'   'analysis(''editoptions'',gcbo,[],guidata(gcbo))'           'enable'  'Edit Analysis Method Options'                     'on'   'push'
        'snapshot' 'snapshot' 'modeloptimizergui(''clientsnapshot'',gcbf)'     'enable'  'Take snapshot of current Analysis settings.'     'on'   'push'
        'calc'   'calcmodel'  'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'    'disable' 'Calculate/Apply Model'              'on'  'push'
        'stats'  'ploteigen'  'pca_guifcn(''ploteigen_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot Variance captured/Cross-validation results'      'off'  'push'
        'scores' 'plotscores' 'pca_guifcn(''plotscores_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Plot scores and sample statistics'  'off'  'push'
        'loads'  'plotloads'  'pca_guifcn(''plotloads_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot loads and variable statistics' 'off'  'push'
        'yloads' 'plotyloads' 'reg_guifcn(''plotyloads_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Plot loads and variable statistics for y-block' 'off'  'push'
        'biplot' 'biplot'     'pca_guifcn(''biplot_Callback'',gcbo,[],guidata(gcbo))'     'disable' 'Scores and loadings biplots'        'off'  'push'
        'xhat'     'plotxhat'     'pca_guifcn(''plotdatahat_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot data estimate and residuals'   'off'  'push'
        };
      
    case 'npls'
      btnlist = {
        'evri'     'evri'         'browse'                                                    'enable'  'View Workspace Browser'           'off'  'push'
        'options'  'setopts'      'analysis(''editoptions'',gcbo,[],guidata(gcbo))'           'enable'  'Edit Analysis Method Options'                     'on'   'push'
        'snapshot' 'snapshot' 'modeloptimizergui(''clientsnapshot'',gcbf)'     'enable'  'Take snapshot of current Analysis settings.'     'on'   'push'
        'calc'     'calcmodel'    'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'    'disable' 'Calculate/Apply Model'              'on'  'push'
        'stats'    'ploteigen'    'pca_guifcn(''ploteigen_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot Variance captured/Cross-validation results'      'off'  'push'
        'scores'   'plotscores'   'pca_guifcn(''plotscores_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Plot scores and sample statistics'  'off'  'push'
        'loads'    'plotloads'    'parafac_guifcn(''plotloads_Callback'',gcbo,[],guidata(gcbo))'    'disable' 'Plot loadings and other statistics' 'off'  'push'
        'loadsurf' 'plotloadsurf' 'parafac_guifcn(''plot3dcomp_Callback'',gcbo,[],guidata(gcbo))'   'disable' 'Plot 2D Loading Surfaces'           'off'  'push'
        'yloads'   'plotyloads'   'reg_guifcn(''plotyloads_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Plot loads and variable statistics for y-block' 'off'  'push'
        'xhat'     'plotxhat'     'pca_guifcn(''plotdatahat_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot data estimate and residuals'   'off'  'push'
        'viewmodl' 'modelviewer'  'parafac_guifcn(''modelviewer_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'View Model Details'                 'on'  'push'
        };
      
    case 'pcr'
      btnlist = {
        'evri'   'evri'       'browse'                                                    'enable'  'View Workspace Browser'           'off'  'push'
        'options' 'setopts'   'analysis(''editoptions'',gcbo,[],guidata(gcbo))'           'enable'  'Edit Analysis Method Options'                     'on'   'push'
        'snapshot' 'snapshot' 'modeloptimizergui(''clientsnapshot'',gcbf)'     'enable'  'Take snapshot of current Analysis settings.'     'on'   'push'
        'calc'   'calcmodel'  'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'    'disable' 'Calculate/Apply Model'              'on'  'push'
        'stats'  'ploteigen'  'pca_guifcn(''ploteigen_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot Variance captured/Cross-validation results'      'off'  'push'
        'scores' 'plotscores' 'pca_guifcn(''plotscores_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Plot scores and sample statistics'  'off'  'push'
        'loads'  'plotloads'  'pca_guifcn(''plotloads_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot loads and variable statistics' 'off'  'push'
        'biplot' 'biplot'     'pca_guifcn(''biplot_Callback'',gcbo,[],guidata(gcbo))'     'disable' 'Scores and loadings biplots'        'off'  'push'
        'xhat'   'plotxhat'     'pca_guifcn(''plotdatahat_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot data estimate and residuals'   'off'  'push'
        };
      
    case 'mlr'
      btnlist = {
        'evri'   'evri'       'browse'                                                    'enable'  'View Workspace Browser'           'off'  'push'
        'options' 'setopts'   'analysis(''editoptions'',gcbo,[],guidata(gcbo))'           'enable'  'Edit Analysis Method Options'                     'on'   'push'
        'snapshot' 'snapshot' 'modeloptimizergui(''clientsnapshot'',gcbf)'     'enable'  'Take snapshot of current Analysis settings.'     'on'   'push'
        'calc'   'calcmodel'  'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'    'disable' 'Calculate/Apply Model'              'on'  'push'
        'scores' 'plotscores' 'pca_guifcn(''plotscores_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Plot scores and sample statistics'  'off'  'push'
        'loads'  'plotloads'  'pca_guifcn(''plotloads_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot loads and variable statistics' 'off'  'push'
        'add_dataset' 'make_doe_y' 'doe_guifcn(''makedoey_Callback'',gcbo,[],guidata(gcbo))'  'disable'  'Add Y Block for current DOE Dataset.'        'off'   'push'
        'texttable'           'anova'  'doe_guifcn(''anova_Callback'',gcbo,[],guidata(gcbo))'           'disable'  'View ANOVA Table'           'on'   'push'
        'halfnorm'        'plothalfnorm'  'doe_guifcn(''plothalfnorm_Callback'',gcbo,[],guidata(gcbo))'    'disable'  'Open Half-Norm plot'          'off'  'push'
        'doe_effects_plot'    'doeeffects'  'doe_guifcn(''doeeffectsplot_Callback'',gcbo,[],guidata(gcbo))'  'disable'  'Open DOE Effects Plot'        'off'   'push'
        };
      
    case 'cls'
      btnlist = {
        'evri'   'evri'       'browse'                                                    'enable'  'View Workspace Browser'           'off'  'push'
        'options' 'setopts'    'analysis(''editoptions'',gcbo,[],guidata(gcbo))'           'enable'  'Edit Analysis Method Options'                     'on'   'push'
        'snapshot' 'snapshot' 'modeloptimizergui(''clientsnapshot'',gcbf)'     'enable'  'Take snapshot of current Analysis settings.'     'on'   'push'
        'calc'   'calcmodel'  'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'    'disable' 'Calculate/Apply Model'              'on'   'push'
        'scores' 'plotscores' 'pca_guifcn(''plotscores_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Plot scores and sample statistics'  'off'  'push'
        'loads'  'plotloads'  'pca_guifcn(''plotloads_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot loads and variable statistics' 'off'  'push'
        'biplot' 'biplot'     'pca_guifcn(''biplot_Callback'',gcbo,[],guidata(gcbo))'     'disable' 'Scores and loadings biplots'        'off'  'push'
        'xhat'     'plotxhat'     'pca_guifcn(''plotdatahat_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot data estimate and residuals'   'off'  'push'
        };
      
    case 'plsda'
      btnlist = {
        'evri'   'evri'       'browse'                                                      'enable'  'View Workspace Browser'              'off'   'push'
        'options' 'setopts'   'analysis(''editoptions'',gcbo,[],guidata(gcbo))'             'enable'  'Edit Analysis Method Options'        'on'    'push'
        'snapshot' 'snapshot' 'modeloptimizergui(''clientsnapshot'',gcbf)'     'enable'  'Take snapshot of current Analysis settings.'     'on'   'push'
        'modelbuild'   'choosegrps'  'plsda_guifcn(''choosegrps_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Select Class Groups'          'on'    'push'
        'calc'   'calcmodel'  'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'      'disable'    'Calculate/Apply Model'            'off'   'push'
        'stats'  'ploteigen'  'pca_guifcn(''ploteigen_Callback'',gcbo,[],guidata(gcbo))'    'disable' 'Plot Variance captured/Cross-validation results'       'off'   'push'
        'scores' 'plotscores' 'plsda_guifcn(''plotscores_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Plot scores and sample statistics'   'off'   'push'
        'loads'  'plotloads'  'pca_guifcn(''plotloads_Callback'',gcbo,[],guidata(gcbo))'    'disable' 'Plot loads and variable statistics'  'off'   'push'
        'yloads' 'plotyloads' 'reg_guifcn(''plotyloads_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Plot loads and variable statistics for y-block' 'off'  'push'
        'biplot' 'biplot'     'pca_guifcn(''biplot_Callback'',gcbo,[],guidata(gcbo))'       'disable' 'Scores and loadings biplots'         'off'   'push'
        'xhat'   'plotxhat'   'pca_guifcn(''plotdatahat_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot data estimate and residuals'    'off'  'push'
        'roc'    'threshold'  'plsda_guifcn(''threshold_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot ROC and Threshold'              'on'   'push'
        'table_confusion'     'showconfusion'     'plsda_guifcn(''showconfusion_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Show confusion matrix and table.'   'off'  'push'
        };
      
    case 'cluster'
      btnlist = {
        'evri'   'evri'       'browse'                                                    'enable'  'View Workspace Browser'           'off'  'push'
        'calc'   'calcmodel'  'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'    'disable' 'Perform Cluster Analysis'           'on'   'push'
        };
      
    case 'knn'
      btnlist = {
        'evri'   'evri'       'browse'                                                    'enable'  'View Workspace Browser'              'off'  'push'
        'options' 'setopts'   'analysis(''editoptions'',gcbo,[],guidata(gcbo))'           'enable'  'Edit Analysis Method Options'       'on'   'push'
        'snapshot' 'snapshot' 'modeloptimizergui(''clientsnapshot'',gcbf)'     'enable'  'Take snapshot of current Analysis settings.'     'on'   'push'
        'modelbuild'   'choosegrps'  'plsda_guifcn(''choosegrps_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Select Class Groups'          'on'    'push'
        'calc'   'calcmodel'  'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'    'disable' 'Perform KNN Classification Analysis' 'on'   'push'
        'stats'  'ploteigen'  'pca_guifcn(''ploteigen_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot Eigenvalues/Cross-validation results'            'off'  'push'
        'scores' 'plotscores' 'pca_guifcn(''plotscores_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Plot sample classification information' 'off'   'push'
        'table_confusion'     'showconfusion'     'plsda_guifcn(''showconfusion_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Show confusion matrix and table.'   'off'  'push'
        };
      
    case 'purity'
      btnlist = {
        'evri'   'evri'       'browse'                                                      'enable'  'View Workspace Browser'           'off'  'push'
        'options' 'setopts'   'analysis(''editoptions'',gcbo,[],guidata(gcbo))'                    'enable'  'Edit Analysis Method Options'                 'on'   'push'
        'calc'   'calcmodel'  'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'      'disable' 'Perform Purity Analysis'            'on'   'push'
        'stats'  'ploteigen'  'pca_guifcn(''ploteigen_Callback'',gcbo,[],guidata(gcbo))'    'disable' 'Plot Eigenvalues/Cross-validation results'            'off'  'push'
        'scores' 'plotscores' 'pca_guifcn(''plotscores_Callback'',gcbo,[],guidata(gcbo))'   'disable' 'Plot scores and sample statistics'  'off'  'push'
        'loads'  'plotloads'  'purity_guifcn(''plotloads_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Plot loads and variable statistics' 'off'  'push'
        'biplot' 'biplot'     'pca_guifcn(''biplot_Callback'',gcbo,[],guidata(gcbo))'       'disable' 'Scores and loadings biplots'        'off'  'push'
        };
      
    case 'puritymainfig'
      %Goes on purity figure, not analysis figure.
      btnlist = {
        'evri'                'evri'              'browse'                                                              'enable'  'View Workspace Browser'           'off'  'push'
        'SetPureVarOne'       'setone'            'purity_guifcn(''setone_Callback'',gcbo,[],guidata(gcbo))'            'enable'  'Set Pure Variable'               'on'   'push'
        'ResetLastVar'        'reset'             'purity_guifcn(''reset_Callback'',gcbo,[],guidata(gcbo))'             'enable'  'Reset Last Variable'             'off'  'push'
        'PlotAtCursor'        'plotcursor'        'purity_guifcn(''plotcursor_Callback'',gcbo,[],guidata(gcbo))'        'enable'  'Plot At Cursor'                      'on'   'push'
        'Cursor'              'cursor'            'purity_guifcn(''cursor_Callback'',gcbo,[],guidata(gcbo))'            'enable'  'Cursor'                          'off'  'push'
        'IncreaseOffsetOne'   'offsetoneincrease' 'purity_guifcn(''offsetoneincrease_Callback'',gcbo,[],guidata(gcbo))' 'enable'  'Increase Offset'                 'on'   'push'
        'DecreaseOffsetOne'   'offsetonedecrease' 'purity_guifcn(''offsetonedecrease_Callback'',gcbo,[],guidata(gcbo))' 'enable'  'Decrease Offset'                 'off'  'push'
        'WinDerIncrease'      'winderincrease'    'purity_guifcn(''winderincrease_Callback'',gcbo,[],guidata(gcbo))'    'enable'  'Window Derivative Increase'      'off'  'push'
        'WinDerDecrease'      'winderdecrease'    'purity_guifcn(''winderdecrease_Callback'',gcbo,[],guidata(gcbo))'    'disable' 'Window Derivative Decrease'      'off'  'push'
        'calc'                'tbresolve'         'purity_guifcn(''resolve_Callback'',gcbo,[],guidata(gcbo))'           'enable'  'Resolve Components'              'on'   'push'
        'ok'                  'tbaccept'          'purity_guifcn(''accept_Callback'',gcbo,[],guidata(gcbo))'            'enable'  'Accept Model'                    'off'  'push'
        };
      
    case 'puritymainfig_der'
      %Goes on purity figure, not analysis figure.
      %Second toolbar.
      btnlist = {
        'space' 'space1' '' '' '' '' ''
        'space' 'space2' '' '' '' '' ''
        'SetPureVarTwoV7'   'settwo'            'purity_guifcn(''settwo_Callback'',gcbo,[],guidata(gcbo))'            'enable'  'Set Derivative Pure Variable'           'on'   'push'
        };
      
    case 'parafac'
      btnlist = {
        'evri'     'evri'         'browse'                                                          'enable'  'View Workspace Browser'             'off'  'push'
        'options'  'setopts'      'analysis(''editoptions'',gcbo,[],guidata(gcbo))'                 'enable'  'Edit Analysis Method Options'       'on'   'push'
        'snapshot' 'snapshot' 'modeloptimizergui(''clientsnapshot'',gcbf)'     'enable'  'Take snapshot of current Analysis settings.'     'on'   'push'
        'calc'     'calcmodel'    'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'          'disable' 'Calculate/Apply Model'              'on'   'push'
        'core_consist'     'corecondia'   'parafac_guifcn(''plotcorecondia'',gcbo,[],guidata(gcbo))'        'disable' 'Plot core consistency information'  'off'  'push'
        'scores'   'plotscores'   'pca_guifcn(''plotscores_Callback'',gcbo,[],guidata(gcbo))'       'disable' 'Plot scores and sample statistics'  'off'  'push'
        'loads'    'plotloads'    'parafac_guifcn(''plotloads_Callback'',gcbo,[],guidata(gcbo))'    'disable' 'Plot loadings and other statistics' 'off'  'push'
        'loadsurf' 'plotloadsurf' 'parafac_guifcn(''plot3dcomp_Callback'',gcbo,[],guidata(gcbo))'   'disable' 'Plot 2D Loading Surfaces'           'off'  'push'
        'xhat'     'plotxhat'     'pca_guifcn(''plotdatahat_Callback'',gcbo,[],guidata(gcbo))'      'disable' 'Plot data estimate and residuals'   'off'  'push'
        'splithalf' 'splithalf'   'parafac_guifcn(''splithalf_Callback'',gcbo,[],guidata(gcbo))'    'disable' 'Perform Split-Half Analysis'        'on'  'push'
        'viewmodl' 'modelviewer'  'parafac_guifcn(''modelviewer_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'View Model Details'                 'on'  'push'
        };
      
    case 'simca'
      btnlist = {
        'evri'          'evri'       'browse'                                                    'enable'  'View Workspace Browser'           'off'  'push'
        'options'       'setopts'       'simcagui(''analysiseditoptions'',gcbo,[],guidata(gcbo))'                  'enable'  'Edit Analysis Method Options'               'on'   'push'
        'modelbuild'    'modelbuilder'  'simca_guifcn(''modlbuilder_Callback'',gcbo,[],guidata(gcbo))'  'enable' 'Show Simca Model Builder'             'on'   'push'
        'calc'          'calcmodel'     'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'        'disable' 'Calculate/Apply Model'               'off'  'push'
        'stats'         'ploteigen'     'pca_guifcn(''ploteigen_Callback'',gcbo,[],guidata(gcbo))'      'disable' 'Plot Eigenvalues/Cross-validation results'             'off'  'push'
        'scores'        'plotscores'    'simca_guifcn(''plotscores_Callback'',gcbo,[],guidata(gcbo))'   'disable' 'Plot scores and sample statistics'   'off'  'push'
        'loads'         'plotloads'     'pca_guifcn(''plotloads_Callback'',gcbo,[],guidata(gcbo))'      'disable' 'Plot loads and variable statistics'  'off'  'push'
        'biplot'        'biplot'        'pca_guifcn(''biplot_Callback'',gcbo,[],guidata(gcbo))'         'disable' 'Scores and loadings biplots'         'off'  'push'
        'table_confusion'     'showconfusion'     'plsda_guifcn(''showconfusion_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Show confusion matrix and table.'   'off'  'push'
        };
      
    case 'corrspec'
      btnlist = {
        'evri'                'evri'              'browse'                                                                 'enable'  'View Workspace Browser'                        'off'  'push'
        'Settings'            'settings'          'corrspecgui(''settings_Callback'',gcbo,[],guidata(gcbo))'               'enable'  'Toggle settings display.'                      'on'   'toggle'
        'SetPureVarOne'       'setone'            'corrspecgui(''setone_Callback'',gcbo,[],guidata(gcbo))'                 'enable'  'Set Pure Variable'                             'on'   'push'
        'ResetLastVar'        'reset'             'corrspecgui(''reset_Callback'',gcbo,[],guidata(gcbo))'                  'enable'  'Reset Last Variable'                           'off'  'push'
        'Max'                 'max'               'corrspecgui(''max_Callback'',gcbo,[],guidata(gcbo))'                    'enable'  'Move cursor to max.'                           'off'  'push'
        'PlotAtCursor'        'plotcursor'        'corrspecgui(''plotcursor_Callback'',gcbo,[],guidata(gcbo))'             'enable'  'Plot At Cursor'                                'off'   'push'
        'InactivateX'         'inactivatex'       'corrspecgui(''inactivatex_Callback'',gcbo,[],guidata(gcbo))'            'enable'  'Inactivate X Selected.'                        'on'  'push'
        'InactivateY'         'inactivatey'       'corrspecgui(''inactivatey_Callback'',gcbo,[],guidata(gcbo))'            'enable'  'Inactivate Y Selected.'                        'off'  'push'
        'InactivateXY'        'inactivatexy'      'corrspecgui(''inactivatexy_Callback'',gcbo,[],guidata(gcbo))'           'enable'  'Inactivate XY Selected.'                       'off'  'push'
        'Reactivate'          'reactivate'        'corrspecgui(''reactivate_Callback'',gcbo,[],guidata(gcbo))'             'enable'  'Reactivate last selection.'                    'off'  'push'
        'map3d'               'map3d'             'corrspecgui(''map3d_Callback'',gcbo,[],guidata(gcbo))'                  'enable'  'Plot map in 3D.'                               'on'  'push'
        'Resolve'             'resolve'           'corrspecgui(''resolve_Callback'',gcbo,[],guidata(gcbo))'                'enable'  'Resolve spectra.'                              'on'  'push'
        %'Accept'              'accept'            'corrspecgui(''accept_Callback'',gcbo,[],guidata(gcbo))'                 'enable'  'Accept corrspec model and return to Analysis.' 'on'  'push'
        };
    case {'lwr'}
      btnlist = {
        'evri'    'evri'       'browse'                                                    'enable'  'View Workspace Browser'           'off'  'push'
        'options' 'setopts'    'analysis(''editoptions'',gcbo,[],guidata(gcbo))'           'enable'  'Edit Analysis Method Options'                     'on'   'push'
        'snapshot' 'snapshot' 'modeloptimizergui(''clientsnapshot'',gcbf)'     'enable'  'Take snapshot of current Analysis settings.'     'on'   'push'
        'calc'    'calcmodel'  'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'    'disable' 'Calculate/Apply Model'              'on'  'push'
        'stats'   'ploteigen'  'pca_guifcn(''ploteigen_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot Variance captured/Cross-validation results'      'off'  'push'
        'scores'  'plotscores' 'lwr_guifcn(''plotscores_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Plot scores and sample statistics'  'off'  'push'
        'loads'   'plotloads'  'lwr_guifcn(''plotloads_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot loads and variable statistics' 'off'  'push'
        'xhat'     'plotxhat'     'pca_guifcn(''plotdatahat_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot data estimate and residuals'   'off'  'push'
        };
    case {'svm'}
      btnlist = {
        'evri'    'evri'       'browse'                                                    'enable'  'View Workspace Browser'           'off'  'push'
        'options' 'setopts'    'analysis(''editoptions'',gcbo,[],guidata(gcbo))'           'enable'  'Edit Analysis Method Options'                     'on'   'push'
        'snapshot' 'snapshot' 'modeloptimizergui(''clientsnapshot'',gcbf)'     'enable'  'Take snapshot of current Analysis settings.'     'on'   'push'
        'modelbuild'   'choosegrps'  'plsda_guifcn(''choosegrps_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Select Class Groups'          'on'    'push'
        'calc'    'calcmodel'  'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'    'disable' 'Calculate/Apply Model'              'off'  'push'
        'stats'   'ploteigen'  'svm_guifcn(''ploteigen_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot Variance captured/Cross-validation results'      'off'  'push'
        'scores'  'plotscores' 'svm_guifcn(''plotscores_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Plot scores and sample statistics'  'off'  'push'
        'table_confusion'     'showconfusion'     'plsda_guifcn(''showconfusion_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Show confusion matrix and table.'   'off'  'push'
        };
    case 'aligntool'
      btnlist = [
        {'plot'       'plotall'      'aligntool(''plot_Callback'',gcbo,[],guidata(gcbo))'       'enable'  'Open All Data in PlotGUI'                       'off'    'push'};
        {'Zoom'       'zoomin'       'aligntool(''zoom_Callback'',gcbo,[],guidata(gcbo))'       'disable' 'Toggle Zoom (double-click to zoom out)'  'off'   'toggle'};
        ];
      
    case 'browse'
      btnlist ={
        'evri'       'evri'       'browse(''refresh'',gcf);'        'enable' 'Refresh Browser'            'off'   'push'
        'new'        'new'        'editds(''filenew'',editds);'     'enable' 'New dataset'                'on'    'push'
        'import'     'import'     'autoimport;'                     'enable' 'Import data'                'off'   'push'
        'open'       'tbwsload'   'browse(''workspace'',''load'')'  'enable' 'Load workspace'             'on'    'push'
        'save'       'tbwssave'   'browse(''workspace'',''save'')'  'enable' 'Save workspace'             'off'   'push'
        };
    case 'doegui'
      btnlist = {
         'evri'         'evri'           'browse'                                                     'enable'  'View Workspace Browser'                       'off'    'push'
         'calc'         'calcdoe'        'doegui(''calcdoe_Callback'',gcbo,[],guidata(gcbo))'         'enable'  'Regenerate DOE (rerandomize).'                            'on'     'push' 
         'addrow'       'addfactor'      'doegui(''addfactor_Callback'',gcbo,[],guidata(gcbo))'       'enable'  'Add a new factor to design.'                  'off'    'push' 
         'deleterow'    'deletefactor'   'doegui(''deletefactor_Callback'',gcbo,[],guidata(gcbo))'    'enable'  'Remove current factor from design.'           'off'    'push' 
         'table_export' 'toanalysis'     'doegui(''exporttoanalysis_Callback'',gcbo,[],guidata(gcbo))' 'enable' 'Export DOE dataset to MLR.'                  'off'    'push'
         'plot'         'plotdata'       'doegui(''plot_Callback'',gcbo,[],guidata(gcbo),''data'')'   'enable' 'Plot DOE data.' 'off' 'push'
         'table_confusion'  'plotconfusion'  'doegui(''plot_Callback'',gcbo,[],guidata(gcbo),''confusion'')'  'disable' 'Show confusion table for a fractional factorial DOE.' 'off' 'push'
         'leverage'         'plotleverage'   'doegui(''plot_Callback'',gcbo,[],guidata(gcbo),''leverage'')'  'enable' 'Plot leverage.' 'off' 'push'
         };
    case 'batchmaturity'
      btnlist = {
        'evri'   'evri'       'browse'                                                    'enable'  'View Workspace Browser'             'off'  'push'
        'options' 'setopts'   'analysis(''editoptions'',gcbo,[],guidata(gcbo))'           'enable'  'Edit Analysis Method Options'       'on'   'push'
        'snapshot' 'snapshot' 'modeloptimizergui(''clientsnapshot'',gcbf)'     'enable'  'Take snapshot of current Analysis settings.'     'on'   'push'
        'calc'   'calcmodel'  'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'    'disable' 'Calculate/Apply Model'              'on'   'push'
        'stats'  'ploteigen'  'pca_guifcn(''ploteigen_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot Eigenvalues/Cross-validation results'            'off'  'push'
        'scores' 'plotscores' 'batchmaturity_guifcn(''plotscores_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Plot scores and sample statistics'  'off'  'push'
        'loads'  'plotloads'  'pca_guifcn(''plotloads_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot loads and variable statistics' 'off'  'push'
        'biplot' 'biplot'     'pca_guifcn(''biplot_Callback'',gcbo,[],guidata(gcbo))'     'disable' 'Scores and loadings biplots'        'off'  'push'
        'xhat'     'plotxhat'     'pca_guifcn(''plotdatahat_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot data estimate and residuals'   'off'  'push'
        };
    case 'modeloptimizergui'
      btnlist = {
        'evri'     'evri'         'browse'                                                                   'enable'  'View Workspace Browser'                          'off'  'push'
        'options'  'setopts'      'modeloptimizergui(''editoptions'',gcbo,[],guidata(gcbo))'                 'enable'  'Edit Options'                                    'on'   'push'
        'analysis' 'findgui'      'modeloptimizergui(''buttonpush'',gcbo,[],guidata(gcbo),''locate'')'       'enable'  'Find Analysis figure.'                           'on'   'push'
        'snapshot' 'snapshot'     'modeloptimizergui(''buttonpush'',gcbo,[],guidata(gcbo),''snapshot'')'     'enable'  'Take snapshot of current Analysis settings.'     'on'   'push'
        'combinations' 'makerun'  'modeloptimizergui(''buttonpush'',gcbo,[],guidata(gcbo),''addcombos'')'    'enable'  'Add unique combinations to model list.'          'on'   'push'
        'calc'     'runall'       'modeloptimizergui(''buttonpush'',gcbo,[],guidata(gcbo),''run_all'')'      'enable'  'Calculate all models.'                           'off'  'push'
        'plot'     'plottable'    'modeloptimizergui(''buttonpush'',gcbo,[],guidata(gcbo),''plottable'')'    'enable'  'Plot comparison table.'                          'off'  'push'
        'calval'     'addvalidation'    'modeloptimizergui(''buttonpush'',gcbo,[],guidata(gcbo),''loadvaliddata'')'    'enable'  'Load Validation data'                          'off'  'push'
        
        };
    case {'ann'}
      btnlist = {
        'evri'    'evri'       'browse'                                                    'enable'  'View Workspace Browser'           'off'  'push'
        'options' 'setopts'    'analysis(''editoptions'',gcbo,[],guidata(gcbo))'           'enable'  'Edit Analysis Method Options'                     'on'   'push'
        'snapshot' 'snapshot' 'modeloptimizergui(''clientsnapshot'',gcbf)'     'enable'  'Take snapshot of current Analysis settings.'     'on'   'push'
        'modelbuild'   'choosegrps'  'plsda_guifcn(''choosegrps_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Select Class Groups'          'on'    'push'
        'calc'    'calcmodel'  'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'    'disable' 'Calculate/Apply Model'              'off'  'push'
        'stats'   'ploteigen'  'pca_guifcn(''ploteigen_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot Cross-validation results'      'off'  'push'
        'scores'  'plotscores' 'ann_guifcn(''plotscores_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Plot scores and sample statistics'  'off'  'push'
        'table_confusion'     'showconfusion'     'plsda_guifcn(''showconfusion_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Show confusion matrix and table.'   'off'  'push'
         };
    case 'anndl'
      btnlist = {
        'evri'    'evri'       'browse'                                                    'enable'  'View Workspace Browser'           'off'  'push'
        'options' 'setopts'    'analysis(''editoptions'',gcbo,[],guidata(gcbo))'           'enable'  'Edit Analysis Method Options'                     'on'   'push'
        'snapshot' 'snapshot' 'modeloptimizergui(''clientsnapshot'',gcbf)'     'enable'  'Take snapshot of current Analysis settings.'     'on'   'push'
        'modelbuild'   'choosegrps'  'plsda_guifcn(''choosegrps_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Select Class Groups'          'on'    'push'
        'calc'    'calcmodel'  'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'    'disable' 'Calculate/Apply Model'              'off'  'push'
        'stats'   'ploteigen'  'pca_guifcn(''ploteigen_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot Cross-validation results'      'off'  'push'
        'scores'  'plotscores' 'anndl_guifcn(''plotscores_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Plot scores and sample statistics'  'off'  'push'
        'loads'  'plotloads'  'pca_guifcn(''plotloads_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot loss' 'off'  'push'
        };
    case 'anndlda'
      btnlist = {
        'evri'    'evri'       'browse'                                                    'enable'  'View Workspace Browser'           'off'  'push'
        'options' 'setopts'    'analysis(''editoptions'',gcbo,[],guidata(gcbo))'           'enable'  'Edit Analysis Method Options'                     'on'   'push'
        'snapshot' 'snapshot' 'modeloptimizergui(''clientsnapshot'',gcbf)'     'enable'  'Take snapshot of current Analysis settings.'     'on'   'push'
        'modelbuild'   'choosegrps'  'plsda_guifcn(''choosegrps_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Select Class Groups'          'on'    'push'
        'calc'    'calcmodel'  'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'    'disable' 'Calculate/Apply Model'              'off'  'push'
        'stats'   'ploteigen'  'pca_guifcn(''ploteigen_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot Cross-validation results'      'off'  'push'
        'scores'  'plotscores' 'anndl_guifcn(''plotscores_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Plot scores and sample statistics'  'off'  'push'
        'loads'  'plotloads'  'pca_guifcn(''plotloads_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot loss' 'off'  'push'
        'table_confusion'     'showconfusion'     'plsda_guifcn(''showconfusion_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Show confusion matrix and table.'   'off'  'push'
        'roc'    'threshold'  'plsda_guifcn(''threshold_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot ROC and Threshold'              'on'   'push' 
        };
    case 'asca'
      btnlist = {
        'evri'   'evri'       'browse'                                                     'enable'  'View Workspace Browser'               'off'  'push'
        'options' 'setopts'   'analysis(''editoptions'',gcbo,[],guidata(gcbo))'            'enable'  'Edit Analysis Method Options'         'on'   'push'
        'boxplot2' 'ploteffect' 'asca_guifcn(''plotvareffects'',gcbo,[],guidata(gcbo))'        'disable' 'Variable Effects Plot'                'on'  'push'
        'calc'   'calcmodel'  'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'     'disable' 'Calculate Model'                'on'   'push'
        'scores' 'plotscores' 'asca_guifcn(''plotscores_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Plot sample classification information' 'off'   'push'
        'loads'  'plotloads'  'asca_guifcn(''plotloads_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot loads and variable statistics'   'off'  'push'
        };
      
     case 'multiblocktool'
      btnlist = {
        'evri'          'evri'       'browse'                                                           'enable'  'View Workspace Browser'       'off'  'push'
        'options'       'setopts'    'multiblocktool(''toolbar_Callback'',gcbo,[],guidata(gcbo))'       'enable'  'Edit Method Options'          'on'   'push'
        'calc'          'calcmodel'  'multiblocktool(''toolbar_Callback'',gcbo,[],guidata(gcbo))'       'disable' 'Join data.'                   'on'   'push'
        'FrwdRevArrow'  'zoomwin'    'multiblocktool(''toolbar_Callback'',gcbo,[],guidata(gcbo))'       'enable'  'Zoom Graph to Window'         'on'   'push'
        'Zoom'          'zoomin'     'multiblocktool(''toolbar_Callback'',gcbo,[],guidata(gcbo))'       'enable'  'Zoom In'                      'off'  'push'
        'Unzoom'        'zoomout'    'multiblocktool(''toolbar_Callback'',gcbo,[],guidata(gcbo))'       'enable'  'Zoom Out'                     'off'  'push'
        'onetoone'      'zoomdefault'    'multiblocktool(''toolbar_Callback'',gcbo,[],guidata(gcbo))'       'enable'  'Zoom To Default Scale'        'off'  'push'
        %'add_dataset'   'applynew'   'multiblocktool(''toolbar_Callback'',gcbo,[],guidata(gcbo))'       'enable'  'Apply to new data.'           'on'   'push'
        };
      
     case 'mccttool'
      btnlist = {
        'evri'          'evri'          'browse'  'enable'  'View Workspace Browser'        'off'  'push'
        'options'       'setopts'       ''        'enable'  'Edit Method Options'           'on'   'push'
        'calc'          'calcmodel'     ''        'disable' 'Create secondary model.'           'on'   'push'
        'FrwdRevArrow'  'zoomwin'       ''        'enable'  'Zoom Graph to Window'          'on'   'push'
        'Zoom'          'zoomin'        ''        'enable'  'Zoom In'                       'off'  'push'
        'Unzoom'        'zoomout'       ''        'enable'  'Zoom Out'                      'off'  'push'
        'onetoone'      'zoomdefault' 	''        'enable'  'Zoom to One to One'            'off'  'push'
        %'insertarrow'   'setinsertpp'   ''        'enable'  'Set Location of Preprocessing' 'off'  'push'
        'table_blank'   'maketable'     ''        'enable'  'Export table of results'       'on'  'push'
        %'add_dataset'   'applynew'   'multiblocktool(''toolbar_Callback'',gcbo,[],guidata(gcbo))'       'enable'  'Apply to new data.'           'on'   'push'
        };
      
    case {'xgb'}
      btnlist = {
        'evri'    'evri'       'browse'                                                    'enable'  'View Workspace Browser'           'off'  'push'
        'options' 'setopts'    'analysis(''editoptions'',gcbo,[],guidata(gcbo))'           'enable'  'Edit Analysis Method Options'                     'on'   'push'
        'snapshot' 'snapshot' 'modeloptimizergui(''clientsnapshot'',gcbf)'     'enable'  'Take snapshot of current Analysis settings.'     'on'   'push'
        'modelbuild'   'choosegrps'  'plsda_guifcn(''choosegrps_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Select Class Groups'          'on'    'push'
        'calc'    'calcmodel'  'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'    'disable' 'Calculate/Apply Model'              'off'  'push'
        'stats'   'ploteigen'  'xgb_guifcn(''ploteigen_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot Variance captured/Cross-validation results'      'off'  'push'
        'scores'  'plotscores' 'xgb_guifcn(''plotscores_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Plot scores and sample statistics'  'off'  'push'
        'loads'  'plotloads'   'xgb_guifcn(''plotloads_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot variable importance' 'off'  'push'
        'table_confusion'     'showconfusion'     'plsda_guifcn(''showconfusion_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Show confusion matrix and table.'   'off'  'push'
        };

    case {'lreg'}
      btnlist = {
        'evri'    'evri'       'browse'                                                    'enable'  'View Workspace Browser'           'off'  'push'
        'options' 'setopts'    'analysis(''editoptions'',gcbo,[],guidata(gcbo))'           'enable'  'Edit Analysis Method Options'                     'on'   'push'
        'snapshot' 'snapshot' 'modeloptimizergui(''clientsnapshot'',gcbf)'     'enable'  'Take snapshot of current Analysis settings.'     'on'   'push'
        'modelbuild'   'choosegrps'  'plsda_guifcn(''choosegrps_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Select Class Groups'          'on'    'push'
        'calc'    'calcmodel'  'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'    'disable' 'Calculate/Apply Model'              'off'  'push'
        'loads'  'plotloads'   'pca_guifcn(''plotloads_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot model theta parameters' 'off'  'push'
        'scores'  'plotscores' 'ann_guifcn(''plotscores_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Plot scores and sample statistics'  'off'  'push'
        'table_confusion'     'showconfusion'     'plsda_guifcn(''showconfusion_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Show confusion matrix and table.'   'off'  'push'
         };   

    case {'lda'}
      btnlist = {
        'evri'    'evri'       'browse'                                                    'enable'  'View Workspace Browser'           'off'  'push'
        'options' 'setopts'    'analysis(''editoptions'',gcbo,[],guidata(gcbo))'           'enable'  'Edit Analysis Method Options'                     'on'   'push'
        'snapshot' 'snapshot' 'modeloptimizergui(''clientsnapshot'',gcbf)'     'enable'  'Take snapshot of current Analysis settings.'     'on'   'push'
        'modelbuild'   'choosegrps'  'plsda_guifcn(''choosegrps_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Select Class Groups'          'on'    'push'
        'calc'    'calcmodel'  'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'    'disable' 'Calculate/Apply Model'              'off'  'push'
        'stats'   'ploteigen'  'pca_guifcn(''ploteigen_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot Variance captured/Cross-validation results'      'off'  'push'
        'loads'  'plotloads'   'pca_guifcn(''plotloads_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot Model Weights' 'off'  'push'
        'scores'  'plotscores' 'ann_guifcn(''plotscores_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Plot scores and sample statistics'  'off'  'push'
        'table_confusion'     'showconfusion'     'plsda_guifcn(''showconfusion_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Show confusion matrix and table.'   'off'  'push'
         }; 
     
     case {'tsne'}
      btnlist = {
        'evri'   'evri'       'browse'                                                    'enable'  'View Workspace Browser'             'off'  'push'
        'options' 'setopts'   'analysis(''editoptions'',gcbo,[],guidata(gcbo))'           'enable'  'Edit Analysis Method Options'       'on'   'push'
        'snapshot' 'snapshot' 'modeloptimizergui(''clientsnapshot'',gcbf)'     'enable'  'Take snapshot of current Analysis settings.'     'on'   'push'
        'calc'   'calcmodel'  'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'    'disable' 'Calculate/Apply Model'              'on'   'push'
        %'stats'  'ploteigen'  'tsne_guifcn(''ploteigen_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot Eigenvalues/Cross-validation results'            'off'  'push'
        'scores' 'plotscores' 'tsne_guifcn(''plotscores_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Plot embeddings and sample statistics'  'off'  'push'
        %'loads'  'plotloads'  'tsne_guifcn(''plotloads_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot loads and variable statistics' 'off'  'push'
        };
    
    case {'umap'}
      btnlist = {
        'evri'   'evri'       'browse'                                                    'enable'  'View Workspace Browser'             'off'  'push'
        'options' 'setopts'   'analysis(''editoptions'',gcbo,[],guidata(gcbo))'           'enable'  'Edit Analysis Method Options'       'on'   'push'
        'snapshot' 'snapshot' 'modeloptimizergui(''clientsnapshot'',gcbf)'     'enable'  'Take snapshot of current Analysis settings.'     'on'   'push'
        'calc'   'calcmodel'  'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'    'disable' 'Calculate/Apply Model'              'on'   'push'
        'flask_circle'  'ploteigen'  'umap_guifcn(''ploteigen_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Generate Connectivity Graph'            'off'  'push'
        'scores' 'plotscores' 'umap_guifcn(''plotscores_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Plot embeddings and sample statistics'  'off'  'push'
        %'loads'  'plotloads'  'umap_guifcn(''plotloads_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot loads and variable statistics' 'off'  'push'
        };
    
    case 'clsti'
      btnlist = {
        'evri'    'evri'          'browse'                                                    'enable'  'View Workspace Browser'             'off'  'push'
        'options' 'setopts'       'analysis(''editoptions'',gcbo,[],guidata(gcbo))'           'enable'  'Edit Analysis Method Options'       'on'   'push'
        'calc'   'calcmodel'     'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'    'enable'  'Calculate/Apply Model'              'on'   'push'
        'tabone'  'clstiBuilder'  'clsti_guifcn(''clstiModelBuilder_callback'',gcbo,[],guidata(gcbo))' 'enable'  'Open CLSTI Model Builder'           'off'  'push'
        'scores' 'plotscores' 'pca_guifcn(''plotscores_Callback'',gcbo,[],guidata(gcbo))' 'disable' 'Plot scores and sample statistics'  'off'  'push'
        'loads'  'plotloads'  'pca_guifcn(''plotloads_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot loads and variable statistics' 'off'  'push'
        %'xhat'     'plotxhat'     'pca_guifcn(''plotdatahat_Callback'',gcbo,[],guidata(gcbo))'  'disable' 'Plot data estimate and residuals'   'off'  'push'
        };
      
    otherwise
      
      btnlist = {
        'evri'   'evri' 'browse'         'enable' 'View Workspace Browser' 'off'  'push'
        };
  end
  
end

%call any toolbar_buttonsets add-on product changes.
fns = evriaddon('toolbar_buttonsets');
for j=1:length(fns)
  %I/O for any functions connecting into this item are:
  %  btnlist = fn(analysis,btnlist)
  %Where analysis is the string defining the analysis mode and btnlist is
  %the current list of buttons (default). This list can be modified or
  %replaced by the called function.
  btnlist = feval(fns{j},analysis,btnlist);
end
