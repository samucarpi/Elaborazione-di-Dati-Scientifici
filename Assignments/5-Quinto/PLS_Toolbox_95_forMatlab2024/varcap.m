function [varc]=varcap(X,T,P,scl,plots)
%VARCAP Variation captured for each variable in any 2-way factor-based model.
%  Calculates percent variation (sum-of-squares) captured in a model for 
%  each variable and number of components. Valid models include: PCA, PCR, 
%  PLS, CLS and LWR. For non-orthogonal models, VARCAP splits variation into
%  unique variation for each component (1:K) plus a row for common variation
%  and another for total variation where K is the number of components.
%
%  INPUTS:
%      X = properly processed and scaled data [MxN, class double].
%
%    I/O: vc = varcap(X,T,P);
%         T = associated scores [MxK, class double] and
%         P = associated loadings [NxK, class double].
%       Note: Scores (T) can be omitted if, and only if, the loadings (P) are
%             ortho-normal (such as those from a PCA or PCR model). In this
%             case, it will be assumed that scores can be calculated from:
%               T = XP
%             If this is not valid for the given loadings, the variance 
%             captured will be incorrect.
%
%    I/O: vc = varcap(X,model);
%     model = a model object.
%             If a model is passed in place of (T), the scores, loadings and
%             plotting scale (scl) are extracted from the model object.
%             Howver, optional inputs of user-defined scale (scl) and 
%             (plots) flag can still be input along with the (model).
%
%  OPTIONAL INPUTS:
%       scl = x-axisscale for plotting [1xN, class double].
%     plots = flag which suppresses plotting when set to 0 {default plots = 1}.
%
% OUTPUTS:
%        vc = matrix of % variance captured [(K+2)xN, class double].
%             Rows 1:K is the percent of UNIQUE variation for each variable
%             on each component where the common variation has been removed.
%             Row K+1 is the percent common variation, and
%             Row K+2, the last row, is the percent total variation
%             captured by the model.
%
%I/O: vc = varcap(X,T,P,scl,plots);
%I/O: vc = varcap(X,model,scl,plots);
%
%See also: ANALYSIS, DATAHAT, PCA, VARCAPY

%Copyright Eigenvector Research, Inc. 1997-2020
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rb

if nargin == 0; X = 'io'; end
if ischar(X);
  options = [];
  options.colormap = '';%parula
  if nargout==0; clear varc; evriio(mfilename,X,options); else; varc = evriio(mfilename,X,options); end
  return;
end

[I,J]=size(X);

if ismodel(T)
  % (X,model,...)
  modl = T;
  switch nargin
    case 2
      % (x,model)
      plots = [];
      scl = [];
    case 3
      % (x,model,scl)
      plots = [];
      scl   = P;
    case 4
      % (x,model,scl,plots)
      plots = scl;
      scl   = P;
  end
  %extract items from model
  T = modl.loads{1,1}(modl.detail.includ{1},:);
  P = modl.loads{2,1};

  if isempty(scl)
    scl = modl.detail.axisscale{2};
  end  
else
  %standard I/O
  switch nargin
    case 2
      % (X,P)  *** OLD I/O    passed as: (X,T)
      P     = T;
      T     = [];
      scl   = [];
      plots = [];
    case 3
      % (X,T,P)
      % (X,P,scl)   *** OLD I/O
      if size(T,1)==I & size(P,1)==J
        % (X,T,P)
        scl   = [];
        plots = [];
      else
        % (X,P,scl)  passed as: (X,T,P)
        scl   = P;
        P     = T;
        T     = [];
        plots = [];
      end
    case 4
      % (X,T,P,scl)
      % (X,P,scl,plots)   *** OLD I/O
      if size(T,1)==I & size(P,1)==J
        % (X,T,P,scl)
        plots = [];
      else
        % (X,P,scl,plots)  passed as: (X,T,P)
        plots = scl;
        scl   = P;
        P     = T;
        T     = [];
      end
    case 5
      % (X,T,P,scl,plots)  everyting is set
  end
end

options = varcap('options');

%defaults for scl and plots
if length(scl)~=J  %empty or doesn't match variables
  scl     = 1:J;
end
if isempty(plots)
  plots   = 1;
end

if isempty(T)
  %happens with old I/O - assume T = XP
  T = X*P;
end

%define mnscl and mxscl for edges of plot
mnscl   = min(scl)-(max(scl)-min(scl))/J;
mxscl   = max(scl)+(max(scl)-min(scl))/J;

%calculate ssX and other stats needed
Etot   = X-T*P';
ssEtot = sum(Etot.^2);
ssX    = sum(X.^2);

F      = size(T,2);
varc   = zeros(F+2,J);
varc(F+2,:) = 100*(1-ssEtot./ssX);

% Calculate model contribution from each component
%TODO: Note that "modl" and M_unique are both samples x variables x PCs and
%could be exceptionally large. This code should be refactored to calculate
%varc in some piece-wise way so we don't end up reproducing the data times
%the number of factors. This currently requires PC*2 times the amount of
%memory used by X alone.
modl = zeros(I,J,F);
for f=1:F;
  modl(:,:,f)=T(:,f)*P(:,f)';
end

% Go through each variable and split variance into common and components
% specific variation
M_unique=zeros(I,J,F);
for j=1:J
  M_unique(:,j,:) = spltvar(squeeze(modl(:,j,:)));
end

for f=1:F
  Ef = X-M_unique(:,:,f);
  ssEf = sum(Ef.^2);
  varc(f,:)=100*(1-(ssEf./ssX));
end
varc(F+1,:)=varc(F+2,:)-sum(varc(1:F,:),1);

if plots~=0
  if plots==1;    %plots>1 = plot on current figure
    figure
  end
  
  showcommon = max(abs(varc(F+1,:)))>1e-5;
  ax = axes;
  h = bar(scl,varc(1:F+showcommon,:)','stacked','FaceColor','flat');
  if ~isempty(options.colormap)
    colormap(ax,options.colormap)
    for k = 1:1:F+showcommon
      h(k).CData = k;
    end
  end
  
  if showcommon
    legendname(h(1:F),str2cell(sprintf('Unique Comp %i\n',1:length(h))));
    legendname(h(F+1),'Common Var');  %last item shown is common variance
  else
    legendname(h(1:F),str2cell(sprintf('Component %i\n',1:length(h))));
  end
  
  axis([mnscl mxscl 0 119])
  h = hline(100,'k--');
  set(h,'color',[.5 .5 .5],'handlevisibility','off');
  if ~ispc
    %User 'interp' here instead of 'linestyle' to fix problem (disappearing
    %bars) when rendering really skinny bars.
    set(findobj(gca,'type','patch'),'edgecolor','interp')
    %WARNING! using the above line on some PCs caused Matlab to HANG!
  end
  xlabel('Variable')
  ylabel('Percent Variation Captured')
  title('Variation Captured')
  figuretheme

end

if nargout==0 & plots
  clear varc
end

%----------------------------------------------------------
function M_uni= spltvar(M);

% M(:,f) is the contribution of component f to the model of the variable x

F=size(M,2);
for f=1:F
  % All columns but column f
  M_no_f = M(:,[1:f-1 f+1:F]);
  % Remove from column f what is predicted from the other columns
  M_uni(:,f) = M(:,f)-M_no_f*(pinv(M_no_f)*M(:,f));
end


