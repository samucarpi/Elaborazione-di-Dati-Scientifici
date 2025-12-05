function tsqcl = tsqlim(m,pc,cl,flag)
%TSQLIM Confidence limits for Hotelling's T^2.
% Calculates the confidence limit for a given confidence level or
% calculates the confidence level corresponding to given a Hotelling's T^2
% value and the corresponding model information.
%
%  INPUTS:
%       m = the number of samples.
%      pc = the number of PCs.
%      cl = the confidence limit (cl) where 0 < cl < 1.
%  Optionally, (m) and (pc) can be omitted and a standard model
%     structure (model) can be passed  along with the confidence limit (cl).
%
%  OPTIONAL INPUTS:
%    flag = [ {1} | 2 ] governs how the function is called.
%           1 = calculates the T^2 at the CL (default)
%           2 = calculates the CL from an input T^2 (tsq) (This is similar
%           to how FTEST is used) When flag=2,
%  OUTPUT:
%   tsqcl = the confidence limit. (See optional input flag for the inverse
%           calculation.)
%
%
%Examples: tsqcl = tsqlim(15,2,0.95);
%          tsqcl = tsqlim(mymodel,0.95);
%
%I/O: tsqcl = tsqlim(m,pc,cl);
%I/O: tsqcl = tsqlim(model,cl);
%I/O: cl    = tsqlim(m,pc,tsq,2);
%I/O: cl    = tsqlim(model,tsq,2);
%
%See also: ANALYSIS, CHILIMIT, PCA, PCR, PLS, SUBGROUPCL

%Copyright Eigenvector Research, Inc. 1997
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 4/97
%nbg 3/22/02 additional error checking
%jms 6/23/03 allow multiple limits for simultaneous detn.
%jms 11/29/05 allow passing of standard model structure

if nargin == 0; m = 'io'; end
varargin{1} = m;
if ischar(varargin{1});
  options = [];
  if nargout==0; clear tsqcl; evriio(mfilename,varargin{1},options); else; tsqcl = evriio(mfilename,varargin{1},options); end
  return;
end

switch nargin
  case 1
    if ismodel(m)
      error('Input (cl) required along with the model');
    else
      error('Inputs (pc) and (cl) required along with number of samples');
    end
  case 2
    %(model,cl)
    if ~ismodel(m)
      error('Input (cl) required along with (m) and (pc)')
    end
    flag  = 1;
    model = m;
    cl    = pc;
    [pc,m] = getdof(model);
  case 3
    %(m,pc,cl)
    %(model,cl,flag)
    %(model,tsq,flag)
    if ~ismodel(m)
      %(m,pc,cl)
      flag = 1;
    else
      %(model,cl,flag)
      %(model,tsq,flag)
      model  = m;
      flag   = cl;
      cl     = pc;
      [pc,m] = getdof(model);
      if isempty(cl) & flag==2
        cl = model.tsqs{1};
      end
    end
  case 4
    %(m,pc,tsq,flag)
    if ~ismodel(m)
      %(m,pc,tsq,flag)
      %do nothing...
    else
      error('Unrecognized input format');
    end
  otherwise
    error('Unrecognized input format');
end

wrn = warning;
warning off backtrace

try
  if flag~=2
    tsqcl_all = [];
    cl_all = cl;
    for cl_one = cl_all;
      %assume that, typical CL will be ~0.9 to 0.999
      cl = cl_one(:);
      if any(cl<=0)
        error('Input (cl) must be >0 (0<cl<1).')
      elseif any(cl>=100)
        error('Input (cl) must be <1 (0<cl<1).')
      elseif any(cl>0&cl<1)
        cl = cl*100;  %convert to %
      end
      
      if m==pc
        tsqcl = NaN;
      elseif pc>m
        tsqcl = NaN;
      else
        alpha = (100-cl)/100;
        tsqcl = pc*(m-1)/(m-pc)*ftest(alpha,pc,m-pc);
      end
      tsqcl_all(end+1) = tsqcl;
    end
    
    tsqcl = tsqcl_all;
  else
    cl(cl<0) = 0;
    if m==pc
      tsqcl = NaN*ones(size(cl));
    elseif pc>m
      tsqcl = NaN*ones(size(cl));
    else
      tsqcl = ftest(cl*(m-pc)/pc/(m-1),pc,m-pc,2);
      tsqcl = (1-tsqcl);
    end
  end
  
catch
  le = lasterror;
  warning(wrn)  %reset warnings
  rethrow(le)
end

warning(wrn);  %reset warnings

%-------------------------------------------------------------------
function [pc,m] = getdof(model);

if isfield(model, 'scores')
  pc = size(model.scores,2);
else
  pc = size(model.loads{2,1},2);
end
m  = model.datasource{1}.include_size(1);
