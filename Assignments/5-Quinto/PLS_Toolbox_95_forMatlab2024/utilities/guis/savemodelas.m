function out = savemodelas(modl,filterindex)
%SAVEMODELAS Opens dialog box for saving a model.
%
% Saves to 3 standard formats or user defined.
%   MAT - This is also standard format .mat file.
%   XML - Uses encodexml to output .xml formatted model.
%   M   - Uses encode to ouput .m formatted model.
%
% User defined uses savemodelas_custom.m to look up and call defined
% functions/file types.
%
% With one input (model), the user is prompted for a file type to save as.
% With no inputs, a cell listing the available file formats (filterlist) is
% returned (see SAVEMODELAS_CUSTOMLIST for information on the cell format).
% With two inputs (model) and (filter_index),the user is offered only one
% file type to save as based on the filter_index number (which points to
% one of the filters in the filterlist).
%
%I/O: savemodelas(model)
%I/O: filterlist = savemodelas         %return list of valid file types
%I/O: savemodelas(model,filter_index)  %save as specific type based on index
%
%See Also: SAVEMODELAS_CUSTOMLIST, SAVEMODELAS_EXAMPLEFUNC

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%Default list.
defaultlist = {
  'XML Extensible Markup (*.xml)'   'local_encodexml'   '.xml';
  'ASCII-MOD File (*.amo)'          'local_amo'         '.amo'
  'MATLAB M-file (*.m)'             'local_encode_m'    '.m';
  'MATLAB MAT File (*.mat)'         'local_save_mat'    '.mat'
  'Vision Air (*.plt)'              'local_plt'         '.plt';
  };

%Append custom list (to top).
mylist = [savemodelas_customlist; defaultlist];

%append other add-on product defined model export methods
addonlists = evriaddon('savemodelas');
for j=1:length(addonlists)
  mylist = [feval(addonlists{j});mylist];
end

if nargin<1;
  out = mylist;
  return
end

if true  % standard system dialog with "Save As Type:" at the bototom
  if nargin<2;
    filterindex = 1:size(mylist,1);
  end
else  %custom dialog which requires pre-selection of file type in one gui then standard save as dialog
  if nargin<2 | isempty(filterindex) | any(filterindex>size(mylist,1))
    filterindex = listdlg('ListString',...
      mylist(:,1)',...
      'ListSize',[230 180],...
      'SelectionMode','single',...
      'PromptString','Export To:',...
      'Name','Export');
    
    if isempty(filterindex)
      %User cancel.
      return
    end
  end
end

fspec = {};
for j=1:length(filterindex);
  %Create filter spec.
  fspec = [fspec; {['*' mylist{filterindex(j),3}]} mylist(filterindex(j),1)];
end

%Get file info.
defaultname = defaultmodelname(modl,'variable',mylist{filterindex(1),2});
defaultfilename = defaultmodelname(modl,'filename',mylist{filterindex(1),2});
[FileName,PathName,MyIndex] = evriuiputfile(fspec,'Save Model As',defaultfilename);

if ~FileName
  %User cancel.
  return
end

%index into available filters based on user selection (might be from a list
%of one type, but if not, we need to do this for the multiple types)
filterindex = filterindex(MyIndex);

%Check for file extension (user may have manually added it), add if not there.
if isempty(strfind(FileName,mylist{filterindex,3}))
  FileName = fullfile(PathName,[FileName mylist{filterindex,3}]);
else
  FileName = fullfile(PathName,FileName);
end

%Write file.
%test for one of the standard methods
switch mylist{filterindex,2}
  case 'local_save_mat'
    eval([defaultname '=modl;']);
    save(FileName,defaultname);
  case 'local_encodexml'
    encodexml(modl,defaultname,FileName);
  case 'local_encode_m'
    modelcode = encode(modl);
    fid = fopen(FileName,'w');
    fprintf(fid,'%s',modelcode);
    fclose(fid);
  case 'local_amo'
    %check if we are being called from analysis
    fig = gcbf;
    if ~isempty(fig) & strcmpi(get(fig,'tag'),'Analysis');
      obj = evrigui(fig);
      exportmodelamo(modl,FileName,obj.getXblock,obj.getYblock);
    else
      exportmodelamo(modl,FileName);
    end
  case 'local_plt'
    writeplt(modl,FileName);
  otherwise
    %chose one of the custom methods, call appropriate function here
    feval(mylist{filterindex,2},modl,FileName);
end
