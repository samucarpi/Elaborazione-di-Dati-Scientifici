% PURITYDEMO_CHSNT Helper demo file for purity function

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.


%assumes purspec to be availabe.
load raman_dust_particles_references

npur=size(purspec,1);
close;
for i=1:npur;
%     for j=1:3;
%         c(j)=corr(purspec(i,:),raman_dust_particles_references.data(j,:));
%     end;
    c=corrcoef([purspec(i,:)',raman_dust_particles_references.data(:,:)']);
    c=c(2:end,1);
    index=find(c==max(c));
    subplot(211);plot(raman_dust_particles_references.axisscale{2},purspec(i,:));axis('tight');
    title(['resolved spectrum #',num2str(i)]);
    set(gca,'xTicklabel',[]);
    subplot(212);plot(raman_dust_particles_references.axisscale{2},raman_dust_particles_references.data(index,:));
    axis('tight');
    
    if index==1;title_string='CASO42H2O';
    elseif index==2;title_string='PBSO4 ';
    else;
        title_string=' SULFUR';
    end;
        
        
        
    title(title_string);
    xlabel(num2str(c(index)));
    pause
end;
close
