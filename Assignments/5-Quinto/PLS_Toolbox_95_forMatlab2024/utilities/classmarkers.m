function list = classmarkers(setname,list)
%CLASSMARKERS Returns a class marker description list.
% Optional input (setname) is the name of the set of markers to return. If
% the set does not exist or the string is 'default', the default set will
% be returned. If no setname is supplied, the "current" set list will be
% returned. If no current set has been defined, the default is returned.
%   Example: list = classmarkers('newset')
%
% If a list of markers (list) is supplied as input along with a set name,
% the marker list is saved as the specified marker set.
%   Example: classmarkers('current',myset)
% Multiple marker sets can be imported at once by passing a structure in
% which each field of the structure holds a set of markers (markerstruct)
% such as obtained from the command:
%   cm = getplspref('classmarkers');
%   save classmarkers cm
% This provides a means to share class marker sets between systems:
%   load classmarkers
%   classmarkers(cm)
%
%I/O: list = classmarkers
%I/O: list = classmarkers(setname)
%I/O: classmarkers(setname,list)
%I/O: classmarkers(markerstruct)

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0
  setname = 'default';
elseif ischar(setname) & nargin<2 & ismember(setname,{'options','help','factoryoptions'})
  options = [];
  options.standard        = 'standard';
  options.old_standard    = 'old_standard';
  options.pretty_symbols  = 'pretty_symbols';
  options.pretty_squares  = 'pretty_squares';
  options.many_classes    = 'many_classes';
  options.filled_objects  = 'filled_objects';
  options.grayscale_objects = 'grayscale';
  options.black_and_white = 'black_and_white';
  options.filled_circles  = 'filled_circles';
  options.filled_squares  = 'filled_squares';
  
  if nargout==0; evriio(mfilename,setname,options); else; list = evriio(mfilename,setname,options); end
  return
end

if isstruct(setname)
  %assume this is a structure of multiple sets. Read all in (recursively)
  for f = fieldnames(setname)';
    classmarkers(f{:},setname.(f{:}));
  end
  return
end

setname = lower(setname);
setname(~ismember(setname,['A':'z' '0':'9'])) = '_';
if nargin>1
  %save list as setname
  factory = fieldnames(classmarkers('factoryoptions'));
  if ismember(setname,factory) | ismember(setname,{'options','help','factoryoptions'})
    error('User can not overwrite built-in set "%s".',setname)
  end
  if isempty(list)
    setplspref('classmarkers',setname,'factory');  %DUMP setname
    return
  end
  setplspref('classmarkers',setname,list)
  return
end

%get current sets
sets = classmarkers('options');
list = {};
if ~strcmpi(setname,'factory') & isfield(sets,setname)
  list = sets.(setname);
  if ischar(list)
    list = factoryset(list);
  end
end
if isempty(list)
  %"factory" or set doesn't exist, give standard
  if isfield(sets,'default');
    list = sets.default;
    if ischar(list)
      list = factoryset(list);
    end
  else
    list = factoryset('standard');
  end
end

if iscell(list)
  %convert to structure if cell (old format)
  list = symstruct(list);
end

%------------------------------------------------------
function list = factoryset(noface,n,markers)
% Get marker properties.

persistent list_standard; %Add persisten for standard to help performance.

if nargin~=1 | ~ischar(noface)
  %create set using algorithm
  if nargin<1
    noface = false;
  end
  if nargin<2
    n = 42;
  end
  if nargin<3
    if n<=42
      markers = {'o' 'v' '*' 's' '+' 'd' '^' 'p'};
    else
      markers = {'o' 'v' 'h' 's' 's' 'd' '^' 'p'};
    end
  end
  
  colors = classcolors;
  if ~noface
    colors = [colors(1:5,:);1 1 1];
  else
    if mod(size(colors,1),length(markers))==0
      colors = colors(1:end-1,:);
    end
    n = size(colors,1)*length(markers);
  end
  if ~iscell(colors)
    colors = mat2cell(colors,ones(1,length(colors)),3);
  end
   
  if ~noface
    mycolor  = rem((1:n)-1,length(colors)-1) + 1;
    myface   = rem((1:n)-1,length(colors)  ) + 1;
  else
    mycolor  = rem((1:n)-1,length(colors)  ) + 1;
    myface   = mycolor;
  end
  mymarker = rem((1:n)-1,length(markers) ) + 1;
  list = [markers(mymarker)'  colors(mycolor)  colors(myface)];
  
  if noface>0 & noface<1
    %fade color
    [rclr,junk,loc] = unique(cat(1,list{:,2}),'rows');
    rclr = rotatehue(rclr,[0 +noface -noface]);
    list(:,2) = mat2cell(rclr(loc,:),ones(1,length(loc)),3);
    
    [rclr,junk,loc] = unique(cat(1,list{:,3}),'rows');
    rclr = rotatehue(rclr,[0 -noface +noface]);
    list(:,3) = mat2cell(rclr(loc,:),ones(1,length(loc)),3);
  end

  %cull out duplicates
  [junk,junk,c2] = unique(cat(1,list{:,2}),'rows');
  [junk,junk,c3] = unique(cat(1,list{:,3}),'rows');
  c1 = char(list(:,1));
  noface = ismember(c1,'+.x*');
  c3(noface) = 0;
  [junk,uni] = unique([double(c1) c2 c3],'rows');
  list = list(sort(uni),:);
  
else
  %predefined string
  switch lower(noface)
    
    case 'black_and_white'
      % manually created
      list = {
        'o' [ 0 0 0 ] [ 0 0 0 ]  ;
        'x' [ 0 0 0 ] [ ] ;
        's' [ 0 0 0 ] [ 1 1 1 ]    ;
        '+' [ 0 0 0 ] [ ] ;
        '^' [ 0 0 0 ] [ 0 0 0 ]    ;
        '*' [ 0 0 0 ] [ ] ;
        '<' [ 0 0 0 ] [ 1 1 1 ]    ;
        '.' [ 0 0 0 ] [ ] ;
        'h' [ 0 0 0 ] [ 0 0 0 ]    ;
        'v' [ 0 0 0 ] [ 1 1 1 ]    ;
        'd' [ 0 0 0 ] [ 0 0 0 ]    ;
        '>' [ 0 0 0 ] [ 1 1 1 ]    ;
        'p' [ 0 0 0 ] [ 0 0 0 ]    ;
        'o' [ 0 0 0 ] [ 1 1 1 ]    ;
        's' [ 0 0 0 ] [ 0 0 0 ]    ;
        '^' [ 0 0 0 ] [ 1 1 1 ]    ;
        'd' [ 0 0 0 ] [ 1 1 1 ]    ;
        'v' [ 0 0 0 ] [ 0 0 0 ]    ;
        'p' [ 0 0 0 ] [ 1 1 1 ]    ;
        '<' [ 0 0 0 ] [ 0 0 0 ]    ;
        'h' [ 0 0 0 ] [ 1 1 1 ]    ;
        '>' [ 0 0 0 ] [ 0 0 0 ];
        };
      
    case 'grayscale'
      % manually created
      list = {
        'o' [ 0 0 0 ] [ 0 0 0 ]  ;
        's' [ 0 0 0 ] [ 1 1 1 ]    ;
        '^' [ 0 0 0 ] [ 0 0 0 ]    ;
        '<' [ 0 0 0 ] [ 1 1 1 ]    ;
        'h' [ 0 0 0 ] [ 0 0 0 ]    ;
        'v' [ 0 0 0 ] [ 1 1 1 ]    ;
        'd' [ 0 0 0 ] [ 0 0 0 ]    ;
        '>' [ 0 0 0 ] [ 1 1 1 ]    ;
        'p' [ 0 0 0 ] [ 0 0 0 ]    ;
        'o' [ 0 0 0 ] [ 1 1 1 ]    ;
        '^' [ 0 0 0 ] [ 1 1 1 ]    ;
        'h' [ 0 0 0 ] [ 1 1 1 ]    ;
        'd' [ 0 0 0 ] [ 1 1 1 ]    ;
        'p' [ 0 0 0 ] [ 1 1 1 ]    ;
        's' [ 0 0 0 ] [ 0 0 0 ]    ;
        '<' [ 0 0 0 ] [ 0 0 0 ]    ;
        'v' [ 0 0 0 ] [ 0 0 0 ]    ;
        '>' [ 0 0 0 ] [ 0 0 0 ]    ;
        'v' [ .5 .5 .5 ] [ .5 .5 .5 ] ;
        '+' [ .5 .5 .5 ] [ ] ;
        'x' [ 0 0 0 ] [ ] ;
        'd' [ .5 .5 .5 ] [ 1 1 1 ] ;
        '>' [ .5 .5 .5 ] [ .5 .5 .5 ] ;
        '.' [ .5 .5 .5 ] [ ] ;
        '*' [ 0 0 0 ] [ ] ;
        'p' [ .5 .5 .5 ] [ 1 1 1 ] ;
        'o' [ .5 .5 .5 ] [ .5 .5 .5 ] ;
        's' [ .5 .5 .5 ] [ 0 0 0 ] ;
        '+' [ 0 0 0 ] [ ] ;
        'x' [ .5 .5 .5 ] [ ] ;
        '^' [ .5 .5 .5 ] [ .5 .5 .5 ] ;
        '<' [ .5 .5 .5 ] [ 0 0 0 ] ;
        '.' [ 0 0 0 ] [ ] ;
        '*' [ .5 .5 .5 ] [ ] ;
        'h' [ .5 .5 .5 ] [ .5 .5 .5 ] ;
        'v' [ .5 .5 .5 ] [ 0 0 0 ] ;
        's' [ 0 0 0 ] [ .5 .5 .5 ] ;
        'd' [ .5 .5 .5 ] [ .5 .5 .5 ] ;
        '>' [ .5 .5 .5 ] [ 0 0 0 ] ;
        '<' [ 0 0 0 ] [ .5 .5 .5 ] ;
        'p' [ .5 .5 .5 ] [ .5 .5 .5 ] ;
        'o' [ .5 .5 .5 ] [ 0 0 0 ] ;
        'v' [ 0 0 0 ] [ .5 .5 .5 ] ;
        's' [ .5 .5 .5 ] [ 1 1 1 ] ;
        '^' [ .5 .5 .5 ] [ 0 0 0 ] ;
        '>' [ 0 0 0 ] [ .5 .5 .5 ] ;
        '<' [ .5 .5 .5 ] [ 1 1 1 ] ;
        'h' [ .5 .5 .5 ] [ 0 0 0 ] ;
        'o' [ 0 0 0 ] [ .5 .5 .5 ] ;
        'v' [ .5 .5 .5 ] [ 1 1 1 ] ;
        'd' [ .5 .5 .5 ] [ 0 0 0 ] ;
        '^' [ 0 0 0 ] [ .5 .5 .5 ] ;
        '>' [ .5 .5 .5 ] [ 1 1 1 ] ;
        'p' [ .5 .5 .5 ] [ 0 0 0 ] ;
        'h' [ 0 0 0 ] [ .5 .5 .5 ] ;
        'o' [ .5 .5 .5 ] [ 1 1 1 ] ;
        's' [ .5 .5 .5 ] [ .5 .5 .5 ] ;
        'd' [ 0 0 0 ] [ .5 .5 .5 ] ;
        '^' [ .5 .5 .5 ] [ 1 1 1 ] ;
        '<' [ .5 .5 .5 ] [ .5 .5 .5 ] ;
        'p' [ 0 0 0 ] [ .5 .5 .5 ] ;
        'h' [ .5 .5 .5 ] [ 1 1 1 ]
        };

    case 'old_standard'
      list = factoryset;
      
    case 'many_classes'
      list = factoryset(false,64);
      
    case 'filled_objects'
      list = factoryset(true);
      
    case 'filled_circles'
      list = factoryset(true,42,{'o'});
      
    case 'filled_squares'
      list = factoryset(true,42,{'s'});
      
    case {'pretty_symbols' 'standard'}
      if isempty(list_standard)
        list_standard = factoryset(.2,80,{'o'    'd'    's'    '^'    'v'    'p' });
      end
      list = list_standard;
    case 'pretty_squares'
      list = factoryset(.2,80,{'s'});

  end
end

if ~isstruct(list)
  list = symstruct(list);
end

%-------------------------------------------
function list = symstruct(in)

if size(in,2)<4
  in = [in cell(size(in,1),1)];
end

list = struct('marker',in(:,1),'edgecolor',in(:,2),'facecolor',in(:,3),'size',in(:,4));

%-------------------------------------------
function out=rotatehue(in,r,ind)
%adjusts a color's hue, saturation, and/or value
%I/O: outcolor = rotatehue(color,[h s v])

if nargin<3
  ind = 1;
end
in = rgb2hsv(in);

if length(r)==1
  in(:,ind) = in(:,ind)+r;
else
  in = in+ones(size(in,1),1)*r;
end
in(:,1) = mod(in(:,1),1);
in(:,2:3) = min(in(:,2:3),1);
in(:,2:3) = max(in(:,2:3),0);
  
out = hsv2rgb(in);
