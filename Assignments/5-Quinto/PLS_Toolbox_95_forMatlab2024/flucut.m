function varargout = flucut(X,LowMiss,TopMiss,options)
%FLUCUT Corrects fluorescence EEM data for Rayleigh and Raman scattering.
% FLUCUT removes Rayleigh (and possibly Raman) scattering by setting these
% regions to be missing (or interpolating these). FLUCUT does this by 
% inserting NaN and 0 values in Excitation-Emission Matrices (EEMs) where 
% the Rayleigh bands bands are.
%
% Alternatively, FLUCUT may also be used to generate weights that can be
% used for deweighting (instead of eliminating) these regions. FLUCUT
% can also be used to subtracts a blank to remove Raman and correct for
% inner filter effects.
%
% Scattering includes bands around the primary and secondary scattering
% emission==excitation [First order Rayleigh - input Rayl1] and
% emis==2*exci [Second order Rayleigh - input Rayl2].
%
% The following actions are performed by FLUCUT:
% Bands around the Rayleigh scatter are set to NaN to avoid bias in least-
% squares modelling. This is controlled by the options (Rayl1) and (Rayl2).
%
% Zeros can be included below the primary scatter and above the secondary
% scatter to improve speed and robustness in subsequent PARAFAC modeling.
% This is defined using the options (LowZero) and (TopZero).
%
% Bands around the first and possibly second order Raman signal can be
% set to missing by using the Raman related parts of the (options) input.
%
% Alternatively FLUCUT may also be used to generate weights that can be used
% for deweighting scatter areas [see input (options)].
%
%  INPUTS:
%        X = DataSet object containing an array of EEMs. (X) is size IxJxK,
%            where I is number of samples, J emissions and K excitations.
%            (X) must be a DataSet object with appropriate axisscales:
%            X.axisscale{2} corresponds to emissions (emi) in nm and
%            X.axisscale{3} corresponds to excitations (exci) in nm.
%
%  Rayl1 = 1 or 2 element vector describing filtering of the band about
%            the Rayleigh line (the 1:1 line where emission=excitation)
%            (Rayl1(1)) [nm]: defines to how far ABOVE the 1:1 Rayleigh line
%                   to mark as "missing" (i.e. NaN) in each emission
%                   spectrum. All emission wavelengths shorter than this
%                   value will be marked as missing (down to Ex-Rayl1(2))
%            (Rayl1(2)) [nm]: defines how far BELOW the 1:1 Rayleigh line
%                   to mark as missing. If omitted, all emission
%                   wavelengths lower than ex+Rayl1(1) will be marked as
%                   missing.
%            If Rayl1==NaN, then it is not used.
%            Zeros set by the LowZero option (see below) supercede the
%            (Rayl1(2)) missing setting.
%  Rayl2 = 1 or 2 element vector to describe the band about emis==2*exci.
%            Usage is similar to (Rayl1).
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%     MakeWts: [ {'off'} | 'on' ] If 'on', weights will be given that can
%              be used to downweight areas of scatter e.g., in PARAFAC
%              models. The weights will be held in the output dataset field
%              'userdata'. {default = 'off', do not create weights}
%     LowZero: [ {'off'} | 'on' ]: If 'on', the values below Rayleigh are set
%              to zero. Zeros well below Rayleigh are better than missing
%              values and stabilizes the model. It can lead to bias and artifacts
%              if the zeros are too close to the Rayleigh scatter ridge.
%     TopZero: [ {'off'} | 'on' ]: If 'on', the values above the 2nd order
%              Rayleigh are set to zero.
% Interpolate: [ 'off' | {'on'} ]: If 'on', the missing values are replaced
%              with interpolated values.
%     Blank:  If the option Blank is set to an integer, the corresponding
%              sample will be assumed to be a blank (e.g. water). The
%              sample will be subtracted from all the remaining samples and
%              the blank itself will be soft-deleted (so that it is not
%              used for fitting the model).
%     RamanCorrect: [ {'off'} | 'on' ]. Set to 'on' in order to also remove
%              first and possible second order Raman scattering.
%     RamanWitdh: [10] Width in nanometers that should be removed above and
%              below the Raman scattering.
%     RamanShift: [3382] Raman shift (in wavenumbers) at which a solvent band
%              should be expected and removed. Default is for the primary
%              Raman water band. Alternatives are
%                     Hexane        2990
%                     THF           3000
%                     Methanol      3090
%                     Isopropanol   3050
%
%      RemoveMissing: [ {'off'} | 'on' ]. Governs removal of wavelengths which
%              contain only missing data (all data removed).
%     innerfilter.use : [ {'off'} | 'on' ] Correct for inner filter effects. Requires an absorption
%             spectrum for each sample including the wavelength axis.
%             The correction is performed in accordance with lakowicz and
%             assumes that a standard 1 cm cuvette is used.
%     innerfilter.options : Settings for inner filter correction.
%     innerfilter.spectra : Absorbance spectra covering from lowest excitation
%             to highest emission. Extrapolation may occur if the range
%             is not sufficient. Each row in IFEspectra must contain
%             the absorbance of the corresponding row in the data
%     innerfilter.wavelengths : Wavelength for the spectra (a vector).
%       plots: [ 'off' | {'on'} ] governs plotting.
%
%  OUTPUT:
%     Xnew =  DataSet object containing the new EEM-array with zeros and NaN
%             inserted (NaN = missing).
%             Columns with only missing values are removed
%
%EXAMPLE:
%   load dorrit
%   Xnew = flucut(EEM,20,[20 20]);
%
%EXAMPLE:
%   z    = dataset(ones(1,250,121));
%   z.axisscale{2} = 1:250;
%   z.axisscale{3} = 1:121;
%   z2 = flucut(z,[10 5],[8 4]);
%   figure, imagesc(squeeze(z2.data)), axis('image'), set(gca,'ydir','normal')
%   dp, hold on, plot(z.axisscale{3},2*z.axisscale{3}+4,'g')
%
%EXAMPLE: suppose X is a stack of 15x23 EEMs with
%                 an axisscale of 11:25 for the emission dimension and
%                 an axisscale of 1:23 for the excitation dimension
%  For a single EEM, the original output might look like the left matrix
%  where "+" is a data point and "I" is the emi==exci line, where "M" is
%  missing and "0" is zero. The right matrix is the result of these
%  commands:
%   >> opts = [];
%   >> opts.LowZero = 'on';
%   >> znew = flucut(z,[3 3],[],opts);
%
%             Original                      Modified
%     - +++++++++++++++++++++++     - +++++++++++++++++++++MM
%    ^  +++++++++++++++++++++++       ++++++++++++++++++++MMM
%    |  ++++++++++++++++++++++I       +++++++++++++++++++MMMM
%    E  +++++++++++++++++++++I+       ++++++++++++++++++MMMMM
%    x  ++++++++++++++++++++I++       +++++++++++++++++MMMMMM
%    c- +++++++++++++++++++I+++     - ++++++++++++++++MMMMMMM
%    i  ++++++++++++++++++I++++       +++++++++++++++MMMMMMM0
%    t  +++++++++++++++++I+++++       ++++++++++++++MMMMMMM00
%    a  ++++++++++++++++I++++++       +++++++++++++MMMMMMM000
%    t  +++++++++++++++I+++++++       ++++++++++++MMMMMMM0000
%    i- ++++++++++++++I++++++++     - +++++++++++MMMMMMM00000
%    o  +++++++++++++I+++++++++       ++++++++++MMMMMMM000000
%    n  ++++++++++++I++++++++++       +++++++++MMMMMMM0000000
%       +++++++++++I+++++++++++       ++++++++MMMMMMM00000000
%       ++++++++++I++++++++++++       +++++++MMMMMMM000000000
%           |    |    |    |              |    |    |    |
%       Emission -->
%
%I/O: Xnew = flucut(X,Rayl1,Rayl2,options);
%
%See also: PARAFAC

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%Modified RB 20-3-2005, nbg 10/11, RB 24-8-2012

if nargin<1;
  X = 'io';
end

if ischar(X) && ismember(X,evriio([],'validtopics')) %Help, Demo, Options
  options = [];
  options.MakeWts = 'off';
  options.TopZero = 'off';
  options.LowZero = 'off';
  options.Interpolate = 'on';
  options.Blank = NaN;
  options.plots   = 'on';
  options.RamanCorrect = 'off';
  options.RamanWidth  = 10;
  options.RamanShift  = 3382;
  options.innerfilter.use = 'off';
  options.innerfilter.options = ife('options');
  options.innerfilter.spectra = [];
  options.innerfilter.wavelengths = [];
  options.RemoveMissing = 'off';
  options.definitions = @optiondefs;
  if nargout==0; evriio(mfilename,X,options); else; varargout{1} = evriio(mfilename,X,options); end
  return;
end

if nargin<4
  options = [];
end
options = reconopts(options,mfilename);

if nargin<2
  error('At least two inputs required.')
end
if nargin<3 | isempty(TopMiss)
  TopMiss = NaN;
end
if max(size(LowMiss))==1
  LowMiss=[LowMiss LowMiss];
end
if max(size(TopMiss))==1
  TopMiss=[TopMiss TopMiss];
end

try
  if ~isa(X,'dataset')
    error('Input (X) must be a dataset (see help).')
  end
catch
  error('Input (X) must be a dataset (see help for how to make a DataSet Object).')
end

xsz = size(X);
if length(xsz)<3
  error('Input (X) must be 3-dimensional EEM data organized as [samples x emission x excitation]')
end
if isempty(X.axisscale{2})
  EmAx = 1:xsz(2);
else
  EmAx = X.axisscale{2};
end
if isempty(X.axisscale{3})
  ExAx = 1:xsz(3);
else
  ExAx = X.axisscale{3};
end


if strcmpi(options.innerfilter.use,'on')
  % check size are ok
  if isempty(options.innerfilter.spectra)
    error('An absorbance spectrum must be given for each sample when inner filter correction is set')
  elseif size(options.innerfilter.spectra,1)~=size(X,1)
    error('The absorbance matrix must have as many rows as there are samples in the data')
  end
  if length(options.innerfilter.wavelengths)~=size(options.innerfilter.spectra,2)
    error('The wavelengths must match the number of variables in the absorbance spectra')
  end
end


% DO PLOTTING OF OLD RESULTS
if iscell(LowMiss) % Either filter values hence plotting
  clf
  Samplenumber = TopMiss(1);
  Rayl = LowMiss;
  
  %%%%%%% PLOTTING
  x = squeeze(X.data(Samplenumber,:,:));
  
  % Plot EEM
  p=surf(ExAx,EmAx,x);
  axis tight
  set(p,'facecolor',[.5 .5 .5],'edgecolor','none')
  camlight, lighting gouraud
  hold on
  set(gcf,'userdata',{X,Rayl,Samplenumber});
  
  % Make sample selector
  uicontrol('Style', 'popup',...
    'String', num2str([1:xsz(1)]'),...
    'Units','Normalized', ...
    'Position',[.01 .9 .2 .1], ...
    'Value',Samplenumber, ...
    'Callback', sprintf('s=get(gcf,''userdata'');%s(s{1},s{2},get(gco,''value''));',mfilename));
  
  return;
end

% DO EXCISING
mask = ones(xsz(2),xsz(3));
if length(LowMiss)<1;
    LowMiss = NaN;
end
for j=1:length(ExAx)
  % First order missing
 
  if ~isnan(LowMiss(1))
    if length(LowMiss)==2
      k = (EmAx<=(ExAx(j)+LowMiss(1))&EmAx>=(ExAx(j)-LowMiss(2)));
    else
      k = (EmAx<=(ExAx(j)+LowMiss(1)));
    end
    mask(k,j)=NaN;
  end
  
  % Low zeros
  if strcmpi(options.LowZero,'on')
    k = (EmAx<(ExAx(j)-LowMiss(2)));
    mask(k,j)=0;
  end
  
  % High missing
  if ~isnan(TopMiss(1))
    if length(TopMiss)==2
      k  = (EmAx>=(2*ExAx(j)-TopMiss(1))&EmAx<=(2*ExAx(j)+TopMiss(2)));
    else
      k  = (EmAx>=(2*ExAx(j)-TopMiss(1)));
    end
    mask(k,j)=NaN;
  end
  
  % High zeros
  if strcmpi(options.TopZero,'on')
    k = (EmAx>(2*ExAx(j)+TopMiss(1)));
    mask(k,j)=0;
  end
  
end

%Raman removal
if strcmpi(options.RamanCorrect,'on');
  Emission = zeros(1,xsz(3));
  for k = 1:xsz(3) % EVERY EXCITATION
    Emission(k)=1e7/( (1e7/ExAx(k))-options.RamanShift);
  end
  for k=1:length(Emission);
    kk = ((EmAx>Emission(k)-options.RamanWidth)& (EmAx<Emission(k)+options.RamanWidth));
    mask(kk,k)=NaN;
  end
  
  % Second order Raman if needed
  Emission = zeros(1,xsz(3));
  for k = 1:xsz(3) % EVERY EXCITATION
    Emission(k)=1e7/( (1e7/(ExAx(k)*2))-(options.RamanShift*2));
  end
  for k=1:length(Emission);
    kk = ((EmAx>Emission(k)-options.RamanWidth)& (EmAx<Emission(k)+options.RamanWidth));
    mask(kk,k)=NaN;
  end
end

%apply mask to entire dataset (at once!)
masked = X.data;
mask = shiftdim(mask,-1);
for j=1:size(masked,1);
  masked(j,:,:) = masked(j,:,:).*mask;
  k = mask==0;
  maskedj = squeeze(masked(j,:));
  maskedj(k) = 0;
  masked(j,:) = maskedj;
end
X.data = masked;

% Inner filter correction
if strcmpi(options.innerfilter.use,'on')
  absorp = dataset(options.innerfilter.spectra);
  absorp.axisscale{2} = options.innerfilter.wavelengths;
  [X] = ife(X,absorp);
end

%blank subtraction
if isfinite(options.Blank) ...
    & round(options.Blank)==options.Blank ...
    & options.Blank>=1 & options.Blank<=xsz(1);
  %if a valid integer
  blank = X.data(options.Blank,:,:);
  blanked = X.data;
  for i=1:xsz(1);
    blanked(i,:,:) = blanked(i,:,:) - blank;
  end
  X.data = blanked;
  % Soft delete blank
  % X.include{1} = setdiff(X.include{1},options.Blank);

end

%%%%%%%%%%%%% MAKE WEIGHTS
if strcmp(options.MakeWts,'on')
  w = gauss(X,EmAx,ExAx,[max(LowMiss) max(LowMiss)/1.5 max(TopMiss)],350,options.RamanShift);
  w = w/max(w(:));
  w = abs(1-w)+.05;
  X.userdata.weights = w;
end

if strcmp(options.RemoveMissing,'on')
  % Remove areas with only missing
  n = squeeze(isnan(X.data(1,:,:)));
  i = (sum(n)<xsz(2));
  j = (sum(n,2)<xsz(3));
  if any(~i) | any(~j)
    X = X(:,j,i);
  end
end

if strcmpi(options.Interpolate,'on')
    try
    X=eemscat(X);
    end
end

if strcmp(options.plots,'on')
  figure;
  feval(mfilename,X,{},1);
end

varargout{1} = X;
%----------------------------------------------------------
function model = gauss(X,EmAx,ExAx,Width,Height,wavenumber_forraman)
% Calculates a gaussian profile as
% area * exp( -(emaxis-(Exc+DelPos)).^2/(2*Width^2)   );
%
% For gauss-fitting
% Assumes that emission is measured appr. every nm
% Width(1) = width of first Rayl. (2) of Raman, (3) of second Ray

[I J K] = size(X);
model = zeros(size(X));

for k = 1:K
  if ~isnan(Width(1))
    gauss_est = Height* exp( -(EmAx-(ExAx(k))).^2/(2*Width(1)^2)   );
    for i = 1:I
      model(i,:,k) = gauss_est;
    end
  end
  if ~isnan(Width(3))
    gauss_est = Height* exp( -(EmAx-(2*ExAx(k))).^2/(2*Width(3)^2)   );
    for i = 1:I
      model(i,:,k) = model(i,:,k)+gauss_est;
    end
  end
  
  if ~isnan(Width(2))
    Ex=1e7/( (1e7/ExAx(k))-wavenumber_forraman);
    gauss_est = Height* exp( -(EmAx-(Ex)).^2/(2*Width(2)^2)   );
    for i = 1:I
      model(i,:,k) = model(i,:,k)+gauss_est;
    end
  end
end


%----------------------------------------------------------
function m = nanmax(x)
m = max(x(~isnan(x)));

%----------------------------------------------------------
function m = nanmin(x)
m = min(x(~isnan(x)));

function  [Xnew,EEMCorrection] = ife(X,absspec,options);

%IFE Inner filter effect correction
%
%    Input:
%    X      EEM dataset in the form of samples x emission x excitation
%            (X.axisscale{2} must hold emission wavelengths and
%            X.axisscale{3} excitation wavelengths; both in nm).
%   absspec Absorbance spectrum covering the whole excitation and
%            emission range. If the absorbance spectrum is not covering
%            the whole range, extrapolation will be performed which is
%            not advisable. The input absspec must be a row vector for each sample
%            in a dataset having the wavelengths in the axisscale
%            (absspec.axisscale{2}=wavelengthaxis)
%
%   Output is the correct EEM dataset assuming a 10x10 cuvette. 

EEMCorrection=[];

standardoptions = struct('name','options',...
  'display','on',...
  'method','lakowicz');

 
if nargin == 0;
  X = 'io';
end

if ischar(X)
  options = standardoptions;
  if nargout==0;
    clear varargout;
    evriio(mfilename,X,options);
  else;
    Xnew = evriio(mfilename,X,options);
  end
  return;
end

if nargin < 3 | isempty(options);
  options = ife('options');
else
  options = reconopts(options,'ife');
end


if length(options.method)<4
  error(['The option method should be either ''lakowicz'' or ''gauthier'''])
end


if length(size(X))~=3
  error(['The first input must be a three-way array with samples in the first mode and then emissions and excitations. This file is ',num2str(length(size(X))),'-way'])
end
try
  em = X.axisscale{2};
  ex = X.axisscale{3};
catch
  error('The dataset should contain the emission mode wavelengths in the second mode and excitations in the third mode')
end
A = absspec.data;
A(find(A<0))=0; % Negative values are a no-go
if size(A,1)~=size(X,1)
  error('There should be equally many rows in the two inputs')
end
Aax = absspec.axisscale{2};    

if strcmpi(options.method(1:3),'lak')
  Xnew=X;
  %XXXxxx
  % Puchalski, Fresenius J Anal Chem (1991) 340:341 -344
  % Lakowicz, 1999
  for i=1:size(Xnew,1)
      EmAbs = interp1(Aax,A(i,:),em,'spline');
      ExAbs = interp1(Aax,A(i,:),ex,'spline');
      At = repmat(EmAbs(:),1,length(ExAbs)) + repmat(ExAbs(:)',length(EmAbs),1);
      EEMCorrection = 10.^(.5*At);
      thisone=squeeze(Xnew.data(i,:,:));
      Xnew.data(i,:,:) = thisone.*EEMCorrection;
  end

% Attempt for non-symmetric cuvette but it doesn't work in this version
%   for i=1:size(Xnew,1)
%     EmAbs = interp1(Aax,A(i,:),em,'spline');
%     ExAbs = interp1(Aax,A(i,:),ex,'spline');
%     Em_abs = 2.303*EmAbs/(options.pathlength/1000); %a = log10(10)*A/pathlength in meters
%     Ex_abs = 2.303*ExAbs/(options.emissionpathlength/1000);
%     for j=1:size(Xnew,2)
%       for k=1:size(Xnew,3);
%         EEMCorrection(j,k) = 10.^(.005*(EmAbs(j)+ExAbs(k))/2.303);
%       end
%     end
%     thisone=squeeze(Xnew.data(i,:,:));
%     Xnew.data(i,:,:) = thisone.*EEMCorrection;
%   end
  
elseif strcmpi(options.method(1:3),'gau')
else
  disp(' The input in options.method not recognized:')
  options.method
  error(['It should be either ''lakowicz'' or ''gauthier'''])
end


function X=eemscat(X);

%EEMSCAT for removing Rayleigh and Raman scattering from fluorescence
%        EEM data and interpolating the excised areas. Missing data are
%        interpolated
%
% INPUT:
%    X      X-array of EEMs. X is size IxJxK, where I is number of
%           samples, J emissions and K excitations. X has to be a
%           dataset object where the axisscales contain wavelengths.
%           You can convert an array to a dataset doing
%           X = dataset(X);
%           X.axisscale{2} = EmAx; % The emission wavelengths (nm)
%           X.axisscale{3} = ExAx; % The excitation wavelengths (nm)
%
% OUTPUT:
%
% NewEEM     EEM data with interpolated areas.
%
% Additional optional output
% EEMNaN    EEM data with missing data rather than interpolated values

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Morteza Bahram - morteza.bahram@gmail.com
% &
% Rasmus Bro - rb@food.ku.dk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin<1
  error('At least one input must be given in EEMSCAT');
end
ax=X.axisscale{2};    %%%%  emission axcisscale
ax2=X.axisscale{3};  %%%%  excitation axcisscale
Q=isnan(X.data);  %%% NaN element at the original data due to emission out

%%%%%%%%%  Interpolating the latest line of emission at every sample
EEM_correct = X.data;
for j=1:size(X,1);  % LOPE FOR EVERY SAMPLE
  ppp=squeeze(EEM_correct(j,end,:));  %%%%%%% the last EMISSION vector in every sample
  w= ~isnan(ppp);
  ww=find(w==1);
  Eendcut=ppp(ww);  %%% the last CUTTED EMISSION vector in every sample
  ax2cut=ax2(ww);      %%% Cutted EMISSION AXIS
  mm=interp1(ax2cut,Eendcut,ax2,'pchip','extrap'); %%% interpolation using cubic option
  ffff=find(mm<0);
  mm(ffff)=0;   %% Forcing Non negativity at the interpolation
  EEM_correct(j,end,:)=mm;
end

%%%%%%  Interpolation  %%%%%%%%%%%
for j=1:size(X,1);  % LOOP FOR EVERY SAMPLE
    for i=1:length(ax2);  % LOOP FOR EVRY EXCITATION WAVELENGHT
        dd=EEM_correct(j,:,i);
        gg= ~isnan(dd);
        ff=find(gg==1);
        Ecut=dd(ff);       %%% CUTTED EMISSION
        axcut=ax(ff);      %%% Cutted EMISSION AXIS
        if ~isnan(dd(1));
            p=interp1(axcut,Ecut,ax,'pchip'); %%% interpolation using cubic option
        else
            p=interp1([min(axcut)-15 min(axcut)-10 axcut],[0 0 Ecut],ax,'pchip'); %%% interpolation using cubic option
        end
        EEM_correct(j,:,i)=p;
    end
end

X.data = EEM_correct;



%----------------------------------------------------------
function out = optiondefs
defs = {
  %Name                         Tab             Datatype        Valid                         Userlevel       %Description
  'MakeWts'                     'Display'       'select'        {'on' 'off'}                  'novice'        'If ''on'', weights will be given that can be used to downweight areas of scatter e.g., in PARAFAC models. The weights will be held in the output dataset field ''userdata''. {default = ''off'', do not create weights}'
  'plots'                       'Display'       'select'        {'final' 'all' 'off'}         'novice'        'Turn plotting of final model on or off. By choosing ''all'' you can choose to see the loadings as the iterations proceed. The final plot can also be produced using the function MODELVIEWER after the model has been fitted.';
  };

out = makesubops(defs);
