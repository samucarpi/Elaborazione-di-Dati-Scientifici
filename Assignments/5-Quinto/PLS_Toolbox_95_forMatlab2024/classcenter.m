function [ccx,mn,cls, npercls] = classcenter(x,classset,mn,cls)
%CLASSCENTER Centers classes in data to the mean of each class.
%  Rows in the input data are centered by class. The result is that each
%  class in the output will have mean response of zero. If no classes are
%  present or all rows belong to the same class, this is equivalent to mean
%  centering.
%
% INPUTS:
%           x = DataSet object to be class-centered.
% OPTIONAL INPUTS:
%    classset = Class set (from rows) which should be used to center data.
%               Default is class set 1.
%          mn = Means from previous call to classcenter. Must be passed
%               with associated classes [see (clss) input].
%        clss = Classes associated with each mean (see previous). Used to
%               apply previously-calculated means to new data.
% OUTPUTS:
%         ccx = Class-centered x. Dataset where each class has been centered.
%          mn = Row vectors of means for each class. The mean is over 
%               included samples only. Thus, (mn) is zero for a class if no 
%               samples are included for that class (in which case the
%               corresponding npercls value will = 0).
%        clss = Class numbers associated with each row of (mn).
%     npercls = Number of contributing samples in each centered class.
%
%I/O: [ccx,mn,clss,npercls] = classcenter(x,classset); %calibrate using classset
%I/O: ccx = classcenter(x,mn,cls);            %apply (classset = 1)
%I/O: ccx = classcenter(x,classset,mn,cls);   %apply using specific classset
%
%See also: MNCN, RESCALE, SCALE

%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0; x = 'io'; end
if ischar(x)
  switch x
    case 'default'
      %create default preprocessing
      ccx = defaultprepro;
    otherwise  %evriio call
      options = [];
      if nargout==0; evriio(mfilename,x,options); else; ccx = evriio(mfilename,x,options); end
  end
  return
end

if ~isdataset(x)
  x = dataset(x);
end
nincl = length(x.include{2});
if nargin<2
  classset = 1;
elseif nargin==2 & numel(classset)~=1
  error('Classset must be a scalar value indicating which class set to use for centering. Did you forget to include "cls" input?');
end
if nargin<3
  %get unique classes
  cl = x.class{1,classset};
  if numel(cl)==0
    error('Classset to use for centering is empty. Check the "cls" input');
  end
  cls = unique(cl);
  mn  = zeros(length(cls),nincl);
  applymode = false;
else
  %applying old means to new data
  if nargin==3
    % (x,mn,cls)  as (x,classet,mn)
    % move items around as needed
    cls = mn;
    mn  = classset;
    classset = 1;
  end
  %get current classes from x and note we're applying
  cl = x.class{1,classset};
  if isempty(cl)
    %no classes? use all zeros (unknown)
    cl = zeros(1,size(x,1));
  end
  applymode = true;
end

if anyexcluded(x)
  ccx = x.data.*nan;  %create output dataset (but all NaNs)
else
  ccx = x.data;
end
xincl = x.include;

%add class zero if not there
if ~ismember(0,cls)
  cls(end+1) = 0;
  if applymode
    mn(end+1,:) = 0;
  end
end

if ~applymode
  npercls = zeros(size(cls));  % number of samples included per class
else
  npercls = [];
end

%cycle through each class calculating mean of the class
for c = 1:length(cls);
  inset = (cl==cls(c));
  if ~applymode
    %determine which are included and calculate and apply mean centering
    inclinset = false(size(inset));
    inclinset(xincl{1}) = inset(xincl{1});
    if any(inclinset)
      %got some included, do centering to those
      [junk,mn(c,:)]      = mncn(x.data(inclinset,xincl{2}));  %calculate mean
      ccx(inset,xincl{2}) = scale(x.data(inset,xincl{2}),mn(c,:));  %apply to all data
      npercls(c)          = sum(inclinset);
    else
      %all excluded - use mean of all zeros
      mn(c,:) = zeros(1,nincl);
    end
  else
    if size(mn,2)~=length(xincl{2})
      error('Number of included variables in new data does not match number of variables in original data')
    end
    if ~isempty(inset)
      %appling previous mean to new data
      ccx(inset,xincl{2}) = scale(x.data(inset,xincl{2}),mn(c,:));  %apply to all data
    end
  end
end

x.data = ccx;
ccx = x;

%--------------------------------------------------
function pp = defaultprepro
%generate default preprocessing structure for this method

pp = [];
pp.description = 'Class Center';
pp.calibrate = { '[data,out{1},out{2}] = classcenter(data,userdata.classset);' };
pp.apply     = { 'data = classcenter(data,userdata.classset,out{1},out{2});'   };
pp.undo      = { 'data = classcenter(data,userdata.classset,-out{1},out{2});'  };
pp.out       = {};
pp.settingsgui   = '';
pp.settingsonadd = 0;
pp.usesdataset   = 1;
pp.caloutputs    = 2;
pp.keyword  = 'classcenter';
pp.tooltip  = 'Remove mean response from each class';
pp.category = 'Scaling and Centering';
pp.userdata = [];
pp.userdata.classset = 1;

pp = preprocess('validate',pp);
