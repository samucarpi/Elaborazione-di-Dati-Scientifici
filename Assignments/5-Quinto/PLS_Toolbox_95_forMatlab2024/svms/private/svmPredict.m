function [predictions] = svmPredict(x, y, model, args)
%SVMPREDICT: Apply Support Vector Machine model to supplied test data.
%
%  This function applies a LIBSVM model to supplied test data in either
%  a classification or regression mode.
%  Returns predictions of the input samples' class membership (classification)
%  or y value predictions (regression)
%
%  INPUTS:
%  x: 	values. m by n array, m samples, n variables
%  y: 	labels. vector of length m indicating sample class (SVM
%     classification) or y value (SVM regression).
%  args:	Arguments. LIBSVM arguments in a struct form.
%
%  OUTPUT:
%  predictions of the input samples' class membership (classification)
%  or y value predictions (regression)
%
% %I/O: out = svmPredict(x, y, model, options); Use x and model for prediction

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

showwaitbar = strcmpi(args.waitbar,'on');
  
%drop bad arguments (not allowed in predict mode)
allowedargs = {'b', 'q'};
for f = allowedargs;
  if isfield(args,f{:})
    aargs.(f{:}) = args.(f{:});
  end
end
args = aargs;

% convert args struct to cell array suitable for libsvm
newargs = libsvmArgs(args);

pr = libsvm.evri.SvmPredict2;
try
  free = java.lang.Runtime.getRuntime.freeMemory;
  sz=size(x);
  tresh = 10;
  doublebytes = 8; % number of bytes for a double
  binlen = floor(free/(tresh*size(x,2)*doublebytes));
  binstarts = 1:binlen:sz(1);
  binends = min(binstarts+binlen-1, sz(1));
  nbins = length(binstarts);
  binlens = binends - binstarts + 1;
  
  % break predictions into segments and combine results
  predictions = repmat(NaN, sz(1),1);
  if showwaitbar
    h = waitbar(0,'Performing prediction... (Close to cancel)');
    set(h,'name','SVM Prediction');
  else
    h = [];
  end
  for ibin = 1:nbins
    range = binstarts(ibin):binends(ibin);
    if ~isempty(y)
      predictions(range) = pr.apply(x(range,:), y(range), model, newargs);
    else
      predictions(range) = pr.apply(x(range,:), [], model, newargs);
    end
    
    if ~isempty(h)
      %show progress bar
      if ~ishandle(h)
        error('Prediction aborted by user');
      end
      waitbar(ibin/nbins,h);
    end
    
  end
catch
  z = lasterror;
  z.message = ['svmPredict error: ' z.message];
  if ishandle(h)
    delete(h);
  end
  rethrow(z)
end

if ishandle(h)
  delete(h);
end
