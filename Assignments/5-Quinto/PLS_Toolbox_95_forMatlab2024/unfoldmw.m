function mwauf = unfoldmw(mwa,order)
%UNFOLDMW Unfolds multiway arrays along specified order.
% The inputs are the multiway array to be unfolded (mwa),
% which may be of class "double" or " dataset",
% and the dimension number along which to perform the
% unfolding (order). The output is the unfolded array (mwauf),
% which is a "double" or "dataset" depending on the input.
% When working with Dataset objects, UNFOLDMW will create
% include fields and labels consistent with the input.
% This function is used in the development of PARAFAC models
% in the alternating least squares steps and in MPCA.
%
%I/O: mwauf = unfoldmw(mwa,order);
%
%See also: MPCA, OUTERM, PARAFAC, TLD, UNFOLDM

% Copyright © Eigenvector Research, Inc. 1998
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%bmw
%rb August 2000, speeded up by factor 20
%bmw August 2002, made to work with dataset objects
%jms 10/8/02 added " " before "unfolded" in .name field of datasets

if nargin == 0; mwa = 'io'; end
varargin{1} = mwa;
if ischar(varargin{1});
  options = [];
  if nargout==0; clear mwauf; evriio(mfilename,varargin{1},options); else; mwauf = evriio(mfilename,varargin{1},options); end
  return; 
end

mwauf = [];

if nargin<2 || isempty(order)
  val = inputdlg({['Enter the single mode which will not be unfolded: ']},'Enter Order',1,{''},'on');
  if isempty(val) || isempty(val{:})
    return
  else
    order = round(str2num(val{:}));
  end
end

if isa(mwa,'dataset')
  wasdataset = 1;
  org_mwa = mwa;
  mwa = mwa.data;
else
  wasdataset = 0;
end
mwasize = size(mwa);
if length(mwasize)<order
  mwasize = [mwasize 1]; % Necessary if last mode has dimension one 
end
ord   = length(mwasize);
mwauf = permute(mwa,[order 1:order-1 order+1:ord]); %makes first order the unfold order
mwauf = reshape(mwauf,mwasize(order),prod(mwasize([1:order-1 order+1:ord])));

if wasdataset == 1
  mwauf = dataset(mwauf);
  mwauf.name = [org_mwa.name ' unfolded'];
  mwauf.author = org_mwa.author;
  mwauf.includ{1} = org_mwa.includ{order};
  mwauf.description = org_mwa.description;
  for setind = 1:size(org_mwa.title,2);
    mwauf.title{1,setind} = org_mwa.title{order,setind}; % Only first title and class transfer
    mwauf.titlename{1,setind} = org_mwa.titlename{order,setind}; % Only first title and class transfer
  end
  for setind = 1:size(org_mwa.class,2);
    mwauf.class{1,setind} = org_mwa.class{order,setind}; % No classes on convolved modes!
    mwauf.classname{1,setind} = org_mwa.classname{order,setind}; % No classes on convolved modes!
  end
  for setind = 1:size(org_mwa.axisscale,2);
    mwauf.axisscale{1,setind} = org_mwa.axisscale{order,setind};
    mwauf.axisscalename{1,setind} = org_mwa.axisscalename{order,setind};
  end
  for setind = 1:size(org_mwa.label,2);
    mwauf.label{1,setind} = org_mwa.label{order,setind}; % No labels on convolved modes yet!
    mwauf.labelname{1,setind} = org_mwa.labelname{order,setind};
  end
  temp = cell(1,ord-1); k = 0;
  foldmodes = [1:order-1 order+1:ord];
  for i = [1:order-1 order+1:ord]
    k = k+1;
    if isempty(org_mwa.label{i,1});
      tmp = int2str([1:mwasize(i)]');
      s = sprintf('M%gV',i);
      org_mwa.label{i,1} = [s(ones(1,mwasize(i)),:) tmp];
    end
    if isempty(org_mwa.title{i,1});
      org_mwa.title{i,1} = sprintf('Mode %g',i);
    end
    if isempty(org_mwa.labelname{i,1});
      org_mwa.labelname{i,1} = sprintf('Mode %g',i);
    end
    inc = zeros(1,mwasize(i));
    inc(org_mwa.includ{i}) = 1;
    temp{k} = inc';
  end
  newlabels = makeplabels2(org_mwa.label, foldmodes);
  mwauf.includ{2} = find(outerm(temp));
  mwauf.userdata = org_mwa.userdata;
  % Set the new labels, labelnames and titles for the unfolded dataset
  for ifold = 1:length(foldmodes)
    mwauf.labelname{2,ifold} = org_mwa.labelname{foldmodes(ifold),1}; 
    mwauf.label{2,ifold} = newlabels{ifold};
    mwauf.title{2,ifold} = org_mwa.title{foldmodes(ifold),1}; 
  end
end

%--------------------------------------------------------------------------
function plabels = makeplabels2(labels, inds)
% Get labels for the unrolled dataset. Create a new label set for each mode
% which is unrolled.
nmodes = length(inds);
m = size(labels{inds(1)},1);
for i=2:nmodes
  m = m*size(labels{inds(i)},1);
end

m1 = 1;
m2 = m;
for i=1:nmodes
  m2 = m2/size(labels{inds(i)},1);
  plabels{i} = getnewlabel(labels{(inds(i))}, m1, m2);
  m1 = m1*size(labels{inds(i)},1);
end

%--------------------------------------------------------------------------
function labelsnew = getnewlabel(labelsold, m1, m2)
% Generate the label for the unrolled modes. 
% labelsold elements are each replicated m1 times, then that result is
% replicated m2 times.
indx = ones(m1,1)*(1:size(labelsold,1));
indx = indx(:);
labelsnew = labelsold(indx,:);
labelsnew = repmat(labelsnew, m2, 1);


%--------------------------------------------------------------------------
%Old version
%mwasize = size(mwa);
%ms = mwasize(order);
%po = prod(mwasize);
%ns = po/ms;
%if order ~= 1
%   pod = prod(mwasize(1:order-1));
%end
%mwauf = zeros(ms,ns);
%for i = 1:ms
%   if order == 1
%      mwauf(i,:) = mwa(i:ms:po);
%   else
%      inds = zeros(1,ns); k = 1; fi = (i-1)*pod + 1;
%      for j = 1:ns/pod
%         inds(k:k+pod-1) = fi:fi+pod-1;
%         fi = fi + ms*pod;
%         k = k + pod;
%      end
%      mwauf(i,:) = mwa(inds);
%   end
%end%
%
%end
