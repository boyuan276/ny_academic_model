function [] = nyiso_gen_prep(in_file, xl_sheet, xl_range)
%NYISO_GEN_PREP preprocesses NYISO Gold Book Generator Data to create files
% for the New York Academic Model.
%   Detailed explanation goes here

% Define a default input file path to the 2019 Gold Book generator data
if ~exist('in_file', 'var')
    in_file = '../../Excel Files/2019-NYCA-Generators.xlsx';
end
if ~exist('xl_sheet', 'var')
    xl_sheet = 'NYCA_2019';
end
if ~exist('xl_range', 'var')
    xl_range = 'B9:S716';
end

% Read & format generator data 
fprintf(2,'WARNING: this script was designed specifically for the 2019 Gold book data!\n')
[~, ~, raw_gen_dat] = xlsread(in_file, xl_sheet, xl_range);
gen_zone = cell2mat(raw_gen_dat(:,3));
gen_cap = cell2mat(raw_gen_dat(:,9));
gen_type = cell2mat(raw_gen_dat(:,15));
gen_fuel = raw_gen_dat(:,16);
gen_in_2018 = cell2mat(raw_gen_dat(:,18));

% Group generators by fuel type and by zone

% Create aggrigated zonal generators


end

