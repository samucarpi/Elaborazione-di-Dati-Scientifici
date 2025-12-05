echo on
%README Release notes for Version 9.5 of PLS_Toolbox.
% Oct 4, 2024
% Copyright Eigenvector Research, Inc. 2002-2024
%
% Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
% INSTALLING PLS_Toolbox:
%   Using the PLS_Toolbox Windows Installer.
%     1) RUN THE INSTALLER:
%       It is recommended that Windows users use the PLS_Toolbox
%       Windows Installer. Copy the .exe file to your Desktop (or other
%       suitable local location). Then double click the icon and follow
%       the instructions. Be sure to verify the location of the
%       installation folder, by default it will be the "toolbox" folder
%       of your current MATLAB installation. When the Installer has
%       completed, it will prompt you to start MATLAB and run an
%       install script. If MATLAB doesn't start see Step 2 below.
% 
%   Manually Installing PLS_Toolbox from ZIP File.
%     1) FILE EXTRACTION:
%       Decompress the PLS_Toolbox ZIP file and move it to the MATLAB 
%       "toolbox" folder (e.g. C:\Program Files\MATLAB\R2009b\toolbox). 
% 
%       Note: For those who already have a version of
%       PLS_Toolbox installed, be sure the folders do not have the same
%       name (by default they should not be). Rename your existing copy
%       of PLS_Toolbox if necessary. 
% 
%     2) RUN EVRIINSTALL:
%       For MATLAB to find PLS_Toolbox the directories that contain the 
%       toolbox files must be added to the MATLAB search path (except 
%       the @DATASET folder). (Note if you are familiar with installing 
%       toolboxes purchased from The MathWorks, this process is
%       slightly different. TMW installers typically are able to set
%       the path automatically.) 
% 
%       Start MATLAB and follow these steps:
%         a) Start MATLAB and use the Current Directory toolbar to 
%            navigate to the PLS_Toolbox directory created in Step One.
%         b) Once PLS_Toolbox is the current directory type evriinstall
%            at the command line (in the COMMAND WINDOW):
% 
%            >> evriinstall
% 
%            A small dialog box will appear. Change the settings as
%            need then click the Install button. EVRIINSTALL will add
%            the PLS_TOOLBOX to the path, check for any installations 
%            problems, and output results to the command window.
%         c) Near the end of the installation you will be prompted for 
%            your License Code. Simply copy and paste the code into the 
%            dialog box, click "OK", and the installation will
%            complete.
%            Note: Although PLS_Toolbox will now be fully functional you
%            will need to restart Matlab to register the PLS_Toolbox help
%            files with the Matlab help system. 
% 
%   Getting Started and Help
%     See the Software User Guide for detailed information on getting
%     started with PLS_Toolbox. Type "helppls" at the command line to open
%     the help browser to a list of PLS_Toolbox help topics.
%
% HAVING PROBLEMS? Try running "evridebug". This utility (located in the
%   main PLS_Toolbox folder) can diagnose many common installation
%   problems. If you have problems running this utility, you may have to
%   switch your working folder to the main PLS_Toolbox folder.
%
% ERROR AND BUG REPORTS:
%  Send bug reports to helpdesk@eigenvector.com
%  Please send your bug reports with the following information:
%   1) PLS_Toolbox License/Registration Number
%   2) Result of executing "ver" at the MATLAB prompt
%   3) Result of executing "evridebug" at the MATLAB prompt
%   4) Computer type, model and operating system version
%   5) Exact errors you are receiving (if any)
%   6) Hardware and memory configuration (if reporting a memory issue)
%   7) Your contact information
%       First Name:
%       Last Name:
%       Company Name:                                              
%       Phone Country Code:
%       Phone Area Code:
%       Phone Main:
%       Phone Extension:
%
% Changes and Bug Fixes in Version 9.5
%   NEW FEATURES
%     DIVINER - Generate optimal PLS models with varying preprocessing and variable selection.
%     ENSEMBLE - Predictions based on multiple calibrated regression models.
%   IMPORTERS
%     ABBSPECTRUMREADR - Reads a ABB SPECTRUM file into a DataSet object.
%   Other Features and Improvements
%     BROWSE - Add menu item to adjust default colormap.
%     EVRICACHEDB - Update derby database to version 10.14 and update class to new syntax. 
%     EVRISHAPLEY - Add support for Ensemble models.
%     PARAFAC - Add auto_outlier option to options interface.
%     PREPROCESS - Save preprofavorites.mat file to EVRI home directory instead of MATLAB prefs folder. 
%     TESTROBUSTNESS - Check Y-block and account for excluded variables.
%
% Changes and Bug Fixes in Version 9.3.1
%   BUG FIXES & ENHANCEMENTS   
%     analysis
%       Fix error in SSQ table when running Analysis LDA/PLSDA with no cross-validation.
%       Fix error in SSQ table when running PCR with multiple Y columns.
%       Fix for plotting preprocessed data and checking OSC preprocessing.
%       Fix for setting a class set from a plot and there is no existing class set in the DSO and cross-validation is turned off.
%     cooksd
%       Enable viewing Cook's Distance statistic in plotgui via plot controls for PCR models.
%     dataset
%       Fix for date field default.
%       Fix for uniqueid field, uses uuid now. 
%       Fix for loading old version DSO that has empty array.
%     evrishapley
%       Add ability to spawn static views of results.
%     lda 
%       Avoiding matrix pencil scenario where S_B and S_W are ill-conditioned.
%     specalign
%       Modify Variable Alignment GUI to include COW parameter optimization utilizing optim_cow.m.
%       Fix font issues on Windows and add segmentlength to the encoded preprocessing description.
%     pdf2text
%       Read PDF document into a string array.
%     plotscores 
%       Fix for measured vs predicted.
%
% Changes and Bug Fixes in Version 9.3
%   NEW FEATURES
%     ALS_SIT - Add command line function for alternating least squares with shift invariant tri-linearity model. 
%     CLSTI - Add CLS Temperature Interpreted model type. Interpolates a test temperature from a give set of pure spectra.
%     CROSSVALGUI - Added cross-validation by Classes and Stratified cross-validation
%     EVRISHAPLEY - Add Shapley Values as additional variable importance measure and model explanation tool.
%     LDA - Add Linear Discriminant Analysis model type.
%     SPLITCALTEST - Added duplex, spxy, and random split methods
%
%   Other Features and Improvements
%     ANALYSIS - Load .parent model of prediction automatically.
%     ANN/SVM - Make results reproducible by adding option, random_state.
%     CONFIG_PYENV - Fix for for Windows pip hanging in Python configuration.
%     DATASET - Update syntax to classdef. 
%     EVRIMODEL/GETSSQTABLE - Add method to retrieve SSQ table from model object in multiple formats. RMSEC now availalbe for most models where available. 
%     Gray CLS - Add plots of original CLS loadings and clutter factor loadings.
%     MODELOPTIMIZER - Fix for adding UMAP or TSNE models to modeloptimizer.
%     PLOTSCORES - Add R2-Q2 plot type.
%     TESTROBUSTNESS - Add Single Variable Test to.
%     TRENDTOOL - Add ability to use preprocessing in interface and model.
%     UMAP - Allow support for 1 component models.
%     Classification - Calculating class probability using exact expression instead of interpolating on lookup table values eliminates very small errors due to interpolation (PLSDA, ANNDA, and ANNDLDA).
%
% Changes and Bug Fixes in Version 9.2.1
%   BUG FIXES & ENHANCEMENTS   
%     analysis
%       Fix when viewing OSC preprocessing and no Y block loaded.
%       Fix for saving UMAP or TSNE models from analysis window.
%       Fix where Analysis showed RMSEC results for 1 LV instead of 1:Max LVs. 
%     arch
%       Add additional meta data to dataset.
%     comparevars
%       Fix bug where comparevars incorrectly reports no differences between two structs if used with non-default option setting for 'breakondiff' = 1.
%     experimentreadr
%       Allow import of experiment file with file names AND class info without requireing numerical data.
%     glswset
%       Add RMSECV/RMSEC ratio to Gray CLS cross-val plot.
%     hmac
%       Fix for labeling of merged classes.
%       Fix for overfitting, using choosecomp instead of using minimum error.
%       Change the default preprocessing to be the same as the user-specified default preprocessing in Analysis
%     MCCTTool
%       Fix for excluded variables in models getting reconciled with data.
%     mcr
%       Fix for applying MCR model, remove extraneous iteration. 
%     modeloptimizer
%       Fix "Add Combinations" when it adds ANN or ANNDA models to avoid duplicates and that the added model(s) use the correct number of hidden layer nodes.
%     modelselectorgui
%       Fixes for mouse position on high res screens.
%     multiblock
%       Fix for applying preprocessing to new data.
%     osccalc 
%       Fix for small interval sizes causing NaN. 
%     plotgui 
%       Add checkbox for biplots, plot loadings to origin. 
%     plotloads_builtin
%       Fix for incorrect labeling in CLS models when y variables are excluded in loadings plot.
%
% Changes and Bug Fixes in Version 9.2
%   NEW FEATURES
%     BIPLOTS - Include lines drawn from loadings points to origin. 
%     DATASET2TABLE - Added function to convert DataSets to MATLAB table datatype.
%     HMAC - Add object that automatically creates a hierarchical model for classification problems.
%     PYTHONTOOLS - Add support for Python 3.10 and Mac M1.
%     SOFTWAREDEVKIT - Add support for C# and MATLAB.
%     TESTROBUSTNESS - Enable testrobustness function for non-linear regression methods (lwr, svm, ann, anndl, xgb).
%   Other Features and Improvements
%     ANALYSIS - Extend corrmap to yblock.
%     EVRICOMPATIBILITY - Re-enable checking via website.
%     EXPERIMENTREADR - Fix to allow experiment file with just file names.
%     GLSWSET - Declutter GUI, added capability to use CLS residuals as a clutter source and can cross-validate over alpha parameter for GLSW and over number of PCs for EPO
%     MLR
%       - Update internal crossval 
%       - Update quadraticInit to be 1 instead of 0
%     PLOTGUI - can now plot Y-block scores for PLS, PLSDA, and N-PLS models.
%
% Changes and Bug Fixes in Version 9.1
%   NEW FEATURES
%      CONFIG_PYENV - Allow for user to configure Python in Matlab using a compressed file which contains the Python virtual environment.
%      ANNDL/ANNDLDA 
%        - Add Loss vs. Epochs plot
%        - Add ROC plot (ANNDLDA only).
%        - Add crossval increment, specify the step size for first hidden layer nodes to be cross-validated over.
%      UMAP
%        - Add connectivity plot.
%        - Undo preprocessing for xhat.
%        - Add embeddings to model.loads field.
%      TSNE - Add embeddings to model.loads field. 
%    GROOTMANAGER - Manage and update MATLAB graphics root object properties.
%    GROOTEDITOR - Interface to GROOTMANAGER.
%    DOEGUI - Updated interface using web-based app tools, interface now available in newer versions of MATLAB. 
%    
%   Other Features and Improvements  
%     ANALYSIS - Add Augmenting, Overwriting, or Cancel when loading X and Y data and there is already X and Y data loaded.
%     ASINHX - Arcsinh transform.
%     ASINSQRT - Arcsin square root transformation.
%     CLUTTER FILTER- Support using cross-validation over multiple GLSW or EPO parameter values when using CLS Residuals.
%     COADDSETTING GUI - Add binning by classes and add standard deviation and variance operations.
%     EDITDS 
%       - Add shuffle and undo shuffle to transform menu.
%       - When unfolding multiway the DataSet Editor will now update to match the unfolded DataSet Object. 
%       - Can do Undo One Action and the DataSet Editor will update to match the original multiway data.
%     EXPERIMENTREADR 
%       - Add class info from Y to X block on import.
%       - Allow experiment file with just file names.
%     FIGBROWSER - Change default to be off and remove any auto startup functionality.
%     FLUCUTSET - Add fix for updating plot when using sample as a blank.
%     GLSW - Scale SVD eigenvalues of input data by the first eigenvalue.
%     MODLRDER - Add summary Y stats.
%     PARAFAC - Add splithalf option to GUI. 
%     PR_ENTROPY - Calculate the pattern recognition entropy (PRE), Shannon entropy.
%     REPORTWRITER 
%       - Add summary stats and prediction stats.
%       - Add summary Y stats and prediction stats.
%       - Fix exporting to PowerPoint in MS Office 2019.
%
% Changes and Bug Fixes in Version 9.0 
%   NEW FEATURES
%    Python enabled tools:
%      ANNDL - Artificial Neural Network Deep Learning.
%      ANNDLDA - Artificial Neural Network Deep Learning for classification.
%      UMAP - Uniform Manifold Approximation and Projection (Unsupervised).
%      TSNE - t-distributed Stochastic Neighbor Embedding.
%    PLOTGUI - Create an axisscale from selected points in a plot of X-block data via context (right-click) menu. This can be used to create a Y-block using create Y from X-block Axis Scale menu item.
%    KNN
%      Select Class Groups interface now available in the KNN Analysis window.
%      Add option to use compression.
%    SIMCA
%      Sub models can now use independent preprocessing and included variables from the Analysis interface.
%      Building SIMCA model from command line can now pass cell array of individual PCA models (built from the same dataset).
%   Other Features and Improvements  
%     analysis - Can now create Y-block from X-block column, axisscale, or class set. And where appropriate, can choose to delete or exclude selection from X-block.
%     constrainfit - Add 'exponential' to type of constraints available.
%     experimentreadr - When splitting data into Cal/Val can now keep replicates based on class set from X or Y block. Also can choose to use Mahalanobis distance or Euclidean distance.
%     hjyreadr - Horiba Raman (.l6s, .l6m) file importer is now faster and can import larger files (up to a maximum of 2048x2048x1024 elements).
%
% Changes and Bug Fixes in Version 8.9.2
%   BUG FIXES & ENHANCEMENTS   
%     getmouseposition
%       Fix for figures not using pixel position.
%     plotgui
%       Fix for plotting images, disregard log scale for images as a temporary fix for plot disappearing when log selected.
%     plotscoreslimits
%       Fix for calling plotscoreslimits from command line.
%     table2dataset
%       Convert raw data to double when creating DSO.
% Changes and Bug Fixes in Version 8.9.1
%   BUG FIXES & ENHANCEMENTS    
%     caltransfer
%       Fix for OSC, use Y block for datasource checking. 
%     editds
%       Fix for propagating transforms (flip and shuffle).
%     lregda
%       Various minor changes and a minor correction to calculation of
%       predicted class probability.
%     mlr
%       Fix to ensure cross-validation uses same method calculating
%       regression vector as used when calibrating model. Change does not
%       affect y prediction but reported RMSEC was not accurate in specific
%       edge cases.
%     modeloptimizergui
%       Show Ncomp/LVs for only factor-based models ('pca' 'mpca' 'plsda' 'pls' 'npls' 'pcr')
%     octane.mat
%       Add class info to demo data.
%     plotgui
%       Update to handle square data and colorby.
%     parafac
%       Update waitbar behavior.
%     variableselectiongui
%       Fix for non-monotonic axis scale.
%
% Changes and Bug Fixes in Version 8.9
%   NEW FEATURES
%    LREGDA - Logistic Regression for classification.
%    SIMCA - Allow ability to cross-validate individual models in interface.
%    CROSSVAL - Allow a class set to be used for custom cross validation.
%    PLSDA
%      Allow creating of new class set based on modeling groups.
%      Enable Variable Selection methods VIP and sRatios.
%    ASCA - Uses the ASCA+ extension as introduced by Thiel, Feraud, and Govaerts (2017) to handle an un-balanced experimental design dataset.
%    PLOTGUI
%      Allow for creating a new class set via selection when viewing an existing class set.
%      Allow for override of default class coloring using 'classcoloruser' setting (set to "yes") then selecting context menu on marker.
%    PREPROCESS - Add Filtering and Despiking Settings GUI, which uses the windowfilter function.
%
%   Other Features and Improvements  
%     editds 	
%       Add menu items for flipping data.
%       Added Save Selected Indices and Load Selected Indices options under File menu.
%     analysis 	
%       Allow reset of included data (via xblock/yblock context menu).
%     anglemapper 	
%       Classification based on angle measures between signals.
%     xgb/xgbda 	
%       Add menu item to allow setting of include based on top N variables.
%     evrimodel 	
%       Add default naming to componentnames so components are unique by default.
%     visionairxmlreadr 	
%       Update java library.
%     doerunsheet 	
%       Increase font size.
%     anovadoe 	
%       Normalize sums of squares so that they the sum over all factors and error sum to 100% (as in Thiel et al (2017)).
%     selectvars 	
%       Extended to work when calibration Y-block is a multi-column class logical dataset or array.
%     pls
%       Fix PLS Y-Block Scores calculation for LVs 2 and higher, to normalize over included data only.
%     wtfa
%       Fix, do not take square root of rho.
%
% Changes and Bug Fixes in Version 8.8.1
%   NEW FEATURES
%     analysis
%       Add xycorrcoef to analysis tools menu.
%   BUG FIXES & ENHANCEMENTS    
%     datafit_enginedemo
%       Add 2 new demo options.
%     evriscript_createConfig
%       Add definitions for evriscript_modules 'xgb', 'xgbda', and 'annda'.
%     modeloptimizergui
%       Fix to account for multivariate Y when adding RMSEP values to the table.
%     mscorrset
%       Fix for older format of userdata (caused error in gui).
%     rpls
%       Show the optimal iteration value on plots by a dashed line.
%     updatemod
%       Fix for model.detail.preprocessing field getting overwritten incorrectly. 
%     xgb
%       After building model replace hyper-parameter search ranges in options with the selected optimal values.
%
% Changes and Bug Fixes in Version 8.8
%   NEW FEATURES
%     ANN-DA - Artificial Neural Net discriminant analysis.
%     Add new demo datasets for classification, SIMS_arylate and Iris.
%     MSCORR - Updated interface and handling of mscorr preprocessing.
%     Parallel computing initialization tools to allow PLS_Toolbox to use the Parallel Computing Toolbox.
%
%   IMPORTERS
%     JCAMPREADR - Update jar to increased the max number of blocks allowed in imported file from 500 to 50000. Throw an exception if this is exceeded. 
%
%   Other Features and Improvements  
%     ANN - Modify 'bpn' algorithm case to support multi-column y.
%     EMSCORR - model support for filter options 'p' and 's'.
%     MATCHVARS - Update to work with reversed axis scales. Will show error if axisscales are mixed.
%     MLRENGINE - Added condmax and output condnum.
%     MODELOPTIMIZER - Add wait bar when applying models to validation data. 
%     MSCORR - Allow window input to be a double array of indices.
%     PARAFAC - Fixed initialization of threeway suitable arrays usind TLD instead of ATLD. 
%     PLOTSCORES_PLS - Updates to studentized residual calucations for PLS and MLR. 
%     PLOTSCORESLIMITS - Limits on scores in PCA are now based solely on the scores distribution and no longer includes the model origin.  
%     SVM/SVMDA - Add parallel-for loop usage in optimization. 
% 
% Changes and Bug Fixes in Version 8.7.1
%   IMPORTERS
%     rdareadr
%       Reads in a Siemens .rda file into a DataSet Object.
%   BUG FIXES & ENHANCEMENTS    
%     addin
%       Add support for 3rd party features.
%     ann
%       Fix bug preventing prediction when using only 2 parameters, model and data, (but no options).
%     dataset/delsamps
%       Enable logical array or a numeric array of 1's and 0's as indicies.
%     evolvfa
%       Added compression, maxpcs = 40, updated algorithm.
%     flucut
%       Changed flucut so it doesn't soft delete the blank sample.
%     getdefaultfontsize 	
%       Convert more interfaces to use this as default. 
%     getscreensize
%       Change default to use values returned by Matlab (rather than Java). Help improve appearance on high DPI screens. 
%     jcampreadr
%       Add support tabular data form = "##XYPOINTS", in addition to "##XYDATA" and "##PEAKTABLE". 
%     opusreadr
%       Changes to handle Bruker Opus files having data and parameter block
%       types with bit 31 = 0 indicating the file was modified by the user.
%       Setting this bit to = 0 is a 21CFR part11 package feature. The
%       block type's bit 31 is = 1 when the file is created by the
%       instrument. On import, the block with the requested spectrum type
%       having bit 31 = 0 is read. If this does not exist then the block
%       with the requested spectrum type = 1 is read. This is done for data
%       and parameter blocks. It is assumed there is one measured sample
%       per file.
%     plotgui
%       Fix Scores Plot's calculation of Q and T2 "reduced" which was calculated 
%       incorrectly by assuming the model was built using options.confidencelimit = 0.95.
%     plotgui_plotscatter
%       Add code to restore colormap if plot command changes it.
%     tdf
%       Extend to support negative input T-statistics (in addition to positive). Now similar to normdf.m.
%     visionairxmlreadr
%       Major performance improvements.
%     xgb
%       Add the jar needed for XGB on Linux.
%     xgbda
%       Ensure XGBDA works properly if test data has no classes (or y-block).
%
% Changes and Bug Fixes in Version 8.7
%   NEW FEATURES
%     XGB and XGBDA Gradient Boosted Decision Tree (XGBoost) Analysis methods for regression or classification added.
%     Multiple interfaces now use fontsize from getdefaultfontsize.m to better display text.  
%     Use ReduceNN Samples and Unfold Multiway from the browse window. 
%     Simplified baseline preprocessing (baselineds).
%     VIPNWAY - new command line function to calculate Variable Influence in Projection (VIP) from a NPLS regression. 
%     MINMAX - Perform min-max scaling, sometimes called "unity normalization" available in preprocessing. 
%     Add robust algorithm to autoscale preprocessing.
%
%   IMPORTERS
%     Improved error handling for several importers. 
%
%   Other Features and Improvements  
%     Improved plotting performance, major gains for Matlab version 2014b+.  
%     WINDOWFILTER - Add option for despiking. 
%     CORRSPECGUI - Open main plot in new window.
%     EMSCORR - Allow xref to be input as dataset.
%     DATAFIT_ENGINE - Asymmetric least squares with smoothing, baselining & robust fitting (available as preprocessing).
%     REPORTWRITER - New option to allow ignoring of figures with given tag. 
%     CALTRANSFER - Add centering to DS, PDS, and DWPDS.
%     
% Changes and Bug Fixes in Version 8.6.2
%   IMPORTERS
%     spereadr
%       Reads Princeton Instruments SPE files.
%     table2dataset
%       Command line function to convert Matlab Table Array to DatasetObject.
%     envireadr
%       Move envireadr to PLS_Toolbox, image DSO will be created if MIA_Toolbox is installed.
%   BUG FIXES & ENHANCEMENTS    
%     analysis 	
%       Add menu item for Model Exporter python format.
%     crossval 	
%       Remove superfluous cross-validation computation when ann is called within crossval_ann.
%     dendrogram 	
%       Add fix for no classes existing.
%     exportfigure 	
%        Multiple fixes, added support for different objects on figure.
%     jmlimit 	
%       Improve the comments to describe the first parameter 'pc' more accurately .
%     matchvars 	
%       If matching by labels (in domatch) but target or xdata has empty labels then return empty data parameter.
%     modelselector 	
%       If query string does not match throw error .
%     modlrder 	
%       Stop modlrder from showing RMSEP if used on a Model. It should only show RMSEP if used on a Prediction, i.e. model.modeltype ending in _pred, case insensitively.
%     plotscores 	
%       Fix for cooks distance causing error.
%     variable selection 	
%       Add custom LVs field for specified mode in rpls. 
%
% Changes and Bug Fixes in Version 8.6.1
%   BUG FIXES & ENHANCEMENTS
%     Variable Selection 	
%       Fixes for using variable selections with more than one window open.
%     Context Menus 	
%       Fixes for context menu positioning high DPI systems. 
%     asca 	
%       Update ssq_tot calculation for using included samples only.
%     dendrogram 	
%       User can now choose to add the created cluster class to the x-block instead of only being allowed to overwrite an existing class.
%     estimatefactors 	
%       Add check to avoid columns which have NaN std dev.
%     matchrows 	
%       Add option for requiring unique labels. 
%     splitcaltest 	
%       Fix bug if replicates classset was not first classset.
%     xlsreadr 	
%       Update to avoid using 'basic' mode to better handle date conversion from Excel to Matlab.
%
% Changes and Bug Fixes in Version 8.6
%   Variable Selection
%     selectvars - selects variables that are predictive using VIP and sRatio.
%     vip - Add demo.
%     analysis - Add new panel for variable selection.
%     beer - Add new demo dataset for variable selection.
%   Importers
%     cytospecreadr -Imports cytospec formatted .cyt files.
%   Other Features and Improvements
%     confusiontable - Fixes for SIMCA model resutls.
%     cooksd - Multiple fixes including plotting and mulivariate y.
%     panelmanager - Updates for using uipanels.
%     plotgui - Fix colormap use in newer Matlab.
%     cluster - Add ability to push dbscan classes into dataset.
%
% Changes and Bug Fixes in Version 8.5.2
%   BUG FIXES & ENHANCEMENTS
%     gscale
%       Update for NaN handling.
%     mscorr 	
%       Fix for DataSet handling. 
%     plotgui 	
%       Various fixes for 2017b compatibility.
%     polyinterp
%       Fix for correctly handle missing values.
%     readplt
%       Fix for compatibility with older Matlab. 
%     visionairxmlreadr 	
%       Fixed for excluded variables.
%
% Changes and Bug Fixes in Version 8.5.1
%   BUG FIXES & ENHANCEMENTS
%     flucut 	
%       Fixed a bug in flucut correction of inner filter effects.
%     autoimport 	
%       Fix Shimadzu and Vision Air automated importing. 
%     MCCTTool 	
%       Various fixes including improved command line output, java initialize checking, and table performance.
%     analysis 	
%       Add Vision Air PLT model import/export. 
%
% Changes and Bug Fixes in Version 8.5
%   Calibration Transfer
%     New Model-centric Calibration Transfer - Interface to develop instrument specific models with calibration transfer.
%     NLSTD - Create or apply non-linear instrument transfer models (PLS_Toolbox only).
%     SST - Spectral Subspace Transformation calibration transfer.
%     Corn DSO - New calibration transfer demonstration data set added. 80 samples of corn measured on 3 different NIR spectrometers with moisture, oil, protein and starch values for each of the samples is also included.
%   Importers
%     shimadzueemreadr - Imports Shimadzu EEM formatted text files.
%     visionairxmlreadr - Imports Vision Air formatted XML files (X- & Y-Blocks).
%     pltreadr - Imports Vision Air model files (.plt).
%     aqualogreadr - Improved capability of loading multiple files containing samples of varying sizes (PLS_Toolbox only).
%     jascoeemreadr - Improved capability of loading multiple files containing samples of varying sizes (PLS_Toolbox only).
%     hitachieemreadr - Improved capability of loading multiple files containing samples of varying sizes (PLS_Toolbox only).
%     RAWREAD - Added support for new version format (3 & 4) (See MIA_Toolbox).
%     SPGREADR Added new feature, options.spectrumindex now can be an integer, an array of integers (indices, & order doesn't matter), or 'all'. When loading multiple files, options.spectrumindex must be either a single value or 'all'.
%   Other Features and Improvements
%     Cook's Distance - Calculates Cooks Distance for samples in a regression model.
%     RPLS - A recursive PLS and PCR variable selection algorithm. 
%     MANHATTANDIST - Calculate Manhattan Distance between rows of a matrix.
%     Confusionmatrix and Confusiontable - Classification results formatting options added. Can now specify use of mostprobable or strict classification rule.
%     calcdifference - Calculate difference between two datasets.
%     Added GLS Weighting to model optimizer.
%
% Changes and Bug Fixes in Version 8.2.1
%   BUG FIXES & ENHANCEMENTS
%     analysis
%       Add preset of min number of nodes (LVs) to Crossvall for ANN.
%     lwrpred
%       Fix for handling old include with nearest points.
%     modelviewer 	
%       Fixed splithalf plotting behavior in PARAFAC (not plotting when splithalf is not chosen).
%     plotscoreslimits
%       Fix limit shown for Leverages to be 3*# variables / # samples limit recommended by ASTM E1655. 
%     updatemod
%       Updating to add model.detail.globalmodel.xoldinclx.
%
% Changes and Bug Fixes in Version 8.2
%   NEW FEATURES
%     Support for PARAFAC2 in analysis interface.
%     Support exporting PARAFAC models to OpenFluor (http://www.openfluor.org) to match resolved components with published fluorescence spectra.
%     Improved figure placement on high resolution systems.
%     Multi-way support in PLSDA via npls.
%     Add user data (.userdata) component naming (.componentname) to model object for PCA, MCR, PURITY, and PARAFAC models. Accessible from Analysis>Tools menu.
%     Add a Model ID class set to modelselector model for given dataset object.
%     Add ability to calculate RMSEP in modeloptimizer.
%     Fix docking of figures.
%     Savgolcv now works for multivariate Y.
%     Include reorthogonalization step in simpls. 
%   Importers
%     spgreadr - Reads Thermo Fisher SPG files. 
%   BUG FIXES & ENHANCEMENTS
%     coda_dw_interactive 	
%       Add TIC plot.
%     corrspecgui 	
%       Fix for lagging mouse motion commands (piling up).
%     encodexml 	
%       Added option to export compact DSO (works for JSON as well).
%     flucutset 	
%       Can now set first order and second order Rayleigh filtering separately.
%     optionseditor 	
%       Fix for row height, allow adjusting and set default to 18 pixels.
%     ipls 	
%       Now checks for missing data before calling function.
%     lwrpred 	
%       Improved performance.
%       Report indices of the nearest calibration points used in the local model when predicting for a sample.
%     multiblocktool 	
%       Add zoom functionality to help with different resolution screens.
%     spcreadr 	
%       Added spc sub-headers into the dso.userdata field (as a cell array).
%
% Changes and Bug Fixes in Version 8.1.1
%   Importers
%     hitachieemreadr - Reads Hitachi EEM files with Rayleigh removal.
%   BUG FIXES & ENHANCEMENTS
%     adjustaxislimitsgui 	
%         Add X and Y Dir to adjust axis interface.
%     parafac 	
%         Add unimodality without associated nonnegativity to constrainfit.m.
%     comparelcms_sim_interactive 	
%         Fix control sizing and improve code performance.
%     editds 	
%         Increase GUI performance.
%     dendrogram 	
%         Dendrogram's "Keep" feature resets the first row classset to the user's dendrogram selection. However, it keeps the original first row class IDs and class set name. Fix to use new class IDs and set class set name = "Cluster Classes".
%     opusreadr 	
%         Fix "date and time" axisscale creation (based on date and time) to handle time reported as GMT or UTC. Also sort rows in order of increasing timestamp.
%     coda_dw_interactive 	
%         Fix control sizing and improve code performance.
%     lwr 	
%         Expose the 'model.detail.extrap' variable in the LWR Scores Plot.
%     savgol2d 	
%         Add 'full' (uses all cross terms) option.
%     cov_cv 	
%         Added makemonotonic to interp1 DO trick to help interpolation.
%     testrobustnessdemo 	
%         Added demo for testrobustness.
%
% Changes and Bug Fixes in Version 8.1
%   BUG FIXES & ENHANCEMENTS
%     Improved text handling for large/zoomed displays.
%     ann
%       Handle special case of cvi being single-valued in ann. This occurs if using CV with nsplits=2. 
%     aqualogreadr
%       Added dedicated reader for Aqualog ABS data files.
%     cluster 
%       Fix for saving classes from plot.
%     corrspecgui
%       Update placing cursor. Update so default values show up in tree.
%     dataset
%       Fix usage of "history" variable to resolve conflicts with internal Matlab functions. 
%     figbrowser
%       Add menu item for bringing all figures forward.
%       Add new submenu for copying image of figure to clipboard. 
%     genalgplot
%       Did not plot results for the uppermost model (highest RMSECV) in case when using pcolor (number of variables > 100).
%       Ensure that the colorbar uses the same "jet" colormap as the plot uses (Matlab from R2014b do not use jet as the default).
%     lwr
%       Add tsqlim to model, for confidence level specified in options.
%       Fix calculation of X residuals in case of using PCR or PLS local model LWR. This affects calculated Q limit (model.detail.reslim{1}). 
%     modelviewer
%       Fixed an extra window in Parafac2 when the model did not include validation (position 3,4)
%     parafac/parafac2
%       Significant speed improvements.
%     r2calc
%       r2calc was too aggressive in trying to match x and y dimensions by transposing one, unintentionally applied when x and y are square and have same size.
%
% Changes and Bug Fixes in Version 8.0.2
%   BUG FIXES & ENHANCEMENTS
%     Change use of inputname in objects to be Matlab 2015b compatible.
%     editds_defaultimportmethods
%       Fix for importing CSV files, user is no longer prompted for which importer to use. 
%
% Changes and Bug Fixes in Version 8.0.1
%   Importers
%     jascoeemreadr - Reads Jasco EEM files with Rayleigh removal.
%   BUG FIXES & ENHANCEMENTS
%     ann 	
%       Fix for evritip error. 
%     bin2scale 	
%       Fix for input order tracking.
%       Fix for identical scales being past.
%       Fix to allow for small error in scale.
%       Fix for small memory leak. 
%     editds 	
%       Allow sorting of n-way DSOs using axisscale, labels, and classes. 
%     genalg
%       Fix for new resize code causing error.
%     plotgui 	
%       Assure line+points mode always shows when first selected.
%       Assure that linewidth and symbolsize are always used for all types of plots and data (included, excluded, selected).
%       Adjust 3D symbol size and dimming behavior to better match corresponding 2D views.
%       Show any connect classes mode for ALL selected y-items (not just first).
%       Fix for errors when showing excluded data in bar plot mode.
%       Add fix R2014b and 15a in which color of excluded items would not match color of the corresponding included data. 
%     preprocess 	
%       Fix for resize behavior on newer versions of Matlab with Mac (and Linux). Also applies to optionseditor and editds. 
%     scriptexpert 	
%       Fix for resize behavior on newer versions of Matlab with Mac (and Linux). Also applies to [optionseditor] and [editds]. 
%     trendtool
%       Add better memory usage using mean vs mncn. 
%
% Changes and Bug Fixes in Version 8.0
%  Multi-Block, and Model and Data Fusion Tool
%    Multiblock Tool - Interface to view, manipulate, and join data. Can be used for data and model fusion, or multi-block modeling.
%    Join multiple blocks of variables measured on the same samples (alignment based on labels, axis scales, or size).
%    Automatically align and join time-based blocks of data (based on time axis scale).
%    Optionally build models on one or more blocks and join outputs from those blocks (model fusion).
%    Choose and apply block-specific preprocessing before joining.
%    Save multiblock model to use to join new data, including application of defined preprocessing and models.
%    After building model from joined data, Analysis automatically splits loadings into component block segments for ease of interpretation. 
%  Analysis and Models
%    MLSCA - Multi-level simultaneous component analysis method added.
%    Shortcuts to Data Fusion methods Multiblock Tool and Hierarchical Model Builder
%    Re-designed Analysis and Preprocessing menus for ease-of-use and consistency.
%    ANN now supports custom cross-validation.
%    PLSDA variance captured plot now available.
%    confusionmatrix - Report additional quantities for each class: count, classification error, precision and F1 score.
%        Standardize terminology: TP = count, TPR = proportion (rate) for confusion matrix quantities, and labels shown. 
%    simca Better handling of full-rank PCA sub-models (where Q residuals are zero.)
%    Nearest neighbor score distance now normalized to maximum calibration value (standard practice for inlier tests.) 
%  Plotting
%    Additional context-menu options for managing line width and symbol size.
%    Add quick access to class symbol sets in context menu.
%    Significantly faster selection display and "linking" between figures.
%    Connect Classes and View Classes buttons now have drop-down menus to display options.
%    Added Compress X-axis Gaps (click for example) toolbar button Compressgapsbutton.png to remove gaps caused by excluded variables or samples.
%    Improve handling of zoom status in newer versions of Matlab.
%    Better handling of font sizes on different screen sizes and platforms.
%    Fix shifting control position issues with newer versions of Matlab. 
%  Importers
%    Automatic reconciliation of mixed axis scales when importing multiple files (using matchvars). Data will automatically include as much of the original data as possible.
%    omnicreadr New importer for OMNICix HDF5 image files.
%    hjyreadr Support for importing on 64-bit Windows systems and for new LabSpec file formats.
%    textreadr and xlsreadr Improved handling of multiple file import using graphically-selected parsing options. Options selected on first file/sheet are now used on ALL subsequent files/sheets. 
%  Preprocessing
%    glog Generalized Log Transform added to preprocessing options.
%    pqnorm Probabilistic Quotient Normalization added to preprocessing options.
%    glsw Clarified how ELS/EMM and EPO options are related
%    Add support for handling missing data in both normaliz and mscorr (median only). 
%  Other Interfaces
%    Model Optimizer - Better handling of numeric data in comparison table, additional statistics, and improved handling of include field.
%        Add better support for model groupings in PLSDA and SVMDA within model optimizer.
%        Add support for more LWR options
%        LWR models: Add "Survey" button to Analysis window to automatically survey over a range of "Local Points" 
%    Better help integration with newer version of Matlab.
%    Hierarchical Model Builder - Add vertical scrolling. 
%  Model Objects
%    Build and change history now captured in history field of Model Object.
%    Add .scoredistance and .esterror as virtual properties for models. These properties can now be accessed directly from models in PLS_Toolbox or Solo_Predictor scripts. 
%
%  New Command-line Features and Functions
%
%  Misc New Functions
%    eemoutlier - New function for automatically removing outliers in fluorescence PARAFAC models.
%    mlsca - Multi-level Simultaneous Component Analysis.
%    multiblock - Create or apply a multiblock model for joining data.
%    kurtosis - Added kurtosis statistic function to distribution fitting toolbox.
%    skewness - Added skewness statistic function to distribution fitting toolbox. 
%  Command-Line Changes
%    als - Sort components by variance captured (if no constraints otherwise defining order).
%    comparemodels - Report the mean (class count weighted) of Classification Error, Precision, F1 Score for classification models.
%    confusionmatrix - Report additional quantities for each class: count, classification error, precision and F1 score..
%        Standardize terminology: TP = count, TPR = proportion (rate) for confusion matrix quantities, and labels shown. 
%    cov_cv - Changed from SVDS to SVD to improve behavior with nearly-rank-deficient cases.
%    crossval - Better handling of cross-validation when using PLSDA.
%        Convert plsda regression method input to be 'sim' (to speed it up).
%        Recognize when user has passed single-column (either logical or class) and force it to be multi-column logical. 
%    histaxes - Fix for when NaN's are present in data.
%    jmlimit - Better handle degenerate cases when multiple confidence levels are requested (return VECTOR of zeros instead of single zero).
%    matchvars - Add option to input a cell array of dataset objects which will be joined after reconciling variables to make the least changes in data.
%    mdcheck - Allow use of KNN as data replacement method (replace missing data with data from sample(s) which are closest). 
%

echo off
