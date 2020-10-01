function PreDAM(Case, d, input_params, input_vars)
%PreDAM takes input parameters and prepares profiles for MOST
%   Detailed explanation goes here

%Define input parameters
IFlims = input_params(1);
printCurt = input_params(2);
RTC_periods = input_params(3);
RTC_hrs = input_params(4);
REC_Cost = input_params(5);
REC_wind = input_params(6);
REC_solar = input_params(7);
REC_hydro = input_params(8);
RenInOpCost = input_params(9);
EVSE = input_params(10);
EVSEfactor = input_params(11);
windyCurt = input_params(12);
solarCurt = input_params(13);
hydroCurt = input_params(14);
otherCurt = input_params(15);
windyCurtFactor = input_params(16);
solarCurtFactor = input_params(17);
hydroCurtFactor = input_params(18);
otherCurtFactor = input_params(19);
IncreasedDAMramp = input_params(20);
IncreasedRTCramp_Steam = input_params(21);
IncreasedRTDramp_Steam = input_params(22);
IncreasedRTCramp_CC = input_params(23);
IncreasedRTDramp_CC = input_params(24);
DAMrampFactor = input_params(25);
RTCrampFactor_Steam = input_params(26);
RTDrampFactor_Steam = input_params(27);
RTCrampFactor_CC = input_params(28);
IncreasedRTDramp_CC = input_params(29);
killNuke = input_params(30);
droppit = input_params(31);
printRTC = input_params(32);
Avg5mingencompare = input_params(33);
minrunshorter = input_params(34);
useinstant = input_params(35);
mustRun = input_params(36);
undrbidfac = input_params(37);
most_period_count = input_params(38);
most_period_count_DAM = input_params(39);
RTM_option = input_params(40);
case_start = input_params(41);
d_start = input_params(42);

% Define input variables
A2F_Load_buses = input_vars{1};
GHI_Load_buses = input_vars{2};
NYC_Load_buses = input_vars{3};
LIs_Load_buses = input_vars{4};
NYCA_Load_buses = input_vars{5};
A2F_load_bus_count = input_vars{6};
GHI_load_bus_count = input_vars{7};
NYC_load_bus_count = input_vars{8};
LIs_load_bus_count = input_vars{9};
map_Array = input_vars{10};
BoundedIF = input_vars{11};
lims_Array = input_vars{12};
A2F_BTM_inc_cap = input_vars{13};
GHI_BTM_inc_cap = input_vars{14};
NYC_BTM_inc_cap = input_vars{15};
LIs_BTM_inc_cap = input_vars{16};
A2F_BTM_2016_cap = input_vars{17};
GHI_BTM_2016_cap = input_vars{18};
NYC_BTM_2016_cap = input_vars{19};
LIs_BTM_2016_cap = input_vars{20};
A2F_ITM_inc_wind_cap = input_vars{21};
GHI_ITM_inc_wind_cap = input_vars{22};
NYC_ITM_inc_wind_cap = input_vars{23};
LIs_ITM_inc_wind_cap = input_vars{24};
A2F_ITM_inc_hydro_cap = input_vars{25};
GHI_ITM_inc_hydro_cap = input_vars{26};
NYC_ITM_inc_hydro_cap = input_vars{27};
LIs_ITM_inc_hydro_cap = input_vars{28};
A2F_ITM_inc_PV_cap = input_vars{29};
GHI_ITM_inc_PV_cap = input_vars{30};
NYC_ITM_inc_PV_cap = input_vars{31};
LIs_ITM_inc_PV_cap = input_vars{32};
A2F_ITM_inc_Bio_cap = input_vars{33};
GHI_ITM_inc_Bio_cap = input_vars{34};
NYC_ITM_inc_Bio_cap = input_vars{35};
LIs_ITM_inc_Bio_cap = input_vars{36};
A2F_ITM_inc_LFG_cap = input_vars{37};
GHI_ITM_inc_LFG_cap = input_vars{38};
NYC_ITM_inc_LFG_cap = input_vars{39};
LIs_ITM_inc_LFG_cap = input_vars{40};
A2F_2016_ITM_wind_ICAP = input_vars{41};
A2F_2016_ITM_hydro_ICAP = input_vars{42};
A2F_2016_ITM_PV_ICAP = input_vars{43};
A2F_2016_ITM_Bio_ICAP = input_vars{44};
A2F_2016_ITM_LFG_ICAP = input_vars{45};
EVSE_Gold_MWh = input_vars{46};
EVSE_Gold_MW = input_vars{47};
date_array = input_vars{48};
ren_tab_array = input_vars{49};
A2F_Gen_buses = input_vars{50};
GHI_Gen_buses = input_vars{51};
NYC_Gen_buses = input_vars{52};
LIs_Gen_buses = input_vars{53};
NEw_Gen_buses = input_vars{54};
A2F_gen_bus_count = input_vars{55};
GHI_gen_bus_count = input_vars{56};
NYC_gen_bus_count = input_vars{57};
LIs_gen_bus_count = input_vars{58};
NEw_gen_bus_count = input_vars{59};
A2F_RE_buses = input_vars{60};
GHI_RE_buses = input_vars{61};
NYC_RE_buses = input_vars{62};
LIs_RE_buses = input_vars{63};


%% Create Strings
%Case
if Case == 0
    Case_Name_String = '2016 Base Case';
    casestr = '2016Base';
elseif Case == 1
    Case_Name_String = '2030 Case';
    casestr = '2030x1';
elseif Case == 2
    Case_Name_String = 'Double 2030 Case';
    casestr = '2030x2';
elseif Case == 3
    Case_Name_String = 'Triple 2030 Case';
    casestr = '2030x3';
else
    fprintf(2,'ERROR: Case %d is not a valid option.\n', Case)
    return
end

%Date
yr  = date_array(d,1);
mon = date_array(d,2);
day_= date_array(d,3);
year_str = num2str(yr, '%02i');
month_str = num2str(mon, '%02i');
day_str = num2str(day_, '%02i');
datestring = strcat(year_str,month_str,day_str);


%% Get Net Load from OASIS
%Define the filename
m_file_loc = '../NYISO Data/ActualLoad5min/';

%Get data file
RT_actual_load = load([datestring,'pal.mat']);
% RT_actual_load = load([m_file_loc,datestring,'pal.mat']);

%Initialize
periods = 0:most_period_count-1;
BigTime = most_period_count;
Time4Graph = linspace(0,24,BigTime);

%Given: 2016 Net Load (Source: NYISO OASIS)
A2F_2016_net_load = (RT_actual_load.M(1 +(periods)*11,2)+...%Zone A
    RT_actual_load.M(2 +(periods)*11,2)+...                 %Zone B
    RT_actual_load.M(4 +(periods)*11,2)+...                 %Zone C
    RT_actual_load.M(7 +(periods)*11,2)+...                 %Zone D
    RT_actual_load.M(10+(periods)*11,2)+...                 %Zone E
    RT_actual_load.M(11+(periods)*11,2));                   %Zone F
GHI_2016_net_load = (RT_actual_load.M(3 +(periods)*11,2)+...%Zone G
    RT_actual_load.M(5 +(periods)*11,2)+...                 %Zone H
    RT_actual_load.M(8 +(periods)*11,2));                   %Zone I
NYC_2016_net_load = (RT_actual_load.M(9 +(periods)*11,2));  %Zone J
LIs_2016_net_load = (RT_actual_load.M(6 +(periods)*11,2));  %Zone K


%% Calculate Regional Load Only
%Given: Incremental BTM Generation
BTM = xlsread('rtd_profiles.xlsx',ren_tab_array(d),'C18:KD28');
A2F_BTM_inc_gen = sum(BTM(1:6,:));
GHI_BTM_inc_gen = sum(BTM(7:9,:));
NYC_BTM_inc_gen = BTM(10,:);
LIs_BTM_inc_gen = BTM(11,:);

%Calculate: Load Only (i.e., Net Load + BTM Generation)
A2F_Load_Only = A2F_2016_net_load + A2F_BTM_inc_gen.' ./A2F_BTM_inc_cap .*A2F_BTM_2016_cap;
GHI_Load_Only = GHI_2016_net_load + GHI_BTM_inc_gen.' ./GHI_BTM_inc_cap .*GHI_BTM_2016_cap;
NYC_Load_Only = NYC_2016_net_load + NYC_BTM_inc_gen.' ./NYC_BTM_inc_cap .*NYC_BTM_2016_cap;
LIs_Load_Only = LIs_2016_net_load + LIs_BTM_inc_gen.' ./LIs_BTM_inc_cap .*LIs_BTM_2016_cap;
NYCA_TrueLoad = A2F_Load_Only + GHI_Load_Only+ NYC_Load_Only+ LIs_Load_Only;


%% Calculate Regional BTM Gen
%Calculate: 2016 BTM Generation
A2F_2016_BTM_gen = A2F_BTM_inc_gen.' ./A2F_BTM_inc_cap .*(A2F_BTM_2016_cap );
GHI_2016_BTM_gen = GHI_BTM_inc_gen.' ./GHI_BTM_inc_cap .*(GHI_BTM_2016_cap );
NYC_2016_BTM_gen = NYC_BTM_inc_gen.' ./NYC_BTM_inc_cap .*(NYC_BTM_2016_cap );
LIs_2016_BTM_gen = LIs_BTM_inc_gen.' ./LIs_BTM_inc_cap .*(LIs_BTM_2016_cap );
NYCA_2016_BTM_gen = A2F_2016_BTM_gen + GHI_2016_BTM_gen + NYC_2016_BTM_gen + LIs_2016_BTM_gen;

%INPUT: NEW BTM Capacity (beyond the incremental needed to reach 2030 case)
A2F_BTM_CASE_cap = A2F_BTM_inc_cap*Case;
GHI_BTM_CASE_cap = GHI_BTM_inc_cap*Case;
NYC_BTM_CASE_cap = NYC_BTM_inc_cap*Case;
LIs_BTM_CASE_cap = LIs_BTM_inc_cap*Case;

%Calculate: CASE BTM Generation
A2F_CASE_BTM_gen = A2F_BTM_inc_gen.' ./A2F_BTM_inc_cap .*(A2F_BTM_CASE_cap + A2F_BTM_2016_cap );
GHI_CASE_BTM_gen = GHI_BTM_inc_gen.' ./GHI_BTM_inc_cap .*(GHI_BTM_CASE_cap + GHI_BTM_2016_cap );
NYC_CASE_BTM_gen = NYC_BTM_inc_gen.' ./NYC_BTM_inc_cap .*(NYC_BTM_CASE_cap + NYC_BTM_2016_cap );
LIs_CASE_BTM_gen = LIs_BTM_inc_gen.' ./LIs_BTM_inc_cap .*(LIs_BTM_CASE_cap + LIs_BTM_2016_cap );
NYCA_CASE_BTM_gen = A2F_CASE_BTM_gen + GHI_CASE_BTM_gen + NYC_CASE_BTM_gen + LIs_CASE_BTM_gen;


%% Calculate Regional Net Load
%CASE Net Load (includes NEW)
A2F_CASE_net_load = (A2F_Load_Only - A2F_CASE_BTM_gen);
GHI_CASE_net_load = (GHI_Load_Only - GHI_CASE_BTM_gen);
NYC_CASE_net_load = (NYC_Load_Only - NYC_CASE_BTM_gen);
LIs_CASE_net_load = (LIs_Load_Only - LIs_CASE_BTM_gen);
NYCA_CASE_net_load = A2F_CASE_net_load + GHI_CASE_net_load + NYC_CASE_net_load + LIs_CASE_net_load;


%% Populate Net Load into MOST
most_busload = zeros(most_period_count,52);
int_start = 1;
int_stop  = most_period_count;
for int = int_start:int_stop
    %Distribute P_load
    i=1:A2F_load_bus_count;
    most_busload(int, A2F_Load_buses(i)) = A2F_CASE_net_load(int)./A2F_load_bus_count;
    i=1:GHI_load_bus_count;
    most_busload(int, GHI_Load_buses(i)) = GHI_CASE_net_load(int)./GHI_load_bus_count;
    i=1:NYC_load_bus_count;
    most_busload(int, NYC_Load_buses(i)) = NYC_CASE_net_load(int)./NYC_load_bus_count;
    i=1:LIs_load_bus_count;
    most_busload(int, LIs_Load_buses(i)) = LIs_CASE_net_load(int)./LIs_load_bus_count;
end


%% Modify for DAM (24 periods)
%Take average of load values in an hour
most_busload_DAM = zeros(most_period_count_DAM,52);
int_start_DAM = 1;
int_stop_DAM = most_period_count_DAM;
for int_DAM = int_start_DAM:int_stop_DAM
    if useinstant == 1
        most_busload_DAM(int_DAM,:) = most_busload(int_DAM*12-11,:);
    else
        most_busload_DAM(int_DAM,:) = mean(most_busload(int_DAM*12-11:int_DAM*12,:));
    end
end

%Reduce by 100*(1 - undrbidfac)% to account for underbidding of load
most_busload_DAM = most_busload_DAM.*undrbidfac;


%% ITM Renewable Generation
%Gather ITM Generation for INCREMENTAL generation capacity
wind  = xlsread('rtd_profiles.xlsx',ren_tab_array(d),'C34:KD44');
hydro = xlsread('rtd_profiles.xlsx',ren_tab_array(d),'C49:KD59');
PV = xlsread('rtd_profiles.xlsx',ren_tab_array(d),'C64:KD74');
Bio = xlsread('rtd_profiles.xlsx',ren_tab_array(d),'C79:KD89');
LFG   = xlsread('rtd_profiles.xlsx',ren_tab_array(d),'C94:KD104');


%% Calculate output per MW installed capacity
%WIND
%ITM Generation for INCREMENTAL generation capacity by Zone
A2F_INC_ITM_wind_gen = sum(wind(1:6,:));
GHI_INC_ITM_wind_gen = sum(wind(7:9,:));
NYC_INC_ITM_wind_gen =     wind(10,:);
LIs_INC_ITM_wind_gen =     wind(11,:);
%Amount of ITM Wind Generation per MW of ICAP by Zone
A2F_ITM_wind_gen_per_iCAP_MW  = A2F_INC_ITM_wind_gen./A2F_ITM_inc_wind_cap;
GHI_ITM_wind_gen_per_iCAP_MW  = GHI_INC_ITM_wind_gen./GHI_ITM_inc_wind_cap;
NYC_ITM_wind_gen_per_iCAP_MW  = NYC_INC_ITM_wind_gen./NYC_ITM_inc_wind_cap;
LIs_ITM_wind_gen_per_iCAP_MW  = LIs_INC_ITM_wind_gen./LIs_ITM_inc_wind_cap;
%Remove NaN's
A2F_ITM_wind_gen_per_iCAP_MW(isnan(A2F_ITM_wind_gen_per_iCAP_MW))=0;
GHI_ITM_wind_gen_per_iCAP_MW(isnan(GHI_ITM_wind_gen_per_iCAP_MW))=0;
NYC_ITM_wind_gen_per_iCAP_MW(isnan(NYC_ITM_wind_gen_per_iCAP_MW))=0;
LIs_ITM_wind_gen_per_iCAP_MW(isnan(LIs_ITM_wind_gen_per_iCAP_MW))=0;


%HYDRO
%ITM Generation for INCREMENTAL generation capacity by Zone
A2F_INC_ITM_hydro_gen = sum(hydro(1:6,:));
GHI_INC_ITM_hydro_gen = sum(hydro(7:9,:));
NYC_INC_ITM_hydro_gen =     hydro(10,:);
LIs_INC_ITM_hydro_gen =     hydro(11,:);
%Amount of ITM Hydro Generation per MW of ICAP by Zone
A2F_ITM_hydro_gen_per_iCAP_MW  = A2F_INC_ITM_hydro_gen./A2F_ITM_inc_hydro_cap;
GHI_ITM_hydro_gen_per_iCAP_MW  = GHI_INC_ITM_hydro_gen./GHI_ITM_inc_hydro_cap;
NYC_ITM_hydro_gen_per_iCAP_MW  = NYC_INC_ITM_hydro_gen./NYC_ITM_inc_hydro_cap;
LIs_ITM_hydro_gen_per_iCAP_MW  = LIs_INC_ITM_hydro_gen./LIs_ITM_inc_hydro_cap;
%Remove NaN's
A2F_ITM_hydro_gen_per_iCAP_MW(isnan(A2F_ITM_hydro_gen_per_iCAP_MW))=0;
GHI_ITM_hydro_gen_per_iCAP_MW(isnan(GHI_ITM_hydro_gen_per_iCAP_MW))=0;
NYC_ITM_hydro_gen_per_iCAP_MW(isnan(NYC_ITM_hydro_gen_per_iCAP_MW))=0;
LIs_ITM_hydro_gen_per_iCAP_MW(isnan(LIs_ITM_hydro_gen_per_iCAP_MW))=0;


%Utility-Scale PV
%ITM Generation for INCREMENTAL generation capacity by Zone
A2F_INC_ITM_PV_gen = sum(PV(1:6,:));
GHI_INC_ITM_PV_gen = sum(PV(7:9,:));
NYC_INC_ITM_PV_gen =     PV(10,:);
LIs_INC_ITM_PV_gen =     PV(11,:);
%Amount of ITM PV Generation per MW of ICAP by Zone
A2F_ITM_PV_gen_per_iCAP_MW  = A2F_INC_ITM_PV_gen./A2F_ITM_inc_PV_cap;
GHI_ITM_PV_gen_per_iCAP_MW  = GHI_INC_ITM_PV_gen./GHI_ITM_inc_PV_cap;
NYC_ITM_PV_gen_per_iCAP_MW  = NYC_INC_ITM_PV_gen./NYC_ITM_inc_PV_cap;
LIs_ITM_PV_gen_per_iCAP_MW  = LIs_INC_ITM_PV_gen./LIs_ITM_inc_PV_cap;
%Remove NaN's
A2F_ITM_PV_gen_per_iCAP_MW(isnan(A2F_ITM_PV_gen_per_iCAP_MW))=0;
GHI_ITM_PV_gen_per_iCAP_MW(isnan(GHI_ITM_PV_gen_per_iCAP_MW))=0;
NYC_ITM_PV_gen_per_iCAP_MW(isnan(NYC_ITM_PV_gen_per_iCAP_MW))=0;
LIs_ITM_PV_gen_per_iCAP_MW(isnan(LIs_ITM_PV_gen_per_iCAP_MW))=0;


%BIOMASS
%ITM Generation for INCREMENTAL generation capacity by Zone
A2F_INC_ITM_Bio_gen = sum(Bio(1:6,:));
GHI_INC_ITM_Bio_gen = sum(Bio(7:9,:));
NYC_INC_ITM_Bio_gen =     Bio(10,:);
LIs_INC_ITM_Bio_gen =     Bio(11,:);
%Amount of ITM Bio Generation per MW of ICAP by Zone
A2F_ITM_Bio_gen_per_iCAP_MW  = A2F_INC_ITM_Bio_gen./A2F_ITM_inc_Bio_cap;
GHI_ITM_Bio_gen_per_iCAP_MW  = GHI_INC_ITM_Bio_gen./GHI_ITM_inc_Bio_cap;
NYC_ITM_Bio_gen_per_iCAP_MW  = NYC_INC_ITM_Bio_gen./NYC_ITM_inc_Bio_cap;
LIs_ITM_Bio_gen_per_iCAP_MW  = LIs_INC_ITM_Bio_gen./LIs_ITM_inc_Bio_cap;
%Remove NaN's
A2F_ITM_Bio_gen_per_iCAP_MW(isnan(A2F_ITM_Bio_gen_per_iCAP_MW))=0;
GHI_ITM_Bio_gen_per_iCAP_MW(isnan(GHI_ITM_Bio_gen_per_iCAP_MW))=0;
NYC_ITM_Bio_gen_per_iCAP_MW(isnan(NYC_ITM_Bio_gen_per_iCAP_MW))=0;
LIs_ITM_Bio_gen_per_iCAP_MW(isnan(LIs_ITM_Bio_gen_per_iCAP_MW))=0;


%Landfill Gas (LFG)
%ITM Generation for INCREMENTAL generation capacity by Zone
A2F_INC_ITM_LFG_gen = sum(LFG(1:6,:));
GHI_INC_ITM_LFG_gen = sum(LFG(7:9,:));
NYC_INC_ITM_LFG_gen =     LFG(10,:);
LIs_INC_ITM_LFG_gen =     LFG(11,:);
%Amount of ITM LFG Generation per MW of ICAP by Zone
A2F_ITM_LFG_gen_per_iCAP_MW  = A2F_INC_ITM_LFG_gen./A2F_ITM_inc_LFG_cap;
GHI_ITM_LFG_gen_per_iCAP_MW  = GHI_INC_ITM_LFG_gen./GHI_ITM_inc_LFG_cap;
NYC_ITM_LFG_gen_per_iCAP_MW  = NYC_INC_ITM_LFG_gen./NYC_ITM_inc_LFG_cap;
LIs_ITM_LFG_gen_per_iCAP_MW  = LIs_INC_ITM_LFG_gen./LIs_ITM_inc_LFG_cap;
%Remove NaN's
A2F_ITM_LFG_gen_per_iCAP_MW(isnan(A2F_ITM_LFG_gen_per_iCAP_MW))=0;
GHI_ITM_LFG_gen_per_iCAP_MW(isnan(GHI_ITM_LFG_gen_per_iCAP_MW))=0;
NYC_ITM_LFG_gen_per_iCAP_MW(isnan(NYC_ITM_LFG_gen_per_iCAP_MW))=0;
LIs_ITM_LFG_gen_per_iCAP_MW(isnan(LIs_ITM_LFG_gen_per_iCAP_MW))=0;


%% Incremental Generation
% Calculate ITM Capacity under current Case
A2F_ITM_CASE_wind_cap  = Case*A2F_ITM_inc_wind_cap;
GHI_ITM_CASE_wind_cap  = Case*GHI_ITM_inc_wind_cap;
NYC_ITM_CASE_wind_cap  = Case*NYC_ITM_inc_wind_cap;
LIs_ITM_CASE_wind_cap  = Case*LIs_ITM_inc_wind_cap;

A2F_ITM_CASE_hydro_cap = Case*A2F_ITM_inc_hydro_cap;
GHI_ITM_CASE_hydro_cap = Case*GHI_ITM_inc_hydro_cap;
NYC_ITM_CASE_hydro_cap = Case*NYC_ITM_inc_hydro_cap;
LIs_ITM_CASE_hydro_cap = Case*LIs_ITM_inc_hydro_cap;

A2F_ITM_CASE_PV_cap    = Case*A2F_ITM_inc_PV_cap;
GHI_ITM_CASE_PV_cap    = Case*GHI_ITM_inc_PV_cap;
NYC_ITM_CASE_PV_cap    = Case*NYC_ITM_inc_PV_cap;
LIs_ITM_CASE_PV_cap    = Case*LIs_ITM_inc_PV_cap;

A2F_ITM_CASE_Bio_cap   = Case*A2F_ITM_inc_Bio_cap;
GHI_ITM_CASE_Bio_cap   = Case*GHI_ITM_inc_Bio_cap;
NYC_ITM_CASE_Bio_cap   = Case*NYC_ITM_inc_Bio_cap;
LIs_ITM_CASE_Bio_cap   = Case*LIs_ITM_inc_Bio_cap;

A2F_ITM_CASE_LFG_cap   = Case*A2F_ITM_inc_LFG_cap;
GHI_ITM_CASE_LFG_cap   = Case*GHI_ITM_inc_LFG_cap;
NYC_ITM_CASE_LFG_cap   = Case*NYC_ITM_inc_LFG_cap;
LIs_ITM_CASE_LFG_cap   = Case*LIs_ITM_inc_LFG_cap;

% Calculate ITM Output profile under current Case
A2F_ITM_CASE_windy_Gen = A2F_ITM_wind_gen_per_iCAP_MW  .*A2F_ITM_CASE_wind_cap;
A2F_ITM_CASE_hydro_Gen = A2F_ITM_hydro_gen_per_iCAP_MW .*A2F_ITM_CASE_hydro_cap;
A2F_ITM_CASE_other_Gen = A2F_ITM_PV_gen_per_iCAP_MW    .*A2F_ITM_CASE_PV_cap + ...
    A2F_ITM_Bio_gen_per_iCAP_MW   .*A2F_ITM_CASE_Bio_cap + ...
    A2F_ITM_LFG_gen_per_iCAP_MW   .*A2F_ITM_CASE_LFG_cap; %%%%%
A2F_ITM_CASE_Gen = A2F_ITM_CASE_windy_Gen + A2F_ITM_CASE_hydro_Gen + A2F_ITM_CASE_other_Gen;

GHI_ITM_CASE_windy_Gen = GHI_ITM_wind_gen_per_iCAP_MW  .*GHI_ITM_CASE_wind_cap;
GHI_ITM_CASE_hydro_Gen = GHI_ITM_hydro_gen_per_iCAP_MW .*GHI_ITM_CASE_hydro_cap;
GHI_ITM_CASE_other_Gen = GHI_ITM_PV_gen_per_iCAP_MW    .*GHI_ITM_CASE_PV_cap + ...
    GHI_ITM_Bio_gen_per_iCAP_MW   .*GHI_ITM_CASE_Bio_cap + ...
    GHI_ITM_LFG_gen_per_iCAP_MW   .*GHI_ITM_CASE_LFG_cap; %%%%%
GHI_ITM_CASE_Gen = GHI_ITM_CASE_windy_Gen + GHI_ITM_CASE_hydro_Gen + GHI_ITM_CASE_other_Gen;

NYC_ITM_CASE_windy_Gen = NYC_ITM_wind_gen_per_iCAP_MW  .*NYC_ITM_CASE_wind_cap;
NYC_ITM_CASE_hydro_Gen = NYC_ITM_hydro_gen_per_iCAP_MW .*NYC_ITM_CASE_hydro_cap;
NYC_ITM_CASE_other_Gen = NYC_ITM_PV_gen_per_iCAP_MW    .*NYC_ITM_CASE_PV_cap + ...
    NYC_ITM_Bio_gen_per_iCAP_MW   .*NYC_ITM_CASE_Bio_cap + ...
    NYC_ITM_LFG_gen_per_iCAP_MW   .*NYC_ITM_CASE_LFG_cap; %%%%%
NYC_ITM_CASE_Gen = NYC_ITM_CASE_windy_Gen + NYC_ITM_CASE_hydro_Gen + NYC_ITM_CASE_other_Gen;

LIs_ITM_CASE_windy_Gen = LIs_ITM_wind_gen_per_iCAP_MW  .*LIs_ITM_CASE_wind_cap;
LIs_ITM_CASE_hydro_Gen = LIs_ITM_hydro_gen_per_iCAP_MW .*LIs_ITM_CASE_hydro_cap;
LIs_ITM_CASE_other_Gen = LIs_ITM_PV_gen_per_iCAP_MW    .*LIs_ITM_CASE_PV_cap + ...
    LIs_ITM_Bio_gen_per_iCAP_MW   .*LIs_ITM_CASE_Bio_cap + ...
    LIs_ITM_LFG_gen_per_iCAP_MW   .*LIs_ITM_CASE_LFG_cap; %%%%%
LIs_ITM_CASE_Gen = LIs_ITM_CASE_windy_Gen + LIs_ITM_CASE_hydro_Gen + LIs_ITM_CASE_other_Gen;

Tot_ITM_CASE_Gen = A2F_ITM_CASE_Gen + GHI_ITM_CASE_Gen + NYC_ITM_CASE_Gen + LIs_ITM_CASE_Gen;


%% 2016 Generation
%Calculate output for existing A2F renewables
A2F_2016_ITM_windy_Gen = A2F_ITM_wind_gen_per_iCAP_MW  .*A2F_2016_ITM_wind_ICAP;
A2F_2016_ITM_hydro_Gen = A2F_ITM_hydro_gen_per_iCAP_MW .*A2F_2016_ITM_hydro_ICAP;
A2F_2016_ITM_other_Gen = A2F_ITM_PV_gen_per_iCAP_MW    .*A2F_2016_ITM_PV_ICAP + ...
    A2F_ITM_Bio_gen_per_iCAP_MW   .*A2F_2016_ITM_Bio_ICAP + ...
    A2F_ITM_LFG_gen_per_iCAP_MW   .*A2F_2016_ITM_LFG_ICAP; %%%%%
A2F_2016_ITM_Gen = A2F_2016_ITM_windy_Gen + A2F_2016_ITM_hydro_Gen + A2F_2016_ITM_other_Gen;


%% Gen Capacity by region for the current case
%All gen by region
A2F_all_CASE_gencap = A2F_2016_ITM_wind_ICAP + A2F_2016_ITM_hydro_ICAP + A2F_2016_ITM_PV_ICAP+ A2F_2016_ITM_Bio_ICAP + A2F_2016_ITM_LFG_ICAP + ...
    A2F_ITM_CASE_wind_cap + A2F_ITM_CASE_hydro_cap + A2F_ITM_CASE_PV_cap + A2F_ITM_CASE_Bio_cap + A2F_ITM_CASE_LFG_cap;
GHI_all_CASE_gencap = GHI_ITM_CASE_wind_cap + GHI_ITM_CASE_hydro_cap + GHI_ITM_CASE_PV_cap+ GHI_ITM_CASE_Bio_cap + GHI_ITM_CASE_LFG_cap;
NYC_all_CASE_gencap = NYC_ITM_CASE_wind_cap + NYC_ITM_CASE_hydro_cap + NYC_ITM_CASE_PV_cap+ NYC_ITM_CASE_Bio_cap + NYC_ITM_CASE_LFG_cap;
LIs_all_CASE_gencap = LIs_ITM_CASE_wind_cap + LIs_ITM_CASE_hydro_cap + LIs_ITM_CASE_PV_cap+ LIs_ITM_CASE_Bio_cap + LIs_ITM_CASE_LFG_cap;
%Renewable statewide totals
TOT_ITM_CASE_wind_cap   = A2F_2016_ITM_wind_ICAP  + A2F_ITM_CASE_wind_cap  + GHI_ITM_CASE_wind_cap  + NYC_ITM_CASE_wind_cap + LIs_ITM_CASE_wind_cap;
TOT_ITM_CASE_hydro_cap  = A2F_2016_ITM_hydro_ICAP + A2F_ITM_CASE_hydro_cap + GHI_ITM_CASE_hydro_cap + NYC_ITM_CASE_hydro_cap + LIs_ITM_CASE_hydro_cap;
TOT_ITM_CASE_PV_cap     = A2F_2016_ITM_PV_ICAP    + A2F_ITM_CASE_PV_cap    + GHI_ITM_CASE_PV_cap    + NYC_ITM_CASE_PV_cap + LIs_ITM_CASE_PV_cap;
TOT_ITM_CASE_Bio_cap    = A2F_2016_ITM_Bio_ICAP   + A2F_ITM_CASE_Bio_cap   + GHI_ITM_CASE_Bio_cap   + NYC_ITM_CASE_Bio_cap + LIs_ITM_CASE_Bio_cap;
TOT_ITM_CASE_LFG_cap    = A2F_2016_ITM_LFG_ICAP   + A2F_ITM_CASE_LFG_cap   + GHI_ITM_CASE_LFG_cap   + NYC_ITM_CASE_LFG_cap + LIs_ITM_CASE_LFG_cap;


%% Populate ITM Gen into MOST
% Determine amount of renewable generation to be added to each region
A2F_ITM_windy_gen_tot = A2F_ITM_CASE_windy_Gen + A2F_2016_ITM_windy_Gen;
A2F_ITM_hydro_gen_tot = A2F_ITM_CASE_hydro_Gen + A2F_2016_ITM_hydro_Gen;
A2F_ITM_other_gen_tot = A2F_ITM_CASE_other_Gen + A2F_2016_ITM_other_Gen; %%%%%
A2F_ITM_gen_tot = A2F_ITM_windy_gen_tot + A2F_ITM_hydro_gen_tot + A2F_ITM_other_gen_tot;

GHI_ITM_windy_gen_tot = GHI_ITM_CASE_windy_Gen;
GHI_ITM_hydro_gen_tot = GHI_ITM_CASE_hydro_Gen;
GHI_ITM_other_gen_tot = GHI_ITM_CASE_other_Gen; %%%%%
GHI_ITM_gen_tot = GHI_ITM_windy_gen_tot + GHI_ITM_hydro_gen_tot + GHI_ITM_other_gen_tot;

NYC_ITM_windy_gen_tot = NYC_ITM_CASE_windy_Gen;
NYC_ITM_hydro_gen_tot = NYC_ITM_CASE_hydro_Gen;
NYC_ITM_other_gen_tot = NYC_ITM_CASE_other_Gen; %%%%%
NYC_ITM_gen_tot = NYC_ITM_windy_gen_tot + NYC_ITM_hydro_gen_tot + NYC_ITM_other_gen_tot;

LIs_ITM_windy_gen_tot = LIs_ITM_CASE_windy_Gen;
LIs_ITM_hydro_gen_tot = LIs_ITM_CASE_hydro_Gen;
LIs_ITM_other_gen_tot = LIs_ITM_CASE_other_Gen; %%%%%
LIs_ITM_gen_tot = LIs_ITM_windy_gen_tot + LIs_ITM_hydro_gen_tot + LIs_ITM_other_gen_tot;

%Statewide Totals by rengen type
TOT_ITM_windy_gen_profile = A2F_ITM_windy_gen_tot + GHI_ITM_windy_gen_tot + NYC_ITM_windy_gen_tot + LIs_ITM_windy_gen_tot;
TOT_ITM_hydro_gen_profile = A2F_ITM_hydro_gen_tot + GHI_ITM_hydro_gen_tot + NYC_ITM_hydro_gen_tot + LIs_ITM_hydro_gen_tot;
TOT_ITM_other_gen_profile = A2F_ITM_other_gen_tot + GHI_ITM_other_gen_tot + NYC_ITM_other_gen_tot + LIs_ITM_other_gen_tot;


%% First 5min generation value vs. Avg hourly value
if Avg5mingencompare == 1
    %get 24 hr profile for all renewables together
    TOT_ITM_profile = TOT_ITM_windy_gen_profile + TOT_ITM_hydro_gen_profile + TOT_ITM_other_gen_profile;
    %find first of the hour values
    FirstValues = zeros(24,1);
    for int = 1:24
        FirstValues(int,:) = TOT_ITM_profile(1,int*12-11);
        FirstValuesLine(int*12-11:int*12,:) = FirstValues(int,:);
    end
    %find average of the hour values
    AverageValues = zeros(24,1);
    for int = 1:24
        AverageValues(int,:) = mean(TOT_ITM_profile(1,int*12-11:int*12));
        AverageValuesLine(int*12-11:int*12,:) = AverageValues(int,:);
    end
    %create a plot
    %                     hFig1 = figure(1);
    %                     hold on
    %                     set(hFig1, 'Position', [450 50 900 400]) %Pixels: from left, from bottom, across, high
    %                     plot(Time4Graph, TOT_ITM_profile)
    %                     plot(Time4Graph, FirstValuesLine)
    %                     plot(Time4Graph, AverageValuesLine)
    %                     legend('Total Renewable','First Values','Average Values')
    %                     legend('Location','eastoutside'),
    %                     set(gca, 'XTick', [0 4 8 12 16 20 24]);
    %                     grid on
    %                     grid minor
    %                     First_Line_Title = ['First vs. Average Values of Renewable Output for: ', datestring(5:6), ' ', datestring(7:8), ' ', datestring(1:4), ' in the ',Case_Name_String];
    %                     ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off',...
    %                         'Units','normalized', 'clipping' , 'off');
    %                     text(0.5, 1.0,[{'\bf \fontsize{12}' First_Line_Title}], 'HorizontalAlignment' ,...
    %                         'center', 'VerticalAlignment', 'top')
    %                     hold off
end


%% Format Renewables and Load for MOST
% Wind
most_bus_rengen_windy = zeros(most_period_count,68);
for int = int_start:int_stop
    %Distribute ITM renewable generation
    i=1:A2F_gen_bus_count;
    most_bus_rengen_windy(int, A2F_Gen_buses(i)) = A2F_ITM_windy_gen_tot(int)./A2F_gen_bus_count;
    i=1:GHI_gen_bus_count;
    most_bus_rengen_windy(int, GHI_Gen_buses(i)) = GHI_ITM_windy_gen_tot(int)./GHI_gen_bus_count;
    i=1:NYC_gen_bus_count;
    most_bus_rengen_windy(int, NYC_Gen_buses(i)) = NYC_ITM_windy_gen_tot(int)./NYC_gen_bus_count;
    i=1:LIs_gen_bus_count;
    most_bus_rengen_windy(int, LIs_Gen_buses(i)) = LIs_ITM_windy_gen_tot(int)./LIs_gen_bus_count;
end

%Remove empty rows
most_bus_rengen_windy(:,62) = [];
most_bus_rengen_windy(:,1:52) = [];

%DAM Averages - take average of load values in an hour
most_windy_gen_DAM = zeros(most_period_count_DAM,15);
for int_DAM = int_start_DAM: int_stop_DAM
    if useinstant ==1
        most_windy_gen_DAM(int_DAM,:) = most_bus_rengen_windy(int_DAM*12-11,:);
    else
        most_windy_gen_DAM(int_DAM,:) = mean(most_bus_rengen_windy(int_DAM*12-11:int_DAM*12,:));
    end
end


% Hydro
most_bus_rengen_hydro = zeros(most_period_count,68);
for int = int_start:int_stop
    %Distribute ITM renewable generation
    i=1:A2F_gen_bus_count;
    most_bus_rengen_hydro(int, A2F_Gen_buses(i)) = A2F_ITM_hydro_gen_tot(int)./A2F_gen_bus_count;
    i=1:GHI_gen_bus_count;
    most_bus_rengen_hydro(int, GHI_Gen_buses(i)) = GHI_ITM_hydro_gen_tot(int)./GHI_gen_bus_count;
    i=1:NYC_gen_bus_count;
    most_bus_rengen_hydro(int, NYC_Gen_buses(i)) = NYC_ITM_hydro_gen_tot(int)./NYC_gen_bus_count;
    i=1:LIs_gen_bus_count;
    most_bus_rengen_hydro(int, LIs_Gen_buses(i)) = LIs_ITM_hydro_gen_tot(int)./LIs_gen_bus_count;
end

%Remove empty rows
most_bus_rengen_hydro(:,62) = [];
most_bus_rengen_hydro(:,1:52) = [];

%DAM Averages - take average of load values in an hour
most_hydro_gen_DAM = zeros(most_period_count_DAM,15);
for int_DAM = int_start_DAM: int_stop_DAM
    if useinstant ==1
        most_hydro_gen_DAM(int_DAM,:) = most_bus_rengen_hydro(int_DAM*12-11,:);
    else
        most_hydro_gen_DAM(int_DAM,:) = mean(most_bus_rengen_hydro(int_DAM*12-11:int_DAM*12,:));
    end
end


% Solar
% !!!!!


% Other
most_bus_rengen_other = zeros(most_period_count,68);
for int = int_start:int_stop
    %Distribute ITM renewable generation
    i=1:A2F_gen_bus_count;
    most_bus_rengen_other(int, A2F_Gen_buses(i)) = A2F_ITM_other_gen_tot(int)./A2F_gen_bus_count;
    i=1:GHI_gen_bus_count;
    most_bus_rengen_other(int, GHI_Gen_buses(i)) = GHI_ITM_other_gen_tot(int)./GHI_gen_bus_count;
    i=1:NYC_gen_bus_count;
    most_bus_rengen_other(int, NYC_Gen_buses(i)) = NYC_ITM_other_gen_tot(int)./NYC_gen_bus_count;
    i=1:LIs_gen_bus_count;
    most_bus_rengen_other(int, LIs_Gen_buses(i)) = LIs_ITM_other_gen_tot(int)./LIs_gen_bus_count;
end

%Remove empty rows
most_bus_rengen_other(:,62) = [];
most_bus_rengen_other(:,1:52) = [];

%DAM Averages - take average of load values in an hour
most_other_gen_DAM = zeros(most_period_count_DAM,15);
for int_DAM = int_start_DAM: int_stop_DAM
    if useinstant ==1
        most_other_gen_DAM(int_DAM,:) = most_bus_rengen_other(int_DAM*12-11,:);
    else
        most_other_gen_DAM(int_DAM,:) = mean(most_bus_rengen_other(int_DAM*12-11:int_DAM*12,:));
    end
end


%Determine amount of thermal generation needed
Tot_ITM_Gen = Tot_ITM_CASE_Gen + A2F_2016_ITM_Gen;
Tot_BTM_Gen = NYCA_2016_BTM_gen + NYCA_CASE_BTM_gen;
demand = NYCA_CASE_net_load - Tot_ITM_Gen.';

demand_DAM = zeros(1,24);
NYCA_CASE_net_load_DAM = zeros(1,24);
NYCA_TrueLoad_DAM = zeros(1,24);
for t = 1:24
    demand_DAM(t) = mean(demand(t*12-11:t*12));
    NYCA_CASE_net_load_DAM(t) = mean(NYCA_CASE_net_load(t*12-11:t*12));
    NYCA_TrueLoad_DAM(t) = mean(NYCA_TrueLoad(t*12-11:t*12));
end

% Load Statistics
NYCA_TrueLoad_AVG_24hr = mean(NYCA_TrueLoad_DAM);
NYCA_TrueLoad_AVG_4hr = mean(NYCA_TrueLoad_DAM(10:14));
NYCA_NetLoad_AVG_24hr = mean(NYCA_CASE_net_load_DAM);
NYCA_NetLoad_AVG_4hr = mean(NYCA_CASE_net_load_DAM(10:14));

end

