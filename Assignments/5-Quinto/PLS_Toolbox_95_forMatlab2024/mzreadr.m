function out = mzreadr(filenames,options)
%MZREADR Reads MZ5 (.mz5) Mass Spec files.
%  Imports data via implementation of the PSI mzML ontology that is
%  based on HDF5.
%  
% INPUT:
%   filename = a text string with the name of a (.mz5) file or
%              a cell of strings of filenames. NOTE: Only single file is
%              supported at this time.
%     If (filename) is omitted or an empty cell or array, the user will be
%     prompted to select a folder and then one or more files in the
%     identified folder. If (filename) is a blank string '', the user will
%     be prompted to select a single file.
%
%     NOTE: Only single file per import is supported currently.
%
% OPTIONAL INPUTS:
%   options = an options structure containing one or more of the following
%    fields:
%       nonmatching : [ 'error' |{'matchvars'} 'cell'] Governs behavior 
%                      when multiple files are being read which cannot be
%                      combined due to mismatched types, sizes, etc.
%                      'matchvars' returns a dataset object,
%                      'cell' returns cell (see outputs, below), 
%                      'error' gives an error.
%        multiselect : [ 'off' | {'on'} ] governs whether file selection
%                      dialog should allow multiple files to be selected
%                      and imported. Setting to 'off' will restrict user to
%                      importing only one file at a time.
%
%
% OUTPUT:
%   x = DSO with data.
%
%I/O: x = mzreadr    
%I/O: x = mzreadr(filename,options)
%I/O: x = mzreadr({'filename' 'filename2'},options)
%
%See also: ASDREADR, ASFREADR, MATCHVARS, EDITDS, HJYREADR, JCAMPREADR, PDFREADR, SPAREADR, SPCREADR, WRITEASF, TEXTREADR

%Copyright Eigenvector Research, Inc. 2015
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%check for evriio input
if nargin==1 && ischar(filenames) && ismember(filenames,evriio([],'validtopics'));
  options = [];
  options.nonmatching = 'matchvars';
  options.multiselect = 'off';
  options.massoffset = 0;
  options.chunksize  = 1.5;
  options.massres    = 1.0;
  options.smartcutoff = true;
  if nargout==0; clear out; evriio(mfilename,filenames,options); else out = evriio(mfilename,filenames,options); end
  return;
end

% parse other possible inputs
% no inputs? set input = '' (to trigger single file read)
if nargin==0;
  filenames = '';
end
%check if there are options and reconcile them as needed
if nargin<2
  %no options!?! use empty
  options = [];
end
options = reconopts(options,mfilename);

out = [];

% if no file list was passed
if isempty(filenames)
  %do actual read for filename
  [filenames, pathname, filterindex] = evriuigetfile({'*.mz5', 'MZ5  Mass Spec (*.mx5)'; '*.*', 'All files'}, 'Open OMNIC spectral file','MultiSelect', options.multiselect);
  if filterindex==0
    out = [];
    return
  else
    %got one or more filenames, add path to each
    if ~iscell(filenames)
      filenames = {filenames};
    end
    for lll = 1:length(filenames)
      filenames{lll} = fullfile(pathname,filenames{lll});
    end
  end

end

switch class(filenames)

  case 'char'
    % Only for the case where user passes explicit string (maybe with
    % wildcards) Does it contains a wild card?
    wild_card_pat = '[\*\?]';
    if regexp(filenames, wild_card_pat)
      % wild card character identified
      target_path = fileparts(filenames);
      if isempty(target_path)
        target_path = pwd;
      end
      dir_files = dir(filenames);
      filenames = {dir_files.name}; filenames = filenames(:)';
      for lll = 1:length(filenames)
        filenames{lll} = fullfile(target_path,filenames{lll});
      end
    else
      % turn single string into a string inside a cell
      filenames = {filenames};
    end

  case 'cell'
    % filenames is a cell already... don't need to do anything...

  otherwise
    error('incorrect input format');

end

%Warning that we can only load one file at a time now.
if length(filenames)>1
  evriwarndlg('MZREADR can only import one file at a time. Only the first file will be imported.','One File Only')
end

%Get attribute info.
if checkmlversion('>=','7.12')
  finfo = h5info(filenames{1}); %Newer function call has datatype included in structure.
else
  %Old call,  has no data type info so try catch fails below.
  finfo = hdf5info(filenames{1});
  finfo = finfo.GroupHierarchy;
end

%fatts = {};

%Put file info into attributes, saved in .userdata.
% [junk,junk,fext] = fileparts(finfo.Filename);

% fatts{1,1} = 'FileName';
% fatts{1,2} = finfo.Filename;
mydata = [];
spectrum_index = h5read(filenames{1},'/SpectrumIndex');
mydata.spectrum_index = [[1; spectrum_index(1:end-1)+1] spectrum_index];
%SPELL SPECTRUM
mydata.spectrum_mz = h5read(filenames{1},'/SpectrumMZ');
mydata.spectrum_intensity = h5read(filenames{1},'/SpectrumIntensity');

sp = [];
for i = 1:length(finfo.Datasets)
  sp(i).name = finfo.Datasets(i).Name;
  sp(i).value = h5read(filenames{1},['/' finfo.Datasets(i).Name]);
end
mydata.other = sp;
%The call to getdso_ms doesn't work yet. 
try
  cdfdso = getdso_ms(mydata,options);
  out = cdfdso;
catch
  % Just output data as we have it.
  out = mydata;
end

% try
%   for i = 1:size(spectrum_index,1)
%     
%   end
%   
% catch
%   err = lasterror;
%   err.message = ['MZREADR: reading "' filenames{1} '"' 10 err.message];
%   rethrow(err);
%   
% end



%----------------------------------------
function cdfdso = getdso_ms(mydata,options)
%Build DSO from mass spec cdf file.

cdfdso = [];

%Use Willem code.
n_scans        = length(mydata.spectrum_index);%Total number of data points (number of rows or spectra).
n_datapoints   = length(mydata.spectrum_mz);%Total number of massess (number of columns). %SPECTRUM_MZ
row_array      = zeros(n_datapoints,1);%Init the array.
inv_res        = 1./options.massres;
column_array   = round(inv_res.*(mydata.spectrum_mz-options.massoffset))./inv_res;%Apply offset and bin
mass_axis      = unique(column_array);
num_masses     = length(mass_axis);

%CREATE ROW_ARRAY WITH ROW INDICES FOR SPARSE
index1=1;
for i=1:n_scans
  %row_array(mydata.spectrum_index(i,1):mydata.spectrum_index(i,2)-1) = ones(mydata.spectrum_index(i,2)-mydata.spectrum_index(i,1),1)*i;
  id1= mydata.spectrum_index(i,1);
  id2= mydata.spectrum_index(i,2);
  row_array(id1:id2-1) = ones(id2-id1,1)*i;
%   if mydata.point_count(i);
%     %a=repmat(i,mydata.point_count(i),1);
%     a                        =ones(mydata.point_count(i),1)*i;
%     %Use ones() instead of repmat helps speed by 25%.
%     index2                   = index1+length(a)-1;%Offset in raw vector.
%     row_array(index1:index2) = a;%Row number.
%     index1                   = index2+1;
%   end;
end;

%row_array(end) = n_scans;
% Replace 0's with values (like in the commented line above).
j=1;
for i=1:length(row_array)
  if (row_array(i) == 0)
    row_array(i)=j;
    j=j+1;
  end
end

% row_array        = [row_array; n_scans];
% % column_array=double([column_array; column_array(end)]);
% column_array     = [column_array; column_array(end)];
% intensity_values = double([mydata.intensity_values ; 0]); %SEPCTRUM_INTENSITY

intensity_values = double(mydata.spectrum_intensity);

%Iterate through data using sparse to be memory friendly.
data     = zeros(n_scans, num_masses);%Create initial array.
%iter = floor(length(intensity_values)/options.chunksize);%Cut data into 1/chunksize chuncks. 
startidx = 1;

while startidx<=length(intensity_values)
  endidx = startidx+options.chunksize*1000000;
  if endidx>length(intensity_values)
    endidx = length(intensity_values);%Make last iteration to the end of the data.
  end
  cur_masses          = column_array(startidx:endidx);
  [~, mass_axis_inds] = ismember(cur_masses, mass_axis);
  subdata             = sparse(row_array(startidx:endidx), ...
    mass_axis_inds,intensity_values(startidx:endidx),n_scans, num_masses);
  data                = data+subdata;
  startidx            = endidx+1;
end

%Comment out this old code, it can be memory inefficient.
%   data=dataset(full(sparse(row_array,column_array,intensity_values)));
cdfdso                    = dataset(data);

%TODO: Get correct scan aquisition rate for proper axisscale!
%cdfdso.axisscale{1,1}     = mydata.scan_acquisition_time/60;
cdfdso.axisscale{1,1}     = 0:1:size(data,1)-1; %placeholder, not correct
cdfdso.axisscalename{1,1} = 'elapsed time, mins.';

cdfdso.axisscale{2,1}       = double(mass_axis);
cdfdso.axisscalename{2,1}   = 'm/z, amu';

% The lines below, uncomment and add slowly adding things.
% %Add globals to description field.
mydescription = '';
% %fn = fieldnames(mydata.globals);
fn = fieldnames(mydata.other(17).value);
for i = 1:length(fn)-1
%   %sp            = {mydata.globals.(fn{i})};
   sp            = {mydata.other(17).value.(fn{i})};
   ind           = find(~cellfun(@isempty, sp));
   sp            = sp{ind};
   if isnumeric(sp)
     sp = num2str(sp);
   end
%   %mydescription = strvcat(mydescription,[fn{i} ' = ' sp]);
   mydescription = strvcat(mydescription,cell2str([fn{i} ' = ' sp]));
 end
cdfdso.description = mydescription;
% 
desc_cell = str2cell(cdfdso.description);
pat{1}    = 'experiment_date_time_stamp';
% pat{2}    = '([0-9]{14})([+-]0{0,})([1-9])';
pat{2}    = '([0-9]{14})([+-][0-9]{2})([0-9]{2})';
ind        = find(~cellfun('isempty', regexp(desc_cell, pat{1})));

if ~isempty(ind)
  cur_str    = desc_cell{ind};
  strtoks    = regexp(cur_str, pat{2}, 'tokens');
  strtoks    = [strtoks{:}];
  expt_start = datenum(strtoks{1}, 'yyyymmddHHMMSS');

  dt_num     = expt_start + cdfdso.axisscale{1,1}/(24*60);
  hrs_offset = str2num(strtoks{2});
  min_offset = str2num(strtoks{3});

  cdfdso.axisscale{1,2}     = dt_num;

  dt_num                    = arrayfun(@(x)addtodate(x, -hrs_offset, 'hour'), dt_num);
  dt_num                    = arrayfun(@(x)addtodate(x, ...
    -sign(hrs_offset)*min_offset, 'minute'), dt_num);
  cdfdso.axisscale{1,3}     = dt_num;
end

cdfdso.axisscalename{1,2} = 'date and time, local';
cdfdso.axisscalename{1,3} = 'date and time, GMT';

% remove any columns that have response of zero for all samples
% zero_inds    = find(sum((cdfdso.data==0),1)==n_scans);
% cdfdso       = delsamps(cdfdso, zero_inds, 2, 2);

% Get indicies to remove the nonsense columns.
smdata = cdfdso.data(1:3,:);
m = mean(smdata,2);
for i = 1:size(smdata,1)
  try
    s(i,1) = std(smdata(i,:));
  catch
    s(i,1) = 0;
  end
end

% Determine which of the 3 datapoints is actual data (for offset).
for i = 1:length(m)
  mg = floor(log10(m(i)));
end
[val, idx] = max(mg);
rm_offset = idx-1;

if (options.smartcutoff)
  
% Remove the anomolous tailing at the end of the dataset.
%h = waitbar(0,sprintf('Scanning MZ 0/%d',size(cdfdso.data,2)));
data_t=sum(cdfdso.data,2);
data_s=std(cdfdso.data,0,2);
deriv_t=zeros(size(cdfdso.data,1)-1,1);%size(cdfdso.data,2));
deriv_s=deriv_t;
%dderiv_t=zeros(size(deriv_t,1)-1,1);
dderiv_s=zeros(size(deriv_t,1)-1,1);

  for i = 1:(size(deriv_t,1))
    deriv_t(i,1)= data_t(i+1,1)- data_t(i,1);%/(i + 1 - i);
    deriv_s(i,1)= data_s(i+1,1)- data_s(i,1);
  end
  clear data_t data_s;

% Check the Derivatives
val_b=0;
tpts=[0 0 0];
for i=1:(size(deriv_t,1)-2)
  tpts = deriv_t(i:i+2,1);
    if (tpts(1) > 0 & tpts(2) > 0 & tpts(3) > 0)
      val_b=i;
      break;
    end
end
clear deriv_t;
  
  for i = 1:(size(dderiv_s,1))
    %dderiv_t(i,1) = deriv_t(i+1,1) - deriv_t(i,1);
    dderiv_s(i,1)= deriv_s(i+1,1)- deriv_s(i,1);
  end
%lgdderiv_t = log(abs(dderiv_t));
lgdderiv_s = log(abs(dderiv_s));
%lgdderiv_t(lgdderiv_t<0) = 0;
for i = 1:(size(lgdderiv_s,1)-1)
  %dderiv_t_d(i,1) = lgdderiv_t(i+1,1) - lgdderiv_t(i,1);
  dderiv_s_d(i,1) = lgdderiv_s(i+1,1) - lgdderiv_s(i,1);
end

clear lgdderiv_s;

dderiv_s_d(dderiv_s_d > -6)=0; % Hard cropping
val_a=find(dderiv_s_d);
val_a= val_a(1); % get first index.
if abs(val_a - val_b) < 10
  cdfdso((min([val_a, val_b])+1):end,:)=[];
else
  cdfdso((val_a+1):end,:)=[];
end

% TODO: allow user set a cutoff point (convert minutes to datapoints).
end

% Gather & remove indexes with near 0 data.
rm_count = 0;
rm_idxs = [];
for i = 1:size(cdfdso.data,1)
  if (rm_count ~= rm_offset)
    rm_idxs= [rm_idxs i];
  end
if(rm_count+1 >= 3)
  rm_count = 0;
else
  rm_count = rm_count+1;
end
end

cdfdso = delsamps(cdfdso, rm_idxs, 1, 2);


%--------------------------------------------
function test
%Test code.

%Show two MS levels in plot:

%rawdata = mzreadr('/Users/scott/Dropbox/Work/EVRI - software development team/MZREADR_BioGEN/ExampleFiles/RMC561S_IMB8minusAsnN_LCMST_SP_1.mz5');
rawdata = mzreadr('C:\Users\Benjamin\Dropbox\EVRI - software development team\MZREADR_BioGEN\ExampleFiles\RMC560S_IMB8minusRiboflavinN_LCMST_SP_1.mz5');
rawdata = mzreadr('C:\Users\Benjamin\Dropbox\EVRI - software development team\MZREADR_BioGEN\ExampleFiles\RMC562S_IMB8minusMetN_LCMST_SP_1.mz5');

rawdata = mzreadr('C:\Users\Benjamin\Dropbox\EVRI - software development team\MZREADR_BioGEN\ExampleFiles\RMC561S_IMB8minusAsnN_LCMST_SP_1.mz5');
ctime = rawdata.other(3).value;
cintensity = rawdata.other(5).value;

plotgui(cintensity,'plottype','scatter');


%Scan fileinfo for available datasets.
%filenames{1} = '/Users/scott/Dropbox/Work/EVRI - software development team/MZREADR_BioGEN/ExampleFiles/RMC561S_IMB8minusAsnN_LCMST_SP_1.mz5';
filenames{1} = 'C:\Users\Benjamin\Dropbox\EVRI - software development team\MZREADR_BioGEN\ExampleFiles\RMC561S_IMB8minusAsnN_LCMST_SP_1.mz5';
finfo = h5info(filenames{1});

sp = [];
for i = 1:length(finfo.Datasets)
  sp(i).name = finfo.Datasets(i).Name;
  sp(i).value = h5read(filenames{1},['/' finfo.Datasets(i).Name]);
end

[num2cell([1:length(finfo.Datasets)]') {finfo.Datasets.Name}' {finfo.Datasets.ChunkSize}' {finfo.Datasets.Dataspace}' {finfo.Datasets.Datatype}' {finfo.Datasets.FillValue}' {finfo.Datasets.Filters}' {finfo.Datasets.Attributes}']
% ans = 
% 
%     [ 1]    'CVParam'                [5000]    [1x1 struct]    [1x1 struct]    [1x1 struct]    [1x2 struct]    []
%     [ 2]    'CVReference'                []    [1x1 struct]    [1x1 struct]              []              []    []
%     [ 3]    'ChomatogramTime'        [1000]    [1x1 struct]    [1x1 struct]    [         0]    [1x2 struct]    []
%     [ 4]    'ChromatogramIndex'          []    [1x1 struct]    [1x1 struct]    [         0]              []    []
%     [ 5]    'ChromatogramInten?'     [1000]    [1x1 struct]    [1x1 struct]    [         0]    [1x2 struct]    []
%     [ 6]    'ChromatogramList'           []    [1x1 struct]    [1x1 struct]              []              []    []
%     [ 7]    'ChromatogramListB?'         []    [1x1 struct]    [1x1 struct]    [1x1 struct]              []    []
%     [ 8]    'ControlledVocabul?'         []    [1x1 struct]    [1x1 struct]              []              []    []
%     [ 9]    'DataProcessing'             []    [1x1 struct]    [1x1 struct]              []              []    []
%     [10]    'FileContent'                []    [1x1 struct]    [1x1 struct]    [1x1 struct]              []    []
%     [11]    'FileInformation'            []    [1x1 struct]    [1x1 struct]    [1x1 struct]              []    []
%     [12]    'InstrumentConfigu?'         []    [1x1 struct]    [1x1 struct]              []              []    []
%     [13]    'ParamGroups'                []    [1x1 struct]    [1x1 struct]              []              []    []
%     [14]    'RefParam'                   []    [1x1 struct]    [1x1 struct]    [1x1 struct]              []    []
%     [15]    'Run'                        []    [1x1 struct]    [1x1 struct]              []              []    []
%     [16]    'Software'                   []    [1x1 struct]    [1x1 struct]              []              []    []
%     [17]    'SourceFiles'                []    [1x1 struct]    [1x1 struct]              []              []    []
%     [18]    'SpectrumIndex'          [2000]    [1x1 struct]    [1x1 struct]    [         0]    [1x2 struct]    []
%     [19]    'SpectrumIntensity'      [5000]    [1x1 struct]    [1x1 struct]    [         0]    [1x2 struct]    []
%     [20]    'SpectrumListBinar?'     [2000]    [1x1 struct]    [1x1 struct]    [1x1 struct]    [1x2 struct]    []
%     [21]    'SpectrumMZ'             [5000]    [1x1 struct]    [1x1 struct]    [         0]    [1x2 struct]    []
%     [22]    'SpectrumMetaData'       [2000]    [1x1 struct]    [1x1 struct]              []    [1x2 struct]    []
%     [23]    'UserParam'              [ 100]    [1x1 struct]    [1x1 struct]    [1x1 struct]    [1x2 struct]    []
%
%
% List of DataSets in file:
%  1   'CVParam'
%  2   'CVReference'
%  3   'ChomatogramTime'
%  4   'ChromatogramIndex'
%  5   'ChromatogramIntensity'
%  6   'ChromatogramList'
%  7   'ChromatogramListBinaryData'
%  8   'ControlledVocabulary'
%  9   'DataProcessing'
%  10  'FileContent'
%  11  'FileInformation'
%  12  'InstrumentConfiguration'
%  13  'ParamGroups'
%  14  'RefParam'
%  15  'Run'
%  16  'Software'
%  17  'SourceFiles'
%  18  'SpectrumIndex'
%  19  'SpectrumIntensity'
%  20  'SpectrumListBinaryData'
%  21  'SpectrumMZ'
%  22  'SpectrumMetaData'
%  23  'UserParam'
% 
% sp(22).value
% ans = 
%                    id: {7206x1 cell}
%                spotID: {7206x1 cell}
%                params: [1x1 struct]
%              scanList: [1x1 struct]
%            precursors: {7206x1 cell}
%              products: {7206x1 cell}
%     refDataProcessing: [1x1 struct]
%         refSourceFile: [1x1 struct]
%                 index: [7206x1 uint32]
%
%     'CVParam'                       [     1x1 struct]
%     'CVReference'                   [     1x1 struct]
%     'ChomatogramTime'               [  7206x1 double]
%     'ChromatogramIndex'             [     2x1 uint32]
%     'ChromatogramIntensity'         [  7206x1 double]
%     'ChromatogramList'              [     1x1 struct]
%     'ChromatogramListBinaryData'    [     1x1 struct]
%     'ControlledVocabulary'          [     1x1 struct]
%     'DataProcessing'                [     1x1 struct]
%     'FileContent'                   [     1x1 struct]
%     'FileInformation'               [     1x1 struct]
%     'InstrumentConfiguration'       [     1x1 struct]
%     'ParamGroups'                   [     1x1 struct]
%     'RefParam'                      [     1x1 struct]
%     'Run'                           [     1x1 struct]
%     'Software'                      [     1x1 struct]
%     'SourceFiles'                   [     1x1 struct]
%     'SpectrumIndex'                 [  7206x1 uint32]
%     'SpectrumIntensity'             [940608x1 double]
%     'SpectrumListBinaryData'        [     1x1 struct]
%     'SpectrumMZ'                    [940608x1 double]
%     'SpectrumMetaData'              [     1x1 struct]
%     'UserParam'                     [     1x1 struct]
%
% FROM: http://proteowizard.sourceforge.net/dox/classpwiz_1_1msdata_1_1mz5_1_1_configuration__mz5.html
%
% ControlledVocabulary - Dataset for the controlled vocabulary sets.
% FileContent - File content dataset.
% Contact - Dataset containing contact infomation.
% CVReference - Dataset containing all used controlled vocabulary accessions (prefix, accession, definition).
% CVParam - Dataset containing all controlled vocabulary parameters.
% UserParam - Dataset containing all user parameters.
% RefParam - Dataset containing all referenced parameter groups.
% ParamGroups - Dataset for parameter groups.
% SourceFiles - Source file dataset.
% Samples - Sample datatset.
% Software - Software dataset.
% ScanSetting - Scan setting datatset.
% InstrumentConfiguration - Instrument configuration datatset.
% DataProcessing - Data processing dataset.
% Run - Dataset containing all meta information for all runs.
% SpectrumMetaData - Dataset containing all meta information of all spectra.
% SpectrumBinaryMetaData - Dataset containing all meta information of all binary data elements for spectra.
% SpectrumIndex - Index dataset. kth element points to the end of the kth spectrum in MZ and SIntensity.
% SpectrumMZ - Dataset containing all mz values for all spectra.
% SpectrumIntensity - Dataset containing all intensity values for all spectra.
% ChromatogramMetaData - Dataset containing all meta information of all chromatograms.
% ChromatogramBinaryMetaData - Dataset containing all meta information of all binary data elements for chromatograms.
% ChromatogramIndex - Index dataset. kth element points to the end of the kth chromatogram in Time and CIntensity.
% ChomatogramTime - Dataset containing all time values.
% ChromatogramIntensity - Dataset containing all chromatogram intensities.
% FileInformation - Dataset containing information about the file and specific dataset configurations.
%
% http://proteowizard.sourceforge.net/dox/cv_8hpp_source.html
% Definitions

% sp(20)
% ans = 
%      name: 'SpectrumListBinaryData'
%     value: [1x1 struct]
% sp(20).value.xParams
% ans = 
%      cvstart: [7206x1 uint32]
%        cvend: [7206x1 uint32]
%     usrstart: [7206x1 uint32]
%       usrend: [7206x1 uint32]
%     refstart: [7206x1 uint32]
%       refend: [7206x1 uint32]
