function out = myfunction(in,options)
%MYFUNCTION Example shell for new PLS_Toolbox function.
%  Briefly explain what the function does. Give description of inputs (in)
%  and outputs (out), unless there are more than 3 to 4 of them. In that
%  case use the following format.
%
%  INPUTS:
%        in  = Explain what is expected for this input
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%          display: [ 'off' | {'on'} ]      governs level of display to command window.
%            plots: [ 'none' | {'final'} ]  governs level of plotting.
%  OUTPUTS:
%       out  = Explain what will be returned in this output
%
%  Explain caveats about using the function including special I/O options
%  here.
%
%I/O: out = myfunction(in,options);
%I/O: myfunction demo
%
%See also: OTHER, RELATED, FUNCTIONS

% Copyright © Eigenvector Research, Inc. 2005
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%Initial coding by: 

%----------
% Replace all occurances of "in" in the following code with the name of
% your first input variable or varargin{1} if this function uses varargin
% instead of a named input variables. Replace "out" in the following code
% with the name of your first output variable or varargout{1} if this
% function uses varargout instead of named output variables.
if nargin == 0; in = 'io'; end  %replace "in" with name of first variable or varargin{1}
if ischar(in);
  %If this function takes strings as first input, use this line instead of
  %the above one.
  %if isa(in,'char') & ismember(in,evriio([],'validtopics')); 
  options = [];
  %Default options structure goes here.
  options.plots = 'off';%Default value.
  options.display = 'on';%Default value.
  
  %Make sure variable names are correct in this line (e.g., 'in' and 'out').
  if nargout==0; evriio(mfilename,in,options); else; out = evriio(mfilename,in,options); end
  
  return;
end

%Additional options checking can go here.
if nargin < 2
  options = [];%Create dummy var so reconopts will fill in defaults.
end
options = reconopts(options,mfilename);%Fill in any missing options values.

%main function goes here
out = in;
