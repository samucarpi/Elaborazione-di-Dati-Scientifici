% PURITYDEMO_CHMIX4 Helper demo file for purity function

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

load MS_time_resolved_references;

flag_purint=1;
if ~exist('purspec','var');
        flag_purint=0;
end;
if flag_purint==1;
    purspec2=purspec;
    purint2=purint;
else
    a=get(0,'userdata');
    purspec2=a.model.loads{2}';
    purint2=a.model.loads{1};
    MS_time_resolved=a.data;
end;
    

npur=size(purspec2,1);
close;
for i=1:npur;
    c=corrcoef([purspec2(i,:)',MS_time_resolved_references.data(:,:)']);
    c=c(2:end,1);
    index=find(c==max(c));
    subplot(311);
    %bar(MS_time_resolved_references.axisscale{2},purspec2(i,:),.01);axis('tight');
    
    spec=purspec2(i,:);varlist=MS_time_resolved_references.axisscale{2}';
    lengthspec=length(spec);
    y0=zeros(1,lengthspec);
    plot(reshape([varlist;varlist;varlist],1,3*lengthspec),...
    reshape([y0;spec;y0],1,3*lengthspec),'b');
    title(['resolved spectrum #',num2str(i)]);
    
    subplot(312);
    bar(MS_time_resolved_references.axisscale{2},MS_time_resolved_references.data(index,:));axis('tight');
    
    spec=MS_time_resolved_references.data(index,:);
    lengthspec=length(spec);
    y0=zeros(1,lengthspec);
    plot(reshape([varlist;varlist;varlist],1,3*lengthspec),...
    reshape([y0;spec;y0],1,3*lengthspec),'b');
    
    
    
    
    
    
    title('reference spectrum');
    xlabel(num2str(c(index)));
    subplot(325);
    plot(MS_time_resolved.axisscale{1},purint2(:,i),'k',...
        MS_time_resolved.axisscale{1}([1 end]),[0 0],'k');
    %ginput(1);
    pause
end;
clear purint2 purspec2
close
