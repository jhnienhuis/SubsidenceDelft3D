function [subsidence,sig0] = consolidation_model(ero_dep,t,sig0,h0)

%soil compaction 2 simple, robust model
e0 = 5; %initial void ratio?

e_max = 0.8; %maximum strain

rho = 2650; %kgm-3
rhow= 1000; %kgm-3
g = 9.81; %ms-2

%time steps
tp = 0.1; %yrs
dt = t(end)./(length(t)-1);
ii = numel(t);
[lx,ly] = size(ero_dep(:,:,1));


sig = sig0;
sigf = sig + (ero_dep(:,:,ii).*g.*(rho-rhow));

cc = 2; %%http://link.springer.com/article/10.1007/s10064-016-0890-6
ca = 0.06*cc; %(ASTM D 2435-70)

%strain mesri
e_str_func = @(e_max,sigf) (e_max.*sigf/1600000);

%primary consolidation
dz_pri = @(sigf,sig) (cc.*h0./(1+e0).*real(log10(sigf./sig)));
dz_primary = max(0,dz_pri(sigf,sig));

%secondary consolidation
dz_sec = @(t,e_eop) (e_eop.*h0.*ca./cc.*dt./(log(10).*(t+0.5*dt)));

%what is the maximum deposition so far
zmax = cummax(cumsum(ero_dep(1:lx,1:ly,1:ii),3),3);
zmax_t = min(zmax,repmat(sum(ero_dep(:,:,1:ii),3),[1,1,ii]));
dz_idx = diff(cat(3,zeros(lx,ly,1), zmax_t),1,3);
dz_secondary = zeros(lx,ly);
dz_find = find(max(max(dz_idx,[],1),[],2)>0)';

%go through timeseries
for jj=dz_find,
    e_eop = max(0,e_str_func(e_max,dz_idx(:,:,jj).*g*rho));
    dz_secondary = dz_secondary + dz_sec(t(end)-t(jj),e_eop);
end

idx = dz_primary>0;
e_eop2 = max(0,e_str_func(e_max.*idx,ero_dep(:,:,ii).*g.*rho));
dz_secondary(idx) = dz_secondary(idx) - (e_eop2(idx).*h0.*ca/cc.*log10(tp./dt));

subsidence = 0 - dz_primary - dz_secondary;

sig0 = max(sig,sigf);
end
