function [ccx,mn,pstd] = classcentroid(x,mn,pstd)
%CLASSCENTROID Centers data to the centroid of all classes.
%  Rows in the input data are centered to the centroid of all the classes.
%  The centroid is equivalent to a weighted mean where each class is given
%  the same weight. For example, if two classes A and B are present the
%  centroid is
%     mn = mean([mean(Class A); mean(Class B)]);
%
% If only two outputs are requested, then the data is centered only. 
% If three outputs are requested, than the data is both centered and scaled
% (scaling based on the pooled standard devation of the classes). Note that 
% samples belonging to class 0 (unknown class) are not used in calculating 
% the centroid or pooled variance.
%
%  INPUTS:
%           x = DataSet object to be centered.
%
% OPTIONAL INPUTS:
%     options = structure array with the following fields:
%         offset: scales by pstd = pstd+offset {default = 0}:
%       classset: Class set (from rows) which should be used to center data.
%                 {Default is class set = 1.}
%
%          mn = Means from previous call to classcentroid.
%        pstd = Pooled standard deviation of the classes e.g.,
%                 pvar = (MA-1)*std(Class A).^2 + (MB-1)*std(Class B).^2)/(MA+MB-2)
%                 pstd = sqrt(pvar);
%                 where MA and MB are the number of samples in each class.
%
% OUTPUTS:
%         ccx = Centered x. Dataset object.
%          mn = Row vector of the centroid between classes.
%        pstd = Row vector of pooled standard deviation of the classes.
%
%I/O: [ccx,mn]      = classcentroid(x,options); %calibrate, centers the data
%I/O: [ccx,mn,pstd] = classcentroid(x,options); %calibrate, centers and scales
%I/O: ccx = classcentroid(x,mn);                %apply, centers new data 
%I/O: ccx = classcentroid(x,mn,pstd);           %apply, centers and scales
%
%See also: AUTO, CLASSCENTER, MNCN, RESCALE, SCALE

%Copyright © Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%options.algorithm - add meantrimmed and median
%                  - add variancetrimmed and madac

%HIDDEN: calling with keywords 'default' or 'defaultscale' return
%preprocessing structures to do centering and centering+scaling

if nargin==0; x = 'io'; end

if ischar(x);
  switch lower(x)
  case 'default' %create default preprocessing
    ccx = defaultprepro(0);
    return;
  case 'defaultscale' %create default preprocessing
    ccx = defaultprepro(1);
    return;
  otherwise;
    options = [];
    options.name = 'options';
    options.offset    = 0;
%     options.algorithm = 'mean'; %
    options.classset  = 1;
    options.definitions = @optiondefs;
    
    if nargout==0; evriio(mfilename,x,options); else
      ccx = evriio(mfilename,x,options); end
    return
  end
end

if ~isdataset(x)
  error('Input (x) must be a dataset object.')
end

if nargin<2
  options     = classcentroid('options');
  applymode   = false;
else
  if isstruct(mn)
    options   = reconopts(mn,mfilename);
    applymode = false;
  elseif isnumeric(mn)
    if length(mn)~=size(x,2)
      error('Size of input (mn) not compatible with (x).')
    end
    if nargin==3
      if length(pstd)~=size(x,2)
        error('Size of input (pstd) not compatible with (x).')
      end      
    end
    applymode = true;
  else
    error('Input (mn) not recognized.')
  end
end

ccx           = x;
if applymode %apply old means and scaling to new data
  if nargin<3
    ccx.data  = scale(x.data,mn);
  else
    ccx.data  = scale(x.data,mn,pstd);
  end
else %calibrate
  if size(x.class,2)<options.classset | isempty(x.class{1,options.classset})
    %no class exists or it is empty? assume everything in the same class
    myclass = ones(1,size(x,1));
  else
    %get actual classes
    myclass = x.class{1,options.classset};
  end
  cs          = unique(myclass(x.include{1}));
  cs          = cs(cs>0);
  mn          = zeros(length(cs),size(x,2));
  if nargout==3
    pstd      = zeros(1,size(x,2));
    pn        = 0;
  end
  for i1=1:length(cs)
    i2        = find(myclass(x.include{1})==cs(i1));
    mn(i1,:)  = mean(x.data(x.include{1}(i2),:));
    if nargout==3
%       pstd    = pstd + std(x.data(x.include{1}(i2),:),[],1).^2;
      pstd    = pstd + (length(i2)-1)*std(x.data(x.include{1}(i2),:),[],1).^2;
      pn      = pn   +  length(i2)-1;
    end
  end
  if length(cs)>1
    mn        = mean(mn);
  end
  if nargout<3
    ccx.data  = scale(x.data,mn);
  else
    pstd      = sqrt(pstd/max(1,pn));
    if isfinite(options.offset)
      pstd = pstd+options.offset;
    end

    ccx.data  = scale(x.data,mn,pstd);
  end
end
  

%--------------------------------------------------
function pp = defaultprepro(scaletoo)
%generate default preprocessing structure for this method

if ~scaletoo
  pp = [];
  pp.description = 'Class Centroid Centering';
  pp.calibrate = { '[data,out{1}] = classcentroid(data,struct(''classset'',userdata.classset));' };
  pp.apply     = { 'data = classcentroid(data,out{1});'   };
  pp.undo      = { 'data = rescale(data,out{1});'  };
  pp.out       = {};
  pp.settingsgui   = '';
  pp.settingsonadd = 0;
  pp.usesdataset   = 1;
  pp.caloutputs    = 1;
  pp.keyword  = 'classcentroid';
  pp.tooltip  = 'Remove class centroid from each variable';
  pp.category = 'Scaling and Centering';
  pp.userdata = [];
  pp.userdata.classset = 1;
else
  pp = [];
  pp.description = 'Class Centroid Centering and Scaling';
  pp.calibrate = { '[data,out{1},out{2}] = classcentroid(data,struct(''classset'',userdata.classset));' };
  pp.apply     = { 'data = classcentroid(data,out{1},out{2});'   };
  pp.undo      = { 'data = rescale(data,out{1},out{2});'  };
  pp.out       = {};
  pp.settingsgui   = '';
  pp.settingsonadd = 0;
  pp.usesdataset   = 1;
  pp.caloutputs    = 2;
  pp.keyword  = 'classcentroidscale';
  pp.tooltip  = 'Remove class centroid from each variable and scale by pooled standard deviation';
  pp.category = 'Scaling and Centering';
  pp.userdata = [];
  pp.userdata.classset = 1;
  
end

pp = preprocess('validate',pp);

%--------------------------
function out = optiondefs

defs = {
  %name                    tab           datatype        valid              userlevel       description
  'offset'                'Settings'     'double'        []                 'novice'        'Scales by pstd = pstd+offset {default = 0}.'
  'classset'              'Settings'     'double'        []                 'novice'        'Class set (from rows) which should be used to center data {Default is class set = 1}.'
  };
out = makesubops(defs);
