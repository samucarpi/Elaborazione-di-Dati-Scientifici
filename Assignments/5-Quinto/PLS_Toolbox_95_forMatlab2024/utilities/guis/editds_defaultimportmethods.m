function importmethods = editds_defaultimportmethods(FilterSpec_format)
%EDITDS_DEFAULTIMPORTMETHODS Returns list of import methods for GUIs.
% Optional input FilterSpec_format triggers return of importmethods in
% format appropriate for input to uigetfile as "FilterSpec".
%
% Also searches the path for a file named "editds_userimport.mat" which
% contains one or more variables which each defines a cell array of
% methods to add. Each row of the given cell array can contain a filetype
% description:
%  { 'Description'  'keword/function' {Default_filetypes} {valid_filetypes} }
%
% Description is the text description that should be shown in import menus
%   and other interfaces. 
% keyword/function is the m-file name (without extension) or keyword that
%   can load the specified files.
% {Default_filetypes} is a cell array of strings defining which filetype
%   extensions (without period) this importer should be responsible for by
%   default. 
%       NOTE: Only ONE importer should have a given extension in this entry.  
% {valid_filetypes} is a cell array of strings defining which filetype
%   extensions (without period) this importer is capable of loading.
%
%I/O: importmethods = editds_defaultimportmethods
%I/O: importmethods = editds_defaultimportmethods(FilterSpec_format)
%
%See also: EDITDS, EDITDS_USERIMPORT, EDITDS_IMPORTMETHODS

%Copyright © Eigenvector Research, Inc. 2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%Columns are:   Description    keword/function   Default_filetypes   valid_filetypes
% where Default_filetypes are the file extensions which this importer is
% the DEFAULT reader for and valid_filetypes is the list of file types
% which this reader handles (whether or not it is the default for them)
sep = {'--------------------------------------'  '' {} {}};
importmethods = {
  'Workspace/MAT file'                           'workspace'      {'mat'}                       {'mat'}
  'Delimited Text File (CSV,TXT)'                'text'           {'csv' 'txt' 'dat'}           {'csv' 'txt' 'dat' 'xy'}
  'XY... Delimited Text Files (TXT,XY)'          'xy'             {'xy'}                        {'xy'  'dat' 'txt'}
  'Excel File (XLS,XLSX,CSV,TXT)'                'excel'          {'xls' 'xlsx' 'xlsm' 'xlsb'}  {'xls' 'csv' 'txt' 'xlsx' 'xlsb' 'xlsm'}
  'Experiment File (EXP,CSV,XLS,TXT)'            'experimentreadr' {'exp'}                      {'exp' 'csv' 'xls' 'txt'  'xlsm' 'xlsx' 'xlsb'}
  'Text from Clipboard (CSV,TXT,XML)'            'clipboard'      {}                  {}
  'XML file (XML)'                               'xml'            {'xml'}             {'xml'}
  sep{:}
  'ABB Spectrum File (SPECTRUM)'                 'abbspectrumreadr'  {'spectrum'}        {'spectrum'}
  'AdventaCT MTF File (MTF)'                     'editds_mtfimport'  {'mtf'}  {'mtf'}
  'AIT ASF File (ASF, AIF, BKH)'                 'asf'               {'asf' 'aif' 'bkh'} {'asf' 'aif' 'bkh'}
  'AIT PIONIR File (PDF)'                        'pdfreadr'       {'pdf'}            {'pdf'}
  'Analytical Spectral Devices (ASD) Indico (V6 and V7)' 'asdreadr'  {'asd'}          {'asd'}
  'Bruker OPUS File'                             'opusreadr'         {'0'}            {'*'}
  'Bruker XRPD Raw File (RAW)'                   'brukerxrpdreadr'   {'raw'}          {'raw'}
  'CytoSpec CYT File (CYT)'                      'cytospecreadr'     {}               {'cyt'}
  'ENVI Format (HDR)'                            'envireadr'      {'hdr'}           {'hdr'};
  'Grams Thermo Galactic File (SPC,DHB)'         'spc'            {'spc','dhb'}       {'spc','dhb'}
  'Guided Wave File (SCAN,AUTOSCAN)'             'gwscanreadr'    {'scan','autoscan'} {'scan','autoscan'}
  'Hitachi EEM File (.TXT)'                      'hitachieemreadr' {}                  {'txt'}
  'HORIBA Raman File (L6S,L6M)'                  'hjyreadr'       {'l6s' 'l6m'}       {'l6s' 'l6m'}
  'HORIBA A-TEEM/Aqualog or Duetta PEM (.DAT)'   'aqualogreadr'   {}                  {'dat'}
  'HORIBA A-TEEM/Aqualog Absorbance ABS (.DAT)'  'aqualogabsreadr'   {}               {'dat'}
  'Jasco EEM File (CSV)'                         'jascoeemreadr'  {}                  {'csv'}
  'JCAMP (DX,JDX,JCM,JCAMP)'                     'jcamp'          {'jdx' 'jcm' 'dx' 'jcamp'} {'jdx' 'jcm' 'dx' 'jcamp'}
  'netCDF Export from MS Software (CDF)'         'netcdfreadr'    {'cdf'}             {'cdf'}
  'Omnic SPA File (SPA)'                         'spareadr'       {'spa'}             {'spa'}
  'PerkinElmer File (FSM, SP, VIS)'              'pereadr'        {'fsm' 'sp' 'vis' 'imp' 'lsc'}  {'fsm' 'sp' 'vis' 'imp' 'lsc'}
  'Princeton Instruments File (SPE)'            'spereadr'       {'spe'}             {'spe'}
  'Siemens RDA File (RDA)'                       'rdareadr'       {'rda'}             {'rda'}
  'Shimadzu EEM Files (CSV)'                     'shimadzueemreadr' {}                {'csv'}
  'Stellarnet ABS File (ABS)'                    'snabsreadr'     {'abs'}             {'abs'}
  'Vision Air XML File (XML)'                    'visionairxmlreadr'   {}             {'xml'}
  sep{:}
  'Other...'                                     'file'           {}                  {}
  };

%look for user-defined importers
file = evriwhich('editds_userimport.mat');
if ~isempty(file);
  try
    toadd = load(file);
    f = fieldnames(toadd);
    if length(f)==1
      toadd = toadd.(f{1});
      importmethods = [importmethods(1:end-1,:); toadd; sep; importmethods(end,:)];  %add user methods at top
    end
  catch
    %no error
  end
end

%check for "other methods"
addon = evriaddon('importmethods');
for j=1:length(addon);
  addmethods = feval(addon{j});
  if isempty(addmethods); continue; end
  if size(addmethods,2)<3;
    [addmethods{1:end,3}] = deal({});  %make sure there are three columns
  end
  if size(addmethods,2)<4;
    addmethods(:,4) = addmethods(:,3);  %make sure there are three columns
  end
  importmethods = [importmethods(1:end-1,:); addmethods; sep; importmethods(end,:)];
end
%if user passed in an input, return list in format appropriate for
%uigetfile's FilterSpec format.
if nargin>0
  filelist = {};
  for j=1:size(importmethods,1)
    if isempty(importmethods{j,4}); continue; end
    filelist(end+1,1:2) = {[sprintf('*.%s',importmethods{j,4}{1}) sprintf(';*.%s',importmethods{j,4}{2:end})] importmethods{j,1}};
  end
  importmethods = filelist;
end

%check for addon product "filters" which may remove methods
addon = evriaddon('importmethods_filter');
for j=1:length(addon);
  importmethods = feval(addon{j},importmethods);
end
