%% Setup
% Start from a Clean Slate
clear
close all
clc
tic

%% Set Simulation Control Parameters
%%%%% I need to brainstorm how to expand this section to make it more date
%%%%% flexible. I don't want the dates to be hard coded into the section.
%%%%% If anything I want the program to determine which dates are being fed
%%%%% to it and run based upon these input dates...

% Pick Date Range
d_start = 1;
d_end   = 1;
date_array = [2016,1,19;2016,3,22;2016,7,25;2016,11,10];
ren_tab_array = ["Jan 19";"Mar 22";"Jul 25";"Nov 10";];

% Pick Case: 0 = Base Case, 1 = 2030 Case, 2 = 2X2030 Case, 3 = 3X2030 Case
%%%%% I need to figure out what exactly went into developing the 2030 case.
%%%%% Incrementalism is not a viable option much past 50% in my opinion. Are
%%%%% numbered variables the way to go on these cases?????
case_start = 0;
case_end   = 0;

% Run real time market?
RTM_option = 0;             %%[1 = yes; 0 = no]

% Interface Flow Limits Enforced?
IFlims = 0;                 %%[1 = yes; 0 = no]

% Plot curtailment and Central-East interface flow?
printCurt = 1;              %%[1 = yes; 0 = no]

% Pick number of RTC periods.
%%%%% I should ask Steve about the number of RTC periods. I.e. he says they
%%%%% should be divislble by 3 and 12 below, but he has the number set to
%%%%% 30. Also, how does this translate into 260 RT_int?????
RTC_periods = 30; %should be divisible by 3 and 12.
RTC_hrs = RTC_periods/12;

% Renewable Energy Credit (REC) Cost
%%%%% Should add a separate REC for Wind and Solar.
REC_Cost =  0; %set to negative number ($-5/MWh) for Renewable Energy Credit
REC_wind = 0; %%%%% this variable doesn't do anything yet
REC_solar = 0; %%%%% this variable doesn't do anything yet
REC_hydro = 0;

% Include renewables in the opweraional cost?
RenInOpCost = 0;            %%[1 = yes; 0 = no]

% Electric Vehicle (EVSE) Load?
EVSE = 0;                   %%[1 = ON; 0 = OFF]
EVSEfactor = 1; %"1" is 1x NYISO estimate. "2" will double MW and MWh estimates

% Is Renewable Curtailable in DAM?
% [1 = mingen is zero; 0 = mingen is maxgen]
windyCurt = 1;
solarCurt = 1; %%%%% this variable doesn't do anything yet
hydroCurt = 1;
otherCurt = 1;

% Reduce mingen from maxgen by a factor
% [Value between 0 (full curtailment allowed) and 1 (No curtailment allowed)]
windyCurtFactor = 0;
solarCurtFactor = 0; %%%%% this variable doesn't do anything yet
hydroCurtFactor = 0;
otherCurtFactor = 0;

% Increase the Ramp Rate: [1 = yes; 0 = no]
IncreasedDAMramp = 0; %reduces Steam and CC units ramp rate in DAM
IncreasedRTCramp_Steam = 1; %reduces Steam and CC units ramp rate in RTC
IncreasedRTDramp_Steam = 1; %reduces Steam and CC units ramp rate in RTC
IncreasedRTCramp_CC = 1; %reduces Steam and CC units ramp rate in RTC
IncreasedRTDramp_CC = 1; %reduces Steam and CC units ramp rate in RTC

% How much should we increase Ramp Rate beyond original mpc.gen input from
% "Matpower Input Data" excel file?
DAMrampFactor = 1.0; %Don't ever change this from 1.0   WHY?????
RTCrampFactor_Steam = 1.1;
RTDrampFactor_Steam = 1.1;
RTCrampFactor_CC = 1.1;
RTDrampFactor_CC = 1.1;

% Retire a Nuclear Unit?
% [ 2 = eliminate one of the GHI nuke plants; 1 = allow all nukes to
% operate]
killNuke = 1;

% Should we make mingen(s) even lower? [1 = yes; 0 = no]
droppit = 0;

% Want to print every RTC result? [1 = yes; 0 = no]
printRTC = 0;

% Want to compare using values from the first 5min period vs the average
% hourly generation period for renewables? [1 = yes; 0 = no] !!!!!
Avg5mingencompare = 0;

% Shall we cut the min run time in half? [1 = yes; 0 = no]
minrunshorter = 0;

% Use average across hour or first instant of the hour for DAM forcast?
% [1 = average; 0 = first instant]
useinstant = 0;

% Make DAM committed NUKE & STEAM units 'Must Run' during RTC? [1 = yes;
% 0 = no]
mustRun = 1; %This should always be set to 1 for all units.

% Reduce by 100*(1 - undrbidfac) percent to account for underbidding of
% load. This factor should be between 0 - 1: [1 = no underbidding]
undrbidfac = 1;

% Determine Number of Periods. I also replaced fivemin_period_count with
% this variable.
most_period_count = 288; % This corresponds to a 5-min RTM (i.e., 24*12)
most_period_count_DAM = 24; % This corresponds to a 24h DAM.

input_params = [
    IFlims;
    printCurt;
    RTC_periods;
    RTC_hrs;
    REC_Cost;
    REC_wind;
    REC_solar;
    REC_hydro;
    RenInOpCost;
    EVSE;
    EVSEfactor;
    windyCurt;
    solarCurt;
    hydroCurt;
    otherCurt;
    windyCurtFactor;
    solarCurtFactor;
    hydroCurtFactor;
    otherCurtFactor;
    IncreasedDAMramp;
    IncreasedRTCramp_Steam;
    IncreasedRTDramp_Steam;
    IncreasedRTCramp_CC;
    IncreasedRTDramp_CC;
    DAMrampFactor;
    RTCrampFactor_Steam;
    RTDrampFactor_Steam;
    RTCrampFactor_CC;
    IncreasedRTDramp_CC;
    killNuke;
    droppit;
    printRTC;
    Avg5mingencompare;
    minrunshorter;
    useinstant;
    mustRun;
    undrbidfac;
    most_period_count;
    most_period_count_DAM;
    RTM_option;
    case_start;
    d_start;
    ];

%% Define Initial Variables
% Define Load Buses by zone

%     A2F_Load_buses = [1 9 33 36 37 39 40 41 42 44 45 46 47 48 49 50 51 52];
%     GHI_Load_buses = [3 4 7 8 25];
%     NYC_Load_buses = [12 15 16 18 20 27];
%     LIs_Load_buses = [21 23 24];
%     NEw_Load_buses = [];
%     NYCA_Load_buses = [A2F_Load_buses GHI_Load_buses NYC_Load_buses LIs_Load_buses NEw_Load_buses];

A2F_Load_buses = [1 9 33 36 37 39 40 41 42 44 45 46 47 48 49 50 51 52];
GHI_Load_buses = [3 4 7 8 25];
NYC_Load_buses = [12 15 16 18 20 27];
LIs_Load_buses = [21 23 24];
NYCA_Load_buses = [1 3 4 7 8 9 12 15 16 18 20 21 23 24 25 27 33 36 37 39 40 41 42 44 45 46 47 48 49 50 51 52];
A2F_load_bus_count = length(A2F_Load_buses);
GHI_load_bus_count = length(GHI_Load_buses);
NYC_load_bus_count = length(NYC_Load_buses);
LIs_load_bus_count = length(LIs_Load_buses);

% Define Gen Buses by zone. %%%%% I changed these from column vectors to
% row vectors, which I checked, and I don't think will cause problems, but
% I wanted to include this note for sanity's sake.
%A2F_Gen_buses = [62 63 64 65 66 67 68];
A2F_Gen_buses = [64 65 66 67 68]; %removed gen at bus 62 for ref bus and bus 63 for no ITM in base case
GHI_Gen_buses = [53 54 60];
NYC_Gen_buses = [55 56 57];
LIs_Gen_buses = [58 59];
NEw_Gen_buses = [61];
A2F_gen_bus_count = length(A2F_Gen_buses);
GHI_gen_bus_count = length(GHI_Gen_buses);
NYC_gen_bus_count = length(NYC_Gen_buses);
LIs_gen_bus_count = length(LIs_Gen_buses);
NEw_gen_bus_count = length(NEw_Gen_buses);

% Define Renewable Energy Buses by zone. %%%%% I pulled these arrays out of
% the RunDAM.m, but I don't actually know where the values within them
% come from. Perhaps they are all proper, but I don't have a physical
% topological map of the system... I should probablly make one.
A2F_RE_buses = [25 26 27 28 29 40 41 42 43 44 55 56 57 58 59]; 
GHI_RE_buses = [15 16 22 30 31 37 45 46 52];
NYC_RE_buses = [17 18 19 32 33 34 47 48 49];
LIs_RE_buses = [20 21 35 36 20 21];

% RTD Value Storage Arrays %%%%% I don't think these belong here... they
% are preallocations.
RTD_Load_Storage = zeros(68,288);
RTD_Gen_Storage = zeros(59,288);
RTD_RenGen_Max_Storage = zeros(45,288);
RTD_RenGen_Min_Storage = zeros(45,288);

% Add Transmission Interface Limits
map_Array  = [  1 -16;...
    1   1;...
    2 -16;...
    2   1;...
    2  86;...
    3  13;...
    3   9;...
    3   7;...
    4  28;...
    4  29;];

BoundedIF = 1; %Row of lims_Array with limits

lims_Array   = [1 -2700 2700;...
    2 -9000 9000;...
    3 -9000 9000;...
    4 -9000 9000;];

% Given: Incremental BTM Capacity. Are these for a future case? Are
% they only for solar?????
A2F_BTM_inc_cap = 1358;
GHI_BTM_inc_cap =  793;
NYC_BTM_inc_cap =  419;
LIs_BTM_inc_cap = 1069;

% Given: 2016 BTM Capacity. Are these from NYISO? Are they only for
% solar?????
A2F_BTM_2016_cap =  266;
GHI_BTM_2016_cap =  155;
NYC_BTM_2016_cap =   82;
LIs_BTM_2016_cap =  209;

% Amount of ITM INCREMENTAL Wind Generation Capacity by Zone. Where
% did these come from?????
A2F_ITM_inc_wind_cap  = 4189;
GHI_ITM_inc_wind_cap  =    0;
NYC_ITM_inc_wind_cap  =  408;
LIs_ITM_inc_wind_cap  =  591;

% Amount of ITM INCREMENTAL hydro Generation Capacity by Zone. Where
% did these come from?????
A2F_ITM_inc_hydro_cap =  542;
GHI_ITM_inc_hydro_cap =   45;
NYC_ITM_inc_hydro_cap =    0;
LIs_ITM_inc_hydro_cap =    0;

% Amount of ITM INCREMENTAL Utility-scale PV Generation Capacity by
% Zone. Where did these come from?????
A2F_ITM_inc_PV_cap = 3044;
GHI_ITM_inc_PV_cap =  438;
NYC_ITM_inc_PV_cap =    0;
LIs_ITM_inc_PV_cap =  373;

% Amount of ITM INCREMENTAL Bio Generation Capacity by Zone. Where
% do these come from????? What does "biomass" mean in this context?????
A2F_ITM_inc_Bio_cap =  122;
GHI_ITM_inc_Bio_cap =    0;
NYC_ITM_inc_Bio_cap =    0;
LIs_ITM_inc_Bio_cap =    0;

% Amount of ITM INCREMENTAL LFG Generation Capacity by Zone. Where
% did these come from?????
A2F_ITM_inc_LFG_cap =   13;
GHI_ITM_inc_LFG_cap =    3;
NYC_ITM_inc_LFG_cap =   34;
LIs_ITM_inc_LFG_cap =    3;

% Existing renewable capacity in A2F (other locations ignored due  to low penetration
A2F_2016_ITM_wind_ICAP  = 1755;
A2F_2016_ITM_hydro_ICAP = 5219;
A2F_2016_ITM_PV_ICAP    =    0;
A2F_2016_ITM_Bio_ICAP   =  148;
A2F_2016_ITM_LFG_ICAP   =  126;

% Get EVSE Load Data (MWh total for the Day)
% Electric Vehicle Energy Usage Forecast (2018 Gold Book) in GWh
%A   B   C   D   E   F   G   H   I   J   K
EVSE_Gold_MWh = [3   5   4   0   2   5   6   3   5   13  23;     %2016
    154 183 180 12  99  206 230 100 150 520 781;]./365.*EVSEfactor;   %2030

% Total Increase in Coincident Winter Peak Demand by Zone in MW (Use winter as its worse than summer)
%A   B   C   D   E   F   G   H   I   J   K
EVSE_Gold_MW  = [1   1   1   0   1   1   2   1   1   4   7;       %2016
    30 36  35  2   19  40  45  20  29  101 153;].*EVSEfactor;    %2030

input_vars = {
    A2F_Load_buses;
    GHI_Load_buses;
    NYC_Load_buses;
    LIs_Load_buses;
    NYCA_Load_buses;
    A2F_load_bus_count;
    GHI_load_bus_count;
    NYC_load_bus_count;
    LIs_load_bus_count;
    map_Array;
    BoundedIF;
    lims_Array;
    A2F_BTM_inc_cap;
    GHI_BTM_inc_cap;
    NYC_BTM_inc_cap;
    LIs_BTM_inc_cap;
    A2F_BTM_2016_cap;
    GHI_BTM_2016_cap;
    NYC_BTM_2016_cap;
    LIs_BTM_2016_cap;
    A2F_ITM_inc_wind_cap;
    GHI_ITM_inc_wind_cap;
    NYC_ITM_inc_wind_cap;
    LIs_ITM_inc_wind_cap;
    A2F_ITM_inc_hydro_cap;
    GHI_ITM_inc_hydro_cap;
    NYC_ITM_inc_hydro_cap;
    LIs_ITM_inc_hydro_cap;
    A2F_ITM_inc_PV_cap;
    GHI_ITM_inc_PV_cap;
    NYC_ITM_inc_PV_cap;
    LIs_ITM_inc_PV_cap;
    A2F_ITM_inc_Bio_cap;
    GHI_ITM_inc_Bio_cap;
    NYC_ITM_inc_Bio_cap;
    LIs_ITM_inc_Bio_cap;
    A2F_ITM_inc_LFG_cap;
    GHI_ITM_inc_LFG_cap;
    NYC_ITM_inc_LFG_cap;
    LIs_ITM_inc_LFG_cap;
    A2F_2016_ITM_wind_ICAP;
    A2F_2016_ITM_hydro_ICAP;
    A2F_2016_ITM_PV_ICAP;
    A2F_2016_ITM_Bio_ICAP;
    A2F_2016_ITM_LFG_ICAP;
    EVSE_Gold_MWh;
    EVSE_Gold_MW;
    date_array;
    ren_tab_array;
    A2F_Gen_buses;
    GHI_Gen_buses;
    NYC_Gen_buses;
    LIs_Gen_buses;
    NEw_Gen_buses;
    A2F_gen_bus_count;
    GHI_gen_bus_count;
    NYC_gen_bus_count;
    LIs_gen_bus_count;
    NEw_gen_bus_count;
    A2F_RE_buses; 
    GHI_RE_buses;
    NYC_RE_buses;
    LIs_RE_buses;
    };


for Case = case_start:case_end
    for d = d_start: d_end
        
        %Run preprocessing script
        PreDAM(Case, d, input_params, input_vars)

        % Print completion message for this case and day
        fprintf('Competed Case %d for %s\n', Case, ren_tab_array(d))
        
    end
end

