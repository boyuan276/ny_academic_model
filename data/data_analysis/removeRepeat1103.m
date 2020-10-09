function [oldTable] = removeRepeat1103(oldTable)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
idx1103 = oldTable.Date == "11/03/2019" & oldTable.Hour == 1;
oldTable.GroupCount(idx1103) = oldTable.GroupCount(idx1103) * 0.5;
oldTable.sum_GrossLoadMW(idx1103) = oldTable.sum_GrossLoadMW(idx1103) * 0.5;
oldTable.sum_HeatInputMMBtu(idx1103) = oldTable.sum_HeatInputMMBtu(idx1103) * 0.5;
% oldTable.sum_LBMPMWHr(idx1103) = oldTable.sum_LBMPMWHr(idx1103) * 0.5;
% oldTable.sum_MarginalCostCongestionMWHr(idx1103) = oldTable.sum_MarginalCostCongestionMWHr(idx1103) * 0.5;
% oldTable.sum_MarginalCostLossesMWHr(idx1103) = oldTable.sum_MarginalCostLossesMWHr(idx1103) * 0.5;
oldTable.sum_GrossRevenue(idx1103) = oldTable.sum_GrossRevenue(idx1103) * 0.5;
oldTable.Dayofyear = day(oldTable.Date, 'dayofyear');
end

