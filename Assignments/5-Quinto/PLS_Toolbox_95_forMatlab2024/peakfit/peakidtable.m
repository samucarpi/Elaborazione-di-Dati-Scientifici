function s = peakidtable(peakdef,options)
%PEAKIDTABLE Writes peak ID information on present graph.
%  For an input of a standard peak structure (peakdef),
%  the output (s) is a cell array of strings containing
%  peak information.
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%     display: [ {'off'} | 'on'] governs level of display to command window.
%      fields: cell array of strings that governs what is printed to (s),
%              default: fields = {'id','fun','param','area'};.
%              Valid strings are the field names in a standard peak
%              structure.
%      params: {1:3} parameters to print.
%     paramformat: format string for fields 'param','lb' and 'ub', 
%              default: paramforamt = '%2.1f %5.1f %2.1f';.
%     areaformat: format string for field 'area',
%              default: areaforamt = '%2.1f';.
%
%I/O: s = peakidtable(peakdef,options);
%
%See also: PEAKIDTEXT, PEAKSTRUCT

%Copyright Eigenvector Research, Inc. 2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 10/08

%probably need to modify to handle the 4 parameter peaks
%need to add penlb and penub

if nargin == 0; peakdef = 'io'; end
if ischar(peakdef);
  options = [];
  options.name = 'options';
  options.display = 'off';
  options.fields  = {'id','fun','param','area'};
  options.params  = 1:3;
  options.paramformat = '%2.1f %5.1f %2.1f';
  options.areaformat = '%2.1f';  
  
  if nargout==0;
    evriio(mfilename,peakdef,options);
  else
    s     = evriio(mfilename,peakdef,options);
  end
  return
end
if nargin<2
  options = peakidtable('options');
else
  options = reconopts(options,'peakidtable');
end
s         = cell(length(peakdef)+1,1);

%create header
for i2=1:length(options.fields)
  s{1}    = [s{1},'\t',options.fields{i2}];
end
s{1}     = sprintf(s{1});

%create table body
for i1=2:length(peakdef)+1
  if ~isempty(lower(peakdef(i1-1).fun))
    s{i1} = '';
    for i2=1:length(options.fields)
      if strcmpi(options.fields{i2},'name')
        s{i1} = [s{i1},'\t',peakdef(i1-1).name];
      elseif strcmpi(options.fields{i2},'id')
        if isa(peakdef(i1-1).id,'char')
          s{i1} = [s{i1},'\t',peakdef(i1-1).id];
        elseif isa(peakdef(i1-1).id,'double')
          s{i1} = [s{i1},'\t',num2str(peakdef(i1-1).id)];
        else
          disp(['Peak ',num2str(i1),' .id class must be char or double.'])
        end
      elseif strcmpi(options.fields{i2},'fun')
        s{i1} = [s{i1},'\t',peakdef(i1-1).fun];
      elseif strcmpi(options.fields{i2},'param')
        s{i1} = [s{i1},sprintf(['\t ',options.paramformat], ...
                 peakdef(i1-1).param(options.params))];
      elseif strcmpi(options.fields{i2},'area')
        s{i1} = [s{i1}, ...
          sprintf(['\t ',options.areaformat],peakdef(i1-1).area)];
      elseif strcmpi(options.fields{i2},'lb')
        s{i1} = [s{i1},sprintf(['\t ',options.paramformat], ...
                 peakdef(i1-1).lb(options.params))];
       elseif strcmpi(options.fields{i2},'ub')
        s{i1} = [s{i1},sprintf(['\t ',options.paramformat], ...
                 peakdef(i1-1).ub(options.params))];
      end
    end
    s{i1} = sprintf(s{i1});
  end
end
  
if strcmpi(options.display,'on');
  disp(s)
end
