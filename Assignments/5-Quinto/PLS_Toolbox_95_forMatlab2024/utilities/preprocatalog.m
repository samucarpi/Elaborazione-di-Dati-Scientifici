function varargout = preprocatalog(fig)
%PREPROCATALOG Is the default catalog of preprocessing methods for preprocess.
% Used by preprocess to define initial default catalog. Input (fig) is figure
%  number of preprocessing GUI.
%
%I/O: called by preprocess - not user accessable
%
%See also: PREPROCESS, PREPROUSER

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS 4/9/02 -split from PREPROCESS
%rsk 10/19/05 -add logdecay.
%rsk 02/24/06 -add SG smooth and deriv as seperate items.

if nargin == 0; fig = 'io'; end
varargin{1} = fig;
if ischar(varargin{1});
  options = [];
  options.newbaselineview = 'off'; %If 'off' then list baseline methods seperately. If 'on' then show only baselineds.
  if nargout==0; clear varargout; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return; 
end

options = preprocatalog('options');

%SavGol setup for seperate derivative and smoothing entries.
pp = savgolset('default');
pp.userdata.order = 0;
pp.keyword = 'smooth';
pp.description = 'Smoothing (SavGol)';
preprocess('addtocatalog', fig, pp);

pp = savgolset('default');
pp.userdata.deriv = 1;
pp.keyword = 'derivative';
pp.description = 'Derivative (SavGol)';
preprocess('addtocatalog', fig, pp);

pp = savgolset('default');
pp.userdata.deriv = 1;
pp.userdata.mode  = 1;
pp.userdata.tails = 'weighted';
pp.keyword = 'derivativecolumns';
pp.description = 'Column-wise Derivative';
preprocess('addtocatalog', fig, pp);

pp = gscaleset('default');
pp.description = 'Block Variance Scaling';
pp.keyword = 'blockvariance';
pp.tooltip = 'Scale block of all variables to unit variance and variable count correction';
pp.userdata.numblocks = 1;
pp.userdata.center = 0;
preprocess('addtocatalog', fig, pp);

preprocess('addtocatalog', fig, mncnset('default'));  
preprocess('addtocatalog', fig, medcnset('default'));  
preprocess('addtocatalog', fig, autoset('default'));
preprocess('addtocatalog', fig, mscorrset('default'));
preprocess('addtocatalog', fig, normset('default'));
preprocess('addtocatalog', fig, detrendset('default'));
preprocess('addtocatalog', fig, snv('default'));
preprocess('addtocatalog', fig, oscset('default'));
preprocess('addtocatalog', fig, gscaleset('default'));
preprocess('addtocatalog', fig, npreprocenterset('default'));
preprocess('addtocatalog', fig, npreproscaleset('default'));
preprocess('addtocatalog', fig, glsw('default'));
preprocess('addtocatalog', fig, logdecayset('default'));
preprocess('addtocatalog', fig, referenceset('default'));
preprocess('addtocatalog', fig, gapsegmentset('default'));
preprocess('addtocatalog', fig, emscorrset('default'));
preprocess('addtocatalog', fig, minmaxset('default'));
preprocess('addtocatalog', fig, windowfilterset('default'));

if strcmp(options.newbaselineview,'on')
  %Add selected points.
  preprocess('addtocatalog', fig, baselineset('default'));
  
  %Add "new" baselineds.
  pp = baselinedsset('default');
  pp.description = 'Baseline Removal Advanced';
  preprocess('addtocatalog', fig, pp)
else
  pp = wlsbaselineset('default');
  for filter = {'whittaker' 'basis'};
    pp.userdata.filter = filter{:};
    pp = wlsbaselineset('default',pp);
    switch filter{:}
      case 'whittaker'
        pp.description = 'Baseline (Automatic Whittaker Filter)';
      otherwise
        pp.description = 'Baseline (Automatic Weighted Least Squares)';
    end
    preprocess('addtocatalog', fig, pp);
  end
  
  preprocess('addtocatalog', fig, baselineset('default'));
end


preprocess('addtocatalog', fig, hrmethodreadr('default'));
preprocess('addtocatalog', fig, poissonset('default'));
preprocess('addtocatalog', fig, classcenterset('default'));
preprocess('addtocatalog', fig, classcentroidset('default'));
preprocess('addtocatalog', fig, classcentroidscaleset('default'));
preprocess('addtocatalog', fig, specalignset('default'));
preprocess('addtocatalog', fig, arithmetic('default'));
preprocess('addtocatalog', fig, flucutset('default'));
preprocess('addtocatalog', fig, glogset('default'));

pp =  glsw('default');
pp.description = 'EPO Filter';
pp.keyword = 'EPO';
pp.userdata = struct('a',-1,'source','automatic','meancenter','yes');
pp.tooltip = 'External Parameter Orthogonalization - remove clutter covariance';
preprocess('addtocatalog',fig,pp);

%--------------------------------
clear pp;
pp = mscorrset('default');
pp.description = 'MSC (Median)';
pp.undo = {};
pp.settingsgui = 'mscorrset';
pp.settingsonadd = 0;
pp.caloutputs = 1;
pp.keyword = 'msc_median';
pp.tooltip = 'Multiplicative Signal Correction - median ratio normalization';
pp.category = 'Normalization';
pp.userdata.meancenter = 1;
pp.userdata.algorithm = 'median';
pp.userdata.options.algorithm = 'median';
pp.userdata.source = 'median';

preprocess('addtocatalog',fig,pp);

%--------------------------------
pp = [];
pp.description   = 'Log10';
pp.calibrate     = {'data(data<0)=0; data = log10(data+userdata.offset);' };
pp.apply         = {'data(data<0)=0; data = log10(data+userdata.offset);' };
pp.undo          = {'data = (10.^data)-userdata.offset;' };
pp.out           = {};
pp.settingsgui   = '';
pp.settingsonadd = 0;
pp.usesdataset   = 0;
pp.caloutputs    = 0;
pp.keyword       = 'log10';
pp.tooltip       = 'Calculate base 10 logarithm of data with minimum value filter';
pp.category      = 'Transformations';
pp.userdata      = struct('offset',0.00001);

preprocess('addtocatalog',fig,pp);

%--------------------------------

pp = [];
pp.description   = 'PQN';
pp.calibrate     = {'[data,out{1},out{2}] = pqnorm(data);' };
pp.apply         = {'data = pqnorm(data,out{2});' };
pp.undo          = {'data = spdiags(out{1},0,length(out{1}),length(out{1}))*data;'};
pp.out           = {};
pp.settingsgui   = '';
pp.settingsonadd = 0;
pp.usesdataset   = 0;
pp.caloutputs    = 1;
pp.keyword       = 'PQN';
pp.tooltip       = 'PQN (Probabilistic Quotient Normalization) a robust sample normalization related to MSC (median)';
pp.category      = 'Normalization';
pp.userdata      = [];

preprocess('addtocatalog',fig,pp);

%--------------------------------
pp = [];
pp.description   = 'Transmission to Absorbance (log(1/T))';
pp.calibrate     = {'data = -log10(data);' };
pp.apply         = {'data = -log10(data);' };
pp.undo          = {'data = 10.^(-data);' };
pp.out           = {};
pp.settingsgui   = '';
pp.settingsonadd = 0;
pp.usesdataset   = 0;
pp.caloutputs    = 0;
pp.keyword       = 'trans2abs';
pp.tooltip       = 'Convert transmission or reflectance to absorbance';
pp.category      = 'Transformations';
pp.userdata      = [ ];

preprocess('addtocatalog',fig,pp);

%----------------------------------

pp.description = 'Pareto (Sqrt Std) Scaling';
pp.calibrate = { '[junk,junk,sd] = auto(data); out{1} = sqrt(sd); data = scale(data,out{1}*0,out{1});' };
pp.apply = { 'data = scale(data,out{1}*0,out{1});' };
pp.undo = { 'data = rescale(data,out{1}*0,out{1});' };
pp.out = {};
pp.settingsgui = '';
pp.settingsonadd = 0;
pp.usesdataset = 0;
pp.caloutputs = 1;
pp.keyword = 'pareto';
pp.tooltip = 'Scale each variable by the square root of its standard deviation';
pp.category = 'Scaling and Centering';
pp.userdata = [ ];

preprocess('addtocatalog',fig,pp);

%----------------------------------

pp.description = 'Variance (Std) Scaling';
pp.calibrate = { '[junk,junk,out{1}] = auto(data); data = scale(data,out{1}*0,out{1});' };
pp.apply = { 'data = scale(data,out{1}*0,out{1});' };
pp.undo = { 'data = rescale(data,out{1}*0,out{1});' };
pp.out = {};
pp.settingsgui = '';
pp.settingsonadd = 0;
pp.usesdataset = 0;
pp.caloutputs = 1;
pp.keyword = 'autoscalenomean';
pp.tooltip = 'Scale each variable by its standard deviation';
pp.category = 'Scaling and Centering';
pp.userdata = [ ];

preprocess('addtocatalog',fig,pp);

%--------------------------------
pp = [];
pp.description   = 'Haar Transform';
pp.calibrate     = {'s1=data(:,1:2:end-1);s2=data(:,2:2:end);data(:,1:size(s1,2)+size(s2,2))=[s1+s2,s1-s2];'};
pp.apply         = {'s1=data(:,1:2:end-1);s2=data(:,2:2:end);data(:,1:size(s1,2)+size(s2,2))=[s1+s2,s1-s2];'};
pp.undo          = {'n=size(data,2);hn=floor(n/2);data(:,1:hn*2)=(data(:,floor(1:.5:(hn+0.5)))+data(:,floor((hn+1):.5:((hn*2)+0.5))).*repmat(ones(size(data,1),1)*[1 -1],1,floor(n/2)))/2;' };
pp.out           = {};
pp.settingsgui   = '';
pp.settingsonadd = 0;
pp.usesdataset   = 0;
pp.caloutputs    = 0;
pp.keyword       = 'haar';
pp.tooltip       = 'Calculate Haar transform (add additional calls for higher-order transforms)';
pp.category      = 'Transformations';
pp.userdata      = struct('offset',0.00001);

preprocess('addtocatalog',fig,pp);

