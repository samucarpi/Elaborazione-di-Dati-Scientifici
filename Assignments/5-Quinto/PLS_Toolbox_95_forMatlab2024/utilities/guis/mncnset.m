function pp = mncnset(pp);
%MNCNSET Returns default mean centering preprocessing structure.
% Both input (p) and output (p) are preprocessing structures
% If no input is supplied or is 'default', default structure 
%  is returned.
%
%I/O:   p = mncnset(p)
%I/O:   p = mncnset('default')
%
%See also: MNCN, PREPROCESS, RESCALE, SCALE

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
  pp.description   = 'Mean Center';
  pp.calibrate     = {'[data,out{1}] = mncn(data);'};
  pp.apply         = {'data = scale(data,out{1});'};
  pp.undo          = {'data = rescale(data,out{1});'};
  pp.out           = {[]};
  pp.settingsgui   = '';
  pp.settingsonadd = 0;
  pp.usesdataset   = 0;
  pp.caloutputs    = 1;
  pp.tooltip       = 'Remove mean offset from each variable';
  pp.category      = 'Scaling and Centering';
end;
