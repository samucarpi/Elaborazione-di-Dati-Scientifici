function keep(varargin)
%KEEP Clear all except named variables in workspace
% Given a list of variables, KEEP clears all other variables
% in the workspace of the calling function. Input (varlist)
% is a text string or cell array of text strings.
%
% Examples:
%    keep j m s
%    keep('j','m','s')
%    mycell = {'j','m','s'}; keep(mycell)
%  would each keep the variables j, m, and s and clear all others
%
%I/O: keep(varlist)
%
%See also: CLEAN, CLEAR

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms
%nbg 8/05 changed help
%jms 10/05 
%  - added test for could not find variable(s) 
%  - fixed nothing cleared (=clear all!!!) bug

if nargin==0;
  error('One or more variable names must be supplied');
end

if nargin==1 & iscell(varargin{1})
  varargin = varargin{1};   %allows cell list of vars to keep
end

list = evalin('caller','who');

notfound = setdiff(varargin,list);
if ~isempty(notfound);
  error(['Nothing cleared - Could not find variable(s) with name(s): ' sprintf('%s ',notfound{:})]);
end

list = setdiff(list,varargin);
if ~isempty(list);
  evalin('caller',['clear' sprintf(' %s',list{:})]);
end
