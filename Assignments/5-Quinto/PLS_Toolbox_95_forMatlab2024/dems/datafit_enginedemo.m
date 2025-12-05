echo on
% DATAFIT_ENGINEDEMO Demo of the DATAFIT_ENGINE function
 
echo off
% Copyright © Eigenvector Research, Inc. 2011
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
 
echo on
 
% INPUT = 1 for Smoothing demo.
% INPUT = 2 for Baselining demo.
% INPUT = 3 gives a robust curve fitting demo with options.trbflag = 'middle'.
% INPUT = 4 gives a robust curve fitting demo with options.trbflag = 'bottom'.
% INPUT = 5 is simliar to 4 but adds the use of basis functions.
% INPUT ~= any(1:5) cancels the demo.
 
echo off

si      = input('Input 1, 2, 3, 4 or 5: ');
if isempty(si), si = 0; end

switch si
case 1 % Smoothing demo.
  
  echo on
  
  % To run the demo hit a "return" after each pause
  pause
  %-------------------------------------------------
  % The DATAFIT_ENGINE function uses a Whittaker smoother that fits the data (y)
  % with a curve (z) using a penalty function on a measure of the 'roughness'.

  % To examine how to use the function, load some data and make a plot.

  pause
  load oesdata
  echo off
  h       = figure('Name','DATAFIT_ENGINEDEMO'); g = zeros(1,3);
  v       = [245 455  0 600;
             300 320  0  75;
             380 410  0 560];
  atitle  = {'Full Spectrum','245 to 455 nm','380 to 410 nm'};
  for i1=1:3
    g(i1) = subplot(3,1,i1);
    plot(oes1.axisscale{2},oes1.data(1,:)); hold on
    title(atitle{i1}), grid
    axis(v(i1,:))
  end, xlabel('Wavelength (nm)')

  echo on
  % The OES spectrum is fairly noisy around the baseline.
  % It is more clear if the figure height is increased.
  % 
  % The smoother is called w/ it's default parameters using
   
  [yb,z]  = datafit_engine(oes1); %output z is the smoothed signal
  
  pause
  echo off
  figure(h)
  for i1=1:3
    axes(g(i1))
    plot(oes1.axisscale{2},z.data(1,:),'color',[0.6 0.5 0]);
    if i1==1
      legend('Original Signal','Slightly Smoothed Signal','location','north')
    end
  end
  
  echo on
  % The smoothing is fairly reasonable but not very strong.
  % The small peak at 309 nm is preserved and the noise is slightly suppressed.
  % The larger peak at 396 nm was also slightly suppressed.
  pause 
  % The smoothness can be enhanced by increasing the roughness penalty
  opts    = datafit_engine('options');
  opts.lambdas = 10; %increase the roughness penalty from 1 to 10.
  [yb2,z2]     = datafit_engine(oes1,opts);   %call wsmooth with new options
  pause
  echo off
  figure(h), g2 = zeros(1,3);
  for i1=1:3
    axes(g(i1))
    plot(oes1.axisscale{2},z2.data(1,:),'color',[0 0.5 0]);

    if i1==1
      legend('Original','Slightly Smoothed','Strong Smooth','location','north')
    end
  end
  echo on
  % The smoothing is fairly strong now.
  % The small peak at 309 nm is more suppressed and
  % the larger peak at 396 nm was also highly suppressed.
   
  % Next, the roughness penalty for specific channels will be reduced.
   
  pause
  opts.ws   = ones(1,size(oes1,2)); %initalize local wt's for roughness penalty
  
  %drop wt's for selected regions
  opts.ws(oes1.axisscale{2}>258 & oes1.axisscale{2}<280) = 0.01;
  opts.ws(oes1.axisscale{2}>307 & oes1.axisscale{2}<311) = 0.01;  
  opts.ws(oes1.axisscale{2}>393 & oes1.axisscale{2}<397) = 0.01; 
  
  %call wsmooth with new options
  [yb3,z3] = datafit_engine(oes1,opts);
  echo off
  figure(h)
  for i1=1:3
    axes(g(i1))
    plot(oes1.axisscale{2},z3.data(1,:),'-','color',[0.9 0.7 0]);
    if i1==1
      legend('Original','Smoothed','Strong Smooth','low penalty on peaks',...
        'location','north')
    end
  end
  
  echo on
  % This shows strong smoothing away from the peaks while
  % doing a better job of preserving the peaks.
  pause
  % Reset wt's for roughness penalty and instead use trbflag = 'middle'
  % to treat peaks as "outliers".
  opts.ws   = ones(1,size(oes1,2));
  opts.lambdas = 1e5;              %increase the roughness penalty from 10 to 1e5.
  opts.trbflag = 'middle';         %use a robust fitting strategy
  [yb4,z4] = datafit_engine(oes1,opts);  %call wsmooth with new options
  pause
  echo off
  figure(h)
  for i1=1:3
    axes(g(i1))
    plot(oes1.axisscale{2},z4.data(1,:), '-','color',[0 0.8 0.8]); %plots z
    plot(oes1.axisscale{2},yb4.data(1,:),'-','color',[0.8 0 0.8]); %plots y-z
    v  = axis; axis([v(1:2) -40 v(4)]); hline(0,'k--')
    if i1==1
      legend('Original','Smoothed','Strong Smooth','low penalty on peaks',...
        'peaks ignored','estimate of baselined data','location','north')
    end
  end
  
  echo on
  % This shows strong smoothing and fits the bulk of the data.
  echo off
  
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
case 2 % Baselining demo.
  echo on

  % To run the demo hit a "return" after each pause
  pause
  %-------------------------------------------------
  % To baseline, the DATAFIT_ENGINE function uses a Whittaker smoother that
  % fits the bottom of the data (y) with a curve (z) using a penalty function
  % measure of the 'roughness'.

  % To examine how to use the function, load some data and make a plot.
  pause
  load oesdata
  echo off
  h       = figure('Name','DATAFIT_ENGINEDEMO'); g = zeros(1,3);
  v       = [245 455  0 600;
             300 320  0  75;
             380 410  0 560];
  atitle  = {'Full Spectrum','245 to 455 nm','380 to 410 nm'};
  for i1=1:3
    g(i1)  = subplot(3,1,i1); title(atitle{i1})
    plot(oes1.axisscale{2},oes1.data(1,:)); hold on
    title(atitle{i1})
    axis(v(i1,:))
  end, xlabel('Wavelength (nm)')

  echo on
  % The OES spectrum is fairly noisy around the baseline but the peaks
  % look pretty clean (not noisy).
  % 
  % The default parameters are changed to fit to the bottom of the spectra
  % using the following two sets of options:
  
  pause
  % set 1
  options = datafit_engine('options');
  options.trbflag = 'bottom'; % change trbflag to fit to the bottom (baseline)
  options.lambdas = 1e5;      % lambda_s is the smoothing penalty set high
  [yb1,z1]        = datafit_engine(oes1(1,:),options);
  % set 2
  options.knotp   = 1;   % use B3 spline basis w/11 interior knots see SMOOTHBASIS 
  options.orderp  = 3;   % augment with third order polynomial see POLYBASIS
  options.lambdab = 1e5; % lambda_b is the basis penalty set high
  options.we      = zeros(1,size(oes1,2)); % add an equality constraint for the
  options.we(oes1.axisscale{2}<258) = 1;   % baseline for <258 nm
  options.ye      = NaN(1,size(oes1,2));
  options.ye(oes1.axisscale{2}<258) = 0;
  options.lambdae = 1e7;
  [yb2,z2]        = datafit_engine(oes1(1,:),options);

  pause
  % Plot the the baseline corrected signal w/out basis functions
  echo off
  figure(h)
  for i1=1:3
    axes(g(i1))
    plot(oes1.axisscale{2},yb1.data(1,:),'r'); grid
    plot(oes1.axisscale{2},z1.data(1,:), '-','color',[0 0.5 0]);
    if i1==1
      legend('Original Signal','Baselined Signal','Baseline','location','north')
    end
  end
  
  pause
  echo on
  % Plot the second run w/ basis functions included
  echo off
  figure(h)
  for i1=1:3
    axes(g(i1))
    plot(oes1.axisscale{2},yb2.data(1,:),'-','color',[0.8 0.6 0]);
    plot(oes1.axisscale{2},z2.data(1,:), '-','color',[0 1 0]);
    v  = axis; axis([v(1:2) -40 v(4)]); hline(0,'k--')
    if i1==1
      legend('Original Signal','Baselined Signal','Baseline', ...
             'Baselined Signal w/ basis','Baseline  w/ basis','location','north')
    end
  end
  echo on
  pause
  % Note that the use of basis functions has restricted z to be smoother
  % and <258 nm now has a zero baseline.
  echo off
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
  case 3
  echo on
  % To run the demo hit a "return" after each pause
  pause
  %-------------------------------------------------

  % The first part of the demo shows how two curves [temperatures versus
  % time] can be smoothed using DATAFIT_ENGINE
  % a) without robust fitting [options.trbflag = 'none'], and
  % b) with    robust fitting [options.trbflag = 'middle'].
  % The effect of the smoothness penalty [options.lambdas] is also
  % exlored.
  
  pause
  % Load (plsdata)
  % (xblock1) corresponds to 20 temperatures measured in a slurry fed
  % ceramic melter (SFCM) [see PLSDEMO for more information].
  % (yblock1) is the corresponding level measurement w/in the melter.

  load('plsdata.mat','xblock1','yblock1')
  pause
  % Test 1. Smooth temperatures 8 & 10 w/o robust fitting [options.trbflag = 'none'].
  opts         = datafit_engine('options');
  opts.trbflag = 'none';                  %[options.trbflag = 'none']
  lambdas      = [10 100 1000 1e4];       % penalty
  
  pause
  % Initialize variables for results and generate plots
  echo off
  z08a         = zeros(length(lambdas),size(xblock1,1)); %smoothed Temperature 8
  g08          = zeros(1,5);                             %smoothed Temperature 10
  z10a         = z08a;
  g10          = g08;
  
  colors       = [1.   0.7  0.4 ;
                  0.9  0.4  0.2 ;
                  0.8  0.2  0.1 ;
                  0.7  0.1  0. ];
  lgnd         = {'Measured';'\lambda_s = 1';'\lambda_s = 10';'\lambda_s = 1e3';'\lambda_s = 1e4'};
  h08          = figure('Name','T_08, trbflag = "none"'); v = get(h08,'position');      
  g08(1)       = plot(xblock1.data(:, 8),'-','color',[0 0.447 0.741]); hold on
  xlabel('Sample Point'), ylabel('T_{08}\rm(C)'), grid, figfont
  h10          = figure('Name','T_10, trbflag = "none"'); set(h10,'position',v-[25 25 0 0]);
  g10(1)       = plot(xblock1.data(:,10),'-','color',[0 0.447 0.741]); hold on
  xlabel('Sample Point'), ylabel('T_{10}\rm(C)'), grid, figfont

  echo on
  pause
  % Loop through and set the lambda values (10, 100, 1000, and 1e4) and run
  % DATAFIT_ENGINE and plot the results.
  pause
  echo off
  for i1=1:length(lambdas)
    opts.lambdas   = lambdas(i1); %set the penalty parameter

    [yb,z08a(i1,:),optz] = datafit_engine(xblock1(:, 8)',opts);
    figure(h08), g08(i1+1)=plot(z08a(i1,:),'-','linewidth',2,'color',colors(i1,:));

    [yb,z10a(i1,:),optz] = datafit_engine(xblock1(:,10)',opts);
    figure(h10), g10(i1+1)=plot(z10a(i1,:),'-','linewidth',2,'color',colors(i1,:));
  end
  figure(h08), legend(g08,lgnd,'location','southwest'), figfont
  figure(h10), legend(g10,lgnd,'location','southeast'), figfont

  echo on
  pause
  % As expected, the smoothing increases as the penalty lambdas increases.
  % At lamdas=10 there is little smoothing and at lamdas=1e4 the fitted
  % curve is very smooth.

  pause
  % Test 2. Smooth temperatures 8 & 10 w/ robust fitting [options.trbflag = 'middle'].
  opts.trbflag = 'middle'; %[options.trbflag = 'middle']
  opts.tol     = 2;        %tolerance on the residuals set manually to 2.
  pause
  % Initialize variables for results and generate plots
  echo off
  z08b         = zeros(length(lambdas),size(xblock1,1));
  z10b         = z08b;
  
  echo off
  
  h08          = figure('Name','T_08, trbflag = "middle"'); v = get(h08,'position'); 
  g08(1)       = plot(xblock1.data(:, 8),'-','color',[0 0.447 0.741]); hold on
  xlabel('Sample Point'), ylabel('T_{08}\rm(C)'), grid, figfont
  h10          = figure('Name','T_10, trbflag = "middle"');  set(h10,'position',v-[25 25 0 0]);
  g10(1)       = plot(xblock1.data(:,10),'-','color',[0 0.447 0.741]); hold on
  xlabel('Sample Point'), ylabel('T_{10}\rm(C)'), grid, figfont
  echo on
  % Loop through and set the lambda values (10, 100, 1000, and 1e4) and run
  % DATAFIT_ENGINE and plot the results.
  pause
  echo off
  for i1=1:length(lambdas)
    opts.lambdas   = lambdas(i1);

    [yb,z08b(i1,:),optz] = datafit_engine(xblock1(:, 8)',opts);
    figure(h08), g08(i1+1)=plot(z08b(i1,:),'-','linewidth',2,'color',colors(i1,:));

    [yb,z10b(i1,:),optz] = datafit_engine(xblock1(:,10)',opts);
    figure(h10), g10(i1+1)=plot(z10b(i1,:),'-','linewidth',2,'color',colors(i1,:));
  end
  echo off
  figure(h08), legend(g08,lgnd,'location','southwest'), figfont
  figure(h10), legend(g10,lgnd,'location','southeast'), figfont

  % As expected, the smoothing increases as the penalty lambdas increases.
  % At lamdas = 10 there is little smoothing and at lamdas = 1e4 the
  % fitted curve is very smooth.

  % Next, compare the results from the two runs w/ & w/o robust fitting.

  pause
  % Create plots to compare test results
  echo off

  figure('Name','T_08, compare trbflag = "none" and "middle"');
  g            = zeros(1,2);
  subplot(2,1,1)
  for i1=1:2
    g(1,i1)    = plot(z08a(i1,:)','-','linewidth',2,'color',colors(i1,:)); hold on
                 plot(z08b(i1,:)','-','linewidth',2,'color',1-exp(-[0.5 0.5 1]*i1))
                 plot(z08b(i1,:)',':','linewidth',2,'color',colors(i1,:));
  end
  title('trbflag: "none" (solid), "middle" (dashed)')
  grid, legend(g,lgnd(2:3),'location','southwest'), ylabel('T_{08}\rm(C)')
  subplot(2,1,2)
  for i1=1:2
    g(1,i1)    = plot(z08a(i1+2,:)','-','linewidth',2,'color',colors(i1,:)); hold on
                 plot(z08b(i1+2,:)','-','linewidth',2,'color',1-exp(-[0.5 0.5 1]*i1))
                 plot(z08b(i1+2,:)','--','linewidth',2,'color',colors(i1,:));
  end
  xlabel('Sample Point')
  grid, legend(g(1:2),lgnd(4:5),'location','southwest'), ylabel('T_{08}\rm(C)'), figfont

  figure('Name','T_10, compare trbflag = "none" and "middle"');
  g            = zeros(1,2);
  subplot(2,1,1)
  for i1=1:2
    g(1,i1)    = plot(z10a(i1,:)','-','linewidth',2,'color',colors(i1,:)); hold on
                 plot(z10b(i1,:)','-','linewidth',2,'color',1-exp(-[0.5 0.5 1]*i1))
                 plot(z10b(i1,:)',':','linewidth',2,'color',colors(i1,:));
  end
  title('trbflag: "none" (solid), "middle" (dashed)')
  grid, legend(g,lgnd(2:3),'location','southwest'), ylabel('T_{10}\rm(C)')
  subplot(2,1,2)
  for i1=1:2
    g(1,i1)    = plot(z10a(i1+2,:)','-','linewidth',2,'color',colors(i1,:)); hold on
                 plot(z10b(i1+2,:)','-','linewidth',2,'color',1-exp(-[0.5 0.5 1]*i1*2))
                 plot(z10b(i1+2,:)','--','linewidth',2,'color',colors(i1,:));
  end
  xlabel('Sample Point')
  grid, legend(g(1:2),lgnd(4:5),'location','southwest'), ylabel('T_{10}\rm(C)'), figfont

  echo on
  % Note that the robust fitting tends to have a smoother curve than the
  % non-robust fitting because the robust method is using only the bulk of
  % the data to provide a smooth curve. I.e., robust fitting is not
  % influenced by points at the extreme highs and lows.

  % One more test is run with robust fitting to show how it can be used to
  % characterize long and short term trends in the data (i.e., low and high
  % frequency signals).

  pause
  % Test 3. Characterize long and short term trends
  opts.trbflag = 'middle';  %'middle' uses robust fitting, 'none' does not use robust fitting
  opts.lambdas = 1e5;       %strong smoothing !!
  opts.tol     = 1;         % residuals w/in tolerance define samples to keep and reject in the fit 
  opts.ws      = ones(1,300);
  opts.ws([72:74 277:280]) = 0.1; %de-weight known outliers

  [yb,z,optz]  = datafit_engine(xblock1',opts); %run DATAFIT_ENGINE 
  z            = z'; yb = yb';
  
  echo off
  figure('Name','Robust Smoothing T_08')
  subplot(2,1,1), g = zeros(1,3);
  g(1)         = plot(xblock1.data(:,8),'-'); hold on
  g(2)         = plot(z.data(:,8));
  x1           = delsamps(xblock1.data(:,8),[73 278 279]); %Remove known outliers for comparison
  y1           = delsamps(yblock1.data,     [73 278 279]);
  g(3)         = hline(mean(x1),'r');
  set(g(3),'linewidth',0.5), uistack(g,'bottom')
  xlabel('Sample Point'), ylabel('T_{08}\rm(C)'), grid
  legend(g,'Measured','Long Term Trend = output (z)','Mean','location','southwest')
  subplot(2,1,2)
  g(1)         = plot(mncn(xblock1.data(:,8)),'-'); hold on
  g(2)         = plot(yb.data(:,8));
  set(hline('--k'),'linewidth',2)
  xlabel('Sample Point'), ylabel('T_{08}\rm(C)'), grid
  legend(g(1:2),'Measured (mean centered)','Short Term Trend = output (yb)','location','southwest'), figfont

  echo on
  pause
  % The upper plot shows a long term "quadradic" response and the lower plot 
  % shows just the "sawtooth" pattern. Note that the main differences between
  % the mean-centered signal and the processed signal are observed at the
  % beginning and end of the time-series.
   
  b = y1\x1; %scale the level to the temperature for comparison
  g(3)         = plot(mncn(yblock1.data*b),'-');
  legend(g,'Measured (mean centered)','Short Term Trend = output (yb)','Measured Level (centered and scaled)','location','southwest')
   
  % The "sawtooth" pattern is also seen in the level.

  pause
  echo off
  figure('Name','Robust Smoothing T_10')
  subplot(2,1,1), g = zeros(1,2);
  g(1)         = plot(xblock1.data(:,10),'-'); hold on
  g(2)         = plot(z.data(:,10));
  xlabel('Sample Point'), ylabel('T_{10}\rm(C)'), grid
  legend(g,'Measured','Long Term Trend = output (z)','location','southeast')
  subplot(2,1,2)
  g(1)         = plot(mncn(xblock1.data(:,10)),'-'); hold on
  g(2)         = plot(yb.data(:,10));
  set(hline('--k'),'linewidth',0.5)
  xlabel('Sample Point'), ylabel('T_{10}\rm(C)'), grid
  legend(g,'Measured (mean centered)','Short Term Trend = output (yb)','location','southeast'), figfont
   
  echo off
  clear g08 g10 h08 h10 i1 g lgnd colors b
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
case 4
  echo on
  % To run the demo hit a "return" after each pause
  pause
  %-------------------------------------------------
  % Please run datafit_engine demo with option "1" before running with 
  % option "4".
  
  pause
  % The DATAFIT_ENGINE function uses a Whittaker smoother that fits the data (y)
  % with a curve (z) using a penalty function on a measure of the 'roughness'.
  % When the demo is run with option "1" (z) was the the output of
  % interest. In this demo (option "4") the demo will fit a curve (z) to
  % the bottom of the example spectrum using options.trbflag = 'bottom', and
  % output (yb) will be a baselined signal - it is the output of interest.
 
  % To examine how to use the fuction, load the OES data and make a plot.
  
  pause
  load oesdata
  echo off
  h       = figure('Name','DATAFIT_ENGINEDEMO Baselined'); g = zeros(1,3);
  v       = [245 455  -10 600;
             300 320  -10  75;
             380 410  -10 560];
  atitle  = {'Full Spectrum','245 to 455 nm','380 to 410 nm'};
  for i1=1:3
    g(i1) = subplot(3,1,i1);
    plot(oes1.axisscale{2},oes1.data(1,:)); hold on
    title(atitle{i1}), grid
    axis(v(i1,:))
  end, xlabel('Wavelength (nm)')

  echo on
  % The OES spectrum has a significant baseline offset and is fairly noisy
  % around the baseline with a standard deviation of ~4. (This can be verified
  % by inspecting the plots in detail after the demo.)
   
  % Next, the default parameters for the DATAFIT_ENGINE function will be
  % modified to fit a smooth function (z) to the bottom of the OES spectra.
  % This smooth function will be used as the baseline.
   
  pause
  opts         = datafit_engine('options');
  opts.tol     = 4;        % ~std(noise)
  opts.trbflag = 'bottom'; % flag to fit to bottom of the spectrum
  opts.lambdas = 1e5;      % high smoothing penalty
   
  [yb,z,optb]  = datafit_engine(oes1,opts);
  % y  is the input signal (oes1),
  % z  is the smoothed signal i.e., the baseline, and
  % yb is the baselined signal (yb = y - z)
  
  echo off
  figure(h)
  for i1=1:3
    axes(g(i1))
    plot(oes1.axisscale{2},z.data(1,:), 'color',[0.6 0.5 0]); hold on
    plot(oes1.axisscale{2},yb.data(1,:),'color',[0.8 0.1 0]);
    if i1==1
      legend('Original Signal','baseline','baselined signal','location','north')
    end
  end, xlabel('Wavelength (nm)')
  
  pause
  echo on
  % Setting opts.trbflag = 'bottom' tells DATAFIT_ENGINE to use an
  % asymmetric least-squares fit to the bottom of the OES spectra.
  % The smoothed fit (z) contains the baseline of the spectra and 
  % (yb) [yb = y - z] is the baselined spectra.
 
  % However, note that the baselined spectrum in the figure is pretty noisy
  % at the baseline. Next, DATAFIT_ENGINE will be used to smooth the
  % signal around the baseline.
  
  pause
  % The objective is to smooth just the regions near the baseline. This can
  % be done by first setting up a vector of weights for individual points
  % in the spectra. (Recall that Ws = diag(opts.ws) corresponds to the
  % individual smoothing weights.) Then set the weights where peaks are
  % present to a low value so as to not smooth the peaks. Finally, set 
  % opts.trbflag = 'none' so use least-squares instead of robust fitting.
  
  opts.ws = ones(1,size(oes1,2));           % initialize Ws
  opts.ws(yb.data(1,:)>opts.tol) = 0.00001; % set Ws with high signal to a low value
  opts.trbflag = 'none';                    % flag to fit to bottom of the spectrum
  opts.lambdas = 1e3;                       % lower the smoothing penalty
  
  % Run DATAFIT_ENGINE with the baselined signal (yb) as the input
  % and plot the results
  
  pause
  echo off
  h       = figure('Name','DATAFIT_ENGINEDEMO Baselined/Smoothed'); g = zeros(1,3);  
  [yb1,z1,optb]  = datafit_engine(yb,opts);
  figure(h), v(1,4) = 520; v(2,4) = 40; v(3,4) = 520;
  for i1=1:3
    g(i1) = subplot(3,1,i1);
    plot(oes1.axisscale{2},yb.data(1,:)); hold on
    title(atitle{i1}), grid
    axis(v(i1,:)), xlabel('Wavelength (nm)')
    plot(oes1.axisscale{2},z1.data(1,:), 'color',[0.6 0.5 0]); hold on
    plot(oes1.axisscale{2},yb1.data(1,:),'color',[0.8 0.1 0]);
    if i1==1
      legend('Original Baselined Signal','Smoothed Baselined Signal','"Noise" Signal','location','north')
    end
  end
  echo off
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
case 5
  echo on
  % To run the demo hit a "return" after each pause
  pause
  %-------------------------------------------------
  % datafit_engine demo with option "5" is similar to
  % option "4" except it adds the use of a basis function.
  
  pause
   
  % The DATAFIT_ENGINE function uses a Whittaker smoother that fits the data (y)
  % with a curve (z) using a penalty function on a measure of the 'roughness'.
  % In the demo with option "4" a smooth curve (z) was fit to the bottom of
  % of an example spectrum using options.trbflag = 'bottom' and output (yb)
  % was a baselined signal - the output of interest. This was followed by a
  % second call to DATAFIT_ENGINE that smoothed the baselined signal. In
  % that case the output of interest was (z) not (yb).
   
  % In this example, the same two calls to DATAFIT_ENGINE are made. The
  % difference is that in this example the first call will use a basis
  % function as well as a roughness penalty.
 
  % Load the OES data and make a plot.
   
  pause
  load oesdata
  echo off
  h       = figure('Name','DATAFIT_ENGINEDEMO Baselined'); g = zeros(1,3);
  v       = [245 455  -10 600;
             300 320  -10  75;
             250 285  -10 560];
  atitle  = {'Full Spectrum','245 to 455 nm','380 to 410 nm'};
  for i1=1:3
    g(i1) = subplot(3,1,i1);
    plot(oes1.axisscale{2},oes1.data(1,:)); hold on
    title(atitle{i1}), grid
    axis(v(i1,:))
  end, xlabel('Wavelength (nm)')
  
  echo on
  pause

  % The OES spectrum has a significant baseline offset and is fairly noisy
  % around the baseline with a standard deviation of ~4. (This can be verified
  % by inspecting the plots in detail after the demo.)
   
  % Next, the default parameters for the DATAFIT_ENGINE function will be
  % modified to fit a smooth function (z) to the bottom of the OES spectra.
  % This smooth function will be used as the baseline.
   
  pause
   
  opts         = datafit_engine('options');
  opts.tol     = 4;        % ~std(noise)
  opts.trbflag = 'bottom'; % flag to fit to bottom of the spectrum
  opts.lambdas = 1e5;      % high smoothing penalty
   
  [yb1,z1]  = datafit_engine(oes1,opts);
  % y   is the input signal (oes1),
  % z1  is the smoothed signal i.e., the baseline, and
  % yb1 is the baselined signal (yb = y - z)
   
  echo off
  figure(h)
  for i1=1:3
    axes(g(i1))
    plot(oes1.axisscale{2},z1.data(1,:), 'color',[0.6 0.5 0]); hold on
    plot(oes1.axisscale{2},yb1.data(1,:),'color',[0.8 0.1 0]);
    if i1==1
      legend('Original Baselined Signal','Smoothed Baselined Signal','"Noise" Signal','location','north')
    end
  end, xlabel('Wavelength (nm)')
  
  echo on 
  % Setting opts.trbflag = 'bottom' tells DATAFIT_ENGINE to use an
  % asymmetric least-squares fit to the bottom of the OES spectra.
  % The smoothed fit (z) contains the baseline of the spectra and 
  % (yb) [yb = y - z] is the baselined spectra.
   
  pause
  echo off
  h2      = figure('Name','DATAFIT_ENGINEDEMO Baselines', ...
    'position',get(h,'position')+[10 -10 0 0]);
  plot(oes1.axisscale{2},z1.data)
  axis([v(1,1:2) 0 220]), grid
  xlabel('Wavelength (nm)')
  ylabel('Baseline Spectra')
  
  echo on
  % Notice that the baselines are fairly complex and non-linear wrt
  % wavelength. It may be desired that the region 245 to 350 nm be more
  % flat i.e., less flexible. The input options will be changed to add a
  % simple offset in this region using basis functions in DATAFIT_ENGINE.
  
  % An offset is set by setting the polynomial order (orderp) to 0. The
  % weights are set to 1 in the 245 to ~350 nm region and to 0 for >350 nm
  % using a sigmoid function to allow for a smooth transition in the weighting.
   
  pause
  opts.orderp  = 0;    % Polynomial order for the basis function
  opts.lambdab = 1e2;  % Fit penalty for the basis function
  opts.wb      = (1+peaksigmoid([1 270 -0.2],oes1.axisscale{2}))/2; % wts
  
  [yb2,z2]  = datafit_engine(oes1,opts);
  % y   is the input signal (oes1),
  % z2  is the smoothed signal i.e., the baseline, and
  % yb2 is the baselined signal (yb = y - z)
   
  % Next, plot the new baselines.
   
  pause
  echo off
  h3      = figure('Name','DATAFIT_ENGINEDEMO Baselines', ...
                   'position',get(h2,'position')+[10 -10 0 0]);
  [hax,hh1,hh2] = plotyy(oes1.axisscale{2},z2.data,oes1.axisscale{2},opts.wb);
  hax(1).XLim = v(1,1:2); hax(1).YLim = [0 220];
  hax(2).XLim = v(1,1:2); hax(2).YLim = [0 1];  grid
  hax(1).YLabel.String = 'Baseline Spectra';
  hax(2).YLabel.String = 'Basis Weights';
  xlabel('Wavelength (nm)')
  
  echo on
  % Notice how the baselines are now flatter in the 245 to ~350 nm region.
   
  % However, as was seen in DATAFIT_ENGINE with option "4", the baselined
  % spectrum in the figure is pretty noisy at the baseline. Therefore,
  % DATAFIT_ENGINE will be used to smooth the signal around the baseline.
  
  pause
  % The objective is to smooth just the regions near the baseline. This can
  % be done by first setting up a vector of weights for individual points
  % in the spectra. (Recall that Ws = diag(opts.ws) corresponds to the
  % individual smoothing weights.) Then set the weights where peaks are
  % present to a low value so as to not smooth the peaks. Finally, set 
  % opts.trbflag = 'none' so use least-squares instead of robust fitting and
  % opts.lambdab = 0 to remove the basis function penalty.
  
  opts.ws = ones(1,size(oes1,2));            % initialize Ws
  opts.ws(yb2.data(1,:)>opts.tol) = 0.00001; % set Ws with high signal to a low value
  opts.trbflag = 'none';                     % flag to fit to bottom of the spectrum
  opts.lambdas = 1e3;                        % lower the smoothing penalty
  opts.lambdab = 0;                          % remove the basis function penalty
  
  % Run DATAFIT_ENGINE with the baselined signal (yb2) as the input
  % and plot the results
  
  pause
  echo off
  h       = figure('Name','DATAFIT_ENGINEDEMO Baselined/Smoothed'); g = zeros(1,3);  
  [yb3,z3]  = datafit_engine(yb2,opts);
  figure(h), v(1,4) = 520; v(2,4) = 40; v(3,4) = 520;
  for i1=1:3
    g(i1) = subplot(3,1,i1);
    plot(oes1.axisscale{2},yb2.data(1,:)); hold on
    title(atitle{i1}), grid
    axis(v(i1,:)), xlabel('Wavelength (nm)')
    plot(oes1.axisscale{2},z3.data(1,:), 'color',[0.6 0.5 0]); hold on
    plot(oes1.axisscale{2},yb3.data(1,:),'color',[0.8 0.1 0]);
    if i1==1
      legend('Original Baselined Signal','Smoothed Baselined Signal','"Noise" Signal','location','north')
    end
  end
  echo off
otherwise
  % 
  % DATAFIT_ENGINEDEMO canceled
end
echo on
 
% End of DATAFIT_ENGINEDEMO
 
echo off
