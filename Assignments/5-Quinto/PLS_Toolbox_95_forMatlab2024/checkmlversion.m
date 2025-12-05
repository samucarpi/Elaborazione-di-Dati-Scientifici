function out = checkmlversion(ctype,mlv)
%CHECKMLVERSION Check current version of Matlab against intput version and comparison.
%
%  NOTE: This is the preferred way of checking versions, the GETMLVERSION
%        way of checking does not work for versions 7.10 and higher.
%  Input:
%     ctype  : ['>='] type of check comparison. Can be any of:
%                 >  <  <=  >=  ==  ~=
%               If omitted, '>' is used.
%     mlv    : ['7.10'] string of version to test for.
%
%  Example:
%    If current working version of Matlab is 7.9 then
%      * checkmlversion('>','7') = true 
%        the current version of Matlab is greater than 7.0.
%      * checkmlversion('>=','7.10') = false
%        the current version of Matlab is NOT >= Matlab 7.10 (R2010a)
%
%I/O: out = checkmlversion('7.9')
%I/O: out = checkmlversion('>','7.4')
%I/O: out = checkmlversion(ctype,mlv)
%
%See also: GETMLVERSION

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
% rsk

persistent cur_major cur_minor

if nargin<1
  error('CHECKMLVERSION needs at least one input.');
end

if nargin == 1
  mlv = ctype;
  ctype = '>';
end

if ~isstr(mlv)
  error('Version number must be in form of a string.');
end

if isempty(cur_major)
  [cur_major, cur_minor] = getversioninfo(version);
end

[chk_major, chk_minor] = getversioninfo(mlv);

out = false;

switch ctype
  case '=='
    if (chk_major == cur_major) && (chk_minor == cur_minor) 
      out = true;
    end
  case '~='
    if (chk_major ~= cur_major) || (chk_minor ~= cur_minor) 
      out = true;
    end
  case '>='
    if cur_major > chk_major
      out = true;
    elseif (cur_major == chk_major) && cur_minor >= chk_minor
      out = true;
    end
  case '<='
    if cur_major < chk_major
      out = true;
    elseif (cur_major == chk_major) && cur_minor <= chk_minor 
      out = true;
    end
  case '>'
    if cur_major > chk_major
      out = true;
    elseif (cur_major == chk_major) && ( cur_minor > chk_minor)
      out = true;
    end
  case '<'
    if cur_major < chk_major
      out = true;
    elseif (cur_major == chk_major) && (cur_minor < chk_minor)
      out = true;
    end
  otherwise
    error('Unrecognized comparison operator.')
end


function [majorv, minorv] = getversioninfo(myver)
%Seperate version number from string.

thisver = sscanf(myver, '%d.%d')';
if length(thisver) < 2
  thisver(2) = 0; % zero-fills to 3 elements
end
majorv = thisver(1);
minorv = thisver(2);


