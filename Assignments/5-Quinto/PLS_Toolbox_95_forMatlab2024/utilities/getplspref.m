function varargout = getplspref(mfile,pref)
%GETPLSPREF Get overriding options (preferences) for PLS_Toolbox functions.
% Retrieves user-defined "overriding default options" for a PLS_Toolbox
% function.
%
% Optional inputs are (mfile) the function name for which preferences
% should be retrieved (If omitted, a structure of all mfile preferences
% will be returned) and (pref) a specific preference to retrieve (default
% is all preferences for the given mfile)
%
%I/O: getplspref(mfile,pref)
%
%See also: SETPLSPREF

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS 10/04/02
%rsk 08/15/05 move test for installing so evriupdate doesn't get run.
%jms 8/26/05 return [] if no settings for fn and specific pref requested
%jms 8/31/05 explictly test for PLS_Toolbox evrirelease
%  -don't do installation or update checks if isdeployed (ver 7.x+ only)
%  -return correctly if no internet access available

if nargin == 0;
  myprefs = [];
  if ~isappdata(0,'PLS_Prefs');
    if ispref('PLS_Toolbox');
      myprefs = getpref('PLS_Toolbox');
    end
  else
    myprefs = getappdata(0,'PLS_Prefs');
  end
  if isempty(myprefs)
    myprefs = struct([]);
  end
  varargout = {myprefs};
  return
end

%read in PLS_Prefs if they aren't already
if ~isappdata(0,'PLS_Prefs');
  myprefs = getpref('PLS_Toolbox');
  setappdata(0,'PLS_Prefs',myprefs);
  %Set all warnings that PLS_Toolbox should ignore off.
  evriwarningswitch;
  
  %First time we're reading preferences this session? Check if we've been installed using evriinstall
  %if we have, the release version will match that stored by evriinstall
  installing = getappdata(0,'PLS_Toolbox_installing');
  if (isempty(installing) | ~installing)
    %If not installing right now...
    warning('off','MATLAB:oldPfileVersion');  %force this warning off ALWAYS!
    
    if (exist('isdeployed') & ~isdeployed) & ~exist('evrinetwork.lic')
      %not deployed AND not told not to bother checking
      if (~isfieldcheck('val.evriinstall.version',myprefs) | ~strcmp(myprefs.evriinstall.version,evrirelease('PLS_Toolbox')))
        insans = questdlg({'This Eigenvector Research product was not installed correctly (using the command "evriinstall"). If it is not run, some functions may not operate correctly and support will not be given for your license.',' ','Run installation now or postpone until Later?'},'Installation Error','Install Now','Later','Install Now');
        switch insans
          case 'Postpone'
            %this will automatically work because we've got the preferences
            %now (ans stored them in appdata) but we'll also go ahead and set
            %the "installing" flag which makes sure the user isn't asked
            %again DURRING THIS SESSION
            setappdata(0,'PLS_Toolbox_installing',1);  %fake installing
          case 'Install Now'
            varargout = {[]};
            evriinstall
            error('Last action aborted while installing PLS_Toolbox');
        end
      else
        %we were installed correctly, just try running evriupdate
        % (NOTE: do not do this if we run evriinstall - it is done there too)
        if ~strcmp(mfile,'evriio')
          evriupdate auto;
        end
      end
    end
    
    % Add jars to the dynamic javaclasspath
    evrijavasetup;
  end
  
else
  myprefs = getappdata(0,'PLS_Prefs');
end

if ~isfield(myprefs,mfile);
  switch nargin
    case 2
      varargout = {[]};
    otherwise
      varargout = {struct([])};
  end
else
  out = getfield(myprefs,mfile);
  switch nargin
    case 2
      if isfield(out,pref);
        out = getfield(out,pref);
      else
        out = [];
      end
  end
  varargout = {out};
end
