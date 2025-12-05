function [issues,splitinfo] = reviewcrossval(varargin)
%REVIEWCROSSVAL Examines cross-validation settings for typical problems.
% Given a standard PLS_Toolbox model structure, REVIEWCROSSVAL examines the
% numerical and build information and returns textual warnings to advise
% the user of possible issues.
% Inputs:
%    model : a standard model structure or the handle to an Analysis GUI.
%
% Output:
%   issues : A structure array containing one or more issues identified in
%           the model. The structure contains the following fields and may
%           contain one or more records, or may be empty if no issues were
%           identified.
%         issue : The text describing the issue.
%         color : A "color code" identifying the sevrity of the issue.
%       issueid : A unique ID identifying the issue.
%  splitinfo : string giving statistical information on the split
%
% If no outputs are requested, any issues are simply displayed in the
% Command Window.
%
%I/O: [issues,splitinfo] = reviewcrossval(model)

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0; varargin{1} = 'io'; end
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; issues = evriio(mfilename,varargin{1},options); end
  return;
end

issues = struct('issue',{},'color',{},'issueid',{});
splitinfo = '';

modl = varargin{1};
if isempty(modl);
  %no model, no error!
  return
end

try
  if ~ismodel(modl)
    if ~ishandle(modl); return; end
    analh = modl;
    if ~strcmpi(get(analh,'tag'),'analysis'); return; end
    cvh     = getappdata(analh,'crossvalgui');
    if isempty(cvh) | ~ishandle(cvh); return; end
    if strcmpi(getappdata(cvh,'enable'),'off'); return; end
    [cv,lv,split,iter,cvi] = crossvalgui('getcontrolsettings',cvh);
    
    curanal = getappdata(analh,'curanal');
    X       = analysis('getobjdata','xblock',analh);
    Y       = analysis('getobjdata','yblock',analh);
    
    if isempty(curanal) | ismember(curanal,{'cluster'}); return; end
    if isempty(X); return; end    
    modl    = evrimodel(curanal);
    modl    = copydsfields(X,modl,[],1);
    if length(modl.datasource)>1 & ~isempty(Y)
      modl    = copydsfields(Y,modl,[],2);
    else
      Y = [];
    end
    
  else  %actual model
    %check for fields which make it reasonable to search
    for f = {'cv' 'split' 'iter' 'cvi'};
      if ~isfieldcheck(['modl.detail.' f{:}],modl)
        return;
      end
    end
    cv    = modl.detail.cv;
    split = modl.detail.split;
    iter  = modl.detail.iter;
    cvi   = modl.detail.cvi;
    
    if length(modl.detail.data)>1
      Y = modl.detail.data{2};
    else
      Y = [];
    end

    if strcmpi(modl.modeltype,'cls')
      %CLS has special rules
      if isempty(modl.detail.rmsecv)
        %although settings are there, no CV done (probably not valid for these settings)
        return;
      end
    end
  end
  
  if ~isdataset(Y);
    Y = dataset(Y);
  end
  
  nsamp = modl.datasource{1}.size(1);

  %check for CLS with pure components (cv won't be used)
  purecomp = false;
  if strcmpi(modl.modeltype,'cls');
    if isempty(Y)
      purecomp = true;
    elseif all(size(Y)==size(Y,1))   %square Y block with CLS?
      if ~isdataset(Y); Y = dataset(Y); end
      sumy = sum(Y.data,2);
      maxy = max(Y.data,[],2);
      purecomp = (all(sumy==maxy) & all(sumy~=0));   %NO Mixtures (all pure components)
    end
  end

  %---------------------------------------------------
  %get percent split for each group
  if ~isnumeric(cvi)
    try
      cvi = encodemethod(nsamp,cvi{:});
    catch
      cvi = [];
    end
  end
  if isnumeric(cvi) & ~isempty(cvi)
    numberOfNegTwos = numel(cvi(cvi==-2));
    cvi = cvi(cvi~=0);
    lengthCVI_noZeros = length(cvi);
    cvi = cvi(cvi~=-1);
    cvi = cvi(cvi~=-2);
    [hy,hx] = hist(cvi,unique(cvi));
    hy = hy+numberOfNegTwos;
%     pct = round(hy./sum(hy)*100);
    pct = round(hy./lengthCVI_noZeros*100);
    splitinfo = sprintf('Left-out Data: Min = %i%%, Max = %i%%, Average = %i%%',min(pct),max(pct),round(mean(pct)));
  else
    pct = [];
  end

  %---------------------------------------
  %look for issues

  if strcmpi(cv,'rnd') 
    if iter<5
      issue = 'Caution: Random cross-validation with fewer iterations often results in significant variability in results. Increase iterations, choose a different method, or repeat analysis multiple times to assess variability.';
    else
      issue = 'Caution: Random cross-validation tends to show variability in results. Repeat analysis multiple times to assess variability in cross-validation results.';
    end
    color = 'yellow';
    issueid = 'cvvaringrandom';
    issues(end+1) = struct('issue',issue,'color',color,'issueid',issueid); %add issue to list
  end

  if split<5 & nsamp<20
    spct = num2str(floor(100/split));
    issue = ['Caution: Number of splits will leave out a high percentage (' spct '%) of the calibration data in each cycle. In small data sets, this may lead to under-estimation of model performance.'];
    color = 'yellow';
    issueid = 'cvdatasplitlow';
    issues(end+1) = struct('issue',issue,'color',color,'issueid',issueid); %add issue to list
  end

  if ismember(cv,{'loo'}) & nsamp>20
    issue = 'Warning: Cross-validation may be biased and report errors lower than expected when using Leave One Out with this data (more than 20 samples). Consider using another Cross-Val Method that leaves more samples at at a time.';
    color = 'red';
    issueid = 'cvloomany';
    issues(end+1) = struct('issue',issue,'color',color,'issueid',issueid); %add issue to list
  elseif ~isempty(pct) & min(pct<3)
    issue = ['Caution: Number of splits will leave out a small percentage (' num2str(min(pct)) '%) of the calibration data in at least one cycle. This may lead to over-estimation of model performance. Consider decreasing the number of splits.'];
    color = 'yellow';
    issueid = 'cvdatasplithigh';
    issues(end+1) = struct('issue',issue,'color',color,'issueid',issueid); %add issue to list
  end

  
  if strcmpi(modl.modeltype,'cls') & purecomp & ~strcmpi(cv,'none')
    %CLS with pure components
    
    issue = 'Notice: Cross-validation will not be applied when pure component spectra are used with CLS models.';
    color = 'red';
    issueid = 'cvclspurecomp';
    %NOTE This error erases all others
    issues = struct('issue',issue,'color',color,'issueid',issueid); %add issue to list
    
  elseif ismember(cv,{'rnd' 'loo'}) | (strcmpi(cv,'vet') & (nsamp<10 | (iter/nsamp)<.1)) 
    %for random, leave one out, and small venetian blinds:
    
    % Check for date axisscales which might indicate sequential samples
    axs = modl.detail.axisscale(1,:,:);
    axs = axs(:);
    axs(cellfun('isempty',axs)) = [];
    badorder = false;
    for j=1:length(axs)
      % (dates are detected by values between 1/1/1900 and 1/1/2200)
      if all(axs{j}>693962) & all(axs{j}<803535) & randomprob(axs{j}) < 10 %apparent DATES which are highly ordered with sample #?
        issue = 'Warning: Date/Time stamps on this data indicates your data is highly ordered with sample number. The selected cross-validation mode is not recommended with this type of data. Try Contiguous Block or Thick Venetian Blinds instead.';
        color = 'red';
        issueid = 'cvorderedaxisscale';
        issues(end+1) = struct('issue',issue,'color',color,'issueid',issueid); %add issue to list
        badorder = true;
        break;
      end
    end

    %     % this test isn't ready. Need to determine if the range of values is
    %     % distributed across the y-range (maybe look at min/max values in
    %     % windows?)
    %     if ~isempty(Y) & ~badorder
    %       % If isyused, check order of y rows to see if sequential samples
    %       for j=1:size(Y,2)
    %         dy = sign(all(diff(Y.data(:,j))));  %check for all increasing/decreasing
    %         if ~all(dy==dy(1)) & randomprob(Y.data(:,j)) < 10 %highly ordered with sample #? (but not monotonically increasing/decreasing)
    %           issue = 'Warning: Y data appears to be highly ordered with sample number. The selected cross-validation mode is not recommended with this type of data. Consider Contiguous Blocks instead.';
    %           color = 'red';
    %           issueid = 'cvorderedyblock';
    %           issues(end+1) = struct('issue',issue,'color',color,'issueid',issueid); %add issue to list
    %           break;
    %         end
    %       end
    %     end

  else  %'con' or 'vet' (wide)

    % Look for order in classes
    %    BAD with {'con' ...} or {'vet' __ n} n>10
    %    OK  with 'loo', {'vet' __ n } n<10, 'rnd'
    
    if ~isempty(Y)
      if modl.isclassification
        % If isyused, check order of y rows to see if all increasing/decreasing samples
        for j=1:size(Y,2)
          dy = sign(diff(Y.data(:,j)));  %check for all increasing/decreasing
          dy(dy==0) = [];  %drop replicate values
          if all(dy==dy(1)) %all increasing/decreasing with sample #?
            issue = 'Caution: Y data appears to be sorted. The selected cross-validation mode is not recommended and you may run into problems if your X data has the same number of classes as you choose segments, you will leave out a complete class.';
            color = 'yellow';
            issueid = 'cvorderedyblock';
            issues(end+1) = struct('issue',issue,'color',color,'issueid',issueid); %add issue to list
            break;
          end
        end
      end
    end
    
    
  end
  
  %TODO: Look for replicates in labels
  
  
catch
  %any errors? Just pass through - do NOT fail if evaluation didn't work
end

if nargout==0
  if ~isempty(issues)
    for j=1:length(issues);
      disp(char(textwrap({['*** ' issues(j).issue]},80)));
    end
  else
    disp('No issues identified in model')
  end
  clear issues
end

%-------------------------------------------------
function p = randomprob(v)
v = v(:)';
if length(v)>15;
  p = (mean(abs(v-savgol(v,3,0))>(range(v')*.1)))*100;
else
  p = 100;
end
