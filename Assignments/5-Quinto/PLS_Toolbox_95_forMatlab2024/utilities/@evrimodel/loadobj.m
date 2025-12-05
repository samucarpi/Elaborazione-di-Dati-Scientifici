function obj = loadobj(obj)
%EVRIMODEL/LOADOBJ Load method for EVRIMODEL objects.

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if isnewmodel(obj)
  
  disp('Warning: Loaded model object newer than present constructor.')
  disp('  Model object converted to structure.')
  obj = struct(obj);
  return
  
end

%Update model through a call to evrimodel constructor - this will do the
%actual updating of the model object (via updatemod and by handling missing
%top-level fields) If the model needs no updating, this will have no impact
obj = evrimodel(obj);  %DO NOT REMOVE!! This is critical!

if isfieldcheck(obj.content,'content.detail.history')
  obj.content.detail.history = sethistory(obj.content.detail.history,'','',['=== Loaded by ' userinfotag]);
end

if getfield(evrimodel('options'),'noobject')
  
  %noobject flag set? return CONTENT of model as structure
  if isfield(obj,'content')
    obj = obj.content;
  end
  disp('EVRIModel Object extracted and downgraded (''noobject'' flag in EVRIModel options is on)');
  return;

end

%---------------------------------------------------
%Need to overload here because if it's a standalone method it will only
%take an object and not structure. Old models can come in as structures.
%New models also could come in as structures if manually transformed.
function isnew = isnewmodel(thismodel)
%EVRIMODEL/ISNEWMODEL Test if model is newer than current version.
% If isnew = 1 then model is newer than current object (and should not be
% loaded in most circumstances).

%Copyright Eigenvector Research, Inc. 2016
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

isnew = 0;
currentmodel = evrimodel;
if isfield(currentmodel,'evrimodelversion')
  pv  = nver(currentmodel.evrimodelversion);   %present version of constructor
else
  pv = nver(currentmodel.modelversion);
end
ov  = nver(thismodel.evrimodelversion);    %version of the loaded dataset object

if ov>pv
  isnew = 1;
end

%---------------------------------------------------
function out = nver(v)
%convert string version: x.y OR x.y.z into numerical value

% npoints = sum(v=='.');
% if npoints>1
%   r = v;
%   out = 0;
%   for j=1:npoints+1;
%     [vp,r] = strtok(r,'.');
%     out = out + str2double(vp)/(10.^(j-1));
%   end
% else
%   out = str2double(v);
% end

% split version string into tokens separated by periods
% toks = regexp(v, '\.', 'split');
% convert strings to numbers
% toks = cellfun(@(x)str2double(x), toks);
% create multipliers of decades: [1 .1 ...]
% pwrs = 10.^(-[0:length(toks)-1]);
% out  = sum(toks.*pwrs);

strinds = strfind(v, '.');
inds    = 1:length(strinds);
v(strinds(inds>1))=[];
out     = str2double(v);
