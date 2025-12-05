function isnew = isnewmodel(thismodel)
%EVRIMODEL/ISNEWMODEL Test if model is newer than current version.
% If isnew = 1 then model is newer than current object (and should not be
% loaded in most circumstances).

%Copyright Eigenvector Research, Inc. 2016
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%NOTE: This function is overloaded in loadobj because of data type
%conflict. Any modifications made here should be made in loadobj as well.

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
