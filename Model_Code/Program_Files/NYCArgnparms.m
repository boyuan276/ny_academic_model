function [A2F_Load_buses, GHI_Load_buses, NYC_Load_buses, LIs_Load_buses, NYCA_Load_buses, NEw_Load_buses, PJM_Load_buses,...
    A2F_load_bus_count,GHI_load_bus_count, NYC_load_bus_count, LIs_load_bus_count, NYCA_load_bus_count, NEw_load_bus_count, PJM_load_bus_count,...
    A2F_Gen_buses, GHI_Gen_buses, NYC_Gen_buses, LIs_Gen_buses, NEw_Gen_buses, PJM_Gen_buses, ...
    A2F_gen_bus_count, GHI_gen_bus_count, NYC_gen_bus_count, LIs_gen_bus_count, NEw_gen_bus_count, PJM_Gen_bus_count,...
    A2F_RE_buses, GHI_RE_buses, NYC_RE_buses, LIs_RE_buses, NEw_RE_buses, PJM_RE_buses,...
    A2F_gens, GHI_gens, NYC_gens, LIs_gens, NEw_gens, PJM_gens,...
    map_Array, BoundedIF, lims_Array] = NYCArgnparms
%NYCArgnparms defines regional system parameters for NYCA that are not 
%defined in the MPC.
%   Detailed explanation goes here

%% Define Load Buses by zone
% These are indices of PQ buses with non-zero load. Some PQ buses have zero
% load and they are not included in the following arrays.
A2F_Load_buses = [1 9 33 36 37 39 40 41 42 44 45 46 47 48 49 50 51 52];
GHI_Load_buses = [3 4 7 8 25];
NYC_Load_buses = [12 15 16 18 20 27];
LIs_Load_buses = [21 23 24];
NYCA_Load_buses = [A2F_Load_buses GHI_Load_buses NYC_Load_buses LIs_Load_buses];
NEw_Load_buses = [26 28 29];
PJM_Load_buses = [];

A2F_load_bus_count = length(A2F_Load_buses);
GHI_load_bus_count = length(GHI_Load_buses);
NYC_load_bus_count = length(NYC_Load_buses);
LIs_load_bus_count = length(LIs_Load_buses);
NYCA_load_bus_count = length(NYCA_Load_buses);
NEw_load_bus_count = length(NEw_Load_buses);
PJM_load_bus_count = length(PJM_Load_buses);

%% Define Gen Buses by zone. 
%%%%% I changed these from column vectors to
% row vectors, which I checked, and I don't think will cause problems, but
% I wanted to include this note for sanity's sake.
%A2F_Gen_buses = [62 63 64 65 66 67 68];
A2F_Gen_buses = [64 65 66 67 68]; %removed gen at bus 62 for ref bus and bus 63 for no ITM in base case
GHI_Gen_buses = [53 54 60];
NYC_Gen_buses = [55 56 57];
LIs_Gen_buses = [58 59];
NEw_Gen_buses = [61];
PJM_Gen_buses = [];

A2F_gen_bus_count = length(A2F_Gen_buses);
GHI_gen_bus_count = length(GHI_Gen_buses);
NYC_gen_bus_count = length(NYC_Gen_buses);
LIs_gen_bus_count = length(LIs_Gen_buses);
NEw_gen_bus_count = length(NEw_Gen_buses);
PJM_Gen_bus_count = length(PJM_Gen_buses);

%% Define Renewable Energy Buses by zone. 
%%%%% I pulled these arrays out of
% the RunDAM.m, but I don't actually know where the values within them
% come from. Perhaps they are all proper, but I don't have a physical
% topological map of the system... I should probablly make one.
A2F_RE_buses = [25 26 27 28 29 40 41 42 43 44 55 56 57 58 59]; 
GHI_RE_buses = [15 16 22 30 31 37 45 46 52];
NYC_RE_buses = [17 18 19 32 33 34 47 48 49];
LIs_RE_buses = [20 21 35 36 20 21];
NEw_RE_buses = [];
PJM_RE_buses = [];

%% Define Generators by zone. 
%%%% The first few elements are generator indices in mpc.gen matrix
% The rest elements are same as RE_buses indiced above
% This doesn't make sense since it's a mix of bus indices and gen indices.
A2F_gens = [1  4  5 10 25 26 27 28 29 40 41 42 43 44 55 56 57 58 59]; 
GHI_gens = [2  3  6 15 16 22 30 31 37 45 46 52];
NYC_gens = [7 11 12 17 18 19 32 33 34 47 48 49];
LIs_gens = [8 13 20 21 35 36 50 51];
NEw_gens = [9]; % Added this on 4/2/19
PJM_gens = [];


%% Add Transmission Interface Limits
%%%% The first column is the group of interface limitation. The second column
% is the branch index in mpc.branch matrix. The sign shows positve flow
% direction (from_bus to to_bus)or negative flow direction.
% Steve only studied the Central-East congestion which is the first group
% of interface limits. The other interface limits were not studied by
% setting high limitations in the lims_Array shown below.
map_Array  = [  
    1 -16; % A2F bus 8 - GHI bus 9
    1   1; % A2F bus 1 - GHI bus 2
    2 -16; % A2F bus 8 - GHI bus 9
    2   1; % A2F bus 1 - GHI bus 2
    2  86; % A2F bus 1 - J bus 27 (goes through GHI)
    3  13; % GHI bus 6 - J bus 11
    3   9; % GHI bus 4 - J bus 14
    3   7; % GHI bus 3 - J bus 18
    4  28; % J bus 16 - K bus 21
    4  29;]; % J bus 16 - K bus 24

%Row of lims_Array with limits
% Only study Central-East interface limit
BoundedIF = 1; 
% IF group, Min flow, Max flow
lims_Array = [
    1 -2700 2700;
    2 -9000 9000;
    3 -9000 9000;
    4 -9000 9000;
    ];

end

