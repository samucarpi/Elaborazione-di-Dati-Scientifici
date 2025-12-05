function pcs = choosecomp(modl,rawmodl,x,y,options)
%CHOOSECOMP Returns suggestion for number of components to include in a model. 
% Automatic factor suggestion based on information available in a given
% model. Suggestion is made on the available information in the model,
% depending on model type:
%
%   PCA
%     * Without cross-validation: selection is based on looking for a
%        "knee" (drop) in eigenvalue. The PC just before the drop is
%        selected.
%     * With cross-validation: initial suggestion is made based on
%        eigenvalues (as described above). Suggestion is refined by looking
%        at change in RMSECV for adding or removing factors . If changing
%        factors provides more than a given % improvement in RMSECV
%        (relative to the maximum RMSECV observed), then suggestion is
%        changed. Threshold for change is defined by options (see below).
%  PLS/PCR 
%    * Without cross-validation: No suggestion will be made.
%    * With cross-validation: A "knee" in RMSEC is searched for (none found
%        will suggest 1 LV). The suggestion is then improved using the
%        RMSECV values and the search algorithm described above for PCA.
%  PLSDA
%    * Without cross-validation: No suggestion will be made.
%    * With cross-validation: An initial suggestion is determined by
%        searching for a "knee" in the mean RMSECV (note difference from
%        PLS/PCR). This suggestion is then refined based on the mean
%        misclassification error reported from cross-validation.
%
% In all cases, a suggestion is only offered for models with more than 7
% factors and if that suggestion includes less than 50% of the estimated 
% rank of the data. No suggestion is made for unlisted model types.
%
% INPUTS:
%     model = standard model structure.
% OPTIONAL INPUTS:
%   options = options structure described below.
% OUTPUTS:
%       lvs = number of suggested components. Will be empty [ ] if no
%             suggestion can be made.
% OPTIONS:
%   The options structure can contain one or more of the following fields:
%       plscvthreshold : [ ] Percent improvement required to relative
%                            RMSECV to change the number of LVs from the
%                            initial suggestion (for PLS models only).
%                            If not specified (i.e. passed as [ ] empty)
%                            the algorithm uses a threshold equal to the
%                            average of the absolute difference of adjacent
%                            RMSECV values. i.e.:
%                                mean(abs(diff(CV)))
%                            Where CV is the relative CV.
%     plsdacvthreshold : [ ] Same as above but used for PLSDA models.
%       pcacvthreshold : [ ] Same as above but used for PCA models.
%            kneealpha : [0.2] Alpha term (typical range 0-1) used to
%                            adjust knee finding sensitivity. The larger
%                            this value, the more "flat" the eigenvalues
%                            vs. PC curve must be before a drop to have the
%                            given PC selected. Alpha is defined within the
%                            knee-finding equation below.
%           robustknee : [ 'off' |{'on'}] governs use of the robust knee
%                            algorithm to verify the knee location.
%           robustsigma : [ 2 ] governs threshold for robust knee finding.
%                            Values more than this multiple above the
%                            significance line will be considered a "knee"
%                            by the robust algorithm.
%          robustwindow : [ 5 ] governs number of values included in each
%                            robust knee-finding window.  
%
%   The default values for these options can also be set using the
%   setplspref command or the preferences expert interface.
%
% Knee-Finding Algorithm:
%  To locate a knee, the following equation is used:
%
%       x1^(1+alpha)    x2^(1+alpha)
%      ------------- - -------------
%           x2              x3
%
%  where x1, x2 and x3 are three eigenvalues associated with consecutive
%  PCs (or other statistics as defined above). Given a vector of x values,
%  the vector is examined from lowest index to highest for the first
%  consecutive group of 3 eigenvalues which give a positive value for the
%  equation above. The position indicated by x2 is selected as the "top" of
%  the knee.
%  The position identified using the method described above is then compared
%  to a position determined using a windowed robust fit (see unimcd). The
%  lesser of the two identified positions is used as the knee. The robust
%  identifier can be turned off using the options.robustknee option
%  described above.
%
%I/O: lvs = choosecomp(model)
%I/O: lvs = choosecomp(model,options)

%Copyright Eigenvector Research, Inc. 2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0;
  modl = 'io';
end
if ischar(modl)
  options = [];
  options.plscvthreshold = [];
  options.plsdacvthreshold = [];
  options.pcacvthreshold = [];
  options.kneealpha  = 0.2;
  options.robustknee = 'on';
  options.robustsigma = 2;
  options.robustwindow = 5;
  
  if nargout==0; evriio(mfilename,modl,options); else; pcs = evriio(mfilename,modl,options); end
  return;
end

if nargin<5;
  options = [];
end
if nargin==2 & ~ismodel(rawmodl) & isstruct(rawmodl)
  %assume this is options!
  options = rawmodl;
  rawmodl = [];
end
options = reconopts(options,mfilename);

pcs = [];
try
  if ismodel(modl)
    
    switch lower(modl.modeltype)
      
      %-------------------------------------------------------------
      case 'pca'
        
        %first, estimate with ssq
        ssq = [];
        switch lower(modl.detail.options.algorithm)
          case 'robustpca'
            %robust pca has residuals in separate vector
            ssq = modl.detail.ssq;
            if ~isempty(ssq)
              ssq = [ssq(:,2);modl.detail.reseig];
            end
          case {'svd' 'maf'}
            %standard SVD (or similar) has residuals included
            ssq = modl.detail.ssq;
            if ~isempty(ssq)
              ssq = ssq(:,2);
            end
        end
        if size(ssq,1)>7
          %determine likely "knee" in the eigenvalues
          pcs = findknee(ssq,options);
          pcs = max(pcs,1);
        end
        
        %now, check rmsecv
        if length(modl.detail.rmsecv)>7
          newpcs = findrmin(modl.detail.rmsecv,options.pcacvthreshold,pcs,options.pcacvthreshold);
          if ~isempty(newpcs)
            pcs = newpcs;
          end
        end
        
        if ~isempty(pcs) & pcs>min(length(modl.detail.includ{1,1}),length(modl.detail.includ{2,1}))/2
          %do NOT suggest if we'd be suggesting > 50% of the approx. rank
          pcs = [];
        end
        
        %-------------------------------------------------------------
      case {'pls' 'pcr' 'npls'}
        
        %check RMSECV
        if length(modl.detail.rmsecv)>7
          pcs = findrmin(modl.detail.rmsec,-5,findknee(modl.detail.rmsec,options)+1,-1);
          if isempty(pcs);
            pcs = 1;
          end
          newpcs = findrmin(modl.detail.rmsecv,options.plscvthreshold,pcs,options.plscvthreshold);
          if ~isempty(newpcs);
            pcs = newpcs;
          end
        else
          %no cross-val?
          %         pcs = findknee(modl.detail.ssq(:,4),options);
          % DO NOT use above code - it often mis-estimates the needed # of factors
        end
        
        if ~isempty(pcs) & pcs>min(length(modl.detail.includ{1,1}),length(modl.detail.includ{2,1}))/2
          %do NOT suggest if we'd be suggesting > 50% of the approx. rank
          pcs = [];
        end
        
        %-------------------------------------------------------------
      case {'plsda'}
        
        %check misclassed
        if length(modl.detail.rmsecv)>7
          errc = mean(modl.detail.rmsecv,1);
          pcs = findrmin(errc,-5,findknee(errc,options)+1,-1);
          if isempty(pcs);
            pcs = 1;
          end
          errcv = mean(modl.detail.classerrcv,1);
          newpcs = findrmin(errcv,options.plsdacvthreshold,pcs,options.plsdacvthreshold);
          if ~isempty(newpcs);
            pcs = newpcs;
          end
        else
          %no cross-val?
          %         pcs = findknee(modl.detail.ssq(:,4),options);
          % DO NOT use above code - it often mis-estimates the needed # of factors
        end
        
        if ~isempty(pcs) & pcs>min(length(modl.detail.includ{1,1}),length(modl.detail.includ{2,1}))/2
          %do NOT suggest if we'd be suggesting > 50% of the approx. rank
          pcs = [];
        end
        
        
    end
  else
    %assume model is just the eigenvalues!
    pcs = findknee(modl,options);
    pcs = max(pcs,1);
  end
catch
  pcs = [];
end

%------------------------------------------
function knee = findknee(v,options)
% locates a significant "knee" in a curve
% this is determined by first calculating the difference in the ratios of
% the square of each value to the subsequent value:
%       x1^(1+alpha)    x2^(1+alpha)
%      ------------- - -------------
%           x2              x3
% the knee is just before the first positive deviation to this quantity
%   (x1^(1+alpha)/x2)-(x2^1+alpha)/x3) > 0 (i.e. x2^1+alpha)/x3 is smaller
%   than x1^1+alpha)/x2)
%

alpha = options.kneealpha;

er = diff((v(1:end-1).^(1+alpha))./(v(2:end)+eps));

knee = min(find(er>0));

if ~isempty(knee)
  knee = knee + 1;
else
  knee = 1;
end

if strcmp(options.robustknee,'on')
  %now, check against robust knee
  robust_knee = robknee(v,options.robustsigma,options.robustwindow);
  knee = min(knee,robust_knee);
end

%------------------------------------------
function [pnt,pv] = findrmin(v,tg,pc,tr)
%finds the minimum of a normalized curve
%  tg = threshold for change to allow growing the # of pcs to a given value
%  tr = threshold for change to allow reduction to a given # of pcs
%  pc = the reference point (default = 1, thus tg is the only important threshold)
%
% First, any components which provided less than (tr) percentage change are
% dropped. Next, components above the new (pc) value are considered for
% inclusion if they provide at least a (tg) percent change (uaulaly
% negative).
%
%  *
%   *    *
%    *  *
%     **
%  1234567
%
%  pc = 6 will be reduced to 5 if tr is >0
%  pc = 6 will be reduced to 4 if tr is <=0
%  pc = 3 will be increased to 4 if tg is <0
%  pc = 3 will be increased to 5 if tg is =0
%
%  Good default values:
%    pls:  tg = tr = -1
%    pca:

if all(size(v)>1)
  v = sum(v,1);
end
if nargin<2
  tg = -0.5;
end
if nargin<3;
  pc = length(v);
  tr = tg;
end
if pc>length(v);
  pc = length(v);
end

pv = (v./max(v))*100;

dave = mean(abs(diff(v)))/max(v)*100;
if isempty(tg)
  tg = -dave;
end
if isempty(tr)
  tr = -dave;
end

pc = max([find(diff(pv(1:pc))<tr) 0])+1;
pnt = min(find(diff(pv(pc:end))>tg))+pc-1;

% figure; plot(1:length(pv),pv,'.-',pc,pv(pc),'ro',pnt,pv(pnt),'g*'); pause; close

%----------------------------------------------
function out = robknee(v,threshold,window)
%Uses windowed MCD to determine where a "jump" occurs in the data

n = length(v);
for j=n-(window-1):-1:1;
  test = log10(v(j:min(j+window,end)));  
  s(j) = outlierlevel(test);
end
out = max(find(s>threshold));
if isempty(out) | out<1
  out = nan;
end

function out = outlierlevel(v)
%code extracted from MCDCOV

rdlimit = 2.2414027276; % = sqrt(chidf('quantile',.975,1)); %constant, so it is now hard-coded
h   = length(v)-1;
[rew.center, rewsca] = unimcd(v,h);
mah = (v-rew.center).^2/rewsca^2;
rd  = sqrt(mah');
out = rd(1)./rdlimit;
