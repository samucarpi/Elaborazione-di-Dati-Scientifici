echo on;
%PURITYENGINEDEMO Demo of purityengine function
 
echo off
% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
 
echo on;
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
%The demo will use a time resolved Raman spectroscopy dataset. 
pause
%-------------------------------------------------
load raman_time_resolved
plot(raman_time_resolved.axisscale{2},raman_time_resolved.data);set(gcf,'name','original data');
xlabel('wavenumbers');ylabel('intensity');
%p=get(gcf,'position');
%set(gcf,'position',p.*[1.2 1.2 1 1]);%move fig to avoid overlap with next fig
pause
%-------------------------------------------------
%close;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Now we will go through 5 iterations of this program, one for each pure variable,
%and plot the intermediate results. The read star indicates the position of
%the maximum in the purity spectrum, i.e. the pure variable position.
data=raman_time_resolved.data;
purvarindex=[];
offset=3;
figure (2);
p=get(gcf,'position');
set(gcf,'position',p.*[.7 .7 1 1]);%move fig to avoid overlap with next fig
set(gcf,'name','purityengine demo');
for i=1:5;
    base=data(:,purvarindex);%define space with previously selected pure variables
    [purity_index,purity_values,length_values]=purityengine(data,base,offset);%calculate
                                              %spectra and index at maximum purity_value      
                
    purvarindex=[purvarindex,purity_index];%append the new pure variable
    subplot(211);plot(purity_values);hold on;%plot purity spectrum
    plot(purity_index,purity_values(purity_index),'r*');hold off;%indicate maximum
    title('purity spectrum');;ylabel('arb. units');
    subplot(212);plot(length_values);hold on;%plot length spectrum
    plot(purity_index,length_values(purity_index),'r*');%indicate maximum
    %                                                   in purity spectrum
    title('length spectrum');xlabel('wavenumbers');ylabel('arb. units');
    hold off
    pause;
%-------------------------------------------------
    echo off
end;
echo on;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%After the determination of four pure variables only noise is left. Additional diagnostics
%are available in purity_interacitve. In this case we would only use four pure variables.
%The intensities of these pure variables are proportional to the concentrations of the
%components and can be used to calculate the resolved spectra.
echo off;
