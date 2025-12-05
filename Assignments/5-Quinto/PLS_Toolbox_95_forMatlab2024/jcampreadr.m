function [data,wrn] = jcampreadr(fname,options)
%JCAMPREADR Reads a JCAMP file into a DataSet object
% Input is the filename of a JCAMP file to read. If omitted, the user is
% prompted for a file. This reader reads JCAMP files of type:
%         ND NMR SPECTRUM,
%         NMR SPECTRUM,
%         INFRARED SPECTRUM,
%         MASS SPECTRUM,
%         RAMAN SPECTRUM,
%         GAS CHROMATOGRAM,
%         UV/VIS SPECTRUM.
% and including any files written in JCAMP-DX format (with limited support
% for beta version 6).
% This importer uses JSpecView, a Java package which enables importing of
% files written the JCAMP-DX format. JSpecView was developed at the
% Department of Chemistry of the University of the West Indies, Mona,
% Jamaica, WI JSpecView is described in an article "The JSpecView Project:
% an Open Source Java viewer and converter for JCAMP-DX, and XML spectral
% data files" by Robert J Lancashire, which is available at:
% http://journal.chemistrycentral.com/content/1/1/31
%
% The imported files are returned in a Dataset Object, or a cell array if 
% they have differing variable axisscales, or number of variables AND the 
% nonmatching option = 'cell'.
% If the file contains peaktable(s) they are extracted and stored in the
% returned DataSet's userdata field.
%
% OPTIONAL INPUTS:
%  filename = either a string specifying the file to read, a cell
%             array of strings specifying multiple files to read, or the
%             output of the MATLAB DIR command specifying one or more files
%             to read. If (fname) is empty or not supplied, the user is
%             prompted to identify files to load.
%   options = an options structure containing the following fields:
% nonmatching : [ 'error' |{'matchvars'} 'cell'] Governs behavior 
%               when multiple files are being read which cannot be combined
%               due to mismatched types, sizes, etc.
%               'matchvars' returns a dataset object,
%               'cell' returns cell (see outputs, below), 
%               'error' gives an error.
%      display: [{'off'}| 'on' ] Governs display to the command line.
%                Warnings encountered during file load will be supressed if
%                display is 'off'.
%      waitbar: [ 'off' |{'on'}] Governs display of waitbar when doing
%                multiple file reading.
%
% OUTPUTS:
%   data = a DataSet object containing the spectrum or spectra from the
%          file(s), or an empty array if no data could be read. If the input
%          file(s) contain any peaktables these are extracted and returned
%          in the output DataSet object's userdata field.
% OUTPUT:
%   data = takes one of two forms:
%       1) If input is a single file, or multiple files containing data that
%          can be combined (same number of data points, same x-axis range,
%          same type of data), the output is a dataset object
%       2) If the input consists of multiple files containing data that
%          cannot simply be combined (different number of data points, 
%          differing x-axis ranges, etc), the output is either:
%          a cell array with a dataset object for each input file if the
%          'nonmatching' option has value 'cell', or
%          a dataset object containing the input data combined using the
%          MATCHVARS function if the 'nonmatching' option has value 
%          'matchvars'.
%   wrn  = a cell array of warnings issued during the reading of the file.
%
%
%I/O: [data,wrn] = jcampreadr(filename,options)
%
%See also: SPCREADR, TEXTREADR

%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.


%- - - - - - - - - - - - - - - - - - - - - - - - - - -
%parse inputs
if nargin==1 & ischar(fname) & ismember(fname,evriio('','validtopics'))
  options = [];
  options.nonmatching = 'matchvars';
  options.display = 'off';
  options.waitbar = 'on';
  if nargout==0; clear data; evriio(mfilename,fname,options); else; data=evriio(mfilename,fname,options); end
  return
end

switch nargin
  case 0
    % ()
    fname = [];
    options = [];
  case 1
    % (filename)
    % (options)
    % (dir(...))
    if isstruct(fname) & ~isfield(fname,'name')
      % (options)
      options = fname;
      fname = [];
    else
      options = jcampreadr('options');
    end
  case 2
    % (filename,options)
end
options = reconopts(options,mfilename);

data = {};  %start with "error" state - only replaced if we get to the end without error
wrn  = {};  %will hold missing header warnings
if isempty(fname)
  %no filename passed (or empty), prompt user
  [nm,pth]=evriuigetfile({'*.dx;*.jdx;*.jcm;*.jcamp;*.DX;*.JDX;;*.JCM;*.JCAMP' 'Readable JCAMP Files (*.dx, *.jdx, *.jcm, *.jcamp)'},'please select a JCAMP file to load','multiselect','on');
  if isnumeric(nm)
    return
  end
elseif isstruct(fname)
  % output from the DIR command (probably)
  if ~isfield(fname,'name')
    error('Input structure must be either options or the output of the "dir" command');
  end
  fname = fname(~[fname.isdir]); %remove directories from structure
  nm = {fname.name};  %convert into cell
  pth = '';
else
  nm = fname;
  pth = '';
end
if isempty(nm) | isnumeric(nm)
  return
end

%- - - - - - - - - - - - - - - - - - - - - - - - - - -
%cell array of names? Multiple files to read
if iscell(nm)
  if length(nm)==1;
    %only one name in a cell? extract and use it as-is
    nm = nm{1};
  else
    %more than one name in cell? concatenate all items
    try
      start = now;
      h = [];
      for j=1:length(nm)
        %read in one file
        [filename,nm{j}] = testopen(nm{j},pth);
        [onefile,onewarn] = jcampreadr(filename);
        
        if j>1 & size(data{1},2)~=size(onefile,2);
          if strcmp(options.nonmatching,'error')
            error('File "%s" has a different number of variables than the previous file(s) and cannot be combined',nm{j});
          end
        end
        onefile.label{1} = repmat(nm{j},size(onefile,1),1);
        onefile.name = '';

        if strcmp(options.nonmatching, 'cell')
          onefile = addsourceinfo(onefile,nm{j});
        end
        data{j} = onefile;
        wrn = [wrn onewarn];
        
        %show waitbar if it is a long load
        if ishandle(h)
          waitbar(j/length(nm),h);
        elseif ~isempty(h) & ~ishandle(h)
          error('User cancelled operation')
        elseif strcmp(options.waitbar,'on') & (now-start)>1/60/60/24
          h = waitbar(0,'Loading JCAMP Files...');
        end
      end
    catch
      le = lasterror;
      if ishandle(h);
        delete(h);
      end
      le.message = [sprintf('Error reading %s\n',nm{j}) le.message];
      rethrow(le)
    end   
    if ishandle(h);
      delete(h);
    end
    
    if ~strcmp(options.nonmatching, 'cell')
      % apply matchvars if not 'cell' case
      data = matchvars(data);
      data = addsourceinfo(data,nm);
      data.name = 'Multiple JCAMP files';
    end
    return
  end
end

%- - - - - - - - - - - - - - - - - - - - - - - - - - -
%read in a JCAMP file
[filename,nm] = testopen(nm,pth);

% read single file
[data,wrn] = jspecviewer(filename);
if ~isempty(data)
  data.name = nm;
  data.description = ['Read from: ' filename];
  data = addsourceinfo(data,filename);
end

%show warnings...
if ~isempty(wrn) & strcmp(options.display,'on')
  if length(wrn)>11;
    disp(char(wrn(1:10)));
    disp(sprintf('-- %i Additional Warnings Not Shown --',length(wrn)-10));
  else
    disp(char(wrn));
  end
end

%--------------------------------------------------------------------------
function [filename,nm] = testopen(nm,pth)
%reconciles path on input filename and additional path info (if present)
%tests file to make sure it is readable
%OUTPUTS:
%  filename = fully qualified filename appropriate to put into java reader
%  nm = input nm filename stripped of any path

[fpth,base,ext] = fileparts(nm);
nm = [base ext];
if isempty(fpth)
  %no path on filename? use pth or pwd
  if isempty(pth)
    pth = pwd;
  end
else
  %use path on the filename if present
  pth = fpth;
end
filename = fullfile(pth,nm);
[fid,msg] = fopen(filename,'r');
if fid<0
  error(['Unable to open file - ' msg]);
end
fclose(fid);

%--------------------------------------------------------------------------
function [dso, wrn] = jspecviewer(ffile)
% Extracts spectrum into a DataSet. Peaktables are saved to the DataSet
% userdata field.
%   datatype  % e.g. UV/VIS SPECTRUM
%   dataclass % e.g. XYPOINTS

if ~exist('evri.application.JdxReader')
  evrijavasetup;
end
wrn = [];

reader = evri.application.JdxReader;
% Must set Log level to Error or Fatal to avoid non-essential output
reader.setLogLevel(jspecview.util.Logger.LEVEL_ERROR);
% methods(reader)
source = reader.readFile(ffile);
% methods(source);
nspectra = source.getNumberOfSpectra;

% Get similar spectra (xydata) and any peaktables.
[xydata, peaktable] = getlengthtypeclass(source);

dso = dataset;
if ~isempty(xydata)
  npoints = xydata.npoints;
  nspectra = sum(xydata.mask);
  
  xaxis    = nan(nspectra,npoints);
  xvals    = nan(nspectra,npoints);
  title   = {};

  for ii=find(xydata.mask)
    spec = source.getJDXSpectrum(ii-1);     % -1 because Java object
    title{ii} = char(spec.getTitle);
    datatype{ii} = char(spec.getDataType);
    xunits{ii} = char(spec.getXUnits);
    yunits{ii} = char(spec.getYUnits);
    origin{ii} = char(spec.getOrigin);
    owner{ii} = char(spec.getOwner);
    longdate{ii} = char(spec.getLongDate);  % YYYY/MM/DD [HH:MM:SS[.SSSS] [±UUUU]]
    date{ii}     = char(spec.getDate);      % form: YY/MM/DD
    time{ii}     = char(spec.getTime);      % form: HH:MM:SS
   
    % Extract data from Coordinate[] in Java is x30 faster than in matlab
    xvals(ii,:) = reader.getYVals(spec);
    if ii==1
      xaxis(ii,:) = reader.getXVals(spec);
    end

    % Look in header row for ##CONCENTRATIONS
    headmap = getHeaderMap(spec);
    if headmap.isKey('##CONCENTRATIONS')
      concentrations{ii} = headmap('##CONCENTRATIONS');
    else
      concentrations{ii} = [];
    end
  end
  [m1axisscalenames, m1axisscales] = converttoaxisscales(concentrations);
  
  xaxisscale = xaxis(1,:);
  dso.data = xvals;
  if ~isempty(m1axisscalenames) & ~isempty(m1axisscales)
    for ii=1:length(m1axisscalenames)
      dso.axisscalename{1,ii} = m1axisscalenames{ii};
      dso.axisscale{1,ii}     = m1axisscales(m1axisscalenames{ii});
    end
  end
  
  dso.axisscale{2} = xaxisscale;
  dso.label{1}     = char(title);
  
  dso.axisscalename{2} = xunits{1};
  dso.labelname{1,2} = 'Title';
  dso.label{1,2} = title;
  dso.labelname{1,3} = 'DataType';
  dso.label{1,3} = datatype;
  dso.labelname{1,4} = 'XUnits';
  dso.label{1,4} = xunits;
  dso.labelname{1,5} = 'YUnits';
  dso.label{1,5} = yunits;
  dso.labelname{1,6} = 'Origin';
  dso.label{1,6} = origin;
  dso.labelname{1,7} = 'Owner';
  dso.label{1,7} = owner;
  dso.labelname{1,8} = 'LongDate';
  dso.label{1,8} = longdate;
  dso.labelname{1,9} = 'Date';
  dso.label{1,9} = date;
  dso.labelname{1,10} = 'Time';
  dso.label{1,10} = time;
end

% Check for peaktables. Add any to DSO.userdata
if ~isempty(peaktable)
  ipeaktables = find(peaktable.mask);
  for ii=ipeaktables
    spec = source.getJDXSpectrum(ii-1);     % -1 because Java object
    title{ii} = char(spec.getTitle); %sprintf('%s_%d', char(spec.getTitle), ii-1);
    datatype{ii} = char(spec.getDataType);
    xunits{ii} = char(spec.getXUnits);
    yunits{ii} = char(spec.getYUnits);
    origin{ii} = char(spec.getOrigin);
    owner{ii} = char(spec.getOwner);
    ptyvals{ii} = reader.getYVals(spec);
    ptxvals{ii} = reader.getXVals(spec);
  end
  % Merge peaktables into a union over all
  ptxall = [];
  ntables = length(ptxvals);
  for ii=1:ntables
    ptxall = union(ptxall, ptxvals{ii});
  end
  nptxall = length(ptxall);
  xyall = zeros(ntables, nptxall);
  % fill in the y values
  for ii=1:ntables
    [ispres inds] = ismember(ptxvals{ii}, ptxall);
    xyall(ii, inds) = ptyvals{ii};
  end
  
  ptdso = dataset(xyall);
  ptdso.axisscale{2} = ptxall;
  ptdso.axisscalename{2} = xunits{1};
  ptdso.labelname{1,2} = 'Title';
  ptdso.label{1,2} = title;
  ptdso.labelname{1,3} = 'DataType';
  ptdso.label{1,3} = datatype;
  ptdso.labelname{1,4} = 'XUnits';
  ptdso.label{1,4} = xunits;
  ptdso.labelname{1,5} = 'YUnits';
  ptdso.label{1,5} = yunits;
  ptdso.labelname{1,6} = 'Origin';
  ptdso.label{1,6} = origin;
  ptdso.labelname{1,7} = 'Owner';
  ptdso.label{1,7} = owner;
  % Save the peaktables DSO to userdata
  dso.userdata.peaktable = ptdso;
end

if size(dso,1)>1
  [pth,nm] = fileparts(ffile);
  dso.label{1,1} = repmat(nm,size(dso.data,1),1);
  dso.labelname{1,1} = 'Filename';
end

% Return dso containing xydata in data field and peaktable in
% userdata.peaktable field. However, if xydata is empty but is peaktable
% is not then just return the peaktable dso (with peak data in data field)
if isempty(xydata)
  if isempty(peaktable)
    dso = [];
    wrn = sprintf('Input file contains no spectra or peaktables (%s)', ffile);
  else
    % no xydata but peaktable has values
    dso = ptdso;
  end
end

%--------------------------------------------------------------------------
function [xydata, peaktable] = getlengthtypeclass(source)
% Find spectra (XYDATA) and returns indices of their location. Throws error
% if spectra with different numbers of wavelengths are found.
% Also finds peaktables (PEAKTABLE) and returns indices of their location.
nspectra = source.getNumberOfSpectra;
npoints = 0;
types   = {};
classes = {};
mask_xydata              = zeros(1,nspectra);
mask_peaktable           = zeros(1,nspectra);
xydata.mask       = mask_xydata;
peaktable.mask = mask_peaktable;
ixy   = 0;
ipeak = 0;
for ii=1:nspectra
  spec = source.getJDXSpectrum(ii-1);  % use -1 because Java object
  if strcmp(char(spec.getDataClass), 'XYDATA') | strcmp(char(spec.getDataClass), 'XYPOINTS')
    mask_xydata(ii) = 1;
    ixy = ixy+1;
    npoints(ixy) = spec.getNumberOfPoints;
    types{ixy}   = char(spec.getDataType);
    classes{ixy} = char(spec.getDataClass);
  elseif strcmp(char(spec.getDataClass), 'PEAKTABLE')
    mask_peaktable(ii) = 1;
    ipeak = ipeak+1;
  end
end
if sum(mask_xydata)>0
  if length(unique(npoints))>1
    error('The %d spectra do not all have the same numberOfPoints', nspectra)
  end
  npoints = npoints(1);
  if length(unique(types))>1
    error('The %d spectra do not all have the same dataType', nspectra)
  end
  datatype  = types{1};
  if length(unique(classes))>1
    error('The %d spectra do not all have the same dataClass', nspectra)
  end
  dataclass  = classes{1};
  
  xydata.npoints   = npoints;
  xydata.datatype  = datatype;
  xydata.dataclass = dataclass;
  xydata.mask      = mask_xydata;
else
  xydata = [];
end
if sum(mask_peaktable)>0
  peaktable.mask   = mask_peaktable;
else
  peaktable = [];
end

%--------------------------------------------------------------------------
function [headmap] = getHeaderMap(spec)
  % Get header row contents as a map
headerarray = spec.getHeaderRowDataAsArray;
headmap = containers.Map;
for ii=1:size(headerarray,1)
  tmp = char(headerarray(ii));
  key = strtrim(tmp(1,:));
  val = strtrim(tmp(2,:));
  headmap(key) = val;
end

%--------------------------------------------------------------------------
function [axisscalenames, axisscalevals] = converttoaxisscales(conc)
% Using ##CONCENTRATIONS elements
% extract axisscale names and values as a union over all samples

nsamp = length(conc);
axisscalevals = containers.Map;

keysall = [];
for ii=1:nsamp
  c1 = conc{ii};
  if ~isempty(c1) 
    lns =  extractBetween(c1, '(', ')');
    [tmpmap] = getaxesinfo(lns);
    keys_i = tmpmap.keys;
    keysall = [keysall keys_i];
  end
end
keysuniq = unique(keysall);

if ~isempty(keysuniq)
  for asname = keysuniq
    axisscalevals(asname{1}) = [];
  end

  for ii = 1:nsamp
    c1 = conc{ii};
    if ~isempty(c1)
      lns = extractBetween(c1, '(', ')');
      [map_i] = getaxesinfo(lns);
      for asname = keysuniq
        if map_i.isKey(asname{1})
          axisscalevals(asname{1}) = [axisscalevals(asname{1}) map_i(asname{1})];
        else
          axisscalevals(asname{1}) = [axisscalevals(asname{1}) NaN];
        end
      end
    else
      for asname = keysuniq
        axisscalevals(asname{1}) = [axisscalevals(asname{1}) NaN];
      end
    end
  end
  axisscalenames = axisscalevals.keys;
else
  axisscalenames = [];
  axisscalevals  = [];
end
    
%--------------------------------------------------------------------------
function [axes1] = getaxesinfo(lns)
% convert each entry of input cell array to an axisscale name and value
% return map with key = axisscalename, value = axisscale value
naxes = length(lns);
axes1 = containers.Map;
for j = 1:naxes
  compgrp = lns{j};  % should have 3 element comma-separated form: N,C,U
  grpfields = strsplit(compgrp, ',');  
  len  = numel(grpfields);
  % 
  aname = '-';
  aval   = NaN;
  aunits = '-';
  switch len
    case 1
      aname  = strtrim(grpfields{1});
    case 2
      aname  = strtrim(grpfields{1});
      aval   = strtrim(grpfields{2});
    case 3
      aname  = strtrim(grpfields{1});
      aval   = strtrim(grpfields{2});
      aunits = strtrim(grpfields{3});
    otherwise
      % use defaults
  end
        
  axisnames{j} = [aname ' (' aunits ')'];
  axisvals{j}  = str2double(aval);
  axes1(axisnames{j}) = axisvals{j};
end
    