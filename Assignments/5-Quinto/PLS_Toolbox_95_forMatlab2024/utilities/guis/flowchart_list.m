function list = flowchart_list(handles)
%FLOWCHART_LIST Generate context-senstive list of flowchart objects
% This function returns the context-sensitive list of flowchart objects to
% display in the Analysis GUI. Input is the structure of handles for the
% relevent Analysis GUI. The list must be an n by 3 cell with each row
% containing:
%     'description'   'enable_test'   'callback'
% where enable_test is a valid matlab command which returns a scalar
% logical value (0 or 1) indicating if the given button should be enabled
% or not. If 'callback' is empty, the object will be shown not as a button
% but as a text label "separator". Text labels can be prepended with the
% string <b> to make the label bold.
% Recall that all callbacks are performed at the command-line but with gcbf
% set as the relevent analysis interface.
%
% Custom flowchart lists can be created and overloaded in two different
% ways:
%  (A) by creating an m-file named "flowchart_list_zzz.m" where zzz is the
%      method for which the flowchart should be used (e.g.
%      "flowchart_list_pca.m") The function should expect two inputs:
%      handles (the handles array from the Analysis window) and list (the
%      basic list of items already defined, usually just the "load data"
%      flowchart item)
%  (B) by creating a MAT file named "flowchart_list_zzz.mat" containing a
%      single variable that contains the list (as defined above). This will
%      REPLACE any items already in the list.
%  Method (B) always takes precidence over (A).
%
%I/O: flowchart_list(analysis_handles)
%
%See also: ANALYSIS, FLOWCHART_CALLBACK

%Copyright © Eigenvector Research, Inc. 2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.


list = getlist(handles);
ind = 0;
for j=1:length(list);
  if ~isempty(list{j,3})
    ind = ind+1;
    list{j,1} = [num2str(ind) '. ' list{j,1}];
  end
end

%-----------------------------------------------
function list = getlist(handles);

list = {
  '<b>Analysis Flowchart' ...
  '1' ...
  ''

  'Load calibration data'  ...
  '~analysis(''isloaded'',''xblock'',handles) & ~getappdata(handles.analysis,''apply_only'')'  ...
  'analysis(''fileimport'',gcbf,[],guidata(gcbf),''x'');'
  };

method = char(getappdata(handles.analysis,'curanal'));

targname = ['flowchart_list_' method];
if ~isempty(evriwhich([targname '.mat']))
  %found a MAT file with this name, load and use contents
  temp = load(evriwhich([targname '.mat']));
  names = fieldnames(temp);
  list = temp.(names{1});
elseif exist(targname,'file')
  %found a specific method flowchart file (overload or just unusual model
  %type) call it (expected I/O is:   list = fn(handles,list)
  list = feval(targname,handles,list);
else
  %no method flowchart file, use standard flowcharts:

  switch method
    case ''
      list = [list; {
        'Choose analysis method'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'moveto(findobj(gcbf,''tag'',''analysisalg''));'
        }];

    case {'mcr'}

      list = [list; {
        'Load C Estimates (optional)'  ...
        'analysis(''isloaded'',''xblock'',handles) & ~strcmp(getappdata(handles.analysis,''statmodl''),''loaded'') & ~analysis(''isloaded'',''yblock'',handles)'  ...
        'analysis(''fileimport'',gcbf,[],guidata(gcbf),''y'');'

        'Choose Preprocessing'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'analysis(''preprocesscustom'',gcbf,[],guidata(gcbf));'

        'Choose Options'  ...
        'analysis(''isloaded'',''xblock'',handles)'   ...
        'analysis(''editoptions'',gcbf, [], guidata(gcbf));'

        'Choose Components'  ...
        'analysis(''isloaded'',''xblock'',handles)'   ...
        'evritip(''flowchart_mcrncomp'',''Select the line in the Variance Captured table which represents the number of components you want to resolve.'',0);'

        'Build Model' ...
        'analysis(''isloaded'',''xblock'',handles) & ismember(getappdata(handles.analysis,''statmodl''),{''none'' ''calnew''})'   ...
        'analysis(''calcmodel_Callback'',gcbf,[],guidata(gcbf));'

        'Review Model' '' ''

        'Review Scores'  ...
        '(~analysis(''isloaded'',''validation_xblock'',handles) | analysis(''isloaded'',''prediction'',handles)) & ismember(getappdata(handles.analysis,''statmodl''),{''calold'' ''loaded''})'   ...
        'pca_guifcn(''plotscores_Callback'',gcbf,[],guidata(gcbf));'

        'Review Loadings'  ...
        '(~analysis(''isloaded'',''validation_xblock'',handles) | analysis(''isloaded'',''prediction'',handles)) & ismember(getappdata(handles.analysis,''statmodl''),{''calold'' ''loaded''})'   ...
        'pca_guifcn(''plotloads_Callback'',gcbf,[],guidata(gcbf));'

        'Compare Models' '' ''

        'Change Components' ...
        'ismember(getappdata(handles.analysis,''statmodl''),{''calold''})'...
        'evritip(''flowchart_mcrncomp2'',''To compare the current model to a new model with a different number of components, select a new number of components in the table and click "Build Model" again.'',0);'

        'Use Model' '' ''

        'Load Test Data' ...
        '1'...
        'analysis(''fileimport'',gcbf,[],guidata(gcbf),''x_val'');'

        'Apply Model' ...
        'analysis(''isloaded'',''validation_xblock'',handles) & analysis(''isloaded'',''model'',handles) & ~analysis(''isloaded'',''prediction'',handles)'   ...
        'analysis(''calcmodel_Callback'',gcbf,[],guidata(gcbf));'

        }];


    case {'parafac'}

      list = [list; {
        'Choose Preprocessing'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'analysis(''preprocesscustom'',gcbf,[],guidata(gcbf));'

        'Choose Components'  ...
        'analysis(''isloaded'',''xblock'',handles)'   ...
        'evritip(''flowchart_parafacncomp'',''Select the line in the Variance Captured table which represents the number of components you want to resolve.'',0);'

        'Build Model' ...
        'analysis(''isloaded'',''xblock'',handles) & ismember(getappdata(handles.analysis,''statmodl''),{''none'' ''calnew''})'   ...
        'analysis(''calcmodel_Callback'',gcbf,[],guidata(gcbf));'
        }];

      list = [list; {
        'Review Model' '' ''
        }];

      list = [list; {

      'Review Results'  ...
      '(~analysis(''isloaded'',''validation_xblock'',handles) | analysis(''isloaded'',''prediction'',handles)) & ismember(getappdata(handles.analysis,''statmodl''),{''calold'' ''loaded''})'   ...
      'parafac_guifcn(''modelviewer_Callback'',gcbf,[],guidata(gcbf));'

      'Compare Models' '' ''

      'Change Components' ...
      'ismember(getappdata(handles.analysis,''statmodl''),{''calold''})'...
      'evritip(''flowchart_parafacncomp2'',''Review the Core Consistency plot and compare the obtained model to models with different numbers of components (by selecting a new number of components in the table) to assure this model provides the appropriate resolution of components.'',0);parafac_guifcn(''plotcorecondia'',gcbo,[],guidata(gcbo));'

      'Rebuild Model' ...
      'ismember(getappdata(handles.analysis,''statmodl''),{''calnew''})'...
      'analysis(''calcmodel_Callback'',gcbf,[],guidata(gcbf));'

      'Use Model' '' ''

      'Load Test Data' ...
      '1'...
      'analysis(''fileimport'',gcbf,[],guidata(gcbf),''x_val'');'

      'Apply Model' ...
      'analysis(''isloaded'',''validation_xblock'',handles) & analysis(''isloaded'',''model'',handles) & ~analysis(''isloaded'',''prediction'',handles)'   ...
      'analysis(''calcmodel_Callback'',gcbf,[],guidata(gcbf));'

      }];
    case {'cls'}

      x = analysis('getobjdata','xblock',handles);
      y = analysis('getobjdata','yblock',handles);
      model = analysis('getobjdata','model',handles);

      list{2,1} = 'Load Reference Spectra';
      
      list = [list; {  'Load Conc. Data (opt.)'  ...
        'analysis(''isloaded'',''xblock'',handles) & ~analysis(''isloaded'',''yblock'',handles)'  ...
        'evritip(''flowchart_clsloady'',''Unless your X data contains "pure component spectra" scaled to unit concentration, you should load the sample mixture information as the Y-block.'',0);analysis(''fileimport'',gcbf,[],guidata(gcbf),''y'');'

        'Load Mixture Spectra' ...
        '1'...
        'analysis(''fileimport'',gcbf,[],guidata(gcbf),''x_val'');'

        'Choose Model Settings' '' ''

        'Choose Preprocessing'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'analysis(''preprocesscustom'',gcbf,[],guidata(gcbf));'

        'Choose Cross-Validation'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'analysis(''crossvalmenu'',gcbf,[],guidata(gcbf));'

        'Build & Apply Model' '' ''

        'Build/Apply Model' ...
        'analysis(''isloaded'',''xblock'',handles) & ismember(getappdata(handles.analysis,''statmodl''),{''none'' ''calnew''})'   ...
        'analysis(''calcmodel_Callback'',gcbf,[],guidata(gcbf));'
        
        'Review Predictions'  ...
        '(~analysis(''isloaded'',''validation_xblock'',handles) | analysis(''isloaded'',''prediction'',handles)) & ismember(getappdata(handles.analysis,''statmodl''),{''calold'' ''loaded''})'   ...
        'pca_guifcn(''plotscores_Callback'',gcbf,[],guidata(gcbf));'

      }];


    case {'pca' 'pls' 'pcr' 'mlr' 'mpca' 'plsda' 'lwr' 'batchmaturity' 'npls'}

      if ~ismember(method,{'pca' 'mpca'})
        list{2,1} = 'Load X data';
        list = [list; {  'Load Y data'  ...
              'analysis(''isloaded'',''xblock'',handles) & ~analysis(''isloaded'',''yblock'',handles)'  ...
              'analysis(''fileimport'',gcbf,[],guidata(gcbf),''y'');'}];
        x = analysis('getobjdata','xblock',handles);
        y = analysis('getobjdata','yblock',handles);
        model = analysis('getobjdata','model',handles);
        if ~ismember(method,{'plsda' 'cls' 'batchmaturity'}) & isempty(model) & (isempty(x) | isempty(y) | (isdataset(y) & isempty(y.data)))
          return;
        end
      end

      if ismember(method,{'batchmaturity'})
        list{end,1} = 'Load Y data (optional)';
        list{end,3} = 'evritip(''flowchart_bmloady'',''Unless you load a y-block, Batch Maturity will assume each batch runs from 0 to 100 maturity.'',0);analysis(''fileimport'',gcbf,[],guidata(gcbf),''y'');';
      end

      if ismember(method,{'cls'})
        list{end,1} = 'Load Y data (optional)';
        list{end,3} = 'evritip(''flowchart_clsloady'',''Unless your X data contains "pure component spectra", you must load Y-block data indicating concentration of each species in the X-block data.'',0);analysis(''fileimport'',gcbf,[],guidata(gcbf),''y'');';
      end
      
      if ismember(method,{'plsda'})

        list{end,1} = 'Load Classes';
        list{end,3} = 'evritip(''flowchart_plsdaloady'',''Unless your X data contains classes, you must load as your Y data either a vector of classes or a logical array indicating class assignments for each sample. Use "Edit/X-block data" to load classes into X-block.'',0);analysis(''fileimport'',gcbf,[],guidata(gcbf),''y'');';
        x = analysis('getobjdata','xblock',handles);
        y = analysis('getobjdata','yblock',handles);
        model = analysis('getobjdata','model',handles);
        if isempty(x) | (isempty(x.class{1}) & isempty(model) & (isempty(y) | (isdataset(y) & isempty(y.data))))
          return;
        end
        if ~isempty(x.class{1})
          list{end,1} = 'Load Classes (optional)';
        end

        list = [list; {
          'Select Class Groups'  ...
          'analysis(''isloaded'',''xblock'',handles)'    ...
          'evritip(''flowchart_plsdabuilder'',''Open the PLSDA Class Group interface to choose subsets of the classes to model. See the "Help" menu in the Class Groups GUI for more assistance.'',0);plsda_guifcn(''choosegrps_Callback'',gcbo,[],guidata(gcbo));'
          }];
      end

      list = [list; {
        'Choose Preprocessing'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'analysis(''preprocesscustom'',gcbf,[],guidata(gcbf));'

        'Choose Cross-Validation'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'analysis(''crossvalmenu'',gcbf,[],guidata(gcbf));'
        }];
      
      if ismember(method,{'lwr'})
        list = [list; {
          'Choose Local Points'  ...
          'analysis(''isloaded'',''xblock'',handles)'   ...
          'evritip(''flowchart_lwrneighbors'',''Choose the number of Local Points which should be used to calculate each local model'',0);analysis(''panelviewselect_Callback'',gcbf,[],guidata(gcbf),2);'
          }];
      end

      list = [list; {
        'Build Model' ...
        'analysis(''isloaded'',''xblock'',handles) & ismember(getappdata(handles.analysis,''statmodl''),{''none'' ''calnew''})'   ...
        'analysis(''calcmodel_Callback'',gcbf,[],guidata(gcbf));'
        }];

      list = [list; {
        'Review Model' '' ''
        }];
      
      if ~ismember(method,{'cls' 'mlr'})
        list = [list; {
          'Choose Components'  ...
          'analysis(''isloaded'',''xblock'',handles) & strcmp(getappdata(handles.analysis,''statmodl''),''calold'')'   ...
          'evritip(''flowchart_eigenvalues'',''Review the Eigenvalues plot, then select the line in the Variance Captured table which represents the number of components you want to include in the model'',0);pca_guifcn(''ploteigen_Callback'',gcbf,[],guidata(gcbf));'
          }];
      end

      list = [list; {

      'Review Scores'  ...
      '(~analysis(''isloaded'',''validation_xblock'',handles) | analysis(''isloaded'',''prediction'',handles)) & ismember(getappdata(handles.analysis,''statmodl''),{''calold'' ''loaded''})'   ...
      'pca_guifcn(''plotscores_Callback'',gcbf,[],guidata(gcbf));'

      'Review Loadings'  ...
      '(~analysis(''isloaded'',''validation_xblock'',handles) | analysis(''isloaded'',''prediction'',handles)) & ismember(getappdata(handles.analysis,''statmodl''),{''calold'' ''loaded''})'   ...
      'pca_guifcn(''plotloads_Callback'',gcbf,[],guidata(gcbf));'

      'Use Model' '' ''

      'Load Test Data' ...
      '1'...
      'analysis(''fileimport'',gcbf,[],guidata(gcbf),''x_val'');'

      'Apply Model' ...
      'analysis(''isloaded'',''validation_xblock'',handles) & analysis(''isloaded'',''model'',handles) & ~analysis(''isloaded'',''prediction'',handles)'   ...
      'analysis(''calcmodel_Callback'',gcbf,[],guidata(gcbf));'

      }];

    case {'svm' 'svmda'}
      
      list{2,1} = 'Load X data';
      list = [list; {  'Load Y data'  ...
        'analysis(''isloaded'',''xblock'',handles) & ~analysis(''isloaded'',''yblock'',handles)'  ...
        'analysis(''fileimport'',gcbf,[],guidata(gcbf),''y'');'}];
      x = analysis('getobjdata','xblock',handles);
      y = analysis('getobjdata','yblock',handles);
      model = analysis('getobjdata','model',handles);
      if ~ismember(method,{'svmda'}) & isempty(model) & (isempty(x) | isempty(y) | (isdataset(y) & isempty(y.data)))
        return;
      end

      if ismember(method,{'svmda'})

        list{end,1} = 'Load Classes';
        list{end,3} = 'evritip(''flowchart_plsdaloady'',''Unless your X data contains classes, you must load as your Y data either a vector of classes. Use "Edit/X-block data" to load classes into X-block.'',0);analysis(''fileimport'',gcbf,[],guidata(gcbf),''y'');';
        x = analysis('getobjdata','xblock',handles);
        y = analysis('getobjdata','yblock',handles);
        model = analysis('getobjdata','model',handles);
        if isempty(x) | (isempty(x.class{1}) & isempty(model) & (isempty(y) | (isdataset(y) & isempty(y.data))))
          return;
        end
        if ~isempty(x.class{1})
          list{end,1} = 'Load Classes (optional)';
        end

        list = [list; {
          'Select Class Groups'  ...
          'analysis(''isloaded'',''xblock'',handles)'    ...
          'evritip(''flowchart_plsdabuilder'',''Open the SVMDA Class Group interface to choose subsets of the classes to model. See the "Help" menu in the Class Groups GUI for more assistance.'',0);plsda_guifcn(''choosegrps_Callback'',gcbo,[],guidata(gcbo));'
        }];
      end

      list = [list; {
        'Choose Preprocessing'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'analysis(''preprocesscustom'',gcbf,[],guidata(gcbf));'

        'Choose Cross-Validation'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'analysis(''crossvalmenu'',gcbf,[],guidata(gcbf));'

        'Review Settings'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'evritip(''flowchart_svmsettings'',''Review the Function Settings panel. Choose one of the algorithms and select the number of data splits to use for parameter optimization.'',0);'

        'Build Model' ...
        'analysis(''isloaded'',''xblock'',handles) & ismember(getappdata(handles.analysis,''statmodl''),{''none'' ''calnew''})'   ...
        'analysis(''calcmodel_Callback'',gcbf,[],guidata(gcbf));'
        }];

      list = [list; {
        'Review Model' '' ''
        }];

      list = [list; {

      'Optimization Results'  ...
      'analysis(''isloaded'',''xblock'',handles) & strcmp(getappdata(handles.analysis,''statmodl''),''calold'')'   ...
      'svm_guifcn(''ploteigen_Callback'',gcbf,[],guidata(gcbf));'

      'Review Scores'  ...
      '(~analysis(''isloaded'',''validation_xblock'',handles) | analysis(''isloaded'',''prediction'',handles)) & ismember(getappdata(handles.analysis,''statmodl''),{''calold'' ''loaded''})'   ...
      'svm_guifcn(''plotscores_Callback'',gcbf,[],guidata(gcbf));'

      'Use Model' '' ''

      'Load Test Data' ...
      '1'...
      'analysis(''fileimport'',gcbf,[],guidata(gcbf),''x_val'');'

      'Apply Model' ...
      'analysis(''isloaded'',''validation_xblock'',handles) & analysis(''isloaded'',''model'',handles) & ~analysis(''isloaded'',''prediction'',handles)'   ...
      'analysis(''calcmodel_Callback'',gcbf,[],guidata(gcbf));'

      }];

    case {'xgb' 'xgbda'}
      
      list{2,1} = 'Load X data';
      list = [list; {  'Load Y data'  ...
        'analysis(''isloaded'',''xblock'',handles) & ~analysis(''isloaded'',''yblock'',handles)'  ...
        'analysis(''fileimport'',gcbf,[],guidata(gcbf),''y'');'}];
      x = analysis('getobjdata','xblock',handles);
      y = analysis('getobjdata','yblock',handles);
      model = analysis('getobjdata','model',handles);
      if ~ismember(method,{'xgbda'}) & isempty(model) & (isempty(x) | isempty(y) | (isdataset(y) & isempty(y.data)))
        return;
      end

      if ismember(method,{'xgbda'})

        list{end,1} = 'Load Classes';
        list{end,3} = 'evritip(''flowchart_plsdaloady'',''Unless your X data contains classes, you must load as your Y data either a vector of classes. Use "Edit/X-block data" to load classes into X-block.'',0);analysis(''fileimport'',gcbf,[],guidata(gcbf),''y'');';
        x = analysis('getobjdata','xblock',handles);
        y = analysis('getobjdata','yblock',handles);
        model = analysis('getobjdata','model',handles);
        if isempty(x) | (isempty(x.class{1}) & isempty(model) & (isempty(y) | (isdataset(y) & isempty(y.data))))
          return;
        end
        if ~isempty(x.class{1})
          list{end,1} = 'Load Classes (optional)';
        end

        list = [list; {
          'Select Class Groups'  ...
          'analysis(''isloaded'',''xblock'',handles)'    ...
          'evritip(''flowchart_plsdabuilder'',''Open the XGBDA Class Group interface to choose subsets of the classes to model. See the "Help" menu in the Class Groups GUI for more assistance.'',0);plsda_guifcn(''choosegrps_Callback'',gcbo,[],guidata(gcbo));'
        }];
      end

      list = [list; {
        'Choose Preprocessing'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'analysis(''preprocesscustom'',gcbf,[],guidata(gcbf));'

        'Choose Cross-Validation'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'analysis(''crossvalmenu'',gcbf,[],guidata(gcbf));'

        'Review Settings'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'evritip(''flowchart_xgbsettings'',''Review the Function Settings panel. Choose one of the algorithms and select the number of data splits to use for parameter optimization.'',0);'

        'Build Model' ...
        'analysis(''isloaded'',''xblock'',handles) & ismember(getappdata(handles.analysis,''statmodl''),{''none'' ''calnew''})'   ...
        'analysis(''calcmodel_Callback'',gcbf,[],guidata(gcbf));'
        }];

      list = [list; {
        'Review Model' '' ''
        }];

      list = [list; {

      'Optimization Results'  ...
      'analysis(''isloaded'',''xblock'',handles) & strcmp(getappdata(handles.analysis,''statmodl''),''calold'')'   ...
      'xgb_guifcn(''ploteigen_Callback'',gcbf,[],guidata(gcbf));'

      'Review Scores'  ...
      '(~analysis(''isloaded'',''validation_xblock'',handles) | analysis(''isloaded'',''prediction'',handles)) & ismember(getappdata(handles.analysis,''statmodl''),{''calold'' ''loaded''})'   ...
      'xgb_guifcn(''plotscores_Callback'',gcbf,[],guidata(gcbf));'

      'Use Model' '' ''

      'Load Test Data' ...
      '1'...
      'analysis(''fileimport'',gcbf,[],guidata(gcbf),''x_val'');'

      'Apply Model' ...
      'analysis(''isloaded'',''validation_xblock'',handles) & analysis(''isloaded'',''model'',handles) & ~analysis(''isloaded'',''prediction'',handles)'   ...
      'analysis(''calcmodel_Callback'',gcbf,[],guidata(gcbf));'

      }];

    case {'lregda'}
      
      list{2,1} = 'Load X data';
      list = [list; {  'Load Y data'  ...
        'analysis(''isloaded'',''xblock'',handles) & ~analysis(''isloaded'',''yblock'',handles)'  ...
        'analysis(''fileimport'',gcbf,[],guidata(gcbf),''y'');'}];
      x = analysis('getobjdata','xblock',handles);
      y = analysis('getobjdata','yblock',handles);
      model = analysis('getobjdata','model',handles);
      if ~ismember(method,{'annda'}) & isempty(model) & (isempty(x) | isempty(y) | (isdataset(y) & isempty(y.data)))
        return;
      end

      if ismember(method,{'lregda'})
        list{end,1} = 'Load Classes';
        list{end,3} = 'evritip(''flowchart_plsdaloady'',''Unless your X data contains classes, you must load as your Y data either a vector of classes. Use "Edit/X-block data" to load classes into X-block.'',0);analysis(''fileimport'',gcbf,[],guidata(gcbf),''y'');';
        x = analysis('getobjdata','xblock',handles);
        y = analysis('getobjdata','yblock',handles);
        model = analysis('getobjdata','model',handles);
        if isempty(x) | (isempty(x.class{1}) & isempty(model) & (isempty(y) | (isdataset(y) & isempty(y.data))))
          return;
        end
        if ~isempty(x.class{1})
          list{end,1} = 'Load Classes (optional)';
        end

        list = [list; {
          'Select Class Groups'  ...
          'analysis(''isloaded'',''xblock'',handles)'    ...
          'evritip(''flowchart_plsdabuilder'',''Open the LREGDA Class Group interface to choose subsets of the classes to model. See the "Help" menu in the Class Groups GUI for more assistance.'',0);plsda_guifcn(''choosegrps_Callback'',gcbo,[],guidata(gcbo));'
        }];
      end

      list = [list; {
        'Choose Preprocessing'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'analysis(''preprocesscustom'',gcbf,[],guidata(gcbf));'

        'Choose Cross-Validation'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'analysis(''crossvalmenu'',gcbf,[],guidata(gcbf));'

        'Review Settings'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'evritip(''flowchart_lregda_settings'',''Review the Function Settings panel. Set the regularization parameter'',0);'

        'Build Model' ...
        'analysis(''isloaded'',''xblock'',handles) & ismember(getappdata(handles.analysis,''statmodl''),{''none'' ''calnew''})'   ...
        'analysis(''calcmodel_Callback'',gcbf,[],guidata(gcbf));'
        }];

      list = [list; {
        'Review Model' '' ''
        }];

      list = [list; {
      'Review Scores'  ...
      '(~analysis(''isloaded'',''validation_xblock'',handles) | analysis(''isloaded'',''prediction'',handles)) & ismember(getappdata(handles.analysis,''statmodl''),{''calold'' ''loaded''})'   ...
      'svm_guifcn(''plotscores_Callback'',gcbf,[],guidata(gcbf));'

      'Use Model' '' ''

      'Load Test Data' ...
      '1'...
      'analysis(''fileimport'',gcbf,[],guidata(gcbf),''x_val'');'

      'Apply Model' ...
      'analysis(''isloaded'',''validation_xblock'',handles) & analysis(''isloaded'',''model'',handles) & ~analysis(''isloaded'',''prediction'',handles)'   ...
      'analysis(''calcmodel_Callback'',gcbf,[],guidata(gcbf));'

      }];    
    
    case {'lda'}
      
      list{2,1} = 'Load X data';
      list = [list; {  'Load Y data'  ...
        'analysis(''isloaded'',''xblock'',handles) & ~analysis(''isloaded'',''yblock'',handles)'  ...
        'analysis(''fileimport'',gcbf,[],guidata(gcbf),''y'');'}];
      x = analysis('getobjdata','xblock',handles);
      y = analysis('getobjdata','yblock',handles);
      model = analysis('getobjdata','model',handles);
      if ~ismember(method,{'annda'}) & isempty(model) & (isempty(x) | isempty(y) | (isdataset(y) & isempty(y.data)))
        return;
      end

      if ismember(method,{'lregda'})
        list{end,1} = 'Load Classes';
        list{end,3} = 'evritip(''flowchart_plsdaloady'',''Unless your X data contains classes, you must load as your Y data either a vector of classes. Use "Edit/X-block data" to load classes into X-block.'',0);analysis(''fileimport'',gcbf,[],guidata(gcbf),''y'');';
        x = analysis('getobjdata','xblock',handles);
        y = analysis('getobjdata','yblock',handles);
        model = analysis('getobjdata','model',handles);
        if isempty(x) | (isempty(x.class{1}) & isempty(model) & (isempty(y) | (isdataset(y) & isempty(y.data))))
          return;
        end
        if ~isempty(x.class{1})
          list{end,1} = 'Load Classes (optional)';
        end

        list = [list; {
          'Select Class Groups'  ...
          'analysis(''isloaded'',''xblock'',handles)'    ...
          'evritip(''flowchart_plsdabuilder'',''Open the LREGDA Class Group interface to choose subsets of the classes to model. See the "Help" menu in the Class Groups GUI for more assistance.'',0);plsda_guifcn(''choosegrps_Callback'',gcbo,[],guidata(gcbo));'
        }];
      end

      list = [list; {
        'Choose Preprocessing'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'analysis(''preprocesscustom'',gcbf,[],guidata(gcbf));'

        'Choose Cross-Validation'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'analysis(''crossvalmenu'',gcbf,[],guidata(gcbf));'

        'Review Settings'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'evritip(''flowchart_lregda_settings'',''Review the Function Settings panel. Set the regularization parameter'',0);'

        'Build Model' ...
        'analysis(''isloaded'',''xblock'',handles) & ismember(getappdata(handles.analysis,''statmodl''),{''none'' ''calnew''})'   ...
        'analysis(''calcmodel_Callback'',gcbf,[],guidata(gcbf));'
        }];

      list = [list; {
        'Review Model' '' ''
        }];

      list = [list; {
      'Review Scores'  ...
      '(~analysis(''isloaded'',''validation_xblock'',handles) | analysis(''isloaded'',''prediction'',handles)) & ismember(getappdata(handles.analysis,''statmodl''),{''calold'' ''loaded''})'   ...
      'svm_guifcn(''plotscores_Callback'',gcbf,[],guidata(gcbf));'
      
      'Review Loadings'  ...
      '(~analysis(''isloaded'',''validation_xblock'',handles) | analysis(''isloaded'',''prediction'',handles)) & ismember(getappdata(handles.analysis,''statmodl''),{''calold'' ''loaded''})'   ...
      'pca_guifcn(''plotloads_Callback'',gcbf,[],guidata(gcbf));'

      'Use Model' '' ''

      'Load Test Data' ...
      '1'...
      'analysis(''fileimport'',gcbf,[],guidata(gcbf),''x_val'');'

      'Apply Model' ...
      'analysis(''isloaded'',''validation_xblock'',handles) & analysis(''isloaded'',''model'',handles) & ~analysis(''isloaded'',''prediction'',handles)'   ...
      'analysis(''calcmodel_Callback'',gcbf,[],guidata(gcbf));'

      }];
    
    case 'knn'
      list = [list; {
        'Choose Preprocessing'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'analysis(''preprocesscustom'',gcbf,[],guidata(gcbf));'

        'Choose K (Neighbors)'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'evritip(''flowchart_choosek'',''In the "Neighbors" edit box, enter the number of neighboring samples which should be used to assign classes of unknowns (can be changed later)'',0);'

        'Choose Cross-Validation'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'analysis(''crossvalmenu'',gcbf,[],guidata(gcbf));'

        'Build Model'  ...
        'analysis(''isloaded'',''xblock'',handles) & ismember(getappdata(handles.analysis,''statmodl''),{''none'' ''calnew''})'   ...
        'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'

        'Review Classes'  ...
        '(~analysis(''isloaded'',''validation_xblock'',handles) | analysis(''isloaded'',''prediction'',handles)) & ismember(getappdata(handles.analysis,''statmodl''),{''loaded'' ''calold''})'   ...
        'knn_guifcn(''plotscores_Callback'',gcbf,[],guidata(gcbf));'

        'Use Model' '' ''

        'Load Test Data' ...
        '1'...
        'analysis(''fileimport'',gcbf,[],guidata(gcbf),''x_val'');'

        'Apply Model' ...
        'analysis(''isloaded'',''validation_xblock'',handles) & analysis(''isloaded'',''model'',handles) & ~analysis(''isloaded'',''prediction'',handles)'   ...
        'analysis(''calcmodel_Callback'',gcbf,[],guidata(gcbf));'

        'Review Predictions'  ...
        '(~analysis(''isloaded'',''validation_xblock'',handles) | analysis(''isloaded'',''prediction'',handles)) & ismember(getappdata(handles.analysis,''statmodl''),{''loaded'' ''calold''})'   ...
        'knn_guifcn(''plotscores_Callback'',gcbf,[],guidata(gcbf));'


        }];

    case 'cluster'
      list = [list; {
        'Choose Settings'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'evritip(''flowchart_clusteropts'',''From the Function Settings view, select an algorithm and any other settings you want to use for cluster analysis'',0);'

        'Choose Preprocessing'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'analysis(''preprocesscustom'',gcbf,[],guidata(gcbf));'

        'Perform Analysis'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'

        }];

    case 'purity'
      list = [list; {
        'Build Purity Model'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'
        }];



    case {'simca'}

      list = [list; {
        'Open Model Builder'  ...
        'analysis(''isloaded'',''xblock'',handles) & ~strcmp(getappdata(handles.analysis,''statmodl''),''loaded'')'    ...
        'evritip(''flowchart_simcabuilder'',''Open the SIMCA Model Builder interface to begin building SIMCA sub-models. See the "Help" menu in the SIMCA Model Builder for more assistance with this GUI.'',0);simca_guifcn(''modlbuilder_Callback'',gcbo,[],guidata(gcbo));'

        'Choose Preprocessing'  ...
        'analysis(''isloaded'',''xblock'',handles) & ~strcmp(getappdata(handles.analysis,''statmodl''),''loaded'')'    ...
        'analysis(''preprocesscustom'',gcbf,[],guidata(gcbf));'

        'Choose Cross-Validation'  ...
        'analysis(''isloaded'',''xblock'',handles) & ~strcmp(getappdata(handles.analysis,''statmodl''),''loaded'')'    ...
        'analysis(''crossvalmenu'',gcbf,[],guidata(gcbf));'

        'Build Model' ...
        'analysis(''isloaded'',''xblock'',handles) & ismember(getappdata(handles.analysis,''statmodl''),{''none'' ''calnew''})'   ...
        'analysis(''calcmodel_Callback'',gcbf,[],guidata(gcbf));'
        }];

      list = [list; {
        'Review Model' '' ''
        }];

      if ~strcmp(method,'mlr')
        list = [list; {
          'Choose Components'  ...
          'analysis(''isloaded'',''xblock'',handles) & strcmp(getappdata(handles.analysis,''statmodl''),''calold'')'   ...
          'evritip(''flowchart_eigenvalues'',''Review the Eigenvalues plot, then select the line in the Variance Captured table which represents the number of components you want to include in the model'',0);pca_guifcn(''ploteigen_Callback'',gcbf,[],guidata(gcbf));'
          }];
      end

      list = [list; {

      'Review Scores'  ...
      '(~analysis(''isloaded'',''validation_xblock'',handles) | analysis(''isloaded'',''prediction'',handles)) & ismember(getappdata(handles.analysis,''statmodl''),{''calold'' ''loaded''})'   ...
      'pca_guifcn(''plotscores_Callback'',gcbf,[],guidata(gcbf));'

      'Review Loadings'  ...
      '(~analysis(''isloaded'',''validation_xblock'',handles) | analysis(''isloaded'',''prediction'',handles)) & ismember(getappdata(handles.analysis,''statmodl''),{''calold'' ''loaded''})'   ...
      'pca_guifcn(''plotloads_Callback'',gcbf,[],guidata(gcbf));'

      'Add Model'  ...
      'ismember(getappdata(handles.analysis,''statmodl''),{''calold''}) && strcmpi(getfield(analysis(''getobjdata'',''model'',handles),''modeltype''),''pca'')'   ...
      'evritip(''flowchart_simcaadd'',''Use the SIMCA Model Builder "Add Model" button to add this model to the Modeled Classes. Then select another class to model, or "Assemble SIMCA Model", if done.'',0);simca_guifcn(''modlbuilder_Callback'',gcbo,[],guidata(gcbo));'

      'Apply Model' '' ''

      'Load Test Data' ...
      'ismember(getappdata(handles.analysis,''statmodl''),{''calold'' ''loaded''}) && strcmpi(getfield(analysis(''getobjdata'',''model'',handles),''modeltype''),''simca'')'...
      'analysis(''fileimport'',gcbf,[],guidata(gcbf),''x_val'');'

      'Apply Model' ...
      'analysis(''isloaded'',''validation_xblock'',handles) && analysis(''isloaded'',''model'',handles) && ~analysis(''isloaded'',''prediction'',handles)  && strcmpi(getfield(analysis(''getobjdata'',''model'',handles),''modeltype''),''simca'')'   ...
      'analysis(''calcmodel_Callback'',gcbf,[],guidata(gcbf));'

      }];

    case {'ann' 'annda'}
      
      list{2,1} = 'Load X data';
      list = [list; {  'Load Y data'  ...
        'analysis(''isloaded'',''xblock'',handles) & ~analysis(''isloaded'',''yblock'',handles)'  ...
        'analysis(''fileimport'',gcbf,[],guidata(gcbf),''y'');'}];
      x = analysis('getobjdata','xblock',handles);
      y = analysis('getobjdata','yblock',handles);
      model = analysis('getobjdata','model',handles);
      if ~ismember(method,{'annda'}) & isempty(model) & (isempty(x) | isempty(y) | (isdataset(y) & isempty(y.data)))
        return;
      end

      if ismember(method,{'annda'})
        list{end,1} = 'Load Classes';
        list{end,3} = 'evritip(''flowchart_plsdaloady'',''Unless your X data contains classes, you must load as your Y data either a vector of classes. Use "Edit/X-block data" to load classes into X-block.'',0);analysis(''fileimport'',gcbf,[],guidata(gcbf),''y'');';
        x = analysis('getobjdata','xblock',handles);
        y = analysis('getobjdata','yblock',handles);
        model = analysis('getobjdata','model',handles);
        if isempty(x) | (isempty(x.class{1}) & isempty(model) & (isempty(y) | (isdataset(y) & isempty(y.data))))
          return;
        end
        if ~isempty(x.class{1})
          list{end,1} = 'Load Classes (optional)';
        end

        list = [list; {
          'Select Class Groups'  ...
          'analysis(''isloaded'',''xblock'',handles)'    ...
          'evritip(''flowchart_plsdabuilder'',''Open the ANNDA Class Group interface to choose subsets of the classes to model. See the "Help" menu in the Class Groups GUI for more assistance.'',0);plsda_guifcn(''choosegrps_Callback'',gcbo,[],guidata(gcbo));'
        }];
      end

      list = [list; {
        'Choose Preprocessing'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'analysis(''preprocesscustom'',gcbf,[],guidata(gcbf));'

        'Choose Cross-Validation'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'analysis(''crossvalmenu'',gcbf,[],guidata(gcbf));'

        'Review Settings'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'evritip(''flowchart_annsettings'',''Review the Function Settings panel. Choose number of nodes in first layer, and second layer (optional).'',0);'

        'Build Model' ...
        'analysis(''isloaded'',''xblock'',handles) & ismember(getappdata(handles.analysis,''statmodl''),{''none'' ''calnew''})'   ...
        'analysis(''calcmodel_Callback'',gcbf,[],guidata(gcbf));'
        }];

      list = [list; {
        'Review Model' '' ''
        }];

      list = [list; {
      'Review Scores'  ...
      '(~analysis(''isloaded'',''validation_xblock'',handles) | analysis(''isloaded'',''prediction'',handles)) & ismember(getappdata(handles.analysis,''statmodl''),{''calold'' ''loaded''})'   ...
      'svm_guifcn(''plotscores_Callback'',gcbf,[],guidata(gcbf));'

      'Use Model' '' ''

      'Load Test Data' ...
      '1'...
      'analysis(''fileimport'',gcbf,[],guidata(gcbf),''x_val'');'

      'Apply Model' ...
      'analysis(''isloaded'',''validation_xblock'',handles) & analysis(''isloaded'',''model'',handles) & ~analysis(''isloaded'',''prediction'',handles)'   ...
      'analysis(''calcmodel_Callback'',gcbf,[],guidata(gcbf));'

      }];
    
    case {'anndl' 'anndlda'}
      
      list{2,1} = 'Load X data';
      list = [list; {  'Load Y data'  ...
        'analysis(''isloaded'',''xblock'',handles) & ~analysis(''isloaded'',''yblock'',handles)'  ...
        'analysis(''fileimport'',gcbf,[],guidata(gcbf),''y'');'}];
      x = analysis('getobjdata','xblock',handles);
      y = analysis('getobjdata','yblock',handles);
      model = analysis('getobjdata','model',handles);
      if ~ismember(method,{'anndlda'}) & isempty(model) & (isempty(x) | isempty(y) | (isdataset(y) & isempty(y.data)))
        return;
      end

      if ismember(method,{'anndlda'})
        list{end,1} = 'Load Classes';
        list{end,3} = 'evritip(''flowchart_plsdaloady'',''Unless your X data contains classes, you must load as your Y data either a vector of classes. Use "Edit/X-block data" to load classes into X-block.'',0);analysis(''fileimport'',gcbf,[],guidata(gcbf),''y'');';
        x = analysis('getobjdata','xblock',handles);
        y = analysis('getobjdata','yblock',handles);
        model = analysis('getobjdata','model',handles);
        if isempty(x) | (isempty(x.class{1}) & isempty(model) & (isempty(y) | (isdataset(y) & isempty(y.data))))
          return;
        end
        if ~isempty(x.class{1})
          list{end,1} = 'Load Classes (optional)';
        end

        list = [list; {
          'Select Class Groups'  ...
          'analysis(''isloaded'',''xblock'',handles)'    ...
          'evritip(''flowchart_plsdabuilder'',''Open the ANNDLDA Class Group interface to choose subsets of the classes to model. See the "Help" menu in the Class Groups GUI for more assistance.'',0);plsda_guifcn(''choosegrps_Callback'',gcbo,[],guidata(gcbo));'
        }];
      end

      list = [list; {
        'Choose Preprocessing'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'analysis(''preprocesscustom'',gcbf,[],guidata(gcbf));'

        'Choose Cross-Validation'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'analysis(''crossvalmenu'',gcbf,[],guidata(gcbf));'

        'Review Settings'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'evritip(''flowchart_annsettings'',''Review the Function Settings panel. Choose number of nodes in first layer, and second layer (optional).'',0);'

        'Build Model' ...
        'analysis(''isloaded'',''xblock'',handles) & ismember(getappdata(handles.analysis,''statmodl''),{''none'' ''calnew''})'   ...
        'analysis(''calcmodel_Callback'',gcbf,[],guidata(gcbf));'
        }];

      list = [list; {
        'Review Model' '' ''
        }];

      list = [list; {
      'Review Scores'  ...
      '(~analysis(''isloaded'',''validation_xblock'',handles) | analysis(''isloaded'',''prediction'',handles)) & ismember(getappdata(handles.analysis,''statmodl''),{''calold'' ''loaded''})'   ...
      'svm_guifcn(''plotscores_Callback'',gcbf,[],guidata(gcbf));'

      'Use Model' '' ''

      'Load Test Data' ...
      '1'...
      'analysis(''fileimport'',gcbf,[],guidata(gcbf),''x_val'');'

      'Apply Model' ...
      'analysis(''isloaded'',''validation_xblock'',handles) & analysis(''isloaded'',''model'',handles) & ~analysis(''isloaded'',''prediction'',handles)'   ...
      'analysis(''calcmodel_Callback'',gcbf,[],guidata(gcbf));'

      }];

    case ('asca')
      
        list{2,1} = 'Load X (Response) data';
        list = [list; {  
        'Load Y (DOE) data'  ...
        'analysis(''isloaded'',''xblock'',handles) & ~analysis(''isloaded'',''yblock'',handles)'  ...
        'analysis(''fileimport'',gcbf,[],guidata(gcbf),''y'');'
      
        'Choose Preprocessing'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'analysis(''preprocesscustom'',gcbf,[],guidata(gcbf));'

        'Perform Analysis'  ...
        'analysis(''isloaded'',''xblock'',handles) & ~analysis(''isloaded'',''model'',handles)'    ...
        'analysis(''calcmodel_Callback'',gcbo,[],guidata(gcbo))'
        }];
      
      case {'tsne' 'umap'}
      
      list = [list; {
        'Choose Preprocessing'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'analysis(''preprocesscustom'',gcbf,[],guidata(gcbf));'

        'Choose Components'  ...
        'analysis(''isloaded'',''xblock'',handles)'   ...
        'evritip(''flowchart_parafacncomp'',''Press the Analysis Method Options button and find the n_components parameter to change the number of components.'',0);'

        'Build Model' ...
        'analysis(''isloaded'',''xblock'',handles) & ismember(getappdata(handles.analysis,''statmodl''),{''none'' ''calnew''})'   ...
        'analysis(''calcmodel_Callback'',gcbf,[],guidata(gcbf));'
        }];

      list = [list; {
        'Review Model' '' ''
        }];

      list = [list; {

      'Review Embeddings'  ...
      '(~analysis(''isloaded'',''validation_xblock'',handles) | analysis(''isloaded'',''prediction'',handles)) & ismember(getappdata(handles.analysis,''statmodl''),{''calold'' ''loaded''})'   ...
      'tsne_guifcn(''plotscores_Callback'',gcbf,[],guidata(gcbf));'

      'Compare Models' '' ''

      'Change Components' ...
      'ismember(getappdata(handles.analysis,''statmodl''),{''calold''})'...
      'evritip(''flowchart_parafacncomp'',''Press the Analysis Method Options button and find the n_components parameter to change the number of components.'',0);'}];
        
      if strcmp(method,'umap')
        list = [list;{
          'Use Model' '' ''

          'Load Test Data' ...
          '1'...
          'analysis(''fileimport'',gcbf,[],guidata(gcbf),''x_val'');'

          'Apply Model' ...
          'analysis(''isloaded'',''validation_xblock'',handles) & analysis(''isloaded'',''model'',handles) & ~analysis(''isloaded'',''prediction'',handles)'   ...
          'analysis(''calcmodel_Callback'',gcbf,[],guidata(gcbf));'}];
      end
    case 'clsti'
      list = {};
      list = [list; {
      
      'Use CLSTI Model Builder interface'...
      '1'...
      'clsti_guifcn(''clstiModelBuilder_callback'',gcbf,[],guidata(gcbf));'

      'Load CLSTI Model'...
      '1'...
      'analysis(''loadmodel'',gcbf,[],guidata(gcbf));'
      
      'Load Test Data' ...
      'analysis(''isloaded'',''model'',handles)'...
      'analysis(''fileimport'',gcbf,[],guidata(gcbf),''x_val'');'
      
      'Apply Model' ...
      'analysis(''isloaded'',''validation_xblock'',handles) & analysis(''isloaded'',''model'',handles) & ~analysis(''isloaded'',''prediction'',handles)'   ...
      'analysis(''calcmodel_Callback'',gcbf,[],guidata(gcbf));'

      'Review Scores'  ...
      'analysis(''isloaded'',''prediction'',handles)'   ...
      'pca_guifcn(''plotscores_Callback'',gcbf,[],guidata(gcbf));'

      'Review Loadings'  ...
      'analysis(''isloaded'',''prediction'',handles)'...
      'pca_guifcn(''plotloads_Callback'',gcbf,[],guidata(gcbf));'



        }];
      
    otherwise
      list = [list; {
        'Build and Review Model...'  ...
        'analysis(''isloaded'',''xblock'',handles)'    ...
        'evrihelpdlg(''Sorry, No additional assistance is available for this analysis method.'',''No Help Available'');'
        }];
  end

end
