function [res] = ScenProfs(res)
%ScenProfs(res) creates input profiles for the scenario
%   res: structure providing raw regional profiles, existing capacities,
%   per MW profiles, and scenario capacitites

% Calculate scenario generation profiles fore each region 
res.A2F_gen = res.A2F_gen_per_MW .*res.A2F_cap;
res.GHI_gen = res.GHI_gen_per_MW.*res.GHI_cap;
res.NYC_gen = res.NYC_gen_per_MW.*res.NYC_cap;
res.LIs_gen = res.LIs_gen_per_MW.*res.LIs_cap;
res.NEw_gen = res.NEw_gen_per_MW.*res.NEw_cap;
res.PJM_gen = res.PJM_gen_per_MW.*res.PJM_cap;

end

