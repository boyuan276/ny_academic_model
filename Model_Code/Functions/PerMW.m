function [res] = PerMW(res)
%PerMW(res) generates per MW profiles for the input resource 
%   res: structure providing raw regional profiles and existing capacities

%Amount of Regional Generation per MW of ICAP by region
res.A2F_gen_per_MW = res.A2F_genin./res.A2F_exist_cap;
res.A2F_gen_per_MW(isnan(res.A2F_gen_per_MW))=0;
res.A2F_gen_per_MW(isinf(res.A2F_gen_per_MW))=0;

res.GHI_gen_per_MW = res.GHI_genin./res.GHI_exist_cap;
res.GHI_gen_per_MW(isnan(res.GHI_gen_per_MW))=0;
res.GHI_gen_per_MW(isinf(res.GHI_gen_per_MW))=0;

res.NYC_gen_per_MW = res.NYC_genin./res.NYC_exist_cap;
res.NYC_gen_per_MW(isnan(res.NYC_gen_per_MW))=0;
res.NYC_gen_per_MW(isinf(res.NYC_gen_per_MW))=0;

res.LIs_gen_per_MW = res.LIs_genin./res.LIs_exist_cap;
res.LIs_gen_per_MW(isnan(res.LIs_gen_per_MW))=0;
res.LIs_gen_per_MW(isinf(res.LIs_gen_per_MW))=0;

if isfield(res, 'NEw_genin') == 1
    res.NEw_gen_per_MW = res.NEw_genin./res.NEw_exist_cap;
    res.NEw_gen_per_MW(isnan(res.NEw_gen_per_MW))=0;
    res.NEw_gen_per_MW(isinf(res.NEw_gen_per_MW))=0;
else
    res.NEw_gen_per_MW = zeros(length(res.A2F_gen_per_MW),1);
end

if isfield(res, 'PJM_genin') == 1
    res.PJM_gen_per_MW = res.PJM_genin./res.PJM_exist_cap;
    res.PJM_gen_per_MW(isnan(res.PJM_gen_per_MW))=0;
    res.PJM_gen_per_MW(isinf(res.PJM_gen_per_MW))=0;
else
    res.PJM_gen_per_MW = zeros(length(res.A2F_gen_per_MW),1);
end

    
end

