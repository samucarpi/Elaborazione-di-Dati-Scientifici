% PLS_TOOLBOX Utilties.
%
% General Utitlites
%   addhelpyvars            - Adds y-block specific info to help field of a model
%   addsourceinfo           - Store origin filename and path in DSO history field.
%   adoptdefinitions        - Inserts definitions into an exsisting definitions list.
%   besttime                - Returns a string describing the time interval provided (in seconds).
%   builddbstr              - Builds a database connection string.
%   cachestruct             - Creates structure of model cache items for display in evritree.
%   calccvbias              - Calculate the Cross-Validation Bias from a cross-validated model
%   calcystats              - Calculate y-block statistics for a regression model.
%   cell2array              - Converts a cell of batch data to a zero-padded array.
%   cell2str                - convert cell array of strings to char array.
%   cellne                  - Compares two cells for inequality in size and/or values.
%   choosecomp              - Returns suggestion for number of components to include in a model. 
%   classcolors             - Defines the colors to be used for classes in plots.
%   classmarkers            - Returns a class marker description list.
%   clean                   - clears and closes everything.
%   clipboard_image         - Copy and paste images to/from the system clipboard.
%   confusionmatrix         - Engine for calculating confusion matrices.
%   confusiontable          - Engine for calculating confusion tables.
%   constrainfit            - Copyright Eigenvector Research, Inc. 2009-2010
%   copydsfields            - Copies informational fields between datasets and/or models.
%   corrspecengine          - This function is the primary calculational engine for the function corrspec.
%   corrspecutilities       - CORRSEPCUTILITIES Contains utility functions for corrspec functions.
%   createtable             - Transforms binary data into text columns.
%   crossval_builtin        - Helper function for built-in model cross-validation.
%   crossval_npls           - CROSSVAL_TEMPLATE Template for helper function for cross-validation.
%   crossval_stdmod         - Helper function for standard model cross-validation.
%   defaultmodelname        - Generate default model name for save of model
%   demodlg                 - Provides a dialog box for use with GUI demos
%   dendrogram              - Display a dendrogram based on Cluster output
%   deptree                 - Interactive m-file dependency tree
%   doc                     - Overload of the Matlab DOC function to trap calls for EVRI products.
%   encode                  - Translates a variable into matlab-executable code.
%   encodedate              - Returns a timestamp in string format including miliseconds.
%   encodemethod            - Create a cross-validation index vector for a given method.
%   encodexml               - Convert standard data types into XML-encoded text.
%   errorbars               - Error bar for Y vs X plots.
%   evriclearlicense        - Clears any stored EVRI license information.
%   evriio                  - Give useful information (help,etc) on a named mfile.
%   evristartup             - Example startup file.
%   evrivarname             - Get a unique variable name for a given workspace.
%   example_template        - MYFUNCTION Example shell for new PLS_Toolbox function.
%   exportmodelregvec       - Export model as regression vector (using regcon).
%   exteriorpts             - Finds pts on the exterior of a data space
%   figfont                 - Modify figures for word processor documents.
%   findsqlfields           - Find field names from SQL string for use as "variable" names in a dataset.
%   fitexp                  - Calculates an exponential curve and its fit to points.
%   fitgauss                - Calculates a gaussian curve and its fit to points.
%   getdatasource           - Extract summary dataset info.
%   getlicensecode          - M-file for getlicensecode.fig
%   getmisclassifieds       - Engine for determining which samples were misclassified.
%   getplspref              - Get overriding options (preferences) for PLS_Toolbox functions.
%   getserverinfo           - M-file for getserverinfo.fig
%   getshareddata           - - Retrieve shared data from a source.
%   getsubstruct            - Utility for returning contents of nested substructures. 
%   idateticks              - convert axis labels into intelligent date ticks
%   importmodel_customlist  - List of user-defined "import" methods for models.
%   inevriautomation        - Evaluate if currently in an EVRI Automation call
%   inferdelim              - Infer the delimiter required to best parse strings into data
%   isdataset               - Test for dataset, returns true if 'in' is a dataset.
%   isfieldcheck            - Utility for checking each field level in a nested structure array.
%   ismac                   - Overload of ISMAC for backward compatibility.
%   ismodel                 - Returns boolean TRUE if input object is a standard model structure.
%   isshareddata            - Tests if item is a shared data object.
%   keep                    - Clear all except named variables in workspace
%   linesrch                - Copyright Eigenvector Research, Inc. 2005-2010
%   linkshareddata          - - Manage links to shared data objects.
%   locatedemo              - Search common locations for a specific demo data file.
%   makepredhelp            - Converts cell format prediction help into structure
%   makesubops              - make sub-options sturcture for options GUI.
%   modelstruct             - Constructs an empty model structure.
%   moveobj                 - Interactively reposition graphics objects.
%   ms_bin                  - bins Mass Spectral data into user-defined bins.
%   nassign                 - Generic subscript assignment indexing for n-way arrays.
%   nindex                  - Generic subscript indexing for n-way arrays.
%   num2ind                 - Finds the index for element in array given the number of the element.
%   parafac_depreciated     - PARAFAC Parallel factor analysis for n-way arrays.
%   parafdiag               - Calculates the (unique) variance of parafac components.
%   pdf2text                - Read PDF document into a string array.
%   plot_corr               - Plotting utility for corrspec.
%   plotbiplotlimits        - PLOTLOADSLIMITS Adjust biplot settings.
%   plotdatahat             - Extract and display data estimates and residuals from a model.
%   plotloads_mlr           - Plotloads helper function used to extract info from model.
%   plotloads_parafac       - PLOTLOADS_MCR Plotloads helper function used to extract info from model.
%   plotloadslimits         - Adjust loadings plots for special settings
%   plotscores_asca         - Plotscores helper function used to extract info from model.
%   plotscores_cls          - Plotscores helper function used to extract info from model.
%   plotscores_defaults     - Manage default scores plot settings.
%   plotscores_defaults_gui - M-file for plotscores_defaults_gui.fig
%   plotscores_lwr          - Plotscores helper function used to extract info from model.
%   plotscores_mlr          - Plotscores helper function used to extract info from model.
%   plotscores_svm          - Plotscores helper function used to extract info from model.
%   plotscores_svmda        - Plotscores helper function used to extract info from model.
%   plslogo                 - Generates PLS_Toolbox CR surface logo.
%   preprouser              - User-defined preprocessing methods.
%   querydb                 - Executes a query (sqlstr) on a database defined by connection string (connstr).
%   querytool               - Database connection and query tool.
%   r2calc                  - Calculate R^2 for a given pair of vectors or matricies.
%   range                   - Calculates the range of the values. 
%   read_dso                - Reads a single dataset object from a MAT file.
%   reconopts               - Reconcile options structure with defaults.
%   recordchange            - Placeholder for functionality not supported in PLS_Toolbox.
%   removeshareddata        - Remove shared data object from source and all links.
%   resolve_maps_2d_cor     - Helper function for corpsec.m to resolve contributions maps.
%   resolve_spectra_2d_cor  - Helper function for corpsec.m to resolve contributions and spectra.
%   revdir                  - Called when user clicks "reverse" button
%   savgol2d                - Savitzky-Golay smoothing and differentiation for grey scale images.
%   scrollzoom              - Enables scroll wheel zoom on a figure.
%   searchshareddata        - - Search properties of shared data.
%   setappdatas             - Sets appdata properties for given figure from structure.
%   setplspref              - Set overriding options (preferences) for PLS_Toolbox functions.
%   setshareddata           - - Change/add source data and call update code for linked data.
%   setsubstruct            - Utility for setting contents of nested substructures. 
%   showposition            - Display the cursor's position on the current axes
%   simcastats              - Calculates prediction statistics for a SIMCA model or prediction
%   spawnaxes               - Split off the current sub-axes object as its own figure. 
%   specalignset            - Settings used to modfiy spectral alignment preprocessing.
%   spdiag                  - Simplified sparse diagonal function.
%   stick                   - Plots stick graph.
%   str2cell                - convert from string to cell array (using tab and lf chars)
%   string_x                - Add backslash before troublesome TeX characters.
%   struct2dataset          - Convert a structure into a dataset object.
%   super_reduce            - Eliminates highly correlated variables.
%   svdlgpls                - Dialog to save variable to workspace or MAT file.
%   uniquename              - Returns a unique string which describes the given object only.
%   updatepropshareddata    - - Make a change to shared data property and notify links.
%   userinfotag             - Returns user and computer-specific string tag for history fields
%   writepltengine          - writes a PLS_Toolbox model object from the Matlab workspace to a Vision Air plt file.
%
% Support Utilities (Undocumented)
%   alignmatfun             - Objective funtion optimized in ALIGNMAT.
%   evridemo                - Start demo for a given mfile.
%   fastnnls_proj           - Projection utility for use from FASTNNLS.
%   gettbicons              - Return structure with all toolbox toolbar icons.
%   initloads               - Utility for initializing loadings in PARAFAC, TUCKER etc.
%   legendname              - Assign legend tags to object handles.
%   makeplabels             - Helper function for UNFOLDMW.
%   nwengine                - For fitting multilinear decomposition models.
%   plotloads_mcr           - Plotloads helper function used to extract info from model.
%   plotloads_purity        - Plotloads helper function used to extract info from model.
%   plotscores_frpcr        - Plotscores helper function used to extract info from model.
%   plotscores_mcr          - Plotscores helper function used to extract info from model.
%   plotscores_mpca         - Plotscores helper function used to extract info from model.
%   plotscores_parafac      - Plotscores helper function used to extract info from model.
%   plotscores_pca          - Plotscores helper function used to extract info from model.
%   plotscores_pcr          - Plotscores helper function used to extract info from model.
%   plotscores_pls          - Plotscores helper function used to extract info from model.
%   plotscores_plsda        - Plotscores helper function used to extract info from model.
%   plotscores_purity       - Plotscores helper function used to extract info from model.
%   plotscores_simca        - Plotscores helper function used to extract info from model.
%   plotscoreslimits        - Display relevant limits on a scores plot.
%   pls_toolboxhelp         - Utility for INFO.XML.
%   preprocatalog           - Is the default catalog of preprocessing methods for preprocess.
%   regresconstr            - For constrained bilinear regression.
%   scoredens               - Unsupported utility.
%   simcasub                - Calculate a single SIMCA Sub-model.
%   standardizeloads        - Utility for standardizing loadings.
%   tabledata               - Extracts line data from a figure.
%   updatemod               - Update model structure to be compatible with the current version.
%
% Defunct Unsupported Utilites (to be discontinued)
%   missmean                - Mean of a matrix X with NaN's.
%   pcapro                  - Projects new data on old principal components model.
%   polypred                - Prediction with POLYPLS models.
