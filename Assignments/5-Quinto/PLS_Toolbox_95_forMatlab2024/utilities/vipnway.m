function  vip_scores = vipnway(model)
% VIPNWAY Calculate Variable Importance in Projection from NPLS model.
% Variable Importance in Projection (VIP) scores estimate the importance of
% each variable in the projection used in a NPLS model and is often used for
% variable selection. A variable with a VIP Score close to or greater than
% 1 (one) can be considered important in given model. Variables with VIP
% scores significantly less than 1 (one) are less important and might be
% good candidates for exclusion from the model.
% It works for X n-way and Y up to two-way and it assume samples are in the first
% mode.
%
% %I/O: vip_scores = vipnway(model)
%
% INPUT:
%   Standard input is:
%   model = a NPLS model structure from a NPLS model

% OUTPUTS:
%  vip_scores = a cell array with dimensions of: [modes 2 to n X # of
%  columns in Y]
%  The first row in the cell array corresponds to VIP Scores for mode 2
%  The second row corresponds to VIP Scores for mode 3

%  $ Version 1 $ Feb 2014 $ Marina Cocchi $ Not compiled $
%  please cite:
%  S. Favilla C. Durante,M. Li Vigni,M. Cocchi,
%  Assessing feature relevance in NPLS models by VIP
%  Chemom. Intell. Lab. Syst. 2013 (129) 76-86.
%


%model object input
if ~ismodel(model) || ~ismember(lower(model.detail.options.functionname),{'npls'})
  error('Input for vipnway must be a NPLS model')
end


dim_arX=size(model.loads,1); % order of the array
T=model.loads{1,1};
nlv=size(T,2);
Q=model.loads{2,2};
B=model.detail.bin;
dim_y=size(Q,1);
for j=2:dim_arX
  w{j}=model.loads{j,1};  % NPLS weights of mode j: J(or K,..) x LVs
  dim_w(j)=size(w{j},1);
end



%%-------- maybe not needed

for j=2:dim_arX
  wnorm{j}=(w{j}*diag(1./sqrt(sum(w{2}.^2,1))));
end

%%---------
% start calculation for VIP, first part is used, for each Y, to assess
% Y variance explained by Factor i with respect to Y variance explained
% by Factor from 1 to nlv
yy=T*B; %[I nLV]x[nLV nLV] = [I nLV]

for i=1:nlv;
  yyy(:,:,i)=yy(:,i)*Q(:,i)'; %[I 1]x [1 x Y] -> [I Y nLV]
end

syyy=sum(yyy.^2); % sum over I -> [1 Y nLV]
syyy_shdim=shiftdim(syyy); %[Y nLV] variance of each y for each LV

if dim_y > 1
  syyy_shdim_perm=permute(syyy_shdim, [2 1]); % invert first second dimension [nLV Y]
else
  syyy_shdim_perm= syyy_shdim;
end

ssyyy=(sum(syyy_shdim_perm)); % [1 Y] total variance for each y

for k=1:dim_y
  var_y(:,k)=syyy_shdim_perm(:,k)./ssyyy(k)'; % [LV 1]./[1] -> [LV Y]
end

for j=2:dim_arX
  for k=1:dim_y;
    VIP_y{k,j-1} = dim_w(j)*(w{:,j}.^2*var_y(:,k));
  end
end
vip_scores = VIP_y';

% LWL - commented out below code because we are using VIP_y
%%%% VIP for all Y altogether
% for i=1:nlv
%   syyy2(i)=sum(sum(yyy(:,:,i).^2));
% end
%
% for j=2:dim_arX
%   VIP{j} = (dim_w(j)*(wnorm{j}.^2*(syyy2./sum(sum(yy.^2)))'));
% end

end