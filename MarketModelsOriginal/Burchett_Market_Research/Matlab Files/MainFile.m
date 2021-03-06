%% Changes
%This is the working file from MarketModel

%

%% Setup
% Start from a Clean Slate
    clear all
    close all
    clc
tic
%% Add Paths
    %Create a path to the 5 minute NYISO Load Data Stock
        path_5minLoad = 'C:\Users\steph\Documents\SMB\RPI\NYISO\Report\Code\ActualLoad5min'; 
        addpath(genpath(path_5minLoad)) 
    %Create a path to the Renewable Data
        path_ren = 'C:\Users\steph\Documents\SMB\RPI\NYISO\Report\Code\renewableData'; 
        addpath(genpath(path_ren)) 
    %Create a path to the Matpower application
        path_Matpower = 'C:\Users\steph\Documents\SMB\RPI\NYISO\MatPower'; 
        addpath(genpath(path_Matpower))
    %Create a path to the MOST application
        path_MOST = 'C:\Users\steph\Documents\SMB\RPI\NYISO\MatPower\most'; 
        addpath(genpath(path_MOST))
    %Create a path to GUROBI
        path_Gurobi = 'C:\gurobi751\win64\matlab'; 
        addpath(genpath(path_Gurobi))
    %Create paths for this file and its subfunctions 
        path_this_file = 'C:\Users\steph\Documents\SMB\RPI\NYISO\MatPower Files\git\MarketModel'; 
        addpath(genpath(path_this_file))
   %Create paths for this file
        path_fxns = 'C:\Users\steph\Documents\SMB\RPI\NYISO\MatPower Files\git\MarketModel\Functions'; 
        addpath(genpath(path_fxns))        
   %Create paths for Data Files 
        path_data = 'C:\Users\steph\Documents\SMB\RPI\NYISO\MatPower Files\git\MarketModel\Program_Files'; 
        addpath(genpath(path_data))     
%% Font Size for publishing

set(0,'DefaultAxesFontSize',14)
set(0,'DefaultTextFontSize',14)
set(0,'DefaultLineLinewidth',1)
disp('changing font sizes to 14 and line width = 1.5') 
%% Define Initial Variables
%Define Load Buses by zone
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
%Define Gen Buses by zone    
%   A2F_Gen_buses = [62; 63; 64; 65; 66; 67; 68;]; %removed gen at bus 62 for ref bus and bus 63 for no ITM in base case
    A2F_Gen_buses = [        64; 65; 66; 67; 68;];
    GHI_Gen_buses = [53; 54; 60;];
    NYC_Gen_buses = [55; 56; 57;];
    LIs_Gen_buses = [58; 59;];
    NEw_Gen_buses = [61;];    
    A2F_gen_bus_count = length(A2F_Gen_buses);  
    GHI_gen_bus_count = length(GHI_Gen_buses);  
    NYC_gen_bus_count = length(NYC_Gen_buses);  
    LIs_gen_bus_count = length(LIs_Gen_buses);  
    NEw_gen_bus_count = length(NEw_Gen_buses);  
% RTD Value Storage Arrays
    RTD_Load_Storage = zeros(68,288);
    RTD_Gen_Storage = zeros(59,288);
    RTD_RenGen_Max_Storage = zeros(45,288);
    RTD_RenGen_Min_Storage = zeros(45,288);
%% Add transmission interface limits
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
%% Set Simulation Control Parameters
%Pick Date Range
    d_start = 1;  
    d_end   = 4;  
    date_array = [2016,1,19;2016,3,22;2016,7,25;2016,11,10];
    ren_tab_array = ["Jan 19";"Mar 22";"Jul 25";"Nov 10";];
%Pick Case    %0 = Base Case,   1 = 2030 Case,      2 = 2X2030 Case,        3 = 3X2030 Case
    case_start = 0;
    case_end   = 1; 
%Interface Flow Limits Enforced? 
    IFlims = 0;
    printCurt = 1;
%Pick number of RTC points. 
    RTC_periods = 30; %should be divisible by 3 and 12.
    RTC_hrs = RTC_periods/12;
%REC Cost
    REC_Cost =  0; %set to negative number ($-5/MWh) for Renewable Energy Credit
    REC_hydro = 0;
    RenInOpCost = 0;
%EVSE Load?
    EVSE = 0; %"1" is on, "0" is off.
    EVSEfactor = 1; %"1" is 1x NYISO estimate.  "2" will double MW and MWh estimates

%% Run Simulation
for Case = case_start:case_end
for d = d_start: d_end
%Is Renewable Curtailable in DAM? (1 = mingen is zero, 0 = mingen is maxgen)
    windyCurt = 1;
    hydroCurt = 1;
    otherCurt = 1; 
%Reduce min gen from max gen by a factor of:  (Value between 0 (full curtailment allowed) and 1(No curtailment allowed).   
    windyCurtFactor = 0;
    hydroCurtFactor = 0;
    otherCurtFactor = 0;
%Increase the Ramp Rate: Yes or No  (1 = yes, 0 = no)
    IncreasedDAMramp = 1; %reduces Steam and CC units ramp rate in DAM
    IncreasedRTCramp_Steam = 1; %reduces Steam and CC units ramp rate in RTC
    IncreasedRTDramp_Steam = 1; %reduces Steam and CC units ramp rate in RTC
    IncreasedRTCramp_CC = 1; %reduces Steam and CC units ramp rate in RTC
    IncreasedRTDramp_CC = 1; %reduces Steam and CC units ramp rate in RTC
%How much should we increase Ramp Rate beyond original mpc.gen input from "Matpower Input Data" excel file
    DAMrampFactor = 1.0; %Don't ever change this from 1.0
    RTCrampFactor_Steam = 1.1;
    RTDrampFactor_Steam = 1.1;
    RTCrampFactor_CC = 1.1;
    RTDrampFactor_CC = 1.1;
%Retire a Nuclear Unit? 
    killNuke = 1;  %!!NOTE: '2' will eliminate one of the GHI nuke plants. '1' will allow all nukes to operate
%Should we make min gen's even lower? (1= yes, 0= no)
    droppit = 0;
%Want to print every RTC result?(1= yes, 0= no)
    printRTC = 0;
%Shall we cut the min run time in half?(1= yes, 0= no)
    minrunshorter = 0;
%Use average across hour or first instant of the hour for DAM forcast
    useinstant = 0;
%Make DAM committed NUKE & STEAM units 'Must Run' during RTC? (1 = yes, 0 = no)
    mustRun = 1; %This should be set to 1 for all units for always. 
%% Create Strings
    %Case
        if Case == 0; Case_Name_String = '2016 Base Case'; end 
        if Case == 1; Case_Name_String = '2030 Case'; end 
        if Case == 2; Case_Name_String = 'Double Case'; end 
        if Case == 3; Case_Name_String = 'Triple Case'; end 
    %Date 
        yr  = date_array(d,1);
        mon = date_array(d,2);
        day_= date_array(d,3);
        year_str = num2str(yr, '%02i');
        month_str = num2str(mon, '%02i');
        day_str = num2str(day_, '%02i');
        datestring = strcat(year_str,month_str,day_str);
        day_str_print = num2str(day_);
%% NET LOAD
    %% Get Net Load from OASIS
    %Define the filename
        m_file_loc = 'C:\Users\steph\Documents\SMB\RPI\NYISO\Data_Dump\RT_ACTUAL_LOAD\';
    %Get data file
        RT_actual_load = load([m_file_loc,datestring,'pal.mat']);       
    %Initialize
        fivemin_period_count = 288;
        periods = 0:fivemin_period_count-1;
        BigTime = fivemin_period_count;
        Time4Graph = linspace(0,24,BigTime);
    %Given: 2016 Net Load (Source: NYISO OASIS)
        A2F_2016_net_load = (RT_actual_load.M(1 +(periods)*11,2)+... %Zone A
                            RT_actual_load.M(2 +(periods)*11,2)+... %Zone B
                            RT_actual_load.M(4 +(periods)*11,2)+... %Zone C
                            RT_actual_load.M(7 +(periods)*11,2)+... %Zone D
                            RT_actual_load.M(10+(periods)*11,2)+... %Zone E
                            RT_actual_load.M(11+(periods)*11,2));    %Zone F
        GHI_2016_net_load = (RT_actual_load.M(3 +(periods)*11,2)+... %Zone G
                            RT_actual_load.M(5 +(periods)*11,2)+... %Zone H
                            RT_actual_load.M(8 +(periods)*11,2));    %Zone I 
        NYC_2016_net_load = (RT_actual_load.M(9 +(periods)*11,2));    %Zone J
        LIs_2016_net_load = (RT_actual_load.M(6 +(periods)*11,2));    %Zone K
    %% Calculate Regional Load Only 
    %Given: Incremental BTM Generation
        BTM = xlsread('rtd_profiles.xlsx',ren_tab_array(d),'C18:KD28');
        A2F_BTM_inc_gen = sum(BTM(1:6,:));
        GHI_BTM_inc_gen = sum(BTM(7:9,:));
        NYC_BTM_inc_gen = BTM(10,:);
        LIs_BTM_inc_gen = BTM(11,:);
    %Given: Incremental BTM Capacity
        A2F_BTM_inc_cap = 1358;
        GHI_BTM_inc_cap =  793;
        NYC_BTM_inc_cap =  419;
        LIs_BTM_inc_cap = 1069;   
    %Given: 2016 BTM Capacity
        A2F_BTM_2016_cap =  266;
        GHI_BTM_2016_cap =  155;
        NYC_BTM_2016_cap =   82;
        LIs_BTM_2016_cap =  209;   
    %Calculate: Load Only
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
        A2F_BTM_CASE_cap = 1358*Case;
        GHI_BTM_CASE_cap =  793*Case;   
        NYC_BTM_CASE_cap =  419*Case;    
        LIs_BTM_CASE_cap = 1069*Case;
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
    %% DETERMINE NUMBER OF PERIODS
        most_period_count = 288;
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
            most_period_count_DAM = 24;
            most_busload_DAM = zeros(most_period_count_DAM,52);
            int_start_DAM = 1;
            int_stop_DAM = most_period_count_DAM;
            for int_DAM = int_start_DAM: int_stop_DAM
                if useinstant == 1
                    most_busload_DAM(int_DAM,:) = most_busload(int_DAM*12-11,:);
                else
                    most_busload_DAM(int_DAM,:) = mean(most_busload(int_DAM*12-11:int_DAM*12,:));
                end
            end
%         %reduce by 10% to account for underbidding of load
%             most_busload_DAM = most_busload_DAM.*1;
%% ITM Renewable Generation
    %Gather ITM Generation for INCREMENTAL generation capacity
        wind  = xlsread('rtd_profiles.xlsx',ren_tab_array(d),'C34:KD44');
        hydro = xlsread('rtd_profiles.xlsx',ren_tab_array(d),'C49:KD59');
        PV = xlsread('rtd_profiles.xlsx',ren_tab_array(d),'C64:KD74');
        Bio = xlsread('rtd_profiles.xlsx',ren_tab_array(d),'C79:KD89');
        LFG   = xlsread('rtd_profiles.xlsx',ren_tab_array(d),'C94:KD104');
    %% Calculate output per single MW
        %WIND
            %ITM Generation for INCREMENTAL generation capacity by Zone
                A2F_INC_ITM_wind_gen = sum(wind(1:6,:));
                GHI_INC_ITM_wind_gen = sum(wind(7:9,:));
                NYC_INC_ITM_wind_gen =     wind(10,:);
                LIs_INC_ITM_wind_gen =     wind(11,:);
            %Amount of ITM INCREMENTAL Wind Generation Capacity by Zone
                A2F_ITM_inc_wind_cap  = 4189;
                GHI_ITM_inc_wind_cap  =    0;
                NYC_ITM_inc_wind_cap  =  408;
                LIs_ITM_inc_wind_cap  =  591;   
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
            %Amount of ITM INCREMENTAL hydro Generation Capacity by Zone
                A2F_ITM_CASE_hydro_cap =  542;
                GHI_ITM_CASE_hydro_cap =   45;
                NYC_ITM_CASE_hydro_cap =    0;
                LIs_ITM_CASE_hydro_cap =    0;   
            %Amount of ITM Hydro Generation per MW of ICAP by Zone
                A2F_ITM_hydro_gen_per_iCAP_MW  = A2F_INC_ITM_hydro_gen./A2F_ITM_CASE_hydro_cap;
                GHI_ITM_hydro_gen_per_iCAP_MW  = GHI_INC_ITM_hydro_gen./GHI_ITM_CASE_hydro_cap;
                NYC_ITM_hydro_gen_per_iCAP_MW  = NYC_INC_ITM_hydro_gen./NYC_ITM_CASE_hydro_cap;
                LIs_ITM_hydro_gen_per_iCAP_MW  = LIs_INC_ITM_hydro_gen./LIs_ITM_CASE_hydro_cap;
                    %Remove NaN's
                        A2F_ITM_hydro_gen_per_iCAP_MW(isnan(A2F_ITM_hydro_gen_per_iCAP_MW))=0;
                        GHI_ITM_hydro_gen_per_iCAP_MW(isnan(GHI_ITM_hydro_gen_per_iCAP_MW))=0;
                        NYC_ITM_hydro_gen_per_iCAP_MW(isnan(NYC_ITM_hydro_gen_per_iCAP_MW))=0;
                        LIs_ITM_hydro_gen_per_iCAP_MW(isnan(LIs_ITM_hydro_gen_per_iCAP_MW))=0;
        %PV
            %ITM Generation for INCREMENTAL generation capacity by Zone
                A2F_INC_ITM_PV_gen = sum(PV(1:6,:));
                GHI_INC_ITM_PV_gen = sum(PV(7:9,:));
                NYC_INC_ITM_PV_gen =     PV(10,:);
                LIs_INC_ITM_PV_gen =     PV(11,:);
            %Amount of ITM INCREMENTAL PV Generation Capacity by Zone
                A2F_ITM_CASE_PV_cap = 3044;
                GHI_ITM_CASE_PV_cap =  438;
                NYC_ITM_CASE_PV_cap =    0;
                LIs_ITM_CASE_PV_cap =  373;   
            %Amount of ITM PV Generation per MW of ICAP by Zone
                A2F_ITM_PV_gen_per_iCAP_MW  = A2F_INC_ITM_PV_gen./A2F_ITM_CASE_PV_cap;
                GHI_ITM_PV_gen_per_iCAP_MW  = GHI_INC_ITM_PV_gen./GHI_ITM_CASE_PV_cap;
                NYC_ITM_PV_gen_per_iCAP_MW  = NYC_INC_ITM_PV_gen./NYC_ITM_CASE_PV_cap;
                LIs_ITM_PV_gen_per_iCAP_MW  = LIs_INC_ITM_PV_gen./LIs_ITM_CASE_PV_cap;
                    %Remove NaN's
                        A2F_ITM_PV_gen_per_iCAP_MW(isnan(A2F_ITM_PV_gen_per_iCAP_MW))=0;
                        GHI_ITM_PV_gen_per_iCAP_MW(isnan(GHI_ITM_PV_gen_per_iCAP_MW))=0;
                        NYC_ITM_PV_gen_per_iCAP_MW(isnan(NYC_ITM_PV_gen_per_iCAP_MW))=0;
                        LIs_ITM_PV_gen_per_iCAP_MW(isnan(LIs_ITM_PV_gen_per_iCAP_MW))=0;
        %Bio Mass 
            %ITM Generation for INCREMENTAL generation capacity by Zone
                A2F_INC_ITM_Bio_gen = sum(Bio(1:6,:));
                GHI_INC_ITM_Bio_gen = sum(Bio(7:9,:));
                NYC_INC_ITM_Bio_gen =     Bio(10,:);
                LIs_INC_ITM_Bio_gen =     Bio(11,:);
            %Amount of ITM INCREMENTAL Bio Generation Capacity by Zone
                A2F_ITM_CASE_Bio_cap =  122;
                GHI_ITM_CASE_Bio_cap =    0;
                NYC_ITM_CASE_Bio_cap =    0;
                LIs_ITM_CASE_Bio_cap =    0;   
            %Amount of ITM Bio Generation per MW of ICAP by Zone
                A2F_ITM_Bio_gen_per_iCAP_MW  = A2F_INC_ITM_Bio_gen./A2F_ITM_CASE_Bio_cap;
                GHI_ITM_Bio_gen_per_iCAP_MW  = GHI_INC_ITM_Bio_gen./GHI_ITM_CASE_Bio_cap;
                NYC_ITM_Bio_gen_per_iCAP_MW  = NYC_INC_ITM_Bio_gen./NYC_ITM_CASE_Bio_cap;
                LIs_ITM_Bio_gen_per_iCAP_MW  = LIs_INC_ITM_Bio_gen./LIs_ITM_CASE_Bio_cap;
                    %Remove NaN's
                        A2F_ITM_Bio_gen_per_iCAP_MW(isnan(A2F_ITM_Bio_gen_per_iCAP_MW))=0;
                        GHI_ITM_Bio_gen_per_iCAP_MW(isnan(GHI_ITM_Bio_gen_per_iCAP_MW))=0;
                        NYC_ITM_Bio_gen_per_iCAP_MW(isnan(NYC_ITM_Bio_gen_per_iCAP_MW))=0;
                        LIs_ITM_Bio_gen_per_iCAP_MW(isnan(LIs_ITM_Bio_gen_per_iCAP_MW))=0;
        %LFG
            %ITM Generation for INCREMENTAL generation capacity by Zone
                A2F_INC_ITM_LFG_gen = sum(LFG(1:6,:));
                GHI_INC_ITM_LFG_gen = sum(LFG(7:9,:));
                NYC_INC_ITM_LFG_gen =     LFG(10,:);
                LIs_INC_ITM_LFG_gen =     LFG(11,:);
            %Amount of ITM INCREMENTAL LFG Generation Capacity by Zone
                A2F_ITM_inc_LFG_cap =   13;
                GHI_ITM_inc_LFG_cap =    3;
                NYC_ITM_inc_LFG_cap =   34;
                LIs_ITM_inc_LFG_cap =    3;   
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
        %% Calculate ITM Capacity under current Case
            A2F_ITM_CASE_wind_cap  = Case*4189;
            GHI_ITM_CASE_wind_cap  = Case*   0;
            NYC_ITM_CASE_wind_cap  = Case* 408;
            LIs_ITM_CASE_wind_cap  = Case* 591;

            A2F_ITM_CASE_hydro_cap = Case* 542;
            GHI_ITM_CASE_hydro_cap = Case*  45;
            NYC_ITM_CASE_hydro_cap = Case*   0;
            LIs_ITM_CASE_hydro_cap = Case*   0;  

            A2F_ITM_CASE_PV_cap    = Case*3044;
            GHI_ITM_CASE_PV_cap    = Case* 438;
            NYC_ITM_CASE_PV_cap    = Case*   0;
            LIs_ITM_CASE_PV_cap    = Case* 373; 

            A2F_ITM_CASE_Bio_cap   = Case* 122;
            GHI_ITM_CASE_Bio_cap   = Case*   0;
            NYC_ITM_CASE_Bio_cap   = Case*   0;
            LIs_ITM_CASE_Bio_cap   = Case*   0;

            A2F_ITM_CASE_LFG_cap   = Case*  13;
            GHI_ITM_CASE_LFG_cap   = Case*   3;
            NYC_ITM_CASE_LFG_cap   = Case*  34;
            LIs_ITM_CASE_LFG_cap   = Case*   3;      
            %% Calculate ITM Output profile under current Case 
            A2F_ITM_CASE_windy_Gen = A2F_ITM_wind_gen_per_iCAP_MW  .*A2F_ITM_CASE_wind_cap;
            A2F_ITM_CASE_hydro_Gen = A2F_ITM_hydro_gen_per_iCAP_MW .*A2F_ITM_CASE_hydro_cap;
            A2F_ITM_CASE_other_Gen = A2F_ITM_PV_gen_per_iCAP_MW    .*A2F_ITM_CASE_PV_cap + ...
                                     A2F_ITM_Bio_gen_per_iCAP_MW   .*A2F_ITM_CASE_Bio_cap + ...
                                     A2F_ITM_LFG_gen_per_iCAP_MW   .*A2F_ITM_CASE_LFG_cap;  
            A2F_ITM_CASE_Gen = A2F_ITM_CASE_windy_Gen + A2F_ITM_CASE_hydro_Gen + A2F_ITM_CASE_other_Gen;

            GHI_ITM_CASE_windy_Gen = GHI_ITM_wind_gen_per_iCAP_MW  .*GHI_ITM_CASE_wind_cap;
            GHI_ITM_CASE_hydro_Gen = GHI_ITM_hydro_gen_per_iCAP_MW .*GHI_ITM_CASE_hydro_cap;
            GHI_ITM_CASE_other_Gen = GHI_ITM_PV_gen_per_iCAP_MW    .*GHI_ITM_CASE_PV_cap + ...
                                     GHI_ITM_Bio_gen_per_iCAP_MW   .*GHI_ITM_CASE_Bio_cap + ...
                                     GHI_ITM_LFG_gen_per_iCAP_MW   .*GHI_ITM_CASE_LFG_cap;  
            GHI_ITM_CASE_Gen = GHI_ITM_CASE_windy_Gen + GHI_ITM_CASE_hydro_Gen + GHI_ITM_CASE_other_Gen;
            
            NYC_ITM_CASE_windy_Gen = NYC_ITM_wind_gen_per_iCAP_MW  .*NYC_ITM_CASE_wind_cap;
            NYC_ITM_CASE_hydro_Gen = NYC_ITM_hydro_gen_per_iCAP_MW .*NYC_ITM_CASE_hydro_cap;
            NYC_ITM_CASE_other_Gen = NYC_ITM_PV_gen_per_iCAP_MW    .*NYC_ITM_CASE_PV_cap + ...
                                     NYC_ITM_Bio_gen_per_iCAP_MW   .*NYC_ITM_CASE_Bio_cap + ...
                                     NYC_ITM_LFG_gen_per_iCAP_MW   .*NYC_ITM_CASE_LFG_cap;  
            NYC_ITM_CASE_Gen = NYC_ITM_CASE_windy_Gen + NYC_ITM_CASE_hydro_Gen + NYC_ITM_CASE_other_Gen;

            LIs_ITM_CASE_windy_Gen = LIs_ITM_wind_gen_per_iCAP_MW  .*LIs_ITM_CASE_wind_cap;
            LIs_ITM_CASE_hydro_Gen = LIs_ITM_hydro_gen_per_iCAP_MW .*LIs_ITM_CASE_hydro_cap;
            LIs_ITM_CASE_other_Gen = LIs_ITM_PV_gen_per_iCAP_MW    .*LIs_ITM_CASE_PV_cap + ...
                                     LIs_ITM_Bio_gen_per_iCAP_MW   .*LIs_ITM_CASE_Bio_cap + ...
                                     LIs_ITM_LFG_gen_per_iCAP_MW   .*LIs_ITM_CASE_LFG_cap;  
            LIs_ITM_CASE_Gen = LIs_ITM_CASE_windy_Gen + LIs_ITM_CASE_hydro_Gen + LIs_ITM_CASE_other_Gen;

            Tot_ITM_CASE_Gen = A2F_ITM_CASE_Gen + GHI_ITM_CASE_Gen + NYC_ITM_CASE_Gen + LIs_ITM_CASE_Gen;
%% 2016 Generation
        %Existing renewable capacity in A2F (other locations ignored due  to low penetration
            A2F_2016_ITM_wind_ICAP  = 1755;
            A2F_2016_ITM_hydro_ICAP = 5219;
            A2F_2016_ITM_PV_ICAP    =    0;
            A2F_2016_ITM_Bio_ICAP   =  148;
            A2F_2016_ITM_LFG_ICAP   =  126;
        %Calculate output for existing A2F renewables
            A2F_2016_ITM_windy_Gen = A2F_ITM_wind_gen_per_iCAP_MW  .*A2F_2016_ITM_wind_ICAP;
            A2F_2016_ITM_hydro_Gen = A2F_ITM_hydro_gen_per_iCAP_MW .*A2F_2016_ITM_hydro_ICAP;
            A2F_2016_ITM_other_Gen = A2F_ITM_PV_gen_per_iCAP_MW    .*A2F_2016_ITM_PV_ICAP + ...
                                     A2F_ITM_Bio_gen_per_iCAP_MW   .*A2F_2016_ITM_Bio_ICAP + ...
                                     A2F_ITM_LFG_gen_per_iCAP_MW   .*A2F_2016_ITM_LFG_ICAP;
            A2F_2016_ITM_Gen = A2F_2016_ITM_windy_Gen + A2F_2016_ITM_hydro_Gen + A2F_2016_ITM_other_Gen;
    %% Gen Capacity by region for the current case
        %All gen by region
            A2F_all_CASE_gencap = A2F_2016_ITM_wind_ICAP + A2F_2016_ITM_hydro_ICAP + A2F_2016_ITM_PV_ICAP+ A2F_2016_ITM_Bio_ICAP + A2F_2016_ITM_LFG_ICAP + ...
                                  A2F_ITM_CASE_wind_cap + A2F_ITM_CASE_hydro_cap + A2F_ITM_CASE_PV_cap+ A2F_ITM_CASE_Bio_cap + A2F_ITM_CASE_LFG_cap;
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
            A2F_ITM_other_gen_tot = A2F_ITM_CASE_other_Gen + A2F_2016_ITM_other_Gen;
            A2F_ITM_gen_tot = A2F_ITM_windy_gen_tot + A2F_ITM_hydro_gen_tot + A2F_ITM_other_gen_tot;

            GHI_ITM_windy_gen_tot = GHI_ITM_CASE_windy_Gen;
            GHI_ITM_hydro_gen_tot = GHI_ITM_CASE_hydro_Gen;
            GHI_ITM_other_gen_tot = GHI_ITM_CASE_other_Gen;
            GHI_ITM_gen_tot = GHI_ITM_windy_gen_tot + GHI_ITM_hydro_gen_tot + GHI_ITM_other_gen_tot;
            
            NYC_ITM_windy_gen_tot = NYC_ITM_CASE_windy_Gen;
            NYC_ITM_hydro_gen_tot = NYC_ITM_CASE_hydro_Gen;
            NYC_ITM_other_gen_tot = NYC_ITM_CASE_other_Gen;
            NYC_ITM_gen_tot = NYC_ITM_windy_gen_tot + NYC_ITM_hydro_gen_tot + NYC_ITM_other_gen_tot;
            
            LIs_ITM_windy_gen_tot = LIs_ITM_CASE_windy_Gen;
            LIs_ITM_hydro_gen_tot = LIs_ITM_CASE_hydro_Gen;
            LIs_ITM_other_gen_tot = LIs_ITM_CASE_other_Gen;
            LIs_ITM_gen_tot = LIs_ITM_windy_gen_tot + LIs_ITM_hydro_gen_tot + LIs_ITM_other_gen_tot;

        %Statewide Totals by rengen type
            TOT_ITM_windy_gen_profile = A2F_ITM_windy_gen_tot + GHI_ITM_windy_gen_tot + NYC_ITM_windy_gen_tot + LIs_ITM_windy_gen_tot;
            TOT_ITM_hydro_gen_profile = A2F_ITM_hydro_gen_tot + GHI_ITM_hydro_gen_tot + NYC_ITM_hydro_gen_tot + LIs_ITM_hydro_gen_tot;
            TOT_ITM_other_gen_profile = A2F_ITM_other_gen_tot + GHI_ITM_other_gen_tot + NYC_ITM_other_gen_tot + LIs_ITM_other_gen_tot;
    %% First vs. Avg Ren values
        %get 24 hr profile for all renewables together
            TOT_ITM_profile = TOT_ITM_windy_gen_profile + TOT_ITM_hydro_gen_profile + TOT_ITM_other_gen_profile;
        %find first of the hour values
            for int = 1:24
                FirstValues(int,:) = TOT_ITM_profile(1,int*12-11);
                FirstValuesLine(int*12-11:int*12,:) = FirstValues(int,:);
            end
        %find average of the hour values
            for int = 1:24
                AverageValues(int,:) = mean(TOT_ITM_profile(1,int*12-11:int*12));
                AverageValuesLine(int*12-11:int*12,:) = AverageValues(int,:);
            end
        %create a plot
%             hFig1 = figure(1);
%             hold on
%             set(hFig1, 'Position', [450 50 900 400]) %Pixels: from left, from bottom, across, high
%             plot(Time4Graph, TOT_ITM_profile)
%             plot(Time4Graph, FirstValuesLine)
%             plot(Time4Graph, AverageValuesLine)
%             legend('Total Renewable','First Values','Average Values')
%             legend('Location','eastoutside'),
%             set(gca, 'XTick', [0 4 8 12 16 20 24]);
%             grid on
%             grid minor
%             First_Line_Title = ['First vs. Average Values of Renewable Output for: ', datestring(5:6), ' ', datestring(7:8), ' ', datestring(1:4), ' in the ',Case_Name_String];
%             ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off',...
%                 'Units','normalized', 'clipping' , 'off');
%             text(0.5, 1.0,[{'\bf \fontsize{12}' First_Line_Title}], 'HorizontalAlignment' ,...
%                 'center', 'VerticalAlignment', 'top')   
%             hold off
        % Assemble into proper format for most
        %% wind
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
                %remove empty rows
                    most_bus_rengen_windy(:,62) = [];
                    most_bus_rengen_windy(:,1:52) = [];
                %DAM Averages
                    %Take average of load values in an hour
                        most_windy_gen_DAM = zeros(most_period_count_DAM,15);
                        for int_DAM = int_start_DAM: int_stop_DAM
                            if useinstant ==1
                                most_windy_gen_DAM(int_DAM,:) = most_bus_rengen_windy(int_DAM*12-11,:);
                            else
                                most_windy_gen_DAM(int_DAM,:) = mean(most_bus_rengen_windy(int_DAM*12-11:int_DAM*12,:));
                            end
                        end
        %% hydro
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
                %remove empty rows
                    most_bus_rengen_hydro(:,62) = [];
                    most_bus_rengen_hydro(:,1:52) = [];
                %DAM Averages
                    %Take average of load values in an hour
                        most_hydro_gen_DAM = zeros(most_period_count_DAM,15);
                        for int_DAM = int_start_DAM: int_stop_DAM
                            if useinstant ==1
                                most_hydro_gen_DAM(int_DAM,:) = most_bus_rengen_hydro(int_DAM*12-11,:);
                            else
                                most_hydro_gen_DAM(int_DAM,:) = mean(most_bus_rengen_hydro(int_DAM*12-11:int_DAM*12,:));
                            end
                        end
        %% other
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
                %remove empty rows
                    most_bus_rengen_other(:,62) = [];
                    most_bus_rengen_other(:,1:52) = [];
                %DAM Averages
                    %Take average of load values in an hour
                        most_other_gen_DAM = zeros(most_period_count_DAM,15);
                        for int_DAM = int_start_DAM: int_stop_DAM
                            if useinstant ==1
                                most_other_gen_DAM(int_DAM,:) = most_bus_rengen_other(int_DAM*12-11,:);
                            else
                                most_other_gen_DAM(int_DAM,:) = mean(most_bus_rengen_other(int_DAM*12-11:int_DAM*12,:));
                            end
                        end

        %Determine amount of thermal gen needed
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
        %% Load Statistics
            NYCA_TrueLoad_AVG_24hr = mean(NYCA_TrueLoad_DAM);
            NYCA_TrueLoad_AVG_4hr = mean(NYCA_TrueLoad_DAM(10:14));
            NYCA_NetLoad_AVG_24hr = mean(NYCA_CASE_net_load_DAM);
            NYCA_NetLoad_AVG_4hr = mean(NYCA_CASE_net_load_DAM(10:14));
            
%% Most DAM Run
    %Add variable names 
        define_constants
    %Define initial data
        casefile = 'case_nyiso16';
        mpc = loadcase(casefile);
        xgd = loadxgendata('xgd_DAM' , mpc);
    %determine number of thermal gens
        [therm_gen_count,~] =  size(mpc.gen(:,9));
%     %Reduce RAMP!
%         if IncreasedDAMramp == 1
%             for col = 17:19
%                 mpc.gen(4:11,col) = mpc.gen(4:11,col).*DAMrampFactor;
%             end
%         end
%     %Retire a Nuke Unit? 
%         for gen = 2:killNuke
%             xgd.CommitKey(gen) = -1;
%         end
    %% Add Renewables
        %WIND
            %Add wind Generators
                [iwind, mpc, xgd] = addwind('wind_gen' , mpc, xgd);
            %Add empty max & min profiles
                profiles = getprofiles('wind_profile_Pmax' , iwind); 
                profiles = getprofiles('wind_profile_Pmin' , profiles);
        %HYDRO
            %Add hydro Generators
                [ihydro, mpc, xgd] = addwind('hydro_gen' , mpc, xgd);
            %Add empty max & min profiles
                profiles = getprofiles('hydro_profile_Pmax' , profiles); 
                profiles = getprofiles('hydro_profile_Pmin' , profiles);
        %OTHER
            %Add other Generators
                [iother, mpc, xgd] = addwind('other_gen' , mpc, xgd);
            %Add empty max & min profiles
                profiles = getprofiles('other_profile_Pmax' , profiles); 
                profiles = getprofiles('other_profile_Pmin' , profiles);
    %% Add load profile
                    profiles = getprofiles('load_profile' , profiles);
    %% Add Ren Gen Profiles
        %WIND
            %Max Gen
                profiles(1).values(:,1,:) = most_windy_gen_DAM;
            %Min Gen
                if windyCurt == 1
                    profiles(2).values(:,1,:) = most_windy_gen_DAM.*windyCurtFactor;
                else
                    profiles(2).values(:,1,:) = most_windy_gen_DAM;
                end
        %HYDRO
            %Max Gen
                profiles(3).values(:,1,:) = most_hydro_gen_DAM;
            %Min Gen
                if hydroCurt == 1
                    profiles(4).values(:,1,:) = most_hydro_gen_DAM.*hydroCurtFactor;
                else
                    profiles(4).values(:,1,:) = most_hydro_gen_DAM;
                end
        %OTHER
            %Max Gen
                profiles(5).values(:,1,:) = most_other_gen_DAM;
            %Min Gen
                if otherCurt == 1
                    profiles(6).values(:,1,:) = most_other_gen_DAM.*otherCurtFactor;
                else
                    profiles(6).values(:,1,:) = most_other_gen_DAM;
                end
    %% Add Load Profile
                profiles(7).values(:,1,:) = most_busload_DAM;
    %% Add EVSE Load
    if EVSE == 1
        %% Get EVSE Load Data (MWh total for the Day)
            %Electric Vehicle Energy Usage Forecast (2018 Gold Book) in GWh
                                %A   B   C   D   E   F   G   H   I   J   K
                EVSE_Gold_MWh = [3   5   4   0   2   5   6   3   5   13  23;     %2016
                                154 183 180 12  99  206 230 100 150 520 781;]./365.*EVSEfactor;   %2030
                        
            %Total Increase in Coincident Winter Peak Demand by Zone in MW (Use winter as its worse than summer)
                                %A   B   C   D   E   F   G   H   I   J   K
                EVSE_Gold_MW  = [1   1   1   0   1   1   2   1   1   4   7;       %2016
                                30 36  35  2   19  40  45  20  29  101 153;].*EVSEfactor;    %2030
        %% Calculate EVSE MWh load at each bus
            %Pick load for the current Case & convert to MWh
                EVSE_Zone = EVSE_Gold_MWh(Case+1,:).*1000; %convert from GWh to MWh
            %Group by Region
                EVSE_Region = [sum(EVSE_Zone(1:6)) sum(EVSE_Zone(7:9)) EVSE_Zone(10) EVSE_Zone(11) 0];
            %Divide by # of load buses in each region = EVSE MWh to add to each load bus in each region [A2F, GHI, NYC, LIs]
                EVSE_Region_Ind = EVSE_Region./[A2F_load_bus_count GHI_load_bus_count NYC_load_bus_count LIs_load_bus_count 1];
        %% Calculate EVSE MW peak at each bus
            %Determine Max EVSE Load in each region
                EVSE_Region_MW = [sum(EVSE_Gold_MW(Case+1,1:6)) sum(EVSE_Gold_MW(Case+1,7:9)) EVSE_Gold_MW(Case+1,10) EVSE_Gold_MW(Case+1,11) 0];
                EVSE_Region_Ind_MW = EVSE_Region_MW./[A2F_load_bus_count GHI_load_bus_count NYC_load_bus_count LIs_load_bus_count 1];
        %% Add Batteries to each Load Bus
            %% How Many Batteries we adding here? 
                BatCount = A2F_load_bus_count+GHI_load_bus_count+NYC_load_bus_count+LIs_load_bus_count;
            %% Initialize
                %Tables
                    storage.gen             = zeros(BatCount,21);
                    storage.sd_table.data   = zeros(BatCount,13);
                    storage.xgd_table.data  = zeros(BatCount,2);
                    storage.gencost         = zeros(BatCount, 7);
                    EVSE_PminProfile = zeros(32,1);
%                     storage.ExpectedTerminalStorageAim = zeros(BatCount,1);
%                     storage.InitialStorage  = zeros(BatCount,1);
%                     storage.InitialStorageCost  = zeros(BatCount,1);
%                     storage.InitialStorageLowerBound  = zeros(BatCount,1);
%                     storage.InitialStorageUpperBound  = zeros(BatCount,1);
%                     storage.TerminalStorageUpperBound  = zeros(BatCount,1);
                %StorageData Parameters
                    storage.sd_table.OutEff				= 1;
                    storage.sd_table.InEff				= 1;
                    storage.sd_table.LossFactor			= 0;
                    storage.sd_table.rho				= 0;
                    storage.sd_table.colnames = {
                        'InitialStorage', ...
                            'InitialStorageLowerBound', ...
                                'InitialStorageUpperBound', ...
                                    'InitialStorageCost', ...
                                        'TerminalStoragePrice', ...
                                            'MinStorageLevel', ...
                                                'MaxStorageLevel', ...
                                                    'OutEff', ...
                                                        'InEff', ...
                                                            'LossFactor', ...
                                                                'rho', ...
                                                                    'ExpectedTerminalStorageMin',...
                                                                        'ExpectedTerminalStorageMax',...
                    };
                    storage.xgd_table.colnames = {
                        'CommitKey', ...
                            'CommitSched', ...
                            };    
%                             'PositiveActiveReservePrice', ...
%                                     'PositiveActiveReserveQuantity', ...
%                                         'NegativeActiveReservePrice', ...
%                                             'NegativeActiveReserveQuantity', ...
%                                                 'PositiveActiveDeltaPrice', ...
%                                                     'NegativeActiveDeltaPrice', ...
%                                                         'PositiveLoadFollowReservePrice', ...
%                                                             'PositiveLoadFollowReserveQuantity', ...
%                                                                 'NegativeLoadFollowReservePrice', ...
%                                                                     'NegativeLoadFollowReserveQuantity', ...
            %% Create Battery Data Containers     
                for Bat = 1:BatCount
                    %% Which Region are we in?
                        if sum(ismember(NYCA_Load_buses(Bat),A2F_Load_buses)) > 0
                            Region = 1; %Region 1 is A2F
                        else
                            if sum(ismember(NYCA_Load_buses(Bat),GHI_Load_buses)) >0
                                Region = 2; %Region 2 is GHI
                            else
                                if sum(ismember(NYCA_Load_buses(Bat),NYC_Load_buses)) >0
                                    Region = 3; %Region 3 is NYC
                                else
                                    if sum(ismember(NYCA_Load_buses(Bat),LIs_Load_buses)) >0
                                        Region = 4; %Region 4 is Long Island
                                    else
                                        Region = 5;
                                    end
                                end
                            end
                        end
                    %% Add individual battery parameters
                                           % bus            Qmin    mBase   Pmax    Pc1     Qc1min	Qc2min	ramp_agc	ramp_q
                                           % 	Pg	Qg	Qmax	Vg      status	Pmin	Pc2     Qc1max	Qc2max	ramp_10     apf
                                           %                                                                        ramp_30	
                       storage.gen(Bat,:) = [NYCA_Load_buses(Bat)...
                                                0   0   0   0   1   100 1   -0.00001   -EVSE_Region_Ind_MW(Region)...
                                                                                    0   0   0   0   0   0   0   0   EVSE_Region_Ind_MW(Region)   0   0];
                    %% Record Pmin Data
                        EVSE_PminProfile(Bat) = -EVSE_Region_Ind_MW(Region);
                    %% Add storage data
                                                        %1 InitialStorage
                                                            %2 InitialStorageLowerBound
                                                                %3 InitialStorageUpperBound
                                                                    %4 InitialStorageCost
                                                                        %5 TerminalStoragePrice
                                                                            %6 MinStorageLevel
                                                                                %7 MaxStorageLevel
                                                                                    %8 OutEff
                                                                                        %9 InEff
                                                                                            %10 LossFactor
                                                                                                %11 rho
                                                                                                    %12 Expected Terminal Storage Min
                                                                                                    %13 Expected Terminal Storage Max
                                                        %1   2   3   4   5   6   7   8   9   10  11  12                         13
                       storage.sd_table.data(Bat,:) =   [0   0   0   0   0   0   EVSE_Region_Ind(Region),...
                                                                                     1   1   0   0   EVSE_Region_Ind(Region) EVSE_Region_Ind(Region)];
                    %% Add storage XGD data
                                                        %1 CommitKey
                                                            %2 CommitSched
                                                                %3 PositiveActiveReservePrice
                                                                    %4 PositiveActiveReserveQuantity
                                                                        %5 NegativeActiveReservePrice
                                                                            %6 NegativeActiveReserveQuantity
                                                                                %7 PositiveActiveDeltaPrice
                                                                                    %8 NegativeActiveDeltaPrice
                                                                                        %9 PositiveLoadFollowReservePrice
                                                                                            %10 PositiveLoadFollowReserveQuantity
                                                                                                %11 NegativeLoadFollowReservePrice
                                                                                                    %12 NegativeLoadFollowReserveQuantity
                                                        %1   2   3   4   5   6   7   8   9   10  11  12
                       storage.xgd_table.data(Bat,:) = [2    1  ];% 0   0   0   0   0   0   0   0   0   0];
                    %% Add storage cost data
                                         %2	startup	n	c(n-1)	...	c0
                                         %      shutdown
%                         storage.gencost(Bat,:) = [2	0	0	3	0.01 10 100]; 
                        storage.gencost(Bat,:) = [2	0	0	2	0   0   0]; 
                end
            %% Push Battery Data to MOST
                [~,mpc,xgd,storage] = addstorage(storage,mpc,xgd);
    end
    %% Set Initial Pg for renewable gens
            xgd.InitialPg(15:29) = xgd.InitialPg(15:29) + most_windy_gen_DAM(1,1:15).';
            xgd.InitialPg(30:44) = xgd.InitialPg(30:44) + most_hydro_gen_DAM(1,1:15).';
            xgd.InitialPg(45:59) = xgd.InitialPg(45:59) + most_other_gen_DAM(1,1:15).';
            xgd.InitialPg(15:59) = xgd.InitialPg(15:59) -1;
    %% Set $-5/MWh renewable cost to avoid curtailment
            mpc.gencost(15:29,6) = REC_Cost;
            mpc.gencost(30:44,6) = REC_hydro;
            mpc.gencost(45:59,6) = REC_Cost;
            mpc.gencost(15:59,4) = 3;
    %% Update generator capacity
        %determine number of renewable gens
            [all_gen_count,~] = size(mpc.gen(:,9));
            ren_gen_count = all_gen_count - therm_gen_count - 32;
        %determine size of renewable gen in each region
            A2F_ind = A2F_all_CASE_gencap/A2F_gen_bus_count;
            GHI_ind = GHI_all_CASE_gencap/GHI_gen_bus_count;
            NYC_ind = NYC_all_CASE_gencap/NYC_gen_bus_count;
            LIs_ind = LIs_all_CASE_gencap/LIs_gen_bus_count;
        %create vector with gen cap in order
            ordered_gen_cap = zeros(ren_gen_count);
            for gen = therm_gen_count+1:all_gen_count
                buss = mpc.gen(gen,1);
                if ismember(buss,A2F_Gen_buses)
                    ordered_gen_cap(gen-therm_gen_count) = A2F_ind;
                else 
                    if ismember(buss,GHI_Gen_buses)
                        ordered_gen_cap(gen-therm_gen_count) = GHI_ind;
                    else 
                        if ismember(buss,NYC_Gen_buses)
                            ordered_gen_cap(gen-therm_gen_count) = NYC_ind;
                        else
                            if ismember(buss,LIs_Gen_buses)
                                ordered_gen_cap(gen-therm_gen_count) = LIs_ind;
                            end
                        end
                    end
                end
            end 

        %update renewable capacity
            for ss = 1:ren_gen_count
                mpc.gen(ss+therm_gen_count,9) = ordered_gen_cap(ss);
            end
    %Determine number of intervals in the simulation
        nt = most_period_count_DAM; % number of period
    %% Add transmission interface limits
        if IFlims == 1
            mpc.if.map = map_Array;
            mpc.if.lims  = lims_Array;
            mpc = toggle_iflims_most(mpc, 'on');
        end
    %% Add EVSE Profile
% % %         EVSE_PminProfile_DAM = zeros(24,32);
% % %         for hour = 1:24
% % %             EVSE_PminProfile_DAM(hour,:) = EVSE_PminProfile;
% % %         end
% % %         profiles(8).values(:,1,:) = EVSE_PminProfile_DAM;
%% Run Algorithm
        %Set options
            mpopt = mpoption;
            mpopt = mpoption(mpopt,'most.dc_model', 1); % use DC network model (default)
%             mpopt = mpoption(mpopt,'model','DC');
            mpopt = mpoption(mpopt,'most.solver', 'GUROBI');
            mpopt = mpoption(mpopt, 'verbose', 0);
            mpopt = mpoption(mpopt,'most.skip_prices', 0);
        %Load all data
            clear mdi
        %Set Ramp Costs = 0
            if EVSE == 1
                numm = 91;
                mdi = loadmd(mpc, nt, xgd, storage, [], profiles);
            else
                numm = 59;
                mdi = loadmd(mpc, nt, xgd, [], [], profiles);
            end
                mdi.RampWearCostCoeff = zeros(numm,24);

            for tt = 1:24
                mdi.offer(tt).PositiveActiveReservePrice = zeros(numm,1);
                mdi.offer(tt).NegativeActiveReservePrice = zeros(numm,1);
                mdi.offer(tt).PositiveActiveDeltaPrice = zeros(numm,1);
                mdi.offer(tt).NegativeActiveDeltaPrice = zeros(numm,1);
                mdi.offer(tt).PositiveLoadFollowReservePrice = zeros(numm,1);
                mdi.offer(tt).NegativeLoadFollowReservePrice = zeros(numm,1);
            end
        %Run the UC/ED algorithm
            clear mdo
            if IFlims == 1
                mdo = most_if(mdi, mpopt);
            else
                mdo = most(mdi, mpopt);
            end
        %View Results
            ms = most_summary(mdo); % print results, depending on verbose  option
           
%% Analyze DAM Results
        %Initialize Summary
            Summaryy = zeros(59,8);
    %% Gen Output in percent prep
        gen_output = ms.Pg;
        gen_capacity = mpc.gen(:,9);

        for gen = 1:length(gen_capacity)
            gen_output_percent(gen,:) = gen_output(gen,:)./gen_capacity(gen);
        end

        gen_output_percent(isnan(gen_output_percent)) = 0;
    %Modify % output to show offline/online units
        for gen = 1:therm_gen_count
            for time = 1:24
                %offline
                if gen_output_percent(gen,time) == 0
                    gen_output_percent(gen,time) = -gen*.01;
                else
                    %at max
                    if gen_output_percent(gen,time) == 1
                        gen_output_percent(gen,time) = 1+gen*.01;
%                         else
%                             %in between... Do nothing
                    end
                end
            end
        end
    %% Gen Output by Unit
        for hour = 1:24
            Nuke_1_DAM(hour) = ms.Pg(1,hour);
            Nuke_2_DAM(hour) = ms.Pg(2,hour);
            Nuke_3_DAM(hour) = ms.Pg(3,hour);
            Steam_1_DAM(hour) = ms.Pg(4,hour);
            Steam_2_DAM(hour) = ms.Pg(5,hour);
            Steam_3_DAM(hour) = ms.Pg(6,hour);
            Steam_4_DAM(hour) = ms.Pg(7,hour);
            Steam_5_DAM(hour) = ms.Pg(8,hour);
            NEimport_DAM(hour) = ms.Pg(9,hour);
            CCGen_1_DAM(hour) = ms.Pg(10,hour);
            CCGen_2_DAM(hour) = ms.Pg(11,hour);
            GTGen_1_DAM(hour) = ms.Pg(12,hour);
            GTGen_2_DAM(hour) = ms.Pg(13,hour);
            LOHIGen_DAM(hour) = ms.Pg(14,hour);
        end
        DAM_gen_storage = zeros(59,24);
        for hour = 1:24
            for gen = 1:59
                DAM_gen_storage(gen,hour) = ms.Pg(gen,hour);
            end
        end
    %% Gen Output by Type
        %Initialize Variables
            NukeGenDAM = zeros(1,24);
            SteamGenDAM = zeros(1,24);
            CCGenDAM = zeros(1,24);
            GTGenDAM = zeros(1,24);
            RenGen_hydroDAM = zeros(1,24);
            RenGen_windyDAM = zeros(1,24);
            RenGen_otherDAM = zeros(1,24);
            BTM4GraphDAM = zeros(1,24);
            LOHIGenDAM = zeros(1,24);
        %Calculate Generation by type 
            for iter = 1:int_stop_DAM
                NukeGenDAM(iter) = ms.Pg(1,iter)+ms.Pg(2,iter)+ms.Pg(3,iter); %NUKE
                SteamGenDAM(iter) = ms.Pg(4,iter)+ms.Pg(5,iter)+ms.Pg(6,iter)+ms.Pg(7,iter)+ms.Pg(8,iter);%STEAM
                CCGenDAM(iter) = ms.Pg(10,iter)+ms.Pg(11,iter);%CC
                GTGenDAM(iter) = ms.Pg(12,iter)+ms.Pg(13,iter);%GT
                LOHIGenDAM(iter) = ms.Pg(14,iter);
                RenGen_windyDAM(iter) = 0;
                for renge = 15:29
                    RenGen_windyDAM(iter) = RenGen_windyDAM(iter) + ms.Pg(renge,iter);
                end
                RenGen_hydroDAM(iter) = 0;
                for renge = 30:44
                    RenGen_hydroDAM(iter) = RenGen_hydroDAM(iter) + ms.Pg(renge,iter);
                end
                RenGen_otherDAM(iter) = 0;%RENEWABLE
                for renge = 45:59
                    RenGen_otherDAM(iter) = RenGen_otherDAM(iter) + ms.Pg(renge,iter);
                end
                BTM4GraphDAM(iter) = mean(NYCA_CASE_BTM_gen(iter*12-11:iter*12));
            end
    %% Gen Revenue -- OLD 24 hrs
%         Gen_DAM_Revenue = zeros(59,1);
%         for genn = 1:59
%             for DAMhr = 1:24
%                 Gen_DAM_Revenue(genn) = Gen_DAM_Revenue(genn) + ms.Pg(genn,DAMhr)*ms.lamP(mpc.gen(genn,1),DAMhr);
%             end
%         end
%         Summaryy(:,1) = Gen_DAM_Revenue;
    %% Gen Revenue -- NEW 21.5 hrs
        %% 21.5 Hour Total
        Gen_DAM_Revenue = zeros(59,1);
        for gen = 1:59
            for hour = 1:21
                Gen_DAM_Revenue(gen) = Gen_DAM_Revenue(gen) + ms.Pg(gen,hour)*ms.lamP(mpc.gen(gen,1),hour);
            end
                Gen_DAM_Revenue(gen) = Gen_DAM_Revenue(gen) + 0.5*ms.Pg(gen,22)*ms.lamP(mpc.gen(gen,1),22);
        end
        Summaryy(:,1) = Gen_DAM_Revenue;
        %% By Hour
        Gen_DAM_Revenue_hr = zeros(4,24);
            %% Upstate
        for hour = 1:21
            Gen_DAM_Revenue_hr(1,hour) = ms.Pg(25,hour)*ms.lamP(mpc.gen(25,1),hour)+...
                                         ms.Pg(26,hour)*ms.lamP(mpc.gen(26,1),hour)+...
                                         ms.Pg(27,hour)*ms.lamP(mpc.gen(27,1),hour)+...
                                         ms.Pg(28,hour)*ms.lamP(mpc.gen(28,1),hour)+...
                                         ms.Pg(29,hour)*ms.lamP(mpc.gen(29,1),hour)+...
                                         ms.Pg(40,hour)*ms.lamP(mpc.gen(40,1),hour)+...
                                         ms.Pg(41,hour)*ms.lamP(mpc.gen(41,1),hour)+...
                                         ms.Pg(42,hour)*ms.lamP(mpc.gen(42,1),hour)+...
                                         ms.Pg(43,hour)*ms.lamP(mpc.gen(43,1),hour)+...
                                         ms.Pg(44,hour)*ms.lamP(mpc.gen(44,1),hour)+...
                                         ms.Pg(55,hour)*ms.lamP(mpc.gen(55,1),hour)+...
                                         ms.Pg(56,hour)*ms.lamP(mpc.gen(56,1),hour)+...
                                         ms.Pg(57,hour)*ms.lamP(mpc.gen(57,1),hour)+...
                                         ms.Pg(58,hour)*ms.lamP(mpc.gen(58,1),hour)+...
                                         ms.Pg(59,hour)*ms.lamP(mpc.gen(59,1),hour)+...
                                         ms.Pg(1,hour)*ms.lamP(mpc.gen(1,1),hour)+...
                                         ms.Pg(4,hour)*ms.lamP(mpc.gen(4,1),hour)+...
                                         ms.Pg(5,hour)*ms.lamP(mpc.gen(5,1),hour)+...
                                         ms.Pg(10,hour)*ms.lamP(mpc.gen(10,1),hour);
        end
            hour = 22;
            Gen_DAM_Revenue_hr(1,hour) =(ms.Pg(25,hour)*ms.lamP(mpc.gen(25,1),hour)+...
                                         ms.Pg(26,hour)*ms.lamP(mpc.gen(26,1),hour)+...
                                         ms.Pg(27,hour)*ms.lamP(mpc.gen(27,1),hour)+...
                                         ms.Pg(28,hour)*ms.lamP(mpc.gen(28,1),hour)+...
                                         ms.Pg(29,hour)*ms.lamP(mpc.gen(29,1),hour)+...
                                         ms.Pg(40,hour)*ms.lamP(mpc.gen(40,1),hour)+...
                                         ms.Pg(41,hour)*ms.lamP(mpc.gen(41,1),hour)+...
                                         ms.Pg(42,hour)*ms.lamP(mpc.gen(42,1),hour)+...
                                         ms.Pg(43,hour)*ms.lamP(mpc.gen(43,1),hour)+...
                                         ms.Pg(44,hour)*ms.lamP(mpc.gen(44,1),hour)+...
                                         ms.Pg(55,hour)*ms.lamP(mpc.gen(55,1),hour)+...
                                         ms.Pg(56,hour)*ms.lamP(mpc.gen(56,1),hour)+...
                                         ms.Pg(57,hour)*ms.lamP(mpc.gen(57,1),hour)+...
                                         ms.Pg(58,hour)*ms.lamP(mpc.gen(58,1),hour)+...
                                         ms.Pg(59,hour)*ms.lamP(mpc.gen(59,1),hour)+...
                                         ms.Pg(1,hour)*ms.lamP(mpc.gen(1,1),hour)+...
                                         ms.Pg(4,hour)*ms.lamP(mpc.gen(4,1),hour)+...
                                         ms.Pg(5,hour)*ms.lamP(mpc.gen(5,1),hour)+...
                                         ms.Pg(10,hour)*ms.lamP(mpc.gen(10,1),hour))*0.5;
            %% GHI
        for hour = 1:21
            Gen_DAM_Revenue_hr(2,hour) = ms.Pg(15,hour)*ms.lamP(mpc.gen(15,1),hour)+...
                                         ms.Pg(16,hour)*ms.lamP(mpc.gen(16,1),hour)+...
                                         ms.Pg(22,hour)*ms.lamP(mpc.gen(22,1),hour)+...
                                         ms.Pg(30,hour)*ms.lamP(mpc.gen(30,1),hour)+...
                                         ms.Pg(31,hour)*ms.lamP(mpc.gen(31,1),hour)+...
                                         ms.Pg(37,hour)*ms.lamP(mpc.gen(37,1),hour)+...
                                         ms.Pg(45,hour)*ms.lamP(mpc.gen(45,1),hour)+...
                                         ms.Pg(46,hour)*ms.lamP(mpc.gen(46,1),hour)+...
                                         ms.Pg(52,hour)*ms.lamP(mpc.gen(52,1),hour)+...
                                         ms.Pg(2,hour)*ms.lamP(mpc.gen(2,1),hour)+...
                                         ms.Pg(3,hour)*ms.lamP(mpc.gen(3,1),hour)+...
                                         ms.Pg(6,hour)*ms.lamP(mpc.gen(6,1),hour);
        end
        hour = 22;
            Gen_DAM_Revenue_hr(2,hour) =(ms.Pg(15,hour)*ms.lamP(mpc.gen(15,1),hour)+...
                                         ms.Pg(16,hour)*ms.lamP(mpc.gen(16,1),hour)+...
                                         ms.Pg(22,hour)*ms.lamP(mpc.gen(22,1),hour)+...
                                         ms.Pg(30,hour)*ms.lamP(mpc.gen(30,1),hour)+...
                                         ms.Pg(31,hour)*ms.lamP(mpc.gen(31,1),hour)+...
                                         ms.Pg(37,hour)*ms.lamP(mpc.gen(37,1),hour)+...
                                         ms.Pg(45,hour)*ms.lamP(mpc.gen(45,1),hour)+...
                                         ms.Pg(46,hour)*ms.lamP(mpc.gen(46,1),hour)+...
                                         ms.Pg(52,hour)*ms.lamP(mpc.gen(52,1),hour)+...
                                         ms.Pg(2,hour)*ms.lamP(mpc.gen(2,1),hour)+...
                                         ms.Pg(3,hour)*ms.lamP(mpc.gen(3,1),hour)+...
                                         ms.Pg(6,hour)*ms.lamP(mpc.gen(6,1),hour))*0.5;
             %% NYC
        for hour = 1:21
            Gen_DAM_Revenue_hr(3,hour) = ms.Pg(17,hour)*ms.lamP(mpc.gen(17,1),hour)+...
                                         ms.Pg(18,hour)*ms.lamP(mpc.gen(18,1),hour)+...
                                         ms.Pg(19,hour)*ms.lamP(mpc.gen(19,1),hour)+...
                                         ms.Pg(32,hour)*ms.lamP(mpc.gen(32,1),hour)+...
                                         ms.Pg(33,hour)*ms.lamP(mpc.gen(33,1),hour)+...
                                         ms.Pg(34,hour)*ms.lamP(mpc.gen(34,1),hour)+...
                                         ms.Pg(47,hour)*ms.lamP(mpc.gen(47,1),hour)+...
                                         ms.Pg(48,hour)*ms.lamP(mpc.gen(48,1),hour)+...
                                         ms.Pg(49,hour)*ms.lamP(mpc.gen(49,1),hour)+...
                                         ms.Pg(7,hour)*ms.lamP(mpc.gen(7,1),hour)+...
                                         ms.Pg(11,hour)*ms.lamP(mpc.gen(11,1),hour)+...
                                         ms.Pg(12,hour)*ms.lamP(mpc.gen(12,1),hour);
        end
        hour = 22;
            Gen_DAM_Revenue_hr(3,hour) =(ms.Pg(17,hour)*ms.lamP(mpc.gen(17,1),hour)+...
                                         ms.Pg(18,hour)*ms.lamP(mpc.gen(18,1),hour)+...
                                         ms.Pg(19,hour)*ms.lamP(mpc.gen(19,1),hour)+...
                                         ms.Pg(32,hour)*ms.lamP(mpc.gen(32,1),hour)+...
                                         ms.Pg(33,hour)*ms.lamP(mpc.gen(33,1),hour)+...
                                         ms.Pg(34,hour)*ms.lamP(mpc.gen(34,1),hour)+...
                                         ms.Pg(47,hour)*ms.lamP(mpc.gen(47,1),hour)+...
                                         ms.Pg(48,hour)*ms.lamP(mpc.gen(48,1),hour)+...
                                         ms.Pg(49,hour)*ms.lamP(mpc.gen(49,1),hour)+...
                                         ms.Pg(7,hour)*ms.lamP(mpc.gen(7,1),hour)+...
                                         ms.Pg(11,hour)*ms.lamP(mpc.gen(11,1),hour)+...
                                         ms.Pg(12,hour)*ms.lamP(mpc.gen(12,1),hour))*0.5;
             %% Long Island
        for hour = 1:21
            Gen_DAM_Revenue_hr(4,hour) = ms.Pg(20,hour)*ms.lamP(mpc.gen(20,1),hour)+...
                                         ms.Pg(21,hour)*ms.lamP(mpc.gen(21,1),hour)+...
                                         ms.Pg(35,hour)*ms.lamP(mpc.gen(35,1),hour)+...
                                         ms.Pg(36,hour)*ms.lamP(mpc.gen(36,1),hour)+...
                                         ms.Pg(50,hour)*ms.lamP(mpc.gen(50,1),hour)+...
                                         ms.Pg(51,hour)*ms.lamP(mpc.gen(51,1),hour)+...
                                         ms.Pg(8,hour)*ms.lamP(mpc.gen(8,1),hour)+...
                                         ms.Pg(13,hour)*ms.lamP(mpc.gen(13,1),hour);
        end
        hour = 22;
            Gen_DAM_Revenue_hr(4,hour) =(ms.Pg(20,hour)*ms.lamP(mpc.gen(20,1),hour)+...
                                         ms.Pg(21,hour)*ms.lamP(mpc.gen(21,1),hour)+...
                                         ms.Pg(35,hour)*ms.lamP(mpc.gen(35,1),hour)+...
                                         ms.Pg(36,hour)*ms.lamP(mpc.gen(36,1),hour)+...
                                         ms.Pg(50,hour)*ms.lamP(mpc.gen(50,1),hour)+...
                                         ms.Pg(51,hour)*ms.lamP(mpc.gen(51,1),hour)+...
                                         ms.Pg(8,hour)*ms.lamP(mpc.gen(8,1),hour)+...
                                         ms.Pg(13,hour)*ms.lamP(mpc.gen(13,1),hour))*0.5;
    %% Count Renewables in Op Cost?
        if RenInOpCost == 1
            Gens = 59;
        else
            Gens = 14;
        end
    %% Gen Op Costs -- OLD 24 hrs 
        Gen_DAM_OpCost24 = zeros(Gens,1);
        for genn = 1:Gens
            for DAMhr = 1:24
                Gen_DAM_OpCost24(genn) = Gen_DAM_OpCost24(genn) + ...
                    mdo.UC.CommitSched(genn,DAMhr)*(mpc.gencost(genn,7) + ms.Pg(genn,DAMhr) *mpc.gencost(genn,6) + (ms.Pg(genn,DAMhr))^2 *mpc.gencost(genn,5));
            end
        end
    %% Gen Op Costs -- NEW 21.5 hrs
        Gen_DAM_OpCost = zeros(59,1);
        for gen = 1:Gens
            for hour = 1:21
                Gen_DAM_OpCost(gen) = Gen_DAM_OpCost(gen) + ...
                    mdo.UC.CommitSched(gen,hour)*(mpc.gencost(gen,7) + ms.Pg(gen,hour) *mpc.gencost(gen,6) + (ms.Pg(gen,hour))^2 *mpc.gencost(gen,5));
            end
            hour = 22;
               Gen_DAM_OpCost(gen) = Gen_DAM_OpCost(gen) + 0.5*(...
                    mdo.UC.CommitSched(gen,hour)*(mpc.gencost(gen,7) + ms.Pg(gen,hour) *mpc.gencost(gen,6) + (ms.Pg(gen,hour))^2 *mpc.gencost(gen,5)));
        end
        Summaryy(:,2) = Gen_DAM_OpCost;
    %% Gen SUP Costs -- OLD 24 hrs (For 24 Hr DAM Obj Fxn Val Cost)
        %Initialize
            Gen_DAM_SUPCost24 = zeros(59,1);
        %Top of the Morning
            for gen = 1:Gens
                if mdo.UC.CommitSched(gen,1) == 1
                    Gen_DAM_SUPCost24(gen) = Gen_DAM_SUPCost24(gen) + mdi.mpc.gencost(gen,2);
                end
            end
        %Later in the Day
            for gen = 1:Gens
                for DAMhr = 2:24
                    if mdo.UC.CommitSched(gen,DAMhr) - mdo.UC.CommitSched(gen,DAMhr-1) == 1
                        Gen_DAM_SUPCost24(gen) = Gen_DAM_SUPCost24(gen) + mdi.mpc.gencost(gen,2);
                    end
                end
            end
    %% Gen SUP Costs -- NEW 21.5 hrs
        %Initialize
            Gen_DAM_SUPCost = zeros(59,1);
        %Top of the Morning
            for gen = 1:Gens
                if mdo.UC.CommitSched(gen,1) == 1
                    Gen_DAM_SUPCost(gen) = Gen_DAM_SUPCost(gen) + mdi.mpc.gencost(gen,2);
                end
            end
        %Later in the Day
            for gen = 1:Gens
                for hour = 2:21
                    if mdo.UC.CommitSched(gen,hour) - mdo.UC.CommitSched(gen,hour-1) == 1
                        Gen_DAM_SUPCost(gen) = Gen_DAM_SUPCost(gen) + mdi.mpc.gencost(gen,2);
                    end
                end
                hour = 22;
                    if mdo.UC.CommitSched(gen,hour) - mdo.UC.CommitSched(gen,hour-1) == 1
                        Gen_DAM_SUPCost(gen) = Gen_DAM_SUPCost(gen) + 0.5*mdi.mpc.gencost(gen,2);
                    end
            end
        Summaryy(:,3) = Gen_DAM_SUPCost;
    %% Record DAM scheduled starts and shutdowns for RTC
        %Initialize
            DAMstarts = zeros(therm_gen_count,1);   %First int unit is online
            DAMshutdowns = zeros(therm_gen_count,1); %Last int unit is online
        %Find hours with starts and shutdowns
            for gen = 1:therm_gen_count
               for hour = 2:22
                   if mdo.UC.CommitSched(gen,hour) - mdo.UC.CommitSched(gen,hour-1) == 1
                       DAMstarts(gen,1) = hour*12+1;
                   end
                   if mdo.UC.CommitSched(gen,hour) - mdo.UC.CommitSched(gen,hour-1) == -1
                       DAMshutdowns(gen,1) = hour*12-12;
                   end
               end
            end

            
%% Plot DAM results
        %Timescale
            BigTime_DAM = int_stop_DAM;
            Time4Graph = linspace(1,24,BigTime_DAM);
    %% First DAM Graph
            DAM_LMP_energy = ms.lamP(62,1:int_stop_DAM);
            DAM_LMP = ms.lamP(1:68,1:int_stop_DAM);
            hFigA = figure(1); 
            set(hFigA, 'Position', [250 50 800 400]) %Pixels: from left, from bottom, across, high
        %% A -- True Load, Net Load, Demand
%             A1 = subplot(3,1,1); hold on;
%                 A2 = get(A1,'position'); A2(4) = A2(4)*0.80; set(A1, 'position', A2); A2(3) = A2(3)*0.75; set(A1, 'position', A2);
%                 yyaxis right
%                     hold on
% %                     plot(Time4Graph,ms.lamP(1,1:int_stop_DAM),'LineStyle','-','color',[0.85 .325 .098])
%                     bar(A1,ms.lamP(1,1:int_stop_DAM),'FaceAlpha',.2)
%                     axis 'auto y';
%                     grid on
%                     ylabel('DAM LMP ($/MWh)')
%                     hold off
%                 yyaxis left
%                     hold on
%                     plot(Time4Graph,NYCA_TrueLoad_DAM(1:int_stop_DAM),'LineStyle','-','color',[0 .447 .741])
%                     plot(Time4Graph,NYCA_CASE_net_load_DAM(1:int_stop_DAM),'LineStyle','-','color',[.466 .674 .188])
%                     plot(Time4Graph,demand_DAM(1:int_stop_DAM),'LineStyle','-','color',[.494 .184 .556])
%                     ylabel('Real Power (MW)')
%                     axis([0.5,24.5,0,1000]); 
%                     set(gca, 'XTick', [0 4 8 12 16 20 24]);
%                     axis 'auto y';
%                     hold off
%                 title('NYCA True Load, Net Load, & Demand')
%                 A3 = legend('True Load', 'Net Load', 'Demand','LMP');               
%                 rect = [.8, 0.76, 0.15, 0.0875]; %[left bottom width height]
%                 set(A3, 'Position', rect)
%                 ylabel('Real Power (MW)')
%                 set(gca, 'XTick', [0 4 8 12 16 20 24]);
%                 axis 'auto y';
%                 grid on; grid minor; box on; hold off 
        %% B -- Generator Output (%)
%             B1 = subplot(3,1,2); hold on;
            B1 = subplot(2,1,1); hold on;
                 B2 = get(B1,'position'); B2(4) = B2(4)*1.15; B2(2) = B2(2)*1; set(B1, 'position', B2); B2(3) = B2(3)*1; set(B1, 'position', B2);
                plot(Time4Graph,gen_output_percent(1,:),'LineStyle',':','color',[0 .447 .741])
                plot(Time4Graph,gen_output_percent(2,:),'LineStyle',':','color',[.635 .078 .184])
                plot(Time4Graph,gen_output_percent(3,:),'LineStyle',':','color',[.85 .325 .098])
                plot(Time4Graph,gen_output_percent(4,:),'LineStyle','--','color',[0 .447 .741])
                plot(Time4Graph,gen_output_percent(5,:),'LineStyle','--','color',[.301 .745 .933])
                plot(Time4Graph,gen_output_percent(6,:),'LineStyle','--','color',[.635 .078 .184])
                plot(Time4Graph,gen_output_percent(7,:),'LineStyle','--','color',[.494 .184 .556])
                plot(Time4Graph,gen_output_percent(8,:),'LineStyle','--','color',[.466 .674 .188])
                plot(Time4Graph,gen_output_percent(10,:),'LineStyle','-.','color',[0 .447 .741])
                plot(Time4Graph,gen_output_percent(11,:),'LineStyle','-.','color',[.494 .184 .556])
                plot(Time4Graph,gen_output_percent(12,:),'LineStyle','-','color',[.494 .184 .556])
                plot(Time4Graph,gen_output_percent(13,:),'LineStyle','-','color',[.466 .674 .188])
%                     B3 = legend('Nuke A2F','Nuke GHI','Nuke GHI','Steam A2F','Steam A2F','Steam GHI','Steam NYC','Steam LI',...
%                                'CC A2F','CC NYC','GT NYC','GT LI');                        
%                 title('Generator Output (% of Nameplate)')
%                 rect = [.8, 0.45, 0.15, .12]; %[left bottom width height]
%                 set(B3, 'Position', rect)
                ylabel('Real Power (%)')
                    xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
                    xticklabels({' ' ' ' ' ' ' ' ' ' ' ' ' '})
%                     set(gca, 'XTick', [0 4 8 12 16 20 24]);
                axis([0.5,24.5,-0.16,1]); 
                yticklabels({' 0','50','100'});
                grid on; grid minor; box on; hold off 
        %% C -- Generation by Type
%             C1 = subplot(3,1,3); hold on;
            C1 = subplot(2,1,2); hold on;
                C2 = get(C1,'position'); C2(4) = C2(4)*1.15; C2(2) = C2(2)*1.35; set(C1, 'position', C2); C2(3) = C2(3)*1; set(C1, 'position', C2);
                    bar([NukeGenDAM;SteamGenDAM;CCGenDAM;GTGenDAM;RenGen_windyDAM;RenGen_hydroDAM;RenGen_otherDAM;BTM4GraphDAM;].'./1000,'stacked','FaceAlpha',.5)
%                     C3 = legend('Nuke', 'Steam', 'CC', 'GT', 'Wind', 'Hydro', 'Other', 'BTM');
%                     reorderLegendbar([1 2 3 4 5 6 7 8]) 
%                 title('Generation by Type')
%                 rect = [.8, 0.125, 0.15, .12]; %[left bottom width height]
%                 set(C3, 'Position', rect)
                ylabel('Real Power (GW)')
                xlabel('Time (Hour Beginning)');
                axis([0.5,24.5,0,30]); 
%                 axis 'auto y';
                    xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
                    xticklabels({'0' '4' '8' '12' '16' '20' '24'})
%                     set(gca, 'XTick', [0 4 8 12 16 20 24]);
                set(gca, 'YTick', [0 10 20 30])
                format shortg
                grid on; grid minor; box on; hold off 
        %% Graph Title (Same for all graphs)
%             First_Line_Title = ['Simulation for: ', datestring(5:6), ' ', datestring(7:8), ' ', datestring(1:4), ' in the ',Case_Name_String];
%             ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off',...
%                 'Units','normalized', 'clipping' , 'off');
%             text(0.5, 1.0,[{'\bf \fontsize{12}' First_Line_Title}], 'HorizontalAlignment' ,...
%                 'center', 'VerticalAlignment', 'top')        
        %% Save to a word file
    %If this is the first loop through the iteration, open a new document
        if and(Case == case_start, d == d_start)
            % Capture current figure/model into clipboard:
                matlab.graphics.internal.copyFigureHelper(hFigA)
            % Start an ActiveX session with PowerPoint:
                word = actxserver('Word.Application');
                word.Visible = 1;
            % Create new presentation:
                op = invoke(word.Documents,'Add');
            % Paste the contents of the Clipboard:
                invoke(word.Selection,'Paste');
    %otherwise grab the existing word document and paste in there. 
        else
            % Capture current figure/model into clipboard:
                  matlab.graphics.internal.copyFigureHelper(hFigA)
            % Find end of document and make it the insertion point:
                end_of_doc = get(word.activedocument.content,'end');
                set(word.application.selection,'Start',end_of_doc);
                set(word.application.selection,'End',end_of_doc); 
            % Paste the contents of the Clipboard:
                invoke(word.Selection,'Paste');
        end
    close all

    %% LMP
        %Average LMP by Region
            AvgLoadLMP = zeros(4,24);
            AvgGenLMP  = zeros(4,24);
            for hour = 1:24
                AvgLoadLMP(1, hour) = mean(ms.lamP([1 9 33 36 37 39 40 41 42 44 45 46 47 48 49 50 51 52],hour));
                AvgLoadLMP(2, hour) = mean(ms.lamP([3 4 7 8 25],hour));
                AvgLoadLMP(3, hour) = mean(ms.lamP([12 15 16 18 20 27],hour));
                AvgLoadLMP(4, hour) = mean(ms.lamP([21 23 24],hour));
                AvgGenLMP(1, hour) = mean(ms.lamP([64 65 66 67 68],hour));
                AvgGenLMP(2, hour) = mean(ms.lamP([53 54 60],hour));
                AvgGenLMP(3, hour) = mean(ms.lamP([55 56 57],hour));
                AvgGenLMP(4, hour) = mean(ms.lamP([58 59],hour));
            end
    %% Thermal Generation by Region
        DAMThermGenByRegion = zeros(4,24);
        for hour = 1:24
            DAMThermGenByRegion(1,hour) = Nuke_1_DAM(hour)+Steam_1_DAM(hour)+Steam_2_DAM(hour)+CCGen_1_DAM(hour);
            DAMThermGenByRegion(2,hour) = Nuke_2_DAM(hour) + Nuke_3_DAM(hour) + Steam_3_DAM(hour);
            DAMThermGenByRegion(3,hour) = Steam_4_DAM(hour) + CCGen_2_DAM(hour)+ GTGen_1_DAM(hour);
            DAMThermGenByRegion(4,hour) = Steam_5_DAM(hour) + GTGen_2_DAM(hour);
        end   
    %% Renewable Gen by Region
        DAMRenGenByRegion = zeros(4,24);
        for hour = 1:24
            DAMRenGenByRegion(1,hour) = sum(mdo.results.Pc([25 26 27 28 29 40 41 42 43 44 55 56 57 58 59],hour));
            DAMRenGenByRegion(2,hour) = sum(mdo.results.Pc([15 16 22 30 31 37 45 46 52],hour));
            DAMRenGenByRegion(3,hour) = sum(mdo.results.Pc([17 18 19 32 33 34 47 48 49],hour));
            DAMRenGenByRegion(4,hour) = sum(mdo.results.Pc([20 21 35 36 20 21],hour));       
        end
    %% Load by Region
        DAMloadByRegion = zeros(4,24);
        for hour = 1:24
            DAMloadByRegion(1,hour) = sum(most_busload_DAM(hour,[1 9 33 36 37 39 40 41 42 44 45 46 47 48 49 50 51 52]));
            DAMloadByRegion(2,hour) = sum(most_busload_DAM(hour,[3 4 7 8 25]));
            DAMloadByRegion(3,hour) = sum(most_busload_DAM(hour,[12 15 16 18 20 27]));
            DAMloadByRegion(4,hour) = sum(most_busload_DAM(hour,[21 23 24]));
        end
    %% MAP distribution by Region
        DAMloadTotalByRegion = zeros(4,1);
        DAMloadTotalByRegion(1,1) = sum(DAMloadByRegion(1,:));
        DAMloadTotalByRegion(2,1) = sum(DAMloadByRegion(2,:));
        DAMloadTotalByRegion(3,1) = sum(DAMloadByRegion(3,:));
        DAMloadTotalByRegion(4,1) = sum(DAMloadByRegion(4,:));
        MAPratio(1,Case*4+d) = DAMloadTotalByRegion(1,1)/sum(DAMloadTotalByRegion(:,1));
        MAPratio(2,Case*4+d) = sum(DAMloadTotalByRegion(2:4,1))/sum(DAMloadTotalByRegion(:,1));

    %% Load Cost By Region
        DAMloadCostByRegionHr = zeros(4,24); 
        for hour = 1:22
            DAMloadCostByRegionHr(1,hour) =   DAM_LMP(1,hour)*most_busload_DAM(hour,1)+...
                                            DAM_LMP(9,hour)*most_busload_DAM(hour,9)+...
                                            DAM_LMP(33,hour)*most_busload_DAM(hour,33)+...
                                            DAM_LMP(36,hour)*most_busload_DAM(hour,36)+...
                                            DAM_LMP(37,hour)*most_busload_DAM(hour,37)+...
                                            DAM_LMP(39,hour)*most_busload_DAM(hour,39)+...
                                            DAM_LMP(40,hour)*most_busload_DAM(hour,40)+...
                                            DAM_LMP(41,hour)*most_busload_DAM(hour,41)+...
                                            DAM_LMP(42,hour)*most_busload_DAM(hour,42)+...
                                            DAM_LMP(44,hour)*most_busload_DAM(hour,44)+...
                                            DAM_LMP(45,hour)*most_busload_DAM(hour,45)+...
                                            DAM_LMP(46,hour)*most_busload_DAM(hour,46)+...
                                            DAM_LMP(47,hour)*most_busload_DAM(hour,47)+...
                                            DAM_LMP(48,hour)*most_busload_DAM(hour,48)+...
                                            DAM_LMP(49,hour)*most_busload_DAM(hour,49)+...
                                            DAM_LMP(50,hour)*most_busload_DAM(hour,50)+...
                                            DAM_LMP(51,hour)*most_busload_DAM(hour,51)+...
                                            DAM_LMP(52,hour)*most_busload_DAM(hour,52);

            DAMloadCostByRegionHr(2,hour) =   DAM_LMP(3,hour)*most_busload_DAM(hour,3)+...
                                            DAM_LMP(4,hour)*most_busload_DAM(hour,4)+...
                                            DAM_LMP(7,hour)*most_busload_DAM(hour,7)+...
                                            DAM_LMP(8,hour)*most_busload_DAM(hour,8)+...
                                            DAM_LMP(25,hour)*most_busload_DAM(hour,25);
                                        
            DAMloadCostByRegionHr(3,hour) =   DAM_LMP(12,hour)*most_busload_DAM(hour,12)+...
                                            DAM_LMP(15,hour)*most_busload_DAM(hour,15)+...
                                            DAM_LMP(16,hour)*most_busload_DAM(hour,16)+...
                                            DAM_LMP(18,hour)*most_busload_DAM(hour,18)+...
                                            DAM_LMP(20,hour)*most_busload_DAM(hour,20)+...
                                            DAM_LMP(27,hour)*most_busload_DAM(hour,27);

            DAMloadCostByRegionHr(4,hour) =   DAM_LMP(21,hour)*most_busload_DAM(hour,21)+...
                                            DAM_LMP(23,hour)*most_busload_DAM(hour,23)+...
                                            DAM_LMP(24,hour)*most_busload_DAM(hour,24);

        end
        DAMloadCostByRegionHr(1,22) = DAMloadCostByRegionHr(1,22)*.5;
        DAMloadCostByRegionHr(2,22) = DAMloadCostByRegionHr(2,22)*.5;
        DAMloadCostByRegionHr(3,22) = DAMloadCostByRegionHr(3,22)*.5;
        DAMloadCostByRegionHr(4,22) = DAMloadCostByRegionHr(4,22)*.5;
        for Region = 1:4
            DAMloadCostByRegion(Region,(Case*4+d)) = sum(DAMloadCostByRegionHr(Region,1:24))./1000; 
        end
            
    
    %% LMP DAM Graph
            hFigLMP = figure(1); 
            set(hFigLMP, 'Position', [250 50 650 300]) %Pixels: from left, from bottom, across, high
        %% B -- Load Weighted LMP 
            B1 = subplot(1,1,1); hold on;  %Pixels: from left, from bottom, across, high
                 B2 = get(B1,'position'); B2(4) = B2(4)*.5; B2(2) = B2(2)*1.5; set(B1, 'position', B2); B2(3) = B2(3)*.85; set(B1, 'position', B2);
                plot(1:24,AvgLoadLMP(1,:),'LineStyle','--','color',[0 .447 .741])
                plot(1:24,AvgLoadLMP(2,:),'LineStyle','--','color',[.635 .078 .184])
                plot(1:24,AvgLoadLMP(3,:),'LineStyle','--','color',[.85 .325 .098])
                plot(1:24,AvgLoadLMP(4,:),'LineStyle','--','color',[.466 .674 .188])

                B3 = legend('Upstate','LHV','NYC','LI');                        
                title('Average Load Bus LMP by Region')
                rect = [.8, 0.3, 0.15, .12]; %[left bottom width height]
                set(B3, 'Position', rect)
                ylabel('LMP ($/MWh)')
                xlabel('Time (Hour Beginning)');
%                     xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
%                     xticklabels({' ' ' ' ' ' ' ' ' ' ' ' ' '})
                     set(gca, 'XTick', [0 4 8 12 16 20 24]);
                axis([1,24,0,20]); 
                axis 'auto y';
                minval = max(max(max(AvgLoadLMP)),15);
                ylim([0 minval])
%                 yticklabels({' 0','50','100'});
                grid on; grid minor; box on; hold off   
        %% C -- Gen Weighted LMP
%              C1 = subplot(2,1,2); hold on;
%                  C2 = get(C1,'position'); C2(4) = C2(4)*.95; C2(2) = C2(2)*1; set(C1, 'position', C2); C2(3) = C2(3)*.75; set(C1, 'position', C2);
%                 plot(1:24,AvgGenLMP(1,:),'LineStyle','--','color',[0 .447 .741])
%                 plot(1:24,AvgGenLMP(2,:),'LineStyle','--','color',[.635 .078 .184])
%                 plot(1:24,AvgGenLMP(3,:),'LineStyle','--','color',[.85 .325 .098])
%                 plot(1:24,AvgGenLMP(4,:),'LineStyle','--','color',[.466 .674 .188])
%                 C3 = legend('Gen Upstate','Gen LHV','Gen NYC','Gen LI');                        
%                 title('Gen Weighted LMP by Region')
%                 rect = [.8, 0.15, 0.15, .12]; %[left bottom width height]
%                 set(C3, 'Position', rect)
%                 ylabel('LMP ($/MWh)')
%                  set(gca, 'XTick', [0 4 8 12 16 20 24]);
%                 axis([1,24,-0.16,1]); 
%                 axis 'auto y';
% %                 yticklabels({' 0','50','100'});
%                 grid on; grid minor; box on; hold off                    
        %% Graph Title (Same for all graphs)
            First_Line_Title = ['Simulation for: ', datestring(5:6), ' ', datestring(7:8), ' ', datestring(1:4), ' in the ',Case_Name_String];
            ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off',...
                'Units','normalized', 'clipping' , 'off');
            text(0.5, 1.0,[{'\bf \fontsize{12}' First_Line_Title}], 'HorizontalAlignment' ,...
                'center', 'VerticalAlignment', 'top')    
        %% Save to a word file
    %If this is the first loop through the iteration, open a new document
            % Capture current figure/model into clipboard:
                  matlab.graphics.internal.copyFigureHelper(hFigLMP)
            % Find end of document and make it the insertion point:
                end_of_doc = get(word.activedocument.content,'end');
                set(word.application.selection,'Start',end_of_doc);
                set(word.application.selection,'End',end_of_doc); 
            % Paste the contents of the Clipboard:
                invoke(word.Selection,'Paste');
    close all
    
    %% Load and Gen by Region
        hFigLoad = figure(3); set(hFigLoad, 'Position', [450 50 650 550]) %Pixels: from left, from bottom, across, high
            %% A -- Thermal Gen by Region 
                A1 = subplot(3,1,1); hold on;
                    A2 = get(A1,'position'); A2(4) = A2(4)*.85; A2(2) = A2(2)*.95; set(A1, 'position', A2); A2(3) = A2(3)*0.85; set(A1, 'position', A2);
                    bar([DAMThermGenByRegion(1,1:24);DAMThermGenByRegion(2,1:24);DAMThermGenByRegion(3,1:24);DAMThermGenByRegion(4,1:24);].','stacked','FaceAlpha',.5)
                    ylabel('Real Power (MW)')
                title('Thermal Generation by Region')

                axis([0.5,24.5,0,1500]); 
                axis 'auto y';
%                     set(gca, 'YTick', [0 500 1000 1500])
                    xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
                    xticklabels({'0' '4' '8' '12' '16' '20' '24'})
                 set(gca, 'YTick', [0 10000 20000 30000 40000 50000 60000 70000])
                yticklabels({'0' '10,000' '20,000' '30,000' '40,000' '50,000' '60,000' '70,000'})
                grid on; grid minor; box on; hold off 
            %% B -- Renewable Gen by Region
                B1 = subplot(3,1,2); hold on;
                    B2 = get(B1,'position'); B2(4) = B2(4)*.85; B2(2) = B2(2)*.95; set(B1, 'position', B2); B2(3) = B2(3)*0.85; set(B1, 'position', B2);
                    bar([DAMRenGenByRegion(1,1:24);DAMRenGenByRegion(2,1:24);DAMRenGenByRegion(3,1:24);DAMRenGenByRegion(4,1:24);].','stacked','FaceAlpha',.5)
                    ylabel('Real Power (MW)')
                axis([0.5,24.5,0,4000]); 
                axis 'auto y';
                title('Renewable Generation by Region')
                B3 = legend('Upstate','LHV','NYC','LI');
                reorderLegendarea([1 2 3 4])
                rect = [.81, 0.405, 0.15, .15]; %[left bottom width height]
                set(B3, 'Position', rect)
                    xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
                    xticklabels({'0' '4' '8' '12' '16' '20' '24'})
                 set(gca, 'YTick', [0 2000 4000 6000 8000 10000])
                yticklabels({'0' '2,000' '4,000' '6,000' '8,000' '10,000'})
                    grid on; grid minor; box on; hold off    
            %% C -- Renewable Gen by Region
                C1 = subplot(3,1,3); hold on;
                    C2 = get(C1,'position'); C2(4) = C2(4)*.85; C2(2) = C2(2)*1; set(C1, 'position', C2); C2(3) = C2(3)*0.85; set(C1, 'position', C2);
                    bar([DAMloadByRegion(1,1:24);DAMloadByRegion(2,1:24);DAMloadByRegion(3,1:24);DAMloadByRegion(4,1:24);].','stacked','FaceAlpha',.5)
                    ylabel('Real Power (MW)')
                title('Load by Region')
                axis([0.5,24.5,0,4000]); 
                axis 'auto y';
%                 title('C-E Flow (MW)')
                    xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
                    xticklabels({'0' '4' '8' '12' '16' '20' '24'})
                 set(gca, 'YTick', [0 10000 20000 30000 40000 50000 60000 70000])
                yticklabels({'0' '10,000' '20,000' '30,000' '40,000' '50,000' '60,000' '70,000'})
                    xlabel('Time (Hour Beginning)')
                    grid on; grid minor; box on; hold off    
            %% Title
                First_Line_Title = ['Simulation for: ', datestring(5:6), ' ', datestring(7:8), ' ', datestring(1:4), ' in the ',Case_Name_String];
                ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off',...
                    'Units','normalized', 'clipping' , 'off');
                text(0.5, 1.0,[{'\bf \fontsize{12}' First_Line_Title}], 'HorizontalAlignment' ,...
                    'center', 'VerticalAlignment', 'top')  
            %% Save to a word file
                % Capture current figure/model into clipboard:
                      matlab.graphics.internal.copyFigureHelper(hFigLoad)
                % Find end of document and make it the insertion point:
                    end_of_doc = get(word.activedocument.content,'end');
                    set(word.application.selection,'Start',end_of_doc);
                    set(word.application.selection,'End',end_of_doc); 
                % Paste the contents of the Clipboard:
                    invoke(word.Selection,'Paste');
                close all

    %% Congestion Charge DAM Difference (analysis only)
        %% DAM Load Cost
                LoadCostDAM = zeros(52,1);
                LoadCostDAMhr = zeros(52,24);
                for bus = 1:52
%                     for hour = 1:24
%                         LoadCostDAM(bus,1) = LoadCostDAM(bus,1) + DAM_LMP(bus,hour)*most_busload_DAM(hour,bus);
%                     end
                    for hour = 1:21
                        LoadCostDAM(bus,1)   = LoadCostDAM(bus,1) + DAM_LMP(bus,hour)*most_busload_DAM(hour,bus);
                        LoadCostDAMhr(bus,hour) = DAM_LMP(bus,hour)*most_busload_DAM(hour,bus);
                    end
                        LoadCostDAM(bus,1) = LoadCostDAM(bus,1) + 0.5*DAM_LMP(bus,22)*most_busload_DAM(22,bus);
                        LoadCostDAMhr(bus,22) = 0.5*DAM_LMP(bus,22)*most_busload_DAM(22,bus);
                end
        %% Flat Scenario DAM Congestion Charge
            DAM_congCharge_region_hr = zeros(4,24);
            for hour = 1:21
                DAM_congCharge_region_hr(1,hour) = DAMloadCostByRegionHr(1,hour) - Gen_DAM_Revenue_hr(1,hour);
                DAM_congCharge_region_hr(2,hour) = DAMloadCostByRegionHr(2,hour) - Gen_DAM_Revenue_hr(2,hour);
                DAM_congCharge_region_hr(3,hour) = DAMloadCostByRegionHr(3,hour) - Gen_DAM_Revenue_hr(3,hour);
                DAM_congCharge_region_hr(4,hour) = DAMloadCostByRegionHr(4,hour) - Gen_DAM_Revenue_hr(4,hour);
            end
            DAM_congCharge_hrr = zeros(1,24);
            for hour = 1:22
                DAM_congCharge_hrr(1,hour) = sum(DAM_congCharge_region_hr(1:4,hour));
            end
        
    %% Figure: Congestion charge by region
        hFigCC = figure(44); set(hFigCC, 'Position', [450 50 650 650]) %Pixels: from left, from bottom, across, high
            %% A -- Load Cost by Region 
                A1 = subplot(3,1,1); hold on;
                    A2 = get(A1,'position'); A2(4) = A2(4)*.95; A2(2) = A2(2)*.95; set(A1, 'position', A2); A2(3) = A2(3)*0.85; set(A1, 'position', A2);
%                     bar([DAM_congCharge_region_hr(1,1:24);DAM_congCharge_region_hr(2,1:24);DAM_congCharge_region_hr(3,1:24);DAM_congCharge_region_hr(4,1:24);].','stacked','FaceAlpha',.5)
                    bar([DAMloadCostByRegionHr(1,1:24);DAMloadCostByRegionHr(2,1:24);DAMloadCostByRegionHr(3,1:24);DAMloadCostByRegionHr(4,1:24);].','stacked','FaceAlpha',.5)
                    ylabel('Cost ($)')
                title('DAM Load Cost by Region')
                A3 = legend('Upstate','LHV','NYC','LI');
                reorderLegendarea([1 2 3 4])
                rect = [.81, 0.705, 0.15, .15]; %[left bottom width height]
                set(A3, 'Position', rect)
                axis([0.5,24.5,0,1500]); 
                axis 'auto y';
%                     set(gca, 'YTick', [0 500 1000 1500])
                    xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
                    xticklabels({'0' '4' '8' '12' '16' '20' '24'})
                    xticklabels({'0' '4' '8' '12' '16' '20' '24'})
                 set(gca, 'YTick', [0 100000 200000 300000 400000 500000 ])
                yticklabels({'0' '100,000' '200,000'  '300,000' '400,000' '500,000'})
                grid on; grid minor; box on; hold off 
            %% B -- Gen Payment by Region 
                B1 = subplot(3,1,2); hold on;
                    B2 = get(B1,'position'); B2(4) = B2(4)*.95; B2(2) = B2(2)*.95; set(B1, 'position', B2); B2(3) = B2(3)*0.85; set(B1, 'position', B2);
%                     bar([DAM_congCharge_region_hr(1,1:24);DAM_congCharge_region_hr(2,1:24);DAM_congCharge_region_hr(3,1:24);DAM_congCharge_region_hr(4,1:24);].','stacked','FaceAlpha',.5)
                    bar([Gen_DAM_Revenue_hr(1,1:24);Gen_DAM_Revenue_hr(2,1:24);Gen_DAM_Revenue_hr(3,1:24);Gen_DAM_Revenue_hr(4,1:24);].','stacked','FaceAlpha',.5)
                    ylabel('Payment ($)')
                title('DAM Generator Payments by Region')
                B3 = legend('Upstate','LHV','NYC','LI');
                reorderLegendarea([1 2 3 4])
                rect = [.81, 0.405, 0.15, .15]; %[left bottom width height]
                set(B3, 'Position', rect)
                axis([0.5,24.5,0,1500]); 
                axis 'auto y';
%                     set(gca, 'YTick', [0 500 1000 1500])
                    xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
                    xticklabels({'0' '4' '8' '12' '16' '20' '24'})
                 set(gca, 'YTick', [0 100000 200000 300000 400000 500000 ])
                yticklabels({'0' '100,000' '200,000'  '300,000' '400,000' '500,000'})
                grid on; grid minor; box on; hold off 
            %% C -- Congestion Charge by Region 
                C1 = subplot(3,1,3); hold on;
                    C2 = get(C1,'position'); C2(4) = C2(4)*.95; C2(2) = C2(2)*.95; set(C1, 'position', C2); C2(3) = C2(3)*0.85; set(C1, 'position', C2);
%                     bar([DAM_congCharge_region_hr(1,1:24);DAM_congCharge_region_hr(2,1:24);DAM_congCharge_region_hr(3,1:24);DAM_congCharge_region_hr(4,1:24);].','stacked','FaceAlpha',.5)
                    bar([DAM_congCharge_hrr(1,1:24);].','FaceAlpha',.5)
                    ylabel('Charge ($)')
                title('DAM Congestion Charge')
                C3 = legend('Total');
                rect = [.81, 0.2, 0.15, .03]; %[left bottom width height]
                set(C3, 'Position', rect)
                axis([0.5,24.5,0,1500]); 
                axis 'auto y';
                minval2 = max(max(DAM_congCharge_hrr),10000);
                ylim([0 minval2])
%                     set(gca, 'YTick', [0 500 1000 1500])
                    xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
                    xticklabels({'0' '4' '8' '12' '16' '20' '24'})
                xlabel('Time (Hour Beginning)');
                 set(gca, 'YTick', [0 10000 20000 30000 40000 50000 60000 70000 80000 90000 100000 110000 120000])
                yticklabels({'0' '10,000' '20,000' '30,000' '40,000' '50,000' '60,000' '70,000' '80,000' '90,000' '100,000' '110,000' '120,000'})
                grid on; grid minor; box on; hold off 
            %% Title
                First_Line_Title = ['Simulation for: ', datestring(5:6), ' ', datestring(7:8), ' ', datestring(1:4), ' in the ',Case_Name_String];
                ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off',...
                    'Units','normalized', 'clipping' , 'off');
                text(0.5, 1.0,[{'\bf \fontsize{12}' First_Line_Title}], 'HorizontalAlignment' ,...
                    'center', 'VerticalAlignment', 'top')  
            %% Save to a word file
                % Capture current figure/model into clipboard:
                      matlab.graphics.internal.copyFigureHelper(hFigCC)
                % Find end of document and make it the insertion point:
                    end_of_doc = get(word.activedocument.content,'end');
                    set(word.application.selection,'Start',end_of_doc);
                    set(word.application.selection,'End',end_of_doc); 
                % Paste the contents of the Clipboard:
                    invoke(word.Selection,'Paste');
                close all
%% DAM only
%***************
% This code should be NOT commented out and a stop placed on "stop = 1" if analysis of the DAM only is desired. 
% Otherwise, comment this code out to run simulations for both DAM and RTM. 
DayCaseWorked = [d,Case]

end
end

stop = 1
for Case = case_start:case_end
for d = d_start: d_end
% Comment out the above code to enable DAM and RTM simulations. 
%***************    
    
    %% Second DAM Graph - Renewable curtailment in the DAM
        %% Initialize
            DAMwindy = zeros(24,2);
            for int = 1:24
                if useinstant == 1
                    DAMwindy(int,1) = sum(most_bus_rengen_windy(int*12-11,:));
                else
                    DAMwindy(int,1) = sum(mean(most_bus_rengen_windy(int*12-11:int*12,:)));
                end
                DAMwindy(int,2) = RenGen_windyDAM(int);
            end
            DAMhydro = zeros(24,2);
            for int = 1:24
                if useinstant == 1
                    DAMhydro(int,1) = sum(most_bus_rengen_hydro(int*12-11,:));
                else
                    DAMhydro(int,1) = sum(mean(most_bus_rengen_hydro(int*12-11:int*12,:)));
                end
                DAMhydro(int,2) = RenGen_hydroDAM(int);
            end
            DAMother = zeros(24,2);
            for int = 1:24
                if useinstant == 1
                    DAMother(int,1) = sum(most_bus_rengen_other(int*12-11,:));
                else
                    DAMother(int,1) = sum(mean(most_bus_rengen_other(int*12-11:int*12,:)));
                end
                DAMother(int,2) = RenGen_otherDAM(int);
            end
        %% DAM Renewable Curtailment MWh - TOTAL
            DAMwindyCurtMWh = 0;
            for hourr = 1:24
                DAMwindyCurtMWh = DAMwindyCurtMWh + DAMwindy(hourr,1) - DAMwindy(hourr,2);
            end
            DAMhydroCurtMWh = 0;
            for hourr = 1:24
                DAMhydroCurtMWh = DAMhydroCurtMWh + DAMhydro(hourr,1) - DAMhydro(hourr,2);
            end
            DAMotherCurtMWh = 0;
            for hourr = 1:24
                DAMotherCurtMWh = DAMotherCurtMWh + DAMother(hourr,1) - DAMother(hourr,2);
            end
        %% DAM Renewable Curtailment MWh - By Hour
            DAMCurtMWh_hrly = -(RenGen_windyDAM(:) - DAMwindy(:,1) + RenGen_hydroDAM(:) - DAMhydro(:,1) + RenGen_otherDAM(:) - DAMother(:,1));
        %% Make Figure
                hFigA = figure(2); set(hFigA, 'Position', [450 50 650 600]) %Pixels: from left, from bottom, across, high
            %% A -- Wind
                A1 = subplot(3,1,1); hold on;
                    A2 = get(A1,'position'); A2(4) = A2(4)*0.80; set(A1, 'position', A2); A2(3) = A2(3)*0.75; set(A1, 'position', A2);
                    bar(DAMwindy)
                    title('DAM Wind Curtailment')
                    if useinstant == 1
                        A3 = legend('first value in hour','DAM committed');               
                    else
                        A3 = legend('hourly average','DAM committed');               
                    end
                        rect = [.8, 0.76, 0.15, 0.0875]; %[left bottom width height]
                    set(A3, 'Position', rect)
                    ylabel('Real Power (MW)')
                    set(gca, 'XTick', [0 4 8 12 16 20 24]);
                    axis 'auto y';
                    grid on; grid minor; box on; hold off 
            %% B -- Hydro
                B1 = subplot(3,1,2); hold on;
                    B2 = get(B1,'position'); B2(4) = B2(4)*1.; B2(2) = B2(2)*1; set(B1, 'position', B2); B2(3) = B2(3)*0.75; set(B1, 'position', B2);
                    bar(DAMhydro)
                    title('DAM Hydro Curtailment')
                    if useinstant == 1
                        B3 = legend('first value in hour','DAM committed');               
                    else
                        B3 = legend('hourly average','DAM committed');               
                    end
                    rect = [.8, 0.45, 0.15, .12]; %[left bottom width height]
                    set(B3, 'Position', rect)
                    ylabel('Real Power (MW)')
                    axis([0.5,24.5,0,1]); 
                    axis 'auto y';
                    set(gca, 'XTick', [0 4 8 12 16 20 24]);
                    grid on; grid minor; box on; hold off 
            %% C -- Other
                C1 = subplot(3,1,3); hold on;
                    C2 = get(C1,'position'); C2(4) = C2(4)*1; C2(2) = C2(2)*1; set(C1, 'position', C2); C2(3) = C2(3)*0.75; set(C1, 'position', C2);
                    bar(DAMother)
                    title('DAM Other Curtailment')
                    if useinstant == 1
                        C3 = legend('first value in hour','DAM committed');               
                    else
                        C3 = legend('hourly average','DAM committed');               
                    end
                    rect = [.8, 0.125, 0.15, .12]; %[left bottom width height]
                    set(C3, 'Position', rect)
                    ylabel('Real Power (MW)')
                    xlabel('Time (hours)');
                    axis([0.5,24.5,0,30000]); 
                    axis 'auto y';
                    set(gca, 'XTick', [0 4 8 12 16 20 24]);
                    format shortg
                    grid on; grid minor; box on; hold off 
            %% Graph Title (Same for all graphs)
                First_Line_Title = ['Simulation for: ', datestring(5:6), ' ', datestring(7:8), ' ', datestring(1:4), ' in the ',Case_Name_String];
                ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off',...
                    'Units','normalized', 'clipping' , 'off');
                text(0.5, 1.0,[{'\bf \fontsize{12}' First_Line_Title}], 'HorizontalAlignment' ,...
                    'center', 'VerticalAlignment', 'top')        
            %% Save to a word file
                % Capture current figure/model into clipboard:
                      matlab.graphics.internal.copyFigureHelper(hFigA)
                % Find end of document and make it the insertion point:
                    end_of_doc = get(word.activedocument.content,'end');
                    set(word.application.selection,'Start',end_of_doc);
                    set(word.application.selection,'End',end_of_doc); 
                % Paste the contents of the Clipboard:
                    invoke(word.Selection,'Paste');
        close all
    %% Store DAM Results
        DAMresults(1,Case*4+d) = d;
        DAMresults(2,Case*4+d) = Case;
        DAMresults(3,Case*4+d) = windyCurt;
        DAMresults(4,Case*4+d) = windyCurtFactor;
        DAMresults(5,Case*4+d) = sum(Gen_DAM_OpCost24(1:Gens)) + sum(Gen_DAM_SUPCost24(1:Gens));
        
        
        DAMresults(6,Case*4+d) = DAMwindyCurtMWh;
        DAMresults(7,Case*4+d) = DAMhydroCurtMWh;
        DAMresults(8,Case*4+d) = DAMotherCurtMWh;
        DAMresults(9,Case*4+d) = ms.f;  
    %% Store Constrained Interface Flow Values
        DAMifFlows = zeros(24,4);
        for hour = 1:24
            DAMifFlows(hour,1) = ms.Pf(1,hour)  - ms.Pf(16,hour);
            DAMifFlows(hour,2) = ms.Pf(1,hour)  - ms.Pf(16,hour) + ms.Pf(86,hour); 
            DAMifFlows(hour,3) = ms.Pf(7,hour)  + ms.Pf(9,hour)  + ms.Pf(13,hour); 
            DAMifFlows(hour,4) = ms.Pf(28,hour) + ms.Pf(29,hour);
        end
    %% Store EVSE Load 
        if EVSE == 1
            %% Initialize
                DAMEVSEload = mdo.Storage.ExpectedStorageDispatch(1:32,1:24);
                EVSEloadDAMgraph = zeros(4,24);
                for hour = 1:24
                    EVSEloadDAMgraph(1,hour) = -DAMEVSEload(1,hour)-DAMEVSEload(6,hour)-sum(DAMEVSEload(17:32,hour)); %A2F
                    EVSEloadDAMgraph(2,hour) = -sum(DAMEVSEload(2:5,hour))-sum(DAMEVSEload(15,hour)); %GHI
                    EVSEloadDAMgraph(3,hour) = -sum(DAMEVSEload(7:11,hour))-DAMEVSEload(16,hour); %NYC
                    EVSEloadDAMgraph(4,hour) = -sum(DAMEVSEload(12:14,hour)); %Long Island
                end
            %% Make Figure
                hFigE = figure(3); set(hFigE, 'Position', [450 50 650 200]) %Pixels: from left, from bottom, across, high
            %% A -- EVSE 
                A1 = subplot(1,1,1); hold on;
                    A2 = get(A1,'position'); A2(4) = A2(4)*.80; A2(2) = A2(2)*2.1; set(A1, 'position', A2); A2(3) = A2(3)*0.75; set(A1, 'position', A2);
                    bar([EVSEloadDAMgraph(1,1:24);EVSEloadDAMgraph(2,1:24);EVSEloadDAMgraph(3,1:24);EVSEloadDAMgraph(4,1:24);].','stacked','FaceAlpha',.5)
                    ylabel('Real Power (MW)')
                axis([0.5,24.5,0,1000]); 
                axis 'auto y';
                A3 = legend('A2F','GHI','NYC','LIs')
                reorderLegendbar([1 2 3 4])
                rect = [.8, 0.25, 0.15, .35]; %[left bottom width height]
                set(A3, 'Position', rect)
                    xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
                    xticklabels({'0' '4' '8' '12' '16' '20' '24'})
%                 set(gca, 'YTick', [0 250 500 1000])
                    xlabel('Time (hours)')
                    grid on; grid minor; box on; hold off 
            %% Save to a word file
%                 % Capture current figure/model into clipboard:
%                       matlab.graphics.internal.copyFigureHelper(hFigE)
%                 % Find end of document and make it the insertion point:
%                     end_of_doc = get(word.activedocument.content,'end');
%                     set(word.application.selection,'Start',end_of_doc);
%                     set(word.application.selection,'End',end_of_doc); 
%                 % Paste the contents of the Clipboard:
%                     invoke(word.Selection,'Paste');
        close all
        end        

    %% Curtailment by Region
        %% DAM Scheduled renewable output by region
            DAMschedRegion = zeros(4,24);
            for hour = 1:24
                %A2F
                    DAMschedRegion(1,hour) = sum(most_windy_gen_DAM(hour,11:15))+...
                                             sum(most_hydro_gen_DAM(hour,11:15))+...
                                             sum(most_other_gen_DAM(hour,11:15));
                %GHI
                    DAMschedRegion(2,hour) = sum(most_windy_gen_DAM(hour,1:2))+most_windy_gen_DAM(hour,8)+...
                                             sum(most_hydro_gen_DAM(hour,1:2))+most_hydro_gen_DAM(hour,8)+...
                                             sum(most_other_gen_DAM(hour,1:2))+most_other_gen_DAM(hour,8);
                %NYC
                    DAMschedRegion(3,hour) = sum(most_windy_gen_DAM(hour,3:5))+...
                                             sum(most_hydro_gen_DAM(hour,3:5))+...
                                             sum(most_other_gen_DAM(hour,3:5));
                %LIs
                    DAMschedRegion(4,hour) = sum(most_windy_gen_DAM(hour,6:7))+...
                                             sum(most_hydro_gen_DAM(hour,6:7))+...
                                             sum(most_other_gen_DAM(hour,6:7));
            end
        %% DAM Actual Renewable Generation by region
            DAMactualRegion = zeros(4,24);
            for hour = 1:24
                %A2F
                    DAMactualRegion(1,hour) = sum(ms.Pg(25:29,hour))+...
                                        sum(ms.Pg(40:44,hour))+...
                                        sum(ms.Pg(55:59,hour));
                %GHI
                    DAMactualRegion(2,hour) = sum(ms.Pg(15:16,hour))+ms.Pg(22,hour)+...
                                        sum(ms.Pg(30:31,hour))+ms.Pg(37,hour)+...
                                        sum(ms.Pg(45:46,hour))+ms.Pg(52,hour);
                %NYC
                    DAMactualRegion(3,hour) = sum(ms.Pg(17:19,hour))+...
                                        sum(ms.Pg(32:34,hour))+...
                                        sum(ms.Pg(47:49,hour));
                %LIs
                    DAMactualRegion(4,hour) = sum(ms.Pg(20:21,hour))+...
                                        sum(ms.Pg(35:36,hour))+...
                                        sum(ms.Pg(50:51,hour));
            end
        %% DAM curtailment by region
            DAMcurtRegion = DAMschedRegion - DAMactualRegion;
        %% Initialize
            DAM_CElimit = ones(1,25).*lims_Array(BoundedIF,3);
        %% Make Figure
            if printCurt == 1
                hFigE = figure(3); set(hFigE, 'Position', [450 50 650 450]) %Pixels: from left, from bottom, across, high
            %% A -- Curtailment by Region 
                A1 = subplot(2,1,1); hold on;
                    A2 = get(A1,'position'); A2(4) = A2(4)*.80; A2(2) = A2(2)*1; set(A1, 'position', A2); A2(3) = A2(3)*0.75; set(A1, 'position', A2);
                    bar([DAMcurtRegion(1,1:24);DAMcurtRegion(2,1:24);DAMcurtRegion(3,1:24);DAMcurtRegion(4,1:24);].','stacked','FaceAlpha',.5)
                    ylabel('Real Power (MW)')
                axis([0.5,24.5,0,2000]); 
%                 axis 'auto y';
                title('Curtailment by Region')
                A3 = legend('A2F','GHI','NYC','LIs');
                reorderLegendbar([1 2 3 4])
                rect = [.8, 0.6, 0.15, .2]; %[left bottom width height]
                set(A3, 'Position', rect)
                    xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
                    xticklabels({'0' '4' '8' '12' '16' '20' '24'})
%                 set(gca, 'YTick', [0 250 500 1000])
%                     xlabel('Time (hours)')
                    ylabel('Curtailment (MW)')
                    grid on; grid minor; box on; hold off 
            %% B -- Central-East Interface Flows
                B1 = subplot(2,1,2); hold on;
                    B2 = get(B1,'position'); B2(4) = B2(4)*.80; B2(2) = B2(2)*1.4; set(B1, 'position', B2); B2(3) = B2(3)*0.75; set(B1, 'position', B2);
                    bar([DAMifFlows(1:24,3);].')
                    plot(1:25,DAM_CElimit)
                    ylabel('Real Power (MW)')
                axis([0.5,24.5,0,4000]); 
%                 axis 'auto y';
                title('Central-East Interface Flow')
                B3 = legend('CE Flow', 'Limit');
                reorderLegendarea([1 2])
                rect = [.8, 0.3, 0.15, .05]; %[left bottom width height]
                set(B3, 'Position', rect)
                    xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
                    xticklabels({'0' '4' '8' '12' '16' '20' '24'})
%                 set(gca, 'YTick', [0 250 500 1000])
                    xlabel('Time (hours)')
                    ylabel('Real Power (MW)')
                    grid on; grid minor; box on; hold off 
            %% Save to a word file
%                 % Capture current figure/model into clipboard:
%                       matlab.graphics.internal.copyFigureHelper(hFigE)
%                 % Find end of document and make it the insertion point:
%                     end_of_doc = get(word.activedocument.content,'end');
%                     set(word.application.selection,'Start',end_of_doc);
%                     set(word.application.selection,'End',end_of_doc); 
%                 % Paste the contents of the Clipboard:
%                     invoke(word.Selection,'Paste');
                close all
            end
            
    %% Debug MW and LMP values
        %DAM MW - Load
            DAM_MW_Load = zeros(24,1);
            for hour = 1:24 
                for bus = 1:52
                    DAM_MW_Load(hour,1) = DAM_MW_Load(hour,1) + most_busload_DAM(hour,bus);
                end
            end
        %DAM MW - Gen
            DAM_MW_Gen = zeros(24,1);
            for hour = 1:24 
                for gen = 1:59
                    DAM_MW_Gen(hour,1) = DAM_MW_Gen(hour,1) + ms.Pg(gen,hour);
                end
            end
        %Calculate Error
            DAM_MW_error = DAM_MW_Load - DAM_MW_Gen
            
%% Real Time
 dubugIfNeeded = 1;
    %% Initialize
        %Real Time Interval 
            RT_int = 1;
        %Startup notification time
                                 %  1  2  3  4  5  6  7  8  9 10  11  12  13   14
            gen_startuptime_hrs = [48 36 24 18 12 10 10 10 10 2   2  1/12 1/12 2]; %Time in Hours (DO NOT USE DECIMALS!  MUST BE FRACTIONS!)
            gen_startuptime = gen_startuptime_hrs.*12 -1; %Time in number of 5 min periods
        %Gather DAM UC results
            DAM_UC_Results = mdo.UC.CommitSched(1:therm_gen_count,:); %columns = hours, rows = units
        %Create Hour Bin
            hourbin = zeros(24,3);
            hourbin(1:24,1) = linspace(1,24,24);
            hourbin(1:24,2) = 1+ (hourbin(1:24,1)-1).*12;
            hourbin(1:24,3) = hourbin(1:24,1).*12;
        %number of periods in an RTC run
            most_period_count_RTC = RTC_periods;
        %Min Run Time
            MinRunTime = xgd.MinUp(1:therm_gen_count).*12;
            MinDownTime = xgd.MinDown(1:therm_gen_count).*12;
    %% Curtailment by Region
        %% RTC Scheduled renewable output by region
            RTMschedRegion = zeros(4,288);
            for int = 1:288
                %A2F
                    RTMschedRegion(1,int) = sum(most_bus_rengen_hydro(int,11:15))+...
                                             sum(most_bus_rengen_windy(int,11:15))+...
                                             sum(most_bus_rengen_other(int,11:15));
                %GHI
                    RTMschedRegion(2,int) = sum(most_bus_rengen_hydro(int,1:2))+most_bus_rengen_hydro(int,8)+...
                                             sum(most_bus_rengen_windy(int,1:2))+most_bus_rengen_windy(int,8)+...
                                             sum(most_bus_rengen_other(int,1:2))+most_bus_rengen_other(int,8);
                %NYC
                    RTMschedRegion(3,int) = sum(most_bus_rengen_hydro(int,3:5))+...
                                             sum(most_bus_rengen_windy(int,3:5))+...
                                             sum(most_bus_rengen_other(int,3:5));
                %LIs
                    RTMschedRegion(4,int) = sum(most_bus_rengen_hydro(int,6:7))+...
                                             sum(most_bus_rengen_windy(int,6:7))+...
                                             sum(most_bus_rengen_other(int,6:7));
            end
    %% Loose vs. Tight (1)
    %Tight
%             MinRunTime(12:13) = 6;
%             MinDownTime(12:13) = 6;
           
    %Loose
            MinRunTime(12:13) = 1;
            MinDownTime(12:13) = 1;
%             
%             MinRunTime(10:11) = 1;
%             MinDownTime(10:11) = 1;
    %**** SWITCHING FROM TIGHT TO LOOSE?  REMEMBER TO CHANGE THE xgd_DAM FILE TOO!!!

    %% RTC Pass #1
        %Define RTC Time Period
            RTC_int_start = RT_int;
            RTC_int_end = RT_int + most_period_count_RTC -1; 
        %Find applicable DAM Hours
            for hourr =1:24
                if and(RTC_int_start>=hourbin(hourr,2),RTC_int_start<=hourbin(hourr,3))
                    hour_1 = hourbin(hourr);
                    hour_2 = hourbin(hourr+1);
                    hour_3 = hourbin(hourr+2);
                break
                end
            end
        %% Profiles
            %% Load
                most_busload_RTC = most_busload(RTC_int_start:RTC_int_end,:);
            %% Generation
                %% CommitKey
                    %Initialize Committment
                        most_CommitKey_RTC = ones(therm_gen_count,1);
                    %Modify for forced on and off units
                        for genUC = 1:therm_gen_count
                            %first... was there any DAM committment? 
                                DAMvalue = DAM_UC_Results(genUC,hour_1) + DAM_UC_Results(genUC,hour_2) + DAM_UC_Results(genUC,hour_3);
                            %Long Start, no DAM committment... Forced OFF
                                if and(DAMvalue ==0, gen_startuptime_hrs(genUC) >=0.5)
                                    most_CommitKey_RTC(genUC) = -1;
                                end
                        end
                    %Prevent unauthorized operation of LoHi Unit
                        most_CommitKey_RTC(14) = -1;
                    %Hour 1 DAM commitment?... Forced ON
                        for genUC = 1:11 %there are 3 Nukes + 5 Steam plants = 8
                            if mustRun == 1
                                if DAM_UC_Results(genUC,hour_1) == 1
                                    most_CommitKey_RTC(genUC) = 2;
                                end
                            else
                                if DAM_UC_Results(genUC,hour_1) == 1
                                    most_CommitKey_RTC(genUC) = 1;
                                end
                            end
                        end
                    %Kill Nukes
                        for gen = 2:killNuke
                            most_CommitKey_RTC(gen) = -1;
                        end
                %% Time until DAM committment (if any)
                    %Time till next hour
                        timeTillHour = hourbin(hour_2,2) - RTC_int_start;
                    %Time till next DAM commitment (if any)
                        %initialize arrays
                            timeTillDAM = zeros(therm_gen_count,1);
                            hrsTillDAM  = zeros(therm_gen_count,1);
                            flagg = 0;
                        %calculate for each generator
                            for gen = 1:therm_gen_count
                                %if committed in Hour_1 then step out
                                    if DAM_UC_Results(gen,hour_1) == 1
                                        timeTillDAM(gen) = 0;
                                    else
                                        %if not committed in hour 1, look beyond Hour_1 
                                            for hourr = hour_2:24
                                                %if committed in a future hour
                                                    if DAM_UC_Results(gen,hourr) == 1
                                                        hrsTillDAM(gen) = hourr - hour_2;
                                                        flagg = 1;
                                                    end
                                                %step out... don't consider future hours
                                                    if flagg == 1
                                                        flagg = 0;
                                                        break;
                                                    end
                                            end
                                        %if not committed all day 
                                            if hourr == 24
                                                hrsTillDAM(gen) = 24;
                                            end
                                            timeTillDAM(gen) = hrsTillDAM(gen)*12 + timeTillHour;
                                    end
                            end
                %% Initial State
                    for gen = 1:therm_gen_count
                        %for gens with CommitKey = 2
                            if  most_CommitKey_RTC(gen) == 2
                                most_InitialState_RTC(gen) = MinRunTime(gen);
                        %for gens with CommitKey = -1 or 0
                            else
                                most_InitialState_RTC(gen) = sign(most_CommitKey_RTC(gen))*min(timeTillDAM(gen),gen_startuptime(gen)) - MinDownTime(gen);
                            end
                        %for gens with CommitKey = 1
                            if most_CommitKey_RTC(gen) == 1
                                most_InitialState_RTC(gen) = 300;
                            end
                    end
                %Save for 2nd RTC Run
                    Previous_RTC_InitState = most_InitialState_RTC.';
        %% Populate MOST Data & Options
            %Add Network Model: Bus, Gen, Branch, Gen_Cost
                define_constants
                casefile = 'case_nyiso16';
                mpc = loadcase(casefile);
                xgd = loadxgendata('xgd_RTC' , mpc);
            %Reduce the Ramp!
                if IncreasedRTCramp_Steam == 1
                    for col = 17:19
                        mpc.gen(4:8,col) = mpc.gen(4:8,col).*RTCrampFactor_Steam;
                    end
                end 
                if IncreasedRTCramp_CC == 1
                    for col = 17:19
                        mpc.gen(10:11,col) = mpc.gen(10:11,col).*RTCrampFactor_CC;
                    end
                end 
            %Drop the mingen
                if droppit== 1
                    mpc.gen(1:therm_gen_count,10) = mpc.gen(:,10)./10;
                end
            %Min Run/Down Time
                xgd.MinUp = MinRunTime;
                xgd.MinDown = MinDownTime;
            %Reduce the min down time
                if minrunshorter == 1
                    for gen = 1:14
                        xgd.MinDown(gen) = floor(xgd.MinDown(gen)/10);
                    end
                end
            %CommitKey (-1, 0/1, 2)
                xgd.CommitKey = most_CommitKey_RTC;
            %InitialState (periods on/off line)
                xgd.InitialState = most_InitialState_RTC.';
        %% Add transmission interface limits
            if IFlims == 1
                mpc.if.map = map_Array;
                mpc.if.lims  = lims_Array;
                mpc = toggle_iflims_most(mpc, 'on');            
            end
        %% Add EVSE Load
    if EVSE == 1
       %% Initialize
            clear storage
                %Tables
                    storage.gen             = zeros(BatCount,21);
                    storage.sd_table.data   = zeros(BatCount,13);
                    storage.xgd_table.data  = zeros(BatCount,2);
                    storage.gencost         = zeros(BatCount, 7);
                    MinStorageLevelPROFILE = zeros(32,RTC_periods);
                %StorageData Parameters
                    storage.sd_table.OutEff				= 1;
                    storage.sd_table.InEff				= 1;
                    storage.sd_table.LossFactor			= 0;
                    storage.sd_table.rho				= 0;
                    storage.sd_table.colnames = {
                        'InitialStorage', ...
                            'InitialStorageLowerBound', ...
                                'InitialStorageUpperBound', ...
                                    'InitialStorageCost', ...
                                        'TerminalStoragePrice', ...
                                            'MaxStorageLevel', ...
                                                'MinStorageLevel', ...
                                                    'OutEff', ...
                                                        'InEff', ...
                                                            'LossFactor', ...
                                                                'rho', ...
                                                                    'ExpectedTerminalStorageMin',...
                                                                        'ExpectedTerminalStorageMax',...
                    };

                    storage.xgd_table.colnames = {
                        'CommitKey', ...
                            'CommitSched', ...
                            };    
       %% Create Battery Data Containers     
                for Bat = 1:BatCount
                    %% Which Region are we in?
                        if sum(ismember(NYCA_Load_buses(Bat),A2F_Load_buses)) > 0
                            Region = 1; %Region 1 is A2F
                        else
                            if sum(ismember(NYCA_Load_buses(Bat),GHI_Load_buses)) >0
                                Region = 2; %Region 2 is GHI
                            else
                                if sum(ismember(NYCA_Load_buses(Bat),NYC_Load_buses)) >0
                                    Region = 3; %Region 3 is NYC
                                else
                                    if sum(ismember(NYCA_Load_buses(Bat),LIs_Load_buses)) >0
                                        Region = 4; %Region 4 is Long Island
                                    else
                                        Region = 5;
                                    end
                                end
                            end
                        end
                    %% Add individual battery parameters
                                           % bus            Qmin    mBase   Pmax    Pc1     Qc1min	Qc2min	ramp_agc	ramp_q
                                           % 	Pg	Qg	Qmax	Vg      status	   Pmin	Pc2     Qc1max	Qc2max	ramp_10     apf
                                           %                                                                        ramp_30	
                       storage.gen(Bat,:) = [NYCA_Load_buses(Bat)...
                                                0   0   0   0   1   100 1 -0.00001 -EVSE_Region_Ind_MW(Region) ...
                                                                                    0   0   0   0   0   0   0   0   EVSE_Region_Ind_MW(Region)   0   0];
                    %% Calculate RTC EVSE MWh
                        RTCtotalEVSEload = zeros(32,288);
                        for EV = 1:32
%                             EVSEloadRTC(EV,RT_int) = sum(12*EVSEloadDAM(EV,1)+12*EVSEloadDAM(EV,2)+0.5*6*EVSEloadDAM(EV,3));
                            RTCtotalEVSEload(EV,RT_int) = sum(DAMEVSEload(EV,1)+DAMEVSEload(EV,2)+.5*DAMEVSEload(EV,3));
                        end
                    %% Add storage data
                                                        %1 InitialStorage
                                                            %2 InitialStorageLowerBound
                                                                %3 InitialStorageUpperBound
                                                                    %4 InitialStorageCost
                                                                        %5 TerminalStoragePrice
                                                                            %6 MaxStorageLevel
                                                                                %7 MinStorageLevel
                                                                                    %8 OutEff
                                                                                        %9 InEff
                                                                                            %10 LossFactor
                                                                                                %11 rho
                                                                                                    %12 Expected Terminal Storage Min
                                                                                                        %13 Expected Terminal Storage Max
                                                        %1   2   3   4   5  6   7    8   9   10  11  12                13
                       storage.sd_table.data(Bat,:) =   [0   0   0   0   0  -RTCtotalEVSEload(Bat,RT_int),...
                                                                                0    1   1   0   0   -RTCtotalEVSEload(Bat,RT_int) -RTCtotalEVSEload(Bat,RT_int)];
                    %% Add storage XGD data
                                                        %1 CommitKey
                                                            %2 CommitSched
                                                                %3 PositiveActiveReservePrice
                                                                    %4 PositiveActiveReserveQuantity
                                                                        %5 NegativeActiveReservePrice
                                                                            %6 NegativeActiveReserveQuantity
                                                                                %7 PositiveActiveDeltaPrice
                                                                                    %8 NegativeActiveDeltaPrice
                                                                                        %9 PositiveLoadFollowReservePrice
                                                                                            %10 PositiveLoadFollowReserveQuantity
                                                                                                %11 NegativeLoadFollowReservePrice
                                                                                                    %12 NegativeLoadFollowReserveQuantity
                                                        %1   2   3   4   5   6   7   8   9   10  11  12
                       storage.xgd_table.data(Bat,:) = [2    1  ];% 0   0   0   0   0   0   0   0   0   0];
                    %% Add storage cost data
                                         %2	startup	n	c(n-1)	...	c0
                                         %      shutdown
                        storage.gencost(Bat,:) = [2	0	0	2	0 0 0]; 
                    %% Min Storage Level
                        %Set targets at top of every hour
%                         MinStorageLevelPROFILE(Bat,  1:11) =  0;
%                         MinStorageLevelPROFILE(Bat, 12:23) = -EVSEloadDAM(Bat,1);
%                         MinStorageLevelPROFILE(Bat, 24:29) = -EVSEloadDAM(Bat,1) - EVSEloadDAM(Bat,2);
%                         MinStorageLevelPROFILE(Bat, 30   ) = -EVSEloadDAM(Bat,1) - EVSEloadDAM(Bat,2) - 0.5*EVSEloadDAM(Bat,3);
                        %Set 1 target at end of 2.5 hours
                        MinStorageLevelPROFILE(Bat, RTC_periods   ) = -RTCtotalEVSEload(Bat,RT_int);
                end
    end
        %% Add Profiles
            %% WIND
                %Add wind Generators
                    [iwind, mpc, xgd] = addwind('wind_gen' , mpc, xgd);
                %Add empty max & min profiles
                    clear profiles
                    profiles = getprofiles('wind_profile_Pmax' , 15:29); 
                    profiles = getprofiles('wind_profile_Pmin' , profiles);
                    profiles(1).values(:,1,:) = most_bus_rengen_windy(RTC_int_start:RTC_int_end,:);
                    if windyCurt == 1
                        profiles(2).values(:,1,:) = most_bus_rengen_windy(RTC_int_start:RTC_int_end,:).*windyCurtFactor;
                    else
                        profiles(2).values(:,1,:) = most_bus_rengen_windy(RTC_int_start:RTC_int_end,:);
                    end
            %% HYDRO
                %Add hydro Generators
                    [ihydro, mpc, xgd] = addwind('hydro_gen' , mpc, xgd);
                %Add empty max & min profiles
                    profiles = getprofiles('hydro_profile_Pmax' , profiles); 
                    profiles = getprofiles('hydro_profile_Pmin' , profiles);
                    profiles(3).values(:,1,:) = most_bus_rengen_hydro(RTC_int_start:RTC_int_end,:);
                    if hydroCurt == 1
                        profiles(4).values(:,1,:) = most_bus_rengen_hydro(RTC_int_start:RTC_int_end,:).*hydroCurtFactor;
                    else
                        profiles(4).values(:,1,:) = most_bus_rengen_hydro(RTC_int_start:RTC_int_end,:);
                    end
            %% OTHER
                %Add other Generators
                    [iother, mpc, xgd] = addwind('other_gen' , mpc, xgd);
                %Add empty max & min profiles
                    profiles = getprofiles('other_profile_Pmax' , profiles); 
                    profiles = getprofiles('other_profile_Pmin' , profiles);
                    profiles(5).values(:,1,:) = most_bus_rengen_other(RTC_int_start:RTC_int_end,:);
                    if otherCurt == 1
                        profiles(6).values(:,1,:) = most_bus_rengen_other(RTC_int_start:RTC_int_end,:).*otherCurtFactor;
                    else
                        profiles(6).values(:,1,:) = most_bus_rengen_other(RTC_int_start:RTC_int_end,:);
                    end
            %% Load 
                    profiles = getprofiles('load_profile' , profiles);
                    profiles(7).values(:,1,:) = most_busload(RTC_int_start:RTC_int_end,:);
            %% Initial Pg
                %Renewables
                    xgd.InitialPg(15:29) = most_bus_rengen_windy(RTC_int_start,:);
                    xgd.InitialPg(30:44) = most_bus_rengen_hydro(RTC_int_start,:);
                    xgd.InitialPg(45:59) = most_bus_rengen_other(RTC_int_start,:);
                %Thermal
                    xgd.InitialPg(1:14) = gen_output(1:14,1);
            %% Therm Max and Min Gen Profiles for 1st interval
                    profiles = getprofiles('Nuke_DAM_profile_Pmax' , profiles); 
                    profiles = getprofiles('Nuke_DAM_profile_Pmin' , profiles); 
                %Create Max and Min Gen Profile Values (Nuke and Steam Units only)
                    therm_Pmax_RTC_Profile = zeros(most_period_count_RTC,8);
                    therm_Pmin_RTC_Profile = zeros(most_period_count_RTC,8);
                    for gen = 1:8 
                        %First period limits
                            therm_Pmax_RTC_Profile(1,gen) = gen_output(gen,1); %plus 
                            therm_Pmin_RTC_Profile(1,gen) = gen_output(gen,1);
                        %Normal Values for other periods
                            for intt = 2:most_period_count_RTC
                                therm_Pmax_RTC_Profile(intt,gen) = mpc.gen(gen,9);
                                therm_Pmin_RTC_Profile(intt,gen) = mpc.gen(gen,10);                                   
                            end
                    end
                %Assign Values to Profiles
                    profiles(8).values(:,1,:) = therm_Pmax_RTC_Profile(1:most_period_count_RTC,:);
                    profiles(9).values(:,1,:) = therm_Pmin_RTC_Profile(1:most_period_count_RTC,:);
            %% EVSE Parameters
            if EVSE == 1
                %% Push Battery Data to MOST
                    [~,mpc,xgd,storage] = addstorage(storage,mpc,xgd);
                %% EVSE Initial Pg
                    xgd.InitialPg(60:91) = -0.00001;
                %% EVSE Pmin and Pmax limits
                    profiles = getprofiles('EVSE_profile_MinLvl' , profiles);    
                %% Add EVSE Profile
                    profiles(10).values(:,1,:) = MinStorageLevelPROFILE.';
            end
        %Determine number of intervals in the simulation
            nt = most_period_count_RTC; % number of period    
        %% Set Options
            %Set options
                mpopt = mpoption;
                mpopt = mpoption(mpopt,'most.dc_model', 1); % use DC network model (default)
    %             mpopt = mpoption(mpopt,'most.solver', 'GUROBI');
                mpopt = mpoption(mpopt, 'verbose', 0);
                mpopt = mpoption(mpopt,'most.skip_prices', 1);
        %% Set $-5/MWh renewable cost to avoid curtailment
            mpc.gencost(15:29,6) = REC_Cost;
            mpc.gencost(30:44,6) = REC_hydro;
            mpc.gencost(45:59,6) = REC_Cost;
            mpc.gencost(15:59,4) = 3;
        %% Load all data
                clear mdi
            %EVSE
            if EVSE == 1
                numm = 91;
                mdi = loadmd(mpc, nt, xgd, storage, [], profiles);
                %% Modify Index for EVSE
                    mdi.Storage.UnitIdx(1:32) = [60:91];
            else
                numm = 59;
                mdi = loadmd(mpc, nt, xgd, [], [], profiles);
            end
                mdi.RampWearCostCoeff = zeros(numm,RTC_periods);
            %Set Time period
                mdi.Delta_T = 5/60;
            %Set Ramp Costs = 0
                for tt = 1:RTC_periods
                    mdi.offer(tt).PositiveActiveReservePrice = zeros(numm,1);
                    mdi.offer(tt).NegativeActiveReservePrice = zeros(numm,1);
                    mdi.offer(tt).PositiveActiveDeltaPrice = zeros(numm,1);
                    mdi.offer(tt).NegativeActiveDeltaPrice = zeros(numm,1);
                    mdi.offer(tt).PositiveLoadFollowReservePrice = zeros(numm,1);
                    mdi.offer(tt).NegativeLoadFollowReservePrice = zeros(numm,1);
                end
    %% Run Algorithm
            %Run the UC/ED algorithm
                clear mdo
                if IFlims == 1
                    mdo = most_if(mdi, mpopt);
                else
                    mdo = most(mdi, mpopt);
                end
            %View Results
                clear ms
                ms = most_summary(mdo); % print results, depending on verbose  option
    %% Analyze Results
             %% Initialize
                RTC_str = num2str(RT_int, '%03i');
                RTIntstring = strcat('RT Int:  ', RTC_str);
                gen_output_percent_all = zeros(therm_gen_count,RTC_periods);
                Hydro_actualGen = zeros(1,288);
                Hydro_schedGen = zeros(1,288);
                HydroCurtailment = zeros(1,288);
                NukeGen = zeros(1,288);
                SteamGen = zeros(1,288);
                CCGen = zeros(1,288);
                GTGen = zeros(1,288);
                LOHIGen = zeros(1,288);
                RenGen_windy = zeros(1,288);
                RenGen_hydro = zeros(1,288);
                RenGen_other = zeros(1,288);
                BTM4Graph = zeros(1,288);
            %% Interface Flows 
                RTMifFlows = nan(288,4);
                for int = RTC_int_start:RTC_int_start+2
                    RTMifFlows(int,1) = ms.Pf(1,int)  - ms.Pf(16,int);
                    RTMifFlows(int,2) = ms.Pf(1,int)  - ms.Pf(16,int) + ms.Pf(86,int); 
                    RTMifFlows(int,3) = ms.Pf(7,int)  + ms.Pf(9,int)  + ms.Pf(13,int); 
                    RTMifFlows(int,4) = ms.Pf(28,int) + ms.Pf(29,int);
                end
            %% EVSE Load
                if EVSE == 1
                    EVSEloadRTD = zeros(32,288);
                    for int = 1:3
                        EVSEloadRTD(1:32,int) = mdo.Storage.ExpectedStorageDispatch(1:32,int);
                    end
                end
    %% Gather Renewable Output for temporary display of 30 values
        %create values
            demand1(1:RTC_periods) = demand(RTC_int_start:RTC_int_end);
            NetLoad(1:RTC_periods) = NYCA_CASE_net_load(RTC_int_start:RTC_int_end);
            TrueLoad(1:RTC_periods) = NYCA_TrueLoad(RTC_int_start:RTC_int_end);
            RenGen_hydro1 = zeros(1,RTC_periods);
            RenGen_windy1 = zeros(1,RTC_periods);
            RenGen_other1 = zeros(1,RTC_periods);
            BTM4Graph1 = zeros(1,RTC_periods);
        %gather values
            for iter = 1:RTC_periods
                    for renge = 15:29
                        RenGen_windy1(iter) = RenGen_windy1(iter) + ms.Pg(renge,iter);
                    end
                    for renge = 30:44
                        RenGen_hydro1(iter) = RenGen_hydro1(iter) + ms.Pg(renge,iter);
                    end
                    for renge = 45:59
                        RenGen_other1(iter) = RenGen_other1(iter) + ms.Pg(renge,iter);
                    end
                BTM4Graph1(iter) = TrueLoad(iter) - NetLoad(iter);
            end            
    %% Gather Gen Output in percent
        gen_output = ms.Pg;
        gen_capacity = mpc.gen(:,9);
        for gen = 1:length(gen_capacity)
            for periodd = 1:RTC_periods
                gen_output_percent_all(gen,periodd) = gen_output(gen,periodd)/gen_capacity(gen);
            end
        end
        gen_output_percent_all(isnan(gen_output_percent_all)) = 0;
    %Modify % output to show offline/online units
        for gen = 1:therm_gen_count
            for time = RTC_int_start:RTC_int_end
                %offline
                if gen_output_percent_all(gen,time) == 0
                    gen_output_percent_all(gen,time) = -gen*.01;
                else
                    %at max
                    if gen_output_percent_all(gen,time) == 1
                        gen_output_percent_all(gen,time) = 1+gen*.01;
%                         else
%                             %in between... Do nothing
                    end
                end
            end
        end

    %Curtailed Hydro
        for ttime = RTC_int_start:RTC_int_end
            Hydro_actualGen(ttime) = sum(ms.Pg(30:44,ttime))/(A2F_2016_ITM_hydro_ICAP + A2F_ITM_CASE_hydro_cap + GHI_ITM_CASE_hydro_cap + NYC_ITM_CASE_hydro_cap + LIs_ITM_CASE_hydro_cap);
            Hydro_schedGen(ttime) = sum(most_bus_rengen_hydro(ttime,:))/(A2F_2016_ITM_hydro_ICAP + A2F_ITM_CASE_hydro_cap + GHI_ITM_CASE_hydro_cap + NYC_ITM_CASE_hydro_cap + LIs_ITM_CASE_hydro_cap);
            HydroCurtailment(ttime) = Hydro_schedGen(ttime) - Hydro_actualGen(ttime);
        end
    %% Gather Gen Output by Type - RTC
        for iter = RT_int:RT_int+most_period_count_RTC-1
            run = iter-RT_int+1;
            NukeGen(iter) = ms.Pg(1,run)+ms.Pg(2,run)+ms.Pg(3,run); %NUKE
            SteamGen(iter) = ms.Pg(4,run)+ms.Pg(5,run)+ms.Pg(6,run)+ms.Pg(7,run)+ms.Pg(8,run);%STEAM
            CCGen(iter) = ms.Pg(10,run)+ms.Pg(11,run);%CC
            GTGen(iter) = ms.Pg(12,run)+ms.Pg(13,run);%GT
            LOHIGen(iter) = ms.Pg(14,run); %Lo High Unit
            RenGen_windy(iter) = 0;
            for renge = 15:29
                RenGen_windy(iter) = RenGen_windy(iter) + ms.Pg(renge,run);
            end
            RenGen_hydro(iter) = 0;
            for renge = 30:44
                RenGen_hydro(iter) = RenGen_hydro(iter) + ms.Pg(renge,run);
            end
            RenGen_other(iter) = 0;%RENEWABLE
            for renge = 45:59
                RenGen_other(iter) = RenGen_other(iter) + ms.Pg(renge,run);
            end
            BTM4Graph(iter) = TrueLoad(run) - NetLoad(run);
        end
        %% Plot RTC1
            %% Initialize
                % Intervals
                    BigTime = most_period_count_RTC;
                    Time4Graph = linspace(0,RTC_hrs,BigTime);
            if printRTC == 1
                %% Make Figure
                    hFigA = figure(2); set(hFigA, 'Position', [450 50 650 850]) %Pixels: from left, from bottom, across, high
                    %% A -- True Load, Net Load, Demand
                        A1 = subplot(4,1,1); hold on;
                        A2 = get(A1,'position'); A2(4) = A2(4)*.85; A2(3) = A2(3)*1; set(A1, 'position', A2);
                            plot(Time4Graph(1:RTC_periods),NYCA_TrueLoad(RTC_int_start:RTC_int_end)./1000,'LineStyle','-','color',[0 .447 .741],'marker','*')
                            plot(Time4Graph(1:RTC_periods),NYCA_CASE_net_load(RTC_int_start:RTC_int_end)./1000,'LineStyle','--','color','red','marker','x')
                            plot(Time4Graph,demand(RTC_int_start:RTC_int_end)./1000,'LineStyle','-','color',[.494 .184 .556],'marker','d','markeredgecolor',[.494 .184 .556])
                            area(Time4Graph,[demand1;RenGen_windy1; RenGen_hydro1; RenGen_other1; BTM4Graph1;].'./1000,'FaceAlpha',.5)
                        title('True Load, Net Load, & Demand')
    %                     A3 = legend('True Load', 'Net Load', 'Demand','Demand', 'Wind','Hydro', 'Other Ren', 'BTM Ren');      
    %                         reorderLegendarea([8 1 7 2 3 4 5 6])
    %                         rect = [.8, 0.77, 0.15, 0.0875]; %[left bottom width height]
    %                         set(A3, 'Position', rect)
                        axis([0,RTC_hrs,0,20]); 
                            set(gca, 'YTick', [0 5 10 15 20])
    %                         axis 'auto y';
                            ylabel('Real Power (GW)')
                            set(gca, 'XTick', Time4Graph);
                            set(gca, 'xticklabel', {'0', ' ', ' ', ' ', ' ', ' ','0.5',  ' ', ' ', ' ', ' ', ' ', '1' , ' ', ' ', ' ', ' ', ' ', '1.5'...
                                                       , ' ', ' ', ' ', ' ', ' ','2', ' ', ' ', ' ', ' ', '2.5'})
%                             set(gca, 'xticklabel', {'0', ' ', ' ', ' ', ' ', ' ','1',  ' ', ' ', ' ', ' ', ' ', '2' , ' ', ' ', ' ', ' ', ' ', '3'...
%                                                        , ' ', ' ', ' ', ' ', ' ','4', ' ', ' ', ' ', ' ', '5'})
                            grid on; box on; hold off 
                    %% B -- Generator Output (%)
                        B1 = subplot(4,1,2); hold on;
                            B2 = get(B1,'position'); B2(4) = B2(4)*.85; B2(2) = B2(2)*1; set(B1, 'position', B2); B2(3) = B2(3)*1; set(B1, 'position', B2);
                            plot(Time4Graph,gen_output_percent_all(1,1:RTC_periods),'LineStyle',':','color',[0 .447 .741])
                            plot(Time4Graph,gen_output_percent_all(2,1:RTC_periods),'LineStyle',':','color',[.635 .078 .184])
                            plot(Time4Graph,gen_output_percent_all(3,1:RTC_periods),'LineStyle',':','color',[.85 .325 .098])
                            plot(Time4Graph,gen_output_percent_all(4,1:RTC_periods),'LineStyle','--','color',[0 .447 .741])
                            plot(Time4Graph,gen_output_percent_all(5,1:RTC_periods),'LineStyle','--','color',[.301 .745 .933])
                            plot(Time4Graph,gen_output_percent_all(6,1:RTC_periods),'LineStyle','--','color',[.635 .078 .184])
                            plot(Time4Graph,gen_output_percent_all(7,1:RTC_periods),'LineStyle','--','color',[.494 .184 .556])
                            plot(Time4Graph,gen_output_percent_all(8,1:RTC_periods),'LineStyle','--','color',[.466 .674 .188])
                            plot(Time4Graph,gen_output_percent_all(10,1:RTC_periods),'LineStyle','-.','color',[0 .447 .741])
                            plot(Time4Graph,gen_output_percent_all(11,1:RTC_periods),'LineStyle','-.','color',[.494 .184 .556])
                            plot(Time4Graph,gen_output_percent_all(12,1:RTC_periods),'LineStyle','-','color',[.494 .184 .556])
                            plot(Time4Graph,gen_output_percent_all(13,1:RTC_periods),'LineStyle','-','color',[.466 .674 .188])
    %                         B3 = legend('Nuke A2F','Nuke GHI','Nuke GHI','Steam A2F','Steam A2F','Steam GHI','Steam NYC','Steam LI',...
    %                                     'CC A2F','CC NYC','GT NYC','GT LI')                        
                            title('RTC Generation (% Of Nameplate)')
    %                         rect = [.8, 0.49, 0.15, .12]; %[left bottom width height]
    %                         set(B3, 'Position', rect)
                            ylabel('Real Power (%)')
                            axis([0,RTC_hrs,-0.16,1]); 
                            set(gca, 'YTick', [0 0.25 0.5 0.75 1])
                            set(gca, 'yticklabel', {'0', '25', '50', '75', '100'})
                            set(gca, 'XTick', Time4Graph);
                            set(gca, 'xticklabel', {'0', ' ', ' ', ' ', ' ', ' ','0.5',  ' ', ' ', ' ', ' ', ' ', '1' , ' ', ' ', ' ', ' ', ' ', '1.5'...
                                                       , ' ', ' ', ' ', ' ', ' ','2', ' ', ' ', ' ', ' ', '2.5'})
%                             set(gca, 'xticklabel', {'0', ' ', ' ', ' ', ' ', ' ','1',  ' ', ' ', ' ', ' ', ' ', '2' , ' ', ' ', ' ', ' ', ' ', '3'...
%                                                        , ' ', ' ', ' ', ' ', ' ','4', ' ', ' ', ' ', ' ', '5'})
                            grid on; box on; hold off 
                    %% C -- Generation by Type - RTC
                        C1 = subplot(4,1,3); hold on;
                            C2 = get(C1,'position'); C2(4) = C2(4)*.85; C2(2) = C2(2)*1; set(C1, 'position', C2); C2(3) = C2(3)*1; set(C1, 'position', C2);
                            area(1:288,[NukeGen;SteamGen;CCGen;GTGen;RenGen_windy;RenGen_hydro;RenGen_other;BTM4Graph;].'./1000,'FaceAlpha',.5)
    %                         C3 = legend('Nuke', 'Steam', 'CC', 'GT', 'Wind', 'Hydro', 'Other Ren', 'BTM');
    %                         reorderLegendarea([1 2 3 4 5 6 7 8]) 
                            title('RTC Generation By Type')
    %                         rect = [.8, 0.23, 0.15, .12]; %[left bottom width height]
    %                         set(C3, 'Position', rect)
                            ylabel('Real Power (GW)')
                            axis([0,288,0,20]); 
                            set(gca, 'YTick', [0 5 10 15 20])
                            set(gca, 'XTick', [0 12 24 36 48 60 72 84 96 108 120 132 144 156 168 180 192 204 216 228 240 252 264 276 288]);
                            set(gca, 'xticklabel', {'0', ' ', ' ', ' ','4', ' ', ' ', ' ', '8', ' ', ' ', ' ', '12', ' ', ' ', ' ', '16', ' ', ' ', ' ', '20', ' ', ' ', ' ', '24'})
                            grid on; box on; hold off 
                    %% D -- Generation by Type - RTD
                        D1 = subplot(4,1,4); hold on;
                            D2 = get(D1,'position'); D2(4) = D2(4)*.85; D2(2) = D2(2)*1; set(D1, 'position', D2); D2(3) = D2(3)*1; set(D1, 'position', D2);
    %                         area(1:288,[NukeGenRTD;SteamGenRTD;CCGenRTD;GTGenRTD;RenGen_windyRTD;RenGen_hydroRTD;RenGen_otherRTD;BTM4GraphRTD;].'./1000,'FaceAlpha',.5)
                            title('RTD Generation By Type')
                            ylabel('Real Power (GW)')
                            xlabel('Time (Hour Beginning)');
                            axis([0,288,0,20]); 
                            set(gca, 'YTick', [0 5 10 15 20])
                            set(gca, 'XTick', [0 12 24 36 48 60 72 84 96 108 120 132 144 156 168 180 192 204 216 228 240 252 264 276 288]);
                            set(gca, 'xticklabel', {'0', ' ', ' ', ' ','4', ' ', ' ', ' ', '8', ' ', ' ', ' ', '12', ' ', ' ', ' ', '16', ' ', ' ', ' ', '20', ' ', ' ', ' ', '24'})
                            grid on; box on; hold off 
                %% Graph Title (Same for all graphs)
                First_Line_Title = [datestring(5:6), ' ', datestring(7:8), ', ', Case_Name_String,', ', RTIntstring];
                ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off',...
                    'Units','normalized', 'clipping' , 'off');
                text(0.5, 1.0,[{'\bf \fontsize{18}' First_Line_Title}], 'HorizontalAlignment' ,...
                    'center', 'VerticalAlignment', 'top')        
                %% Print
                        % Capture current figure/model into clipboard:
                              matlab.graphics.internal.copyFigureHelper(hFigA)
                        % Find end of document and make it the insertion point:
                            end_of_doc = get(word.activedocument.content,'end');
                            set(word.application.selection,'Start',end_of_doc);
                            set(word.application.selection,'End',end_of_doc); 
                        % Paste the contents of the Clipboard:
                            invoke(word.Selection,'Paste');
                close all                 
            end
        %% Plot EVSE
        if EVSE == 1
            EVSEloadRTD_24 = nan(1,288);
            for int = 1:288-6
                EVSEloadRTD_24(1,int+6) = -sum(EVSEloadRTD(1:32,int));
            end
        Time4Graphp = linspace(0,24,288);
            %% Make Graph
                hFigE = figure(19); set(hFigE, 'Position', [250 50 800 400]) %Pixels: from left, from bottom, across, high
                 %% A -- DAM LMP
                    A1 = subplot(2,1,1); hold on;
                    A2 = get(A1,'position'); A2(4) = A2(4)*1; A2(3) = A2(3)*1; A2(2) = A2(2)*1; set(A1, 'position', A2);
                        bar([EVSEloadDAMgraph(1,1:24);EVSEloadDAMgraph(2,1:24);EVSEloadDAMgraph(3,1:24);EVSEloadDAMgraph(4,1:24);].','stacked','FaceAlpha',.5)
                        area(Time4Graphp(1:288),EVSEloadRTD_24,'FaceAlpha',.8)
                        ylabel('Real Power (MW)')
                    axis([0.5,24.5,0,1000]); 
                    axis 'auto y';
                        xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
                        xticklabels({'0' '4' '8' '12' '16' '20' '24'})
    %                     set(gca, 'YTick', [0 250 500 750 1000])
                        grid on; grid minor; box on; hold off 
                %% Save to a word file
            if printRTC == 1
                % Capture current figure/model into clipboard:
                      matlab.graphics.internal.copyFigureHelper(hFigE)
                % Find end of document and make it the insertion point:
                    end_of_doc = get(word.activedocument.content,'end');
                    set(word.application.selection,'Start',end_of_doc);
                    set(word.application.selection,'End',end_of_doc); 
                % Paste the contents of the Clipboard:
                    invoke(word.Selection,'Paste');
            end
            close all     
        end
        
    %% RTDx3
        %% Initialize
            RTD_LMP = NaN(68,288);
            Gen_RTD_OpCost = zeros(59,1);
        %% Gather Data
            %DAM UC results
                RTD_UC_Status = mdo.UC.CommitSched(1:therm_gen_count,1:3);
            %Gen Starts
                %Initialize
                    StartsPerGen = zeros(therm_gen_count,1);
                %Count first interval as a Generator Startup
                    for gen = 1:therm_gen_count
                        if RTD_UC_Status(gen) == 1
                            StartsPerGen(gen) = 1;
                        end
                    end
        %% Loop through RTD Runs    
            for RTDLoop = 1:3
                %% Get data
                    mpc_RTD = mpc;
                %% Remove EVSE as Batteries
                    if EVSE == 1
                        mpc_RTD.gen(60:91,:) = []; %Make their max gen = 0
                        mpc_RTD.genfuel(60:91,:) = [];
                        mpc_RTD.gencost(60:91,:) = [];
                        mpc_RTD.iess = [];
                    end
                %% Ramp Rates
                    %restore ramp rates to original values (from RTC to original)
                        if IncreasedRTCramp_Steam == 1
                            for col = 17:19
                                mpc_RTD.gen(4:8,col) = mpc_RTD.gen(4:8,col)./RTCrampFactor_Steam;
                            end
                        end 
                        if IncreasedRTCramp_CC == 1
                            for col = 17:19
                                mpc_RTD.gen(10:11,col) = mpc_RTD.gen(10:11,col)./RTCrampFactor_CC;
                            end
                        end 
                    %set ramp rates to new RTD values (from original to RTD)
                        if IncreasedRTDramp_Steam == 1
                            for col = 17:19
                                mpc_RTD.gen(4:8,col) = mpc_RTD.gen(4:8,col).*RTDrampFactor_Steam;
                            end
                        end 
                        if IncreasedRTDramp_CC == 1
                            for col = 17:19
                                mpc_RTD.gen(10:11,col) = mpc_RTD.gen(10:11,col).*RTDrampFactor_CC;
                            end
                        end 
                %% Remove offline generators
                    %count offline gens
                        offlineGens = 0;
                        if RT_int ==1
                            for gen = 1:therm_gen_count
                                if RTD_UC_Status(15-gen,RTDLoop) == 0
                                    mpc_RTD.gen(15-gen,:) = [];
                                    mpc_RTD.gencost(15-gen,:) = [];
                                    mpc_RTD.genfuel(15-gen,:) = [];
                                    offlineGens = offlineGens+1;
                                else %Need to make sure first RTD run doesn't differ from first RTC MW output
                                    mpc_RTD.gen(15-gen,9)  = min(mpc_RTD.gen(15-gen,9) ,gen_output(15-gen,1) + mpc_RTD.gen(15-gen,19)/6); 
                                    mpc_RTD.gen(15-gen,10) = max(mpc_RTD.gen(15-gen,10),gen_output(15-gen,1) - mpc_RTD.gen(15-gen,19)/6);
                                end
                            end
                        else
                            for gen = 1:therm_gen_count
                                if RTD_UC_Status(15-gen,RTDLoop) ~= 0
%                                     %Set Max and Min Gens
                                        mpc_RTD.gen(15-gen,9)  = min(mpc_RTD.gen(15-gen,9) ,RTD_Gen_Storage(15-gen,RT_int-1) + mpc_RTD.gen(15-gen,19)/6); 
                                        mpc_RTD.gen(15-gen,10) = max(mpc_RTD.gen(15-gen,10),RTD_Gen_Storage(15-gen,RT_int-1) - mpc_RTD.gen(15-gen,19)/6);
%                                         mpc_RTD.gen(15-gen,9)  = RTD_Gen_Storage(15-gen,RT_int-1); 
%                                         mpc_RTD.gen(15-gen,10) = RTD_Gen_Storage(15-gen,RT_int-1);
                                else
                                    %Otherwise eliminate row
                                        mpc_RTD.gen(15-gen,:) = [];
                                        mpc_RTD.gencost(15-gen,:) = [];
                                        mpc_RTD.genfuel(15-gen,:) = [];
                                        offlineGens = offlineGens+1;
                                end
                            end    
                        end
                %% Add load data for the interval
                    mpc_RTD.bus(1:52, PD) = most_busload_RTC(RTDLoop,:);
                    mpc_RTD.bus(53:68, PD) = 0;   
                %% Add EVSE as load
                    if EVSE == 1
                        for EV = 1:32
                            mpc_RTD.bus(NYCA_Load_buses(EV), PD) = mpc_RTD.bus(NYCA_Load_buses(EV), PD) - EVSEloadRTD( EV,RT_int);                
                        end
                    end
                %% Define renewable output
                    firstWindy = 14-offlineGens+1;  lastWindy = firstWindy+14;
                    firstHydro = lastWindy+1;       lastHydro = firstHydro+14;
                    firstOther = lastHydro+1;       lastOther = firstOther+14;
                    mpc_RTD.gen(firstWindy:lastWindy,9)  = (most_bus_rengen_windy(RT_int,:)).';
                    mpc_RTD.gen(firstWindy:lastWindy,10) = (most_bus_rengen_windy(RT_int,:)).';
                    mpc_RTD.gen(firstHydro:lastHydro,9)  = (most_bus_rengen_hydro(RT_int,:)).';
                    mpc_RTD.gen(firstHydro:lastHydro,10) = 0;
                    mpc_RTD.gen(firstOther:lastOther,9)  = (most_bus_rengen_other(RT_int,:)).';
                    mpc_RTD.gen(firstOther:lastOther,10) = (most_bus_rengen_other(RT_int,:)).';
                %% Set Options
                    mpopt = mpoption;       %start with default options
                    mpopt = mpoption(mpopt, 'model', 'DC');
                    mpopt = mpoption(mpopt,'out.all',0);
                    mpopt = mpoption(mpopt,'verbose',0); 
                %% Run MatPower
                    results = runopf(mpc_RTD, mpopt);
                %% Analyze Results
                    %Gather Prices
                        RTD_LMP(1:68,RT_int) = results.bus(1:68,14);
                    %Gather results for graphing
                        RTD_Load_Storage(:,RT_int) = results.bus(:,3);

                        onlinegen = 1;
                        for gen = 1:therm_gen_count
                            if RTD_UC_Status(gen,RTDLoop) == 1
                                RTD_Gen_Storage(gen,RT_int) = results.gen(onlinegen,2);
                                onlinegen = onlinegen +1;
                            else
                                RTD_Gen_Storage(gen,RT_int) = 0;
                            end
                        end
                        RTD_Gen_Storage(therm_gen_count+1:therm_gen_count+45,RT_int) = results.gen(onlinegen:onlinegen+44,2);

                        RTD_RenGen_Max_Storage(:,RT_int) = results.gen(onlinegen:onlinegen+44,9);
                        RTD_RenGen_Min_Storage(:,RT_int) = results.gen(onlinegen:onlinegen+44,10);
                    %Gen RTD Costs
                        %Op Cost Calculation
                            for gen = 1:Gens
                                Gen_RTD_OpCost(gen) = Gen_RTD_OpCost(gen) + ...
                                        1/12*(...
                                                mdo.UC.CommitSched(gen,RT_int)*(mpc.gencost(gen,7) + ...
                                                RTD_Gen_Storage(gen,RT_int) *mpc.gencost(gen,6) + ...
                                                RTD_Gen_Storage(gen,RT_int)^2 *mpc.gencost(gen,5))...
                                              );
                            end   
                %% Increment period
                    RT_int = RT_int + 1
            end
            
    %% RTC Pass #2
        %Get UC results from 15min into last RTC run
            Previous_RTC_Status = RTD_UC_Status(:,3);
        %Define RTC Time Period
            RTC_int_start = RT_int;
            RTC_int_end = RT_int + most_period_count_RTC -1; %There are 30 periods
        %Find applicable DAM Hours
            for hourr =1:24
                if and(RTC_int_start>=hourbin(hourr,2),RTC_int_start<=hourbin(hourr,3))
                    hour_1 = hourbin(hourr);
                    hour_2 = hourbin(hourr+1);
                    hour_3 = hourbin(hourr+2);
                break
                end
            end
        %% Create Profiles
        %Load
            most_busload_RTC = most_busload(RTC_int_start:RTC_int_end,:);
        %Renewable generation
            most_windy_gen_RTC = most_bus_rengen_windy(RTC_int_start:RTC_int_end,:);
            most_hydro_gen_RTC = most_bus_rengen_hydro(RTC_int_start:RTC_int_end,:);
            most_other_gen_RTC = most_bus_rengen_other(RTC_int_start:RTC_int_end,:);
        %Generation
            %% CommitKey
                %Initialize Committment
                    most_CommitKey_RTC = ones(therm_gen_count,1);
                %Modify for forced on and off units
                    for genUC = 1:therm_gen_count
                        %first... was there any DAM committment? 
                            DAMvalue = DAM_UC_Results(genUC,hour_1) + DAM_UC_Results(genUC,hour_2) + DAM_UC_Results(genUC,hour_3);
                        %Long Start, no DAM committment... Forced OFF
                            if Previous_RTC_Status(genUC) == 0
                                if and(DAMvalue ==0, gen_startuptime_hrs(genUC) >=0.5)
                                    most_CommitKey_RTC(genUC) = -1;
                                end
                            end
                    end
                %Prevent unauthorized operation of LoHi Unit
                    most_CommitKey_RTC(14) = -1;
                %Hour 1 DAM commitment?... Forced ON
                    for genUC = 1:11 %there are 3 Nukes + 5 Steam plants = 8
                            if mustRun == 1
                                if DAM_UC_Results(genUC,hour_1) == 1
                                    most_CommitKey_RTC(genUC) = 2;
                                end
                            else
                                if DAM_UC_Results(genUC,hour_1) == 1
                                    most_CommitKey_RTC(genUC) = 1;
                                end
                            end
                    end
                %Kill Nukes
                    for gen = 2:killNuke
                        most_CommitKey_RTC(gen) = -1;
                    end
            %% Time until DAM committment (if any)
                %Time till next hour
                    timeTillHour = hourbin(hour_2,2) - RTC_int_start;
                %Time till next DAM commitment (if any)
                    %initialize arrays
                        timeTillDAM = zeros(therm_gen_count,1);
                        hrsTillDAM  = zeros(therm_gen_count,1);
                        flagg = 0;
                    %calculate for each generator
                        for gen = 1:therm_gen_count
                            %if committed in Hour_1 then step out
                                if DAM_UC_Results(gen,hour_1) == 1
                                    timeTillDAM(gen) = 0;
                                else
                                    %if not committed in hour 1, look beyond Hour_1 
                                        for hourr = hour_2:24
                                            %if committed in a future hour
                                                if DAM_UC_Results(gen,hourr) == 1
                                                    hrsTillDAM(gen) = hourr - hour_2;
                                                    flagg = 1;
                                                end
                                            %step out... don't consider future hours
                                                if flagg == 1
                                                    flagg = 0;
                                                    break;
                                                end
                                        end
                                    %if not committed all day 
                                        if hourr == 24
                                            hrsTillDAM(gen) = 24;
                                        end
                                        timeTillDAM(gen) = hrsTillDAM(gen)*12 + timeTillHour;
                                end
                        end
            %% Initial State
                for gen = 1:therm_gen_count
                    most_InitialState_RTC(gen) = sign(Previous_RTC_InitState(gen))*(abs(Previous_RTC_InitState(gen))+3);
                    if and(Previous_RTC_Status(gen)==0,most_CommitKey_RTC(gen)==1)
                        most_InitialState_RTC(gen) = -MinRunTime(gen);
                    end
                end
                Previous_RTC_InitState(1:therm_gen_count) = most_InitialState_RTC(1:therm_gen_count);
        %% Populate MOST Data
            %Add Network Model: Bus, Gen, Branch, Gen_Cost
                define_constants
                casefile = 'case_nyiso16';
                mpc = loadcase(casefile);
                xgd = loadxgendata('xgd_RTC' , mpc);
            %RTC Values
                %Reduce RAMP!
                    if IncreasedRTCramp_Steam == 1
                        for col = 17:19
                            mpc.gen(4:8,col) = mpc.gen(4:8,col).*RTCrampFactor_Steam;
                        end
                    end 
                    if IncreasedRTCramp_CC == 1
                        for col = 17:19
                            mpc.gen(10:11,col) = mpc.gen(10:11,col).*RTCrampFactor_CC;
                        end
                    end 
                %Drop the mingen
                    if droppit== 1
                        mpc.gen(1:therm_gen_count,10) = mpc.gen(:,10)./10;
                    end
                %Min Run/Down Time
                    xgd.MinUp = MinRunTime;
                    xgd.MinDown = MinDownTime;
                %Reduce the min down time
                    if minrunshorter == 1
                        for gen = 1:therm_gen_count
                            xgd.MinDown(gen) = floor(xgd.MinDown(gen)/10);
                        end
                    end
                %CommitKey (-1, 0/1, 2)
                    xgd.CommitKey = most_CommitKey_RTC;
                %InitialState (periods on/off line)
                    xgd.InitialState = most_InitialState_RTC.';
        %% Add EVSE Load
    if EVSE == 1
       %% Initialize
            clear storage
                %Tables
                    storage.gen             = zeros(BatCount,21);
                    storage.sd_table.data   = zeros(BatCount,13);
                    storage.xgd_table.data  = zeros(BatCount,2);
                    storage.gencost         = zeros(BatCount, 7);
                    MinStorageLevelPROFILE = zeros(32,RTC_periods);
                %StorageData Parameters
                    storage.sd_table.OutEff				= 1;
                    storage.sd_table.InEff				= 1;
                    storage.sd_table.LossFactor			= 0;
                    storage.sd_table.rho				= 0;
                    storage.sd_table.colnames = {
                        'InitialStorage', ...
                            'InitialStorageLowerBound', ...
                                'InitialStorageUpperBound', ...
                                    'InitialStorageCost', ...
                                        'TerminalStoragePrice', ...
                                            'MaxStorageLevel', ...
                                                'MinStorageLevel', ...
                                                    'OutEff', ...
                                                        'InEff', ...
                                                            'LossFactor', ...
                                                                'rho', ...
                                                                    'ExpectedTerminalStorageMin',...
                                                                        'ExpectedTerminalStorageMax',...
                    };

                    storage.xgd_table.colnames = {
                        'CommitKey', ...
                            'CommitSched', ...
                            };    
            %% Create Battery Data Containers     
                for Bat = 1:BatCount
                    %% Which Region are we in?
                        if sum(ismember(NYCA_Load_buses(Bat),A2F_Load_buses)) > 0
                            Region = 1; %Region 1 is A2F
                        else
                            if sum(ismember(NYCA_Load_buses(Bat),GHI_Load_buses)) >0
                                Region = 2; %Region 2 is GHI
                            else
                                if sum(ismember(NYCA_Load_buses(Bat),NYC_Load_buses)) >0
                                    Region = 3; %Region 3 is NYC
                                else
                                    if sum(ismember(NYCA_Load_buses(Bat),LIs_Load_buses)) >0
                                        Region = 4; %Region 4 is Long Island
                                    else
                                        Region = 5;
                                    end
                                end
                            end
                        end
                    %% Add individual battery parameters
                                           % bus            Qmin    mBase   Pmax    Pc1     Qc1min	Qc2min	ramp_agc	ramp_q
                                           % 	Pg	Qg	Qmax	Vg      status	   Pmin	Pc2     Qc1max	Qc2max	ramp_10     apf
                                           %                                                                        ramp_30	
                       storage.gen(Bat,:) = [NYCA_Load_buses(Bat)...
                                                0   0   0   0   1   100 1 -0.00001 -EVSE_Region_Ind_MW(Region) ...
                                                                                    0   0   0   0   0   0   0   0   EVSE_Region_Ind_MW(Region)   0   0];
%                     %% Calculate Total EVSE MWh for RTC2
%                         for EV = 1:32
%                             %RTC2 2.5hr total EVSE load         =  previous RTC EVSE load         plus another 15 minutes of hr3     minus EVSE load from RTD1 to 3
%                             RTCtotalEVSEload(EV,(RT_int-1)/3+1) = RTCtotalEVSEload(EV,(RT_int-1)/3) - .25*DAMEVSEload(EV,3) + sum(EVSEloadRTD(EV,1:3))/12;
%                         end
                    %% Calculate Total EVSE MWh for RTC2
                        RTCtotalEVSEload(Bat,(RT_int-1)/3+1) = RTCtotalEVSEload(Bat,(RT_int-1)/3) - .25*DAMEVSEload(Bat,3) + sum(EVSEloadRTD(Bat,1:3))/12;
                    %% Add storage data
                                                        %1 InitialStorage
                                                            %2 InitialStorageLowerBound
                                                                %3 InitialStorageUpperBound
                                                                    %4 InitialStorageCost
                                                                        %5 TerminalStoragePrice
                                                                            %6 MaxStorageLevel
                                                                                %7 MinStorageLevel
                                                                                    %8 OutEff
                                                                                        %9 InEff
                                                                                            %10 LossFactor
                                                                                                %11 rho
                                                                                                    %12 Expected Terminal Storage Min
                                                                                                        %13 Expected Terminal Storage Max
                                                        %1   2   3   4   5  6   7    8   9   10  11  12                13
                       storage.sd_table.data(Bat,:) =   [0   0   0   0   0  -RTCtotalEVSEload(Bat,(RT_int-1)/3+1),...
                                                                                0    1   1   0   0   -RTCtotalEVSEload(Bat,(RT_int-1)/3+1) -RTCtotalEVSEload(Bat,(RT_int-1)/3+1)];
                    %% Add storage XGD data
                                                        %1 CommitKey
                                                            %2 CommitSched
                                                                %3 PositiveActiveReservePrice
                                                                    %4 PositiveActiveReserveQuantity
                                                                        %5 NegativeActiveReservePrice
                                                                            %6 NegativeActiveReserveQuantity
                                                                                %7 PositiveActiveDeltaPrice
                                                                                    %8 NegativeActiveDeltaPrice
                                                                                        %9 PositiveLoadFollowReservePrice
                                                                                            %10 PositiveLoadFollowReserveQuantity
                                                                                                %11 NegativeLoadFollowReservePrice
                                                                                                    %12 NegativeLoadFollowReserveQuantity
                                                        %1   2   3   4   5   6   7   8   9   10  11  12
                       storage.xgd_table.data(Bat,:) = [2    1  ];% 0   0   0   0   0   0   0   0   0   0];
                    %% Add storage cost data
                                         %2	startup	n	c(n-1)	...	c0
                                         %      shutdown
                        storage.gencost(Bat,:) = [2	0	0	2	0 0 0]; 
                    %% Min Storage Level
                        %Set targets at top of every hour
%                             MinStorageLevelPROFILE(Bat,  1:11) =  0;
%                             MinStorageLevelPROFILE(Bat, 12:23) = -EVSEloadDAM(Bat,1);
%                             MinStorageLevelPROFILE(Bat, 24:29) = -EVSEloadDAM(Bat,1) - EVSEloadDAM(Bat,2);
%                             MinStorageLevelPROFILE(Bat, 30   ) = -EVSEloadDAM(Bat,1) - EVSEloadDAM(Bat,2) - 0.5*EVSEloadDAM(Bat,3);
                        %Set 1 target at end of 2.5 hours
                            MinStorageLevelPROFILE(Bat, RTC_periods   ) = -RTCtotalEVSEload(Bat,(RT_int-1)/3+1);
                end
    end
            %% Add Profiles
                %% Renewables
                    %WIND
                        %Add wind Gener ators
                            [iwind, mpc, xgd] = addwind('wind_gen' , mpc, xgd);
                        %Add empty max & min profiles
                            profiles = getprofiles('wind_profile_Pmax' , iwind); 
                            profiles = getprofiles('wind_profile_Pmin' , profiles);
                            profiles(1).values(:,1,:) = most_bus_rengen_windy(RTC_int_start:RTC_int_end,:);
                            if windyCurt == 1
                                profiles(2).values(:,1,:) = most_bus_rengen_windy(RTC_int_start:RTC_int_end,:).*windyCurtFactor;
                            else
                                profiles(2).values(:,1,:) = most_bus_rengen_windy(RTC_int_start:RTC_int_end,:);
                            end
                    %HYDRO
                        %Add hydro Generators
                            [ihydro, mpc, xgd] = addwind('hydro_gen' , mpc, xgd);
                        %Add empty max & min profiles
                            profiles = getprofiles('hydro_profile_Pmax' , profiles); 
                            profiles = getprofiles('hydro_profile_Pmin' , profiles);
                            profiles(3).values(:,1,:) = most_bus_rengen_hydro(RTC_int_start:RTC_int_end,:);
                            if hydroCurt == 1
                                profiles(4).values(:,1,:) = most_bus_rengen_hydro(RTC_int_start:RTC_int_end,:).*hydroCurtFactor;
                            else
                                profiles(4).values(:,1,:) = most_bus_rengen_hydro(RTC_int_start:RTC_int_end,:);
                            end
                    %OTHER
                        %Add other Generators
                            [iother, mpc, xgd] = addwind('other_gen' , mpc, xgd);
                        %Add empty max & min profiles
                            profiles = getprofiles('other_profile_Pmax' , profiles); 
                            profiles = getprofiles('other_profile_Pmin' , profiles);
                            profiles(5).values(:,1,:) = most_bus_rengen_other(RTC_int_start:RTC_int_end,:);
                            if otherCurt == 1
                                profiles(6).values(:,1,:) = most_bus_rengen_other(RTC_int_start:RTC_int_end,:).*otherCurtFactor;
                            else
                                profiles(6).values(:,1,:) = most_bus_rengen_other(RTC_int_start:RTC_int_end,:);
                            end
                %% Load
                    %Add load profile
                            profiles = getprofiles('load_profile' , profiles);
                            profiles(7).values(:,1,:) = most_busload(RTC_int_start:RTC_int_end,:);
                %% Initial Pg
                    %Renewables
                        xgd.InitialPg(15:29) = most_bus_rengen_windy(RTC_int_start,:);
                        xgd.InitialPg(30:44) = most_bus_rengen_hydro(RTC_int_start,:);
                        xgd.InitialPg(45:59) = most_bus_rengen_other(RTC_int_start,:);
                    %Thermal
                        xgd.InitialPg(1:14) = RTD_Gen_Storage(1:therm_gen_count,RT_int-1);
                %% Max and Min Gen profiles for RTC
                    %Create Max and Min Gen Profile Spaces
                        profiles = getprofiles('therm_profile_Pmax' , profiles); 
                        profiles = getprofiles('therm_profile_Pmin' , profiles); 
                    %Create Max and Min Gen Profile Values
                        therm_Pmax_RTC_Profile = zeros(most_period_count_RTC,therm_gen_count);
                        therm_Pmin_RTC_Profile = zeros(most_period_count_RTC,therm_gen_count);
                    for gen = 1:therm_gen_count
                        %First period limits
                            %If the unit was offline
                            if RTD_Gen_Storage(gen,RT_int-1) == 0
                                %and if the unit is a gas turbine
                                if or(gen == 12, gen == 13)
                                    %then set the first max/min values equal to the actual max/min values
                                    therm_Pmax_RTC_Profile(1,gen) = mpc.gen(gen,9);
                                    therm_Pmin_RTC_Profile(1,gen) = mpc.gen(gen,10);                                                
                                %otherwise, if its not a gas turbine
                                else
                                    %then set Pmax = min gen and Pmin = 0
                                    therm_Pmax_RTC_Profile(1,gen) = mpc.gen(gen,10); 
                                    therm_Pmin_RTC_Profile(1,gen) = 0;                
                                end
                            %otherwise, if the unit was online
                            else 
                                %and if the unit was at max output in previous RTD interval
                                if RTD_Gen_Storage(gen,RT_int-1) == mpc.gen(gen,9)
                                    %then set Pmax = actual max value and Pmin = actual max value - 5min ramp rate 
                                    therm_Pmax_RTC_Profile(1,gen) = mpc.gen(gen,9);
                                    therm_Pmin_RTC_Profile(1,gen) = mpc.gen(gen,9) - mpc.gen(gen,19)/6;
                                %otherwise, if the unit was online, but not at max output
                                else
                                    %and if the unit was below actual min gen (i.e. in startup mode)
                                    if RTD_Gen_Storage(gen,RT_int-1) < mpc.gen(gen,10)
                                        %then set the max value equal to the last value + 5min ramp rate.  Set min value = smaller of the same or the actual min gen
                                        therm_Pmax_RTC_Profile(1,gen) = RTD_Gen_Storage(gen,RT_int-1) + mpc.gen(gen,19)/6;
                                        therm_Pmin_RTC_Profile(1,gen) = min(RTD_Gen_Storage(gen,RT_int-1) + mpc.gen(gen,19)/6,mpc.gen(gen,10));  
                                    %otherwise, if the unit was operating between max and min gen 
                                    else
                                        %then set max and min = previous value +/- 5min ramp rate
                                        therm_Pmax_RTC_Profile(1,gen) = min(RTD_Gen_Storage(gen,RT_int-1) + mpc.gen(gen,19)/6,mpc.gen(gen,9));
                                        therm_Pmin_RTC_Profile(1,gen) = max(RTD_Gen_Storage(gen,RT_int-1) - mpc.gen(gen,19)/6,mpc.gen(gen,10));                                          
                                    end
                                end

                            end
                            
                        %Second period and beyond
                            for intt = 2:most_period_count_RTC
                                %if the unit was in startup mode in the previous period (i.e. output below min gen)
                                if therm_Pmax_RTC_Profile(intt-1,gen) < mpc.gen(gen,10)
                                    %then set the max value equal to the last value + intt* 5min ramp rate.  (think intt= steps up from 0 to min gen)
                                    %and set min value = smaller of the same or the actual min gen
                                    therm_Pmax_RTC_Profile(intt,gen) = RTD_Gen_Storage(gen,RT_int-1) + intt*mpc.gen(gen,19)/6;
                                    therm_Pmin_RTC_Profile(intt,gen) = min(RTD_Gen_Storage(gen,RT_int-1) + intt*mpc.gen(gen,19)/6,mpc.gen(gen,10));
                                %otherwise, if the unit was either offline or online, but not in startup mode,
                                else
                                    %then set max/min values = actual max/min values
                                    therm_Pmax_RTC_Profile(intt,gen) = mpc.gen(gen,9);
                                    therm_Pmin_RTC_Profile(intt,gen) = mpc.gen(gen,10);                                   
                                end
                            end
                        %If unit offline at start of RTC Window and has DAM committment in RTC window, 
                        %Then create MinGenMW staircase with step size = Ramp Rate
                            %If the unit was offline in previous RTD interval
                            if RTD_Gen_Storage(gen,RT_int-1) == 0
                                %and if the unit is going to startup within the RTC window due to a DAM commitment 
                                if and(timeTillDAM(gen) < RTC_periods, timeTillDAM(gen) > 0)
                                    %Start counting how high you've climbed again
                                        RampStep(gen) = 0;
                                    %set Max = Min = Ramp Rate(MW) - 1MW for first 5min interval when DAM committment occurs
                                        therm_Pmax_RTC_Profile(timeTillDAM(gen),gen) = mpc.gen(gen,19)/6-1;
                                        therm_Pmin_RTC_Profile(timeTillDAM(gen),gen) = mpc.gen(gen,19)/6-1; 
                                    %Count this first step
                                        RampStep(gen) = mpc.gen(gen,19)/6-1;
                                    %Start counting number of steps again
                                        StepCounterr(gen) = 0;
                                    %Create Staircase
                                        %While RampStep is less than min gen
                                        while RampStep(gen) < mpc.gen(gen,10)
                                            %Count number of steps
                                                StepCounterr(gen) = StepCounterr(gen) + 1;
                                            %Climb up another step
                                                RampStep(gen) =  RampStep(gen) + mpc.gen(gen,19)/6-1;
                                            %While we are still in the RTC window 
                                            if StepCounterr(gen) + timeTillDAM(gen) <= RTC_periods
                                                %set the max/min value for that interval equal to the Ramp step 
                                                %if we have stepped above the min gen, set the min gen = actual and max = step. 
                                                therm_Pmax_RTC_Profile(timeTillDAM(gen)+StepCounterr(gen),gen) = RampStep(gen);
                                                therm_Pmin_RTC_Profile(timeTillDAM(gen)+StepCounterr(gen),gen) = min(RampStep(gen),mpc.gen(gen,10)); 
                                            end
                                        end
                                end
                            end
                    end
            %Assign Values to Profiles
                profiles(8).values(:,1,:) = therm_Pmax_RTC_Profile(1:most_period_count_RTC,:);
                profiles(9).values(:,1,:) = therm_Pmin_RTC_Profile(1:most_period_count_RTC,:);
            %% EVSE Parameters
            if EVSE == 1
                %% Push Battery Data to MOST
                    [~,mpc,xgd,storage] = addstorage(storage,mpc,xgd);
                %% EVSE Initial Pg
                    xgd.InitialPg(60:91) = -0.00001;
                %% EVSE Pmin and Pmax limits
                    profiles = getprofiles('EVSE_profile_MinLvl' , profiles);    
                %% Add EVSE Profile
                    profiles(10).values(:,1,:) = MinStorageLevelPROFILE.';
            end
        %% Add transmission interface limits
            if IFlims == 1
                mpc.if.map = map_Array;
                mpc.if.lims  = lims_Array;
                mpc = toggle_iflims_most(mpc, 'on');            
            end
        %% Set options
            %Determine number of intervals in the simulation
                nt = most_period_count_RTC; % number of period
                mpopt = mpoption;
                mpopt = mpoption(mpopt,'most.dc_model', 1); % use DC network model (default)
    %             mpopt = mpoption(mpopt,'most.solver', 'GUROBI');
                mpopt = mpoption(mpopt, 'verbose', 0);
                mpopt = mpoption(mpopt,'most.skip_prices', 1);
        %% Set $-5/MWh renewable cost to avoid curtailment
            mpc.gencost(15:29,6) = REC_Cost;
            mpc.gencost(30:44,6) = REC_hydro;
            mpc.gencost(45:59,6) = REC_Cost;
            mpc.gencost(15:59,4) = 3;
        %% Load all data
                clear mdi
            %EVSE
                if EVSE == 1
                    numm = 91;
                    mdi = loadmd(mpc, nt, xgd, storage, [], profiles);
                    %% Modify Index for EVSE
                        mdi.Storage.UnitIdx(1:32) = [60:91];
                else
                    numm = 59;
                    mdi = loadmd(mpc, nt, xgd, [], [], profiles);
                end
            %Set Time period
                mdi.Delta_T = 5/60;
            %Set Ramp Costs = 0
                mdi.RampWearCostCoeff = zeros(numm,RTC_periods);
                for tt = 1:RTC_periods
                    mdi.offer(tt).PositiveActiveReservePrice = zeros(numm,1);
                    mdi.offer(tt).NegativeActiveReservePrice = zeros(numm,1);
                    mdi.offer(tt).PositiveActiveDeltaPrice = zeros(numm,1);
                    mdi.offer(tt).NegativeActiveDeltaPrice = zeros(numm,1);
                    mdi.offer(tt).PositiveLoadFollowReservePrice = zeros(numm,1);
                    mdi.offer(tt).NegativeLoadFollowReservePrice = zeros(numm,1);
                end
    %% Run Algorithm
            %Run the UC/ED algorithm
                clear mdo
                if IFlims == 1
                    mdo = most_if(mdi, mpopt);
                else
                    mdo = most(mdi, mpopt);
                end
            %View Results
                clear ms
                ms = most_summary(mdo); % print results, depending on verbose  option
        %% Plot RTC 2
            %% Initialize
                RTC_str = num2str(RT_int, '%03i');
                RTIntstring = strcat('RT Int:  ', RTC_str);
            %Gen Output in percent prep
                gen_output = ms.Pg;
                gen_capacity = mpc.gen(:,9);
                for gen = 1:length(gen_capacity)
                    gen_output_percent_all(gen,:) = gen_output(gen,:)./gen_capacity(gen);
                end
                gen_output_percent_all(isnan(gen_output_percent_all)) = 0;
            %Modify % output to show offline/online units
                for gen = 1:therm_gen_count
                    for time = 1:RTC_periods
                        %offline
                        if gen_output_percent_all(gen,time) == 0
                            gen_output_percent_all(gen,time) = -gen*.01;
                        else
                            %at max
                            if gen_output_percent_all(gen,time) == 1
                                gen_output_percent_all(gen,time) = 1+gen*.01;
        %                         else
        %                             %in between... Do nothing
                            end
                        end
                    end
                end
            %Curtailed Hydro
                for ttime = RTC_int_start:RTC_int_end
                    Hydro_actualGen(ttime-RTC_int_start+1) = sum(ms.Pg(30:44,ttime-RTC_int_start+1))/(A2F_2016_ITM_hydro_ICAP + A2F_ITM_CASE_hydro_cap + GHI_ITM_CASE_hydro_cap + NYC_ITM_CASE_hydro_cap + LIs_ITM_CASE_hydro_cap);
                    Hydro_schedGen(ttime-RTC_int_start+1) = sum(most_bus_rengen_hydro(ttime,:))/(A2F_2016_ITM_hydro_ICAP + A2F_ITM_CASE_hydro_cap + GHI_ITM_CASE_hydro_cap + NYC_ITM_CASE_hydro_cap + LIs_ITM_CASE_hydro_cap);
                    HydroCurtailment(ttime-RTC_int_start+1) = Hydro_schedGen(ttime-RTC_int_start+1) - Hydro_actualGen(ttime-RTC_int_start+1);
                end
            %Define Time Intervals
                BigTime = most_period_count_RTC;
                Time4Graph = linspace(0,RTC_hrs,BigTime);
            %% EVSE Load
                if EVSE == 1
                    for int = RT_int:RT_int+2
                        EVSEloadRTD(1:32,int) = mdo.Storage.ExpectedStorageDispatch(1:32,int);
                    end
                end
            %% Gather Renewable Output for temporary display of 30 values
                %create values
                    demand1(1:RTC_periods) = demand(RTC_int_start:RTC_int_end);
                    NetLoad(1:RTC_periods) = NYCA_CASE_net_load(RTC_int_start:RTC_int_end);
                    TrueLoad(1:RTC_periods) = NYCA_TrueLoad(RTC_int_start:RTC_int_end);
                    RenGen_hydro1 = zeros(1,RTC_periods);
                    RenGen_windy1 = zeros(1,RTC_periods);
                    RenGen_other1 = zeros(1,RTC_periods);
                    BTM4Graph1 = zeros(1,RTC_periods);
                %gather values
                    for iter = 1:RTC_periods
                            for renge = 15:29
                                RenGen_windy1(iter) = RenGen_windy1(iter) + ms.Pg(renge,iter);
                            end
                            for renge = 30:44
                                RenGen_hydro1(iter) = RenGen_hydro1(iter) + ms.Pg(renge,iter);
                            end
                            for renge = 45:59
                                RenGen_other1(iter) = RenGen_other1(iter) + ms.Pg(renge,iter);
                            end
                        BTM4Graph1(iter) = TrueLoad(iter) - NetLoad(iter);
                    end
            %% Gather Gen Output by Type - RTC
                for iter = RT_int:RT_int+most_period_count_RTC-1
                    run = iter-RT_int+1;
                    NukeGen(iter) = ms.Pg(1,run)+ms.Pg(2,run)+ms.Pg(3,run); %NUKE
                    SteamGen(iter) = ms.Pg(4,run)+ms.Pg(5,run)+ms.Pg(6,run)+ms.Pg(7,run)+ms.Pg(8,run);%STEAM
                    CCGen(iter) = ms.Pg(10,run)+ms.Pg(11,run);%CC
                    GTGen(iter) = ms.Pg(12,run)+ms.Pg(13,run);%GT
                    LOHIGen(iter) = ms.Pg(14,run); %Lo High Unit
                    RenGen_windy(iter) = 0;
                    for renge = 15:29
                        RenGen_windy(iter) = RenGen_windy(iter) + ms.Pg(renge,run);
                    end
                    RenGen_hydro(iter) = 0;
                    for renge = 30:44
                        RenGen_hydro(iter) = RenGen_hydro(iter) + ms.Pg(renge,run);
                    end
                    RenGen_other(iter) = 0;%RENEWABLE
                    for renge = 45:59
                        RenGen_other(iter) = RenGen_other(iter) + ms.Pg(renge,run);
                    end
                    BTM4Graph(iter) = TrueLoad(run) - NetLoad(run);
                end
            %% Gather Gen Output by Type - RTD
                NukeGenRTD = NaN(1,288);
                SteamGenRTD = NaN(1,288);
                CCGenRTD = NaN(1,288);
                GTGenRTD = NaN(1,288);
                LOHIGenRTD = NaN(1,288);
                RenGen_windyRTD = NaN(1,288);
                RenGen_hydroRTD = NaN(1,288);
                RenGen_otherRTD = NaN(1,288);
                BTM4GraphRTD = NaN(1,288);
                for iter = 1:RT_int-1
                    NukeGenRTD(iter) = RTD_Gen_Storage(1,iter)+RTD_Gen_Storage(2,iter)+RTD_Gen_Storage(3,iter); %NUKE
                    SteamGenRTD(iter) = RTD_Gen_Storage(4,iter)+RTD_Gen_Storage(5,iter)+RTD_Gen_Storage(6,iter)+RTD_Gen_Storage(7,iter)+RTD_Gen_Storage(8,iter);%STEAM
                    CCGenRTD(iter) = RTD_Gen_Storage(10,iter)+RTD_Gen_Storage(11,iter);%CC
                    GTGenRTD(iter) = RTD_Gen_Storage(12,iter)+RTD_Gen_Storage(13,iter);%GT
                    LOHIGenRTD(iter) = RTD_Gen_Storage(14,iter);
                    RenGen_windyRTD(iter) = 0;
                    for renge = 15:29
                        RenGen_windyRTD(iter) = RenGen_windyRTD(iter) + RTD_Gen_Storage(renge,iter);
                    end
                    RenGen_hydroRTD(iter) = 0;
                    for renge = 30:44
                        RenGen_hydroRTD(iter) = RenGen_hydroRTD(iter) + RTD_Gen_Storage(renge,iter);
                    end
                    RenGen_otherRTD(iter) = 0;%RENEWABLE
                    for renge = 45:59
                        RenGen_otherRTD(iter) = RenGen_otherRTD(iter) + RTD_Gen_Storage(renge,iter);
                    end
                    BTM4GraphRTD(iter) = NYCA_TrueLoad(iter) - NYCA_CASE_net_load(iter);
                end    
            %% Create Figures
        if printRTC == 1
                hFigA = figure(2); set(hFigA, 'Position', [450 50 650 850]) %Pixels: from left, from bottom, across, high
                %% A -- True Load, Net Load, Demand
                    A1 = subplot(4,1,1); hold on;
                    A2 = get(A1,'position'); A2(4) = A2(4)*.85; A2(3) = A2(3)*1; set(A1, 'position', A2);
                        plot(Time4Graph(1:RTC_periods),NYCA_TrueLoad(RTC_int_start:RTC_int_end)./1000,'LineStyle','-','color',[0 .447 .741],'marker','*')
                        plot(Time4Graph(1:RTC_periods),NYCA_CASE_net_load(RTC_int_start:RTC_int_end)./1000,'LineStyle','--','color','red','marker','x')
                        plot(Time4Graph,demand(RTC_int_start:RTC_int_end)./1000,'LineStyle','-','color',[.494 .184 .556],'marker','d','markeredgecolor',[.494 .184 .556])
                        area(Time4Graph,[demand1;RenGen_windy1; RenGen_hydro1; RenGen_other1; BTM4Graph1;].'./1000,'FaceAlpha',.5)
                    title('True Load, Net Load, & Demand')
%                     A3 = legend('True Load', 'Net Load', 'Demand','Demand', 'Wind','Hydro', 'Other Ren', 'BTM Ren');      
%                         reorderLegendarea([8 1 7 2 3 4 5 6])
%                         rect = [.8, 0.77, 0.15, 0.0875]; %[left bottom width height]
%                         set(A3, 'Position', rect)
                    axis([0,RTC_hrs,0,20]); 
                        set(gca, 'YTick', [0 5 10 15 20])
%                         axis 'auto y';
                        ylabel('Real Power (GW)')
                        set(gca, 'XTick', Time4Graph);
                            set(gca, 'xticklabel', {'0', ' ', ' ', ' ', ' ', ' ','0.5',  ' ', ' ', ' ', ' ', ' ', '1' , ' ', ' ', ' ', ' ', ' ', '1.5'...
                                                       , ' ', ' ', ' ', ' ', ' ','2', ' ', ' ', ' ', ' ', '2.5'})
%                             set(gca, 'xticklabel', {'0', ' ', ' ', ' ', ' ', ' ','1',  ' ', ' ', ' ', ' ', ' ', '2' , ' ', ' ', ' ', ' ', ' ', '3'...
%                                                        , ' ', ' ', ' ', ' ', ' ','4', ' ', ' ', ' ', ' ', '5'})
                        grid on; box on; hold off 
                %% B -- Generator Output (%)
                    B1 = subplot(4,1,2); hold on;
                        B2 = get(B1,'position'); B2(4) = B2(4)*.85; B2(2) = B2(2)*1; set(B1, 'position', B2); B2(3) = B2(3)*1; set(B1, 'position', B2);
                        plot(Time4Graph,gen_output_percent_all(1,:),'LineStyle',':','color',[0 .447 .741])
                        plot(Time4Graph,gen_output_percent_all(2,:),'LineStyle',':','color',[.635 .078 .184])
                        plot(Time4Graph,gen_output_percent_all(3,:),'LineStyle',':','color',[.85 .325 .098])
                        plot(Time4Graph,gen_output_percent_all(4,:),'LineStyle','--','color',[0 .447 .741])
                        plot(Time4Graph,gen_output_percent_all(5,:),'LineStyle','--','color',[.301 .745 .933])
                        plot(Time4Graph,gen_output_percent_all(6,:),'LineStyle','--','color',[.635 .078 .184])
                        plot(Time4Graph,gen_output_percent_all(7,:),'LineStyle','--','color',[.494 .184 .556])
                        plot(Time4Graph,gen_output_percent_all(8,:),'LineStyle','--','color',[.466 .674 .188])
                        plot(Time4Graph,gen_output_percent_all(10,:),'LineStyle','-.','color',[0 .447 .741])
                        plot(Time4Graph,gen_output_percent_all(11,:),'LineStyle','-.','color',[.494 .184 .556])
                        plot(Time4Graph,gen_output_percent_all(12,:),'LineStyle','-','color',[.494 .184 .556])
                        plot(Time4Graph,gen_output_percent_all(13,:),'LineStyle','-','color',[.466 .674 .188])
%                         B3 = legend('Nuke A2F','Nuke GHI','Nuke GHI','Steam A2F','Steam A2F','Steam GHI','Steam NYC','Steam LI',...
%                                     'CC A2F','CC NYC','GT NYC','GT LI')                        
                        title('RTC Generation (% Of Nameplate)')
%                         rect = [.8, 0.49, 0.15, .12]; %[left bottom width height]
%                         set(B3, 'Position', rect)
                        ylabel('Real Power (%)')
                        axis([0,RTC_hrs,-0.16,1]); 
                        set(gca, 'YTick', [0 0.25 0.5 0.75 1])
                        set(gca, 'yticklabel', {'0', '25', '50', '75', '100'})
                        set(gca, 'XTick', Time4Graph);
                            set(gca, 'xticklabel', {'0', ' ', ' ', ' ', ' ', ' ','0.5',  ' ', ' ', ' ', ' ', ' ', '1' , ' ', ' ', ' ', ' ', ' ', '1.5'...
                                                       , ' ', ' ', ' ', ' ', ' ','2', ' ', ' ', ' ', ' ', '2.5'})
%                             set(gca, 'xticklabel', {'0', ' ', ' ', ' ', ' ', ' ','1',  ' ', ' ', ' ', ' ', ' ', '2' , ' ', ' ', ' ', ' ', ' ', '3'...
%                                                        , ' ', ' ', ' ', ' ', ' ','4', ' ', ' ', ' ', ' ', '5'})
                        grid on; box on; hold off 
                %% C -- Generation by Type - RTC
                    C1 = subplot(4,1,3); hold on;
                        C2 = get(C1,'position'); C2(4) = C2(4)*.85; C2(2) = C2(2)*1; set(C1, 'position', C2); C2(3) = C2(3)*1; set(C1, 'position', C2);
                        area(1:288,[NukeGen;SteamGen;CCGen;GTGen;RenGen_windy;RenGen_hydro;RenGen_other;BTM4Graph;].'./1000,'FaceAlpha',.5)
%                         C3 = legend('Nuke', 'Steam', 'CC', 'GT', 'Wind', 'Hydro', 'Other Ren', 'BTM');
%                         reorderLegendarea([1 2 3 4 5 6 7 8]) 
                        title('RTC Generation By Type')
%                         rect = [.8, 0.23, 0.15, .12]; %[left bottom width height]
%                         set(C3, 'Position', rect)
                        ylabel('Real Power (GW)')
                        axis([0,288,0,20]); 
                        set(gca, 'YTick', [0 5 10 15 20])
                        set(gca, 'XTick', [0 12 24 36 48 60 72 84 96 108 120 132 144 156 168 180 192 204 216 228 240 252 264 276 288]);
                        set(gca, 'xticklabel', {'0', ' ', ' ', ' ','4', ' ', ' ', ' ', '8', ' ', ' ', ' ', '12', ' ', ' ', ' ', '16', ' ', ' ', ' ', '20', ' ', ' ', ' ', '24'})
                        grid on; box on; hold off 
                %% D -- Generation by Type - RTD
                    D1 = subplot(4,1,4); hold on;
                        D2 = get(D1,'position'); D2(4) = D2(4)*.85; D2(2) = D2(2)*1; set(D1, 'position', D2); D2(3) = D2(3)*1; set(D1, 'position', D2);
                        area(1:288,[NukeGenRTD;SteamGenRTD;CCGenRTD;GTGenRTD;RenGen_windyRTD;RenGen_hydroRTD;RenGen_otherRTD;BTM4GraphRTD;].'./1000,'FaceAlpha',.5)
                        title('RTD Generation By Type')
                        ylabel('Real Power (GW)')
                        xlabel('Time (Hour Beginning)');
                        axis([0,288,0,20]); 
                        set(gca, 'YTick', [0 5 10 15 20])
                        set(gca, 'XTick', [0 12 24 36 48 60 72 84 96 108 120 132 144 156 168 180 192 204 216 228 240 252 264 276 288]);
                        set(gca, 'xticklabel', {'0', ' ', ' ', ' ','4', ' ', ' ', ' ', '8', ' ', ' ', ' ', '12', ' ', ' ', ' ', '16', ' ', ' ', ' ', '20', ' ', ' ', ' ', '24'})
                        grid on; box on; hold off 
            %% Graph Title (Same for all graphs)
            First_Line_Title = [datestring(5:6), ' ', datestring(7:8), ', ', Case_Name_String,', ', RTIntstring];
            ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off',...
                'Units','normalized', 'clipping' , 'off');
            text(0.5, 1.0,[{'\bf \fontsize{18}' First_Line_Title}], 'HorizontalAlignment' ,...
                'center', 'VerticalAlignment', 'top')        
            %% Print
                    % Capture current figure/model into clipboard:
                          matlab.graphics.internal.copyFigureHelper(hFigA)
                    % Find end of document and make it the insertion point:
                        end_of_doc = get(word.activedocument.content,'end');
                        set(word.application.selection,'Start',end_of_doc);
                        set(word.application.selection,'End',end_of_doc); 
                    % Paste the contents of the Clipboard:
                        invoke(word.Selection,'Paste');
            close all     
        end
           %% Plot EVSE
                if EVSE == 1
                    for int = 1:288-6
                        EVSEloadRTD_24(1,int+6) = -sum(EVSEloadRTD(1:32,int));
                    end
                Time4Graphp = linspace(0,24,288);
                    %% Make Graph
                        hFigE = figure(19); set(hFigE, 'Position', [250 50 800 400]) %Pixels: from left, from bottom, across, high
                    %% A -- DAM LMP
                            A1 = subplot(2,1,1); hold on;
                            A2 = get(A1,'position'); A2(4) = A2(4)*1; A2(3) = A2(3)*1; A2(2) = A2(2)*1; set(A1, 'position', A2);
                                bar([EVSEloadDAMgraph(1,1:24);EVSEloadDAMgraph(2,1:24);EVSEloadDAMgraph(3,1:24);EVSEloadDAMgraph(4,1:24);].','stacked','FaceAlpha',.5)
                                area(Time4Graphp(1:288),EVSEloadRTD_24,'FaceAlpha',.8)
                                ylabel('Real Power (MW)')
                            axis([0.5,24.5,0,1000]); 
                            axis 'auto y';
                                xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
                                xticklabels({'0' '4' '8' '12' '16' '20' '24'})
    %                             set(gca, 'YTick', [0 100 200 300 400 500 600 700 800 900 1000])
                                grid on; grid minor; box on; hold off 
                    %% Save to a word file
                    if printRTC == 1
                        % Capture current figure/model into clipboard:
                              matlab.graphics.internal.copyFigureHelper(hFigE)
                        % Find end of document and make it the insertion point:
                            end_of_doc = get(word.activedocument.content,'end');
                            set(word.application.selection,'Start',end_of_doc);
                            set(word.application.selection,'End',end_of_doc); 
                        % Paste the contents of the Clipboard:
                            invoke(word.Selection,'Paste');
                    end
                    close all     
                end
        %% Interface Flows 
                round = 1;
            for int = RTC_int_start:RTC_int_start+2
                RTMifFlows(int,1) = ms.Pf(1,round)  - ms.Pf(16,round);
                RTMifFlows(int,2) = ms.Pf(1,round)  - ms.Pf(16,round) + ms.Pf(86,round); 
                RTMifFlows(int,3) = ms.Pf(7,round)  + ms.Pf(9,round)  + ms.Pf(13,round); 
                RTMifFlows(int,4) = ms.Pf(28,round) + ms.Pf(29,round);
                round = round + 1;
            end        
                clear round;
                
                
    %% RTC Pass 3+ & RTDx3 (RTC3 And Beyond)
        %Initialize
            if EVSE == 0
                EVSEloadRTD = zeros(32,288);
                BatCount = 32;
                EVSE_Region_Ind_MW = zeros(1,5);
                RTCtotalEVSEload = zeros(32,288);
                DAMEVSEload = zeros(32,24);
            end
        MaxGenforRTD_SUP = zeros(therm_gen_count,3);
        MaxGenforRTD_SHUT = zeros(therm_gen_count,3);
        DAMstartupModeLastRTC = zeros(therm_gen_count,1);
            %Loop through
            for loop = 1:85-(RTC_periods-30)/3
            %% Run RTD 3 times

        %Store N-2 UC Results
            RTD_UC_Status_Nm2 = RTD_UC_Status(:,3);
        %Run RTD 3 times
[RT_int,RTD_Load_Storage,RTD_Gen_Storage,RTD_RenGen_Max_Storage, RTD_RenGen_Min_Storage,RTD_UC_Status,RTD_LMP,Gen_RTD_OpCost,most_busload] = ...
    RunRTD3Times(RT_int,mdo,therm_gen_count,mpc,most_busload_RTC,most_bus_rengen_windy,most_bus_rengen_hydro,...
                 most_bus_rengen_other,RTD_Load_Storage,RTD_Gen_Storage,RTD_RenGen_Max_Storage, RTD_RenGen_Min_Storage,RTD_LMP,Gen_RTD_OpCost,...
                 windyCurt,windyCurtFactor,hydroCurt,hydroCurtFactor,otherCurt,otherCurtFactor,ms,IncreasedRTCramp_Steam,RTCrampFactor_Steam,MaxGenforRTD_SUP,MaxGenforRTD_SHUT,...
                 IncreasedRTDramp_Steam,RTDrampFactor_Steam,IncreasedRTCramp_CC,RTCrampFactor_CC,IncreasedRTDramp_CC,RTDrampFactor_CC,...
                 EVSE,EVSEloadRTD,NYCA_Load_buses,most_busload,Gens);
             
            %% Run RTC
%                  try 
               [ONOFF,mdo,ms,most_busload_RTC,most_windy_gen_RTC,most_hydro_gen_RTC,most_other_gen_RTC,NukeGen, SteamGen, ...
                CCGen, GTGen, LOHIGen,RenGen_windy, RenGen_hydro, RenGen_other,BTM4Graph,Previous_RTC_InitState,MaxGenforRTD_SUP,MaxGenforRTD_SHUT,...
                EVSEloadRTD,RTCtotalEVSEload,RTMifFlows,DAMstartupModeLastRTC] = ...
            RunRTC(RTD_UC_Status,RT_int,most_busload,most_bus_rengen_windy,most_bus_rengen_hydro,most_bus_rengen_other,...
                    therm_gen_count,RTD_UC_Status_Nm2,DAM_UC_Results,gen_startuptime_hrs,hourbin,Previous_RTC_InitState,...
                    RTD_Gen_Storage,MinRunTime,MinDownTime,...
                    most_period_count_RTC,NYCA_TrueLoad,NYCA_CASE_net_load,demand,datestring,Case_Name_String,...
                    NukeGen, SteamGen, CCGen, GTGen, LOHIGen,RenGen_windy, RenGen_hydro, RenGen_other,BTM4Graph,...
                    windyCurt,hydroCurt,otherCurt,droppit,printRTC,minrunshorter,mustRun,...
                    windyCurtFactor, hydroCurtFactor,otherCurtFactor,mdo,gen_startuptime,...
                    IncreasedRTCramp_Steam,RTCrampFactor_Steam,killNuke,IncreasedRTCramp_CC,RTCrampFactor_CC,RTC_hrs,...
                    REC_Cost,REC_hydro,...
                    map_Array, lims_Array, IFlims,RTMifFlows,...
                    EVSE,BatCount,NYCA_Load_buses,A2F_Load_buses,GHI_Load_buses,NYC_Load_buses,LIs_Load_buses,...
                    EVSE_Region_Ind_MW,RTCtotalEVSEload,DAMEVSEload,EVSEloadRTD,RTC_periods,DAMstarts,DAMshutdowns,DAMstartupModeLastRTC);
                
                %% Accumulate starts
                    for ff = 1:14
                        if ONOFF(ff) >=1
                            StartsPerGen(ff) = StartsPerGen(ff) + ONOFF(ff);
                        end
                    end
                %% Print
                    %% Paste RTC figure
                        if printRTC == 1
                        % Find end of document and make it the insertion point:
                            end_of_doc = get(word.activedocument.content,'end');
                            set(word.application.selection,'Start',end_of_doc);
                            set(word.application.selection,'End',end_of_doc); 
                        % Paste the contents of the Clipboard:
                            invoke(word.Selection,'Paste');
                            close all
                    %% Create & Print EVSE Figure
                        if EVSE == 1
                            %Initialize
                                for int = 1:288-6
                                    EVSEloadRTD_24(1,int+6) = -sum(EVSEloadRTD(1:32,int));
                                end
                                Time4Graphp = linspace(0,24,288);
                            %% Make EVSE Graph
                                hFigE = figure(19); set(hFigE, 'Position', [250 50 800 400]) %Pixels: from left, from bottom, across, high
                                    %% A -- DAM LMP
                                        A1 = subplot(2,1,1); hold on;
                                        A2 = get(A1,'position'); A2(4) = A2(4)*1; A2(3) = A2(3)*1; A2(2) = A2(2)*1; set(A1, 'position', A2);
                                            bar([EVSEloadDAMgraph(1,1:24);EVSEloadDAMgraph(2,1:24);EVSEloadDAMgraph(3,1:24);EVSEloadDAMgraph(4,1:24);].','stacked','FaceAlpha',.5)
                                            area(Time4Graphp(1:288),EVSEloadRTD_24,'FaceAlpha',.8)
                                            ylabel('Real Power (MW)')
                                        axis([0.5,24.5,0,1000]); 
                                        axis 'auto y';
                                            xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
                                            xticklabels({'0' '4' '8' '12' '16' '20' '24'})
%                                             set(gca, 'YTick', [0 100 200 300 400 500 600 700 800 900 1000])
                                            grid on; grid minor; box on; hold off 
                            %% Print EVSE Graph
                                    matlab.graphics.internal.copyFigureHelper(hFigE)
                                % Find end of document and make it the insertion point:
                                    end_of_doc = get(word.activedocument.content,'end');
                                    set(word.application.selection,'Start',end_of_doc);
                                    set(word.application.selection,'End',end_of_doc); 
                                % Paste the contents of the Clipboard:
                                    invoke(word.Selection,'Paste');
                                    close all
                        end
                        end
%                 catch
%                     fprintf('  RTC failed to converge\n\n');
%                     keyboard;
%                     break
%                 end
            end
          lastRTD_int = RT_int-1;
          Summaryy(:,5) = Gen_RTD_OpCost;
         
%% Final Graphs

    %% EVSE Graph
        if EVSE == 1
            %% Initialize
                for int = 1:288-6
                    EVSEloadRTD_24(1,int+6) = -sum(EVSEloadRTD(1:32,int));
                end
                Time4Graphp = linspace(0,24,288);
                hFigE = figure(19); set(hFigE, 'Position', [250 50 800 200]) %Pixels: from left, from bottom, across, high
            %% A -- DAM LMP
                    A1 = subplot(1,1,1); hold on;
                    A2 = get(A1,'position'); A2(4) = A2(4)*.8; A2(3) = A2(3)*.8; A2(2) = A2(2)*2.5; set(A1, 'position', A2);
                        bar([EVSEloadDAMgraph(1,1:24);EVSEloadDAMgraph(2,1:24);EVSEloadDAMgraph(3,1:24);EVSEloadDAMgraph(4,1:24);].','stacked','FaceAlpha',.5)
                        area(Time4Graphp(1:288),EVSEloadRTD_24,'FaceAlpha',.8)
                    A3 = legend('DAM Upstate','DAM LHV','DAM NYC','DAM LI','RTM NYCA');
                    reorderLegendarea([1 2 3 4 5])
                    rect = [.8, 0.5, 0.15, .2]; %[left bottom width height]
                    set(A3, 'Position', rect)
                        ylabel('Real Power (MW)')
                        xlabel('Time (Hour Beginning)')
                    axis([0.5,24.5,0,16]); 
%                     axis 'auto y';
                        xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
                        xticklabels({'0' '4' '8' '12' '16' '20' '24'})
%                     set(gca, 'YTick', [0 100 200 300 400 500 600 700 800 900 1000])
                        grid on; grid minor; box on; hold off 
            %% Print EVSE Graph
                matlab.graphics.internal.copyFigureHelper(hFigE)
            % Find end of document and make it the insertion point:
                end_of_doc = get(word.activedocument.content,'end');
                set(word.application.selection,'Start',end_of_doc);
                set(word.application.selection,'End',end_of_doc); 
            % Paste the contents of the Clipboard:
                invoke(word.Selection,'Paste');
                close all
        end
            
    %% Initialize
            gen_output_percent_final = zeros(14,288);
        %Gen Output in Percent
            for gen = 1:therm_gen_count
                gen_output_percent_final(gen,:) = RTD_Gen_Storage(gen,:)./gen_capacity(gen);
            end
        %Remove NaN values
            gen_output_percent_final(isnan(gen_output_percent_final)) = 0;
        %Time Intervals
            BigTime = RT_int-1;
            Time4Graph = linspace(0,24,288);   
        %Get Gen Data from RTD Runs

            for iter = 1:lastRTD_int
                NukeGenRTD(iter) = RTD_Gen_Storage(1,iter)+RTD_Gen_Storage(2,iter)+RTD_Gen_Storage(3,iter); %NUKE
                SteamGenRTD(iter) = RTD_Gen_Storage(4,iter)+RTD_Gen_Storage(5,iter)+RTD_Gen_Storage(6,iter)+RTD_Gen_Storage(7,iter)+RTD_Gen_Storage(8,iter);%STEAM
                CCGenRTD(iter) = RTD_Gen_Storage(10,iter)+RTD_Gen_Storage(11,iter);%CC
                GTGenRTD(iter) = RTD_Gen_Storage(12,iter)+RTD_Gen_Storage(13,iter);%GT
                LOHIGenRTD(iter) = RTD_Gen_Storage(14,iter);
                RenGen_windyRTD(iter) = 0;
                for renge = 15:29
                    RenGen_windyRTD(iter) = RenGen_windyRTD(iter) + RTD_Gen_Storage(renge,iter);
                end
                RenGen_hydroRTD(iter) = 0;
                for renge = 30:44
                    RenGen_hydroRTD(iter) = RenGen_hydroRTD(iter) + RTD_Gen_Storage(renge,iter);
                end
                RenGen_otherRTD(iter) = 0;%RENEWABLE
                for renge = 45:59
                    RenGen_otherRTD(iter) = RenGen_otherRTD(iter) + RTD_Gen_Storage(renge,iter);
                end
                BTM4GraphRTD(iter) = NYCA_TrueLoad(iter) - NYCA_CASE_net_load(iter);
            end
        %Modify % output to show offline/online units
            for gen = 1:therm_gen_count
                for time = 1:lastRTD_int
                    %offline
                    if gen_output_percent_final(gen,time) == 0
                        gen_output_percent_final(gen,time) = -gen*.01;
                    else
                        %at max
                        if gen_output_percent_final(gen,time) == 1
                            gen_output_percent_final(gen,time) = 1+gen*.01;
%                         else
%                             %in between... Do nothing
                        end
                    end
                end
            end
    %% Final Figure #1
        hFigA = figure(1); 
            set(hFigA, 'Position', [250 50 800 400]) %Pixels: from left, from bottom, across, high
            %% A -- True Load, Net Load, Demand
%                 A1 = subplot(4,1,1); hold on;
%                 A2 = get(A1,'position'); A2(4) = A2(4)*1; A2(3) = A2(3)*0.75; set(A1, 'position', A2);
%                     plot(Time4Graph,NYCA_TrueLoad,'LineStyle','-','color',[0 .447 .741],'marker','.')
%                     plot(Time4Graph,NYCA_CASE_net_load,'LineStyle','--','color','red','marker','.')
%                     plot(Time4Graph,demand,'LineStyle','-','color',[.494 .184 .556],'marker','.','markeredgecolor',[.494 .184 .556])
%                     area(Time4Graph,[demand.';RenGen_windy; RenGen_hydro; RenGen_other; BTM4Graph;].','FaceAlpha',.5)
%                 title('RTC Gen, True Load, Net Load, & Demand')
%                 A3 = legend('True Load', 'Net Load', 'Demand','Demand', 'Wind','Hydro', 'Other Ren', 'BTM Ren');      
%                     reorderLegendarea([8 1 7 2 3 4 5 6])
%                     rect = [.8, 0.8, 0.15, 0.0875]; %[left bottom width height]
%                     set(A3, 'Position', rect)
%                 axis([0,24,0,30000]); 
%                     ylabel('Real Power (MW)')
%                     set(gca, 'XTick', [0 4 8 12 16 20 24]);
%                 grid on; grid minor; box on; hold off 
            %% B -- Generation by Type
%                 B1 = subplot(4,1,2); hold on;
                B1 = subplot(2,1,2); hold on;
%                     B2 = get(B1,'position'); B2(4) = B2(4)*1; B2(2) = B2(2)*1; set(B1, 'position', B2); B2(3) = B2(3)*0.75; set(B1, 'position', B2);
                    B2 = get(B1,'position'); B2(4) = B2(4)*1.15; B2(2) = B2(2)*1.35; set(B1, 'position', B2); B2(3) = B2(3)*1; set(B1, 'position', B2);
                    area(Time4Graph,[NukeGenRTD;SteamGenRTD;CCGenRTD;GTGenRTD;RenGen_windyRTD;RenGen_hydroRTD;RenGen_otherRTD;BTM4GraphRTD;].'./1000,'FaceAlpha',.5)
%                     title('   Generation by Type')
%                     rect = [.8, 0.57, 0.15, .12]; %[left bottom width height]
%                     set(B3, 'Position', rect)
                    ylabel('Real Power (GW)')
                    axis([0,24,0,30]); 
                    set(gca, 'YTick', [0 10 20 30])
                    set(gca, 'XTick', [0 4 8 12 16 20 24]);
                    xlabel('Time (Hour Beginning)')
                    grid on; grid minor; box on; hold off
            %% C -- Generation Output (MW)
%                 C1 = subplot(4,1,3); hold on;
%                     C2 = get(C1,'position'); C2(4) = C2(4)*1; C2(2) = C2(2)*1; set(C1, 'position', C2); C2(3) = C2(3)*0.75; set(C1, 'position', C2);
%                     plot(Time4Graph(1:lastRTD_int),RTD_Gen_Storage(1,1:lastRTD_int),'LineStyle',':','color',[0 .447 .741])
%                     plot(Time4Graph(1:lastRTD_int),RTD_Gen_Storage(2,1:lastRTD_int),'LineStyle',':','color',[.635 .078 .184])
%                     plot(Time4Graph(1:lastRTD_int),RTD_Gen_Storage(3,1:lastRTD_int),'LineStyle',':','color',[.85 .325 .098])
%                     plot(Time4Graph(1:lastRTD_int),RTD_Gen_Storage(4,1:lastRTD_int),'LineStyle','--','color',[0 .447 .741])
%                     plot(Time4Graph(1:lastRTD_int),RTD_Gen_Storage(5,1:lastRTD_int),'LineStyle','--','color',[.301 .745 .933])
%                     plot(Time4Graph(1:lastRTD_int),RTD_Gen_Storage(6,1:lastRTD_int),'LineStyle','--','color',[.635 .078 .184])
%                     plot(Time4Graph(1:lastRTD_int),RTD_Gen_Storage(7,1:lastRTD_int),'LineStyle','--','color',[.494 .184 .556])
%                     plot(Time4Graph(1:lastRTD_int),RTD_Gen_Storage(8,1:lastRTD_int),'LineStyle','--','color',[.466 .674 .188])
%                     plot(Time4Graph(1:lastRTD_int),RTD_Gen_Storage(10,1:lastRTD_int),'LineStyle','-.','color',[0 .447 .741])
%                     plot(Time4Graph(1:lastRTD_int),RTD_Gen_Storage(11,1:lastRTD_int),'LineStyle','-.','color',[.494 .184 .556])
%                     plot(Time4Graph(1:lastRTD_int),RTD_Gen_Storage(12,1:lastRTD_int),'LineStyle','-','color',[.494 .184 .556])
%                     plot(Time4Graph(1:lastRTD_int),RTD_Gen_Storage(13,1:lastRTD_int),'LineStyle','-','color',[.466 .674 .188])
%                     title('Generator Output (MW)')
%                         ylabel('Real Power (MW)')
%                         axis([0,24,0,6000]); 
%                         set(gca, 'XTick', [0 4 8 12 16 20 24]);
%                     grid on; grid minor; box on; hold off  
            %% D -- Generator Output (%)
%                 D1 = subplot(4,1,4); hold on;
                D1 = subplot(2,1,1); hold on;
                    D2 = get(D1,'position'); D2(4) = D2(4)*1; D2(2) = D2(2)*1; set(D1, 'position', D2); D2(3) = D2(3)*1; set(D1, 'position', D2);
%                     D2 = get(D1,'position'); D2(4) = D2(4)*.85; D2(2) = D2(2)*1; set(D1, 'position', D2); D2(3) = D2(3)*1; set(D1, 'position', D2);
                    plot(Time4Graph(1:lastRTD_int),gen_output_percent_final(1,1:lastRTD_int),'LineStyle',':','color',[0 .447 .741])
                    plot(Time4Graph(1:lastRTD_int),gen_output_percent_final(2,1:lastRTD_int),'LineStyle',':','color',[.635 .078 .184])
                    plot(Time4Graph(1:lastRTD_int),gen_output_percent_final(3,1:lastRTD_int),'LineStyle',':','color',[.85 .325 .098])
                    plot(Time4Graph(1:lastRTD_int),gen_output_percent_final(4,1:lastRTD_int),'LineStyle','--','color',[0 .447 .741])
                    plot(Time4Graph(1:lastRTD_int),gen_output_percent_final(5,1:lastRTD_int),'LineStyle','--','color',[.301 .745 .933])
                    plot(Time4Graph(1:lastRTD_int),gen_output_percent_final(6,1:lastRTD_int),'LineStyle','--','color',[.635 .078 .184])
                    plot(Time4Graph(1:lastRTD_int),gen_output_percent_final(7,1:lastRTD_int),'LineStyle','--','color',[.494 .184 .556])
                    plot(Time4Graph(1:lastRTD_int),gen_output_percent_final(8,1:lastRTD_int),'LineStyle','--','color',[.466 .674 .188])
                    plot(Time4Graph(1:lastRTD_int),gen_output_percent_final(10,1:lastRTD_int),'LineStyle','-.','color',[0 .447 .741])
                    plot(Time4Graph(1:lastRTD_int),gen_output_percent_final(11,1:lastRTD_int),'LineStyle','-.','color',[.494 .184 .556])
                    plot(Time4Graph(1:lastRTD_int),gen_output_percent_final(12,1:lastRTD_int),'LineStyle','-','color',[.494 .184 .556])
                    plot(Time4Graph(1:lastRTD_int),gen_output_percent_final(13,1:lastRTD_int),'LineStyle','-','color',[.466 .674 .188])
%                         D3 = legend('Nuke A2F','Nuke GHI','Nuke GHI','Steam A2F','Steam A2F','Steam GHI','Steam NYC','Steam LI',...
%                                        'CC A2F','CC NYC','GT NYC','GT LI');                        
                    plot(Time4Graph(1:288),zeros(1,288),'color',[0 0 0 0.1])
                    plot(Time4Graph(1:288),ones(1,288),'color',[0 0 0 0.1])
%                     title('Generator Output (% of Nameplate)')
%                     rect = [.8, 0.3, 0.15, .12]; %[left bottom width height]
%                     set(D3, 'Position', rect)
                    ylabel('Real Power (%)')
                    axis([0,24,-0.16,1]); 
                    set(gca, 'XTick', [0 4 8 12 16 20 24]);
                    xticklabels({' ' ' ' ' ' ' ' ' ' ' ' ' '})
                    set(gca, 'YTick', [0 0.5 1.0]);
                    yticklabels({' 0','50','100'});
%                     
                    grid on; grid minor; box on; hold off     
            %% Graph Title (Same for all graphs)
%                 First_Line_Title = ['Simulation for: ', datestring(5:6), ' ', datestring(7:8), ' ', datestring(1:4), ' in the ',Case_Name_String,', SUMMARY of All RTD Runs'];
%                 ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off',...
%                     'Units','normalized', 'clipping' , 'off');
%                 text(0.5, 1.0,[{'\bf \fontsize{14}' First_Line_Title}], 'HorizontalAlignment' ,...
%                     'center', 'VerticalAlignment', 'top')        
        %% Print
                % Capture current figure/model into clipboard:
                      matlab.graphics.internal.copyFigureHelper(hFigA)
                % Find end of document and make it the insertion point:
                    end_of_doc = get(word.activedocument.content,'end');
                    set(word.application.selection,'Start',end_of_doc);
                    set(word.application.selection,'End',end_of_doc); 
                % Paste the contents of the Clipboard:
                    invoke(word.Selection,'Paste');
            close all     

     %% Final Figure #2 - DAM vs RTD
        %% Get RTM Values
             %% Initialize
                Nuke_1 = NaN(1,288);
                Nuke_2 = NaN(1,288);
                Nuke_3 = NaN(1,288);
                Steam_1 = NaN(1,288);
                Steam_2 = NaN(1,288);
                Steam_3 = NaN(1,288);
                Steam_4 = NaN(1,288);
                Steam_5 = NaN(1,288);
                CCGen_1 = NaN(1,288);
                CCGen_2 = NaN(1,288);
                LOHIGen = NaN(1,288);
                GTGen_1 = NaN(1,288);
                GTGen_2 = NaN(1,288);
            %% Populate RTD values
                %push out 30 minutes to line up with bars.
                for iter = 1:lastRTD_int
                    Nuke_1(iter+6) = RTD_Gen_Storage(1,iter);
                    Nuke_2(iter+6) = RTD_Gen_Storage(2,iter);
                    Nuke_3(iter+6) = RTD_Gen_Storage(3,iter);
                    Steam_1(iter+6) = RTD_Gen_Storage(4,iter);
                    Steam_2(iter+6) = RTD_Gen_Storage(5,iter);
                    Steam_3(iter+6) = RTD_Gen_Storage(6,iter);
                    Steam_4(iter+6) = RTD_Gen_Storage(7,iter);
                    Steam_5(iter+6) = RTD_Gen_Storage(8,iter);
                    CCGen_1(iter+6) = RTD_Gen_Storage(10,iter);
                    CCGen_2(iter+6) = RTD_Gen_Storage(11,iter);
                    LOHIGen(iter+6) = RTD_Gen_Storage(14,iter);
                    GTGen_1(iter+6) = RTD_Gen_Storage(12,iter);
                    GTGen_2(iter+6) = RTD_Gen_Storage(13,iter);
                end
                for iter = 1:lastRTD_int
                    RenGen_windy(iter+6) = 0;
                    for renge = 15:29
                        RenGen_windy(iter+6) = RenGen_windy(iter+6) + RTD_Gen_Storage(renge,iter);
                    end
                    RenGen_hydro(iter+6) = 0;
                    for renge = 30:44
                        RenGen_hydro(iter+6) = RenGen_hydro(iter+6) + RTD_Gen_Storage(renge,iter);
                    end
                    RenGen_other(iter+6) = 0;
                    for renge = 45:59
                        RenGen_other(iter+6) = RenGen_other(iter+6) + RTD_Gen_Storage(renge,iter);
                    end
                end
        %% Make Figure
        hFigB = figure(22); set(hFigB, 'Position', [450 50 650 850]) %Pixels: from left, from bottom, across, high
            %% A -- Nuke Output
                A1 = subplot(4,1,1); hold on;
                A2 = get(A1,'position'); A2(4) = A2(4)*1; A2(3) = A2(3)*0.75; set(A1, 'position', A2);
                    bar([Nuke_1_DAM;Nuke_2_DAM;Nuke_3_DAM;].','stacked','FaceAlpha',.5)
                    area(Time4Graph(1:288),[Nuke_1;Nuke_2;Nuke_3;].','FaceAlpha',.5)
                title('Nuke Output - RTD vs. DAM')
                A3 = legend('Nuke1_A_2_F DAM', 'Nuke2_G_H_I DAM','Nuke3_G_H_I DAM','Nuke1_A_2_F RTD', 'Nuke2_G_H_I RTD','Nuke3_G_H_I RTD');      
                    reorderLegendarea([1 2 3 4 5 6])
                    rect = [.8, 0.8, 0.15, 0.0875]; %[left bottom width height]
                    set(A3, 'Position', rect)
                axis([0.5,24.5,0,6000]); 
                ylabel('Real Power (MW)')
                xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
                xticklabels({'0' '4' '8' '12' '16' '20' '24'})
%                 set(gca, 'XTick', [0 4 8 12 16 20 24]);
                grid on; grid minor; box on; hold off 
            %% B -- Steam
                B1 = subplot(4,1,2); hold on;
                    B2 = get(B1,'position'); B2(4) = B2(4)*1; B2(2) = B2(2)*1; set(B1, 'position', B2); B2(3) = B2(3)*0.75; set(B1, 'position', B2);
                    bar([Steam_1_DAM;Steam_2_DAM;Steam_3_DAM;Steam_4_DAM;Steam_5_DAM;].','stacked','FaceAlpha',.5)
                    area(Time4Graph(1:288),[Steam_1;Steam_2;Steam_3;Steam_4;Steam_5;].','FaceAlpha',.5)
                title('Steam Output - RTD vs. DAM')
                B3 = legend('Steam1_A_2_F DAM', 'Steam2_A_2_F DAM','Steam3_G_H_I DAM','Steam4_N_Y_C DAM','Steam5_L_I_s DAM',...
                            'Steam1_A_2_F RTD', 'Steam2_A_2_F RTD','Steam3_G_H_I RTD','Steam4_N_Y_C RTD','Steam5_L_I_s RTD');      
                    reorderLegendarea([1 2 3 4 5 6 7 8 9 10])
                    rect = [.8, 0.57, 0.15, 0.0875]; %[left bottom width height]
                    set(B3, 'Position', rect)
                axis([0.5,24.5,0,12500]); 
                ylabel('Real Power (MW)')
                xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
                xticklabels({'0' '4' '8' '12' '16' '20' '24'})
%                 set(gca, 'XTick', [0 4 8 12 16 20 24]);
                grid on; grid minor; box on; hold off 
            %% C -- Combined Cycle + Low/High Unit
                C1 = subplot(4,1,3); hold on;
                    C2 = get(C1,'position'); C2(4) = C2(4)*1; C2(2) = C2(2)*1; set(C1, 'position', C2); C2(3) = C2(3)*0.75; set(C1, 'position', C2);
                    bar([CCGen_1_DAM;CCGen_2_DAM;].','stacked','FaceAlpha',.5)
                    area(Time4Graph(1:288),[CCGen_1;CCGen_2;].','FaceAlpha',.5)
                    C3 = legend('CC1_A_2_F DAM', 'CC2_N_Y_C DAM','CC1_A_2_F RTD', 'CC2_N_Y_C RTD');
                    reorderLegendarea([1 2 3 4])
                    title('Combined Cycle Output - RTD vs. DAM')
                    rect = [.8, 0.35, 0.15, 0.0875]; %[left bottom width height]
                    set(C3, 'Position', rect)
                axis([0.5,24.5,0,9000]); 
                ylabel('Real Power (MW)')
                xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
                xticklabels({'0' '4' '8' '12' '16' '20' '24'})
%                 set(gca, 'XTick', [0 4 8 12 16 20 24]);
                grid on; grid minor; box on; hold off 
            %% D -- Gas Turbines
                D1 = subplot(4,1,4); hold on;
                    D2 = get(D1,'position'); D2(4) = D2(4)*1; D2(2) = D2(2)*1; set(D1, 'position', D2); D2(3) = D2(3)*0.75; set(D1, 'position', D2);
                    bar([GTGen_1_DAM;GTGen_2_DAM;].','stacked','FaceAlpha',.5)
                    area(Time4Graph(1:288),[GTGen_1;GTGen_2;].','FaceAlpha',.5)
                title('Gas Turbine Output - RTD vs. DAM')
                D3 = legend('GT1_N_Y_C DAM', 'GT2_L_I_s DAM','GT1_N_Y_C RTD', 'GT2_L_I_s RTD');      
                    reorderLegendarea([1 2 3 4])
                    rect = [.8, 0.15, 0.15, 0.05]; %[left bottom width height]
                    set(D3, 'Position', rect)
                axis([0.5,24.5,0,5000]); 
                ylabel('Real Power (MW)')
                xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
                xticklabels({'0' '4' '8' '12' '16' '20' '24'})
%                 set(gca, 'XTick', [0 4 8 12 16 20 24]);
                xlabel('\bf Time (Hour Beginning)')
                grid on; grid minor; box on; hold off 
            %% Graph Title (Same for all graphs)
                First_Line_Title = ['Simulation for: ', datestring(5:6), ' ', datestring(7:8), ' ', datestring(1:4), ' in the ',Case_Name_String,' SUMMARY of RTD'];
                ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off',...
                    'Units','normalized', 'clipping' , 'off');
                text(0.5, 1.0,[{'\bf \fontsize{14}' First_Line_Title}], 'HorizontalAlignment' ,...
                    'center', 'VerticalAlignment', 'top')        
        %% Print
%                 % Capture current figure/model into clipboard:
%                       matlab.graphics.internal.copyFigureHelper(hFigB)
%                 % Find end of document and make it the insertion point:
%                     end_of_doc = get(word.activedocument.content,'end');
%                     set(word.application.selection,'Start',end_of_doc);
%                     set(word.application.selection,'End',end_of_doc); 
%                 % Paste the contents of the Clipboard:
%                     invoke(word.Selection,'Paste');
            close all     

     %% Final Figure #3 - RENEWABLES
        %% Initial setup
             %Dam Results by generator
                clear RenGen_windy
                clear RenGen_hydro
                clear RenGen_other
                RenGen_windy = NaN(1,288);
                RenGen_hydro = NaN(1,288);
                RenGen_other = NaN(1,288);
            %Get RTD values
                for iter = 1:lastRTD_int
                    RenGen_windy(iter) = 0;
                    for renge = 15:29
                        RenGen_windy(iter) = RenGen_windy(iter) + RTD_Gen_Storage(renge,iter);
                    end
                    RenGen_hydro(iter) = 0;
                    for renge = 30:44
                        RenGen_hydro(iter) = RenGen_hydro(iter) + RTD_Gen_Storage(renge,iter);
                    end
                    RenGen_other(iter) = 0;
                    for renge = 45:59
                        RenGen_other(iter) = RenGen_other(iter) + RTD_Gen_Storage(renge,iter);
                    end
                end
        %% RTD Renewable Curtailment MWh
            RTDwindyCurtMWh = 0;
            for int = 1:lastRTD_int
                RTDwindyCurtMWh = RTDwindyCurtMWh + (TOT_ITM_windy_gen_profile(1,int) - RenGen_windy(1,int))*1/12;
            end
            RTDhydroCurtMWh = 0;
            for int = 1:lastRTD_int
                RTDhydroCurtMWh = RTDhydroCurtMWh + (TOT_ITM_hydro_gen_profile(1,int) - RenGen_hydro(1,int))*1/12;
            end
            RTDotherCurtMWh = 0;
            for int = 1:lastRTD_int
                RTDotherCurtMWh = RTDotherCurtMWh + (TOT_ITM_other_gen_profile(1,int) - RenGen_other(1,int))*1/12;
            end
            
        DAMresults(9,Case*4+d) = RTDwindyCurtMWh;
        DAMresults(10,Case*4+d) = RTDhydroCurtMWh;
        DAMresults(11,Case*4+d) = RTDotherCurtMWh;
        %% Make Figure
        hFigC = figure(22); set(hFigC, 'Position', [450 50 650 850]) %Pixels: from left, from bottom, across, high
            %% A -- WIND
                A1 = subplot(4,1,1); hold on;
                A2 = get(A1,'position'); A2(4) = A2(4)*1; A2(3) = A2(3)*0.75; set(A1, 'position', A2);
                    area(Time4Graph(1:288),[RenGen_windy;TOT_ITM_windy_gen_profile-RenGen_windy;].','FaceAlpha',.5)
                    plot(Time4Graph(1:288),ones(1,288).*TOT_ITM_CASE_wind_cap,'color',[0 0 0],'marker','.');
                title('Wind Generation')
                A3 = legend('Scheduled', 'Deviation','Nameplate');      
                    rect = [.8, 0.8, 0.15, 0.0875]; %[left bottom width height]
                    set(A3, 'Position', rect)
                axis([0,24,0,8000]); 
                ylabel('Real Power (MW)')
                set(gca, 'XTick', [0 4 8 12 16 20 24]);
                grid on; grid minor; box on; hold off 
            %% B -- HYDRO
                B1 = subplot(4,1,2); hold on;
                B2 = get(B1,'position'); B2(4) = B2(4)*1; B2(2) = B2(2)*1; set(B1, 'position', B2); B2(3) = B2(3)*0.75; set(B1, 'position', B2);
                    area(Time4Graph(1:288),[RenGen_hydro;TOT_ITM_hydro_gen_profile-RenGen_hydro;].','FaceAlpha',.5)
                    plot(Time4Graph(1:288),ones(1,288).*TOT_ITM_CASE_hydro_cap,'color',[0 0 0],'marker','.');
                title('Hydro Generation')
                B3 = legend('Scheduled', 'Deviation','Nameplate');     
                    rect = [.8, 0.57, 0.15, 0.0875]; %[left bottom width height]
                    set(B3, 'Position', rect)
                axis([0,24,0,8000]); 
                ylabel('Real Power (MW)')
                set(gca, 'XTick', [0 4 8 12 16 20 24]);
                grid on; grid minor; box on; hold off 
            %% C -- OTHER
                C1 = subplot(4,1,3); hold on;
                C2 = get(C1,'position'); C2(4) = C2(4)*1; C2(2) = C2(2)*1; set(C1, 'position', C2); C2(3) = C2(3)*0.75; set(C1, 'position', C2);
                   area(Time4Graph(1:288),[RenGen_other;TOT_ITM_other_gen_profile-RenGen_other;].','FaceAlpha',.5)
                   plot(Time4Graph(1:288),ones(1,288).*(TOT_ITM_CASE_PV_cap + TOT_ITM_CASE_Bio_cap + TOT_ITM_CASE_LFG_cap),'color',[0 0 0],'marker','.');
                title('Other (Bio,LFG,Solar) Generation')
                C3 = legend('Scheduled', 'Deviation','Nameplate');     
                    rect = [.8, 0.35, 0.15, 0.0875]; %[left bottom width height]
                    set(C3, 'Position', rect)
                axis([0,24,0,8000]); 
                ylabel('Real Power (MW)')
                set(gca, 'XTick', [0 4 8 12 16 20 24]);
                grid on; grid minor; box on; hold off 
            %% D -- CURTAILMENT
                D1 = subplot(4,1,4); hold on;
                    D2 = get(D1,'position'); D2(4) = D2(4)*1; D2(2) = D2(2)*1; set(D1, 'position', D2); D2(3) = D2(3)*0.75; set(D1, 'position', D2);
                    area(Time4Graph(1:288),[TOT_ITM_windy_gen_profile-RenGen_windy;TOT_ITM_hydro_gen_profile-RenGen_hydro;TOT_ITM_other_gen_profile-RenGen_other;].','FaceAlpha',.5)
                title('Curtailment')
                D3 = legend('Wind','Hydro','Other');      
                    reorderLegendarea([1 2 3])
                    rect = [.8, 0.15, 0.15, 0.05]; %[left bottom width height]
                    set(D3, 'Position', rect)
                axis([0,24,0,120]); 
                axis 'auto y';
                ylabel('Real Power (MW)')
                set(gca, 'XTick', [0 4 8 12 16 20 24]);
                xlabel('\bf Time (Hour Beginning)')
                grid on; grid minor; box on; hold off 
            %% Graph Title (Same for all graphs)
                First_Line_Title = ['Simulation for: ', datestring(5:6), ' ', datestring(7:8), ' ', datestring(1:4), ' in the ',Case_Name_String,' SUMMARY of RTD'];
                ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off',...
                    'Units','normalized', 'clipping' , 'off');
                text(0.5, 1.0,[{'\bf \fontsize{14}' First_Line_Title}], 'HorizontalAlignment' ,...
                    'center', 'VerticalAlignment', 'top')        
        %% Print
%                 % Capture current figure/model into clipboard:
%                       matlab.graphics.internal.copyFigureHelper(hFigC)
%                 % Find end of document and make it the insertion point:
%                     end_of_doc = get(word.activedocument.content,'end');
%                     set(word.application.selection,'Start',end_of_doc);
%                     set(word.application.selection,'End',end_of_doc); 
%                 % Paste the contents of the Clipboard:
%                     invoke(word.Selection,'Paste');
            close all     
   
     %% Final Figure #4 - RAMP LIMIT VIOLATIONS
        %% Initial setup
%             %Ramp Limits by generator
%                 RampLimits(1:therm_gen_count)  = mpc.gen(1:therm_gen_count,19);
%             %Calculate Ramp events
%                 delta = NaN(therm_gen_count,lastRTD_int-1);
%                 RampUpViolations = NaN(therm_gen_count,lastRTD_int-1);
%                 RampDownViolations = NaN(therm_gen_count,lastRTD_int-1);
%                 delta = NaN(therm_gen_count,lastRTD_int-1);
%                 for gen = 1:therm_gen_count
%                     for iter = 1:lastRTD_int-1
%                         delta(gen,iter) = RTD_Gen_Storage(gen,iter+1) - RTD_Gen_Storage(gen,iter);
%                         if and(delta(gen,iter)>0,delta(gen,iter)>RampLimits(gen))
%                             RampUpViolations(gen,iter) = delta(gen,iter) - RampLimits(gen);
%                         end
%                         if and(delta(gen,iter)<=0,delta(gen,iter)<-RampLimits(gen))
%                             RampDownViolations(gen,iter) = -delta(gen,iter) - RampLimits(gen);
%                         end
%                     end
%                 end                    
        %% Make Figure
%         hFigD = figure(22); set(hFigD, 'Position', [450 50 650 450]) %Pixels: from left, from bottom, across, high
             %% A -- Ramp Up Violations
%                 A1 = subplot(2,1,1); hold on;
%                 A2 = get(A1,'position'); A2(4) = A2(4)*.9; A2(2) = A2(2)*.9; A2(3) = A2(3)*0.75; set(A1, 'position', A2);
%                     plot(Time4Graph(1:lastRTD_int-1),RampUpViolations(1,1:lastRTD_int-1),'LineStyle',':','color',[0 .447 .741])
%                     plot(Time4Graph(1:lastRTD_int-1),RampUpViolations(2,1:lastRTD_int-1),'LineStyle',':','color',[.635 .078 .184])
%                     plot(Time4Graph(1:lastRTD_int-1),RampUpViolations(3,1:lastRTD_int-1),'LineStyle',':','color',[.85 .325 .098])
%                     plot(Time4Graph(1:lastRTD_int-1),RampUpViolations(4,1:lastRTD_int-1),'LineStyle','--','color',[0 .447 .741])
%                     plot(Time4Graph(1:lastRTD_int-1),RampUpViolations(5,1:lastRTD_int-1),'LineStyle','--','color',[.301 .745 .933])
%                     plot(Time4Graph(1:lastRTD_int-1),RampUpViolations(6,1:lastRTD_int-1),'LineStyle','--','color',[.635 .078 .184])
%                     plot(Time4Graph(1:lastRTD_int-1),RampUpViolations(7,1:lastRTD_int-1),'LineStyle','--','color',[.494 .184 .556])
%                     plot(Time4Graph(1:lastRTD_int-1),RampUpViolations(8,1:lastRTD_int-1),'LineStyle','--','color',[.466 .674 .188])
%                     plot(Time4Graph(1:lastRTD_int-1),RampUpViolations(10,1:lastRTD_int-1),'LineStyle','-.','color',[0 .447 .741])
%                     plot(Time4Graph(1:lastRTD_int-1),RampUpViolations(11,1:lastRTD_int-1),'LineStyle','-.','color',[.494 .184 .556])
%                     plot(Time4Graph(1:lastRTD_int-1),RampUpViolations(12,1:lastRTD_int-1),'LineStyle','-','color',[.494 .184 .556])
%                     plot(Time4Graph(1:lastRTD_int-1),RampUpViolations(13,1:lastRTD_int-1),'LineStyle','-','color',[.466 .674 .188])
%                     A3 = legend('Nuke A2F','Nuke GHI','Nuke GHI','Steam A2F','Steam A2F','Steam GHI','Steam NYC','Steam LI',...
%                                        'CC A2F','CC NYC','GT NYC','GT LI');                        
%                 title('Ramp Up Violations')
%                 rect = [.8, 0.4, 0.15, .12]; %[left bottom width height]
%                 set(A3, 'Position', rect)
%                 axis([0,24,0,8000]); 
%                 axis 'auto y';
%                 ylabel('Amt over Upper Lim (MW)')
%                 set(gca, 'XTick', [0 4 8 12 16 20 24]);
%                 grid on; grid minor; box on; hold off 
             %% B -- Ramp Down Violations
%                 B1 = subplot(2,1,2); hold on;
%                 B2 = get(B1,'position'); B2(4) = B2(4)*.9; B2(2) = B2(2)*1; set(B1, 'position', B2); B2(3) = B2(3)*0.75; set(B1, 'position', B2);
%                     plot(Time4Graph(1:lastRTD_int-1),RampDownViolations(1,1:lastRTD_int-1),'LineStyle',':','color',[0 .447 .741])
%                     plot(Time4Graph(1:lastRTD_int-1),RampDownViolations(2,1:lastRTD_int-1),'LineStyle',':','color',[.635 .078 .184])
%                     plot(Time4Graph(1:lastRTD_int-1),RampDownViolations(3,1:lastRTD_int-1),'LineStyle',':','color',[.85 .325 .098])
%                     plot(Time4Graph(1:lastRTD_int-1),RampDownViolations(4,1:lastRTD_int-1),'LineStyle','--','color',[0 .447 .741])
%                     plot(Time4Graph(1:lastRTD_int-1),RampDownViolations(5,1:lastRTD_int-1),'LineStyle','--','color',[.301 .745 .933])
%                     plot(Time4Graph(1:lastRTD_int-1),RampDownViolations(6,1:lastRTD_int-1),'LineStyle','--','color',[.635 .078 .184])
%                     plot(Time4Graph(1:lastRTD_int-1),RampDownViolations(7,1:lastRTD_int-1),'LineStyle','--','color',[.494 .184 .556])
%                     plot(Time4Graph(1:lastRTD_int-1),RampDownViolations(8,1:lastRTD_int-1),'LineStyle','--','color',[.466 .674 .188])
%                     plot(Time4Graph(1:lastRTD_int-1),RampDownViolations(10,1:lastRTD_int-1),'LineStyle','-.','color',[0 .447 .741])
%                     plot(Time4Graph(1:lastRTD_int-1),RampDownViolations(11,1:lastRTD_int-1),'LineStyle','-.','color',[.494 .184 .556])
%                     plot(Time4Graph(1:lastRTD_int-1),RampDownViolations(12,1:lastRTD_int-1),'LineStyle','-','color',[.494 .184 .556])
%                     plot(Time4Graph(1:lastRTD_int-1),RampDownViolations(13,1:lastRTD_int-1),'LineStyle','-','color',[.466 .674 .188])
%                 title('Ramp Down Violations')
%                 axis([0,24,0,8000]); 
%                 axis 'auto y';
%                 ylabel('Amt under Lower Lim (MW)')
%                 set(gca, 'XTick', [0 4 8 12 16 20 24]);
%                 grid on; grid minor; box on; hold off 
             %% Graph Title (Same for all graphs)
%                 First_Line_Title = ['Simulation for: ', datestring(5:6), ' ', datestring(7:8), ' ', datestring(1:4), ' in the ',Case_Name_String,' SUMMARY of RTD'];
%                 ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off',...
%                     'Units','normalized', 'clipping' , 'off');
%                 text(0.5, 1.0,[{'\bf \fontsize{14}' First_Line_Title}], 'HorizontalAlignment' ,...
%                     'center', 'VerticalAlignment', 'top')        
        %% Print
%                 % Capture current figure/model into clipboard:
%                       matlab.graphics.internal.copyFigureHelper(hFigD)
%                 % Find end of document and make it the insertion point:
%                     end_of_doc = get(word.activedocument.content,'end');
%                     set(word.application.selection,'Start',end_of_doc);
%                     set(word.application.selection,'End',end_of_doc); 
%                 % Paste the contents of the Clipboard:
%                     invoke(word.Selection,'Paste');
%             close all      

     %% Final Figure #5 - LMP
        %% Initial Setup
            %LMP
                %Initialize
                    RTD_LMP_graph = nan(1,288);
                %Get RTD values
                    for iter = 1:lastRTD_int
                        RTD_LMP_graph(1,iter+6) = RTD_LMP(62,iter); %tag this to ref bus: energy component of LMP only
                    end
            %Curtailment
                %Initialize
                    TotRT_CURT_graph = nan(1,288);
                %Total 
                    TotRT_CURT = [TOT_ITM_windy_gen_profile-RenGen_windy + TOT_ITM_hydro_gen_profile-RenGen_hydro + TOT_ITM_other_gen_profile-RenGen_other;].';
                    for iter = 1:lastRTD_int
                        TotRT_CURT_graph(iter+6) = TotRT_CURT(iter);
                    end
        %% Make Figure
        hFigE = figure(22); set(hFigE, 'Position', [250 50 800 400]) %Pixels: from left, from bottom, across, high
             %% A -- DAM LMP
                A1 = subplot(2,1,1); hold on;
                A2 = get(A1,'position'); A2(4) = A2(4)*1; A2(3) = A2(3)*1; A2(2) = A2(2)*1; set(A1, 'position', A2);
%                     bar(A1,DAM_LMP(1,1:24),'FaceAlpha',.2)
%                     area(Time4Graph(1:288),RTD_LMP_graph,'FaceAlpha',.5)
                    bar(A1,DAM_LMP_energy(1,1:24))
                    area(Time4Graph(1:288),RTD_LMP_graph,'FaceAlpha',.8)
%                     title('LMP')
                    ylabel('LMP ($/MWh)')
                    axis([0.5,24.5,0,16]); 
%                     axis 'auto y';
                    xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
                    xticklabels({' ' ' ' ' ' ' ' ' ' ' ' ' '})
%                     set(gca, 'XTick', [0 4 8 12 16 20 24]);
                    grid on; grid minor; box on; hold off 
            %% B -- Curtailment
                B1 = subplot(2,1,2); hold on;
                    B2 = get(B1,'position'); B2(4) = B2(4)*1.15; B2(2) = B2(2)*1.35; set(B1, 'position', B2); B2(3) = B2(3)*1; set(B1, 'position', B2);
                    bar(B1, DAMCurtMWh_hrly(1:24,1))
                    area(Time4Graph(1:288),TotRT_CURT_graph,'FaceAlpha',.8)
%                     title('Curtailment')
                    axis([0.5,24.5,0,1500]); 
%                     axis 'auto y';
                ylabel('Curtailment (MW)')
                    xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
                    xticklabels({'0' '4' '8' '12' '16' '20' '24'})
%                     set(gca, 'XTick', [0 4 8 12 16 20 24]);
                    xlabel('Time (Hour Beginning)')
                    grid on; grid minor; box on; hold off                 
        %% Print
                % Capture current figure/model into clipboard:
                      matlab.graphics.internal.copyFigureHelper(hFigE)
                % Find end of document and make it the insertion point:
                    end_of_doc = get(word.activedocument.content,'end');
                    set(word.application.selection,'Start',end_of_doc);
                    set(word.application.selection,'End',end_of_doc); 
                % Paste the contents of the Clipboard:
                    invoke(word.Selection,'Paste');
            close all  
            
    %% Final Figure #6 - Curtailment by Region & Interface Flow
        %% Initial Setup
            %% RTM Actual Renewable Generation by region
                RTMactualRegion = zeros(4,288);
                for int = 1:lastRTD_int
                    %A2F
                        RTMactualRegion(1,int) = sum(RTD_Gen_Storage(25:29,int))+...
                                            sum(RTD_Gen_Storage(40:44,int))+...
                                            sum(RTD_Gen_Storage(55:59,int));
                    %GHI
                        RTMactualRegion(2,int) = sum(RTD_Gen_Storage(15:16,int))+RTD_Gen_Storage(22,int)+...
                                            sum(RTD_Gen_Storage(30:31,int))+RTD_Gen_Storage(37,int)+...
                                            sum(RTD_Gen_Storage(45:46,int))+RTD_Gen_Storage(52,int);
                    %NYC
                        RTMactualRegion(3,int) = sum(RTD_Gen_Storage(17:19,int))+...
                                            sum(RTD_Gen_Storage(32:34,int))+...
                                            sum(RTD_Gen_Storage(47:49,int));
                    %LIs
                        RTMactualRegion(4,int) = sum(RTD_Gen_Storage(20:21,int))+...
                                            sum(RTD_Gen_Storage(35:36,int))+...
                                            sum(RTD_Gen_Storage(50:51,int));
                end
        %% RTM curtailment by region
            RTMcurtRegion = RTMschedRegion - RTMactualRegion;
            RTMcurtRegion_g = nan(4,288);
            for int = 1:lastRTD_int
                RTMcurtRegion_g(:,int+6) = RTMcurtRegion(:,int);
            end
        %% RTM interface flow on central east 
            RTMifFlows_g = nan(4,288);
            for int = 1:lastRTD_int
                RTMifFlows_g(:,int+6) = RTMifFlows(int,:);
            end
        %% Make Figure
            if printCurt == 1
                hFigE = figure(3); set(hFigE, 'Position', [450 50 650 450]) %Pixels: from left, from bottom, across, high
            %% A -- Curtailment by Region 
                A1 = subplot(2,1,1); hold on;
                    A2 = get(A1,'position'); A2(4) = A2(4)*.80; A2(2) = A2(2)*1; set(A1, 'position', A2); A2(3) = A2(3)*0.75; set(A1, 'position', A2);
                    bar([DAMcurtRegion(1,1:24);DAMcurtRegion(2,1:24);DAMcurtRegion(3,1:24);DAMcurtRegion(4,1:24);].','stacked','FaceAlpha',.5)
                    area(Time4Graph(1:288),[RTMcurtRegion_g(1,:);RTMcurtRegion_g(2,:);RTMcurtRegion_g(3,:);RTMcurtRegion_g(4,:);].','FaceAlpha',.5)
                    ylabel('Real Power (MW)')
                axis([0.5,24.5,0,1500]); 
%                 axis 'auto y';
%                 title('Curtailment by Region')
                A3 = legend('DAM Upstate','DAM LHV','DAM NYC','DAM LI','RTM Upstate','RTM LHV','RTM NYC','RTM LI');
                reorderLegendarea([1 2 3 4 5 6 7 8])
                rect = [.8, 0.6, 0.15, .2]; %[left bottom width height]
                set(A3, 'Position', rect)
                    set(gca, 'YTick', [0 500 1000 1500])
                    xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
                    xticklabels({'0' '4' '8' '12' '16' '20' '24'})
%                 set(gca, 'YTick', [0 250 500 1000])
                    xlabel('Time (Hour Beginning)')
                    ylabel('Curtailment (MW)')
                    grid on; grid minor; box on; hold off 
            %% B -- Central-East Interface Flows
                B1 = subplot(2,1,2); hold on;
                    B2 = get(B1,'position'); B2(4) = B2(4)*.80; B2(2) = B2(2)*1.4; set(B1, 'position', B2); B2(3) = B2(3)*0.75; set(B1, 'position', B2);
                    bar([DAMifFlows(1:24,BoundedIF);].')
                    plot(1:25,DAM_CElimit)
                    area(Time4Graph(1:288),[RTMifFlows_g(BoundedIF,:);].','FaceAlpha',.5)
                    ylabel('C-E Flow (MW)')
                axis([0.5,24.5,0,4000]); 
%                 axis 'auto y';
%                 title('C-E Flow (MW)')
                B3 = legend('DAM CE Flow', 'Limit', 'RTM CE Flow');
                reorderLegendarea([2 1 3])
                rect = [.8, 0.3, 0.15, .05]; %[left bottom width height]
                set(B3, 'Position', rect)
                    xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
                    xticklabels({'0' '4' '8' '12' '16' '20' '24'})
%                 set(gca, 'YTick', [0 250 500 1000])
                    xlabel('Time (Hour Beginning)')
                    ylabel('Real Power (MW)')
                    grid on; grid minor; box on; hold off     
            %% Save to a word file
                % Capture current figure/model into clipboard:
                      matlab.graphics.internal.copyFigureHelper(hFigE)
                % Find end of document and make it the insertion point:
                    end_of_doc = get(word.activedocument.content,'end');
                    set(word.application.selection,'Start',end_of_doc);
                    set(word.application.selection,'End',end_of_doc); 
                % Paste the contents of the Clipboard:
                    invoke(word.Selection,'Paste');
                close all
            end
          
    %% Real Time Settlement
    %% Debug MW and LMP values
        %RTM MW - Load
            RTM_MW_Load = zeros(288 - RTC_periods,1);
            for int = 1:288 - RTC_periods 
                for bus = 1:52
                    RTM_MW_Load(int,1) = RTM_MW_Load(int,1) + most_busload(int,bus);
                end
            end
        %RTM MW - Gen
            RTM_MW_Gen = zeros(288 - RTC_periods,1);
            for int = 1:288 - RTC_periods 
                for gen = 1:59
                    RTM_MW_Gen(int,1) = RTM_MW_Gen(int,1) + RTD_Gen_Storage(gen,int);
                end
            end
        %Calculate Error
            RTM_MW_error = RTM_MW_Load - RTM_MW_Gen
    
        %% RTD Revenue
            %Initialize
                Gen_RTD_Revenue = zeros(59,1);
            %% Thermal Gen RTD Revenue
                for gen = 1:59
                    for hourr = 1:24
                        for int = 1:12
                            if (hourr-1)*12+int <= (288 - RTC_periods)
                                Gen_RTD_Revenue(gen) = Gen_RTD_Revenue(gen) + ...
                                    1/12*( RTD_Gen_Storage(gen,(hourr-1)*12+int) - DAM_gen_storage(gen,hourr)  )*( RTD_LMP(mpc.gen(gen,1),(hourr-1)*12+int));
                            end
                        end
                    end    
                end
            %% Renewable Gen RTD Revenue
%                 %Do Renewables Bid in DAM? 
%                     RenInDAM = 1; %If 1, then bid 100% in DAM and settle in RT.  If 0, then 100% settled in RT. 
%                 %Remove DAM Revenue for renewables if they didn't bid in DAM
%                     if RenInDAM ~= 1
%                         Gen_DAM_Revenue(15:59) = 0;
%                     end
%                 %Calculate RTD Revenue
%                     if RenInDAM == 1
%                         for genn = 15:59
%                             for hourr = 1:24
%                                 for int = 1:12
%                                     if (hourr-1)*12+int <= (288 - RTC_periods)
%                                         Gen_RTD_Revenue(genn) = Gen_RTD_Revenue(genn) + ...
%                                             1/12*( RTD_Gen_Storage(genn,(hourr-1)*12+int) - DAM_gen_storage(genn,hourr))*( RTD_LMP(mpc.gen(genn,1),(hourr-1)*12+int));
%                                     end
%                                 end
%                             end
%                         end
%                     else
%                         for genn = 15:59
%                             for hourr = 1:24
%                                 for int = 1:12
%                                     if (hourr-1)*12+int <= (288 - RTC_periods)
%                                         Gen_RTD_Revenue(genn) = Gen_RTD_Revenue(genn) + ...
%                                             1/12*( RTD_Gen_Storage(genn,(hourr-1)*12+int) )*( RTD_LMP(mpc.gen(genn,1),(hourr-1)*12+int) );
%                                     end
%                                 end
%                             end
%                         end
%                     end         
                    Summaryy(:,4) = Gen_RTD_Revenue;
        %% Startup Costs
            Gen_RTD_Sup_Costs = zeros(59,1);
            for gen = 1:14
                Gen_RTD_Sup_Costs(gen) = StartsPerGen(gen) * mdi.mpc.gencost(gen,2);
            end
            Summaryy(:,6) = Gen_RTD_Sup_Costs;
        %% DAMAP - Ensures Gen's don't loose $
            %Gen Energy Revenue + Startup
                Gen_NetRev = zeros(59,1);
                for gen = 1:59
                    Gen_NetRev(gen) = Gen_DAM_Revenue(gen) + Gen_RTD_Revenue(gen) - Gen_RTD_OpCost(gen) - Gen_RTD_Sup_Costs(gen);
                end
            %Determine DAMAP
                DAMAP = zeros (59,1);
                for gen = 1:59
                    if Gen_NetRev(gen) < 0
                        DAMAP(gen) = - Gen_NetRev(gen);
                    end
                end
            %Gen Energy Revenue + Startup + DAMAP
                Gen_NetRev_w_DAMAP = zeros(59,1);
                for gen = 1:59
                    Gen_NetRev_w_DAMAP(gen) = Gen_DAM_Revenue(gen) + Gen_RTD_Revenue(gen) - Gen_RTD_OpCost(gen)- Gen_RTD_Sup_Costs(gen) + DAMAP(gen);
                end
        %% Cost to Loads
            Cost2LoadsOLD = sum(Gen_DAM_Revenue(1:59)) + sum(Gen_RTD_Revenue(1:59)) + sum(Gen_RTD_Sup_Costs(1:59)) + sum(DAMAP(1:59));
            DAMresults(4,Case*4+d) = Cost2LoadsOLD;


            %% RTM Load Cost
                LoadCostRTM = zeros(52,1);
                LoadCostRTMint = zeros(52,288);
                for bus = 1:52
                    for hour = 1:24
                        for int = 1:12
                            if (hour-1)*12+int <= (288 - RTC_periods)
                                LoadCostRTM(bus,1) = LoadCostRTM(bus,1) +...
                                    1/12*(most_busload((hour-1)*12+int,bus) - most_busload_DAM(hour,bus))*...
                                    RTD_LMP(bus,(hour-1)*12+int);
                                
                                LoadCostRTMint(bus,(hour-1)*12+int) = 1/12*(most_busload((hour-1)*12+int,bus) - most_busload_DAM(hour,bus))*...
                                    RTD_LMP(bus,(hour-1)*12+int);
                            end
                        end
                    end
                end
            
            
            Cost2LoadsCong = sum(DAMAP(1:59)) + sum(LoadCostRTM(1:52,1)) + sum(LoadCostDAM(1:52,1));
            
            DAMresults(3,Case*4+d) = Cost2LoadsCong;
    %% Load Cost By Region
        RTMloadCostByRegionHr = zeros(4,288); 
        for hour = 1:24
            for int = 1:12
                if (hour-1)*12+int <= (288 - RTC_periods)
 RTMloadCostByRegionHr(1,(hour-1)*12+int) = RTD_LMP(1,(hour-1)*12+int) *(most_busload((hour-1)*12+int,1)  - most_busload_DAM(hour,1))+...
                                            RTD_LMP(9,(hour-1)*12+int) *(most_busload((hour-1)*12+int,9)  - most_busload_DAM(hour,9))+...
                                            RTD_LMP(33,(hour-1)*12+int)*(most_busload((hour-1)*12+int,33) - most_busload_DAM(hour,33))+...
                                            RTD_LMP(36,(hour-1)*12+int)*(most_busload((hour-1)*12+int,36) - most_busload_DAM(hour,36))+...
                                            RTD_LMP(37,(hour-1)*12+int)*(most_busload((hour-1)*12+int,37) - most_busload_DAM(hour,37))+...
                                            RTD_LMP(39,(hour-1)*12+int)*(most_busload((hour-1)*12+int,39) - most_busload_DAM(hour,39))+...
                                            RTD_LMP(40,(hour-1)*12+int)*(most_busload((hour-1)*12+int,40) - most_busload_DAM(hour,40))+...
                                            RTD_LMP(41,(hour-1)*12+int)*(most_busload((hour-1)*12+int,41) - most_busload_DAM(hour,41))+...
                                            RTD_LMP(42,(hour-1)*12+int)*(most_busload((hour-1)*12+int,42) - most_busload_DAM(hour,42))+...
                                            RTD_LMP(44,(hour-1)*12+int)*(most_busload((hour-1)*12+int,44) - most_busload_DAM(hour,44))+...
                                            RTD_LMP(45,(hour-1)*12+int)*(most_busload((hour-1)*12+int,45) - most_busload_DAM(hour,45))+...
                                            RTD_LMP(46,(hour-1)*12+int)*(most_busload((hour-1)*12+int,46) - most_busload_DAM(hour,46))+...
                                            RTD_LMP(47,(hour-1)*12+int)*(most_busload((hour-1)*12+int,47) - most_busload_DAM(hour,47))+...
                                            RTD_LMP(48,(hour-1)*12+int)*(most_busload((hour-1)*12+int,48) - most_busload_DAM(hour,48))+...
                                            RTD_LMP(49,(hour-1)*12+int)*(most_busload((hour-1)*12+int,49) - most_busload_DAM(hour,49))+...
                                            RTD_LMP(50,(hour-1)*12+int)*(most_busload((hour-1)*12+int,50) - most_busload_DAM(hour,50))+...
                                            RTD_LMP(51,(hour-1)*12+int)*(most_busload((hour-1)*12+int,51) - most_busload_DAM(hour,51))+...
                                            RTD_LMP(52,(hour-1)*12+int)*(most_busload((hour-1)*12+int,52) - most_busload_DAM(hour,52));

            RTMloadCostByRegionHr(2,(hour-1)*12+int) =   RTD_LMP(3,(hour-1)*12+int)*(most_busload((hour-1)*12+int,3) - most_busload_DAM(hour,3))+...
                                            RTD_LMP(4,(hour-1)*12+int)*(most_busload((hour-1)*12+int,4) - most_busload_DAM(hour,4))+...
                                            RTD_LMP(7,(hour-1)*12+int)*(most_busload((hour-1)*12+int,7) - most_busload_DAM(hour,7))+...
                                            RTD_LMP(8,(hour-1)*12+int)*(most_busload((hour-1)*12+int,8) - most_busload_DAM(hour,8))+...
                                            RTD_LMP(25,(hour-1)*12+int)*(most_busload((hour-1)*12+int,25) - most_busload_DAM(hour,25));
                                        
            RTMloadCostByRegionHr(3,(hour-1)*12+int) =   RTD_LMP(12,(hour-1)*12+int)*(most_busload((hour-1)*12+int,12) - most_busload_DAM(hour,12))+...
                                            RTD_LMP(15,(hour-1)*12+int)*(most_busload((hour-1)*12+int,15) - most_busload_DAM(hour,15))+...
                                            RTD_LMP(16,(hour-1)*12+int)*(most_busload((hour-1)*12+int,16) - most_busload_DAM(hour,16))+...
                                            RTD_LMP(18,(hour-1)*12+int)*(most_busload((hour-1)*12+int,18) - most_busload_DAM(hour,18))+...
                                            RTD_LMP(20,(hour-1)*12+int)*(most_busload((hour-1)*12+int,20) - most_busload_DAM(hour,20))+...
                                            RTD_LMP(27,(hour-1)*12+int)*(most_busload((hour-1)*12+int,27) - most_busload_DAM(hour,27));

            RTMloadCostByRegionHr(4,(hour-1)*12+int) =   RTD_LMP(21,(hour-1)*12+int)*(most_busload((hour-1)*12+int,21) - most_busload_DAM(hour,21))+...
                                            RTD_LMP(23,(hour-1)*12+int)*(most_busload((hour-1)*12+int,23) - most_busload_DAM(hour,23))+...
                                            RTD_LMP(24,(hour-1)*12+int)*(most_busload((hour-1)*12+int,24) - most_busload_DAM(hour,24));

                end
            end
        end
        for Region = 1:4
            RTMloadCostByRegion(Region,(Case*4+d)) = sum(RTMloadCostByRegionHr(Region,1:288))./1000./12; 
        end
        %% Print Summary
         %Gen_Net_Rev.  =  DAM Rev    +  RTD Rev     - RTD Op Cost - RTD SUP Cost
          Summaryy(:,7) = Summaryy(:,1)+Summaryy(:,4)-Summaryy(:,5)-Summaryy(:,6);
          MAP = zeros(59,1);
          for gen = 1:59
              if Summaryy(gen,7) < 0
                  MAP(gen,1) = - Summaryy(gen,7);
              end
          end
          Summaryy(:,8) = MAP;
          AllRunsSummary(1:59,(1+8*(Case*4+d-1)):(8+8*(Case*4+d-1))) = Summaryy;
          
      %% Congestion Charges
        %DAM Congestion Charge
            CC_DAM = sum(LoadCostDAM(1:52,1)) - sum(Gen_DAM_Revenue(1:59,1));
        %RTM Congestion Charge
            CC_RTM = sum(LoadCostRTM(1:52,1)) - sum(Gen_RTD_Revenue(1:59,1));
        %MAP Congestion Charge
            %Flat Case MAP 
                    %2016   2016    2016    2016    2030    2030    2030    2030    (Rows are 1:15 gens)
                    %1      2       3       4       1       2       3       4
                MAP_Flat_all = [...
0	0	0	0	0	0	0	0	;
0	0	0	0	0	0	0	0	;
0	0	0	0	0	0	0	0	;
0	1373	0	0	0	0	0	0	;
0	0	0	0	0	0	0	0	;
0	0	0	0	0	0	0	6280	;
0	0	0	0	0	0	0	0	;
0	0	0	0	0	12769	0	21264	;
0	0	0	0	0	0	0	0	;
0	0	0	0	0	8928	0	1658	;
0	7542	0	6074	0	0	0	0	;
12	2128	0	997	4709	0	1447	9	;
16	0	0	15	2134	2299	920	963	;
0	0	0	0	0	0	0	0	;
0	0	0	0	0	0	0	0	;
                        ];

                    %These are hard coded in.  If the flat case changes, these should be updated.  REMEMBER
            %MAP
            MAP_Flat = zeros(59,1);
            MAP_Flat(1:15,1) = MAP_Flat_all(:,Case*4+d);
            
            CC_MAP = sum(MAP(1:59,1)) - sum(MAP_Flat(1:59,1));
            
            CC_Tot = CC_DAM + CC_RTM + CC_MAP;
            CC_results(1,Case*4+d) = CC_DAM;
            CC_results(2,Case*4+d) = CC_RTM;
            CC_results(3,Case*4+d) = CC_MAP;
            CC_results(4,Case*4+d) = CC_Tot;

          
end 
end
toc

save RunData AllRunsSummary CC_results DAMresults%"load temp" then line above in 'try'







