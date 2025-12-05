function desgn=boxbehnken(k)
%BOXBEHNKEN Create a Box-Behnken Design of Experiments.
% Input (k) is the number of factors to include in the model. Output is a
% code, centered Box-Behnken design in which all factors will have three
% levels.
%
%I/O: desgn = boxbehnken(k)
%
%See also: BOXBEHNKEN, CCDFACE, CCDSPHERE, DOEGEN, DOESCALE, FACTDES, FFACDES1

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0; k = 'io'; end
if ischar(k);
  options = [];
  if nargout==0; evriio(mfilename,k,options); else; desgn = evriio(mfilename,k,options); end
  return; 
end

%get a 3-level k-factor full factorial
d = factdes(k,3);

switch k
  case {1 2}
    %with one factor, use ALL points
    use = true(size(d,1),1);
  case 3
  %with more than one factor, only keep points with only one factor at
  %zero or all factors at zero (center point)
  use = ismember(sum(d==0,2),[1 k]);
  case 4
    use = ismember(sum(d==0,2),[2 k]); % keep points with 2 facs at zero
    % or all factors at zero (center point)
  case 5
    use = ismember(sum(d==0,2),[3 k]); % keep points with 3 facs at zero
    % or all factors at zero (center point)
%   case 6
%     use = ismember(sum(d==0,2),[4 k]); % keep points with 4 facs at zero
%     % [1 k] gives 193. [4 k] gives 61. Wikipedia and R say 48+1
  otherwise
    error('Box-Behnken design only supported up to 5 factor'); %7 factors')
end
desgn = d(use,:);
