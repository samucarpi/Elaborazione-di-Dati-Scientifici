function evriclearlicense(force)
%EVRICLEARLICENSE Clears any stored EVRI license information.
% After license is cleared, user is prompted for a new license code. If a
% new valid license code is not entered, the old license code information
% is restored (whether or not it was valid).
% If input (force) if set to 1 (true), EVRICLEARLICENSE will clear old
% license code information without requesting a new license code. Any
% existing license code will be discarded. Default is to ask for a new
% license code.
%
%I/O: evriclearlicense(force)
%
%See also: EVRIINSTALL


%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<1
  force = 0;
end

%If we find a license file, we need to throw an error the user
%needs to delete the file manually before the license can be cleared. Don't
%use dialog because if user accidentally deletes file it will be difficult
%to undo.
mylic = which('evrilicense.lic');
if ~isempty(mylic)
  error([10 'License file found, please manually delete this file before clearing license:' 10 10 mylic])
end

try
  license = getpref('EVRI','license');
catch
  license = '';
end
setpref('EVRI','license',[]);
setappdata(0,'EVRI_license',[]);
if ispref('EVRI_LM')
  temp = getpref('EVRI_LM');
  rmpref('EVRI_LM');
  if isfield(temp,'localid');
    %if localid was set REset it. We don't want to change localid
    %when the rest of the license info is cleared
    setpref('EVRI_LM','localid',temp.localid);
  end
end

clear evriio
if (force)
  %don't even ask for new code
  return
end
z=evriio('test');  %force request of new license info

if ~isempty(findstr(z,'expired')) & ~isempty(license);
  setpref('EVRI','license',license)
  setappdata(0,'EVRI_license',license)
end

  
