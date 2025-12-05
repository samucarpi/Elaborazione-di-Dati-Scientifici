function tbxStruct = demos
%DEMOS Demo list for the PLS_Toolbox.

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 1/27/01

%This function follows the example in 
%toolbox-blockset integration instructions.doc
%written by J. Tung

if nargout==0, demo toolbox 'PLS_Toolbox'; return; end

tbxStruct.Name = 'PLS_Toolbox';
tbxStruct.Type = 'Toolbox';

tbxStruct.Help = cell(2,1);
tbxStruct.Help = {
  ' PLS_Toolbox contains the foremost collection ',
  ' of tools for chemometrics and multivariate analysis. ',
  ' Included are algorithms for single and multi-block ',
  ' analysis, GUI, and command line functions for Principal ',
  ' Components Analysis, linear and non-linear regression, ',
  ' multi-way routines, multivariate image analysis, ',
  ' classification, and more.',
  ' ',
  [' "<functionname> demo" shows a short demo of each function.', 10],
  [' "<functionname> io" to get a list of the function I/O.<br>', 10],
  [' "<functionname> help" to get online help on each function.<br>', 10],
  ' "help <functionname>" to get help as usual.' };

tbxStruct.DemoList = { 'ALIGNMAT alignment of matrices and N-way arrays.' 'alignmat(''demo'')' '' ;
  'ALS Alternating Least Squares computational engine' 'als(''demo'')' '' ;
  'ANOVA1W One way analysis of variance' 'anova1w(''demo'')' '' ;
  'ANOVA2W Two way analysis of variance' 'anova2w(''demo'')' '' ;
  'AREADR reads ascii text and converts to a data matrix.' 'areadr(''demo'')' '' ;
  'AUTOCOR Autocorrelation of time series' 'autocor(''demo'')' '' ;
  'AUTO Autoscales matrix to mean zero unit variance' 'auto(''demo'')' '' ;
  'BASELINE Subtracts a polynomial baseline offset from spectra.' 'baseline(''demo'')' '' ;
  'BASELINEW - Baseline using windowed polynomial filter' 'baselinew(''demo'')' '' ;
  'CALIBSEL variable selection' 'calibsel(''demo'')' '' ;
  'CHILIMIT Chi-squared confidence limits from sum-of-squares residuals' 'chilimit(''demo'')' '' ;
  'CLUSTER KNN and K-means cluster analysis with dendrograms' 'cluster(''demo'')' '' ;
  'COADD reduce resolution through combination of adjacent variables or samples' 'coadd(''demo'')' '' ;
  'COMPRESSMODEL - remove references to unused variables from a model' 'compressmodel(''demo'')' '' ;
  'CORCONDIA for evaluating consistency of PARAFAC model. ' 'corcondia(''demo'')' '' ;
  'COREANAL Analysis of the core array of a Tucker model' 'coreanal(''demo'')' '' ;
  'CORECALC calculate the Tucker3 core given the data array and loadings ' 'corecalc(''demo'')' '' ;
  'CORRMAP Correlation map with variable grouping' 'corrmap(''demo'')' '' ;
  'CRCVRND Cross-validation for CR models using SDEP' 'crcvrnd(''demo'')' '' ;
  'CR Continuum Regression for multivariate y' 'cr(''demo'')' '' ;
  'CROSSCOR Cross correlation of time series' 'crosscor(''demo'')' '' ;
  'CROSSVAL Cross-validation for PCA, PLS, MLR, and PCR' 'crossval(''demo'')' '' ;
  'DATAHAT calculates the model estimate and residuals of the data' 'datahat(''demo'')' '' ;
  'DELSAMPS Deletes samples (rows) or variables (columns) from data matrices.' 'delsamps(''demo'')' '' ;
  'DERESOLV Changes high resolution spectra to low resolution' 'deresolv(''demo'')' '' ;
  'DISCRIMPROB calculate Discriminate probabilities of discrete classes for continuous predicted values' 'discrimprob(''demo'')' '' ;
  'DISTSLCT selects samples on outside of data space' 'distslct(''demo'')' '' ;
  'DOPTIMAL selection of samples from a candidate matrix.' 'doptimal(''demo'')' '' ;
  'DP draws a diagonal line on an existing figure.' 'dp(''demo'')' '' ;
  'DURBIN_WATSON criterion for measure of continuity.' 'durbin_watson(''demo'')' '' ;
  'ELLPS plots an ellipse on an existing figure' 'ellps(''demo'')' '' ;
  'ENCODE Translates a variable into matlab-executable code' 'encode(''demo'')' '' ;
  'EVOLVFA performs forward and reverse evolving factor analysis.' 'evolvfa(''demo'')' '' ;
  'EWFA Evolving Window factor Analysis' 'ewfa(''demo'')' '' ;
  'EXPLODE extracts variables from a structure array to the workspace' 'explode(''demo'')' '' ;
  'FACTDES full factorial design of experiments.' 'factdes(''demo'')' '' ;
  'FASTNNLS Fast non-negative least squares' 'fastnnls(''demo'')' '' ;
  'FFACDES1 2^(k-p) fractional factorial design of experiments.' 'ffacdes1(''demo'')' '' ;
  'FIGMERIT Analytical figures of merit for multivariate calibration' 'figmerit(''demo'')' '' ;
  'FINDINDX - finds the index of the array element closest to value r' 'findindx(''demo'')' '' ;
  'FIR2SS Transform FIR model into equivalent state space model' 'fir2ss(''demo'')' '' ;
  'FRPCR full-ratio PCR calibration and prediction' 'frpcr(''demo'')' '' ;
  'FRPCRENGINE engine for full-ratio PCR regression.' 'frpcrengine(''demo'')' '' ;
  'FTEST Inverse F test and F test' 'ftest(''demo'')' '' ;
  'FULLSEARCH Exhaustive Search Algorithm for small problems.' 'fullsearch(''demo'')' '' ;
  'GASELCTR genetic algorithm for variable selection with PLS' 'gaselctr(''demo'')' '' ;
  'GENALGPLOT selected variable plot, color-coded by RMSECV for GA results' 'genalgplot(''demo'')' '' ;
  'GRAM Generalized rank annihilation method ' 'gram(''demo'')' '' ;
  'GSCALE Performs group/block scaling for submatrices of a single matrix.' 'gscale(''demo'')' '' ;
  'GSCALER Applies group/block scaling to submatrices of a single matrix.' 'gscaler(''demo'')' '' ;
  'GSELECT selects subset of plotted line object points using a variety of interactive graphical modes' 'gselect(''demo'')' '' ;
  'HLINE adds horizontal lines to figure at specified locations' 'hline(''demo'')' '' ;
  'JMLIMIT confidence limits for Q residuals via Jackson-Mudholkar' 'jmlimit(''demo'')' '' ;
  'LAMSEL Determines indices of wavelength axes in specified ranges' 'lamsel(''demo'')' '' ;
  'LEVERAG Calculate sample leverages' 'leverag(''demo'')' '' ;
  'LINMODELDEMO Demo of the CROSSVAL, MODLRDER, PCR, PLS, PREPROCESS and SSQTABLE functions' 'linmodeldemo' '' ;
  'LSQ2TOP Fits a polynomial to the top/(bottom) of data.' 'lsq2top(''demo'')' '' ;
  'LWRPRED Predictions based on locally weighted regression models' 'lwrpred(''demo'')' '' ;
  'LWRXY Predictions based on lwr models with y-distance weighting' 'lwrxy(''demo'')' '' ;
  'MDCHECK Missing Data Checker and infiller' 'mdcheck(''demo'')' '' ;
  'MLPCA Maximum likelihood principal components analysis' 'mlpca(''demo'')' '' ;
  'MNCN Mean center scales matrix to mean zero.' 'mncn(''demo'')' '' ;
  'MODELVIEWER visualization of fitted multi-way models.' 'modelviewer(''demo'')' '' ;
  'MODLPRED Predictions based on regression models.' 'modlpred(''demo'')' '' ;
  'MODLRDER Prints model information for standard model structures' 'modlrder(''demo'')' '' ;
  'MPCA Multi-way Principal Components Analysis' 'mpca(''demo'')' '' ;
  'MSCORR Multiplicative scatter correction (MSC)' 'mscorr(''demo'')' '' ;
  'NCROSSVAL Cross-validation for NPLS' 'ncrossval(''demo'')' '' ;
  'NIPPLS NIPALS Partial Least Squares computational engine' 'nippls(''demo'')' '' ;
  'NORMALIZ Normalizes rows of matrix' 'normaliz(''demo'')' '' ;
  'NPLS multilinear-PLS (N-PLS) for true multi-way regression' 'npls(''demo'')' '' ;
  'NPREPROCESS preprocessing of multi-way arrays' 'npreprocess(''demo'')' '' ;
  'OSCAPP Applies OSC model to new data' 'oscapp(''demo'')' '' ;
  'OSCCALC Calculates orthogonal signal correction' 'osccalc(''demo'')' '' ;
  'OUTERM Outer product of any number of vectors with multiple factors' 'outerm(''demo'')' '' ;
  'PARAFAC2 for n-way arrays with shifts or irregular sized slabs' 'parafac2(''demo'')' '' ;
  'PARAFAC Parallel factor analysis for n-way arrays' 'parafac(''demo'')' '' ;
  'PCA Principal components analysis' 'pca(''demo'')' '' ;
  'PCAENGINE Principal Components Analysis computational engine' 'pcaengine(''demo'')' '' ;
  'PCAPRO Projects new data on old principal components model.' 'pcapro(''demo'')' '' ;
  'PCOLORMAP Pseudocolor plot with labels and colorbar.' 'pcolormap(''demo'')' '' ;
  'PCR Principal components regression: multivariate inverse least squares regession' 'pcr(''demo'')' '' ;
  'PCRENGINE Principal Component Regression computational engine' 'pcrengine(''demo'')' '' ;
  'PERCENTILE Finds percentile point (similar to MEDIAN).' 'percentile(''demo'')' '' ;
  'PLOTEIGEN build dataset object of eigenvalues/RMSECV information.' 'ploteigen(''demo'')' '' ;
  'PLOTLOADS extract and display loadings information from a model structure' 'plotloads(''demo'')' '' ;
  'PLOTSCORES extract and display score information from a model.' 'plotscores(''demo'')' '' ;
  'PLSDA - Partial least squares discriminant analysis.' 'plsda(''demo'')' '' ;
  'PLS Partial least squares regression via NIPALS or SIMPLS algorithm' 'pls(''demo'')' '' ;
  'PLSDTHRES Bayesian threshold determination for PLS Discriminate Analysis' 'plsdthres(''demo'')' '' ;
  'PLSNIPAL NIPALS algorithm for PLS' 'plsnipal(''demo'')' '' ;
  'PLSPULSM Identifies FIR dynamics models for MISO systems' 'plspulsm(''demo'')' '' ;
  'PLSRSGCV Generates PLS models for MSPC with cross-validation' 'plsrsgcv(''demo'')' '' ;
  'PLSRSGN Generates a matrix of PLS models for MSPC' 'plsrsgn(''demo'')' '' ;
  'PLTTERN Plots a 2D ternary diagram.' 'plttern(''demo'')' '' ;
  'PLTTERNF Plots a 3D ternary diagram with frequency of occurrence.' 'pltternf(''demo'')' '' ;
  'POLYINTERP Polynomial interpolation, smoothing, and differentiation.' 'polyinterp(''demo'')' '' ;
  'POLYPLS PLS regression with polynomial inner-relation.' 'polypls(''demo'')' '' ;
  'PREPROCESS Selection and application of preprocessing methods' 'preprocess(''demo'')' '' ;
  'PROJDEMO Demo of the MLR, PCR, and PLS regression vectors.' 'projdemo' '' ;
  'REGCON Converts regression model to y = ax + b form' 'regcon(''demo'')' '' ;
  'REPLACEVARS Replaces variables based on PCA or PLS models' 'replacevars(''demo'')' '' ;
  'RESCALE Rescales matrix ' 'rescale(''demo'')' '' ;
  'RESIDUALLIMIT confidence limits for Q residuals' 'residuallimit(''demo'')' '' ;
  'RIDGECV Ridge regression by cross validation' 'ridgecv(''demo'')' '' ;
  'RIDGE Ridge regression by Hoerl-Kennard-Baldwin' 'ridge(''demo'')' '' ;
  'RINVERSE Calculates pseudo inverse for PLS, PCR and RR models' 'rinverse(''demo'')' '' ;
  'RMSE Root Mean Square Error' 'rmse(''demo'')' '' ;
  'RWB Red-white-blue color map' 'rwb(''demo'')' '' ;
  'SAVGOLCV Cross-validation for Savitzky-Golay smoothing and differentiation.' 'savgolcv(''demo'')' '' ;
  'SAVGOL Savitzky-Golay smoothing and differentiation.' 'savgol(''demo'')' '' ;
  'SCALE Scales matrix as specified.' 'scale(''demo'')' '' ;
  'SHUFFLE Randomly re-orders matrix rows.' 'shuffle(''demo'')' '' ;
  'SIMCA Soft independent method of class analogy model maker.' 'simca(''demo'')' '' ;
  'SIMPLS Partial Least Squares computational engine using SIMPLS algorithm' 'simpls(''demo'')' '' ;
  'SNV Standard Normal Variate scaling' 'snv(''demo'')' '' ;
  'SPCREADR reads a Galactic SPC file' 'spcreadr(''demo'')' '' ;
  'SSQTABLE print variance captured table to command window.' 'ssqtable(''demo'')' '' ;
  'STATDEMO Elementary stats, t test, F test and AVOVA' 'statdemo' '' ;
  'STDDEMO Demo of the STDSSLCT, STDGEN, and OSCCALC functions' 'stddemo' '' ;
  'STDFIR Standardization using FIR filtering.' 'stdfir(''demo'')' '' ;
  'STDGEN Piecewise and direct standardization transform generator' 'stdgen(''demo'')' '' ;
  'STDIZE Standardizes new spectra using previously developed transform' 'stdize(''demo'')' '' ;
  'STDSSLCT Selects subset of spectra for use in standardization' 'stdsslct(''demo'')' '' ;
  'TLD Trilinear decomposition.' 'tld(''demo'')' '' ;
  'TSQLIM confidence limits for Hotelling''s T^2' 'tsqlim(''demo'')' '' ;
  'TSQMTX calculates matrix for T^2 contributions for PCA' 'tsqmtx(''demo'')' '' ;
  'TTESTP Evaluates t-distribution and its inverse' 'ttestp(''demo'')' '' ;
  'TUCKER analysis for n-way arrays' 'tucker(''demo'')' '' ;
  'UNFOLDM unfolds an augmented matrix for MPCA' 'unfoldm(''demo'')' '' ;
  'UNFOLDMW Unfolds multiway arrays along specified order' 'unfoldmw(''demo'')' '' ;
  'VARCAP Variance captured for each variable in PCA model' 'varcap(''demo'')' '' ;
  'VARIMAX Orthogonal rotation of loadings.' 'varimax(''demo'')' '' ;
  'VLINE adds vertical lines to figure at specified locations' 'vline(''demo'')' '' ;
  'WRTPULSE Creates input/output matrices for dynamic model identification' 'wrtpulse(''demo'')' '' ;
  'WTFA Window target factor analysis' 'wtfa(''demo'')' '' ;
  'XCLGETDATA extracts a matrix from an Excel spreadsheet' 'xclgetdata(''demo'')' '' ;
  'XCLPUTDATA places a MATLAB matrix in an Excel spreadsheet' 'xclputdata(''demo'')' '' ;
  'TEXTREADR Reads ASCII flat files or .XLS files MS Excel and other spreadsheets' 'textreadr(''demo'')' '' ;
  'ZLINE adds vertical lines to 3D figure at specified locations' 'zline(''demo'')' '' };

% %---------------------------------
% The above list was generated with this code:
% 
% pth = fileparts(which('pcademo.m'));
% 
% dem = dir(fullfile(pth,'*.m')); 
% dem = {dem.name};
% tbfiles = [dir(fullfile(pth,'../*.m')); dir(fullfile(pth,'../utilities/*.m'))]; 
% tbfiles = {tbfiles.name};
% 
% dems = cell(200,3);
% ind = 0;
% for j=1:length(dem); 
%   basename = [dem{j}(1:end-6)];
%   if ismember([basename '.m'],tbfiles);
%     hlp = help(basename);
%     target = [basename '(''demo'')'];
%   else
%     hlp = help([basename 'demo']);
%     target = [basename 'demo'];
%   end
%   hlp = fliplr(deblank(fliplr(hlp(1:findstr(hlp,10)-1))));
%   ind = ind+1;
%   dems{ind,1} = hlp;
%   dems{ind,2} = target;
%   dems{ind,3} = '';
% end
% 
% clipboard('copy',sprintf([encode(dems(1:ind,:),'tbxStruct.DemoList',0) ';']))

