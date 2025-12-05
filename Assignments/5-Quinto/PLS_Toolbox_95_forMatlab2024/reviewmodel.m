function issues = reviewmodel(varargin)
%REVIEWMODEL Examines a standard model structure for typical problems.
% Given a standard PLS_Toolbox model structure, REVIEWMODEL examines the
% numerical and build information and returns textual warnings to advise
% the user of possible issues.
% Inputs:
%    model : a standard model structure (or the handle to an Analysis GUI).
%
% Output:
%   issues : A structure array containing one or more issues identified in
%           the model. The structure contains the following fields and may
%           contain one or more records, or may be empty if no issues were
%           identified.
%         issue : The text describing the issue.
%         color : A "color code" identifying the sevrity of the issue.
%       issueid : A unique ID identifying the issue.
% If no outputs are requested, any issues are simply displayed in the
% Command Window.
%
%I/O: issues = reviewmodel(model)

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

modl = varargin{1};
if ~isstruct(modl) & ishandle(modl);
  modl = analysis('getobjdata','model',modl);
end
if isempty(modl);
  %no model, no error!
  return
end

try
  switch lower(modl.modeltype)
    case {'pca' 'pls' 'pcr' 'plsda' 'mlr'}
      
      %-----------------------------------------------
      %Check for no mean-centering
      xmncn = true;
      ymncn = true;
      if ismember(lower(modl.modeltype),{'pls' 'pcr' 'mlr'})
        %regression methods, check if y-block was mean centered
        yoffset = abs(mean(modl.detail.data{2}.data(modl.detail.include{1,2},modl.detail.include{2,2})) - mean(modl.pred{2}(modl.detail.include{1,2},:)));
        if any(yoffset>1e-9)
          ymncn = false;
          
          % Safeguard: double check the model.
          ppList=modl.detail.preprocessing{1,2};
          if ~(isempty(ppList))
            for (i=1:size(ppList,2))
              if strcmpi(ppList(i).description,'mean center') | strcmpi(ppList(i).description,'autoscale')
                ymncn = true;
                break;
              end
            end
          end
        end
        if ismember(lower(modl.modeltype),{'mlr'}) & isempty(modl.detail.preprocessing{1})
          ymncn = false;
        end
      else % 'pca' 'plsda'
        if isempty(modl.detail.preprocessing{1})
          ymncn = false;
        end
      end
      if isfield(modl,'loads')
        offset = max(abs(mean(modl.loads{1}(modl.detail.includ{1},:)))./mean(modl.loads{1}(modl.detail.includ{1},:).^2));
        if (offset>1e-9*max(modl.datasource{1}.size))
          xmncn = false;
          
          % Safeguard: double check the model.
          ppList=modl.detail.preprocessing{1,2};
          if ~(isempty(ppList))
            for (i=1:size(ppList,2))
              if strcmpi(ppList(i).description,'mean center') | strcmpi(ppList(i).description,'autoscale')
                xmncn = true;
                break;
              end
            end
          end
        end
      else
        if isempty(modl.detail.preprocessing{1})
          xmncn = false;
        end
      end      
      if ~xmncn & ymncn & isfield(modl.detail.options,'algorithm') & ~ismember(modl.detail.options.algorithm,{'robustpca','robustpls','robustpcr','frpcr'})
        issue = ['Warning: It appears the X data is not mean-centered. '...
          'Mean centering can significantly improve the performance of this kind of model and should generally ALWAYS be used. '...
          'Also note that you cannot compare "variance captured" in this model to any model using Mean Centering.'];
        color = 'red';
        issueid = 'pcanomncn';
        %add issue to list
        issues(end+1) = struct('issue',issue,'color',color,'issueid',issueid);
      end
      
      if xmncn & ~ymncn
        issue = ['Warning: Y-block not mean centered but X-block is. In regression methods, if X is mean centered, the Y must also be mean centered. '...
          'Please check the y-block preprocessing and confirm that at least Mean Centering is selected. Offset in predictions will result otherwise.'];
        color = 'red';
        issueid = 'regynomncn';
        %add issue to list
        issues(end+1) = struct('issue',issue,'color',color,'issueid',issueid);
      end
      
      if  isfield(modl.detail.options,'algorithm') & ismember(modl.detail.options.algorithm,{'frpcr'}) & xmncn
        issue = ['Warning: It appears this data is mean-centered. '...
          'Mean centering is generally not recommended with the FRPCR algorithm and removing it can significantly improve the performance of this kind of model. '...
          'However, note that you cannot compare "variance captured" when not using Mean Centering.'];
        color = 'red';
        issueid = 'frpcrnomncn';
        %add issue to list
        issues(end+1) = struct('issue',issue,'color',color,'issueid',issueid);
      end
      
      %-----------------------------------------------
      %Check for unusual Q's
      if ~isempty(modl.ssqresiduals{1})
        sq = sort(modl.ssqresiduals{1}(modl.detail.includ{1}));
        if length(modl.detail.includ{1})>15 && any(diff(sq)./max(sq)>.3);
          issue = ['Warning: This model appears to have some unusual Q residuals. '...
            'Please review Q residuals and Q contributions using the Scores plot and determine if these samples are errors that should be removed. '...
            'If these are not errors, consider adding additional samples and using more latent variables/principal components for a more reliable model. '];
          color = 'yellow';
          issueid = 'qoutliers';
          issues(end+1) = struct('issue',issue,'color',color,'issueid',issueid);
        end
      end
      
      %-----------------------------------------------
      %Check for unusual T2's
      st = sort(modl.tsqs{1}(modl.detail.includ{1}));
      if length(modl.detail.includ{1})>15 && any(diff(st)./max(st)>.3);
        issue = ['Warning: This model appears to have some unusual Hotelling''s T^2 values. '...
          'Please review T^2 and T contributions using the Scores plot and determine if these samples are errors that should be removed. '...
          'If these are not errors, consider adding additional samples which are like these. '];
        color = 'yellow';
        issueid = 't2outliers';
        issues(end+1) = struct('issue',issue,'color',color,'issueid',issueid);
      end
      
      %-----------------------------------------------
      %Check for rank deficiency
      if isfield(modl,'loads') & size(modl.loads{2},2)>3 & size(modl.loads{2},2)>=min(modl.datasource{1}.size(1)-1,modl.datasource{1}.size(2))
        issue = ['Warning: This model is "full rank" and may be an overfit to this particular data. '...
          'Consider using fewer components for a more reliable model. '];
        color = 'red';
        issueid = 'pcarank';
        issues(end+1) = struct('issue',issue,'color',color,'issueid',issueid);
      end
      
    case 'asca'
      if (modl.detail.effects(1)<1e-7)
        issue = ['Note: The x-block appears to be mean centered. '...
          'This is OK but will cause the "mean" in the effects table to be zero.'];
        color = 'yellow';
        issueid = 'ascamncn';
        issues(end+1) = struct('issue',issue,'color',color,'issueid',issueid);
      end
      
    case 'cls'
      %-----------------------------------------------
      %Check for mean centering (not desired)
      xoffset = max(abs((modl.detail.means{1}./modl.detail.stds{1})));
      yoffset = max(abs((modl.detail.means{2}./modl.detail.stds{2})));
      if (xoffset<1e-9) || (yoffset<1e-9)
        issue = ['Warning: It appears the x-block and/or y-block data have been mean-centered. '...
          'Mean centering with CLS models can cause significant performance problems. '...
          'It is recommended you do NOT use mean centering or autoscaling with CLS analyses.'];
        color = 'red';
        issueid = 'clsmncn';
        issues(end+1) = struct('issue',issue,'color',color,'issueid',issueid);
      end
      
    case 'parafac'
      %----------------------------------------------
      %Check for degeneracy result
      othertests = true;
      
      if ~modl.detail.converged.isconverged
        issue = ['Warning: ' modl.detail.converged.message '.'];
        color = 'red';
        issueid = 'parafacnoconvergence';
        issues(end+1) = struct('issue',issue,'color',color,'issueid',issueid);
        othertests = false;
      end
      
      if othertests & min(min(modl.detail.tuckercongruence-eye(size(modl.detail.tuckercongruence,2))))<(-.85)
        issue = ['Warning: Some factors are highly negatively correlated. This could indicate a '...
          'two-factor degeneracy. You can try to decrease the number of components. If this does '...
          'not help, try changing the model by changing preprocessing of the data or applying nonnegativity constraints.'];
        color = 'red';
        issueid = 'parafactuckercon';
        issues(end+1) = struct('issue',issue,'color',color,'issueid',issueid);
        othertests = false;
      end
      
      if othertests
        ssq = modl.detail.ssq.percomponent.data(:,[2 5]);
        if any(sum(ssq>100,1)>1)
          %more than one component with > 100% fit of X (or unique fit)
          issue = ['Warning: Consider using fewer components. The % X fit for this model indicates there may be a ' ...
            'degeneracy in the recovered components (Two or more components may be fitting the same feature '...
            'which would be better described using only one component.) Review the loadings and scores to '...
            'diagnose if there is a degeneracy.'];
          color = 'red';
          issueid = 'parafacdegen';
          issues(end+1) = struct('issue',issue,'color',color,'issueid',issueid);
        end
        
        E = modl.detail.coreconsistency.consistency;
        if E<30
          %core consistency looks poor
          issue = ['Warning: Check the core consistency plot. The core consistency for this model indicates there may be a ' ...
            'degeneracy in the recovered components (Two or more components may be fitting the same feature '...
            'which would be better described using only one component.)'];
          if E<0
            color = 'red';
          else
            color = 'yellow';
          end
          issueid = 'parafaccoredegen';
          issues(end+1) = struct('issue',issue,'color',color,'issueid',issueid);
        end
      end
      
  end
  
  switch lower(modl.modeltype)
    case {'lwr' 'pls' 'pcr' 'plsda' 'mlr' 'cls'}
      if isfieldcheck(modl,'modl.detail.cv') & isempty(modl.detail.cv) ...
          & (~strcmp(lower(modl.modeltype),'cls') | prod(modl.datasource{2}.size)>0)
        %(don't issue warning if CLS without y-block)
        issue = ['Warning: Cross-validation was not performed for this model. The reliability of this model should be assessed with either cross-validation or a separate validtion set. ' ...
          'Click on the model checkmark to enable cross-validation.'];
        color = 'yellow';
        issueid = 'nocrossval';
        issues(end+1) = struct('issue',issue,'color',color,'issueid',issueid);
      end
      
  end
  
  if isfieldcheck(modl,'modl.detail.cv') & strcmpi(modl.detail.cv,'rnd')
    issue = ['Caution: You used random cross-validation which may show different results due only to random sample selection. ' ...
      'Use caution when comparing cross-valdation results after making other changes - differences may be due only to random seed differences.'];
    color = 'yellow';
    issueid = 'randomcrossval';
    issues(end+1) = struct('issue',issue,'color',color,'issueid',issueid);
  end
  
  addissues = reviewcrossval(modl);
  issues = [issues; addissues];
  
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
