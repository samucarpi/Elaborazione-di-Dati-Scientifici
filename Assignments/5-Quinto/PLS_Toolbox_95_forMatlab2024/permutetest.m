function results = permutetest(x,y,rm,cvi,ncomp,options)
%PERMTEST Permutation testing for regression and classification models.
% Performs permutation test where the y-block is shuffled allowing the
% calculation of probability that the results obtained with the unperturbed
% y-block are significant or not (as compared to random chance). Inputs are
% identical to the standard call to crossvalidation.
%
% In addition to storing all Root Mean Square Error of Calibration (RMSEC)
% and cross-validation (RMSECV), the self-predicted and cross-validated
% residuals of each permutation are compared to the original residuals
% using the following tests:
%     Wilcoxon test
%     Sign test
%     Randomized t-test
%     T-test
% These tests give probability of similarity of the two sets of residuals.
% Thus, a low probability indicates the perturbed results are significantly
% different from the original model and, thus, the original model is
% significant. Note that many of these can provide valid results even with
% very few iterations. However, more iterations improve results and also
% permit better plots.
% 
% When requested the final plot of fractional y-block information captured
% by calibration and cross-validation versus y-correlation is shown. For
% more information, see permuteplot.
%
%INPUTS:
%         x = X-block data to be tested (DataSet or Double)
%         y = Y-block data to be tested (DataSet, Double or logical)
%        rm = regression method as defined in crossval
%       cvi = Cell array defining data split method and total permutation
%             iterations to be performed: {'method' splits iterations}.
%             For split method 'con' or 'rnd' it is best to leave the third 
%             cvi 'iterations' parameter = 1 to avoid slow performance as 
%             the permutation test is repeated iteration times, thus  
%             performing iterations*npermutation permutations. Use the  
%             npermutation option alone to control the number of 
%             permutations used in those cases.
%     ncomp = Maximum number of latent variables to be tested
%OPTIONAL INPUTS:
%   options = Options structure with one or more of the fields defined in
%             crossval. (See crossval for details on the options). In
%             addition, the following fields are defined for special use in
%             this function:
%         plotlvs = [ 1 ] Model size (in latent variables) to show in final
%                   display table and plots. The results for the model with
%                   the corresponding number of latent variables will be
%                   shown.
%    permutation : [ {'no'} | 'yes' ] Passed to crossval where it controls 
%                   whether to Perform a permutation test instead of simple
%                   cross-validation. 
%   npermutation : [ {100} ] Number of permutations to perform (if
%                   permutation flag is 'yes')
%OUTPUTS:
%   results = A structure with the following fields. Sizes are defined
%             using lvs = number of latent variables, iter = number of
%             iterations performed, and ny = number of y-block columns. All
%             fields are size = [lvs iterations ny] unless stated
%             otherwise.
%           rmsecvperm: RMSECV for each permuted y-block.
%            rmsecperm: RMSEC for each permuted y-block.
%               rmsecv: RMSECV for the original unpermuted y-block. 
%                        Size = [lvs 1 ny]
%                rmsec: RMSEC for the original unpermuted y-block. 
%                        Size = [lvs 1 ny]
%               cvprob: Probabilities calculated for cross-validated
%                       residuals. Sub-fields indicate method (defined
%                       above). Sizes all = [lvs ny]
%                cprob: Probabilities calculated for self-predicted
%                       residuals. Sub-fields indicate method (defined
%                       above). Sizes all = [lvs ny]
%                 ycor: Correlation of each original y-block column (rows
%                       here) with each permuted y-block (columns).
%                 rmsy: Root Mean Square of each y-block column.
%                    y: The original unpermuted y-block.
%
%I/O: results = permutetest(x,y,rm,cvi,ncomp,options)
%
%See also: CROSSVAL, PERMUTEPLOT, PERMUTEPROBS

%Copyright © Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.

if nargin==0; x = 'io'; end
if ischar(x)
  options = crossval('options');
  options.plotlvs = 1;
  if nargout==0; evriio(mfilename,x,options); else; results = evriio(mfilename,x,options); end
  return
end

if nargin<6
  options = [];
end
options = reconopts(options,mfilename);

if ~isdataset(y)
  %this function expects y to be a DSO (don't care about x though)
  y = dataset(y);
end

% get iteration information
if isfield(options, 'permutation') & strcmp('yes', options.permutation)
  nits = options.npermutation;
else
  nits = 100;
end

%- - - - - - - - - - - - - - - - - - 
%cross-validation settings
cvopts = options;
cvopts.plots = 'none';
cvopts.display = 'off';
cvopts.permutation = 'no';
cvin = {rm cvi ncomp cvopts};

%waitbar variables
starttime = now;
lasttime = now;
waitbarhandle = [];

%- - - - - - - - - - - - - - - - - - 
%get unperturbed crossval results first
res0 = crossval(x,y,cvin{:});

%- - - - - - - - - - - - - - - - - - 
%get some sizes and initialize matrices
[mx,ny,ncomp] = size(res0.cvpred);

rmsec   = nan(ncomp,nits,ny);
rmsecv  = rmsec;
probsw  = nan(ncomp,nits,ny);
probcsw = probsw;
probss  = probsw;
probcss = probsw;
probrt  = probsw;
probcrt = probsw;
probtt  = probsw;
probctt = probsw;

allcv0res = [];
allcv1res = [];

ycor    = nan(ny,nits);

ind = (1:mx)';

%- - - - - - - - - - - - - - - - - - 
%iterate shuffling y-block each time
for it = 1:nits;
    
  %waitbar update
  if (now-lasttime)>0.5/60/60/24;
    est      = (now-starttime)/it * (nits+1-it)*60*60*24;
    lasttime = now;
    if ~isempty(waitbarhandle)
      drawnow;
      if ~ishandle(waitbarhandle);
        error('Terminated by user...');
      end
      waitbar(it/(nits+1));
      set(waitbarhandle,'name',['Est. Time Remaining: ' besttime(est)])
      cvin{end}.waitbartrigger = inf;
      drawnow;
    elseif est > options.waitbartrigger
      desc = 'Permutation Testing...';
      waitbarhandle = waitbar(it/(nits+1),[ desc ' (Close to cancel)']);
      set(waitbarhandle,'name',['Est. Time Remaining: ' besttime(est)])
      cvin{end}.waitbartrigger = inf;
      drawnow;
    end
  end  %waitbar update
  
  %get shuffled y
  ord     = shuffle(ind);
  y_reord = y(ord,:);
  
  %cross-validate based on supplied conditions
  res     = crossval(x,y_reord,cvin{:});
    
  %store rmsec/cv results
  rmsec(:,it,:)  = res.rmsec';
  rmsecv(:,it,:) = res.rmsecv';
  
  %calculate probabilities on residuals
  for yi = 1:ny;
    ycol = double(y_reord(:,yi).data);
    for ci = 1:ncomp;
      
      %calculate residuals
      cv0res = res0.cvpred(ord,yi,ci) - ycol;
      cv1res = res.cvpred(:,yi,ci) - ycol;
      c0res  = res0.cpred(ord,yi,ci) - ycol;
      c1res  = res.cpred(:,yi,ci) - ycol;
      
      if ci==2;
      allcv1res = [allcv1res; cv1res];
      allcv0res = [allcv0res; cv0res];
      end
      
      if all(isnan(cv0res)); continue; end
      use = all(isfinite([cv0res cv1res c0res c1res]),2);
      
      probsw(ci,it,yi)  = wilcoxon(cv0res(use,:), cv1res(use,:));
      probcsw(ci,it,yi) = wilcoxon(c0res(use,:), c1res(use,:));
      
      probss(ci,it,yi)  = signtest(cv0res(use,:), cv1res(use,:));
      probcss(ci,it,yi) = signtest(c0res(use,:), c1res(use,:));
      
      probrt(ci,it,yi)  = randomttest(cv0res(use,:), cv1res(use,:));
      probcrt(ci,it,yi) = randomttest(c0res(use,:), c1res(use,:));
      
      probtt(ci,it,yi)  = getfield(ttest2p(cv0res(use,:), cv1res(use,:)),'p');
      probctt(ci,it,yi) = getfield(ttest2p(c0res(use,:), c1res(use,:)),'p');
      
    end
    %calculate correlation between permuted and normal y
    temp = corrcoef(y(:,yi).data,double(ycol));
    ycor(yi,it) = temp(2,1).^2;
  end
  
end  %main iteration loop

delete(waitbarhandle);

%- - - - - - - - - - - - - - - - - - 
%assemble output structure
out = [];
out.rmsecvperm  = rmsecv;
out.rmsecperm   = rmsec;
out.rmsecv      = permute(res0.rmsecv,[2 3 1]);
out.rmsec       = permute(res0.rmsec,[2 3 1]);

out.cvprob.wilcoxon    = permute(mean(probsw,2),[1 3 2]);
out.cvprob.signtest    = permute(mean(probss,2),[1 3 2]);
out.cvprob.randomttest = permute(mean(probrt,2),[1 3 2]);
out.cvprob.ttest       = permute(mean(probtt,2),[1 3 2]);

out.cprob.wilcoxon    = permute(mean(probcsw,2),[1 3 2]);
out.cprob.signtest    = permute(mean(probcss,2),[1 3 2]);
out.cprob.randomttest = permute(mean(probcrt,2),[1 3 2]);
out.cprob.ttest       = permute(mean(probctt,2),[1 3 2]);

out.ycor  = ycor;
out.rmsy  = rmse(y.data)';
out.y     = y;

results = out;

%- - - - - - - - - - - - - - - - - - 
%do plots and display if requested
if strcmp(options.plots,'final')
  permuteplot(out,options.plotlvs);
end
if strcmp(options.display,'on')
  permuteprobs(out,options.plotlvs);
end
