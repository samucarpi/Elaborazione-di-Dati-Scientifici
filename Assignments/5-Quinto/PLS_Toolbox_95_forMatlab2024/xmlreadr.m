function [object,theStruct] = xmlreadr(filename,options)
% XMLREADR Convert XML file to a MATLAB structure.
%
% XMLREADR is a wrapper function around PARSEXML. The only functionality
% which XMLREADR adds is to prompt the user to identify the file to load if
% the filename parameter is empty. The parsexml parameter 'nooutertag' is
% represented by options.nooutertag, with default = false.
% See PARSEXML for complete function description.
%
% INPUT:
%  filename = XML filname to convert. If input (filename) is omitted, the
%             user will be prompted for a file name to read.
%
% OPTIONAL INPUT:
%   options = structure array with the following field:
%     nooutertag : [{false} | true] when set to "true" this input indicates
%             that the outer-most xml object should be stripped from the
%             resulting output (object). This allows direct access to the
%             object itself rather than a structure with the object as the
%             first and only field of that structure.
%
% OUTPUTS:
%    object = MATLAB object.
% theStruct = is the pre-parsed XML object and allows access to raw field
%             attributes and other content that cannot be converted into
%             a Matlab object.
%
%I/O: [object,theStruct] = xmlreadr(filename,options);
%
%See also: PARSEXML, ENCODEXML

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

object    = [];
theStruct = [];

if nargin == 0
  filename = [];
elseif (ischar(filename) & isempty(filename))
  filename = [];
elseif nargin==1 & ischar(filename) & ismember(filename,{ 'io' 'demo' 'help' 'options' 'factoryoptions' 'test' 'clearlicense' 'release' })
  options = [];
  options.name = 'options';
  options.nooutertag = false;
  if nargout==0; clear object; evriio(mfilename,filename,options); else; object = evriio(mfilename,filename,options); end
  return;
end

% Prompt user if no filename was passed in
if nargin<2
  options = [];
elseif isnumeric(options) | islogical(options)
  %user supplied numeric as second input? assume it is nooutertag value
  options = struct('nooutertag',options);  
end
options = reconopts(options,mfilename);

%prompt for file (if not supplied)
if nargin<1 | isempty(filename)
  [filename,pth] = evriuigetfile({'*.xml' 'XML files';'*.*' 'All Files'});
  if isnumeric(filename) %canceled out
    return
  end
  filename = fullfile(pth,filename);
end

% reconcile options
nooutertag = options.nooutertag;

[object,theStruct] = parsexml(filename,nooutertag);
 
