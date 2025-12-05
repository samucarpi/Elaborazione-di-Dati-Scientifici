function evrireporterror
%EVRIREPORTERROR Gathers error information and optionally reports it.
% User is given an option to automatically send information or simply copy
% it to the clipboard for self-reporting.
% NOTE: This function reports the path information which some users might
% consider proprietary. If you do not wish to send this information, you
% must use the self-reporting method and edit this information from the
% report. Path information may, however, be needed to fully diagnose errors
% encountered.
%
%I/O: evrireporterror

%Copyright Eigenvector Research, Inc. 2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%gather error, installation and path information

%WARNING: DO NOTHING before these lines! If anything happens which causes
%an error now, the critical error information needed here will be lost!
errinfo = lasterr;  %store error string now
generrinfo = lasterror;

%create waitbar
wbh = [];
try
  wbh = waitbar(.33,'Collecting Error Information...');
catch
end

%gather the other information
if checkmlversion('<','7')
  generrinfo.stack = dbstack;
  generrinfo.stack(1,1).name = 'evrireporterror can not obtain additional error stack details in this Matlab version';
end

try
  errinfo = encode(generrinfo,'lasterror');
catch
  %just use existing lasterr information gathered just above
end

try
  dbinfo = evridebug;
catch
  dbinfo = 'Not available';
end

if ~isempty(wbh) & ishandle(wbh); wbh = waitbar(.66,wbh); end
try
  installinfo = str2cell(plsver);
catch
  installinfo = {'Not available'};
end

try
  cobj = evricachedb;
  cacheinfo = cobj.getstats;
catch
  cacheinfo = {'Not available'};
end

try
  info = sprintf(...
    '%s\n','---ERROR INFORMATION--------------------------------------',errinfo,...
    ' ',   '---DEBUG INFORMATION--------------------------------------',dbinfo{:},...
    ' ',   '---MODEL CACHE INFORMATION--------------------------------',cacheinfo{:},...
    ' ',   '---SYSTEM INFORMATION-------------------------------------',installinfo{:});
catch
  info = errinfo;
end

try
  %copy to clipboard
  clipboard('copy',info);
  onclipboard = true;
catch
  onclipboard = false;
end

%delete waitbar
if ishandle(wbh); 
  delete(wbh);
end

%ask how to handle this information.
method = '';
while isempty(method)
  if onclipboard
    method = evriquestdlg('Error information has been copied to your clipboard, you can paste this into an e-mail message and send to helpdesk@eigenvector.com yourself, or choose to have it sent to the Eigenvector Internet Help server automatically.','Help Information Ready','Automatic Request','Show Contents','Cancel (Send Myself)','Automatic Request');
  else
    method = evriquestdlg('Error information available. You can view this information or choose to have it sent to the Eigenvector Internet Help server automatically.','Help Information Ready','Automatic Request','Show Contents','Automatic Request');
  end
  switch method
    case 'Show Contents'
      uiwait(infobox([{'====Error Report===='};{' '};str2cell(info)]));
      method = '';
    case 'Automatic Request'

      %check for existing information we've stored before
      name = '';
      email = '';
      username = '';
      try
        prefs = getpref('PLS_Toolbox');
        if isfield(prefs,'evrireporterror')
          prefs = prefs.evrireporterror;
          if isfield(prefs,'name');
            name = prefs.name;
          end
          if isfield(prefs,'email')
            email = prefs.email;
          end
          if isfield(prefs,'username')
            username = prefs.username;
          end
        end
      catch
      end
         
      %get contact info
      contact = inputdlg({'Enter your name' 'AND: contact e-mail address' 'OR: Eigenvector Research Username'},'Contact information',1,{name,email,username});
      if isempty(contact);
        method = '';
        continue;
      end
      if isempty(contact{2}) && isempty(contact{3})
        uiwait(errordlg('You must provide either an e-mail address or username so Eigevector Research can contact you! Please try again or use manual submission.','Submission Failed'));
        method = '';
        continue;
      end
      
      try
        prefs = getpref('PLS_Toolbox');
        prefs.evrireporterror.name = contact{1};
        prefs.evrireporterror.email = contact{2};
        prefs.evrireporterror.username = contact{3};
        setpref('PLS_Toolbox','evrireporterror',prefs.evrireporterror)
      catch
        %error while saving contact info? just skip it
      end
      
      %get info on this error
      description = inputdlg({'Please describe what you were doing when this happened and any other description which might help diagnose the problem:'},'What Happened?',10,{''});
      if isempty(description)
        description = {''};
      end
      description = description{1};  %extract from cell
      
      try
        %add user info to top of message
        safeinfo = [sprintf('Name: %s\nEmail: %s\nUsername: %s\nAdditional Information:\n\n',contact{:})];
        for j=1:size(description,1)
          safeinfo = [safeinfo sprintf('%s\n',deblank(description(j,:)))];
        end
        safeinfo = [safeinfo sprintf('\n\n') info];

        %convert bad characters in info and convert to post format
        toconvert = char(['%=''"+-&:\']);
        for j=1:length(toconvert);
          safeinfo = strrep(safeinfo,toconvert(j),['%' dec2hex(toconvert(j))]);
        end
        safeinfo = strrep(safeinfo,' ','+');
        safeinfo = sprintf('info=%s',safeinfo);

        wbh = [];
        try
          wbh = waitbar(.5,'Sending Error Information...');
        catch
        end
        %send to EVRI
        res = sendmsg('software.eigenvector.com', 80, postheader(safeinfo));
        
      catch
        res = '';
      end
      
      if ~isempty(wbh) & ishandle(wbh)
        delete(wbh);
      end

      if isempty(findstr(res,'submission accepted'))
        uiwait(errordlg('Message could not be submitted automatically. Please try again or use manual submission.','Submission Failed'));
        method = '';
      else
        %message was submitted - check for new releases
        
        if isempty(getappdata(0,'evrireporterr_novercheck'));
          try
            notcurrent = (evriupdate(2)==1);
          catch
            notcurrent = false;
          end
          setappdata(0,'evrireporterr_novercheck',1)
        else
          %already checked during this session - don't check again
          notcurrent = false;
        end
        
        if ~notcurrent
          %got the current version or we were not able to check
          uiwait(msgbox('Request has been submitted. Eigenvector Research will be in contact with you by e-mail regarding this submission.','Accepted','help'))
        else
          %NOT the current version.
          resp = questdlg({'Request has been submitted. Eigenvector Research will be in contact with you by e-mail regarding this submission.',' ','However, we have detected that your software is out of date. Would you like to check for available updates now to see if this resolves your problem?'},'Version Not Current','Check for Updates','Skip','Check for Updates');
          if strcmpi(resp,'Check for Updates')            
            evriupdate(3);
          end
        end
      end
      
  end
end

%------------------------------------------------------
function header = postheader(info)
%create header for message

header = {'POST /toolbox/download/submiterror.php HTTP/1.1'
  'Host: software.eigenvector.com'
  'User-Agent: Matlab'
  sprintf('Content-Length: %i',length(info))
  'Content-Type: application/x-www-form-urlencoded'
  ''
  info};


%------------------------------------------------------
function [rcv] = sendmsg(srv, port, msg)
%SENDMSG sends message via java socket.
%  Function will wait one second and then see if a message was sent back
%  and put resutls into rcv.
%
% INPUTS:
%   srv  - [string] either URL name or IP address.
%   port - [double] port number to connect to on server.
%   msg  - [string] message to send.
% OUTPUT:
%   rcv  - [string] response from server.
%
%I/O: rcv = sendmsg(srv, port, msg)

%Copyright Eigenvector Research, Inc. 2002-2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

import java.io.*;
import java.net.*;

if ~iscell(msg);
  msg = {msg};
end

try
  starttime = now;
  clientSocket = java.net.Socket(srv,port);
  iStream_client = clientSocket.getInputStream;
  iReader_client = java.io.InputStreamReader(iStream_client);

  outStream_client = clientSocket.getOutputStream;

  clientOut = java.io.PrintWriter(outStream_client, true);
  clientIn = java.io.BufferedReader(iReader_client);
  clientOut.println(java.lang.String(sprintf('%s\n',msg{:})));

  while ~clientIn.ready
    if (now-starttime)>15/60/60/24;
      error('No response from server')
    end
  end

  rcv = {};
  while clientIn.ready
    rcv{end+1} = char(readLine(clientIn));
  end
  if length(rcv)>1;
    rcv = sprintf('%s\n',rcv{:});
  else
    rcv = rcv{1};
  end
  
catch
  rcv = '';
end

try
  clientSocket.close;
end
try  
  iStream_client.close;
end
try
  outStream_client.close;
end
try
  clientIn.close;
end
try
  clientOut.close;
end
