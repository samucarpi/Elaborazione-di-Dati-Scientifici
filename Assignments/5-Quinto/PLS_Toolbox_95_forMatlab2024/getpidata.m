function [pidso, warnlog] = getpidata(taglist,startdate,enddate,options)
%GETPIDATA Uses the current PI connection to construct a DSO from 'taglist'.
%  This function requires the PI SDK (software developer kit) be installed.
%  If only taglist is submitted and or date inputs are empty then a
%  "snapshot" of the data is returned. Date inputs can be any PI supported
%  value.
%
%  INPUTS:
%     taglist = Cell array of strings containing tags to query or excel
%               file with one column of tag names.
%   startdate = Start date/time to query or excel file with 2 columns
%               (start and end dates). Each row will indicate a unique
%               start/end and will be appended according to appenddir
%               option setting.
%    endtdate = End date/time to query.
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%       tagsearch: [ {'off'} | 'on' ] Show PI tag search gui.
%     interpolate: [ {'interval'} | 'total' ] Governs interpolate settings,
%                  'interval' is the time between data points in seconds.
%                  'total' is the total number of points to retrieve.
%  interpolateval: {60} Default is interval if 60 seconds.
%         timeout: {10} Seconds to wait for server to return for each column of data.
%        savefile: {''} File name to save output to.
%  diplaywarnings: [ 'off' | {'on'} ] Show warning at command line after calculation.
%  timecorrection: {0} Time in seconds to be added when converting PI
%                  timestamps to Matlab time.
%         rawdata: [ {'off'} | 'on' ] Retrieve PI "compressed data" (actual
%                  Archive events) for given taglist. This will not use any
%                  interpolation and because data will likely be of
%                  different length, the result will be returned in a
%                  structure, not a dso.
%  userservertime: [ 'off' | {'on'} | local] Governs how to convert Matlab
%                  timestamps (axisscale{1,1}). 'on' creates timestamps
%                  with timezone settings (e.g., daylight savings rules)
%                  applied. If set to 'off' then server time is used with
%                  no timezone rules applied. If set to 'local', local
%                  timezone is applied. 
%       appenddir: [ {'mode 1'} | 'mode 3'] Mode to append to when using 
%                                           multiple time range inputs.
%     lengthmatch: [ 'min' | {'max'} | 'stretch' | 'fixed' ] Defines how
%                   slabs should be concatenated (used only when appenddir
%                   = 'mode 3'):
%                     'min' truncates all slabs to the shortest slab length.
%                     'max' adds NaN's to the end of each slab to match the
%                            longest slab length.
%                     'stretch' interpolates all slabs to match the length of
%                            the FIRST read slab.
%                     'fixed' either truncates or infills all slabs to
%                            match a specific length specified in
%                            targetlength, below.
%                   All modes can also be adapted to match a minimum or
%                   maximum length using the "targetlength" option, below.
%    targetlength: [] Optional target length (used only when appenddir
%                   = 'mode 3'). A non-empty value will be used
%                   in place of the default length defined by the
%                   lengthmatch option. If lengthmatch is 'min', this
%                   option defines the MAXIMUM length slab to allow. If
%                   lengthmatch is 'max', this option defines the MINIMUM
%                   length slab to allow. If lengthmatch is 'stretch', this
%                   option defines the target length. If lengthmatch is
%                   'fixed' then this option defines the target length.
%  OUTPUT:
%     pidso = dataset object of queried values or (if rawdata = 'on') a
%             1xn structure array with the following fields:
%               .tagname
%               .time 
%               .value
%            
%             With DSO returned queries, timestamps are returned in the
%             .axisscale field. Matlab adjusted timestamps are reported in
%             .axisscale{1,1}. The original UTC timestamps are reported in
%             .axisscale{1,2}.
%
%I/O: [pidso, warnlog] = getpidata(taglist,startdate,enddate,options)
%I/O: dso = getpidata({'SINUSOID' 'BA:PHASE.1' 'BA:TEMP.1'},'y-2d','t',options);
%I/O: dso = getpidata('tagnames.xls','y-2d','t',options);
%I/O: dso = getpidata('tagnames.xls','dates.xls',options);
%
%See also: PICONNECTGUI

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0; taglist = 'io'; end

if ischar(taglist)&& ismember(taglist,evriio([],'validtopics'));
  options = [];
  options.tagsearch         = 'off';
  options.interpolate       = 'interval';
  %options.server            = '';
  options.interpolateval    = 60;
  options.timeout           = 10;
  options.savefile          = '';
  options.diplaywarnings    = 'on';
  options.timecorrection    = 0;
  options.rawdata           = 'off';
  options.userservertime    = 'on';
  options.appenddir         = 'mode 1';
  options.lengthmatch       = 'max';
  options.targetlength      = [];
  options.definitions   = @optiondefs;
  
  if nargout==0;
    evriio(mfilename,taglist,options);
  else
    pidso = evriio(mfilename,taglist,options);
  end
  return;
end

%Check inputs.
if nargin < 2;
  startdate = '';
end

%Flag for date looping behavior.
loopdate = 0;

%Deal with xlsfiles.
if ischar(taglist)&&~isempty(strfind(taglist,'.xls'))
  try
    [junk temp] = xlsread(taglist);
  catch
    error(['Error reading XLS file: ' taglist '. ' lasterr]);
  end
  taglist = temp;
end

if ~isempty(startdate)&&~isempty(strfind(startdate,'.xls'))
  try
    [junk temp] = xlsread(startdate);
  catch
    error(['Error reading XLS file: ' startdate '. ' lasterr]);
  end
  loopdate = 1;
  startdate = temp;
end

%Default enddate is current time.
if nargin < 3
  enddate = datestr(now);
end

%If called with xls date file then options can be passed as third input.
%getpidata('tagnames.xls','dates.xls',options)
if isstruct(enddate)
  options = enddate;
elseif nargin < 4
  options  = getpidata('options');
end

options = reconopts(options,getpidata('options'));

%Use snapshot to get current value of tag if no start date given.
snapshot = 0;
if isempty(startdate)
  snapshot = 1;
end

%Try a server connect. Function will error out here if SDK is not
%installed.
try
  mySDK = actxserver('PISDK.PISDK');
  myServer = mySDK.Servers.DefaultServer;
catch
  error(['Error trying to create PI Server connection. Make sure PISDK (part of OSI Data Access Pack) is installed.' lasterr]);
end

%Query for tags.
if isempty(taglist) || strcmp(options.tagsearch,'on')
  %Get point list from SDK object. This brings up a activex gui.
  myAppObject = actxserver('PISDKDlg.ApplicationObject');
  myPointList = myAppObject.TagSearch.Show;
  %NOTE: InterpolatedValues method not yet supported for List object.
  if myPointList.Count == 0
    %User cancel.
    pidso = [];
    return
  end
  %Create cell array of strings from list.
  taglist = '';
  for i = 1:myPointList.Count
    taglist = [taglist; {myPointList.Item(i).Name}];
  end
  try
    %Delete object.
    myAppObject.delete
  end
end

%Recursive call for date looping.
pidso = [];
warnlog = '';

if loopdate
  loopwb = waitbar(0,'Looping through dates... (Close to Cancel)');
  targetlength = options.targetlength;%Pull varglen into its own variable.

  for i = 1:size(startdate,1)
    if ishandle(loopwb)
      waitbar(i/size(startdate,1),loopwb)
    else
      pidso = [];
      return
    end
    [tempdso wlog] = getpidata(taglist,startdate{i,1},startdate{i,2},options);
    if strcmp(options.appenddir,'mode 3')
      %concatenate slabs. Input option "lengthmatch" offers three modes:
      %    'min' shorten all slabs to the SHORTEST length
      %    'max' lengthen all slabs (with NaN's) to the LONGEST slab length
      %    'stretch' interpolates all slabs to match the first slab's
      %       length
      %    'fixed' lengthens (with NaN) or truncates each slab to match a
      %       speciifc length specified in targetlength
      
      if i==1 & isempty(targetlength);
        pidso = tempdso;  %first one is easy
        targetlength = size(tempdso,1);  %note that length
      else
        %additional slabs (or when targetlength is supplied in options)
        switch options.lengthmatch
          case 'fixed'
            if size(tempdso,1)>targetlength
              %shorten this slab to match targetlength
              tempdso = nindex(tempdso,1:targetlength,1);
            elseif size(tempdso,1)<targetlength
              %lengthen this slab to match targetlength
              sz = size(tempdso);
              tempdso = [tempdso;ones(targetlength-sz(1),sz(2))*nan];
            end
          case 'min'
            if size(tempdso,1)<targetlength
              %shorten all other slabs to the shortest slab length
              targetlength = size(tempdso,1);
              if ~isempty(pidso)
                pidso = nindex(pidso,1:targetlength,1);
              end
            elseif size(tempdso,1)>targetlength
              %shorten this slab to match all others
              tempdso = nindex(tempdso,1:targetlength,1);
            end
          case 'max'
            if size(tempdso,1)>targetlength
              %lengthen all other slabs to match longest slab length
              targetlength = size(tempdso,1);
              if ~isempty(pidso)
                sz = size(pidso);
                if length(sz)==2; sz(3) = 1; end
                pidso = [pidso;ones(targetlength-sz(1),sz(2),sz(3))*nan];
              end
            elseif size(tempdso,1)<targetlength
              %lengthen this slab to match targetlength
              sz = size(tempdso);
              tempdso = [tempdso;ones(targetlength-sz(1),sz(2))*nan];
            end
          case 'stretch'
            %adjust tempdso length to match first slab's length
            tempdso = interp1(linspace(0,1,size(tempdso,1)),tempdso,linspace(0,1,targetlength));
        end

        if isempty(pidso)
          pidso = tempdso;
        else
          try
            pidso = cat(3,pidso,tempdso);
          catch
            if ishandle(loopwb)
              close(loopwb)
            end
            error('Cannot combine slabs of data into a consistent 3-way matrix')
          end
        end
      end


    else
      pidso = [pidso;tempdso];
    end
    warnlog = [warnlog;wlog];
  end

  if ishandle(loopwb)
    close(loopwb)
  end
  
  %Only display last warning, should be same for all dates.
  if length(warnlog)>3*size(startdate,1) && strcmp(options.diplaywarnings,'on')
    disp(warnlog)
  end

  return
end

%Initialize data variable.
newdat = [];

%Initialize var labels.
varlabels = '';

%Flag for dealing with timestamps. Only need to deal with first time
%through, all other times will be same.
timeconvert = 0;

%Get Points collection from server. The List object isn't fully supported
%so use Points collection for now. This means only able to get points from
%a single server.
myPoints = myServer.PIPoints;

t1 = actxserver('PITimeServer.PITime');
t1.localDate = startdate;

t2 = actxserver('PITimeServer.PITime');
t2.localDate = enddate;

%Need a PIAsynchStatus object to input to interpolate values. It will error
%otherwise.
asyncObj = actxserver('PISDKCommon.PIAsynchStatus');
waitbarhandle = waitbar(0,'Querying Data... (Close to Cancel)');

warnlog = {'WARNING LOG:';'';''}; %Log of warning messages received per tag.

%Loop through and grab each column of data.
for i = 1:length(taglist)
  if ishandle(waitbarhandle)
    waitbar(i/length(taglist),waitbarhandle)
  else
    pidso = [];
    return
  end

  %Use try/catch here in case name doesn't return value.
  try
    if snapshot
      myInterp = myPoints.Item(taglist{i}).Data.Snapshot;
    elseif strcmp(options.rawdata,'on')
      %Get raw data from server. Use '3' for 3rd input (BoundaryType), it
      %is the defualt "auto".
      myInterp = myPoints.Item(taglist{i}).Data.RecordedValues(...
        startdate,enddate,3,'',0,asyncObj);
    else
      if strcmp(options.interpolate,'interval')
        myInterp = myPoints.Item(taglist{i}).Data.InterpolatedValues2(...
          startdate,enddate,options.interpolateval,'',0,asyncObj);
      elseif strcmp(options.interpolate,'total')
        myInterp = myPoints.Item(taglist{i}).Data.InterpolatedValues(...
          startdate,enddate,options.interpolateval,'',0,asyncObj);
      end
    end

    %Wait for interp to come back. There can be delay in creating the
    %object so need to allow time or error will occur later.
    tmr = 0;
    while ~snapshot && myInterp.Count == 0
      if tmr>options.timeout
        warnlog = [warnlog;{['TAG [' taglist{i} ']']}];
        warnlog = [warnlog;{'**Server connect time out. If querying a large data set, '}];
        warnlog = [warnlog;{'try increasing options.timeout in getpidata.m.'}];
        break
      end
      tmr = tmr+1;
      pause(1);
    end

    %Get Point type so can figure out what datatype is being returned.
    datatype = myPoints.Item(taglist{i}).PointType;

    %Get data.
    if snapshot
      %Returns single value so put into cell so works later.
      idata = {myInterp.value};
    else
      %Returns cell array.
      %[idata itimes] = myInterp.GetValueArrays;
      if ~timeconvert
        [idata, itimes] = myInterp.GetValueArrays;
        itimes = itimes';
        if strcmp(options.rawdata,'off')
          %Not using raw data so no need to keep retrieving timestamps.
          timeconvert = 1;
        end
      else
        idata = myInterp.GetValueArrays;
      end
    end

    if ~isempty(strfind(datatype,'Float')) || ~isempty(strfind(datatype,'Int'))
      %Get numeric array. Replace non numeric values with NaN. This can
      %happen for values returned during server shutdown ect... a PI
      %DigitalState object is returned.
      numindx = cellfun(@isnumeric,idata);
      nonpoints = idata(~numindx); %Get nonnumeric points so a warning can be issued.
      idata(~numindx) = {NaN}; %Replace nonnumeric with NaN.
      idata = double([idata{:}]');

      msgs = getnanstate(nonpoints);
      if ~isempty(msgs)
        %Add log message.
        warnlog = [warnlog;{['TAG [' taglist{i} ']']}];
        warnlog = [warnlog;{'**Replace with NaN warning for following PI States:'}];
        warnlog = [warnlog;{['  -' msgs{:}]}];
        warnlog = [warnlog; {''}]; %Add seperator.
      end

    elseif ~isempty(strfind(datatype,'Digital'))
      idata = cellfun(@getstate,idata);
    elseif ~isempty(strfind(datatype,'string'))
      %Placeholder for future functionality.

    elseif ~isempty(strfind(datatype,'Timestamp'))
      %Placeholder for future functionality.
    end
    
    if strcmp(options.rawdata,'on')
      if ~isempty(idata)
        %Construct raw data structure.
        newdat(i).tagname  = taglist{i};
        newdat(i).time  = tconvert(itimes,options,myServer);
        newdat(i).value = idata;
      end
    else
      newdat = [newdat idata];
      varlabels = [varlabels taglist(i)];
    end
  catch
    warnlog = [warnlog; {['**Unable to retrieve data for tag: ' taglist{i} '. Continuing query.']}];
    warnlog = [warnlog; {lasterr}];
    warnlog = [warnlog; {''}]; %Add seperator.
  end
end

if ishandle(waitbarhandle)
  close(waitbarhandle)
end

if isempty(newdat)
  %Either no data or errors so just return.
  pidso = [];
  if length(warnlog)>3 && strcmp(options.diplaywarnings,'on')
    disp(warnlog)
  end
  return
end

if strcmp(options.rawdata,'on')
  %Structure.
  pidso = newdat;
else
  %DSO.
  pidso = dataset(newdat);
  pidso.label{2,1} = varlabels;
end

%Add time values to axisscale.
if ~snapshot && strcmp(options.rawdata,'off')
  %Convert time to Matlab format.
  nitimes = tconvert(itimes,options,myServer);

  %Add to DSO.
  pidso.axisscale{1,1} = nitimes; %Add offset time into first axisscale.
  pidso.axisscale{1,2} = itimes; %Add original times into second scale.
end

if length(warnlog)>3 && strcmp(options.diplaywarnings,'on')
  disp(warnlog)
end

%Save option behavior.
if ~isempty(options.savefile)
  save(options.savefile,'pidso');
  if nargout == 0
    clear('pidso');
  end
end

try
  %Delete object.
  mySDK.delete
end

try
  %Delete object.
  asyncObj.delete
end

%--------------------------------------------------------------------
function state = getstate(obj)
%Return digital state of object.
state = get(obj,'Code');

%--------------------------------------------------------------------
function statecell = getnanstate(cellin)
%Input is cell array of objects.
%Output is cell array of strings with unique name of state.
statecell = '';
if isempty(cellin)
  return
end

for i = 1:length(cellin)
  statecell = [statecell; {get(cellin{i},'Name')}];
end

statecell = unique(statecell);

%--------------------------------------------------------------------
function ntime = tconvert(otime,options,myServer)
%Adjust time vector to Matlab time. PI uses Unix epoc (01-Jan-70).

%Get offset for Matlab time (in days).
timeoffset = datenum('01-Jan-70');

%Convert itime from seconds to days.
ntime = (otime+options.timecorrection)/(24*60*60);

%Calculate UTC offset. This happens with conversion of UTC time during
%interpolation. Need to use PITime obj, get the current time string (clock
%time) and the current time in UTC seconds and see what diff is. Should be
%in integer hours.
if strcmp(options.userservertime,'on')
  %Current server time with TZ rules applied.
  t1 = actxserver('PITimeServer.DynamicTime');
  t1.SetClockSource(myServer);
  set(t1,'TimeZoneInfo', myServer.PITimeZoneInfo);
elseif strcmp(options.userservertime,'off')
  %Current server time and not TZ rules applied.
  t1 = actxserver('PITimeServer.DynamicTime');
  t1.SetClockSource(myServer);
else
  %Change to current local system time.
  t1 = actxserver('PITimeServer.PITime');
  t1.SetToCurrent;
end

t2 = datevec(t1.LocalDate);
t3 = t1.UTCSeconds;
t3 = t3/(24*60*60) + timeoffset; %Correct to matlab time so can use datevec.
t3 = datevec(t3);

e = etime(t2,t3); %Time diff in seconds.
tdiff = round(e/(60*60))/24; %Time diff in days.

try
  %Delete object.
  t1.delete;
end

%Add offset.
ntime = ntime+timeoffset+tdiff;

%--------------------------
function out = optiondefs()

defs = {
  
%name                    tab              datatype        valid                            userlevel       description
'tagsearch'             'Setup'          'select'        {'on' 'off'}                     'novice'        'Show PI tag search gui.';
'interpolate'           'Setup'          'select'        {'interval' 'total'}             'novice'        'Governs interpolate settings, ''interval'' is the time between data points in seconds, ''total'' is the total number of points to retrieve.';  
'interpolateval'        'Setup'          'double'        'float'                          'novice'        'Default is interval if 60 seconds/values depending on ''interpolate''.';
'timeout'               'Time'           'double'        'int(0:inf)'                     'novice'        'Seconds to wait for server to return for each column of data.';
'savefile'              'Return'         'char'          {''}                             'novice'        'File name to save output to.';
'diplaywarnings'        'Return'         'select'        {'on' 'off'}                     'novice'        'Show warning at command line after calculation.';
'timecorrection'        'Time'           'double'        'int(0:inf)'                     'novice'        'Time in seconds to be added when converting PI timestamps to Matlab time.';
'rawdata'               'Return'         'select'        {'on' 'off'}                     'novice'        'Retrieve PI "compressed data" (actual Archive events) for given taglist. This will not use any interpolation and because data will likely be of different length, the result will be returned in a structure, not a dso.';
'userservertime'        'Time'           'select'        {'on' 'off' 'local'}             'novice'        'Governs how to convert Matlab timestamps (axisscale{1,1}). ''on'' creates timestamps with timezone settings (e.g., daylight savings rules) applied. If set to ''off'' then server time is used with no timezone rules applied. If set to ''local'', local timezone is applied.';
'appenddir'             'Return'         'select'        {'mode 1' 'mode 3'}              'novice'        'Mode to append to when using multiple time range inputs.';
'lengthmatch'           'Return'         'select'        {'min' 'max' 'stretch' 'fixed'}  'novice'        'Defines how slabs should be concatenated when using appenddir ''mode3''. ''min'' truncates all slabs to the shortest slab length. ''max'' adds NaN''s to the end of each slab to match the longest slab length. ''stretch'' interpolates all slabs to match the length of the FIRST read slab. ''fixed'' either truncates or infills all slabs to match a specific length specified in targetlength below. All modes can also be adapted to match a min/max length using the "targetlength" option (see below).';
'targetlength'          'Return'         'double'        'int(0:inf)'                     'novice'        'Optional target length to use when appending with appenddir = ''mode3''. A non-empty value will be used in place of the default length defined by the lengthmatch option. If lengthmatch is ''min'', this option defines the MAXIMUM length slab to allow. If lengthmatch is ''max'', this option defines the MINIMUM length slab to allow. If lengthmatch is ''stretch'', this option defines the target length. If lengthmatch is ''fixed'' then this option defines the target length.';

};

out = makesubops(defs);
