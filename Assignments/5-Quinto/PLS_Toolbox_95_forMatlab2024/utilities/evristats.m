function out = evristats(mfile,action)
%EVRISTATS Accumulates and sends statistics on function usage to EVRI.
% Collects usage information for PLS_Toolbox functions and periodically
% sends collected stats to the Eigenvector Research server. This
% information is anonymous and voluntary. To disable this feature, use:
%   setplspref('evristats','accumulate',0)
%
%I/O: evristats(mfile,action)
%I/O: out = evristats;

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

persistent stats lastsend accumulate accumtime session prstrnd

if nargin==0
  evristatsgui
  accumulate = getplspref('evristats','accumulate');  %reload choice
  return
end

if nargout>0
  out = [];
end

%---------------------------------------------------------------
%determine if we have permssion from user to collect statistics
if isempty(accumulate)
  %if empty, first time this session we've been called
  %check if the user has been asked
  accumulate = getplspref('evristats','accumulate');
  % % %HARD-CODED Exclusion of this code!!
  % % %because of security concerns we are temporarily disabling even ASKING
  % % %if the user wants to share info. Users can still manually choose to
  % % %share (by running the evristats function or choosing the menu option
  % % %themselves) but we will NOT automatically ask!
  %   if ~isempty(accumulate) & ~accumulate
  %     return;  %accumulate is 0? don't even ask (whether or not they have been)
  %   end
  %   asked = getplspref('evristats','asked');
  %   if isempty(asked) | asked==0
  %     setplspref('evristats','asked',-1); %flag to check if setplspref works
  %     accumulate = 0; %do NOT collect right now, wait till next session
  %     return
  %   end
  %   if asked==-1
  %     %user hasn't been asked, but it is apparent that plspref is working, OK
  %     %to ask (if plspref isn't working, we NEVER want to ask because we will
  %     %annoy the hell out of the user asking each time if they want to
  %     %participate)
  %     if rand(1)<.2
  %       %for a random selection of users, ask if they will participate
  %       evristatsgui
  %       accumulate = getplspref('evristats','accumulate');  %reload choice
  %     else
  %       %the rest of the time, leave the user alone
  %       accumulate = 0;
  %       return;
  %     end
  %   end
  if isempty(accumulate)
    %still empty? default if nothing set
    accumulate = 0;
  end
end
if ~accumulate
  %no permission? exit now
  return;
end

%amount of time to accumulate over
accumtime = getplspref('evristats','accumtime');
if isempty(accumtime)
  %default time to accumulate over
  accumtime = 15;
end

%date of last send
if isempty(lastsend)
  lastsend = now;
end

%initialize stats array with cumulative count and other session info
if isempty(stats)
  stats.cumulative = 0;  
end

if nargin>0
  %inputs? add information to stats structure
  if nargin<2 
    action = '';
  end
  if ~isempty(mfile)
    %got an m-file name, add to the count for the given mfile+action
    if ~isfield(stats,mfile)
      if ~isempty(action) 
        stats.(mfile).(action) = 1;
      else
        stats.(mfile) = 1;
      end
    else
      %got the mfile already
      if isnumeric(stats.(mfile)) & isempty(action)
        %no fields AND action is empty
        stats.(mfile) = stats.(mfile)+1;
      else
        %fields OR action is not empty
        if isnumeric(stats.(mfile))
          %take old stats and put into "unknown" category
          stats.(mfile) = struct('unknown',stats.(mfile));
        end
        if ~isfield(stats.(mfile),action)
          %add first instance of this action
          stats.(mfile).(action) = 1;
        else
          %increase count for this action
          stats.(mfile).(action) = stats.(mfile).(action)+1;
        end
      end
    end
    %add to cumulative too
    stats.cumulative = stats.cumulative+1;
  end
else
  %no inputs? return output of stats
  out = stats;
end

%check if we should send the accumulated statistics to the server
if (now-lastsend)*60*24>accumtime & stats.cumulative>10;
  
  %grab/generate prstrnd
  if isempty(prstrnd)
    prstrnd = getplspref('evristats','prstrnd');
    if isempty(prstrnd)
      prstrnd = randcode(25);
      setplspref('evristats','prstrnd',prstrnd);
    end
  end
  
  %session code (changes on each startup of Matlab)
  if isempty(session)
    session = getappdata(0,'evristats_session');
    if isempty(session)
      session = randcode(25);
      setappdata(0,'evristats_session',session);
    end
  end
  
  lastsend = now;  %always reset "last send" timestamp
  try
    info = makesafe(encodejson(stats));

    %gather user information for submission
    [v,p] = evrirelease;
    lic   = lower(pls('test'));
    syst = [];
    syst.product = p;           %product name
    syst.version = v;           %product version
    syst.isdemo  = ~isempty(strfind(lic,'expires')) & isempty(strfind(lic,'floating'));  %boolean true = is a demo
    syst.sessionrnd = session;  %session-persistent random string
    syst.prstrnd    = prstrnd;  %install-persistent random string
    syst         = makesafe(encodejson(syst));

    safeinfo = sprintf('info=%s&system=%s',info,syst);
    
    res = sendmsg('software.eigenvector.com', 80, postheader(safeinfo));
    
  catch
    %error during submission?
    accumulate = 0;  %turn OFF accumulation and submission for this session
    res = '';
  end
  
  if ~isempty(strfind(res,'submission accepted'))
    %if submission was accepted, clear stats
    stats = [];
  end
  
end

%---------------------------------------------------
function   out = randcode(num)

base = ['A':'Z' '0':'9'];
out  = base(floor(rand(1,num)*length(base))+1);

%---------------------------------------------------
function safeinfo = makesafe(safeinfo)

toconvert = char(['%=''"+-&:\']);
for j=1:length(toconvert);
  safeinfo = strrep(safeinfo,toconvert(j),['%' dec2hex(toconvert(j))]);
end
safeinfo = strrep(safeinfo,' ','+');

%------------------------------------------------------
function header = postheader(info)
%create header for message

header = {'POST /toolbox/download/submitstats.php HTTP/1.1'
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

%Copyright Eigenvector Research, Inc. 2002-2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if ~iscell(msg);
  msg = {msg};
end

timeout = 1000;  %miliseconds before no server response is considered fatal

try
  starttime = now;
  clientSocket = java.net.Socket;
  clientSocket.connect(java.net.InetSocketAddress(srv, port), timeout) 
  iStream_client = clientSocket.getInputStream;
  iReader_client = java.io.InputStreamReader(iStream_client);

  outStream_client = clientSocket.getOutputStream;

  clientOut = java.io.PrintWriter(outStream_client, true);
  clientIn = java.io.BufferedReader(iReader_client);
  clientOut.println(java.lang.String(sprintf('%s\n',msg{:})));

  while ~clientIn.ready
    if (now-starttime)>3/60/60/24;
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

%------------------------------------------------------------
function  str = encodejson(data)
%ENCODEJSON Converts a generic data object to JSON-encoded object.
% Converts a standard Matlab variable (var) into a human-readable JSON
% format. The optional second input ('filename.js') gives the name for the
% output file (if omitted, the JSON is only returned in the output
% variable). For more information on the format, see http://json.org/ 
%
% Example:
%     z.a = 1;
%     z.b = { 'this' ; 'that' };
%     z.c.sub1 = 'one field';
%     z.c.sub2 = 'second field';
%     out = encodejson(z)
%   Returns...
%     {
%      "a":1,
%      "b":["this","that"],
%      "c":{"sub1":"one field","sub2":"second field"}
%     }
%
%I/O: xml = encodejson(var)
%I/O: xml = encodejson(var,'outputfile.js')
%
%See also: ENCODE, ENCODEXML

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

try
  str = '';
  sz = size(data);
  
  if isnumeric(data) | islogical(data)
    %numeric arrays
    if isempty(data)
      str = ['[ ]'];
    elseif length(sz)>2 | sum(sz>1)>1
      %anything other than a vector, do arrayloop
      str = arrayloop(data);
    else
      if islogical(data)
        names = {'false' 'true'};
        str = sprintf('%s,',names{data+1});
      else
        str = sprintf('%0.12g,',data);
      end
      str = str(1:end-1);
      str = regexprep(str,'NaN','null');
      str = regexprep(str,'-Inf','null');
      str = regexprep(str,'Inf','null');
      if any(sz>1);
        str = ['[' str ']'];
      end
    end
    
  else
    
    switch class(data)
      case 'struct'
        if any(sz>1)
          str = arrayloop(data);
        elseif isempty(data);
          str = {'{}'};
        else
          str = {'{'};
          for f = fieldnames(data)';
            str{end+1} = ['"' f{:} '":' encodejson(data.(f{:})) ];
            str{end+1} = ',';
          end
          str = str(1:end-1);
          str{end+1} = '}';
        end
        
      case 'cell'
        if any(sz>1)
          str = arrayloop(data);
        elseif ~any(sz==0)
          str = ['[' encodejson(data{1}) ']'];
        else
          str = ['[ ]'];
        end
        
      case 'char'
        if sz(1)>1
          data = str2cell(data,1);
          data = sprintf('%s\n',data{:}); %convert to string representation of array
        end
        clean = data;
        clean = regexprep(clean,'\\','\\\\');
        clean = regexprep(clean,'\r','\\r');
        clean = regexprep(clean,'\n','\\n');
        clean = regexprep(clean,'\t','\\t');
        clean = regexprep(clean,'"','\\"');
        clean = regexprep(clean,'/','\\/');
        str = ['"' clean '"'];
        
      case 'dataset'
        str = encodejson(struct(data));
        
      otherwise
        str = '"Unencodable Object"';
        
    end
  end
  
  if iscell(str); str = sprintf('%s',str{:}); end

catch
  str = '"error encoding JSON"';
end

%-------------------------------------------
function str = arrayloop(data)
%generic array indexer

str = {};
sz = size(data);
k = length(sz);
if isnumeric(data) | (k==2 & sz(2)==1)
  it = cell(1,k-1);
  sz = sz(1:end-1);  %drop last index for numerics
  addit = ':';
else
  it = cell(1,k);
  addit = {};
end

if length(sz)+isnumeric(data)<=2
  nparens = sum(sz>1);
else
  nparens = length(sz);
end
[it{:}] = deal(1);
t = length(it);
str{end+1} = repmat('[',1,nparens);
while all([it{:}]<=sz) & t>0
  item = squeeze(nindex(data,[it addit],1:k));
  switch class(item)
    case 'cell'
      str{end+1} = encodejson(item{1});
    otherwise
      str{end+1} = encodejson(item);
  end
  %increment indexing for next level up
  t = length(it);
  it{t} = it{t}+1;
  if it{t}>sz(t);
    closed = 0;
    while it{t}>sz(t)
      [it{t:end}] = deal(1);
      t = t-1;
      closed = closed+1;
      if t<1; break; end %done with incrementing
      it{t} = it{t}+1;
    end
    str{end+1} = repmat(']',1,closed);
    str{end+1} = [',' repmat('[',1,closed)];
  else
    str{end+1} = ',';
  end
end

str(end) = [];
if nparens==1;
  str{end} = ']';
end
