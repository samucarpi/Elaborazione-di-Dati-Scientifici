function str = safename(str)
%SAFENAME Returns valid Matlab variable name
% Removes all illegal characters. 
% Note: can't use genvarname.m because not available in ML 7.0.
%
%I/O: str = safename(str)

%Copyright © Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if isempty(str); return; end

safechars = ['A':'Z' 'a':'z' '0':'9' '_'];
lsc = length(safechars);
str(str==' ') = [];

%drop bad characters
bad = find(~ismember(str,safechars));
for j=length(bad):-1:1
  conv = ['0x' dec2hex(str(bad(j)),2)];
  str = [str(1:bad(j)-1) conv str(bad(j)+1:end)];
end

if ~ismember(lower(str(1)),'a':'z')
  str = ['d' str];
end

%Fold end of string (beyond end of allowed length) into end of string so we
%preserve SOME aspect of uniqueness but don't exceed max characters
while length(str)>63
  %convert from string to index
  [c,junk,stri] = unique([safechars,str]);
  stri = stri(lsc+1:end);
  
  %find part to remove
  l = length(str);
  th = min(l-63,floor(l/3));
  remove = stri(end-th+1:end);
  stri = stri(1:end-th);
  
  %combine remove with end of str
  stri(end-th+1:end) = stri(end-th+1:end)+remove;
  
  %convert back to string
  str = c(mod(stri-1,lsc)+1);
end
