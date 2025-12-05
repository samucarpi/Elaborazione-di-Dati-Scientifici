function obj = loadobj(obj)
%EVRISCRIPT_STEP/LOADOBJ Load object method for object.

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

opts = evriscript('options');
if opts.keywordonly
  obj = struct('execute','Loading EVRISCRIPT from a file is currently disabled ("keywordonly" mode enabled)');
  return
end

junk  = evriscript_step;
pv  = nver(junk.evriscript_stepversion);   %present version of constructor
ov  = nver(obj.evriscript_stepversion);    %version of the loaded dataset object

if ov>pv
  
  disp('Warning: Loaded EVRIScript_step object newer than present constructor.')
  disp('  Model object converted to structure.')
  obj = struct(obj);
  return
  
end

if ov==1
  %specal backwards compatibility fixes (a field was added but we forgot to
  %change the version number - this object MIGHT be an old one without the
  %step_optional field, so add it now if we're missing it (but add it in
  %the right place!!)
  if ~isfield(obj,'step_optional')
    opts = obj.options;
    obj = struct(obj);
    obj = rmfield(obj,'options'); %REMOVE the field for a moment...
    obj.step_optional = 'pseduo-property';  %add missing field
    obj.options = opts;  %REPLACE options at end
    obj = class(obj,'evriscript_step'); 
  end
end    
if ov==pv
  %correct current version... exit now
  return
end

%---------------------------------------------------
function out = nver(v)
%convert string version: x.y OR x.y.z into numerical value

npoints = sum(v=='.');
if npoints>1
  r = v;
  out = 0;
  for j=1:npoints+1;
    [vp,r] = strtok(r,'.');
    out = out + str2double(vp)/(10.^(j-1));
  end
else
  out = str2double(v);
end
