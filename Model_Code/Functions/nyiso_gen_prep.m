function [gen_agg_cap, gen_agg_type, gen_agg_fuel] = nyiso_gen_prep(in_file, xl_sheet, xl_range)
%NYISO_GEN_PREP preprocesses NYISO Gold Book Generator Data to create files
% for the New York Academic Model.
%   Detailed explanation goes here

% Define a default input file path to the 2019 Gold Book generator data
if ~exist('in_file', 'var')
    % You must be in the Functions directory of the NYAM code for this to
    % work!
    in_file = '../../Excel Files/2019-NYCA-Generators.xlsx';
%     in_file = '../../Excel Files/2019-NYCA-Generators.csv';
end
if ~exist('xl_sheet', 'var')
    xl_sheet = 'NYCA_2019';
end
if ~exist('xl_range', 'var')
    xl_range = 'B9:S716';
end

%Load facility-level generator data from EPA AMPD
path_cems = '../data/epa_cems';
addpath(genpath(path_cems))
yr = 2018;
yrstr = num2str(yr);
yrstr = yrstr(end-1:end);
infile = sprintf('CEMSbyfacility%s.mat',yrstr);
load(infile,'CEMS')

% Read & format generator data 
fprintf(2,'Warning: this script was designed specifically for the 2019 Gold book data!\n\n')
[~, ~, raw_gen_dat] = xlsread(in_file, xl_sheet, xl_range);
gen_zone = cell2mat(raw_gen_dat(:,3));
gen_ptid = raw_gen_dat(:,4);
for ii = 1:length(gen_ptid)
    if isstr(gen_ptid{ii})
        gen_ptid{ii} = str2num(gen_ptid{ii});
    end
end
gen_ptid = cell2mat(gen_ptid);
gen_cap = cell2mat(raw_gen_dat(:,9));
gen_type = raw_gen_dat(:,15);
gen_fuel = raw_gen_dat(:,16);
gen_in_2018 = cell2mat(raw_gen_dat(:,18));

%Match NYISO facilities to NY RGGI facilities


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
        gen_agg_zone{jj,ii} = zn;
        gen_agg_cap{jj,ii} = sum(zone_gen_cap(ismember(gen_type_by_zone{:,zone_num}, type)));
        gen_agg_type{jj,ii} = type;
        c = zone_gen_fuel(ismember(gen_type_by_zone{:,zone_num}, type));
        [s,~,j]=unique(c);
        gen_agg_fuel{jj,ii} = s{mode(j)};
        jj = jj + 1;
    end
    ii = ii + 1;
end

% Print aggrigated generator information to screen
Zone = cat(1,gen_agg_zone{:});
Capacity = cat(1,gen_agg_cap{:});
Type = cat(1,gen_agg_type{:});
Fuel = cat(1,gen_agg_fuel(:));
Fuel = Fuel(~cellfun('isempty',Fuel));

% Write a NYAM Matpower case file
mpc = loadcase('case_nyiso16');
[A2F_Load_buses, GHI_Load_buses, NYC_Load_buses, LIs_Load_buses, NYCA_Load_buses, NEw_Load_buses, PJM_Load_buses,...
    A2F_load_bus_count,GHI_load_bus_count, NYC_load_bus_count, LIs_load_bus_count, NYCA_load_bus_count, NEw_load_bus_count, PJM_load_bus_count,...
    A2F_Gen_buses, GHI_Gen_buses, NYC_Gen_buses, LIs_Gen_buses, NEw_Gen_buses, PJM_Gen_buses, ...
    A2F_gen_bus_count, GHI_gen_bus_count, NYC_gen_bus_count, LIs_gen_bus_count, NEw_gen_bus_count, PJM_Gen_bus_count,...
    A2F_RE_buses, GHI_RE_buses, NYC_RE_buses, LIs_RE_buses, NEw_RE_buses, PJM_RE_buses,...
    A2F_gens, GHI_gens, NYC_gens, LIs_gens, NEw_gens, PJM_gens,...
    map_Array, BoundedIF, lims_Array] = NYCArgnparms;


% Randomly assign generators to generator buses within their region
Bus = zeros(length(Zone), 1);
for ii = 1:length(Zone)
    if Zone(ii) == 'A' || Zone(ii) == 'B' || Zone(ii) == 'C' || Zone(ii) == 'D' || Zone(ii) == 'E' || Zone(ii) == 'F'
        Bus(ii) = datasample(A2F_Gen_buses, 1);
    elseif Zone(ii) == 'G' || Zone(ii) == 'H' || Zone(ii) == 'I'
        Bus(ii) = datasample(GHI_Gen_buses, 1);
    elseif Zone(ii) == 'J' 
        Bus(ii) = datasample(NYC_Gen_buses, 1);
    elseif Zone(ii) == 'K' 
        Bus(ii) = datasample(LIs_Gen_buses, 1);
    else
        fprintf(2, 'Error: Zone %s does not exist', Zone(ii));
        return
    end   
end

T = table(Zone, Bus, Capacity, Type, Fuel);
fprintf('--------------------------------------------------------------------------\n')
fprintf('    Aggrigated Generator Summary\n')
fprintf('--------------------------------------------------------------------------\n\n')
disp(T)

define_constants;
len1 = length(mpc.gen(:,1));
len2 = length(Zone);
diff = len2 - len1;
mpc.gen = [mpc.gen; repmat(mpc.gen(end,:),diff,1)]; 
mpc.gen(:, BUS_I) = Bus;
mpc.gen(:, PMAX) = Capacity;

%Extract generator minimums from the CEMS data

%Extract ramping rates from the CEMS data


% savecase('case_nyiso_2019GB', mpc)

end

