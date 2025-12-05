function obj = calibrate(obj)
%EVRIMODEL/CALIBRATE Calibrate a model based on the current parameters.
% Calibrate a model based on a stored EVRIScript object.
%
%I/O: model = calibrate(model)

%Copyright (c) Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if isempty(obj.calibrate)
  error('No calibrate method defined for this model type. See "%s" function for help.',lower(obj.content.modeltype));
end
if iscalibrated(obj)
  error('Model is already calibrated')
end

%check for "automatic" ncomp mode
if ismember('ncomp',getcalprops(obj)) & ischar(obj.calibrate.script.ncomp) & strcmpi(obj.calibrate.script.ncomp,'auto')
  %TODO: handle automatic ncomp mode
  % 1) build model (using 1 component)
  % 2) cross-validate
  % 3) call choosecomp
  % 4) reset ncomp to selected # of components (and fall through to
  % code below which will re-build with that # of components)
  error('Automatic component selection not enabled');
end

%we have an evriscript object, try executing it
try
  scr = obj.calibrate.script.execute;
catch
  le = lasterror;
  le.stack = le.stack(end);
  rethrow(le);
end

if getfield(evrimodel('options'),'usecache')
  %add results to model cache (if possible)
  data = {};
  for f = {'x' 'y'};
    if ismember(f{:},getcalprops(obj)) & ~isempty(scr.(f{:}))
      data{end+1} = scr.(f{:});
    end
  end
  modelcache(scr.model,data);
end

temp         = scr.model;
for tocopy = {'contributions' 'matchvars' 'reducedstats' 'plots' 'display'};
  temp.(tocopy{:}) = obj.(tocopy{:});
end

obj = temp;
