function safestring = string_x(string);
%STRING_X Add backslash before troublesome TeX characters.
% The TeX interpreter is used on various text objects in figures to add
% subscripts, superscripts and other special effects to text. These effects
% are triggered by special characters in strings. STRING_X "escapes" these
% special characters to keep them from being handled by the TeX
% interpreter.  An escaping backslash is added before each of these
% characters: _ ^ { }
%
% Input is a string (string), output is the backslashed string
% (safestring).
%
%I/O: safestring = string_x(string);

% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%Original by WW, Revised 3/04 JMS, added help

%Create a blank line which will contain the \ chars where needed
a        = blanks(length(string));

%Identify where \s are needed and add those to line
badchar  = ismember(string,'_^{}');   %add other tests here
a(badchar) = '\';

%Get a master index which contains 1 for all chars which should make it
%into the final string (only \ chars in the top line will be used)
ind      = [badchar; ones(1,length(string))];
string   = [a;string];

%Do the prepend of \ using the identified chars to use
safestring = string(logical(ind))';
