function [x,angl] = anglemapper(x,targ,options)
%ANGLEMAPPER Classification based on angle measures between signals.
%  ANGLEMAPPER can be used with two-way matrices (e.g., time-series) or
%  multivarite images from imaging spectroscopy. Samples are classed as
%  the target with the smallest angle between the sample and the target.
%  Different algorithms can be selected using (options.algorithm). The
%  default is a simple angle measure (a.k.a., Spectral Angle Mapper).
% 
%  For a two-way MxN matrix and a set of K target signals or spectra (targ),
%  ANGLEMAPPER calculates an angle between each target and each row of the
%  input (x). The output (x) is a MxN DataSet object with the last class
%  for Mode 1 (x.class{1,end}) corresponding to the target with the
%  smallest angle.
% 
%  For an MxN DataSet object (x) of type "image" with a total of M pixels
%  and a set of K target spectra (targ), ANGLEMAPPER calculates an angle
%  between each target and each pixel (row) the input (x). The output (x)
%  is a MxN image DataSet object with the last class for Mode 1
%  (x.class{1,end}) corresponding to the target with the smallest angle.
%
%  INPUTS:
%          x = data set (MxN class double or DataSet object). Images must
%                be input as a DataSet object (see BUILDIMAGE).
%       targ = targets  (KxN class double or DataSet object) with K
%                targets, K>1. If (targ) is a DataSet object, the output
%                new class will inherit the classname and class lookup
%                table from the desired target class using
%                (options.classset).
%  
%  OPTIONAL INPUT:
%    options = structure array with the following fields:
%       display: [ 'off' | {'on'} ]      governs level of display and waitbar.
%     algorithm: [ {sam} | 'scm' | 'wtfa' | 'wtfac' ]
%     threshold: [{80}], threshold in degrees for classification [0<threshold<90].
%                  Samples/Pixels with all target angles >threshold
%                  are not given a class.
%       minnorm: [{0.03}], approximate noise level, points with norm smaller
%                   than minnorm*max(norm(x))) are not given a class.
%      labelset: [1], target.label{1,options.labelset} becomes the class
%                  lookup for the new class in output (x).
%
%       sam: Spectral Angle Mapper (SAM): Yuhas,RH, Goetz, AFH, Boardman, JW,
%            "Discrimination Among Semi-Arid Landscape Endmembers Using Spectral 
%            Angle Mapper (SAM) Algorithm," Summaries of the 4th Annual
%            JPL AirborneG eoscience Workshop, JPL Pub-92-14, AVIRIS Workshop.
%            Jet Propulsion Laboratory, Pasadena, CA, 147-150 (1992).
%       scm: Spectral Correlation Mapper (SCM): de Carvalho Jr, OA, Meneses, PR,
%            "Spectral Correlation Mapper (SCM): An Improvement on the Spectral
%            Angle Mapper (SAM)," Summaries of the 9th JPL Airborne Earth
%            Science Workshop, JPL, Publication 00-18, 9 p. (2000).
%      wtfa: Window Target FActor Analysis (wtfa): Lohnes, MT, Guy, RD, Wentzell, PD,
%            "Window Target-Testing Factor Analysis: Theory and Application to the
%            Chromatographic Analysis of Complex Mixtures with Multiwavelength
%            Fluorescence Detection", Anal. Chim. Acta, 389, 95-113 (1999).
%            Malinowski, ER, "Obtaining the Key Set of Typical Vectors by Factor
%            Analysis and Subsequent Isolation of Component Spectra," 134, 129-
%            137 (1982). DOI: 10.1016/S0003-2670(01)84184-2
%            Malinowski, ER, Factor Analysis in Chemistry, 2nd ed. John Wiley & Sons,
%            New York 1991.
%     wtfac: Window Target Factor Analysis with Correlation (wtfac).
% 
%    OUTPUTS:
%          x = input (x) with a new class added to the sample mode as a MxN 
%                DataSet object.
%       angl = MxK matrix of angles for each of the K targets.
%  
%I/O: [x,angl] = anglemapper(x,targ,options);
%
%See also: BUILDIMAGE, EVOLVFA, EWFA, EWFA_IMG, PCA, WTFA, WTFA_IMG

%Copyright Eigenvector Research, Inc. 2020
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0;     x = 'io'; end
varargin{1} = x;
if ischar(varargin{1})
  options             = [];
  options.name        = 'options';
  options.display     = 'on';
  options.algorithm   = 'sam';
  options.threshold   = 80;
  options.minnorm     = 0.03;
  options.labelset    = 1;
  options.wtfawindow  = 3;
  options.wtfap       = 0.95;
  options.wtfaoptions = wtfa('options');
  if nargout==0
    clear x;
    evriio(mfilename,varargin{1},options);
  else
    x     = evriio(mfilename,varargin{1},options);
  end
  return
end

if nargin<2
  error('ANGLEMAPPER requires at least 2 inputs.')
end
if nargin<3                   %set default options
  options = anglemapper('options');
else
  options = reconopts(options,anglemapper('options'));
end
options.wtfaoptions.plots   = 'none';
options.wtfaoptions.display = options.display;

if ~isdataset(x)              %Class double: create the DSO
  if ndims(x)==3              %3-way, make it an image
    x     = buildimage(x);
  else                        %2-way, make it a DSO
    x     = dataset(x);
  end
end
m         = size(x);          %M,N samples by variable

if isdataset(targ)
  x       = copydsfields(targ,x,2);
else
  targ    = dataset(targ);
end
k         = size(targ);       %K,N

if isempty(targ.label{1,options.labelset})
  targ.label{1,options.labelset}     = int2str((1:k)');
  targ.labelname{1,options.labelset} = 'Target';
end
tclass    = length(x.class(1,:))+1;
for ii=1:length(x.class(1,:))
  if isempty(x.class{1,ii})
    tclass  = ii;
    break
  end
end
x.class{1,tclass}     = zeros(1,m(1));
x.classname{1,tclass} = targ.labelname{1,options.labelset};
if isempty(x.classname{1,tclass})
  x.classname{1,tclass} = 'Target';
end
tmq       = cell(k(1),2);
for ii=1:k(1)
  tmq{ii,1}     = ii;
  tmq{ii,2}     = deblank(targ.label{1,options.labelset}(ii,:));
end

if strcmpi(x.type,'image') %Image DSO
  if evriio('mia')
    switch lower(options.algorithm)
    case 'sam'
      [~,angl]  = wtfa_img(x,targ,1,1,options.wtfaoptions);
    case 'scm'
      [~,angl]  = wtfa_img(mncn(x')',mncn(targ')',1,1,options.wtfaoptions);
    case 'wtfa'
      [~,angl]  = wtfa_img(x,targ,options.wtfawindow,options.wtfap,options.wtfaoptions);
    case 'wtfac'
      [~,angl]  = wtfa_img(mncn(x')',mncn(targ')', ...
                      options.wtfawindow,options.wtfap,options.wtfaoptions);
    otherwise
      error('Input (options.algorithm) not recognized.')
    end
    [tmp,ii] = min(angl,[],3);
    ii       = ii(:);
    if ~isempty(options.threshold)
      ii(tmp(:)>options.threshold) = 0;
    end
    if ~isempty(options.minnorm)&&options.minnorm>0
      tmp    = sqrt(sum(x.data.^2,2,'omitnan'));
      ii(tmp(:)<(max(tmp(:))*options.minnorm))  = 0;
    end
    x.class{1,tclass} = ii;
    x.classlookup{1,tclass} = tmq;
  else
    error('MIA_Toolbox is required for image data.')
  end
else                       %Two-Way DSO
  switch lower(options.algorithm)
  case 'sam'
    [~,angl]  = wtfa(x,targ,1,1,options.wtfaoptions);
  case 'scm'
    [~,angl]  = wtfa(mncn(x')',mncn(targ')',1,1,options.wtfaoptions);
  case 'wtfa'
    [~,angl]  = wtfa(x,targ,options.wtfawindow,options.wtfap,options.wtfaoptions);
  case 'wtfac'
    [~,angl]  = wtfa(mncn(x')',mncn(targ')', ...
                    options.wtfawindow,options.wtfap,options.wtfaoptions);
  otherwise
    error('Input (options.algorithm) not recognized.')
  end
  [tmp,ii] = min(angl,[],2);
  if ~isempty(options.threshold)
    ii(tmp(:)>options.threshold) = 0;
  end
  if ~isempty(options.minnorm)&&options.minnorm>0
    tmp    = sqrt(sum(x.data.^2,2,'omitnan'));
    ii(tmp(:)<(max(tmp(:))*options.minnorm))  = 0;
  end
  x.class{1,tclass} = ii;
  x.classlookup{1,tclass} = tmq;
end %strcmpi(x.type,'image')

end


%% NOTES and TESTING Code

%SAM
%     angl    = normaliz(x.data(:,targ.include{2}))* ...
%               normaliz(targ.data(:,targ.include{2}))';
%     angl    = real(acos(angl))*180/pi;

%SCM
%     angl    = normaliz(mncn(x.data(:,targ.include{2})')')* ...
%               normaliz(mncn(targ.data(:,targ.include{2})')')';
%     angl    = real(acos(angl))*180/pi;
