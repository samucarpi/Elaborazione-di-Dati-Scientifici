function [clrs,index] = classcolors(v,matchclr)
%CLASSCOLORS Defines the colors to be used for classes in plots.
% Output is a three-column matrix defining the unique colors to use for
% plotting classes. This function is used by a number of PLS_Toolbox
% functions.
%
% If input v is -1, then a graphical user interface is presented on which
% the user can select the colors and color order desired.
%
% OPTINAL INPUTS:
%         v  = class color set to use. A value of zero looks for
%              user-defined colors (see below), then falls back on
%              highest-nubmered class color set (default = 0).
%              If -1 is used, then a GUI is presented to choose order.
%   matchclr = a three-element color code which should be matched in the
%              class colors. Output will be the one color from the class
%              colors that best matches this color.
%
% User-defined colors set:
%  The user can override the color sets by using setplspref to define their
%  own color set:
%    setplspref('classcolors','userdefined',clrs)
%  This can be cleared using:
%    setplspref('classcolors','userdefined','factory')
%
%I/O: clrs = classcolors
%I/O: clrs = classcolors(v)
%I/O: clrs = classcolors(matchclr)
%I/O: clrs = classcolors(v,matchclr)

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<1
  % ()
  v = 0;
end
if length(v)==3
  % (matchclr,...)
  matchclr = v;
  v = 0;
elseif nargin<2
  % (v)
  matchclr = [];
end

if v==-1
  %Offer GUI selection
  sym = symbolstyle('coloronly');  %offer GUI and wait for return
  v = 0;  %now load whatever colors the user set, if any
end

if v==0
  %v=0 look for user-defined (in plspref)
  clrs = getplspref('classcolors','userdefined');
  if isempty(clrs) | size(clrs,2)~=3 | ~isnumeric(clrs)
    %couldn't find user defined? 
    v = inf; %force choice of highest numbered v set
  end
end

switch v
  case 0 
    %don't overwrite what's in clrs (used above if userdefined is set)
    %... do nothing
    
  case 1
    %original set
    clrs = [
      0.2500    0.2500    0.2500
      1.0000         0         0
      0    0.7000         0
      0         0    1.0000
      0    1.0000    1.0000
      1.0000    0.3333         0
      0    1.0000         0
      0.6667         0    1.0000
      1.0000         0    0.3333
      1.0000    0.6667    0.6667
      0         0    0.6667
      0.6667         0         0
      0    0.6667    1.0000
      0    1.0000    0.8000
      1.0000    0.3333    0.6667
      0    1.0000    0.3333
      1.0000    0.6667    0.3333
      0    0.3333    1.0000
      0.6667    0.3333    1.0000
      0.6667    0.6667         0
      0.6667    1.0000    0.6667
      0.3333         0    0.3333
      1.0000    0.3333    0.3333
      0.6667    0.6667    1.0000
      ];
    
    % % Based loosely on:
    % cl = factdes(3,4)/3;
    % cls = cl(sum(cl,2)>.4 & sum(cl,2)<2.6 & sum(abs(scale(cl,[1 0 1])),2)>.5 & sum(abs(scale(cl,[1 1 0])),2)>.4,:);
    % %  (manually select the first 4 colors)
    % cls(distslct(cls,25,2,[42 6 2 13]),:)
    % % some additional colors were then removed by hand
    
  otherwise  %  case 2  (if a new color set is designed, make this case 2)
    %based on colors selected to be most different from each other (see
    %CIEDE2000 : http://en.wikipedia.org/wiki/Color_difference )
    
    v = 2;
    clrs = [
      0.250980   0.250980   0.250980
      1.000000   0.000000   0.000000
      0.000000   0.700000   0.000000
      0.000000   0.000000   1.000000
      0.003922   1.000000   0.996078
      1.000000   0.650980   0.996078
      1.000000   0.858824   0.400000
      0.000000   0.392157   0.003922
      0.003922   0.000000   0.403922
      0.584314   0.000000   0.227451
      0.000000   0.490196   0.709804
      1.000000   0.000000   0.964706
      1.000000   0.933333   0.909804
      0.466667   0.301961   0.000000
      0.564706   0.984314   0.572549
      0.000000   0.462745   1.000000
      0.835294   1.000000   0.000000
      1.000000   0.576471   0.494118
      0.415686   0.509804   0.423529
      1.000000   0.007843   0.615686
      0.996078   0.537255   0.000000
      0.478431   0.278431   0.509804
      0.494118   0.176471   0.823529
      0.521569   0.662745   0.000000
      1.000000   0.000000   0.337255
      0.643137   0.141176   0.000000
      0.000000   0.682353   0.494118
      0.407843   0.239216   0.231373
      0.741176   0.776471   1.000000
      0.741176   0.827451   0.576471
      0.000000   0.725490   0.090196
      0.619608   0.000000   0.556863
      0.760784   0.549020   0.623529
      1.000000   0.454902   0.639216
      0.003922   0.815686   1.000000
      0.000000   0.278431   0.329412
      0.898039   0.435294   0.996078
      0.470588   0.509804   0.192157
      0.054902   0.298039   0.631373
      0.568627   0.815686   0.796078
      0.745098   0.600000   0.439216
      0.588235   0.541176   0.909804
      0.733333   0.533333   0.000000
      0.262745   0.000000   0.172549
      0.870588   1.000000   0.454902
      0.000000   1.000000   0.776471
      1.000000   0.898039   0.007843
      0.384314   0.054902   0.000000
      0.000000   0.560784   0.611765
      0.596078   1.000000   0.321569
      0.458824   0.266667   0.694118
      0.709804   0.000000   1.000000
      0.000000   1.000000   0.470588
      1.000000   0.431373   0.254902
      0.000000   0.372549   0.223529
      0.419608   0.407843   0.509804
      0.372549   0.678431   0.305882
      0.654902   0.341176   0.250980
      0.647059   1.000000   0.823529
      1.000000   0.694118   0.403922
      0.000000   0.607843   1.000000
      0.909804   0.368627   0.745098
      ];

end

%if we're matching a color, look for user-supplied color in colormap and
%return it (returns cloest match of color in map
if ~isempty(matchclr)
  [mwhat,index] = min(sum(scale(clrs,matchclr).^2,2));
  clrs = clrs(index,:);
else
  index = v;
end
