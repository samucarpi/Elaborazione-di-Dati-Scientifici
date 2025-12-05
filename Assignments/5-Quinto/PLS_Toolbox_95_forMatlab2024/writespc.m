function out = writespc(data,filename)
%WRITESPC Writes Galactic SPC files.
% Creates an SPC format file to contain the contents of a DataSet object.
%
% INPUTS:
%   data     = a dataset to be written to SPC format file
%   filename = a text string with the name of a SPC file
%
%  Data is written out in the 'new' SPC format, fversn = 0x4BH (= 75 dec).
%  Although SPC.H makes mention of a 0x4C setting for new format SPC files
%  that allows for a different word order, most Galactic software products
%  do not support it.
%
%I/O: writespc(data,filename)
%
%See also: SPCREADR, WRITECSV

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0;
  data = 'io';
end
if ischar(data) %Help, Demo, Options
  options = [];
  if nargout==0; evriio(mfilename,data,options); else; out = evriio(mfilename,data,options); end
  return;
end

if nargin<2;
  [filename,pth] = evriuiputfile({'*.spc' 'Galactic SPC (*.spc)'});
  if ~isstr(filename) & filename == 0;
    return;
  end
  filename = fullfile(pth,filename);
end


% now make sure that all file names entered have the correct extension
[fp,fn,fe] = fileparts(filename);
if isempty(fe)
  filename = [filename '.spc'];  %make sure there is an extension on the filename
end

try
  [f,msg] = fopen(filename,'w');
  
  if f<0
    error(msg);
  end
  
  if ~isa(data,'dataset')
    data = dataset(data);
  end
  
  %Add x-units if available from file
  knownxunits = definexunits;
  namex = data.axisscalename{2};
  [ismem, iloc]=ismember(namex, {knownxunits{:,2}});
  if ismem
    fxtype = knownxunits{iloc, 1};     % Found known axis label in fxtype
    talabs = 0;         % Found known axis label in fxtype or fytype. Do not use talabs
  else
    fxtype = 0;
    talabs = 32;       % Use talabs, indicating use of fcatxt axis labels
  end
  
  fytype = 0;
  fztype = 0;
  
  fcatxt   = repmat(char(0), 1, 30);
  if talabs==0      % Did recognize X axis label from axisscalename{2}
    fcatxt = sprintf('%-9.9s%c%-9.9s%c%-9.9s%c', namex, 0, 'Arbitrary', 0, 'Arbitrary', 0);
  elseif talabs>0   % Did not recognize known axis label from axisscalename
                    % so just use whatever the axisscalenames are
    namez  = data.axisscalename{1};
    
    if ~isempty(namex)
      fcatxt = sprintf('%-9.9s%c', namex, 0);
    else
      fcatxt = sprintf('%-9.9s%c', 'Arbitrary', 0);
    end
    str0 = sprintf('%-9.9s%c', 'Arbitrary', 0);
    fcatxt = sprintf('%s%s', fcatxt, str0);
    if ~isempty(namez)
      str0 = sprintf('%-9.9s%c', namez, 0);
      fcatxt = sprintf('%s%s', fcatxt, str0);
    else
      str0 = sprintf('%-9.9s%c', 'Arbitrary', 0);
      fcatxt = sprintf('%s%s', fcatxt, str0);
    end
  end
  
  [m,n] = size(data);
  ax = data.axisscale{2};
  if isempty(ax)
    ax = 1:n;
  end
  ay = data.axisscale{1};
  if isempty(ay)
    ay = 1:m;
  end
  
  % Is this=multi spectra (multi subfiles)
  tmulti = 0;
  if m>1
    tmulti = 4;
  end
  
  %handle ftflgs
  % 1 #define TSPREC	1	/* Single precision (16 bit) Y data if set. */
  % 2 #define TCGRAM	2	/* Enables fexper in older software (CGM if fexper=0) */
  % 3 #define TMULTI	4	/* Multiple traces format (set if more than one subfile) */
  % 4 #define TRANDM	8	/* If TMULTI and TRANDM=1 then arbitrary time (Z) values */
  % 5 #define TORDRD	16	/* If TMULTI abd TORDRD=1 then ordered but uneven subtimes */
  % 6 #define TALABS	32	/* Set if should use fcatxt axis labels, not fxtype etc.  */
  % 7 #define TXYXYS	64	/* If TXVALS and multifile, then each subfile has own X's */
  % 8 #define TXVALS	128	/* Floating X value array preceeds Y's  (New format only) */
  ftflgs = tmulti + talabs + 128;
  ftflgs_bin = mod(floor(ftflgs./2.^[0:7]),2)==1;   %convert ftflgs to binary digits
  
  fwrite(f,ftflgs,'uint8');      %   BYTE   ftflgs; /* Flag bits defined below */
  fwrite(f,75,'uint8');    %   BYTE   fversn; /* 4Bh=> new LSB 1st, 4Ch=> new MSB 1st, 4Dh=> old format */
  
  fwrite(f,0,'uint8');    %   BYTE   fexper; /* Reserved for internal use (experiment-1) */
  fwrite(f,128,'uint8');  %   char   fexp;   /* Fraction scaling exponent integer (80h=>float) */
  fwrite(f,n,'uint32');   %   DWORD  fnpts;  /* Integer number of points (or TXYXYS directory position) */
  fwrite(f,ax(1),'float64');   %   double ffirst; /* Floating X coordinate of first point */
  fwrite(f,ax(end),'float64'); %   double flast;  /* Floating X coordinate of last point */
  fwrite(f,m,'uint32');    %   DWORD  fnsub;  /* Integer number of subfiles (1 if not TMULTI) */
  
  fwrite(f, fxtype, 'uint8');  %   BYTE   fxtype; /* Type of X units (see definitions below) */
  fwrite(f, fytype, 'uint8');  %   BYTE   fytype; /* Type of Y units (see definitions below) */
  fwrite(f, fztype, 'uint8');  %   BYTE   fztype; /* Type of Z units (see definitions below) */
  fwrite(f, 0,'uint8');        %   BYTE   fpost;  /* Posting disposition (see GRAMSDDE.H) */
  bindate = getbindate(data.date);
  fwrite(f, bin2dec(bindate),'uint32');    %   DWORD  fdate;  /* Date/Time LSB: min=6b,hour=5b,day=5b,month=4b,year=12b */
  fres    = [repmat('-', 1, 8) char(0)];
  fwrite(f, fres, 'char');     % char fres[9]; /* Resolution description text (null terminated) */
  fsrc    = [repmat('-', 1, 8) char(0)];
  fwrite(f, fsrc, 'char');     % char fsource[9]; /* Source instrument description text (null terminated) */
  fwrite(f, 0,'uint16');       % WORD fpeakpt; /* Peak point number for interferograms (0=not known) */
  fspare  = repmat(0, 1, 8);
  fwrite(f, fspare,'float32'); % float fspare[8]; /* Used for Array Basic storage */
  fcmnt    = repmat(char(0), 1, 130);
  if ~isempty(data.description)
    desclen = numel(data.description);
    dsodesc = reshape(data.description', 1, desclen);
    cappedlen = min(desclen, 129);
    fcmnt(1:cappedlen)   = dsodesc(1:cappedlen);    % use DSO description
  elseif ~isempty(data.name)
    str = ['Dataset: ' data.name];
    desclen = numel(str);
    dsodesc = reshape(str', 1, desclen);
    cappedlen = min(desclen, 129);
    fcmnt(1:cappedlen)   = dsodesc(1:cappedlen);    % use DSO description
  end
  fwrite(f, fcmnt, 'char');    % char fcmnt[130]; /* Null terminated comment ASCII text string */

  fwrite(f, fcatxt,'char');     % char fcatxt[30]; /* X,Y,Z axis label strings if ftflgs=TALABS */
  
  fwrite(f, 0,'uint32');   % DWORD flogoff; /* File offset to log block or 0 (see above) */
  fwrite(f, 1,'uint32');   % DWORD fmods; /* File Modification Flags (see below: 1=A,2=B,4=C,8=D..) */
  fwrite(f, 0, 'uint8');   % BYTE  fprocs  /* Processing code (see GRAMSDDE.H) */
  fwrite(f, 0, 'uint8');   % BYTE  flevel  /* Calibration level plus one (1 = not calibration data) */
  fwrite(f, 0, 'uint16');  % WORD  fsampin /* Sub-method sample injection number (1 = first or only ) */
  fwrite(f, 0, 'float32'); % float ffactor /* Floating data multiplier concentration factor (IEEE-32) */
  fwrite(f, 0, 'char');    % char  fmethod =
  fwrite(f, 0, 'float32'); % float fzinc   Note: Set=0 so z inc etc is calculated from subfiles' subtime/subnext
  fwrite(f, 0, 'uint32');  % DWORD fwplanes
  fwrite(f, 0, 'float32'); % float fwinc
  fwrite(f, 0, 'uint8');   % BYTE fwtype
  fwrite(f, repmat(0, 1, 187),'char');   % char freserv
  
  % pad out to 512 bytes for header total
  % From spc.h: Note that the new format header has 512 bytes
  augm = 512-ftell(f);
  fwrite(f, uint8(repmat(0, 1, augm)), 'uint8');
  
  if ftflgs_bin(7)
    error('Writing SPC sub-files with differently spaced x-axes not supported. Break into separate sub-files')
  end
  
  %create or read x-axis
  if ftflgs_bin(8);
    fwrite(f,ax,'float32');   %write axisscale{2} (float format)
  end
  
  %repeat below for each ROW of data (known as "traces" in the SPC file)
  for traceindex = 1:m;
    fwrite(f,8,'uint8');		%   BYTE  subflgs;	/* Flags as defined below */
    %define SUBCHGD 1	      % /* Subflgs bit if subfile changed */
    %define SUBNOPT 8	      % /* Subflgs bit if peak table file should not be used */
    %define SUBMODF 128	    % /* Subflgs bit if subfile modified by arithmetic */
    fwrite(f,128,'uint8');  %   char   fexp;   /* Fraction scaling exponent integer (80h=>float) */
    ti     = traceindex;
    subind = ti -1;
    fwrite(f, subind,'uint16');		%   WORD  subindx;	/* Integer index number of trace subfile (0=first) */
    fwrite(f, ay(ti),'float32');	%   float subtime;	/* Floating time for trace (Z axis corrdinate) */
    
    % Unless this capability is required, the value of the subnext parameter should be set to null, or
    % set to the same value as the subtime. However, if the multifile is set up to have an evenly
    % spaced Z axis and the fzinc parameter is null, then the subtime and subnext values in the
    % very first subfile must be set to different values to indicate the Z value spacing.
    if ti==1 & m>1
      fwrite(f, ay(ti+1),'float32');		%   float subnext;	/* Floating time for next trace (May be same as beg) */
    else
      fwrite(f, ay(ti),'float32');		%   float subnext;	/* Floating time for next trace (May be same as beg) */
    end
    
    fwrite(f, 0,'float32');		%   float subnois;	/* Floating peak pick noise level if high byte nonzero*/
    fwrite(f, 0,'uint32');		%   DWORD subnpts;	/* Integer number of subfile points for TXYXYS type*/
    fwrite(f, 0,'uint32');		%   DWORD subscan;	/*Integer number of co-added scans or 0 (for collect)*/
    fwrite(f, repmat(0, 1, 8),'uint8');		%   char  subresv[8];	/* Reserved area (must be set to zero) */
    fwrite(f,data.data(traceindex,:),'float32');   %Read current subfile (float format)
    
  end

  %prepare audit log info
  txtlog = {
    sprintf('name=%s',data.name)
    sprintf('author=%s',data.author)
    sprintf('type=%s',data.type)
    sprintf('date=%s',datestr(data.date,31))
    sprintf('moddate=%s',datestr(data.moddate,31))
    };
  
  if strcmpi(data.type,'image')
    imsz = sprintf('%i,',data.imagesize);
    immodes = length(data.imagesize);
    imsz = imsz(1:end-1);  %drop last ,
    imorder = ['xyz' 'a'+(0:(immodes-4))];
    imorder = imorder(1:immodes);  %get the characters we need
    txtlog = [txtlog;
      sprintf('imagesize=%s',imsz)
      sprintf('imageorder=%s',imorder)
      ];
  end
  txtlog = sprintf('%s\n',txtlog{:});
  
  %write log info
  logsizd = length(txtlog)+64;
  logsizm = ceil(logsizd/4096)*4096;
  logbins = 0;   %no binary data before log
  logdsks = 0;   %no binary data after log
  logtxto = logbins+64;  %normally logbins + 64 but we are not storing any log binary data 
  fwrite(f,logsizd,'uint32');    % DWORD logsizd; /* byte size of disk block */
  fwrite(f,logsizm,'uint32');    % DWORD logsizm; /* byte size of memory block */
  fwrite(f,logtxto,'uint32');    % DWORD logtxto; /* byte offset to text */
  fwrite(f,logbins,'uint32');    % DWORD logbins; /* byte size of binary area (immediately after logstc) */
  fwrite(f,logdsks,'uint32');    % DWORD logdsks; /* byte size of disk area (immediately after logbins) */
  fwrite(f,zeros(1,44),'uint8'); % char logspar[44]; /* reserved (must be zero) */
  
  fwrite(f,txtlog,'char');
  
  fclose(f);
catch
  err = lasterror;
  try
    %make sure the file gets closed
    fclose(f);
  catch
  end
  rethrow(err);
end

%----------------------------------------------------
function units = definexunits
%axisscalename{2}

units = {
  0,'Arbitrary Intensity'
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
%"units" (no DSO equivalent)

units = {
  0,'Arbitrary'
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

%-------------------------------------------------------
function bindate = getbindate(s)
% convert 1x6 double date to SPC 32-binary representation, as
%/* Date/Time LSB: min=6b,hour=5b,day=5b,month=4b,year=12b */
% s         = data.date;
year = datestr(datenum(s(1),s(2),s(3),s(4),s(5),s(6)),'yyyy');
mon  = datestr(datenum(s(1),s(2),s(3),s(4),s(5),s(6)),'mm');
day  = datestr(datenum(s(1),s(2),s(3),s(4),s(5),s(6)),'dd');
hour = datestr(datenum(s(1),s(2),s(3),s(4),s(5),s(6)),'HH');
min  = datestr(datenum(s(1),s(2),s(3),s(4),s(5),s(6)),'MM');
sec  = datestr(datenum(s(1),s(2),s(3),s(4),s(5),s(6)),'SS');
%
byear = dec2bin(str2num(year), 12);
bmon  = dec2bin(str2num(mon), 4);
bday  = dec2bin(str2num(day), 5);
bhour = dec2bin(str2num(hour), 5);
bmin  = dec2bin(str2num(min), 6);
% bsec  = dec2bin(str2num(sec));
bindate = [byear bmon bday bhour bmin];
