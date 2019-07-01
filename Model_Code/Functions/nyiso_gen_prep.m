function [gen_agg_cap, gen_agg_type, gen_agg_fuel] = nyiso_gen_prep(in_file, xl_sheet, xl_range)
%NYISO_GEN_PREP preprocesses NYISO Gold Book Generator Data to create files
% for the New York Academic Model.
%   Detailed explanation goes here

% Define a default input file path to the 2019 Gold Book generator data
if ~exist('in_file', 'var')
    % You must be in the Functions directory of the NYAM code for this to
    % work!
    in_file = '../../Excel Files/2019-NYCA-Generators.xlsx';
end
if ~exist('xl_sheet', 'var')
    xl_sheet = 'NYCA_2019';
end
if ~exist('xl_range', 'var')
    xl_range = 'B9:S716';
end

% Read & format generator data 
fprintf(2,'Warning: this script was designed specifically for the 2019 Gold book data!\n\n')
[~, ~, raw_gen_dat] = xlsread(in_file, xl_sheet, xl_range);
gen_zone = cell2mat(raw_gen_dat(:,3));
gen_cap = cell2mat(raw_gen_dat(:,9));
gen_type = raw_gen_dat(:,15);
gen_fuel = raw_gen_dat(:,16);
gen_in_2018 = cell2mat(raw_gen_dat(:,18));

% Sort generators by zone 
gen_cap_by_zone = {gen_cap(gen_zone == 'A') gen_cap(gen_zone == 'B') ...
    gen_cap(gen_zone == 'C') gen_cap(gen_zone == 'D') ...
    gen_cap(gen_zone == 'E') gen_cap(gen_zone == 'F') ...
    gen_cap(gen_zone == 'G') gen_cap(gen_zone == 'H') ...
    gen_cap(gen_zone == 'I') gen_cap(gen_zone == 'J') ...
    gen_cap(gen_zone == 'K')};
gen_type_by_zone = {gen_type(gen_zone == 'A') gen_type(gen_zone == 'B') ...
    gen_type(gen_zone == 'C') gen_type(gen_zone == 'D') ...
    gen_type(gen_zone == 'E') gen_type(gen_zone == 'F') ...
    gen_type(gen_zone == 'G') gen_type(gen_zone == 'H') ...
    gen_type(gen_zone == 'I') gen_type(gen_zone == 'J') ...
    gen_type(gen_zone == 'K')};
gen_fuel_by_zone = {gen_fuel(gen_zone == 'A') gen_fuel(gen_zone == 'B') ...
    gen_fuel(gen_zone == 'C') gen_fuel(gen_zone == 'D') ...
    gen_fuel(gen_zone == 'E') gen_fuel(gen_zone == 'F') ...
    gen_fuel(gen_zone == 'G') gen_fuel(gen_zone == 'H') ...
    gen_fuel(gen_zone == 'I') gen_fuel(gen_zone == 'J') ...
    gen_fuel(gen_zone == 'K')};

% Aggrigate generators in each zone by fuel type
zones = ['A' 'B' 'C' 'D' 'E' 'F' 'G' 'H' 'I' 'J' 'K'];
gen_agg_cap = {};
gen_agg_type = {};
gen_agg_fuel = {};
ii = 1;
for zn = zones
    zone_num = Zone_let2num({zn});
    zone_gen_cap = gen_cap_by_zone{:,zone_num};
    zone_gen_fuel = gen_fuel_by_zone{:,zone_num};
    unique_unit_type = unique(gen_type_by_zone{:,zone_num});
    jj = 1;
    for type = unique_unit_type'
        type = cell2mat(type); 
        gen_agg_cap{jj,ii} = sum(zone_gen_cap(ismember(gen_type_by_zone{:,zone_num}, type)));
        gen_agg_type{jj,ii} = type;
        c = zone_gen_fuel(ismember(gen_type_by_zone{:,zone_num}, type));
        [s,~,j]=unique(c);
        gen_agg_fuel{jj,ii} = s{mode(j)};
        jj = jj + 1;
    end
    ii = ii + 1;
end

end

