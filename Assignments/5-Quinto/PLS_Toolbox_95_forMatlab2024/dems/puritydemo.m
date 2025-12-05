echo on
%PURITYDEMO Demo of purity function
 
echo off
% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¬, without
%  written permission from Eigenvector Research, Inc.
 
answer = menu('Choose demo of purity',...
  'Raman spectra of time resolved reaction',...
  'FTIR microscopy spectra of a three layer polymer laminate, use of 2nd derivative pure variables',...
  'MS time resolved data, pure spectrum to pure variable solution',...
  'Raman spectra, combined use of conventional and 2nd derivative pure variables',...
  'All');
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
echo off
%switch answer
%case{1,5};
if (answer==1)|(answer==5);
  echo on;
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
  %The first demo is the most basic use of the function purity. We read a file with
  %a time resolved Raman spectroscopy data set and resolve 4 components.
  %First, we will load and plot the data.
  pause
%-------------------------------------------------
  load raman_time_resolved
  plot(raman_time_resolved.axisscale{2},raman_time_resolved.data);
  pause;
%-------------------------------------------------
  close;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
  %When we run the purity program we will see the following.
  %A figure with two spectra. The top spectrum is the length (2-norm) spectrum, which has a
  %similar appearance as the original spectra. The bottom spectrum is the purity 
  %spectrum. The maximum in this spectrum is the pure(st) variable. This point is
  %marked in both spectra. Clicking the mouse eliminates the contributions associated
  %with the pure variable. This process goes on until we selected all pure variables.
  %The previously selected pure variables are indicated with green markers.
  %After this the resolved spectra and contribution profiles are plotted.
  %We run the program for four components:
  pause
%-------------------------------------------------
  options=purity('options');
  options.display='off';
  options.demo = 1;
  purity(raman_time_resolved,4,options);
  echo off;
  close;
end;
if (answer==2)|(answer==5);
  
  %case{2,5};
  echo on;
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %The next file contains FTIR microscopy data of a three layered polymer laminate.
  %The middle layer needs to be resolved, since it is below the resolution of the 
  %spectroscopy. The polymer laminate is schematized below with the three layers
  %colored differently. The stars indicate points where the spectrometer samples. The
  %observation area of the microscope is larger than the middle layer. The expected
  %contribution profiles of the three components are also plotted. It is
  %important to memorize the contribution profiles.
  pause;
%-------------------------------------------------
  echo off;
  y=[0 0 1 1];subplot(211);
  fill([0 .45 .45 0],y,'r',[.45 .55 .55 .45],y,'g',[.55 1 1 .55],y,'b' );
  hold on;
  x=[.1:.1:.9];
  h=plot(x,[.5],'k*');
  set(gca,'xTicklabel',[],'yTicklabel',[]);
  hold off;
  subplot(614);h=plot(x,[1 1 1 1 0 0 0 0 0],'r');
  set(h,'linewidth',4);
  set(gca,'xTicklabel',[],'yTicklabel',[],'Ticklength',[0 0]);
  subplot(615);h=plot(x,[0 0 0 0 1 0 0 0 0],'g');
  set(h,'linewidth',4);
  set(gca,'xTicklabel',[],'yTicklabel',[],'Ticklength',[0 0]);
  subplot(616);h=plot(x,[0 0 0 0 0 1 1 1 1],'b');
  set(h,'linewidth',4);
  set(gca,'xTicklabel',[],'yTicklabel',[],'Ticklength',[0 0]);
  shg
  echo on;
  pause;
%-------------------------------------------------
  close;
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %First, we will load the data, followed by plotting.
  pause
%-------------------------------------------------
  load FTIR_microscopy;
  plot(FTIR_microscopy.axisscale{2},FTIR_microscopy.data);set(gca,'Xdir','reverse');
  pause;
%-------------------------------------------------
  close;
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %The file will be resolved for three components.Please note that the x-axis scale is
  %reversed. The program does this automatically because FTIR_microscopy.axisscale{2} is given 
  %in reverse order. Pay attention to the resolved contributions and compare
  %them with the predicted profiles.
  pause
%-------------------------------------------------
  options=purity('options');
  options.display='off';
  options.demo = 1;
  purity(FTIR_microscopy,3,options);
  close;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %The resolved data are not correct, as can be easily deduced from the contribution
  %plots. This is because the variables were not pure. The use of inverted
  %2nd derivative data minimizes baseline and narrows peaks. From now
  %on we will refer to this inverted 2nd derivative data as the derivative data. 
  %For the 2nd derivative we use Savitzky Golay with a window of nine and a
  %polynomial of order 2. The inverted 2nd derivative data are calculated as follows:
  datader=-savgol(FTIR_microscopy.data,9,2,2);
  datader(datader<0)=0;
  %
  %We will plot the conventional and 2nd derivative data.
  pause
%-------------------------------------------------
  subplot(211);plot(FTIR_microscopy.axisscale{2},FTIR_microscopy.data);set(gca,'Xdir','reverse');
  subplot(212);plot(FTIR_microscopy.axisscale{2},datader);set(gca,'Xdir','reverse');
  pause;
%-------------------------------------------------
  close;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %In order to use the inverted 2nd derivative in the function, both the conventional
  %as well as the 2nd derivative need to be used. A new dataset is created
  %for this
  
  zz=FTIR_microscopy;
  zz.data=datader;
  lamdemo2_obj=cat(3,FTIR_microscopy,zz);
  %
  %The command for the purity calculations is:
  %purity(lamdemo2_obj,3);
  %The program will now show the length and purity spectrum of both the conventional
  %and the derivative data. The pure variables will be selected from the 2nd derivative
  %data. Because the baseline was minimized and the peaks narrowed, the 2nd derivative
  %pure variable intensities reflect the proper behavior. These intensities will then
  %be used to resolve the conventional data.
  pause;
%-------------------------------------------------
  options=purity('options');
  options.display='off';
  options.demo = 1;
  purity(lamdemo2_obj,3,options);
  echo off;
  close;
end;
if (answer==3)|(answer==5);
  
  %case{3,5};
  echo on;
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %The next example is a time resolved mass spectral data set of 3 components. The
  %sample is heated in a direct probe and the components evolve sequentially. We need
  %to take care that the mass spectra are plotted properly by using options.plot{2}.
  %This option enables us to tell the program that the spectra are discontinuous,
  %which results in mass spectra. The contribution profiles are continuous.
  %We have reference spectra in another file, so we need to use the output arguments of the
  %function purity to preserve the results so that we are able to compare the resolved spectra
  %with reference spectra. We will first load the data and run the program.
  %The plot options need to be change to accomodate the mass spectral plot.
  pause
%-------------------------------------------------
  load MS_time_resolved
  options=purity('options');
  %options.plot{2}='dc';
  options.axistype{2}='bar';
  options.axistype{1}='continuous';
  
  options.display='off';
  options.demo = 1;
  [purint,purspec]=purity(MS_time_resolved,3,options);
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %In order to compare the resolved spectra in purspec we run the script puritydemo_chmix4.
  %This programs plots the purspec solution sequentially with together with the reference
  %spectrum with the highest correlation. The correlation is listed in the
  %plot.
  pause
%-------------------------------------------------
  echo off
  puritydemo_chmix4
  echo on;
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %The correlation of the middle component shows limited similarity. We can check if there is
  %another component by selecting 4 components and check the results again
  pause
%-------------------------------------------------
  [purint,purspec]=purity(MS_time_resolved,4,options);
  echo off
  puritydemo_chmix4
  echo on;
  
  %This addition of a fourth component revealed a background signal in the first resolved 
  %component. This background should not have a high correlation with any of the background 
  %spectra. For time resolved data such as this it is also possible to determine the purest spectra
  %and determine the solution by setting the 'mode' in options to 'rows'. We will first do 3
  %components.
  pause
%-------------------------------------------------
  options.mode='rows';
  [purint,purspec]=purity(MS_time_resolved,3,options);
  echo off
  puritydemo_chmix4
  echo on;
  
  %The middle spectrum has a relatively low correlation: 0.94. Overlap with the other 
  %components can be observed. Using four components does not help:
  %[purint,purspec]=purity(MS_time_resolved,4,options);
  %puritydemo_chmix4
  pause
%-------------------------------------------------
  [purint,purspec]=purity(MS_time_resolved,4,options);
  echo off
  puritydemo_chmix4
  echo on;
  
  %The pure spectrum approach did not give the proper resolution because the middle component is
  %not pure. However, the pure spectrum approach has advantages in that working with data such
  %as GCMS, the pure spectrum approach enables to see the results in chromatogram-like plots. 
  %Furthermore, in some cases it is easier to extract pure spectra than pure variables. The next
  %approach enables the user to use a combination of the pure spectrum and the pure variable approach.
  %Basically, the pure spectrum approach is used, after which the variables with the highest 
  %correlation with the extracted contributions are determined. The variable with the highest
  %correlation with a contribution profile is a proper pure variable. This two step process results
  %two solutions: the pure spectrum solution followed by the pure variable solution. This process
  %can be achieved by changing the mode field in options to 'row2col'. We
  %will change this option and run the program for three components.
  pause
%-------------------------------------------------
  options.mode='row2col';
  [purint,purspec]=purity(MS_time_resolved,3,options);
  echo off
  puritydemo_chmix4
  echo on;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %The solution found now enabled the pure spectrum approach to be used and
  %obtain the proper pure variable solution. The use of a fourth component did not give a 
  %a significant improvement in this case.
  pause;
%-------------------------------------------------
  echo off;
end;
if (answer==4)|(answer==5);
  %case{4,5};
  echo on;
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %The next demonstration is of a file with Raman imaging data. We will not treat this as
  %an image, though. There are three chemical components and a scattering component. We have 
  %reference spectra to check the results. First, we will load and plot the data. We will also need
  %2nd derivative data in the process, which we will also calculate and plot.
  pause
%-------------------------------------------------
  load raman_dust_particles
  datader=-savgol(raman_dust_particles.data,9,2,2);
  datader(datader<0)=0;
  zz=raman_dust_particles;
  zz.data=datader;
  snt2_obj=cat(3,raman_dust_particles,zz);
  subplot(211);plot(raman_dust_particles.axisscale{2},raman_dust_particles.data);
  subplot(212);plot(raman_dust_particles.axisscale{2},datader);
  pause;
%-------------------------------------------------
  close;
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %We will first analyze the conventional data set and resolve 4 components.
  %A fourth component is necessary to take care of the baseline. 
  pause;
%-------------------------------------------------
  options=purity('options');
  options.display='off';
  options.demo = 1;
  [purint,purspec]=purity(raman_dust_particles,4,options);
  close;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %The spectra are compared with their best match reference spectra through the script
  %puritydemo_chsnt
  pause
%-------------------------------------------------
  echo off
  puritydemo_chsnt
  echo on;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %The resolved spectra look fine, but the background spectrum has a negative echo from the
  %components, which is to be expected for the pure variable approach. Furthermore, the
  %contributions of the components will also be off because of the background contributions.
  %When we want to extract a proper background spectrum we should use the 2nd derivative
  %intensities for the sharp peaks that define the components and the conventional data 
  %for the baseline peak. This can be done by selecting the pure variables from both the
  %conventional as well as the 2nd derivative data by using the select option as shown
  %below. The program automatically selects the variable with the highest purity, 
  %indicated by a red cursor.
  %The original data has an high 'natural' offset because of the baseline, so
  %set the offset for the conventional pure variables to zero. If we do not do this,
  %the automated routine gives problems.
  pause
  %
  options=purity('options');
  options.select=[1 2];
  options.offset=[0 10];
  options.display='off';
  options.demo = 1;
  [purint,purspec]=purity(snt2_obj,4,options);
  close;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %The background spectrum now is of a good quality. We will check the spectra again
  %by comparing them with reference spectra by issuing the function puritydemo_chsnt
  pause
%-------------------------------------------------
  echo off;
  puritydemo_chsnt
  echo on;
end;
 
 
 
