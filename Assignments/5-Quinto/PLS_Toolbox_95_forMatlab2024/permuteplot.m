function fig = permuteplot(varargin)
%PERMUTEPLOT Create plot of permutation test results.
% Produces a plot of fractional y-block information captured by calibration
% and cross-validation versus y-correlation is shown. The x-axis of this
% figure shows the correlation of each permuted y-block against the
% original. The y-axis shows the fractional information captured (1 -
% RMS(E).^2 / RMS(Y).^2). The plot includes the unperturbed results too. A
% significant difference between the unperturbed and permuted y-block
% results indicates the likelihood of original model significance.
%
%INPUTS:
%   results = Results structure from permutetest.
%OPTIONAL INPUTS:
%      nlvs = Number of latent variables for which results should be shown.
%OUTPUTS:
%      fig = Handle of the created figure.
%
%I/O: fig = permuteplot(results,nlvs)
%
%See also: PERMUTEPLOT, PERMUTEPROBS, PERMUTETEST

%Copyright © Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.

if isstruct(varargin{1})
  %create a plot
  r = varargin{1};
  if nargin>1
    nlv = varargin{2};
  else
    nlv = 1;
  end
  nlv = min(size(r.rmsec,1),max(1,nlv));  %limit to number of LVs in model
  ny = length(r.rmsy);
  
  fig = figure;
  [nr,nc] = mplot(ny);
  mydata = [];
  mylabels = {};
  for yi = 1:ny
    subplot(nr,nc,yi);
    ycor = [1 r.ycor(yi,:)];
    q2y = 1-[r.rmsecv(nlv,:,yi) r.rmsecvperm(nlv,:,yi)].^2./(r.rmsy(yi,1).^2);
    r2y = 1-[r.rmsec(nlv,:,yi)  r.rmsecperm(nlv,:,yi) ].^2./(r.rmsy(yi,1).^2);
    
    %subtract mean and divide by standard deviation
    [junk,mn,sd] = auto([q2y(2:end)';r2y(2:end)']);
    q2y = (q2y-mn)/sd;
    r2y = (r2y-mn)/sd;
    
    m = 0; %mean([q2y(:);r2y(:)]);
    req = polyfit(ycor(:),r2y(:)-m,1);
    qeq = polyfit(ycor(:),q2y(:)-m,1);
    
    h = plot(...
      ycor,r2y-m,'g^',ycor,q2y-m,'bs',...
      [0 1],polyval(req,[0 1]),'g-',[0 1],polyval(qeq,[0 1]),'b-');
    
    set(h(1),'markerFaceColor','g')
    set(h(2),'markerFaceColor','b')
    legendname(h(1),'Fractional Y Calibration')
    legendname(h(2),'Fractional Y Cross-Validation')
    legendname(h(3),'Fractional Y Calibration Fit')
    legendname(h(4),'Fractional Y Cross-Validation Fit')
    hl = hline('k--');
    set(hl,'handlevisibility','off');
    
    ylabel('Standardized SSQ Y (CV and C)')
    xlabel('Correlation permuted Y to original Y')
    title(sprintf('Sum Squared Y (C & CV) for %i Components',nlv));
    
    if ny==1
      ylbl = '';
    else
      ylbl = sprintf('%i',yi);
    end
    
    mydata = [mydata [ycor;r2y-m;q2y-m]'];
    mylabels = [mylabels {sprintf('Y%s Correlation',ylbl) sprintf('Fractional Y%s Calibration',ylbl) sprintf('Fractional Y%s Cross-Validation',ylbl)}];
  end
  
  results = dataset(mydata);
  results.label{2} = mylabels;
  setappdata(fig,'permutation_results',results);
  
  btnlist = {
    'table_edit'  'editdata'  'editds(getappdata(gcbf,''permutation_results''));'  'enable' 'View Results in Editor'          'off' 'push'
    'save'        'savedata'  'svdlgpls(getappdata(gcbf,''permutation_results''))' 'enable' 'Save Results to Workspace/File'  'off' 'push'
    };
  toolbar(fig,'',btnlist);
  
end

if nargout==0
  clear fig
end
