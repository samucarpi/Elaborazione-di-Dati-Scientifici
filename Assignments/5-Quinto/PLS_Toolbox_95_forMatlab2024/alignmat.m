function varargout = alignmat(varargin)
%ALIGNMAT Alignment of matrices and N-way arrays.
%  ALIGNMAT finds the subarray of (b), (bi), that most matches (a).
%  (a) can be considered a standard matrix.
%
%  INPUTS:
%   I/O: [bi,itst] = alignmat(amodel,b); %aligns matrix b w/ model in amodel
%    amodel = model of the array (a).
%             Models for (amodel) are standard model structures
%             from PCA, PCR, GRAM, TLD, PARAFAC, or DECOMPOSE.
%         b = test matrix that must have the same number of
%             modes/dimensions as (a) with each element of
%             size(b)>=size(a). It can be class "double" or "dataset".
%   ALIGNMAT finds the subarray of (b), (bi), that most matches the model
%   estimate of (a) by minimizing the projection residuals on (amodel).
%
%   I/O: [bi,itst] = alignmat(a,b,ncomp);%aligns matrix b w/ a using SVD
%         a = M by N two-way array.
%         b = Mb(>=M) by N two-way array.
%    nocomp = Optional input (scalar integer) number of components to
%             use in the decomposition {default: ncomp = 1}.
%   ALIGNMAT finds the submatrix of (b) that most matches (a) by minimizing
%     R=sum(s(nocomp+1:end))/sum(s(1:ncomp)) where s = svd([a,bi]).
%   Both (a) and (b) can be class "double" or "dataset".
%
%  OUTPUTS:
%        bi = the matrix that best matches (amodel) or (a) class "double".
%      itst = cell array containing the indices of (b) that match (bi).
%             Since interpolation is used the indices may NOT be integers.
%
%I/O: alignmat demo
%
%See also: ALIGNPEAKS, ALIGNSPECTRA, ANALYSIS, CALTRANSFER, GRAM, MATCHROWS, PARAFAC, PCA, REGISTERSPEC, TLD

%Copyright Eigenvector Research, Inc. 2000
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 9/00
%nbg 3/02 modified to standard I/O and to accept DataSets
%jms 4/02 modified to standard I/O
%jms 3/24/03 number of components in model from LOADS not SCORES
%nbg 12/05 modified help
%nbg 8/06 added the model's .detail.includ field for the loads
%nbg 9/21 added 'linesearch' for initialization - calls GOLDENSECSEARCHD

if nargin == 0; varargin{1} = 'io'; end
if ischar(varargin{1});
  options = [];
  options.name          = 'options';
  options.display       = 'on';     %Displays output to the command window
  options.algorithm     = 'projection';  %svd(x^T*x), svd(x), projection2d
  options.interpolate   = 'linear'; %'off'
  %options.preprocessing = {[] []};  %See preprocess
  options.definitions = @optiondefs;
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return;
end
optoptions = optimset('fminsearch');
%optoptions.MaxFunEvals = '400*numberofvariables';

if nargin<2
  error('ALIGNMAT requires at least 2 inputs.')
else
  if isnumeric(varargin{1})
    varargin{1}      = dataset(varargin{1});
    algorithmdefault = 'svd(x^T*x)';
  elseif isdataset(varargin{1}) %expected, do nothing
    algorithmdefault = 'svd(x^T*x)';
  elseif ismodel(varargin{1})  %possible model
    checkmodel(varargin{1});
    algorithmdefault = 'projection'; %projection2d
  else
    error('First input must be "double", "dataset", or standard model structure.')
  end
  if isnumeric(varargin{2})  %test matrix
    varargin{2}     = dataset(varargin{2});
  elseif isdataset(varargin{2})
    %expected, do nothing
  else
    error('Second input must be class "double" or "dataset".')
  end
end
if nargin<3
  %I/O: [bi,itst,rest] = alignmat(model,data)
  %I/O: [bi,itst,rest] = alignmat(stdmat,data)
  %nocomp and options must be set
  options = alignmat('options');
  options.algorithm = algorithmdefault;
  if isdataset(varargin{1})
    nocomp  = 1;
    warning('EVRI:AlignmatNcompFix','Input ncomp set to 1.')
  elseif ismodel(varargin{1})
    nocomp  = size(varargin{1}.loads{2,1},2);
  else
    error('Unrecognized input for model')
  end
end
if nargin==3
  %I/O: [bi,itst,rest] = alignmat(model,data,options)
  %I/O: [bi,itst,rest] = alignmat(stdmat,data,nocomp)
  %nocomp or options must be set

  %is varagrin{3} options or nocomp?
  options = alignmat('options');
  if isdataset(varargin{1})
    nocomp = checknocomp(varargin{3}, ...
      min([length(varargin{1}.includ{1,1}),length(varargin{1}.includ{2,1})]));
    options.algorithm = algorithmdefault;
  elseif ismodel(varargin{1})
    switch class(varargin{3})
      case 'double'
        warning('EVRI:AlignmatNcompIgnored','Input nocomp ignored. Using ncomp from the model.')
        nocomp = size(varargin{1}.loads{1},2);
        options.algorithm = algorithmdefault;
      case 'struct'   %testing for OPTIONS not model
        if isoption(varargin{3});
          options = reconopts(varargin{3},options);
          if ~strcmpi(options.algorithm,'projection')
            warning('EVRI:AlignmatAlgorithmIgnored','Algorithm not recognized. Using default.')
            options.algorithm = algorithmdefault;
          end
        else
          options.algorithm = algorithmdefault;
        end
      otherwise
        error(['Input options should be an options structure. Type ''options=alignmat(''options'')'''])
    end
  end
end
if nargin==4
  %I/O: [bi,itst,rest] = alignmat(model,data,options,nocomp)
  %I/O: [bi,itst,rest] = alignmat(model,data,nocomp,options)
  %I/O: [bi,itst,rest] = alignmat(stdmat,data,options,nocomp)
  %I/O: [bi,itst,rest] = alignmat(stdmat,data,nocomp,options)
  %determine which of varargin is nocomp or options

  %is varagrin{3} options or nocomp?
  switch class(varargin{3})  %put varargin into expected order
    case 'double'  %expected order, don't do anything
    case 'struct'  %swap 3 and 4
      nocomp = varargin{4};
      varargin{4} = varargin{3};
      varargin{3} = nocomp;
    otherwise
      error(['IO not recognized. Type ''alignmat help'''])
  end

  if isdataset(varargin{1})
    nocomp = checknocomp(varargin{3}, ...
      min([length(varargin{1}.includ{1,1}),length(varargin{1}.includ{2,1})]));
    if isoption(varargin{4})
      options = reconopts(varargin{4},alignmat('options'));
    else
      options = alignmat('options');
    end
    options.algorithm = algorithmdefault;
  elseif ismodel(varargin{1})
    if ~isempty(varargin{3})
      warning('EVRI:AlignmatNcompIgnored','Input ncomp ignored. Using ncomp from the model.')
    end
    if isoption(varargin{4})
      options = varargin{4};
    else
      options = alignmat('options');
    end
    options.algorithm = algorithmdefault;
    nocomp = size(varargin{1}.loads{1},2);
  end
end
%End Input
%Consistency Checks
switch options.algorithm
  case {'svd(x^T*x)','svd(x)'}
    [varargout{1},varargout{2}] = alignmatsubfun(varargin{1},varargin{2},nocomp,options);
  case 'projection'
    bt     = varargin{2}.includ;
    bt     = varargin{2}.data(bt{:});
    d      = size(bt);    %vector of length >=2
    nmode  = ndims(bt);   %number of modes

    %make sure test is matrix or nd array
    if prod(d)==1
      error('Input b must not be scalar.')
    elseif any(d==1)
      error('Input b must not be vector or contain singleton dimensions.')
    end
    %make sure number of dims of test array compatible with model
    if length(varargin{1}.loads)~=nmode
      error(['Model of "',varargin{1}.datasource{1,1}.name,'" and ndims(b) not compatible.'])
    end
    nocomp = size(varargin{1}.loads{1},2);
    imode = zeros(1,nmode);    %imode = identifies which modes to align
    lsiz  = imode;             %lsiz  = cell of indices for the test matrix bt
    bsiz  = cell(1,nmode);
    for ii=1:nmode
      %lsiz(ii)    = size(varargin{1}.loads{ii},1); %commented nbg 9/14/06
      lsiz(ii)    = length(varargin{1}.detail.includ{ii}); %nbg 9/14/06
      if lsiz(ii)<d(ii)
        imode(ii) = 1;
      elseif lsiz(ii)>d(ii)
        error(['Size of model loads for dim ',int2str(ii),' > test matrix dim.'])
      end
      bsiz{ii}    = 1:size(bt,ii);
    end

    %multiply loadings so they can be fit to bi
    uloads  = zeros(prod(lsiz),nocomp);
    for ii=1:nocomp
      %v     = varargin{1}.loads{1}(:,ii); %commented nbg 9/14/06
      v     = varargin{1}.loads{1}(varargin{1}.detail.includ{1},ii); %nbg 9/14/06
      for ij=2:nmode
        %v   = v*varargin{1}.loads{ij}(:,ii)'; %commented nbg 9/14/06
        v   = v*varargin{1}.loads{ij}(varargin{1}.detail.includ{ij},ii)'; %nbg 9/14/06
        v   = v(:);
      end
      uloads(:,ii) = v;
    end, clear v

    %Note for future:
    % [x,fval,exitflag,out] = lmoptimizebnd(fun,x0,xlow,xup,options,params);
    %need to modify alignmatfun to include J and H
    % replace code in here --- if using lmoptimizebnd

    bnds    = ones(2,nmode);                     %bounds on starting indice x
    for ii=find(imode);
      bnds(2,ii) = d(ii)-lsiz(ii)+1;
    end

    switch 'linesearch' %'meanbnds' %
      case 'meanbnds'
        x       = mean(bnds(:,find(imode))); %vector of starting indices
      case 'linesearch'
        ik      = find(imode); %modes to align       
        x       = round(mean(bnds(:,ik))); %vector of starting indices
        ysiz    = bsiz;        %axes (initial part of array to use)    
        for ij=1:length(ik)
          ysiz{ik(ij)} = [x(ij):x(ij)+lsiz(ik(ij))-1];
        end
        [res,ii] = sort(-diff(bnds(:,ik)),2);
        ik      = ik(ii);
        for ij=ik
          ysiz{ij} = [bnds(1,ij):bnds(2,ij)+lsiz(ij)-1];
          bu    = bt(ysiz{:});
          ii    = goldensecsearchd('alignmatfun',[1:diff(bnds(:,ij))+1],'projection',uloads,bu,ij,lsiz,bsiz,bnds);
          x(ij) = ysiz{ij}(ii);
          ysiz{ij} = [x(ij):x(ij)+lsiz(ij)-1];
        end
    end
    itst    = fminsearch('alignmatfun',x,optoptions,'projection',uloads,bt,imode,lsiz,bsiz,bnds);
    %---

    clear loads uloads bu res

    %modify ysiz to be the size of the loads starting at the optimum
    ysiz    = bsiz;
    ii      = find(imode);
    for ij=1:length(x)
      ysiz{ii(ij)} = [itst(ij):itst(ij)+lsiz(ii(ij))-1];
    end
    varargout{2}   = ysiz;
    ysiz{1} = ysiz{1}';
    varargout{1}   = interpn(bsiz{:},bt,ysiz{:},'*linear');
  case 'projection2d'
    if length(varargin{1}.loads)>3
      error('ALIGN with PROJECTION2D not defined for models with more than 2 modes.')
    end
    %need to test the size of the modes and the size of tstmat
    [varargout{1},varargout{2}] = alignmatsubfun(varargin{1},varargin{2},nocomp,options);
end
%End Consistency Checks

% switch options.plots
%   case 'final'
%     figure
%     plot(1:length(res),res,'o-b'), hold on
%     plot(itst(1),rest(itst(1)),'or','markerfacecolor',[1 0 0]), hold off
%     xlabel('Index of Row 1 of B')
%     if isa(stdmat,'struct')
%       title(stdmat.name)
%       ylabel('Projection Residual')
%     else
%       s1     = ['\Sigma(s(',int2str(prank+1),':end))/'];
%       s2     = ['\Sigma(s(1:',int2str(prank),'))'];
%       title('Ratio of Singular Values')
%       ylabel([s1,s2])
%     end
% end

function [b,itst] = alignmatsubfun(a,b,nocomp,options)
%Inputs are:
%  a:       is dataset containing the standard matrix, or
%            struct containing a bilinear model
%  b:       is dataset to be standardized size(b,1)>size(a,1)
%  nocomp:  is the number of components to keep (used in svd algorithms)
%  options: standard alignmat options structure
%Outputs are:
%  b:       input b with the includ field modified
%  itst:    b.includ{1,1}
%  res:     for svd methods this is ratio sum(s(nocomp+1:end))/sum(s(1:nocomp));
%           for projection it is the projection residuals

if isdataset(a) && mdcheck(a.data(a.includ{1},a.includ{2}));
  [flag,missmap,replaced] = mdcheck(a.data(a.includ{1},a.includ{2}));
  a.data(a.includ{1},a.includ{2}) = replaced;
end
if isdataset(b) && mdcheck(b.data(b.includ{1},b.includ{2}));
  [flag,missmap,replaced] = mdcheck(b.data(b.includ{1},b.includ{2}));
  b.data(b.includ{1},b.includ{2}) = replaced;
end

switch options.algorithm
  case {'svd(x^T*x)','svd(x)'}
    bt      = b.data(b.includ{1,1},b.includ{2,1});
    a       = a.data(a.includ{1,1},a.includ{2,1});
    if size(a,1)>size(bt,1)
      %if reference is LARGER than sample, invert them to solve
      flipped = true;
      temp = a;
      a = bt;
      bt = temp;
    else
      %normal case (reference is smaller than sample)
      flipped = false;
    end
    [mt,nt] = size(bt);
    [ms,ns] = size(a);
    switch options.algorithm
      case 'svd(x^T*x)'    %uses svd(x'*x) or svd(x*x')
        if ms<ns+nt
          for ii=1:mt-ms+1
            s        = svd([a,bt(ii:ii+ms-1,:)]*[a,bt(ii:ii+ms-1,:)]');
            res(ii)  = sum(s(nocomp+1:end))/sum(s(1:nocomp));
          end
        else
          for ii=1:mt-ms+1
            s        = svd([a,bt(ii:ii+ms-1,:)]'*[a,bt(ii:ii+ms-1,:)]);
            res(ii)  = sum(s(nocomp+1:end))/sum(s(1:nocomp));
          end
        end
      case 'svd(x)'        %uses svd(x)  (slower)
        for ii=1:mt-ms+1
          s        = svd([a,bt(ii:ii+ms-1,:)]);
          res(ii)  = sum(s(nocomp+1:end))/sum(s(1:nocomp));
        end
    end
    clear s
    [u,ii] = min(res);
    switch options.interpolate
      case 'linear'
        optoptions = optimset('fminsearch');
        %Display, TolX, TolFun, MaxFunEvals, and MaxIter.
        ii = fminsearch('alignmatfun',ii,optoptions,options.algorithm,a,bt,ms,mt,ns,nt,nocomp);
        itst = [ii:ii+ms-1]';
        if ~flipped;
          b    = interp1q([1:mt]',bt,itst);
        else
          b    = interp1q(itst,a,[1:mt]');
        end
      otherwise
        itst = [ii:ii+ms-1]';
        if ~flipped;
          b    = bt(itst,:);
        else
          b    = interp1(itst,a,[1:mt]','nearest');
        end
    end
  case 'projection'

  case 'projection2d'
    mode1   = a.loads{1};    ms = length(mode1);
    mode2   = a.loads{2};    ns = length(mode2);
    i1      = b.includ{1,1};
    i2      = b.includ{2,1};
    bt      = b.data(i1,i2);
    [mt,nt] = size(bt);
    z       = zeros(size(mode1,2),size(mode1,1)*size(mode2,1));
    for ii=1:size(mode1,2)
      z(ii,:) = kron(mode1(:,ii)',mode2(:,ii)');
    end
    z       = z'*inv(z*z');
    res     = zeros(mt-ms+1,nt-ns+1);
    for ii=1:mt-ms+1
      for ij=1:nt-ns+1
        u        = bt(ii:ii+ms-1,ij:ij+ns-1)';
        v        = diag(u(:)'*z);
        u        = (bt(ii:ii+ms-1,ij:ij+ns-1)-mode1*v*mode2').^2;
        res(ii,ij)  = sum(sum(u)');
      end
    end
    itst    = cell(1,2);
    [u,ij]  = min(res,[],2);
    [u,ii]  = min(u);
    ij      = ij(ii);
    itst{1} = [ii:ii+ms-1];
    itst{2} = [ij:ij+ns-1];
    clear u s
    switch options.interpolate
      case 'linear'
        optoptions = optimset('fminsearch');
        %Display, TolX, TolFun, MaxFunEvals, and MaxIter.
        ii = [ii ij];
        nocomp = {mode1, mode2};
        ii = fminsearch('alignmatfun',ii,optoptions,options.algorithm,z,bt,ms,mt,ns,nt,nocomp);
        itst{1} = [ii(1):ii(1)+ms-1]';
        itst{2} = [ii(2):ii(2)+ns-1]';
        [u,v] = meshgrid([ii(2):ii(2)+ns-1],[ii(1):ii(1)+ms-1]);
        b    = interp2(bt,u,v);
      otherwise
        b    = bt(itst{1},itst{2});
    end

end

function checkmodel(x)
%CHECKMODEL Checks if the Input is an acceptable model. Errors otherwise.
if ~ismodel(x)
  error('First input is not a standard model structure.')
end
s  = {'pca';'pcr';'gram';'tld';'parafac'};
if ~any(ismember(lower(x.modeltype),s))
  error(['Models of type "',x.modeltype,'" not recognized by ALIGNMAT.'])
end

function t = isoption(x)
%ISOPTION Checks if the Input is an acceptable options structure. Warns otherwise.
if ~isa(x,'struct')
  error('Input options structure not valid.')
else
  t = true;
end

function x = checknocomp(x,minsize)
%CHECKNOCOMP Checks if Input is an acceptable nocomp. Errors or warns otherwise.
if ~isa(x,'double')
  error('When first input is class "double" nocomp must be scalar.')
elseif prod(size(x))>1
  error('Input nocomp must be scalar.')
elseif x>minsize
  error('Input nocomp must be less than min(size("first input")).')
elseif isempty(x)
  x = 1;
end

%--------------------------
function out = optiondefs()

defs = {
  
%name                    tab              datatype        valid                       userlevel       description
'display'                'Display'        'select'        {'on' 'off'}                'novice'        'Governs level of display.';
'algorithm'              'Algorithm'      'select'        {'projection' 'svd(x^T*x)' 'svd(x)' 'projection2d'}   'novice'         'Algorithm';
'interpolate'            'Algorithm'      'select'        {'linear' 'off'}            'novice'        'Interpolate';
};

out = makesubops(defs);
