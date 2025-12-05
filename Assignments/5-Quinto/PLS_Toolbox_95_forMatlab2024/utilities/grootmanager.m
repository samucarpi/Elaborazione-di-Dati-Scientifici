function varargout = grootmanager(cmd,varargin)
%GROOTMANAGER - Manage and update MATLAB graphics root object properties.
%  Properties are saved in "property sets" in a single structure as a
%  MATLAB preference. The current set is in the .currentset field. Changing
%  the current set will update groot defaults to the new set. 
%
%  When calling 'updateset' for the first time, grootmanager will create a
%  default set name "Groot Set One" and add the current defaults returned
%  by get(groot,'default').
%
%  Examples: 
%    Create first set with current defaults.
%      mydefaults = grootmanager('updateset')
%
%    Create first set with current defaults.
%      [currentset, currentsetname] = grootmanager('getcurrentset')
%
%    Create new set for easier viewing.
%      grootmanager('addset','ThickLinesBigFont')
%      grootmanager('changeset','ThickLinesBigFont')
%      grootmanager('set','defaultAxesFontSize',20)
%      grootmanager('set','defaultLineLineWidth',4)
%
%    Create new set for plotting images.
%      grootmanager('addset','ImageSetBlackBackground')
%      grootmanager('changeset','ImageSetBlackBackground')
%      grootmanager('set','defaultAxesTitleFontSizeMultiplier',3)
%      grootmanager('set','factoryAxesTitleHorizontalAlignment','left')
%      grootmanager('set','factoryFigureColor',[0 0 0])
%
%    Change back to previous set and create plot.
%      grootmanager('changeset','ThickLinesBigFont')
%      plot(rand(10))
%
%    Return structyure of default or factory property name/values.
%      mylist = grootmanager('listdefault')
%      mylist = grootmanager('listfactory')
%
%    Return cell array of strings of properties.
%      mylist = grootmanager('listobjects')
%      mylist = grootmanager('listobject','line')
%      mylist = grootmanager('search','axes','color')
%
%  Commands (cmd): 
%    set         - Set property value and add it to the current set. 
%    get         - Get a property value. 
%    updateset   - Set current set to get(groot,'default'). If output
%                  assigned then property structure is returned. 
%    changeset   - Change set being used (update all defaults).
%    addset      - Add a new property set.
%    removeset   - Remove set and reset defaults.
%    getcurrentset - Get current property set struct. 
%    getparent   - Get main parent structure with all property sets.
%    setparent   - Set main parent structure with all property sets.
%    listdefault - List current property defaults that have been set.
%    listfactory - List all properties with default values.
%    listobjects - List ojbects that have properties that can be set.
%    listobject  - List properties for given object.
%    search      - Look for a term in all properties and return those that 
%                  include the term. 
%    startup     - Add current set to current root properties. 
%    factoryreset - Remove all default properties.
%    clearall    - Remove all current defaults (factoryreset) and remove
%                  saved preferences rmpref('GRootManagerProperties').
%  
%
%I/O: grootmanager('set',propName,propValue)
%I/O: grootmanager('set',propName,'remove')%Remove property from current set.
%I/O: factorylist = grootmanager('listfactory')
%
%See also: GET, GROOT, GROOTEDITOR, SET, FIGURE, AXES, RESET

%Copyright Eigenvector Research, Inc. 2022
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%These lists only need to be queried once. Make persistent for speed.
persistent factorylist objectlist

validcommands = {'set' ... %Set a name/value property.
  'get' ... %Get a name/value property.
  'updateset' ... %Set current set to get(groot,'default').
  'changeset' ... %Change set being used (update all defaults).
  'addset' ... %Add a new property set.
  'removeset' ... %Remove set and reset defaults.
  'getcurrentset' ... %Get current property struct from saved. 
  'getparent' ...%Get all saved groot sets (parent structure).
  'setparent' ...%Set all saved groot sets (parent structure).
  'listdefault' ... %List current property defaults that have been set.
  'listfactory' ... %List all properties with default values.
  'listobjects' ... %List ojbects that have properties that can be set.
  'listobject' ... %List properties for given object.
  'search' ... %Look for a term in all properties and return those that include the term. 
  'startup' ... %Add current set defaults.
  'factoryreset' ... %Clears current defaults aka reset(groot)
  'clearall'};


%% Input Validation
p = inputParser();
p.addRequired('cmd',@(x) any(validatestring(x,validcommands)));
p.addOptional('propname','',@(x)ischar(x)||isstruct(x));
p.addOptional('propval','',@(x) true);%Take any input.

p.parse(cmd, varargin{:});
cmd = p.Results.cmd;
propname = p.Results.propname;
propval = p.Results.propval;

%% Run command.
switch cmd
  case 'listdefault'
    varargout{1} = get(groot,'default');

  case 'listfactory'
    if isempty(factorylist)
      factorylist = get(groot,'factory');
    end
    varargout{1} = factorylist;

  case 'listobjects'
    %Parse objects out of factory list.
    if isempty(objectlist)
      factorylist = grootmanager('listfactory');
      allpropnames = fieldnames(factorylist);
      objnames = strrep(allpropnames,'factory','');
      caploc = regexp(objnames,'[A-Z]');

      objectlist = cell(1,length(objnames));
      for i = 1:length(objnames);
        objectlist{i} = objnames{i}(1:caploc{i}(2)-1);
      end
      objectlist = unique(objectlist)';
    end
    varargout{1} = objectlist;

  case 'listobject'
    %Get properties for given object.
    varargout{1}  = get(groot,['factory' propname]);

  case 'set'
    %Set a new default property.
    assert(~isempty(propname),sprintf('%s:MissingPropertyName', mfilename), ...
      'Property Name must not be empty.');
    assert(~isempty(propval),sprintf('%s:MissingPropertyValue', mfilename), ...
      'Property Value must not be empty.');
    
    %Get default/factory names.
    [dpropname, fpropname] = getPropertyName(propname);
 
    %Set the property/value.
    set(groot,dpropname,propval);
    grootmanager('updateset');

  case 'setparent'
    %Get main saved properties.
    savedprops = getpref('GRootManagerProperties');
    if isstruct(propname)
      if isfield(propname,'PropertyStruct')
        %Attempting to save raw output from getparent.
        setpref('GRootManagerProperties','PropertyStruct',propname.PropertyStruct);
      elseif isfield(propname,'currentset')
        %Acutal struct that should be saved. 
        setpref('GRootManagerProperties','PropertyStruct',propname);
      else
        error('Unrecognized parent structure for GROOTMANAGER.')
      end
    end

  case 'get'
    %Get a default property value.
    [dpropname, fpropname] = getPropertyName(propname);
    if lower(propname(1))=='d'
      varargout{1} = get(groot,dpropname);
    else
      varargout{1} = get(groot,fpropname);
    end

  case 'getparent'
    %Get main saved properties.
    savedprops = getpref('GRootManagerProperties');
    if isempty(savedprops) || isempty(fieldnames(savedprops)) %Check for empty field names, this happens after a reset.
      savedprops.currentset = "Groot Set One";
      savedprops.propertyset(1).name = "Groot Set One";
      savedprops.propertyset(1).properties = get(groot,'default');
      setpref('GRootManagerProperties','PropertyStruct',savedprops);
    else
      savedprops = savedprops.PropertyStruct;
    end
    varargout{1} = savedprops;

  case 'changeset'
    %Change to new set.
    savedprops = grootmanager('getparent');

    newSetIndex = contains(lower([savedprops.propertyset.name]),lower(propname));
    assert(any(newSetIndex),sprintf('%s:MissingPropertyValue', mfilename), ...
      ['Property Set "' propname '" not found.']);

    grootmanager('factoryreset')
    savedprops.currentset = propname;
    set(groot,'default',savedprops.propertyset(newSetIndex).properties)
    setpref('GRootManagerProperties','PropertyStruct',savedprops);

  case 'addset'
    savedprops = grootmanager('getparent');
    if isempty(propname)
      return
    else
      newSetIndex = contains(lower([savedprops.propertyset.name]),lower(propname));
      assert(~any(newSetIndex),sprintf('%s:DuplicateSetName', mfilename), ...
        ['Set name "' propname '" already exists.']);
    end
    savedprops.propertyset(end+1).name = propname;
    savedprops.propertyset(end).properties = struct();
    setpref('GRootManagerProperties','PropertyStruct',savedprops);

  case 'removeset'
    savedprops = grootmanager('getparent');
    if isempty(propname)
      return
    else
      setIndex = contains(lower([savedprops.propertyset.name]),lower(propname));
      assert(any(setIndex),sprintf('%s:MissingSetName', mfilename), ...
        ['Set name "' propname '" does not exists.']);
    end
    savedprops.propertyset(setIndex) = [];
    setpref('GRootManagerProperties','PropertyStruct',savedprops);
  case 'updateset'
    %Save current default to current grootmanger set.
    savedprops = grootmanager('getparent');
    currentSetIndex = contains([savedprops.propertyset.name],savedprops.currentset);
    savedprops.propertyset(currentSetIndex).properties = get(groot,'default');
    setpref('GRootManagerProperties','PropertyStruct',savedprops);
    if nargout>0
      varargout{1} = savedprops.propertyset(currentSetIndex).properties;
    end

  case 'getcurrentset'
    savedprops = grootmanager('getparent');
    currentSetIndex = contains([savedprops.propertyset.name],savedprops.currentset);
    varargout{1} = savedprops.propertyset(currentSetIndex).properties;
    varargout{2} = savedprops.currentset;
  case 'startup'
    [curprops, curset] = grootmanager('getcurrentset');
    grootmanager('changeset',curset);
  case 'factoryreset'
    reset(groot);%Same as set(groot,'default',struct());
  case 'clearall'
    reset(groot);
    rmpref('GRootManagerProperties');
  case 'search'
    if isempty(propval)
      %Searching over all objects for a term.
      mylist = grootmanager('listfactory');
      srchterm = propname;
    else
      %Searching over one object for a term.
      mylist = grootmanager('listobject',propname);
      srchterm = propval;
    end
    myfnames = fieldnames(mylist);
    myidx = contains(lower(myfnames),lower(srchterm));
    varargout{1} = myfnames(myidx);

end

end

%---------------------------------------------
function [dpropname, fpropname] = getPropertyName(propname)
%Check for default/factory prefix and retrun both.
if length(propname)<8 | ...
    (strcmpi(propname(1:7),'default')==0 && strcmpi(propname(1:7),'factory')==0)
  propname = ['factory' propname];
end
dpropname = strrep(propname,'factory','default');
fpropname = strrep(propname,'default','factory');

%Check to make sure property exists.
flist = grootmanager('listfactory');
assert(ismember(fpropname,fieldnames(flist)),sprintf('%s:PropertyNameNotFound', mfilename), ...
  ['Property Name [' fpropname '] not found in property list. See grootmanager(''listfactory'') for current props.']);
end

%-------------------------
function test
%Clear all saved props.
grootmanager('clearall')

%Create default.
myprops = grootmanager('getparent')
myprops.propertyset(1)
myprops.propertyset(1).properties

%Get lists.
mylist = grootmanager('listdefault')
mylist = grootmanager('listfactory')
mylist = grootmanager('listobjects')
mylist = grootmanager('listobject','line')

%Add new set.
grootmanager('addset','ThickLinesBigFont')
grootmanager('changeset','ThickLinesBigFont')

grootmanager('set','defaultAxesFontSize',20)
grootmanager('set','defaultLineLineWidth',4)

plot(rand(10))

%Add new set.
grootmanager('addset','ImageSetBlackBckgrnd')
grootmanager('changeset','ImageSetBlackBckgrnd')
grootmanager('set','defaultAxesTitleFontSizeMultiplier',3)
grootmanager('set','factoryAxesTitleHorizontalAlignment','left')
grootmanager('set','factoryFigureColor',[0 0 0])

A = imread('ngc6543a.jpg');
image(A);
title('Test Image','Color','white')

close all force
grootmanager('changeset','ThickLinesBigFont')
plot(rand(10))

myval = grootmanager('get','factoryUitoggletoolIcon');%empty
myval = grootmanager('get','defaultLineLineWidth');%4
myval = grootmanager('get','factoryLineLineWidth');%.5

%Manually set groot props then use updateset add it.
set(groot,'defaultAxesColor',[.5 .6 .7])
set(groot,'defaultAxesColormap',hot(265))

get(groot,'default')
myprops = grootmanager('getparent');

myprops.propertyset(2).properties
grootmanager('updateset')

myprops = grootmanager('getparent');
myprops.propertyset(2).properties

%Remove set.
myprops.propertyset.name
grootmanager('removeset','ImageSetBlackBckgrnd')
myprops = grootmanager('getparent');
myprops.propertyset.name

end