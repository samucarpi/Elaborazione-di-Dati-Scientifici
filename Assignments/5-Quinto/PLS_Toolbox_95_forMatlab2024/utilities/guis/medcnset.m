function pp = medcnset(pp);
%MEDCNSET Returns default median centering preprocessing structure.
% Both input (p) and output (p) are preprocessing structures
% If no input is supplied or is 'default', default structure 
%  is returned.
%
%I/O:   p = medcnset(p)
%I/O:   p = medcnset('default')
%
%See also: MEDCN, MNCN, PREPROCESS, RESCALE, SCALE

%Copyright Eigenvector Research 2001
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% JMS 4/9/2002

if nargin > 0 & ismember(pp,evriio([],'validtopics'));
  options = [];
  if nargout==0; evriio(mfilename,pp,options); clear pp; else; pp = evriio(mfilename,pp,options); end
  return; 
end

if nargin == 0 | (isa(pp,'char') & strcmp(pp,'default'));
  pp = [];
  pp.description   = 'Median Center';
  pp.calibrate     = {'[data,out{1}] = medcn(data);'};
  pp.apply         = {'data = scale(data,out{1});'};
  pp.undo          = {'data = rescale(data,out{1});'};
  pp.out           = {[]};
  pp.settingsgui   = '';
  pp.settingsonadd = 0;
  pp.usesdataset   = 0;
  pp.caloutputs    = 1;
  pp.tooltip       = 'Remove median offset from each variable';
  pp.category      = 'Scaling and Centering';
end;

%-------------------------------------------------------------------
function linkwithfunctions
%placeholder function - this is just so that we'll make sure the compiler
%includes these functions when compiling

medcn
