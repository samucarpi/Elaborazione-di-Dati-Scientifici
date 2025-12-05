% PLS_Toolbox
% Version 9.5 (24944) 04-October-2024
% For use with MATLAB versions newer than 5 years from release date.
% Copyright (c) 1995 Eigenvector Research, Inc.
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%
% Help and information
%   Contents         - This file.
%   helppls          - Context related help on the PLS_Toolbox.
%   readme           - Release notes for this version of the PLS_Toolbox.
%   demos            - Demo list for the PLS_Toolbox.
%   evridebug        - Checks the PLS_Toolbox installation for problems.
%   evriinstall      - Install Eigenvector Research Product.
%   evriuninstall    - Uninstall an Eigenvector Research toolbox.
%   evriupdate       - Check Eigenvector.com for available PLS_Toolbox updates.
%   plsver           - Displays version information.
%  <functionname> demo - Runs a short demo for each function.
%  <functionname> io   - Prints short version of the io.
%  <functionname> help - Accesses the online help.
%
% Plotting, Analysis Aids, and I/O Functions
%   abline           - Draws a line on the current axes with a given slope and intercept.
%   analysis         - Graphical user interface for data analysis.
%   aqualogreadr     - Reads Horiba Aqualog files with Raleigh removal.
%   areadr           - Reads ascii data and strips header.
%   asdreadr         - Imports data from Analytical Spectral Devices (ASD) Indico (Versions 6 and 7) data files.
%   asfreadr         - Reads AIT ASF files.
%   autoexport       - Exports a DataSet object to a file of the specified format.
%   autoimport       - Automatically reads specified file. Handles all standard filetypes.
%   b3spline         - Univariate spline fit and prediction.
%   boxplot          - Box plot showing various statistical properties of a data matrix.
%   classcenter      - Centers classes in data to the mean of each class.
%   conload          - Congruence loadings for PARAFAC, TUCKER and NPLS
%   dp               - Draws a diagonal line on an existing figure.
%   ellps            - Plots an ellipse on an existing figure.
%   envireadr        - Reads ENVI image files.
%   experimentreadr  - Importer for automatic importing and alignment of X and Y blocks.
%   explode          - Extracts variables from a structure array to the workspace.
%   exportfigure     - Automatically export figures to an external program.
%   figuretheme      - Resets a figure background and axes to a specified color.
%   aqualogreadr     - Read HORIBA Aqualog files.
%   getpidata        - Uses the current PI connection to construct a DSO from 'taglist'.
%   gselect          - Selects objects in a figure (various selection styles).
%   gwscanreadr      - Reads Guided Wave scan and autoscan files.
%   histaxes         - Creates a histogram of the content of a given axes.
%   hitachieemreadr  - Reads Hitachi EEM files with Rayleigh removal.
%   hjyreadr         - Reads HORIBA files (Windows Only).
%   hline            - Adds horizontal lines to figure at specified locations.
%   importtool       - GUI for designating column/row data types. 
%   infobox          - Display a string in an information box.
%   jascoeemreadr    - Reads Jasco EEM files with Rayleigh removal.
%   jcampreadr       - Reads a JCAMP file into a DataSet object
%   matchrows        - Matches up rows from two DataSet objects using labels or sizes.
%   mplot            - Automatic creation of subplots and plotting.
%   mtfreadr         - Read AdventaCT Multi-Trace Format (MTF) files.
%   netcdfreadr      - Reads in netCDF files and outputs a DataSet and or structure.
%   opusreadr        - Reads Bruker OPUS files.
%   parsemixed       - Parse numerical and text data into a DataSet Object.
%   parsexml         - Convert XML file to a MATLAB structure.
%   pcolormap        - Pseudocolor plot with labels and colorbar.
%   pdfreadr         - Importer for AIT PIONIR PDF files.
%   pereadr          - Read PerkinElmer files.
%   ploteigen        - Builds dataset object of eigenvalues/RMSECV information.
%   plotgui          - Interactive DataSet object viewer.
%   plotloads        - Extract and display loadings information from a model structure.
%   plotmonotonic    - Plot lines with breaks when the x-value "doubles-back" on itself. 
%   plotscores       - Extract and display score information from a model.
%   pltreadr         - Imports Vision Air .plt model as an EVRI model.
%   plttern          - Plots a 2D ternary diagram.
%   pltternf         - Plots a 3D ternary diagram with frequency of occurrence.
%   querydb          - Executes a query on a database defined by connection string.
%   rdareadr         - Reads in a Siemens .rda file into a DataSet Object.
%   readplt          - Reads a Vision Air plt file and imports as a PLS_Toolbox model object.
%   readVisionAirSampleXML - Vision Air function to import Vision Air Formatted XML files (spectral data) into Matlab.
%   reportwriter     - Write a summary of the analysis including associated figures to html/word/powerpoint.
%   rwb              - Red white and blue color map.
%   setpath          - Modifies and saves current directory to the MATLAB search path.
%   shimadzueemreadr - Reads Shimadzu EEM files with Rayleigh removal.
%   snabsreadr       - StellarNet ABS file importer.
%   spareadr         - Reads Thermo Fisher SPA files.
%   spgreadr         - Reads Thermo Fisher SPG files. 
%   spcreadr         - Reads Galactic SPC files.
%   subgroupcl       - Displays a confidence ellipse for points in a two-dimensional plot.
%   symbolstyle      - Interface to modify class symbols.
%   textreadr        - Reads an ASCII or .XLS file in as a DataSet Object.
%   trendtool        - Univariate trend analysis tool.
%   visionairxmlreadr - imports .xml files that are Vision Air formatted.( driver function for readVisionAirSampleXML)
%   vline            - Adds vertical lines to figure at specified locations.
%   writeasf         - Writes AIT ASF files from a dataset object.
%   writecsv         - Export a DataSet object to a comma-separated values (CSV) file.
%   writeplt         - Exports an EVRI model as a Vision Air .plt model.
%   writespc         - Writes Galactic SPC files. 
%   xclgetdata       - Extracts matrix from an Excel spreadsheet.
%   xclputdata       - Write matrix to an Excel spreadsheet.
%   xlsreadr         - Reads .XLS files from MS Excel and other spreadsheets.
%   xyreadr          - Reads one or more ASCII XY or XY... files into a DataSet object.
%   yscale           - Rescales the y-axis limits on each subplot in a figure.
%   zline            - Adds vertical lines to 3D figure at specified locations.
%   xmlreadr         - Convert XML file to a MATLAB structure.
%
% Data Editing, Scaling, and Preprocessing
%   alignpeaks       - Calibrates wavelength scale using standard peaks.
%   alignspectra     - Calibrates wavelength scale using standard spectrum.
%   arithmetic       - Apply simple arithmetic operations to all or part of dataset.
%   asinhx           - Arcsinh transform.
%   asinsqrt         - Arcsin square root transformation.
%   auto             - Autoscales matrix to mean zero unit variance.
%   baseline         - Subtracts a polynomial baseline offset from spectra.
%   baselineds       - Wrapper for baselining functions.
%   baselinew        - Baseline using windowed polynomial filter.
%   batchalign       - Convert data columns based on matching ref col to target vector. 
%   batchdigester    - Parse wafer or batch data into MPCA or Summary PCA form.
%   batchfold        - Transform batch data into dataset for analysis. 
%   batchmaturity    - Batch process model and monitoring. 
%   classcentroid    - Centers data to the centroid of all classes. 
%   coadd            - Reduce resolution through combination of adjacent variables or samples.
%   cov_cv           - Estimation of a regularized inverse covariance matrix.
%   delsamps         - Deletes samples (rows) or variables (columns) from data matrices.
%   editds           - Editor for DataSet Objects.
%   emscorr          - Extended Multiplicative Scatter Correction (EMSC). 
%   excludemissing   - Automatically exclude too-much missing data in a matrix.
%   flucut           - Remove scatter from fluorescence EEM data.
%   gapsegment       - Provides Gap-Segment derivatives.
%   glsw             - Generalized least-squares weighting/preprocessing.
%   gscale           - Group/block scaling for a single or multiple blocks.
%   gscaler          - Applies group/block scaling to submatrices of a single matrix.
%   hrmethodreadr    - Convert a Kaiser HoloReact band integration methods into a preprocessing structure.
%   kennardstone     - Selects a subset of samples by Kennard-Stone algorithm.
%   lamsel           - Determines indices of wavelength axes in specified ranges.
%   line_filter      - spectral filtering via convolution, and deconvolution.
%   logdecay         - Mean centers and variance scales a matrix using the log decay of the variable axis.
%   lsq2top          - Fits a polynomial to the top/(bottom) of data.
%   lsq2topb         - Fits a polynomial to the top/(bottom) of data.
%   mdcheck          - Missing Data Checker and infiller.
%   med2top          - Fits a constant to top/(bottom) of data.
%   medcn            - Median center scales matrix to median zero.
%   minmax           - Perform min-max scaling, sometimes called "unity normalization". 
%   mncn             - Scale matrix to mean zero.
%   mscorr           - Multiplicative scatter/signal correction (MSC).
%   multiblock       - Create or apply a multiblock model for joining data.
%   normaliz         - Normalize rows of matrix.
%   oplecorr         - Optical Path-Length Estimation and Correction.
%   oscapp           - Applies OSC model to new data.
%   osccalc          - Calculates orthogonal signal correction (OSC).
%   poissonscale     - Perform Poisson scaling with scaling offset.
%   polyinterp       - Polynomial interpolation, smoothing, and differentiation.
%   polytransform    - Add polynomial and cross terms to data matrix.
%   pr_entropy       - Calculate pattern recognition entropy (PRE), Shannon entropy.
%   preprocess       - Selection and application of standard preprocessing structures.
%   preprocessiterator - Create array of preprocessing combinations. 
%   preprouser       - User-defined preprocessing methods.
%   registerspec     - Shift spectra based on expected peak locations.
%   rescale          - Scales data back to original scaling.
%   sammon           - Computes Sammon projection for data or map. 
%   savgol           - Savitzky-Golay smoothing and differentiation.
%   savgolcv         - Cross-validation for Savitzky-Golay smoothing and differentiation.
%   scale            - Scales data using specified means and std. devs.
%   shuffle          - Randomly re-orders matrix and multiple blocks rows.
%   snv              - Standard normal variate scaling.
%   specedit         - GUI for selecting spectral regions on a plot.
%   splitcaltest     - Splits randomly ordered data into calibration and test sets.
%   super_reduce     - Eliminates highly correlated variables.
%   unfoldm          - Rearranges (unfolds) an augmented matrix to row vectors.
%   unfoldmw         - Unfolds multiway arrays along specified order.
%   windowfilter     - Spectral filtering.
%   wlsbaseline      - Weighted least squares baseline function.
%   wsmooth          - Whittaker smoother. 
%
% Model statistics and related utilities
%   aqualogreadr     - Renamed from fluoromaxreadr.
%   chilimit         - Chi-squared confidence limits from sum-of-squares residuals.
%   correctbias      - Automatically adjust regression model for bias and slope errors.
%   datahat          - Calculates the model estimate and residuals of the data.
%   diviner          - Generate optimal PLS models with varying preprocessing and variable selection.
%   ensemble         - Predictions based on multiple calibrated regression models.
%   ils_esterror     - Estimation error for ILS models.
%   jmlimit          - Confidence limits for Q residuals via Jackson-Mudholkar.
%   knnscoredistance - Calculate the average distance to the k-Nearest Neighbors in score space.
%   modeloptimizer   - Create model for iterating over analysis models.
%   qconcalc         - Calculate Q residuals contributions for predictions on a model.
%   manrotate        - Graphical interface to manually rotate model loadings.
%   permutetest      - Permutation testing for regression and classification models.
%   permuteplot      - Create plot of permutation test results.
%   permuteprobs     - Display probabilities derrived from permutation testing.
%   residuallimit    - Estimates confidence limits for sum squared residuals.
%   reviewmodel      - Examines a standard model structure for typical problems.
%   tconcalc         - Calculate Hotellings T2 contributions for predictions on a model.
%   tsqlim           - Confidence limits for Hotelling's T^2.
%   tsqmtx           - Calculates matrix for T^2 contributions for PCA.
%   tsqqmtx          - Calculates matrix for T^2+Q contributions for PCA and MPCA.
%
% Statistics, ANOVA, Experimental design, Miscellaneous
%   anova1w          - One-way analysis of variance.
%   anova2w          - Two-way analysis of variance.
%   classsummary     - List class and axisscale distributions for a DataSet.
%   corrmap          - Correlation map with variable grouping.
%   cov_cv -         - Estimation of a regularized inverse covariance matrix.
%   distslct         - Selects samples on outside of data space.
%   doptimal         - Selects samples based on D-Optimal criteria.
%   durbin_watson    - Criterion for measure of continuity.
%   factdes          - Full factorial design of experiments.
%   ffacdes1         - Fractional factorial design of experiments.
%   ftest            - F test and inverse F test statistic.
%   percentile       - Finds percentile point (similar to MEDIAN).
%   reducennsamples  - Selects a subset of samples by removing nearest neighbors.
%   stdsslct         - Selects data subsets (often for use in standardization).
%   ttestp           - Evaluates t-distribution and its inverse.
%   xycorrcoef       - Correlation coefficients between variables in X-block and variables in Y-block.
%
% Principal Components Analysis
%   estimatefactors  - Estimate number of significant factors in multivariate data.
%   mlpca            - Maximum likelihood principal components analysis.
%   pca              - Principal components analysis.
%   pcaengine        - Principal Components Analysis computational engine.
%   ssqtable         - Displays variance captured table for model.
%   tsne             - t-distributed Stochastic Neighbor Embedding.
%   umap             - Uniform Manifold Approximation and Projection (Unsupervised).
%   varcap           - Variance captured for each variable in PCA model.
%   varimax          - Orthogonal rotation of loadings.
%
% Curve Resolution and Evolving Factor Analysis
%   als              - Alternating Least Squares computational engine.
%   als_sti          - Alternating least squares with shift invariant tri-linearity.
%   coda_dw_interactive - Interactive version of CODA_DW.
%   coda_dw          - Calculates values for the Durbin_Watson criterion of columns of data set.
%   comparelcms_simengine  - Calculational Engine for comparelcms.
%   comparelcms_sim_interactive - Interactive interface for COMPARELCMS.
%   corrspec         - Resolves correlation spectroscopy maps.
%   corrspecgui      - Interactive GUI to perform correlation spectroscopy.
%   dispmat          - DISPMAP Calculates the dispersion matrix of two spectral data sets.
%   evolvfa          - Evolving factor analysis (forward and reverse).
%   ewfa             - Evolving window factor analysis.
%   mcr              - Multivariate curve resolution with constraints.
%   purity           - Self-modeling mixture analysis method based on purity of variables or spectra.
%   purityengine     - Calculates purity values of columns of data set.
%   wtfa             - Window target factor analysis.
%
% Cluster Analysis and Classification Functions
%   anglemapper      - Classification based on angle measures between signals.
%   anndlda          - Artificial Neural Network Deep Learning for classification.
%   asca             - Simultaneous Component Analysis.
%   class2logical    - Create a PLSDA logical block from class assignments.
%   cluster          - Agglomerative and K-means cluster analysis with dendrograms.
%   dbscan           - Density-based automatic sample clustering.
%   discrimprob      - Discriminate probabilities for continuous predicted values.
%   knn              - K-nearest neighbor classifier.
%   knnscoredistance - Calculate the average distance to the k-Nearest Neighbors in score space.
%   lda              - Linear discriminant analysis.
%   lregda           - Logistic Regression discriminant analysis.
%   manhattandist    - Calculate Manhattan Distance betweem rows of a matrix.
%   mlsca            - Multi-level Simultaneous Component Analysis.
%   plsda            - Partial least squares discriminant analysis.
%   plsdaroc         - Calculate and display ROC curves for PLSDA model.
%   plsdthres        - Bayesian threshold determination for PLS Discriminate Analysis.
%   roccurve         - Calculate and display ROC curve(s) for yknown and ypred.
%   simca            - Soft Independent Method of Class Analogy.
%   svmda            - Support Vector Machine (LIBSVM) for classification.
%   xgbda            - Gradient Boosted Tree Ensemble for classification (Discriminant Analysis).
%
% Multi-way and Image Functions
%   alignmat         - Alignment of matrices and N-way arrays.
%   corcondia        - Evaluates consistency of PARAFAC model.
%   coreanal         - Analysis of the core array of a Tucker model.
%   corecalc         - Calculate the Tucker3 core given the data array and loadings.
%   eemoutlier       - Function for automatically removing outliers in fluorescence PARAFAC models.
%   gram             - Generalized rank annihilation method.
%   modelviewer      - Visualization tool for multi-way models.
%   mpca             - Multi-way (unfold) principal components analysis.
%   npls             - Multilinear-PLS (N-PLS) for true multi-way regression.
%   npreprocess      - Preprocessing of multi-way arrays.
%   outerm           - Computes outer product of any number of vectors.
%   parafac          - Parallel factor analysis for n-way arrays.
%   parafac2         - Parallel factor analysis for unevenly sized n-way arrays.
%   splithalf        - Performs splithalf validation of PARAFAC models.
%   tucker           - Analysis for n-way arrays.
%
% Linear and Non-Linear Regression
%   ann              - Artificial Neural Network regression models. 
%   anndl            - Artificial Neural Network Deep Learning.
%   calccvbias       - Calculate the Cross-Validation Bias from a cross-validated model. 
%   cls              - Classical Least Squares regression for multivariate Y.
%   clsti            - Temperature interpolated classical least squares.
%   cooksd           - Calculates Cooks Distance based on regression model.
%   correctbias      - Automatically adjust regression model for bias and slope errors.
%   cr               - Continuum Regression for multivariate y.
%   crcvrnd          - Cross-validation for continuum regression.
%   crossval         - Cross-validation for decomposition and linear regression.
%   dspls            - Partial Least Squares computational engine using Direct Scores algorithm.
%   evrishapley      - Calculate a variable's contribution using Shapley Values.
%   fastnnls         - Fast non-negative least squares.
%   fasternnls       - Fast non-negative least squares with selective constraints.
%   figmerit         - Analytical figures of merit for multivariate calibration.
%   frpcrengine      - Engine for full-ratio PCR regression.
%   leverag          - Calculate sample leverages.
%   lwr              - Locally weighted regression for multivariate Y.
%   lwrpred          - Predictions based on locally weighted regression models.
%   mlr              - Multiple Linear Regression for multivariate Y.
%   mlrengine        - Multiple Linear Regression computational engine.
%   modlpred         - Predictions using standard model structures.
%   modlrder         - Displays model info for standard model structures.
%   nippls           - NIPALS Partial Least Squares computational engine.
%   pcr              - Principal components regression for multivariate Y.
%   pcrengine        - Principal Component Regression computational engine.
%   pls              - Partial least squares regression for multivariate Y.
%   plsnipal         - NIPALS algorithm for one PLS latent variable.
%   polypls          - PLS regression with polynomial inner-relation.
%   regcon           - Converts regression model to y = ax + b form.
%   ridge            - Ridge regression by Hoerl-Kennard-Baldwin.
%   ridgecv          - Ridge regression by cross validation.
%   rinverse         - Calculate pseudo inverse for PLS, PCR and RR models.
%   rmse             - Calculate Root Mean Square Difference(Error).
%   simpls           - Partial Least Squares computational engine using SIMPLS algorithm.
%   sratio           - Calculates selectivity ratio for a given regression model.
%   stepwise_regrcls - Stepwise CLS engine.
%   svm              - Support Vector Machine (LIBSVM) for regression or classification. 
%   varcapy          - Calculate percent y-block variance captured by a PLS regression model.
%   vip              - Calculate Variable Importance in Projection from regression model.
%   vipnway          - Calculate Variable Importance in Projection from NPLS model.  
%   xgb              - Gradient Boosted Tree (XGBoost) for regression.
%
% Variable Selection
%   calibsel         - Statistical procedure for variable selection.
%   fullsearch       - Exhaustive Search Algorithm for small problems.
%   gaselctr         - Genetic algorithm for variable selection with PLS.
%   genalg           - Genetic Algorithm for Variable Selection.
%   genalgplot       - Plot GA results using selected variable plot, color-coded by RMSECV.
%   ipls             - Interval PLS and forward/reverse MLR variable selection.
%   rpls             - Recursive variable selection algorithm using PLS/PCR.
%
% Multivariate Instrument Standardization
%   calcdifference   - Calculate difference between two datasets.
%   caltransfer      - Create or apply calibration and instrument transfer models.
%   deresolv         - Changes high resolution spectra to low resolution.
%   MCCTObject       - Holds all elemets for modelcentric calibration transfer.
%   nlstd            - Standardization based on nonlinear methods.
%   stdfir           - Standardization based on FIR modelling.
%   stdgen           - Piecewise and direct standardization transform generator.
%   stdize           - Applies transform from STDGEN to new spectra.
%
% MSPC and Identification of Finite Impulse Response Models
%   autocor          - Auto-correlation function for time series data.
%   crosscor         - Cross-correlation function for time series data.
%   fir2ss           - Transform FIR model into equivalent state space model.
%   plspulsm         - Identifies FIR dynamics models for MISO systems.
%   plsrsgcv         - Generate PLS models for MSPC with cross-validation.
%   plsrsgn          - Generates a matrix of PLS models for MSPC.
%   replace          - Replaces variables based on factor-based models.
%   wrtpulse         - Create input/output matrices for dynamic model identification.
%
% Model Utilities
%   browse           - PLS_Toolbox Toolbar and Workspace browser.
%   choosencomp      - GUI to select number of components from SSQ table.
%   compressmodel    - Remove references to unused variables from a model.
%   copydsfields     - Copies informational fields between datasets and/or models.
%   encodemodelbuilder - Create MATLAB m-code which will regenerate a given model.
%   evrimodel        - EVRI Model Object. 
%   hmac             - Automatic Hierarchical Model Builder Object for Classification.
%   ismodel          - Returns boolean TRUE if input object is a standard model structure.
%   matchvars        - Align variables of a dataset to allow prediction with a model.
%   minimizemodel    - Shrinks model by removing non-critical information. 
%   modelcache       - Stores and retrieves models in the model cache.
%   modelselector    - Create or apply a model selector model.
%   modelselectorgui - Graphical Interface to built ModelSelector models 
%   modelstruct      - Constructs an empty model structure.
%   reportwriter     - Write a summary of the analysis including associated figures to html/word/powerpoint
%   reviewcrossval   - Examines cross-validation settings for typical problems.
%   reviewmodel      - Examines a standard model structure for typical problems.
%   testrobustness   - Test regression model for robustness to various effects.
%   updatemod        - Update model structure to be compatible with the current version.
%
% Programming Utilities
%   besttime         - Returns a string describing the time interval provided (in seconds).
%   cellne           - Compares two cells for inequality in size and/or values.
%   centerfigure     - Places a given figure into a centered default position.
%   checkmlversion   - Check current version of Matlab against intput version and comparison.
%   clipboard_image  - Copy and paste images to/from the system clipboard.
%   contents         - Mfile of functions to enable Matlab helpwin.
%   encode           - Translates a variable into matlab-executable code.
%   erdlgpls         - Error dialog.
%   evribase64       - Base64 encode/decode object encodes and decodes double from base64 encoding.
%   evricompatibility  - Tests for inter-product compatibility of Eigenvector toolboxes
%   evridebug        - Checks the PLS_Toolbox installation for problems.
%   evridir          - Locate and or create EVRI home directory.
%   evrihelpconfig   - Configure info.xml file so help will work correctly. 
%   evriinstall      - Install Eigenvector Research Product.
%   evrimovepath     - Move all Eigenvector products to the top or bottom of the Matlab path.
%   evrirelease      - Returns Eigenvector product release number.
%   evrireporterror  - Gathers error information and optionally reports it.
%   evritraperror    - Utility to retrieve error information for debugging purposes.
%   evriuninstall    - Uninstall an Eigenvector Research toolbox.
%   evriupdate       - Check Eigenvector.com for available PLS_Toolbox updates.
%   exportfigure     - Automatically export figures to an external program.
%   figbrowser       - Browser with icons of all Matlab figures.
%   findindx         - Finds the index of the array element closest to value r.
%   getdatasource    - Extract summary dataset info.
%   getmlversion     - Returns current Matlab version as an integer.
%   grootmanager     - Manage and update MATLAB graphics root object properties.
%   grooteditor      - Interface to GROOTMANAGER.
%   lddlgpls         - Dialog to load variable from workspace or MAT file.
%   moveobj          - Interactively reposition graphics objects.
%   helppls          - Context related help on the PLS_Toolbox.
%   readme           - Release notes for this version of the PLS_Toolbox.
%   reversebytes     - Flips order of bytes in a word.
%   string_x         - Add backslash before troublesome TeX characters.
%   svdlgpls         - Dialog to save variable to workspace or MAT file.
%   unhist           - Create a vector whose values follow an empirical distribution. 
%
% PLS_Toolbox Demonstrations
%   datasetdemo      - Demonstrates use of the dataset object.
%   demos            - Demo list for the PLS_Toolbox.
%   linmodeldemo     - Demo of the CROSSVAL, MODLRDER, PCR, PLS, PREPROCESS and SSQTABLE functions.
%   loopfilereadr    - An example function for reading files in a loop from a directory.
%   projdemo         - Demo of the MLR, PCR, and PLS regression vectors.
%   statdemo         - Elementary stats, t test, F test and AVOVA.
%   stddemo          - Demo of the STDSSLCT, STDGEN, and OSCCALC functions.
%
% PLS_Toolbox Test Data Sets
%   alcohol          - Biological fluid analysis of alcoholics for discriminant analysis.
%   aminoacids       - Fluorescence EEM of 5 samples for PARAFAC.
%   arch             - Archeological artifact XRF data for PCA amd SIMCA examples.
%   bread            - Sensory evaluation of breads.
%   comparevars      - Compares two variables of any type and returns differences.
%   dorrit           - EEM of 27 samples with 4 flourophores for PARAFAC.
%   etchdata         - Engineering process data from semiconductor metal etch (MPCA).
%   fia              - Flow Injection Analysis of hydroxy-benzaldehydes.
%   FTIR_microscopy  - FTIR microscopy transect spectra of a three-layer polymer laminate.
%   halddata         - Hald cement curing data.
%   lcms             - LC/MS electrospray of 15 surfactant solution.
%   lcms_compare1    - Select data from LC/MS electrospray data set.
%   lcms_compare2    - Select data from LC/MS electrospray data set.
%   lcms_compare3    - Select data from LC/MS electrospray data set.
%   MS_time_resolved   - Direct probe time profile MS of three color-coupling compounds.
%   nir_data         - NIR spectra of pseudo gasoline samples for STDDEMO.
%   nmr_data         - NMR data for GRAM demo.
%   oesdata          - Optical emission spectra from metal etch.
%   paint            - Non-linear paint formulation data.
%   pcadata          - Slurry Fed Ceramic Melter (SFCM) data.
%   plsdata          - SFCM data for PCR and PLS demos.
%   plslogo          - Generates PLS_Toolbox CR surface logo.
%   projdat          - Projection demo data for PROJDEMO.
%   pulsdata         - Time series data for PLSPULSM demo.
%   raman_time_resolved - Raman spectra of a time resolved reaction.
%   replacedata      - SFCM data for REPLACEDEMO.
%   sawdata          - Surface acoustic wave sensor data for organic vapors.
%   statdata         - Data sets for ANOVA and statistics STATDEMO.
%   sugar            - Fluorescence EEM N-way data set.
%   wine             - Wine demographic data set for PCA example.
%   wineregion       - Metal Composition of Wines for classification by region.
%   areadrdemtext.txt   - Text file used by AREADRDEMO.
%   textreadrdata.txt    - Text file used by TEXTREADRDEMO.
%   Redbeerdata.xls     - Example spreadsheet for "Intro to MATLAB".
%
% See also the contents for PLS_Toolbox/utilities folder
