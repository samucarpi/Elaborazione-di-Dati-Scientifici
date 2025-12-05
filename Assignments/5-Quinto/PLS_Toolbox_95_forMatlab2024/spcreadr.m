function [out,xaxis,auditlog,description]=spcreadr(filename,subs,wlrange,options)
%SPCREADR Reads Galactic SPC files.
%  INPUT:
%   filename = a text string with the name of a SPC file or
%              a cell of strings of SPC filenames.
%     If (filename) is omitted or an empty cell {}, the user will be
%     prompted to select a folder and then one or more SPC files in the
%     identified folder. If (filename) is a blank string, the user will be
%     prompted to select a file. Importer will also load DHB files.
%
% OPTIONAL INPUTS:
%      subs = a scalar or vector indicating the sub-files to read
%             {default = all subfiles}.
%   wlrange = a two element vector of the wavelength range to return
%             (endpoints are  inclusive)  {default = whole spectrum}.
%   options = structure array with the following fields:
%          waitbar : [ 'off' | 'on' |{'auto'}] governs the display of a
%                     waitbar when loading multiple files. If 'auto',
%                     waitbar is displayed for larger sets of files only.
%     nonmatching : [ 'none' | {'matchvars'} | 'intersect' |'interpolate' ] defines
%                     action taken when the x-axes of two spectra being 
%                     read do not match. The options are:
%                     'matchvars' uses MATCHVARS to merge imported spectra
%                     when the spectral x-axes differ.
%                     'intersect' returns only the points where the 
%                       spectral x-axis values overlap exactly.
%                     'interpolate' returns the overlapping portions with 
%                       linear interpolation to match spectral points 
%                       exactly. As no extrapolation will be done, the 
%                       returned spectra will cover the smallest common 
%                       spectral range. 
%                     'none' ignores x-axis differences as long as the 
%                       number of data points is the same in all spectra.
%    textauditlog : [{'no'}| 'yes'] governs output of audit log contents.
%                   When 'yes', the auditlog is returned as a raw text
%                   array. Otherwise, the auditlog is returned as a
%                   structure with field names taken from  auditlog keys.
%     multiselect : [ 'off' | {'on'} ] governs whether file selection
%                   dialog should allow multiple files to be selected
%                   and imported. Setting to 'off' will restrict user to
%                   importing only one file at a time.
%      endianness : Empty uses default (aka native) for PC and Linux with
%                   Mac being forced little endian (long standing default).
%                   Otherwise, single character string n/b/l/s/a
%                   (native/big/little/big 64/little 64).
%
%  Outputs can be in two forms.
%  1) With a single output, the data is returned as a DataSet object.
%  2) With more than one output, the outputs are a matrix of intensities
%    (data), the corresponding wavelength vector (wl), the text audit
%    log from the file (auditlog), and the description of the file from the
%    comment field (description).
%
% Additional Audit Log Information:
%   If the SPC file audit log contains an "author" or "name" key (as
%   key=value entry), the corresponding value will be copied into the
%   author or name DataSet object field.
%
% Image Data:
%   If the audit log contains a key "imagesize" as a key=value pair, the
%   data is assumed to be an image and an image DataSet is created with the
%   given image size. Image size should be specified as a comma-separated
%   list of dimensions in the image plane. The number of spectra in the
%   file must match the product of image sizes.
%     imagesize = 150,210
%   Images are normally expected to be formated row-wise, so the the first
%   dimension specified above would be the number of spectra in a row of
%   the image and the second would be the number of spectra per column
%   (that is: x,y). If the image is formatted in other directions, the
%   specific image modes can be specified using the imageorder key=value
%   pair. The value should be two or three letters of "xyz" indicating the
%   order of the data:
%     imageorder = yx
%   indicates a two-dimensional image stored column-wise. Similarly:
%     imageorder = zxy
%   indicates a three-dimensional (volumetric) image stored as "drills
%   down" in the z direction repeated for each x,y position.
%
%I/O: x = spcreadr(filename,subs,wlrange,options);             %dataset output
%I/O: [data,xaxis,auditlog,description] = spcreadr(filename,subs,wlrange,options); %data array output
%
%See also: AUTOIMPORT, TEXTREADR, WRITESPC

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
% 8/21/00 JMS now reads auditlog too
% 2/03 JMS added copyright and recompile notes
% 2/03 JMS removed all references to spcload
% 5/03 JMS changed # of points to be double word
%  -fixed audit-log reading error (added readkeyedline)
% 9/8/03 JMS ignore nsubs=0 (assume at least one subfile is present)
% 9/22/03 JMS added multiple-file read
% 9/29/03 JMS adjusted handling of scaling=0 and scaling>128
% 10/13/03 JMS -added ability to read unequally spaced SPC files
%   -test for different x-axis for each subfile (not currently supported)
%   -revised handling of read on a Mac to use big-endian open instead of manual reveral
% 10/14/03 JMS 
%   -fixed bug in unequally spaced SPC file read code
%   -added interpretation of axis types
% 11/6/03 JMS
%   -allow input of string arrays of filenames
% 1/9/04 JMS
%   -blank input gives load dialog
% 3/2/04 jms
%   -cancel from load dialog returns empty (used to give error w/outputs)
%   -added special "multiple file" selection mode (numeric input)
% 3/15/04 jms
%   -fixed MAC byte ordering (fopen should use "le" not "be")
% 3/19/04 jms -added R14 support of multi-file uigetfile
%   -changed "select multiple files from current folder" to be triggered by
%     an empty cell instead of "0"
%   -no outputs returns dataset (not double)
% 4/19/04 jms -added test for dataset objects not defined
%   -multi-file auditlogs stored in cell array
%   -fixed bug with multi-file output as raw data
%   -added test for PLS_Toolbox not loaded
% 5/6/04 jms -added selection of folder to load multiple
%   -fixed auditlog concatination with multi-file load
% 11/18/04 jms -use file exponent if subfile exponent not set
%   -moved cell parsing into subroutine
%   -fixed exponent handling (again)
% 12/10/04 jms -disabled R14 "special code" for multifiles (has limitation
%    on number of files selectable due to bug in Matlab)
% 1/5/04 jms -allow multi-file read with raw variables as output
%    -fixed auditlog creation with multiple file read and raw var output
% 2/11/04 jms -read in z-axis time stamps
%    -assign name and author fields in DSO
% 7/26/05 jms -added interpolate option when x-axis doesn't match
%    -added options input
%    -added waitbar
% 9/25/06 nbg modified help

usedatasets   = exist('dataset','file');
useplstoolbox = exist('evriio','file');

logkeys = {'operator' 'author' 'name' 'imagesize' 'imageorder'};
relogkeys = sprintf('(%s)\\s*=(.*)|',logkeys{:});

%define default options
defaultoptions = [];
defaultoptions.nonmatching = 'matchvars';  % 'none' | 'intersect' | 'interpolate'
defaultoptions.textauditlog = 'no';           % 'no' | 'yes'
defaultoptions.waitbar = 'auto';
defaultoptions.multiselect = 'on';
defaultoptions.endianness = '';%Empty uses default (aka native) for PC and Linux with Mac being forced little endian (long standing default). Otherwise, single character string n/b/l/s/a (native/big/little/big 64/little 64) 

if nargin == 0 | (ischar(filename) & isempty(filename))
  filename = {};  %trigger parsecell below (it will offer select file dialog)
else
  if useplstoolbox & isstr(filename) & all(isstrprop(filename,'alpha')) & ismember(filename,evriio([],'validtopics'));
    if nargout==0; clear out; evriio(mfilename,filename,defaultoptions); else; out = evriio(mfilename,filename,defaultoptions); end
    return; 
  end
end

%find and reconcile options
if nargin>1 & isstruct(subs)
  options = subs;
  subs = [];
elseif nargin>2 & isstruct(wlrange)
  options = wlrange;
  wlrange = [];
elseif nargin<4
  options = [];
end
if ~useplstoolbox  %Options settings for non-PLS_Toolbox version
  if isempty(options);
    options = defaultoptions;
  end
else
  options = reconopts(options,'spcreadr');
end

%Handle cell arrays first - recursively call ourselves with each file name
if isa(filename,'char') & size(filename,1)>1;  %more than one row char array? Do as cell
  filename = mat2cell(filename,ones(size(filename,1),1),size(filename,2));
end
if isa(filename,'struct')
  if isfield(filename,'name');  %structure with "name" field?
    filename = filename(~[filename.isdir]);
    filename = {filename.name};
  else
    error('A structure containing filenames must have the names stored in field "name"');
  end
end

%Cell is list of filenames (or empty cell implies load multiple from current folder)
if iscell(filename) & length(filename)==1
  filename = filename{1};
end
if iscell(filename);
  options.norecon = true;  %set flag saying we don't have to reconcile options (already done)
  switch nargin
    case 2
      otherargs = {subs [] options};
    case 3
      otherargs = {subs wlrange options};
    case 4
      otherargs = {subs wlrange options};
    otherwise
      otherargs = {[] [] options};
  end
  if nargout>1;
    usedatasets = 0;  %even if we HAVE DSOs, don't use them if the user asked for multiple outputs
  end
  [out,xaxis,auditlog,description] = parsecell(filename,otherargs,usedatasets,options,nargout);
  return
end

%=============================================
%Read a file (we have a text file name here)

if nargin<2;
  subs    = [];
end
if nargin<3;
  wlrange = [];
end
textauditlog = strcmp(options.textauditlog,'yes');

if isempty(findstr('.spc',lower(filename))) & isempty(findstr('.dhb',lower(filename))); filename=[filename '.spc']; end;

% Open with appropriate endianness. May need to force to little on some
% platforms. 
if isempty(options.endianness)
  ismac=~isempty(findstr(computer,'MAC'));
  if ismac
    %Little endian.
    [f,MESSAGE]=fopen(filename,'r','ieee-le');
  else
    %Default (native).
    [f,MESSAGE]=fopen(filename);
  end
else
  [f,MESSAGE]=fopen(filename,'r',options.endianness);
end

if f==-1;
  disp([MESSAGE]);
  disp(['Current folder: ' pwd]);
  error(['File ''' filename ''' does not exist or some other similar error (check directory)']);
end;

wbhandle = [];
try
  ftflgs = double(fread(f,1,'uint8'));    %   BYTE   ftflgs; /* Flag bits defined below */
  fversn = double(fread(f,1,'uint8'));    %   BYTE   fversn; /* 4Bh=> new LSB 1st, 4Ch=> new MSB 1st, 4Dh=> old format */
  
  %handle ftflgs
  % 1 #define TSPREC	1	/* Single precision (16 bit) Y data if set. */
  % 2 #define TCGRAM	2	/* Enables fexper in older software (CGM if fexper=0) */
  % 3 #define TMULTI	4	/* Multiple traces format (set if more than one subfile) */
  % 4 #define TRANDM	8	/* If TMULTI and TRANDM=1 then arbitrary time (Z) values */
  % 5 #define TORDRD	16	/* If TMULTI abd TORDRD=1 then ordered but uneven subtimes */
  % 6 #define TALABS	32	/* Set if should use fcatxt axis labels, not fxtype etc.  */
  % 7 #define TXYXYS	64	/* If TXVALS and multifile, then each subfile has own X's */
  % 8 #define TXVALS	128	/* Floating X value array preceeds Y's  (New format only) */
  ftflgs_bin = mod(floor(ftflgs./2.^[0:7]),2)==1;   %convert ftflgs to binary digits
  
  if fversn==75 | fversn==76
    fexper = fread(f,1,'uint8');    %   BYTE   fexper; /* Reserved for internal use (experiment-1) */
    fexp   = fread(f,1,'int8');    %   char   fexp;   /* Fraction scaling exponent integer (80h=>float) */
    fnpts  = fread(f,1,'uint32');   %   DWORD  fnpts;  /* Integer number of points (or TXYXYS directory position) */
    ffirst = fread(f,1,'float64');   %   double ffirst; /* Floating X coordinate of first point */
    flast  = fread(f,1,'float64');   %   double flast;  /* Floating X coordinate of last point */
    fnsub  = fread(f,1,'uint32');    %   DWORD  fnsub;  /* Integer number of subfiles (1 if not TMULTI) */
    fxtype = fread(f,1,'uint8');     %   BYTE   fxtype; /* Type of X units (see definitions below) */
    fytype = fread(f,1,'uint8');     %   BYTE   fytype; /* Type of Y units (see definitions below) */
    fztype = fread(f,1,'uint8');     %   BYTE   fztype; /* Type of Z units (see definitions below) */
    fpost  = fread(f,1,'uint8');     %   BYTE   fpost;  /* Posting disposition (see GRAMSDDE.H) */
    fdate  = fread(f,1,'uint32');    %   DWORD  fdate;  /* Date/Time LSB: min=6b,hour=5b,day=5b,month=4b,year=12b */    
    fres    = char(fread(f,9,'char')');     % char fres[9]; /* Resolution description text (null terminated) */
    fsource = char(fread(f,9,'char')');    % char fsource[9]; /* Source instrument description text (null terminated) */
    fpeakpt = fread(f,1,'uint16');         % WORD fpeakpt; /* Peak point number for interferograms (0=not known) */
    fspare  = fread(f,8,'float32');        % float fspare[8]; /* Used for Array Basic storage */
    fcmnt   = char(fread(f,130,'char')');  % char fcmnt[130]; /* Null terminated comment ASCII text string */
    fcatxt  = char(fread(f,30,'char')');   % char fcatxt[30]; /* X,Y,Z axis label strings if ftflgs=TALABS */
    flogoff = fread(f,1,'uint16');         % DWORD flogoff; /* File offset to log block or 0 (see above) */
    fmods   = fread(f,1,'uint16');         % DWORD fmods; /* File Modification Flags (see below: 1=A,2=B,4=C,8=D..) */
    % BYTE fprocs; /* Processing code (see GRAMSDDE.H) */
    % BYTE flevel; /* Calibration level plus one (1 = not calibration data) */
    % WORD fsampin; /* Sub-method sample injection number (1 = first or only ) */
    % float ffactor; /* Floating data multiplier concentration factor (IEEE-32) */
    % char fmethod[48]; /* Method/program/data filename w/extensions comma list */
    % float fzinc; /* Z subfile increment (0 = use 1st subnext-subfirst) */
    % DWORD fwplanes; /* Number of planes for 4D with W dimension (0=normal) */
    % float fwinc; /* W plane increment (only if fwplanes is not 0) */
    % BYTE fwtype; /* Type of W axis units (see definitions below) */
    % char freserv[187]; /* Reserved (must be set to zero) */
    
    %Using fread with 'char' caused a problem for Linux user on unusual
    %file. Read past where expected (512).
    %
    %remainder = fread(f,(512-ftell(f)),'char'); %Bad for Linux with some files. 
    %
    %Can us uchar which forces 8bit read but since remainder isn't used
    %just use fseek.
    %
    %remainder = fread(f,(512-ftell(f)),'uchar'); %Ok for Linux I think.
    
    fseek(f,(512-ftell(f)),'cof');
    
  elseif fversn==77
    %   fclose(f);
    %   error(['Wrong/Old File Type (' num2str(fversn) ')! Read file into Grams and save as a new file']);
    [fexper, fexp, fnpts, ffirst, flast, fnsub, fxtype, fytype, fztype, fpost, fdate, fcmnt] = readoldheader(f);
    [fres, fsource, fcatxt] = deal('');
    
    if ftflgs_bin(3)
      %TMULTI flag on
      fnsub = inf;   %trick code below to extract as many subfiles as it can (we can't tell how many with this file format)
    end
  else
    error(['Unsupported SPC File Version (' dec2hex(fversn) ').']);
  end
  
  if ftflgs_bin(7)
    error('Unable to read SPC sub-files with differently spaced x-axes. Break into separate sub-files')
  end
  
  %create or read x-axis
  if ~ftflgs_bin(8);
    fstep = ((flast-ffirst)/(fnpts-1));
    xaxis = ffirst:fstep:flast;
  else  %unequally spaced x-axis. read in xaxis
    xaxis = fread(f,fnpts,'float32');   %Read current subfile (float format)
    xaxis = xaxis(:)';                  % Ensure xaxis is a ROW vector
  end
  
  %find sub-range (if requested)
  if isempty(wlrange);
    wlrange=1:fnpts;
  else
    if length(wlrange)==2; %end points given? do inclusive range w/all points
      wlrange = find(xaxis>=wlrange(1) & xaxis<=wlrange(2));
    else
      wlrange = interp1(xaxis,1:length(xaxis),wlrange,'nearest');
      wlrange(~isfinite(wlrange)) = [];  %drop invalid points
    end
    xaxis = xaxis(wlrange);
  end;
  
  %identify sub-files we want
  if fnsub==0
    fnsub = 1;   %try for at least one sub-file if none are found
  end
  if isempty(subs);
    if isfinite(fnsub)
      max_subs  = fnsub;
      totalsubs = fnsub;
    else
      max_subs  = inf;
      totalsubs = 1;  %will mean we don't pre-allocate to right size, but we can't tell how many we've got anyway
    end
  else
    if isinf(subs); subs=1:fnsub;end;
    if max(subs)>fnsub; error(['Not that many subfiles']); end;
    max_subs  = max(subs);
    totalsubs = length(subs);
  end
  
  % if subs=0 then tell user how many are in the file and the xaxis info
  if ~isempty(subs) & subs==0;
    if fversn==77
      error('Cannot return number of subfiles with old file format');
    end
    out   = fnsub;
    xaxis = [min(xaxis) max(xaxis) length(xaxis)];
    fclose(f);
    return;
  end
  
  index      = 0; 
  totalwls   = length(wlrange);
  
  %locate end of file
  posnow = ftell(f);
  fseek(f,0,1);  %locate end of file
  flength = ftell(f);
  fseek(f,posnow,-1);  %reset to spot we were reading from

  if strcmp(options.waitbar,'on') | (strcmp(options.waitbar,'auto') & max_subs>1000)
    wbhandle = waitbar(0,'Loading SPC Files...');
  end

  %Read sub-file(s)
  out=zeros(totalwls,totalsubs);   %set up output array (i.e. check memory)
  j = 0;
  % limit how small the waitbar increment can be to waitfract
  waitfract = 1/50;
  nwaitsteps = ceil(max_subs*waitfract);
  nwaitsteps = max(10, nwaitsteps);
  
  % save subheads in a cell array (important: need to update this as readsubheadr subfunction gets updated).
  %subheads = { 'subflgs', 'subexp', 'subindx', 'subtime', 'subnext', 'subnois', 'subnpts', 'subscan'};%, 'subresv'};
    subheads = { 'subflgs', 'subexp', 'subindx', 'subtime', 'subnext', 'subnois', 'subnpts', 'subscan', 'subwlevel', 'subresv'};
    tmp = zeros(fnsub,size(subheads,2)+3);
        for i=1:length(subheads)
          if (i < size(subheads,2))
            subhds.(subheads{i}) = tmp(:,i);
          else
            subhds.(subheads{i}) = tmp(:,i:end);
          end
        end
    
  while j<max_subs;
    if ishandle(wbhandle) & mod(index, nwaitsteps)==0
      waitbar(index/totalsubs);
    end
    j = j+1;
    if flength==ftell(f); break; end
    if feof(f); break; end
    [currentframe,subhead] = readsubfile(f,fnpts,fexp,fversn,fnsub,ftflgs_bin);
    % save subheaders part 1
      for ih=1:size(subheads,2)
        if ih < size(subheads,2)
          %subheads{j+1,ih}=subhead(ih);
          subhds.(subheads{1,ih})(j)=subhead(ih);
        else
          %subheads{j+1,ih}=subhead(ih:end);
          subhds.(subheads{1,ih})(j,:)=subhead(ih:end);
        end
      end
    
    if isempty(subs) | any(j==subs);         %user wants this one?
      index=index+1;
      out(:,index) = currentframe(wlrange,:);  %then store it
      zaxis(index) = subhead(4);  %grab any z-axis info
    end;
  end;
  if ishandle(wbhandle)
    delete(wbhandle);
  end

  if nargout<2 & usedatasets
    textauditlog = true; %always do text log when doing dataset
  end
  auditlog = readauditlog(f,textauditlog);
  
  %special processing of audit log for DSO-specific keywords
  imagesize = [];
  imageorder = '';
  author = 'SPCREADR';
  name = '';
  if textauditlog & ~isempty(auditlog)
    %look for keywords to add context to DSO
    matchedkeys = regexpi(str2cell(auditlog),relogkeys,'tokens');
    haskeys = ~cellfun('isempty',matchedkeys);
    if any(haskeys)
      foundkeys = cellfun(@(z) lower(z{1}{1}),matchedkeys(haskeys),'uniformoutput',0);
      foundvals = cellfun(@(z) z{1}{2},matchedkeys(haskeys),'uniformoutput',0);
      
      %image-specific keywords
      loc = ismember(foundkeys,'imagesize');
      if any(loc)
        %make DSO into an image DSO
        imagesize = str2num(foundvals{loc});
        
        %look for other image info
        loc = ismember(foundkeys,'imageorder');
        if any(loc)
          imageorder = foundvals{loc};
        end        
      end

      %operator/author keywords
      loc = ismember(foundkeys,'author');
      if any(loc)
        author = foundvals{loc};
      else
        loc = ismember(foundkeys,'operator');
        if any(loc)
          author = foundvals{loc};
        end
      end

      %name keyword
      loc = ismember(foundkeys,'name');
      if any(loc)
        name = foundvals{loc};
      end

    end
  end
catch
  if ishandle(wbhandle)
    delete(wbhandle);
  end

  fclose(f);
  rethrow(lasterror)
end

fclose(f);

out = out';  %transpose to row convention

%get description information
description = { fcmnt fcatxt };
description(cellfun('isempty',description)) = [];
description = char(description);

if usedatasets & nargout<=1;
  %create dataset if only one output requested
  out = dataset(out);

  out.description = description;
  
  if ~isempty(name)
    out.name = name;
  else
    [pth,out.name] = fileparts(filename);
  end
  out.author = author;
  
  out.axisscale{2} = xaxis;

  [pth,nm] = fileparts(filename);
  out.label{1} = repmat(nm,size(out.data,1),1);
  
  %Add x-units if available from file
  units = definexunits;
  index = find(ismember([units{:,1}],fxtype));
  if ~isempty(index)
    out.axisscalename{2} = units{index(1),2};
  end

  if ~all(zaxis==zaxis(1))
    out.axisscale{1} = zaxis;
  else
    out.axisscale{1} = 1:size(out,1);
    out.axisscalename{1} = 'Subfile Index';
  end

  %create image if information found in audit log
  if ~isempty(imagesize) & size(out,1)==prod(imagesize)
    out.type = 'image';
    out.imagesize = imagesize;
    if ~isempty(imageorder)
      %check for order of slabs requested
      imageorder(~ismember(imageorder,'xyz')) = [];  %drop all non relevant chars
      order = [strfind(imageorder,'x') strfind(imageorder,'y') strfind(imageorder,'z')];
      if length(order)>1 & any(diff(order)~=1)
        out = permute_img(out,order);
      end
    end
  end
  
  % save subheaders part 2
  out.axisscale{1,end+1}=subhds.subindx';
  out.axisscale{1,end+1}=subhds.subindx';
  out.axisscale{1,end+1}=subhds.subtime';
  out.axisscale{1,end+1}=subhds.subnext';
  %out.axisscale{1,end+1}=subhds.subtime(:):1/fnpts-1:subhds.subnext(:);
  out.label{1,end+1}={num2str(subhds.subscan)};
  out.axisscale{1,end+1}=subhds.subwlevel';
  
  out.userdata = {auditlog,subhds};
  %out.userdata = {auditlog,subheads};
  %out.userdata = auditlog;
  out = addsourceinfo(out,filename);

end

%-----------------------------------------------------------------
function [currentframe,subhead] = readsubfile(f,fnpts,fexp,fversn,fnsub,ftflgs_bin)
%READSUBFILE reads a subfile
% input f is file ID # and fnpts is # of points in a sub-file

subhead = readsubhdr(f);				% Read sub-header

if fnsub==1; subhead(2)=fexp; end;  %not multifile? use fexp
% Above line needed because, From SPC.H: "if TMULTI is not set, then the
% subexp is ignored in favor of fexp."

if fversn==75 | fversn==76
  if subhead(2)~= -128;
    %determine which numerical format we're supposed to be using based on
    %file header flags 1 #define TSPREC	1	/* Single precision (16 bit) Y
    %data if set. */
    if ftflgs_bin(1)
      %header flag
      numformat = 'int16';
    else
      numformat = 'int32';
    end
    currentframe=fread(f,fnpts,numformat);   %Read current subfile (IBM SPC format)
    currentframe = currentframe*(2^subhead(2))/(2^32);     %adjust for scaling denoted by subhead(2)
  else
    currentframe=fread(f,fnpts,'float32');   %Read current subfile (float format)
  end
else
  currentframe = fread(f,fnpts*2,'int16');
  currentframe = currentframe(2:2:end)+currentframe(1:2:end)*2^16;
  currentframe = currentframe.*(2^subhead(2))/(2^32);
end

%-----------------------------------------------------------------
function out=readsubhdr(f);
%READSUBHDR reads the sub header for a subfile
% input f is file ID #

subflgs=fread(f,1,'uint8');		%   BYTE  subflgs;	/* Flags as defined below */
%define SUBCHGD 1	/* Subflgs bit if subfile changed */
%define SUBNOPT 8	/* Subflgs bit if peak table file should not be used */
%define SUBMODF 128	/* Subflgs bit if subfile modified by arithmetic */
subexp = fread(f,1,'int8');    %   char   fexp;   /* Fraction scaling exponent integer (80h=>float) */   
subindx=fread(f,1,'uint16');		%   WORD  subindx;	/* Integer index number of trace subfile (0=first) */
subtime=fread(f,1,'float32');		%   float subtime;	/* Floating time for trace (Z axis corrdinate) */
subnext=fread(f,1,'float32');		%   float subnext;	/* Floating time for next trace (May be same as beg) */
subnois=fread(f,1,'float32');		%   float subnois;	/* Floating peak pick noise level if high byte nonzero*/
subnpts=fread(f,1,'uint32');		%   DWORD subnpts;	/* Integer number of subfile points for TXYXYS type*/
subscan=fread(f,1,'uint32');		%   DWORD subscan;	/*Integer number of co-added scans or 0 (for collect)*/
  subwlevel=fread(f,1,'float32');   %float subwlevel 32bitfloat
%subresv=fread(f,8,'uint8');		%   char  subresv[8];	/* Reserved area (must be set to zero) */
subresv=fread(f,4,'uint8');		%   fixed (4 instead of 8).
% 1 1 2 4 4 4 4 4 8
%out=[subflgs subexp subindx subtime subnext subnois subnpts subscan];
  out=[subflgs subexp subindx subtime subnext subnois subnpts subscan subwlevel subresv'];

%-----------------------------------------------------------------
function log=readauditlog(f,textmode);
% READAUDITLOG reads the end of the file for all the audit log entries.

log = '';
if feof(f);
  return
end

% typedef struct /* log block header format */
% {
logsizd = fread(f,1,'uint32'); % DWORD logsizd; /* byte size of disk block */
logsizm = fread(f,1,'uint32'); % DWORD logsizm; /* byte size of memory block */
logtxto = fread(f,1,'uint32'); % DWORD logtxto; /* byte offset to text */
logbins = fread(f,1,'uint32'); % DWORD logbins; /* byte size of binary area (immediately after logstc) */
logdsks = fread(f,1,'uint32'); % DWORD logdsks; /* byte size of disk area (immediately after logbins) */
logspar = fread(f,44,'char'); % char logspar[44]; /* reserved (must be zero) */
% } LOGSTC;

if isempty(logsizd) | logsizd==0
  return;
end

if logbins>0
  %binary data stored in log? read it (discareded, however)
  logbin = fread(f,logbins,'uint8');
end

if ~textmode
  log=[];
else
  log = {};
end
key='';

while ~strcmp(key,'EOF');
  try;
    oneline=fgetl(f);
    
    if ~isstr(oneline) & oneline==-1;
      key=['EOF'];
      oneline=[];   
    else;
      
      if ~isempty(oneline) & any(oneline==5);
        %a code of 5 appears to mean end of audit log, look for it and take everything up to it.
        if min(find(oneline==5))>1;
          oneline=oneline(1:min(find(oneline==5))-1);
        else
          key=['EOF'];
          oneline=[];   
        end;
      end;
      if ~isempty(oneline);
        if ~textmode
          [key,value]=readkeyedline(oneline);					%read a line
          if ~isempty(key) & ~strcmp(key,'EOF');
            key(find(ismember(key(:),{' ' '.' ':' ';' ','}))) = '_';
            if ~isempty(findstr(lower(key),'date'));
              %is it a date field? try converting it to matlab-normal date format
              if isstr(value)
                log=setfield(log,key,datestr(datenumplus(value)));
              else
                log=setfield(log,key,datestr(value));
              end;
            else
              %not at date field? just write it out as usual
              if checkmlversion('>=','7')
                %Make sure field name is valid.
                key = genvarname(key);
              end
              log=setfield(log,key,value);
            end;
          end;
        else
          %text-only audit log mode, just return text, not structure
          log{end+1} = oneline;
        end
      end;
    end;
  catch;
  end;
end;

if textmode
  log = char(log);
end

%----------------------------------------------------
function [key,value]=readkeyedline(line,token)

if nargin<2;
  token = '=';
end

[key,value] = strtok(line,token);
value = value(2:end);

nval = str2double(value);
if ~isnan(nval);  
  %If it WAS convertable using str2double, actually use str2num (more general)
  value = str2num(value);
end   %otherwise, return string

%----------------------------------------------------
function units = definexunits

units = {
  1,'Wavenumber (cm-1)'
  2,'Micrometers'
  3,'Nanometers'
  4,'Seconds'
  5,'Minutes'
  6,'Hertz'
  7,'Kilohertz'
  8,'Megahertz'
  9,'Mass (M/z)'
  10,'Parts per million'
  11,'Days'
  12,'Years'
  13,'Raman Shift (cm-1)'
  14,'Electron Volts (eV)'
  16,'Diode Number'
  17,'Channel'
  18,'Degrees'
  19,'Temperature (F)'
  20,'Temperature (C)'
  21,'Temperature (K)'
  22,'Data Points'
  23,'Milliseconds (mSec)'
  24,'Microseconds (uSec)'
  25,'Nanoseconds (nSec)'
  26,'Gigahertz (GHz)'
  27,'Centimeters (cm)'
  28,'Meters (m)'
  29,'Millimeters (mm)'
  30,'Hours'
  255,'Double interferogram (no display labels)'};

%----------------------------------------------------
function units = defineyunits

units = {
  1,'Interferogram'
  2,'Absorbance'
  3,'Kubelka-Munk'
  4,'Counts'
  5,'Volts'
  6,'Degrees'
  7,'Milliamps'
  8,'Millimeters'
  9,'Millivolts'
  10,'Log (1/R)'
  11,'Percent'
  12,'Intensity'
  13,'Relative Intensity'
  14,'Energy'
  16,'Decibel'
  19,'Temperature (F)'
  20,'Temperature (C)'
  21,'Temperature (K)'
  22,'Index of Refraction [N]'
  23,'Extinction Coeff. [K]'
  24,'Real'
  25,'Imaginary'
  26,'Complex'
  128,'Transmission'
  129,'Reflectance'
  130,'Arbitrary or Single Beam with Valley Peaks'
  131,'Emission'};

%-----------------------------------------------------
function [data,xaxis,auditlog,description] = parsecell(filename,otherargs,usedatasets,options,num_arg_out)

blocksize = 300;
data     = [];
xaxis    = [];
auditlog = [];
labels   = {};
description = {};

if isempty(filename) | (length(filename)==1 & isempty(filename{1})) ;    %empty cell = choose files
  if strcmpi(options.multiselect,'on')
    prompt = 'Select File(s) To Load';
  else 
    prompt = 'Select File To Load';
  end
  [filename,pathname] = evriuigetfile({'*.spc;*.SPC;*.dhb;*.DHB','Galactic SPC files (*.spc;*.dhb)';'*.*' 'All Files'},prompt,'MultiSelect',options.multiselect);
  if isempty(filename) | isnumeric(filename); return; end
  
  if ~iscell(filename);
    filename = {filename};
  end
  for ind=1:length(filename);
    filename{ind} = fullfile(pathname,filename{ind});
  end
  
  %If length of cell is one then call spcreader with single file input so
  %parsecell logic (matchvars) is not used. Allows for full meta data
  %(labels, axisscale) to be included, otherwise the meta data is truncated
  %below.
  if length(filename)==1
    if num_arg_out>1
      [data,xaxis,auditlog,description] = spcreadr(filename{1},otherargs{1},otherargs{2},options);
    else
      data = spcreadr(filename{1},otherargs{1},otherargs{2},options);%Get actual dataset.
    end
    return
  end
  
end

%Read files
if strcmp(options.waitbar,'on') | (strcmp(options.waitbar,'auto') & length(filename)>100)
  wbhandle = waitbar(0,'Loading SPC Files...');
  otherargs{3}.waitbar = 'off'; %do NOT use waitbar at file-level if we're using it here
else
  wbhandle = [];
end

if usedatasets
  %always use text auditlog if usedataset
  otherargs{3}.textauditlog = 'yes';  
elseif strcmpi(options.nonmatching, 'matchvars')
  options.nonmatching = 'interpolate';
end

try
  dindex = 1;
  datacell = {};  
  % If spectral ranges do not match then switch to accumulating each 
  % imported file as a dataset, saved into datacell
  for fnameindex = 1:length(filename);
    if ishandle(wbhandle) & mod(fnameindex,10)==0
      waitbar(fnameindex/length(filename));
    end
    fname = filename(fnameindex);

    %read in file
    if fnameindex==1 & usedatasets
      %create dataset
      basedso = spcreadr(fname{:},otherargs{:});
      data1   = basedso.data;
      xaxis1  = basedso.axisscale{2};
      auditlog1 = basedso.userdata;
      description1 = basedso.description;
    elseif ~isempty(datacell) & usedatasets
      % We have switched to saving cell array of DSOs
      datacell{end+1} = spcreadr(fname{:},otherargs{:});
      continue;
    else
      [data1,xaxis1,auditlog1,description1] = spcreadr(fname{:},otherargs{:});
    end
    if ~isempty(xaxis) & ~isempty(xaxis1)
      %do spectral ranges match?
      if length(xaxis)~=length(xaxis1) | any(xaxis~=xaxis1);
        % no, then merge according to option "nonmatching"
        switch options.nonmatching
          case 'none'
            if length(xaxis)~=length(xaxis1);
              error(['Two or more spectra have different numbers of points (failure loading ' fname{:} ')']);
            end
            
          case 'matchvars'
            % Normally "data" is an array holding matching loaded spectra.
            % When a non-matching spectrum is imported AND if
            % option.nonmatching = 'matchvars' then switch from
            % accumulating spectra in array "data" to saving each imported
            % spectrum as a DSO in cell array "datacell", after first
            % saving the spectra already accumulated, "data", as the first 
            % DSO in "datacell", datacell{1}.
            % If "datacell" is not empty it means we have encountered
            % non-matching spectra (and options.nonmatching = 'matchvars')
            % and are now accumulating DSOs in "datacell".
            if isempty(datacell) 
              % Convert data array already accumulated to DSO
              %dump unused block padding
              data = data(1:dindex-1,:);
              
              data = dataset(data);
              data.axisscale{2} = xaxis;
              data.axisscalename{1} = basedso.axisscalename{1};
              data.axisscalename{2} = basedso.axisscalename{2};
              data.label{1}  = labels;
              data.axisscale{1} = 1:size(data,1);
              out.axisscalename{1} = 'File Index';
              data.userdata  = auditlog;
              data.name      = 'Multiple SPC Files';
              data.author    = basedso.author;
              data.description = description;
              datacell{1} = data;
              % and add this new unmatching file as next DSO in datacell
              datacell{2} = spcreadr(fname{:},otherargs{:});
            else
              % Accumulating new files as DSO in datacell 
              datacell{end+1} = spcreadr(fname{:},otherargs{:});
            end
            
          case 'interpolate'
            use = xaxis>min(xaxis1) & xaxis<max(xaxis1);
            if isempty(use);
              error(['Two or more spectra have no overlapping spectral regions (failure loading ' fname{:} ')']);
            end
            xaxis = xaxis(use);
            data   = data(:,use);
            switch size(data1,1)
              case 1
                %vector - simple case
                data1  = interp1(xaxis1,data1,xaxis,'linear');
              otherwise
                %matrix - requires transpose
                data1  = interp1(xaxis1,data1',xaxis,'linear')';
            end
            xaxis1 = xaxis;
            
          otherwise
            [xaxis1,ia,ib] = intersect(xaxis1,xaxis);
            if isempty(xaxis1)
              error(['Two or more spectra have no spectral points in common (failure loading ' fname{:} ')']);
            end
            data1 = data1(:,ia);
            data  = data(:,ib);
        end
      end
    else
      %first spectrum, build data block up to length of file list
      data = zeros(length(filename)+1,size(data1,2));  %try allocating memory        
    end
    
    %add new data to existing matrix if no un-matching files were found yet
    %(not in datacell mode)
    if isempty(datacell)
      data(dindex:dindex+size(data1,1)-1,:) = data1;
      dindex = dindex+size(data1,1);
      if size(data,1)<dindex
        data = [data;zeros(blocksize,size(data,2))];
      end
      xaxis = xaxis1;
      if ~isempty(auditlog1);
        if isempty(auditlog);
          auditlog = {auditlog1};
        else
          auditlog(end+1) = {auditlog1};
        end
      end
      
      [pth,mylbl] = fileparts(fname{:});
      labels = [labels;repmat({mylbl},size(data1,1),1)];
      description{end+1} = description1;
    end
    
  end
  
  if isempty(datacell)    
    %dump unused block padding
    data = data(1:dindex-1,:);
    
    if usedatasets
      %create dataset
      data = dataset(data);
      data.axisscale{2} = xaxis;
      data.axisscalename{1} = basedso.axisscalename{1};
      data.axisscalename{2} = basedso.axisscalename{2};
      data.label{1}  = labels;
      data.axisscale{1} = 1:size(data,1);
      out.axisscalename{1} = 'File Index';
      data.userdata  = auditlog;
      data.name      = 'Multiple SPC Files';
      data.author    = basedso.author;
      data.description = char(description);
      data           = addsourceinfo(data,filename);
    end
  else
    data = datacell;
    % Use matchvars to merge the accumulated DSOs if requested
    if strcmp(options.nonmatching,'matchvars')
      data = matchvars(data);
      data = addsourceinfo(data,filename);
      xaxis = data.axisscale{2};
      auditlog = data.userdata;
      description = data.description;
    end
  end
  
catch
  if ishandle(wbhandle)
    delete(wbhandle);
  end
  if exist('rethrow')
    rethrow(lasterror)  %only works in ver 6.5 and later
  else
    error(lasterr)  %use for ver 6.1 and earlier
  end
end
if ishandle(wbhandle)
  delete(wbhandle);
end

%---------------------------------------------------------
function out = getmlversion
%GETMLVERSION returns current Matlab version as a double
%
%I/O: version = getmlversion

out = getappdata(0,'spcmatlabversion');
if isempty(out);
  out  = version;
  out  = str2num(out(1:3));
  setappdata(0,'spcmatlabversion',out);
end

%===========================================================
function [fexper, fexp, fnpts, ffirst, flast, fnsub, fxtype, fytype, fztype, fpost, fdate, ocmnt] = readoldheader(f)

%** Header items not defined in old format (or defined strangely and punted here) **
fexper = 0;   %   /* Reserved for internal use (experiment-1) */
fnsub  = 1;   %   /* Integer number of subfiles (1 if not TMULTI) */
fztype = 0;   %   /* Type of Z units (see definitions below) */
fpost  = 0;   %   /* Posting disposition (see GRAMSDDE.H) */
fdate  = 0;   %   /* Date/Time LSB: min=6b,hour=5b,day=5b,month=4b,year=12b */

fexp   = fread(f,1,'int16');     %   short oexp;		/* Word rather than byte */
fnpts  = fread(f,1,'float32');   %   float onpts; 	/* Floating number of points */
ffirst = fread(f,1,'float32');   %   float ofirst;	/* Floating X coordinate of first pnt (SP rather than DP) */
flast  = fread(f,1,'float32');   %   float olast; 	/* Floating X coordinate of last point (SP rather than DP) */
fxtype = fread(f,1,'uint8');     %   BYTE  oxtype;	/* Type of X units */
fytype = fread(f,1,'uint8');     %   BYTE  oytype;	/* Type of Y units */

% remainder = fread(f,(256-ftell(f)-32),'char');  % Read to end of header (except subheader)
% 
% ocmnt = '';

oyear  = fread(f,1,'uint16');     %    WORD  oyear; 	/* Year collected (0=no date/time) - MSB 4 bits are Z type */
omonth = fread(f,1,'uint8');      %    BYTE  omonth;	/* Month collected (1=Jan) */
oday   = fread(f,1,'uint8');      %    BYTE  oday;		/* Day of month (1=1st) */
ohour  = fread(f,1,'uint8');      %    BYTE  ohour; 	/* Hour of day (13=1PM) */
ominute = fread(f,1,'uint8');     %    BYTE  ominute;	/* Minute of hour */
ores    = char(fread(f,8,'char')'); %    char  ores[8];	/* Resolution text (null terminated unless 8 bytes used) */
opeakpt = fread(f,1,'uint16');    %    WORD  opeakpt;
onscans = fread(f,1,'uint16');    %    WORD  onscans;
ospare  = fread(f,7,'float32');   %    float ospare[7];
ocmnt   = char(fread(f,130,'char')');  %    char  ocmnt[130];
ocatxt  = char(fread(f,30,'char')');   %    char  ocatxt[30];

ocmnt(ocmnt==0) = [];  %drop zeros from comment
ocmnt = strtrim(ocmnt);

% remainder = fread(f,(256-ftell(f)-33),'char');  % Read to end of header (except subheader)
% osubh1  = char(fread(f,32,'char')');   %    char  osubh1[32];	/* Header for first (or main) subfile included in main header */

function [datenumVal, datetimeVal] = fdateConvert(fdate)

% sub function to convert embedded 32 bit unsigned long in SPC files to
% useful date/time formats

my32Bits    = dec2bin(uint32(fdate));
% pad string to the left with zeroes to fill as necessary
my32Bits    = sprintf('%s%s', repmat('0', 1,32-length(my32Bits)), my32Bits);

% extracting date/time info; indices below are as per specification guide
% for SPC file format

yearInds   = 1:12;
monthInds  = 13:16;
dayInds    = 17:21;
hourInds   = 22:26;
minuteInds = 27:32;

allInds = {yearInds monthInds dayInds hourInds minuteInds};

dtVec   = cellfun(@(x)bin2dec(my32Bits(x)), allInds);

dtVec       = dtVec(:)';
dtVec       = [dtVec 0];
datenumVal  = datenum(dtVec);
datetimeVal = datetime(dtVec);