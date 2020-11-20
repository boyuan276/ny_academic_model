function [P_max,P_min, RampUp_max, RampDown_max] = GenAggregator(generators)
%GenAggregator calculates maximum power, minimum power, maximum ramp up
%rate, and maximum ramp down rate
%   generator is a table that contains hourly gross load data of the
%   generators associate to one of the eight thermal generators in NYAM.

gen_hourly = groupsummary(generators, ["Date", "Hour"], "sum", "GrossLoadMW");
gen_hourly = gen_hourly(gen_hourly.sum_GrossLoadMW > 0, :);
P_max = max(gen_hourly.sum_GrossLoadMW);
lowPercent = 5;
highPercent = 95;
[~,P_min,~,~] = isoutlier(gen_hourly.sum_GrossLoadMW,"percentiles", [lowPercent, highPercent]);
ramp_rate = gen_hourly.sum_GrossLoadMW(2:end) - gen_hourly.sum_GrossLoadMW(1:end-1);
ramp_rate = [ramp_rate; 0];
gen_hourly.RampRate = ramp_rate;
[~,RampDown_max,RampUp_max,~] = isoutlier(gen_hourly.RampRate,"percentiles", [1, 99]);
% RampUp_max = max(gen_hourly.RampRate);
% RampDown_max = min(gen_hourly.RampRate);
end

