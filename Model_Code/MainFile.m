%% How to Use This Script
%This is the working file from MarketModel. You MUST run this file from the
%current working directory (ny_marketmodel/Model_Code). You must have
%Matpower, MOST, and GUROBI installed where Matlab can find them.


%% Known Issues/Upcomming Changes

%%%%% One major change that I should make to this model in the near term is
%%%%% the separation of solar from "Other" given how much of our work is
%%%%% centered around solar.

%%%%% Need to use the variables defined in Matpower to get data from
%%%%% structures. Right now, the column numbers are hard-coded.

%%%%% The RunRTCMkt.m script is far from working: I simply copied and
%%%%% pasted everything that was origionally in this script over to this
%%%%% other fuction. Have not debugged necessary i/o for this function nor
%%%%% have I tested this script with RTM_option = 1.

%%%%% Should transision from the use of double array to cell array for
%%%%% AllRunsSummary data storage with one cell for each case.

%% Setup
% Start from a Clean Slate
clear
close all
clc
tic

%% Add Paths
%Create a path to the 5 minute NYISO Load Data Stock
path_5minLoad = '../NYISO Data/ActualLoad5min';
addpath(genpath(path_5minLoad))
%Create a path to the Renewable Data
path_ren = '../NYISO Data/renewableData';
addpath(genpath(path_ren))
%Create paths for supporting functions
path_fxns = './Functions';
addpath(genpath(path_fxns))
%Create paths for Data Files
path_data = './Program_Files';
addpath(genpath(path_data))

%% Font Size for publishing
set(0,'DefaultAxesFontSize',14)
set(0,'DefaultTextFontSize',14)
set(0,'DefaultLineLinewidth',1)
fprintf('Changing font sizes to 14 and line width = 1.5\n')

%% Set Simulation Control Parameters
%%%%% I need to brainstorm how to expand this section to make it more date
%%%%% flexible. I don't want the dates to be hard coded into the section.
%%%%% If anything I want the program to determine which dates are being fed
%%%%% to it and run based upon these input dates...

% Pick Date Range
days = [1];
d_start = 1;
d_end   = 1;
date_array = [2016,1,19;2016,3,22;2016,7,25;2016,11,10];
ren_tab_array = ["Jan 19";"Mar 22";"Jul 25";"Nov 10";];

% Pick Case: 0 = Base Case, 1 = 2030 Case, 2 = 2X2030 Case, 3 = 3X2030 Case
%%%%% I need to figure out what exactly went into developing the 2030 case.
%%%%% Incrementalism is not a viable option much past 50% in my opinion. Are
%%%%% numbered variables the way to go on these cases?????
case_ids = [1];
case_start = 0;
case_end   = 0;
case_nam_array = ['Base_Case','2030_Case','2x2030_Case','3x2030_Case'];

% Figure output method
Fig_save = 0;               %%[1 = save to pdf; 0 = output to screen]

% Do you want to write data to an output file?
mat_save = 0;               %%[1 = yes; 0 = no]

% Do you want to write summary of all cases to an output file?
mat_save_all = 0;           %%[1 = yes; 0 = no]

% Run real time market?
RTM_option = 0;             %%[1 = yes; 0 = no]

% Interface Flow Limits Enforced?
IFlims = 1;                 %%[1 = yes; 0 = no]

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
    Fig_save;
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

% Define Generators by zone. Where is gen 9?????
A2F_gens = [1  4  5 10 25 26 27 28 29 40 41 42 43 44 55 56 57 58 59]; 
GHI_gens = [2  3  6 15 16 22 30 31 37 45 46 52];
NYC_gens = [7 11 12 17 18 19 32 33 34 47 48 49];
LIs_gens = [8 13 20 21 35 36 50 51];

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

% Existing renewable capacity in A2F (other locations ignored due to low
% penetration)
A2F_2016_ITM_wind_ICAP  = 1755;
A2F_2016_ITM_hydro_ICAP = 5219;
A2F_2016_ITM_PV_ICAP    =    0;
A2F_2016_ITM_Bio_ICAP   =  148;
A2F_2016_ITM_LFG_ICAP   =  126;

% Existing renewable capacity in GHI
GHI_2016_ITM_wind_ICAP  =    0;
GHI_2016_ITM_hydro_ICAP =    0;
GHI_2016_ITM_PV_ICAP    =    0;
GHI_2016_ITM_Bio_ICAP   =    0;
GHI_2016_ITM_LFG_ICAP   =    0;

% Existing renewable capacity in NYC
NYC_2016_ITM_wind_ICAP  =    0;
NYC_2016_ITM_hydro_ICAP =    0;
NYC_2016_ITM_PV_ICAP    =    0;
NYC_2016_ITM_Bio_ICAP   =    0;
NYC_2016_ITM_LFG_ICAP   =    0;

% Existing renewable capacity in NYC
LIs_2016_ITM_wind_ICAP  =    0;
LIs_2016_ITM_hydro_ICAP =    0;
LIs_2016_ITM_PV_ICAP    =    0;
LIs_2016_ITM_Bio_ICAP   =    0;
LIs_2016_ITM_LFG_ICAP   =    0;

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
    A2F_gens; 
    GHI_gens;
    NYC_gens;
    LIs_gens;
    };

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DAY AHEAD MARKET MODEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for Case = case_ids
    for d = days

        [DAMresults, DAMifFlows, Summaryy ] = ...
            RunDAM(Case, d, input_params, input_vars);
        
        if RTM_option == 0
            AllRunsSummary(:,(1+3*(Case*4+d-1)):(3+3*(Case*4+d-1))) = Summaryy;
        end
        
        if mat_save == 1
            resultsfilestr = ['../../MarketModel_Output/', ...
                case_nam_array(Case+1),ren_tab_array(d),'DAMRunData.mat'];
            save(resultsfilestr, 'DAMresults')
            %save(resultsfilestr, 'CC_results', 'DAMresults')
        end
        
        % Print completion message for this case and day
        fprintf('DAM competed for Case %d on %s\n', Case, ren_tab_array(d))
        
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% REAL TIME MARKET MODEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if RTM_option == 1
    for Case = case_ids
        for d = days
            
            [CC_results, Summaryy] = RunRTCMkt(Case, d, input_params, input_vars);
            
            AllRunsSummary(1:59,(1+8*(Case*4+d-1)):(8+8*(Case*4+d-1))) = Summaryy;
            
            if mat_save == 1
                resultsfilestr = ['../../MarketModel_Output/', ...
                    case_nam_array(Case+1),ren_tab_array(d),'RTCRunData.mat'];
                save(resultsfilestr, 'CC_results', 'Summaryy')
            end
            
            % Print completion message for this case and day
            fprintf('RTM competed for Case %d on %s\n', Case, ren_tab_array(d))
            
        end
    end
end
toc

% Save a summary of all cases and all days
if mat_save_all == 1
    resultsfilestr = ['../../MarketModel_Output/AllCasesRunData.mat'];
    save(resultsfilestr, 'AllRunsSummary','case_ids','days')
end




