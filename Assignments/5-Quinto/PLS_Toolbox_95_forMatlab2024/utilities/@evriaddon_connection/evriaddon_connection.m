function out = evriaddon_connection(varargin)
%EVRIADDON_CONNECTION Defines entry point connections for add-on products.
% EVRIADDON_CONNECTION objects are created by EVRIADDON overload methods
% within an add-on product. They specify the entry point(s) that the add-on
% product wants to be called during. They must be created from within an
% EVRIADDON object method. For more information on using
% EVRIADDON_CONNECTIONS, see the EVRIADDON object help.
% (evriaddon/evriaddon.m)
%
%I/O: obj = evriaddon_connection('Product Description')

% Copyright © Eigenvector Research, Inc. 2008
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

out = [];
out.evriaddon_connectionversion = '1.0';

if nargin>0 && ischar(varargin{1})
  out.name = varargin{1};
else
  out.name = '';
end

out.priority = 100;

%----------------------
%Add new entry points here (add to both entrypoints list and add actual
%field below)

%list of fields
out.entrypoints = {
  'analysistypes' 
  'importmethods'
  'importmethods_filter'
  'savemodelas' 
  'preprocess' 
  'browse_post_gui_init'
  'browse_shortcuts'
  'browse_shortcuts_filter'
  'cachestruct_settings_branch'
  'toolbar_buttonsets'
  'strictedit'
  'analysis_post_gui_init'
  'analysis_enable_method'
  'analysis_calcmodel_callback'
  'analysis_post_calcmodel_callback'
  'analysis_pre_loaddata_callback'
  'analysis_post_loaddata_callback'
  'analysis_pre_setobjdata_callback'
  'analysis_post_setobjdata_callback'
  'analysis_status_contextmenu_callback'
  'lddlgpls_initialize'
  'load_smat_required'
  'load_postload'
  'autoimport_postload'
  'addsourceinfo_prefilter'
  'plotgui_toolbar'
  'plotgui_plotcommand'
  'plotgui_windowbuttonmotion'
  'plotgui_windowbuttondown'
  'plotgui_windowbuttondown_rightclick'
  'plotgui_windowbuttondown_doubleclick'
  'evrijavasetup_jarfolder'
  'evriscript_configfile'
  }';

%automatically generate actual fields (all empty)
for f = out.entrypoints;
  out.(f{:}) = {};
end

% We don't currently have any way to report these help strings to users, so
% we're simply including them here for internal reference

out.help.analysistypes      = '    list = fn(list);  % {tag  Label Function  separator} - see analysistypes.'; 
out.help.importmethods      =   '    addmethods = fn;  %return cell array of import methods - See editds_defaultimportmethods.';
out.help.importmethods_filter = '    methods = fn(methods);  %returns filtered list of import methods (remove or add as needed).';
out.help.savemodelas        = '    methods = fn;     %{''filespec''   ''callback_fcn''   ''.ext''}  - See savemodelas.';
out.help.preprocess         = '    fn(fig);          %add user items to catalog in "fig" prepro figure - See preprouser for format.';  
out.help.browse_post_gui_init = '    fn(fig);          %actions to perform at end of main Browse GUI creation code.'; 
out.help.browse_shortcuts   = '    shortcuts = fn;   %add given shortcuts to workspace - See browse_shortcuts.';  
out.help.browse_shortcuts_filter = '    list = fn(list);  %modify browse shortcuts - list is structure array. Filer as desired. see browse_shortcuts.'; 
out.help.cachestruct_settings_branch = '    nodes = fn(nodes);  %modify cachestruct settings branch';
out.help.toolbar_buttonsets = '    list = fn(list,analysis);  %modify toolbar button "list" for analysis mode "analysis" - See toolbar_buttonsets.';
out.help.strictedit         = '    out = fn;         %determine if editors should be run with "strict editing.';
out.help.analysis_post_gui_init = '    fn(fig);    %actions to perform at end of GUI_INIT callback on startup of Analysis.';
out.help.analysis_enable_method = '    fn(fig,eventdata,handles,newtag,oldtag);  %perform user-specified events when analysis method is changed.';
out.help.analysis_calcmodel_callback = '    fn(fig,eventdata,handles);  %perform user-specified events when calc model is clicked (calc or apply).';
out.help.analysis_post_calcmodel_callback = '    fn(fig,eventdata,handles);  %perform user-specified events after model is calculated or applied.';
out.help.analysis_pre_loaddata_callback = '    fn(fig,block); %actions to perform before loading specified block (string) into analysis figure fig (handle).';
out.help.analysis_post_loaddata_callback = '    fn(fig,block); %actions to perform after loading specified block (string) into analysis figure fig (handle).';
out.help.analysis_pre_setobjdata_callback = '    fn(fig,item,obj); %actions to perform before assigning any object in analysis. fig is analysis handle, item is block name, obj is new value.'; 
out.help.analysis_status_contextmenu_callback = '    fn(fig,key);  %actions to perform after status context menu is set up. "key" is menu being enabled.';
out.help.lddlgpls_initialize = '    fn(fig);         %perform user-defined pre-run actions.'; 
out.help.load_smat_required  = '    out = fn;         %returns true if user loading should be restricted to SMAT files.';
out.help.load_postload       = '    out = fn(out,filename,addflags);  %allow addon to modify loaded objects before unwrapping from secure envelope (if any) and returning to caller.';
out.help.autoimport_postload = '    data = fn(data,filename,methodname);    %allow addon to modify imported object after importing before passing to caller';
out.help.addsourceinfo_prefilter = '      filenamelist = fn(filenamelist);   %filter the list of filenames before storing them in the DSO history (e.g. resolve paths)';
out.help.plotgui_toolbar     = '    list = fn(targfig,list);   %modify list of PlotGUI toolbar items for a given target figure';
out.help.plotgui_plotcommand = '    fn(targfig);   %run addtional plot commands after plotgui update';
out.help.plotgui_windowbuttonmotion = '    fn(targfig);   %run addtional window button motion commands';
out.help.plotgui_windowbuttondown = '    fn(targfig);   %run addtional window button down commands';
out.help.plotgui_windowbuttondown_rightclick = '    fn(targfig);   %run addtional window button down alt (right) click commands';
out.help.plotgui_windowbuttondown_doubleclick = '    fn(targfig);   %run addtional window button down double click commands';
out.help.evrijavasetup_jarfolder = '  folder = fn    %identify folder which should be searched for java objects';
out.help.evriscript_configfile   = '  list = fn      %return filename or cell array of filenames to read and use as evriscript modules';

%
%----------------------


out = class(out,mfilename);  %cast into custom object
