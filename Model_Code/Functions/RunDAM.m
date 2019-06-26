function [DAMresults, DAMifFlows, Summaryy] = ...
    RunDAM(scen, Case, date, input_params)
%RunDAM run the day ahead market model for the time period of one day
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
windyCurt = input_params(11);
solarCurt = input_params(12);
hydroCurt = input_params(13);
otherCurt = input_params(14);
windyCurtFactor = input_params(15);
solarCurtFactor = input_params(16);
hydroCurtFactor = input_params(17);
otherCurtFactor = input_params(18);
IncreasedDAMramp = input_params(19);
IncreasedRTCramp_Steam = input_params(20);
IncreasedRTDramp_Steam = input_params(21);
IncreasedRTCramp_CC = input_params(22);
IncreasedRTDramp_CC = input_params(23);
DAMrampFactor = input_params(25);
RTCrampFactor_Steam = input_params(25);
RTDrampFactor_Steam = input_params(26);
RTCrampFactor_CC = input_params(27);
IncreasedRTDramp_CC = input_params(28);
killNuke = input_params(29);
droppit = input_params(30);
printRTC = input_params(31);
Avg5mingencompare = input_params(32);
minrunshorter = input_params(33);
useinstant = input_params(34);
mustRun = input_params(35);
undrbidfac = input_params(36);
most_period_count = input_params(37);
most_period_count_DAM = input_params(38);
RTM_option = input_params(39);
case_start = input_params(40);
d_start = input_params(41);
Fig_save = input_params(42);
VERBOSE = input_params(43);
vis_prof = input_params(44);

[A2F_Load_buses, GHI_Load_buses, NYC_Load_buses, LIs_Load_buses, NYCA_Load_buses, NEw_Load_buses, PJM_Load_buses,...
    A2F_load_bus_count,GHI_load_bus_count, NYC_load_bus_count, LIs_load_bus_count, NYCA_load_bus_count, NEw_load_bus_count, PJM_load_bus_count,...
    A2F_Gen_buses, GHI_Gen_buses, NYC_Gen_buses, LIs_Gen_buses, NEw_Gen_buses, PJM_Gen_buses, ...
    A2F_gen_bus_count, GHI_gen_bus_count, NYC_gen_bus_count, LIs_gen_bus_count, NEw_gen_bus_count, PJM_Gen_bus_count,...
    A2F_RE_buses, GHI_RE_buses, NYC_RE_buses, LIs_RE_buses, NEw_RE_buses, PJM_RE_buses,...
    A2F_gens, GHI_gens, NYC_gens, LIs_gens, NEw_gens, PJM_gens,...
    map_Array, BoundedIF, lims_Array] = NYCArgnparms;

%Add MOST constant parameter names
define_constants;

%Define initial data
casefile = 'case_nyiso16'; %!!!!!
mpc = loadcase(casefile);
xgd = loadxgendata('xgd_DAM' , mpc); %!!!!!

%Determine number of thermal gens
[therm_gen_count,~] =  size(mpc.gen(:, GEN_BUS));

%Reduce RAMP!
%%%%%Why are only generators 4 - 11 included in this? Generators 12 & 13
%%%%%are gas turbines, so should be included, and 9 -- the NEISO import --
%%%%%should probably not be. 
if IncreasedDAMramp == 1
    for col = [RAMP_AGC, RAMP_10, RAMP_30] 
        mpc.gen(4:11,col) = mpc.gen(4:11,col).*DAMrampFactor; 
    end
end

%Retire a Nuke Unit?
for gen = 2:killNuke
    xgd.CommitKey(gen) = -1;
end

% Read in renewable energy profiles and/or read data from wrfout files
date = datestr(date,'yyyymmdd');
load(strcat(scen,'_REdat_',date), 'wind','hydro','pv','btm','bio','lfg')

% Define scenario-specific parameters
[wind, hydro, pv, btm, bio, lfg, ees, ev, stoch, Case_Name_String] = ...
    feval(scen, wind, hydro, pv, btm, bio, lfg);

% Format Date for plots
datestring = datestr(datetime(date,'InputFormat','yyyyMMdd'), 'mmm-dd-yyyy');

%%%%% The following code is not ready for implementation yet...
% %% Check for stochastic simulation, and format input data
% if exist('stoch','var') > 0
%     stoed = 1;
%     if iscell(stoch.loadprof) == 1 
%         get_hist_loadprof = 1;
%     elseif ischar(stoch.loadprof) == 1
%         sto_loadprof = load(stoch.loadprof);
%         stoch.loadprof = sto_loadprof;
%     end
%     if iscell(stoch.windprof) == 1 
%         get_hist_windprof = 1; %%%%% Wait on this for now; no access to historical data
%     elseif ischar(stoch.windprof) == 1
%         sto_windprof = load(stoch.windprof);
%         stoch.windprof = sto_windprof;
%     end
%     if iscell(stoch.PVprof) == 1
%         get_hist_PVprof = 1; %%%%% Wait on this for now; no access to historical data
%     elseif ischar(stoch.PVprof) == 1
%         sto_PVprof = load(stoch.PVprof);
%         stoch.PVprof = sto_PVprof;
%     end
%     
% else
%     stoed = 0;
% end

%% Get Net Load from OASIS
[A2F_exist_NL, GHI_exist_NL, NYC_exist_NL, LIs_exist_NL,~,~,~,~] = NYISOnetloadPRE_DAM(datestring, undrbidfac, useinstant);

%%%%% The following code is not ready for implementation yet...
% if get_hist_loadprof == 1
%     load_dates = stoch.loadprof;
%     stoch.loadprof = zeros(24,length(load_dates),4);
%     for ii = 1:length(load_dates)
%         indat = load_dates{ii};
%         [~,~,~,~, A2F_exist_NL, GHI_exist_NL, NYC_exist_NL, LIs_exist_NL] = ...
%             NYISOnetloadPRE_DAM(indat, undrbidfac, useinstant);
%         stoch.loadprof(:,ii,1) = A2F_exist_NL;
%         stoch.loadprof(:,ii,2) = GHI_exist_NL;
%         stoch.loadprof(:,ii,3) = NYC_exist_NL;
%         stoch.loadprof(:,ii,4) = LIs_exist_NL;
%     end
% end



%% Calculate Regional Load Only

% Calculate: Load Only (i.e., Net Load from NYISO + BTM Generation)
A2F_Load_Only = A2F_exist_NL + btm.A2F_genin;
GHI_Load_Only = GHI_exist_NL + btm.GHI_genin;
NYC_Load_Only = NYC_exist_NL + btm.NYC_genin;
LIs_Load_Only = LIs_exist_NL + btm.LIs_genin;

% A2F_Load_Only = A2F_exist_NL + btm.A2F_genin ./btm.A2F_cap .*btm.A2F_exist_cap;
% GHI_Load_Only = GHI_exist_NL + btm.GHI_genin ./btm.GHI_cap .*btm.GHI_exist_cap;
% NYC_Load_Only = NYC_exist_NL + btm.NYC_genin ./btm.NYC_cap .*btm.NYC_exist_cap;
% LIs_Load_Only = LIs_exist_NL + btm.LIs_genin ./btm.LIs_cap .*btm.LIs_exist_cap;
NYCA_Load_Only = A2F_Load_Only + GHI_Load_Only + NYC_Load_Only + LIs_Load_Only;


%% Calculate generation per MW installed capacity

% Call PerMW() for each resource to calculate the normalized gen profs
wind = PerMW(wind);
hydro = PerMW(hydro);
pv = PerMW(pv);
btm = PerMW(btm);
bio = PerMW(bio);
lfg = PerMW(lfg);


%% Renewable generation under current scenario

% Call ScenProfs() for each resource to create the scenario gen profs
wind = ScenProfs(wind);
hydro = ScenProfs(hydro);
pv = ScenProfs(pv);
btm = ScenProfs(btm);
bio = ScenProfs(bio);
lfg = ScenProfs(lfg);

NYCA_scen_BTM_gen = btm.A2F_gen + btm.GHI_gen + btm.NYC_gen + btm.LIs_gen;

%%%%% Pretty sure the following has been taken care of via structural
%%%%% changes to the code but some of the overall sums may cause problems.
% % Calculate generation profiles under current Case
% A2F_ITM_CASE_windy_Gen = A2F_ITM_wind_gen_per_iCAP_MW  .*A2F_ITM_CASE_wind_cap;
% A2F_ITM_CASE_hydro_Gen = A2F_ITM_hydro_gen_per_iCAP_MW .*A2F_ITM_CASE_hydro_cap;
% A2F_ITM_CASE_solar_Gen = A2F_ITM_PV_gen_per_iCAP_MW    .*A2F_ITM_CASE_PV_cap;
% A2F_ITM_CASE_other_Gen = A2F_ITM_PV_gen_per_iCAP_MW    .*A2F_ITM_CASE_PV_cap + ...
%     A2F_ITM_Bio_gen_per_iCAP_MW   .*A2F_ITM_CASE_Bio_cap + ...
%     A2F_ITM_LFG_gen_per_iCAP_MW   .*A2F_ITM_CASE_LFG_cap;
% A2F_ITM_CASE_other_Gen =A2F_ITM_Bio_gen_per_iCAP_MW   .*A2F_ITM_CASE_Bio_cap + ...
%     A2F_ITM_LFG_gen_per_iCAP_MW   .*A2F_ITM_CASE_LFG_cap;
% A2F_ITM_CASE_Gen = A2F_ITM_CASE_windy_Gen + A2F_ITM_CASE_hydro_Gen + A2F_ITM_CASE_other_Gen;
% A2F_ITM_CASE_Gen = A2F_ITM_CASE_windy_Gen + A2F_ITM_CASE_hydro_Gen + ...
%     A2F_ITM_CASE_solar_Gen + A2F_ITM_CASE_other_Gen;

% GHI_ITM_CASE_windy_Gen = GHI_ITM_wind_gen_per_iCAP_MW  .*GHI_ITM_CASE_wind_cap;
% GHI_ITM_CASE_hydro_Gen = GHI_ITM_hydro_gen_per_iCAP_MW .*GHI_ITM_CASE_hydro_cap;
% GHI_ITM_CASE_solar_Gen = GHI_ITM_PV_gen_per_iCAP_MW    .*GHI_ITM_CASE_PV_cap;
% GHI_ITM_CASE_other_Gen = GHI_ITM_PV_gen_per_iCAP_MW    .*GHI_ITM_CASE_PV_cap + ...
%     GHI_ITM_Bio_gen_per_iCAP_MW   .*GHI_ITM_CASE_Bio_cap + ...
%     GHI_ITM_LFG_gen_per_iCAP_MW   .*GHI_ITM_CASE_LFG_cap;
% GHI_ITM_CASE_other_Gen = GHI_ITM_Bio_gen_per_iCAP_MW   .*GHI_ITM_CASE_Bio_cap + ...
%     GHI_ITM_LFG_gen_per_iCAP_MW   .*GHI_ITM_CASE_LFG_cap;
% GHI_ITM_CASE_Gen = GHI_ITM_CASE_windy_Gen + GHI_ITM_CASE_hydro_Gen + GHI_ITM_CASE_other_Gen;
% GHI_ITM_CASE_Gen = GHI_ITM_CASE_windy_Gen + GHI_ITM_CASE_hydro_Gen + ...
%     GHI_ITM_CASE_solar_Gen + GHI_ITM_CASE_other_Gen;

% NYC_ITM_CASE_windy_Gen = NYC_ITM_wind_gen_per_iCAP_MW  .*NYC_ITM_CASE_wind_cap;
% NYC_ITM_CASE_hydro_Gen = NYC_ITM_hydro_gen_per_iCAP_MW .*NYC_ITM_CASE_hydro_cap;
% NYC_ITM_CASE_solar_Gen = NYC_ITM_PV_gen_per_iCAP_MW    .*NYC_ITM_CASE_PV_cap;
% NYC_ITM_CASE_other_Gen = NYC_ITM_PV_gen_per_iCAP_MW    .*NYC_ITM_CASE_PV_cap + ...
%     NYC_ITM_Bio_gen_per_iCAP_MW   .*NYC_ITM_CASE_Bio_cap + ...
%     NYC_ITM_LFG_gen_per_iCAP_MW   .*NYC_ITM_CASE_LFG_cap; 
% NYC_ITM_CASE_other_Gen = NYC_ITM_Bio_gen_per_iCAP_MW   .*NYC_ITM_CASE_Bio_cap + ...
%     NYC_ITM_LFG_gen_per_iCAP_MW   .*NYC_ITM_CASE_LFG_cap;
% NYC_ITM_CASE_Gen = NYC_ITM_CASE_windy_Gen + NYC_ITM_CASE_hydro_Gen + NYC_ITM_CASE_other_Gen;
% NYC_ITM_CASE_Gen = NYC_ITM_CASE_windy_Gen + NYC_ITM_CASE_hydro_Gen + ...
%     NYC_ITM_CASE_solar_Gen + NYC_ITM_CASE_other_Gen;

% LIs_ITM_CASE_windy_Gen = LIs_ITM_wind_gen_per_iCAP_MW  .*LIs_ITM_CASE_wind_cap;
% LIs_ITM_CASE_hydro_Gen = LIs_ITM_hydro_gen_per_iCAP_MW .*LIs_ITM_CASE_hydro_cap;
% LIs_ITM_CASE_solar_Gen = LIs_ITM_PV_gen_per_iCAP_MW    .*LIs_ITM_CASE_PV_cap;
% LIs_ITM_CASE_other_Gen = LIs_ITM_PV_gen_per_iCAP_MW    .*LIs_ITM_CASE_PV_cap + ...
%     LIs_ITM_Bio_gen_per_iCAP_MW   .*LIs_ITM_CASE_Bio_cap + ...
%     LIs_ITM_LFG_gen_per_iCAP_MW   .*LIs_ITM_CASE_LFG_cap;
% LIs_ITM_CASE_other_Gen = LIs_ITM_Bio_gen_per_iCAP_MW   .*LIs_ITM_CASE_Bio_cap + ...
%     LIs_ITM_LFG_gen_per_iCAP_MW   .*LIs_ITM_CASE_LFG_cap;
% LIs_ITM_CASE_Gen = LIs_ITM_CASE_windy_Gen + LIs_ITM_CASE_hydro_Gen + LIs_ITM_CASE_other_Gen;
% LIs_ITM_CASE_Gen = LIs_ITM_CASE_windy_Gen + LIs_ITM_CASE_hydro_Gen + ...
%     LIs_ITM_CASE_solar_Gen + LIs_ITM_CASE_other_Gen;

% Tot_ITM_CASE_Gen = A2F_ITM_CASE_Gen + GHI_ITM_CASE_Gen + ...
%     NYC_ITM_CASE_Gen + LIs_ITM_CASE_Gen;

%% Calculate Regional Net Load
% Scenario Net Load (includes new BTM generation)
A2F_scen_NL = (A2F_Load_Only - btm.A2F_gen);
GHI_scen_NL = (GHI_Load_Only - btm.GHI_gen);
NYC_scen_NL = (NYC_Load_Only - btm.NYC_gen);
LIs_scen_NL = (LIs_Load_Only - btm.LIs_gen);
NYCA_scen_NL = A2F_scen_NL + GHI_scen_NL + NYC_scen_NL + LIs_scen_NL;


%% Populate Net Load into MOST
most_busload = zeros(most_period_count,52);
int_start = 1;
int_stop  = most_period_count;
for int = int_start:int_stop
    %Distribute P_load
    i=1:A2F_load_bus_count;
    most_busload(int, A2F_Load_buses(i)) = A2F_scen_NL(int)./A2F_load_bus_count;
    i=1:GHI_load_bus_count;
    most_busload(int, GHI_Load_buses(i)) = GHI_scen_NL(int)./GHI_load_bus_count;
    i=1:NYC_load_bus_count;
    most_busload(int, NYC_Load_buses(i)) = NYC_scen_NL(int)./NYC_load_bus_count;
    i=1:LIs_load_bus_count;
    most_busload(int, LIs_Load_buses(i)) = LIs_scen_NL(int)./LIs_load_bus_count;
end


%% Modify for DAM (24 periods)
%Take average of load values over each hour
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


%% Renewable Capacity for the current case
%Renwable capacity by region
A2F_scen_REcap = wind.A2F_cap + hydro.A2F_cap + ...
    pv.A2F_cap + bio.A2F_cap + lfg.A2F_cap;
GHI_scen_REcap = wind.GHI_exist_cap + hydro.GHI_exist_cap + ...
    pv.GHI_cap + bio.GHI_cap + lfg.GHI_cap;
NYC_scen_REcap = wind.NYC_cap + hydro.NYC_cap + ...
    pv.NYC_cap + bio.NYC_cap + lfg.NYC_cap;
LIs_scen_REcap = wind.LIs_cap + hydro.LIs_cap + ...
    pv.LIs_cap + bio.LIs_cap + lfg.LIs_cap;

%Renewable capacity by type
%%%%%These values are unused.
% TOT_ITM_CASE_wind_cap   = A2F_existing_ITM_wind_ICAP  + GHI_existing_ITM_wind_ICAP + ...
%     NYC_existing_ITM_wind_ICAP  + LIs_existing_ITM_wind_ICAP  + A2F_ITM_CASE_wind_cap + ...
%     GHI_ITM_CASE_wind_cap  + NYC_ITM_CASE_wind_cap + LIs_ITM_CASE_wind_cap;
% TOT_ITM_CASE_hydro_cap  = A2F_existing_ITM_hydro_ICAP + GHI_existing_ITM_hydro_ICAP +...
%     NYC_existing_ITM_hydro_ICAP + LIs_existing_ITM_hydro_ICAP + A2F_ITM_CASE_hydro_cap +...
%     GHI_ITM_CASE_hydro_cap + NYC_ITM_CASE_hydro_cap + LIs_ITM_CASE_hydro_cap;
% TOT_ITM_CASE_PV_cap     = A2F_existing_ITM_PV_ICAP + GHI_existing_ITM_PV_ICAP + ...
%     NYC_existing_ITM_PV_ICAP + LIs_existing_ITM_PV_ICAP + A2F_ITM_CASE_PV_cap + ...
%     GHI_ITM_CASE_PV_cap    + NYC_ITM_CASE_PV_cap + LIs_ITM_CASE_PV_cap;
% TOT_ITM_CASE_Bio_cap    = A2F_existing_ITM_Bio_ICAP   + GHI_existing_ITM_Bio_ICAP   + ...
%     NYC_existing_ITM_Bio_ICAP   + LIs_existing_ITM_Bio_ICAP   + A2F_ITM_CASE_Bio_cap   + ...
%     GHI_ITM_CASE_Bio_cap   + NYC_ITM_CASE_Bio_cap + LIs_ITM_CASE_Bio_cap;
% TOT_ITM_CASE_LFG_cap    = A2F_existing_ITM_LFG_ICAP   + GHI_existing_ITM_LFG_ICAP   + ...
%     NYC_existing_ITM_LFG_ICAP   + LIs_existing_ITM_LFG_ICAP   + A2F_ITM_CASE_LFG_cap   + ...
%     GHI_ITM_CASE_LFG_cap   + NYC_ITM_CASE_LFG_cap + LIs_ITM_CASE_LFG_cap;


%% First 5min generation value vs. Avg hourly value
if Avg5mingencompare == 1
    %Statewide generation totals by renewable type
    TOT_ITM_windy_gen_profile = A2F_ITM_windy_gen_tot + GHI_ITM_windy_gen_tot + NYC_ITM_windy_gen_tot + LIs_ITM_windy_gen_tot;
    TOT_ITM_hydro_gen_profile = A2F_ITM_hydro_gen_tot + GHI_ITM_hydro_gen_tot + NYC_ITM_hydro_gen_tot + LIs_ITM_hydro_gen_tot;
    TOT_ITM_solar_gen_profile = A2F_ITM_solar_gen_tot + GHI_ITM_solar_gen_tot + NYC_ITM_solar_gen_tot + LIs_ITM_solar_gen_tot;
    TOT_ITM_other_gen_profile = A2F_ITM_other_gen_tot + GHI_ITM_other_gen_tot + NYC_ITM_other_gen_tot + LIs_ITM_other_gen_tot;
    
    %get 24 hr profile for all renewables together
    TOT_ITM_profile = TOT_ITM_windy_gen_profile + TOT_ITM_hydro_gen_profile + ...
        TOT_ITM_solar_gen_profile + TOT_ITM_other_gen_profile;
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


%% Format Renewable and Load Profiles for MOST input

% Wind
most_bus_rengen_windy = zeros(most_period_count, length(mpc.bus));
for int = int_start:int_stop
    %Distribute wind generation evenly across all gen buses
    i=1:A2F_gen_bus_count;
    most_bus_rengen_windy(int, A2F_Gen_buses(i)) = wind.A2F_gen(int)./A2F_gen_bus_count;
    i=1:GHI_gen_bus_count;
    most_bus_rengen_windy(int, GHI_Gen_buses(i)) = wind.GHI_gen(int)./GHI_gen_bus_count;
    i=1:NYC_gen_bus_count;
    most_bus_rengen_windy(int, NYC_Gen_buses(i)) = wind.NYC_gen(int)./NYC_gen_bus_count;
    i=1:LIs_gen_bus_count;
    most_bus_rengen_windy(int, LIs_Gen_buses(i)) = wind.LIs_gen(int)./LIs_gen_bus_count;
end

%Remove empty rows 
most_bus_rengen_windy(:,62) = []; %62 is the reference bus
most_bus_rengen_windy(:,1:52) = []; %Buses 1 - 52 may be load buses... however some are also listed as RE buses.

%DAM Averages - take average of load values in an hour
if length(wind.A2F_gen) > 24
    most_windy_gen_DAM = zeros(most_period_count_DAM,15);
    for int_DAM = int_start_DAM: int_stop_DAM
        if useinstant ==1
            most_windy_gen_DAM(int_DAM,:) = most_bus_rengen_windy(int_DAM*12-11,:);
        else
            most_windy_gen_DAM(int_DAM,:) = mean(most_bus_rengen_windy(int_DAM*12-11:int_DAM*12,:));
        end
    end
else    
    most_windy_gen_DAM = most_bus_rengen_windy;    
end

% Visualize input profiles
if vis_prof == 1
    RE_inprof_vis(most_windy_gen_DAM, 'Wind')
end


% Hydro
most_bus_rengen_hydro = zeros(most_period_count,68);
for int = int_start:int_stop
    %Distribute hydro generation evenly across all gen buses
    i=1:A2F_gen_bus_count;
    most_bus_rengen_hydro(int, A2F_Gen_buses(i)) = hydro.A2F_gen(int)./A2F_gen_bus_count;
    i=1:GHI_gen_bus_count;
    most_bus_rengen_hydro(int, GHI_Gen_buses(i)) = hydro.GHI_gen(int)./GHI_gen_bus_count;
    i=1:NYC_gen_bus_count;
    most_bus_rengen_hydro(int, NYC_Gen_buses(i)) = hydro.NYC_gen(int)./NYC_gen_bus_count;
    i=1:LIs_gen_bus_count;
    most_bus_rengen_hydro(int, LIs_Gen_buses(i)) = hydro.LIs_gen(int)./LIs_gen_bus_count;
end

%Remove empty rows
most_bus_rengen_hydro(:,62) = [];
most_bus_rengen_hydro(:,1:52) = [];

%DAM Averages - take average of load values in an hour
if length(hydro.A2F_gen) > 24
    most_hydro_gen_DAM = zeros(most_period_count_DAM,15);
    for int_DAM = int_start_DAM: int_stop_DAM
        if useinstant == 1
            most_hydro_gen_DAM(int_DAM,:) = most_bus_rengen_hydro(int_DAM*12-11,:);
        else
            most_hydro_gen_DAM(int_DAM,:) = mean(most_bus_rengen_hydro(int_DAM*12-11:int_DAM*12,:));
        end
    end
else    
    most_hydro_gen_DAM = most_bus_rengen_hydro;    
end

% Visualize input profiles
if vis_prof == 1
    RE_inprof_vis(most_hydro_gen_DAM, 'Hydro')
end


% Solar
most_bus_rengen_solar = zeros(most_period_count,68);
for int = int_start:int_stop
    %Distribute solar generation evenly across all gen buses
    i=1:A2F_gen_bus_count;
    most_bus_rengen_solar(int, A2F_Gen_buses(i)) = pv.A2F_gen(int)./A2F_gen_bus_count;
    i=1:GHI_gen_bus_count;
    most_bus_rengen_solar(int, GHI_Gen_buses(i)) = pv.GHI_gen(int)./GHI_gen_bus_count;
    i=1:NYC_gen_bus_count;
    most_bus_rengen_solar(int, NYC_Gen_buses(i)) = pv.NYC_gen(int)./NYC_gen_bus_count;
    i=1:LIs_gen_bus_count;
    most_bus_rengen_solar(int, LIs_Gen_buses(i)) = pv.LIs_gen(int)./LIs_gen_bus_count;
end

%Remove empty rows
most_bus_rengen_solar(:,62) = [];
most_bus_rengen_solar(:,1:52) = [];

%DAM Averages - take average of load values in an hour
if length(pv.A2F_gen) > 24
    most_solar_gen_DAM = zeros(most_period_count_DAM,15);
    for int_DAM = int_start_DAM:int_stop_DAM
        if useinstant ==1
            most_solar_gen_DAM(int_DAM,:) = most_bus_rengen_solar(int_DAM*12-11,:);
        else
            most_solar_gen_DAM(int_DAM,:) = mean(most_bus_rengen_solar(int_DAM*12-11:int_DAM*12,:));
        end
    end
else    
    most_solar_gen_DAM = most_bus_rengen_solar;
end

% Visualize input profiles
if vis_prof == 1
    RE_inprof_vis(most_solar_gen_DAM, 'Solar')
end

% Other
most_bus_rengen_other = zeros(most_period_count,68);
for int = int_start:int_stop
    %Distribute other renewable generation evenly across all gen buses
    i=1:A2F_gen_bus_count;
    most_bus_rengen_other(int, A2F_Gen_buses(i)) = (bio.A2F_gen(int) + lfg.A2F_gen(int))./A2F_gen_bus_count;
    i=1:GHI_gen_bus_count;
    most_bus_rengen_other(int, GHI_Gen_buses(i)) = (bio.GHI_gen(int) + lfg.GHI_gen(int))./GHI_gen_bus_count;
    i=1:NYC_gen_bus_count;
    most_bus_rengen_other(int, NYC_Gen_buses(i)) = (bio.NYC_gen(int) + lfg.NYC_gen(int))./NYC_gen_bus_count;
    i=1:LIs_gen_bus_count;
    most_bus_rengen_other(int, LIs_Gen_buses(i)) = (bio.LIs_gen(int) + lfg.LIs_gen(int))./LIs_gen_bus_count;
end

%Remove empty rows
most_bus_rengen_other(:,62) = [];
most_bus_rengen_other(:,1:52) = [];

%DAM Averages - take average of load values in an hour
if length(bio.A2F_gen) > 24
    most_other_gen_DAM = zeros(most_period_count_DAM,15);
    for int_DAM = int_start_DAM: int_stop_DAM
        if useinstant ==1
            most_other_gen_DAM(int_DAM,:) = most_bus_rengen_other(int_DAM*12-11,:);
        else
            most_other_gen_DAM(int_DAM,:) = mean(most_bus_rengen_other(int_DAM*12-11:int_DAM*12,:));
        end
    end
else    
    most_other_gen_DAM = most_bus_rengen_other;    
end

% Visualize input profiles
if vis_prof == 1
    RE_inprof_vis(most_other_gen_DAM, 'Other')
    prompt = 'Press any key when you are finished checking the profiles';
    input(prompt,'s');
end

%%%%% The following is commented out because it's unused
%Determine amount of thermal generation needed
% Tot_ITM_Gen = Tot_ITM_CASE_Gen + A2F_existing_ITM_Gen;
% Tot_BTM_Gen = NYCA_existing_BTM_gen + NYCA_CASE_BTM_gen;
% demand = NYCA_scen_NL - Tot_ITM_Gen.';
% 
% demand_DAM = zeros(1,24);
% NYCA_CASE_net_load_DAM = zeros(1,24);
% NYCA_TrueLoad_DAM = zeros(1,24);
% for t = 1:24
%     demand_DAM(t) = mean(demand(t*12-11:t*12));
%     NYCA_CASE_net_load_DAM(t) = mean(NYCA_CASE_net_load(t*12-11:t*12));
%     NYCA_TrueLoad_DAM(t) = mean(NYCA_TrueLoad(t*12-11:t*12));
% end
% 
% % Load Statistics
% NYCA_TrueLoad_AVG_24hr = mean(NYCA_TrueLoad_DAM);
% NYCA_TrueLoad_AVG_4hr = mean(NYCA_TrueLoad_DAM(10:14));
% NYCA_NetLoad_AVG_24hr = mean(NYCA_CASE_net_load_DAM);
% NYCA_NetLoad_AVG_4hr = mean(NYCA_CASE_net_load_DAM(10:14));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MOST DAM Run
%% Add Renewables to MOST data matpower data and extra generator data

%WIND
%Add wind Generators
[iwind, mpc, xgd] = addwind('wind_gen', mpc, xgd);
%Initialize max & min profiles
profiles = getprofiles(wind_profile_Pmax(iwind) , iwind);
profiles = getprofiles(wind_profile_Pmin(iwind) , profiles);


%HYDRO
%Add hydro Generators
[ihydro, mpc, xgd] = addwind('hydro_gen', mpc, xgd);
%Initialize max & min profiles
profiles = getprofiles(hydro_profile_Pmax(ihydro), profiles);
profiles = getprofiles(hydro_profile_Pmin(ihydro), profiles);


%SOLAR
%Add solar Generators
[isolar, mpc, xgd] = addwind('solar_gen', mpc, xgd);
%Initialize max & min profiles
profiles = getprofiles(solar_profile_Pmax(isolar), profiles); 
profiles = getprofiles(solar_profile_Pmin(isolar), profiles);


%OTHER
%Add other VRE Generators
[iother, mpc, xgd] = addwind('other_gen' , mpc, xgd);
%Initialize max & min profiles
profiles = getprofiles(other_profile_Pmax(iother) , profiles); 
profiles = getprofiles(other_profile_Pmin(iother) , profiles);


%LOAD
%Initialize load profile
profiles = getprofiles('load_profile' , profiles);


%STORAGE
%Add utility-scale batteries
util_bat = storage_gen(ees, A2F_Load_buses, GHI_Load_buses, NYC_Load_buses, LIs_Load_buses, NYCA_Load_buses, NEw_Load_buses, PJM_Load_buses,...
    A2F_load_bus_count,GHI_load_bus_count, NYC_load_bus_count, LIs_load_bus_count, NYCA_load_bus_count, NEw_load_bus_count, PJM_load_bus_count);

%Push battery data to MOST
[iutilbat, mpc, xgd, storage] = addstorage(util_bat, mpc, xgd);

%EVSE Load
if EVSE == 1
    % Add Storage resources and characterize load and storage resource of EVs
    EV_storage = ...
    EVSE_resource(EVSE_Gold_MWh, EVSE_Gold_MW, NYCA_Load_buses, ...
    A2F_Load_buses, GHI_Load_buses, NYC_Load_buses, LIs_Load_buses, ...
    A2F_load_bus_count, GHI_load_bus_count, ...
    NYC_load_bus_count, LIs_load_bus_count, NYCA_load_bus_count, Case);
    
    % Push battery data to MOST
    [iEVSE, mpc, xgd, storage] = addstorage(EV_storage, mpc, xgd, storage);
    
end


%% Add RE Generator Profiles
%%%%% How can we improve the indexing so we dont need to call out the
%%%%% profile values individually? (i.e. I don't want to have to write
%%%%% profiles(1).values(:,1,:)...

%WIND Profile
%Max Gen
 profiles(1).values(:,1,:) = most_windy_gen_DAM;
%Min Gen (i.e. normalize max gen profile by curtailment factor)
if windyCurt == 1
    profiles(2).values(:,1,:) = most_windy_gen_DAM.*windyCurtFactor;
else
    profiles(2).values(:,1,:) = most_windy_gen_DAM;
end


%HYDRO Profile
%Max Gen
profiles(3).values(:,1,:) = most_hydro_gen_DAM;
%Min Gen (i.e. normalize max gen profile by curtailment factor)
if hydroCurt == 1
    profiles(4).values(:,1,:) = most_hydro_gen_DAM.*hydroCurtFactor;
else
    profiles(4).values(:,1,:) = most_hydro_gen_DAM;
end


%SOLAR Profile
%Max Gen
profiles(5).values(:,1,:) = most_solar_gen_DAM;
%Min Gen (i.e. normalize max gen profile by curtailment factor)
if solarCurt == 1
    profiles(6).values(:,1,:) = most_solar_gen_DAM.*solarCurtFactor;
else
    profiles(6).values(:,1,:) = most_solar_gen_DAM;
end


%OTHER Profile
%Max Gen
profiles(7).values(:,1,:) = most_other_gen_DAM;
%Min Gen (i.e. normalize max gen profile by curtailment factor)
if otherCurt == 1
    profiles(8).values(:,1,:) = most_other_gen_DAM.*otherCurtFactor;
else
    profiles(8).values(:,1,:) = most_other_gen_DAM;
end


%LOAD Profile
profiles(9).values(:,1,:) = most_busload_DAM;


%% Set Initial PG (first period generation) for renewable gens
xgd.InitialPg(iwind) = xgd.InitialPg(iwind) + most_windy_gen_DAM(1,:).';
% xgd.InitialPg(iwind) = xgd.InitialPg(iwind) - 1; %Why was 1 MW subtracted
% here?????
xgd.InitialPg(ihydro) = xgd.InitialPg(ihydro) + most_hydro_gen_DAM(1,:).';
xgd.InitialPg(isolar) = xgd.InitialPg(isolar) + most_solar_gen_DAM(1,:).';
xgd.InitialPg(iother) = xgd.InitialPg(iother) + most_other_gen_DAM(1,:).';


%% Set renewable credit (negative cost) to avoid curtailment
%%%%% Should think about weather or not this accurately captures the
%%%%% fucnction of RECs in a wholesale market. 
mpc.gencost(iwind,6) = REC_wind;
mpc.gencost(ihydro,6) = REC_hydro;
mpc.gencost(isolar,6) = REC_solar;
mpc.gencost(iother,6) = REC_Cost;
mpc.gencost(iwind ,4) = 3; %%%%% This is the polynomial order for the cost function


%% Update generator capacity
%Determine number of renewable gens
[all_gen_count,~] = size(mpc.gen(:, GEN_BUS)); 
ren_gen_count = all_gen_count - therm_gen_count - 32; %%%%% Why 32????? I think this is the number of load buses that info appears irrelevant.

%Determine size of renewable gen in each region
A2F_ind = A2F_scen_REcap/A2F_gen_bus_count;
GHI_ind = GHI_scen_REcap/GHI_gen_bus_count;
NYC_ind = NYC_scen_REcap/NYC_gen_bus_count;
LIs_ind = LIs_scen_REcap/LIs_gen_bus_count;

%Create vector with generator capacity in order
ordered_gen_cap = zeros(ren_gen_count);
for gen = therm_gen_count + 1:all_gen_count
    buss = mpc.gen(gen, 1);
    if ismember(buss, A2F_Gen_buses)
        ordered_gen_cap(gen-therm_gen_count) = A2F_ind;
    elseif ismember(buss, GHI_Gen_buses)
        ordered_gen_cap(gen-therm_gen_count) = GHI_ind;
    elseif ismember(buss, NYC_Gen_buses)
        ordered_gen_cap(gen-therm_gen_count) = NYC_ind;
    elseif ismember(buss, LIs_Gen_buses)
        ordered_gen_cap(gen-therm_gen_count) = LIs_ind;
    end
end

%Update renewable capacity
for ss = 1:ren_gen_count
    mpc.gen(ss + therm_gen_count, PMAX) = ordered_gen_cap(ss); 
end

%Number of intervals in the simulation
nt = most_period_count_DAM; % number of periods


%% Add transmission interface limits
if IFlims == 1
    mpc.if.map = map_Array;
    mpc.if.lims = lims_Array;
    mpc = toggle_iflims_most(mpc, 'on');
end


%% Run MOST Algorithm
%Set MOST options
mpopt = mpoption;
% Use DC network model (default)
mpopt = mpoption(mpopt,'most.dc_model', 1); 
% Use GUROBI as to solve the mip
mpopt = mpoption(mpopt,'most.solver', 'GUROBI');
% Set the verbose option
mpopt = mpoption(mpopt,'verbose', VERBOSE);
% Skip price computation stage for mixed integer problems, see 'help
% miqps_matpower' for details.
mpopt = mpoption(mpopt,'most.skip_prices', 0); 

% Load all data into the MOST data structure
clear mdi
mdi = loadmd(mpc, nt, xgd, storage, [], profiles);

%Set ramp costs to zero
mdi.RampWearCostCoeff = zeros(all_gen_count,24);
for tt = 1:24
    mdi.offer(tt).PositiveActiveReservePrice = zeros(all_gen_count,1);
    mdi.offer(tt).NegativeActiveReservePrice = zeros(all_gen_count,1);
    mdi.offer(tt).PositiveActiveDeltaPrice = zeros(all_gen_count,1);
    mdi.offer(tt).NegativeActiveDeltaPrice = zeros(all_gen_count,1);
    mdi.offer(tt).PositiveLoadFollowReservePrice = zeros(all_gen_count,1);
    mdi.offer(tt).NegativeLoadFollowReservePrice = zeros(all_gen_count,1);
end

% Run the UC/ED algorithm
clear mdo
if IFlims == 1
    mdo = most_if(mdi, mpopt);
else
    mdo = most(mdi, mpopt);
end

% View Results (print results - depending on verbose option)
ms = most_summary(mdo);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Analyze DAM Results
%Initialize Summary
if RTM_option == 1
    Summaryy = zeros(all_gen_count,8);
else
    Summaryy = zeros(all_gen_count,3);
end

%Gen output normalized by capacity (i.e., instantaneous CF)
gen_output = ms.Pg;
gen_capacity = mpc.gen(:, PMAX);

for gen = 1:length(gen_capacity)
    gen_output_percent(gen,:) = gen_output(gen,:)./gen_capacity(gen);
end

%Remove NANs
gen_output_percent(isnan(gen_output_percent)) = 0;

%%%%% This code ARTIFICALLY changes the output: ITS NOT CORRECT; IT'S FOR
%%%%% VISUAL PURPOSES ONLY!!!
% Modify CF for easy differentiation
for gen = 1:therm_gen_count
    for time = 1:24
        %offline
        if gen_output_percent(gen,time) == 0
            gen_output_percent(gen,time) = -gen*.001;
        else
            %at max
            if gen_output_percent(gen,time) == 1
                gen_output_percent(gen,time) = 1+gen*.001;
            end
        end
    end
end


%% GENERATION OUTPUT BY UNIT

Nuke_1_DAM = zeros(1,24);
Nuke_2_DAM = zeros(1,24);
Nuke_3_DAM = zeros(1,24);
Steam_1_DAM = zeros(1,24);
Steam_2_DAM = zeros(1,24);
Steam_3_DAM = zeros(1,24);
Steam_4_DAM = zeros(1,24);
Steam_5_DAM = zeros(1,24);
NEimport_DAM = zeros(1,24);
CCGen_1_DAM = zeros(1,24);
CCGen_2_DAM = zeros(1,24);
GTGen_1_DAM = zeros(1,24);
GTGen_2_DAM = zeros(1,24);
LOHIGen_DAM = zeros(1,24);

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

DAM_gen_storage = zeros(all_gen_count,24);
for hour = 1:24
    for gen = 1:all_gen_count
        DAM_gen_storage(gen,hour) = ms.Pg(gen,hour);
    end
end


%% GENERATION OUTPUT BY TYPE
NukeGenDAM = zeros(1,24);
SteamGenDAM = zeros(1,24);
CCGenDAM = zeros(1,24);
GTGenDAM = zeros(1,24);
RenGen_hydroDAM = zeros(1,24);
RenGen_windyDAM = zeros(1,24);
RenGen_solarDAM = zeros(1,24);
RenGen_otherDAM = zeros(1,24);
BTM4GraphDAM = zeros(1,24);
LOHIGenDAM = zeros(1,24);

%Calculate Generation by type
for iter = 1:int_stop_DAM
    %NUKE
    NukeGenDAM(iter) = ms.Pg(1,iter)+ms.Pg(2,iter)+ms.Pg(3,iter); 
    
    %STEAM
    SteamGenDAM(iter) = ms.Pg(4,iter)+ms.Pg(5,iter)+ms.Pg(6,iter)+ms.Pg(7,iter)+ms.Pg(8,iter);
    
    %CC
    CCGenDAM(iter) = ms.Pg(10,iter)+ms.Pg(11,iter);
    
    %GT
    GTGenDAM(iter) = ms.Pg(12,iter)+ms.Pg(13,iter);
    
    %Import: HQ --> A2F 
    
    LOHIGenDAM(iter) = ms.Pg(14,iter);
    
    %WIND
    RenGen_windyDAM(iter) = 0;
    for renge = iwind(1):iwind(end)
        RenGen_windyDAM(iter) = RenGen_windyDAM(iter) + ms.Pg(renge,iter);
    end
    
    %HYDRO
    RenGen_hydroDAM(iter) = 0;
    for renge = ihydro(1):ihydro(end)
        RenGen_hydroDAM(iter) = RenGen_hydroDAM(iter) + ms.Pg(renge,iter);
    end
    
    %SOLAR
    RenGen_solarDAM(iter) = 0;
    for renge = isolar(1):isolar(end)
        RenGen_solarDAM(iter) = RenGen_solarDAM(iter) + ms.Pg(renge,iter);
    end
    
    %OTHER RENEWABLE
    RenGen_otherDAM(iter) = 0; 
    for renge = iother(1):iother(end)
        RenGen_otherDAM(iter) = RenGen_otherDAM(iter) + ms.Pg(renge,iter);
    end
    
    %BTM
    BTM4GraphDAM(iter) = mean(NYCA_scen_BTM_gen(iter*12-11:iter*12));
    
end


%% GENERATOR REVENUE
Gen_DAM_Revenue = zeros(all_gen_count,1);
if RTM_option == 0
    % ----- DAM ONLY (24 hrs) ----- %
    for gen = 1:all_gen_count
        for DAMhr = 1:24
            Gen_DAM_Revenue(gen) = Gen_DAM_Revenue(gen) + ms.Pg(gen,DAMhr)*ms.lamP(mpc.gen(gen,1),DAMhr);
        end
    end
    
else
    % ----- DAM & RTM (21.5 hrs) ----- %
    for gen = 1:all_gen_count
        for hour = 1:21
            Gen_DAM_Revenue(gen) = Gen_DAM_Revenue(gen) + ms.Pg(gen,hour)*ms.lamP(mpc.gen(gen,1),hour);
        end
        Gen_DAM_Revenue(gen) = Gen_DAM_Revenue(gen) + 0.5*ms.Pg(gen,22)*ms.lamP(mpc.gen(gen,1),22);
    end
    
end
% Record DAM generator revenue in output summary 
Summaryy(:,1) = Gen_DAM_Revenue;


% DAM generator revenue by hour
Gen_DAM_Revenue_hr = zeros(4,24);

if RTM_option == 1
    % ----- DAM & RTM (21.5 hrs) ----- %
    % Upstate (Zones A-F)
    for hour = 1:21
        Gen_DAM_Revenue_hr(1,hour) = ...
            sum(ms.Pg(A2F_gens,hour).*ms.lamP(mpc.gen(A2F_gens,1),hour));
    end
    
    hour = 22;
    Gen_DAM_Revenue_hr(1,hour) = ...
        sum(ms.Pg(A2F_gens,hour).*ms.lamP(mpc.gen(A2F_gens,1),hour))*0.5;
    
    % Zones GHI
    for hour = 1:21
        Gen_DAM_Revenue_hr(2,hour) = ...
            sum(ms.Pg(GHI_gens,hour).*ms.lamP(mpc.gen(GHI_gens,1),hour));
    end
    
    hour = 22;
    Gen_DAM_Revenue_hr(2,hour) = ...
        sum(ms.Pg(GHI_gens,hour).*ms.lamP(mpc.gen(GHI_gens,1),hour))*0.5;
    
    
    % NYC (Zone J)
    for hour = 1:21
        Gen_DAM_Revenue_hr(3,hour) = ...
            sum(ms.Pg(NYC_gens,hour).*ms.lamP(mpc.gen(NYC_gens,1),hour));
    end
    
    hour = 22;
    Gen_DAM_Revenue_hr(3,hour) = ...
        sum(ms.Pg(NYC_gens,hour).*ms.lamP(mpc.gen(NYC_gens,1),hour))*0.5;
    
    
    % Long Island (Zone K)
    for hour = 1:21
        Gen_DAM_Revenue_hr(4,hour) = ...
            sum(ms.Pg(LIs_gens,hour).*ms.lamP(mpc.gen(LIs_gens,1),hour));
    end
    
    hour = 22;
    Gen_DAM_Revenue_hr(4,hour) = ...
        sum(ms.Pg(LIs_gens,hour).*ms.lamP(mpc.gen(LIs_gens,1),hour))*0.5;
    
else 
    % ----- DAM ONLY (24 hrs) ----- %
    % Upstate (Zones A-F)
    for hour = 1:24
        Gen_DAM_Revenue_hr(1,hour) = ...
            sum(ms.Pg(A2F_gens,hour).*ms.lamP(mpc.gen(A2F_gens,1),hour));
    end
    
    % Zones GHI
    for hour = 1:24
        Gen_DAM_Revenue_hr(2,hour) = ...
            sum(ms.Pg(GHI_gens,hour).*ms.lamP(mpc.gen(GHI_gens,1),hour));
    end
    
    % NYC (Zone J)
    for hour = 1:24
        Gen_DAM_Revenue_hr(3,hour) = ...
            sum(ms.Pg(NYC_gens,hour).*ms.lamP(mpc.gen(NYC_gens,1),hour));
    end
    
    % Long Island (Zone K)
    for hour = 1:24
        Gen_DAM_Revenue_hr(4,hour) = ...
            sum(ms.Pg(LIs_gens,hour).*ms.lamP(mpc.gen(LIs_gens,1),hour));
    end
    
end
 

%% GENERATOR OPERATIONAL COSTS
% Include renewables in operational cost?
if RenInOpCost == 1
    Gens = all_gen_count;
else
    Gens = therm_gen_count;
end

Gen_DAM_OpCost = zeros(all_gen_count,1);
if RTM_option == 0
    % ----- DAM ONLY (24 hrs) ----- %
    for gen = 1:Gens
        for DAMhr = 1:24
            Gen_DAM_OpCost(gen) = Gen_DAM_OpCost(gen) + ...
                mdo.UC.CommitSched(gen,DAMhr)*(mpc.gencost(gen,7) + ...
                ms.Pg(gen,DAMhr) *mpc.gencost(gen,6) + ...
                (ms.Pg(gen,DAMhr))^2 *mpc.gencost(gen,5));
        end
    end
    
else
    % ----- DAM & RTM (21.5 hrs) ----- %
    for gen = 1:Gens
        for hour = 1:21
            Gen_DAM_OpCost(gen) = Gen_DAM_OpCost(gen) + ...
                mdo.UC.CommitSched(gen,hour)*(mpc.gencost(gen,7) + ...
                ms.Pg(gen,hour) *mpc.gencost(gen,6) + ...
                (ms.Pg(gen,hour))^2 *mpc.gencost(gen,5));
        end
        hour = 22;
        Gen_DAM_OpCost(gen) = Gen_DAM_OpCost(gen) + ...
            0.5*(mdo.UC.CommitSched(gen,hour)*(mpc.gencost(gen,7) + ...
            ms.Pg(gen,hour) *mpc.gencost(gen,6) + ...
            (ms.Pg(gen,hour))^2 *mpc.gencost(gen,5)));
    end
end
% Record DAM operational cost in output summary
Summaryy(:,2) = Gen_DAM_OpCost;


%% GENERATOR SUPPLY COSTS
Gen_DAM_SUPCost = zeros(all_gen_count,1);
if RTM_option == 0
    % ----- DAM ONLY (24 hrs) ----- %
    %Top of the Morning
    for gen = 1:Gens
        if mdo.UC.CommitSched(gen,1) == 1
            Gen_DAM_SUPCost(gen) = Gen_DAM_SUPCost(gen) + mdi.mpc.gencost(gen,2);
        end
    end
    
    %Later in the Day
    for gen = 1:Gens
        for DAMhr = 2:24
            if mdo.UC.CommitSched(gen,DAMhr) - mdo.UC.CommitSched(gen,DAMhr-1) == 1
                Gen_DAM_SUPCost(gen) = Gen_DAM_SUPCost(gen) + mdi.mpc.gencost(gen,2);
            end
        end
    end
    
else
    % ----- DAM & RTM (21.5 hrs) ----- %
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
end
Summaryy(:,3) = Gen_DAM_SUPCost;


%% Record DAM scheduled starts and shutdowns for RTC 
if RTM_option == 1
    
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
    
end

%% CALCULATE REGIONAL QUANTITIES
AvgLoadLMP = zeros(4,24);
AvgGenLMP  = zeros(4,24);
DAMThermGenByRegion = zeros(4,24);
DAMRenGenByRegion = zeros(4,24);
DAMloadByRegion = zeros(4,24);

for hour = 1:24
    
    %Average LMP by Region
    AvgLoadLMP(1, hour) = mean(ms.lamP(A2F_Load_buses, hour));
    AvgLoadLMP(2, hour) = mean(ms.lamP(GHI_Load_buses, hour));
    AvgLoadLMP(3, hour) = mean(ms.lamP(NYC_Load_buses, hour));
    AvgLoadLMP(4, hour) = mean(ms.lamP(LIs_Load_buses, hour));
    AvgGenLMP(1, hour) = mean(ms.lamP(A2F_Gen_buses, hour));
    AvgGenLMP(2, hour) = mean(ms.lamP(GHI_Gen_buses, hour));
    AvgGenLMP(3, hour) = mean(ms.lamP(NYC_Gen_buses, hour));
    AvgGenLMP(4, hour) = mean(ms.lamP(LIs_Gen_buses, hour));
    
    % Thermal Generation by Region
    DAMThermGenByRegion(1,hour) = Nuke_1_DAM(hour) + Steam_1_DAM(hour) +...
        Steam_2_DAM(hour) + CCGen_1_DAM(hour);
    DAMThermGenByRegion(2,hour) = Nuke_2_DAM(hour) + Nuke_3_DAM(hour) +...
        Steam_3_DAM(hour);
    DAMThermGenByRegion(3,hour) = Steam_4_DAM(hour) + CCGen_2_DAM(hour) +...
        GTGen_1_DAM(hour);
    DAMThermGenByRegion(4,hour) = Steam_5_DAM(hour) + GTGen_2_DAM(hour);
    
    % Renewable Generation by Region
    DAMRenGenByRegion(1,hour) = sum(mdo.results.Pc(A2F_RE_buses, hour));
    DAMRenGenByRegion(2,hour) = sum(mdo.results.Pc(GHI_RE_buses, hour));
    DAMRenGenByRegion(3,hour) = sum(mdo.results.Pc(NYC_RE_buses, hour));
    DAMRenGenByRegion(4,hour) = sum(mdo.results.Pc(LIs_RE_buses, hour));
    
    % Load by Region
    DAMloadByRegion(1,hour) = sum(most_busload_DAM(hour, A2F_Load_buses));
    DAMloadByRegion(2,hour) = sum(most_busload_DAM(hour, GHI_Load_buses));
    DAMloadByRegion(3,hour) = sum(most_busload_DAM(hour, NYC_Load_buses));
    DAMloadByRegion(4,hour) = sum(most_busload_DAM(hour, LIs_Load_buses));
    
end

%%%%% The following is commented out because it was unused
% % MAP distribution by Region %?????
% DAMloadTotalByRegion = zeros(4,1);
% DAMloadTotalByRegion(1,1) = sum(DAMloadByRegion(1,:));
% DAMloadTotalByRegion(2,1) = sum(DAMloadByRegion(2,:));
% DAMloadTotalByRegion(3,1) = sum(DAMloadByRegion(3,:));
% DAMloadTotalByRegion(4,1) = sum(DAMloadByRegion(4,:));
% MAPratio(1,Case*4+d) = DAMloadTotalByRegion(1,1)/sum(DAMloadTotalByRegion(:,1));
% MAPratio(2,Case*4+d) = sum(DAMloadTotalByRegion(2:4,1))/sum(DAMloadTotalByRegion(:,1));


% Load Cost By Region
DAM_LMP = ms.lamP(1:68,1:int_stop_DAM);
DAMloadCostByRegionHr = zeros(4,24);

if RTM_option == 1
    % ----- DAM & RTM (21.5 hrs) ----- %
    for hour = 1:22
        % Upstate (Zones A-F)
        DAMloadCostByRegionHr(1,hour) = ...
            sum(DAM_LMP(A2F_Load_buses,hour).*most_busload_DAM(hour,A2F_Load_buses)');
        
        % Zones GHI
        DAMloadCostByRegionHr(2,hour) = ...
            sum(DAM_LMP(GHI_Load_buses,hour).*most_busload_DAM(hour,GHI_Load_buses)');
        
        % New York City (Zone J)
        DAMloadCostByRegionHr(3,hour) = ...
            sum(DAM_LMP(NYC_Load_buses,hour).*most_busload_DAM(hour,NYC_Load_buses)');
        
        % Long Island (Zone K)
        DAMloadCostByRegionHr(4,hour) = ...
            sum(DAM_LMP(LIs_Load_buses,hour).*most_busload_DAM(hour,LIs_Load_buses)');
        
    end
    % Account for half period on the 22nd hour
    DAMloadCostByRegionHr(:,22) = DAMloadCostByRegionHr(:,22)*.5;
    
else
    % ----- DAM ONLY (24 hrs) ----- %
    for hour = 1:24
        % Upstate (Zones A-F)
        DAMloadCostByRegionHr(1,hour) = ...
            sum(DAM_LMP(A2F_Load_buses,hour).*most_busload_DAM(hour,A2F_Load_buses)');
        
        % Zones GHI
        DAMloadCostByRegionHr(2,hour) = ...
            sum(DAM_LMP(GHI_Load_buses,hour).*most_busload_DAM(hour,GHI_Load_buses)');
        
        % New York City (Zone J)
        DAMloadCostByRegionHr(3,hour) = ...
            sum(DAM_LMP(NYC_Load_buses,hour).*most_busload_DAM(hour,NYC_Load_buses)');
        
        % Long Island (Zone K)
        DAMloadCostByRegionHr(4,hour) = ...
            sum(DAM_LMP(LIs_Load_buses,hour).*most_busload_DAM(hour,LIs_Load_buses)');
        
    end
    
end

%%%%% The following is commented out because it was unused
% for Region = 1:4
%     DAMloadCostByRegion(Region,(Case*4+d)) = sum(DAMloadCostByRegionHr(Region,1:24))./1000;
% end


%% CONGESTION CHARGE
% The congestion charge is given by the difference in total regional load
% cost and generation revenue for a given period. 

% DAM Load Cost
LoadCostDAM = zeros(52,1);
LoadCostDAMhr = zeros(52,24);
for bus = 1:52
    if RTM_option == 0
        % ----- DAM ONLY (24 hrs) ----- %
        for hour = 1:24
            LoadCostDAM(bus,1) = LoadCostDAM(bus,1) + DAM_LMP(bus,hour)*most_busload_DAM(hour,bus);
            LoadCostDAMhr(bus,hour) = DAM_LMP(bus,hour)*most_busload_DAM(hour,bus);
        end
    else
        % ----- DAM & RTM (21.5 hrs) ----- %
        for hour = 1:21
            LoadCostDAM(bus,1) = LoadCostDAM(bus,1) + DAM_LMP(bus,hour)*most_busload_DAM(hour,bus);
            LoadCostDAMhr(bus,hour) = DAM_LMP(bus,hour)*most_busload_DAM(hour,bus);
        end
        LoadCostDAM(bus,1) = LoadCostDAM(bus,1) + 0.5*DAM_LMP(bus,22)*most_busload_DAM(22,bus);
        LoadCostDAMhr(bus,22) = 0.5*DAM_LMP(bus,22)*most_busload_DAM(22,bus);
    end
end

% Flat Scenario DAM Congestion Charge
DAM_congCharge_region_hr = zeros(4,24);
DAM_congCharge_hrr = zeros(1,24);
if RTM_option == 0
    % ----- DAM ONLY (24 hrs) ----- %
    for hour = 1:24
        DAM_congCharge_region_hr(1,hour) = DAMloadCostByRegionHr(1,hour) - Gen_DAM_Revenue_hr(1,hour);
        DAM_congCharge_region_hr(2,hour) = DAMloadCostByRegionHr(2,hour) - Gen_DAM_Revenue_hr(2,hour);
        DAM_congCharge_region_hr(3,hour) = DAMloadCostByRegionHr(3,hour) - Gen_DAM_Revenue_hr(3,hour);
        DAM_congCharge_region_hr(4,hour) = DAMloadCostByRegionHr(4,hour) - Gen_DAM_Revenue_hr(4,hour);
        
        DAM_congCharge_hrr(1,hour) = sum(DAM_congCharge_region_hr(1:4,hour));
    end
    
else
    % ----- DAM & RTM (21.5 hrs) ----- %
    for hour = 1:21
        DAM_congCharge_region_hr(1,hour) = DAMloadCostByRegionHr(1,hour) - Gen_DAM_Revenue_hr(1,hour);
        DAM_congCharge_region_hr(2,hour) = DAMloadCostByRegionHr(2,hour) - Gen_DAM_Revenue_hr(2,hour);
        DAM_congCharge_region_hr(3,hour) = DAMloadCostByRegionHr(3,hour) - Gen_DAM_Revenue_hr(3,hour);
        DAM_congCharge_region_hr(4,hour) = DAMloadCostByRegionHr(4,hour) - Gen_DAM_Revenue_hr(4,hour);
    end
    
    for hour = 1:22
        DAM_congCharge_hrr(1,hour) = sum(DAM_congCharge_region_hr(1:4,hour));
    end
end


%% RENEWABLE CURTAILMENT

% Index renewable generators by region 
All_REgenbus = mpc.gen(therm_gen_count+1:end, BUS_I);
A2F_REgen_L = logical([zeros(therm_gen_count,1);sum(A2F_Gen_buses == All_REgenbus,2)]);
GHI_REgen_L = logical([zeros(therm_gen_count,1);sum(GHI_Gen_buses == All_REgenbus,2)]);
NYC_REgen_L = logical([zeros(therm_gen_count,1);sum(NYC_Gen_buses == All_REgenbus,2)]);
LIs_REgen_L = logical([zeros(therm_gen_count,1);sum(LIs_Gen_buses == All_REgenbus,2)]);

% Initialize
DAMwindy = zeros(24,2);
for int = 1:24
    % Get Input renewable generation (available)
    if useinstant == 1
        DAMwindy(int,1) = sum(most_bus_rengen_windy(int*12-11,:));
    else
        DAMwindy(int,1) = sum(mean(most_bus_rengen_windy(int*12-11:int*12,:)));
    end
    % Get MOST output renewable generation (actual)
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

DAMsolar = zeros(24,2);
for int = 1:24
    if useinstant == 1
        DAMsolar(int,1) = sum(most_bus_rengen_solar(int*12-11,:));
    else
        DAMsolar(int,1) = sum(mean(most_bus_rengen_solar(int*12-11:int*12,:)));
    end
    DAMsolar(int,2) = RenGen_solarDAM(int);
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

% DAM Renewable Curtailment MWh - TOTAL
%%%%% Confirm that the following code is correct
DAMwindyCurtMWh = 0;
DAMhydroCurtMWh = 0;
DAMsolarCurtMWh = 0;
DAMotherCurtMWh = 0;
for hourr = 1:24
    DAMwindyCurtMWh = DAMwindyCurtMWh + DAMwindy(hourr,1) - DAMwindy(hourr,2);
    DAMhydroCurtMWh = DAMhydroCurtMWh + DAMhydro(hourr,1) - DAMhydro(hourr,2);
    DAMsolarCurtMWh = DAMsolarCurtMWh + DAMsolar(hourr,1) - DAMsolar(hourr,2);
    DAMotherCurtMWh = DAMotherCurtMWh + DAMother(hourr,1) - DAMother(hourr,2);
end

% DAM renewable Curtailment MWh - By Hour
DAMCurtMWh_hrly = -(DAMwindy(:,2) - DAMwindy(:,1) + ...
    DAMhydro(:,2) - DAMhydro(:,1) + ...
    DAMsolar(:,2) - DAMsolar(:,1) + ...
    DAMother(:,2) - DAMother(:,1));

% DAM availble renewable output by region
%%%%% I feel as if the hard coded values here may not be wrong, but is a
%%%%% terribly messy and risky way to code this!!!!!
DAMschedRegion = zeros(4,24);
for hour = 1:24
    %A2F
    DAMschedRegion(1,hour) = sum(most_windy_gen_DAM(hour,11:15))+...
        sum(most_hydro_gen_DAM(hour,11:15))+...
        sum(most_solar_gen_DAM(hour,11:15))+...
        sum(most_other_gen_DAM(hour,11:15));
    %GHI
    DAMschedRegion(2,hour) = sum(most_windy_gen_DAM(hour,1:2))+most_windy_gen_DAM(hour,8)+...
        sum(most_hydro_gen_DAM(hour,1:2))+most_hydro_gen_DAM(hour,8)+...
        sum(most_solar_gen_DAM(hour,1:2))+most_solar_gen_DAM(hour,8)+...
        sum(most_other_gen_DAM(hour,1:2))+most_other_gen_DAM(hour,8);
    %NYC
    DAMschedRegion(3,hour) = sum(most_windy_gen_DAM(hour,3:5))+...
        sum(most_hydro_gen_DAM(hour,3:5))+...
        sum(most_solar_gen_DAM(hour,3:5))+...
        sum(most_other_gen_DAM(hour,3:5));
    %LIs
    DAMschedRegion(4,hour) = sum(most_windy_gen_DAM(hour,6:7))+...
        sum(most_hydro_gen_DAM(hour,6:7))+...
        sum(most_solar_gen_DAM(hour,6:7))+...
        sum(most_other_gen_DAM(hour,6:7));
end

% DAM actual renewable generation by region
DAMactualRegion = zeros(4,24);
for hour = 1:24
    %A2F
    DAMactualRegion(1,hour) = sum(ms.Pg(A2F_REgen_L,hour));
    %GHI
    DAMactualRegion(2,hour) = sum(ms.Pg(GHI_REgen_L,hour));
    %NYC
    DAMactualRegion(3,hour) = sum(ms.Pg(NYC_REgen_L,hour));
    %LIs
    DAMactualRegion(4,hour) = sum(ms.Pg(LIs_REgen_L,hour));
end

% Calculate curtailment by region
 DAMcurtRegion = DAMschedRegion - DAMactualRegion;

%%%%%%%%%%%%%%%%%%%%%% THIS IS WHERE I STOPPED IN THE SOLAR SPLITTING TASK!

%% INTERFACE FLOWS

% Store Constrained Interface Flow Values
%%%%% Again, should be careful as the lines are hard-coded.
DAMifFlows = zeros(24,4);
for hour = 1:24
    DAMifFlows(hour,1) = ms.Pf(1,hour)  - ms.Pf(16,hour);
    DAMifFlows(hour,2) = ms.Pf(1,hour)  - ms.Pf(16,hour) + ms.Pf(86,hour);
    DAMifFlows(hour,3) = ms.Pf(7,hour)  + ms.Pf(9,hour)  + ms.Pf(13,hour);
    DAMifFlows(hour,4) = ms.Pf(28,hour) + ms.Pf(29,hour);
end

% Initialize
DAM_CElimit = ones(1,25).*lims_Array(BoundedIF,3);


%% EV LOAD
if EVSE == 1
    
    % Initialize
    DAMEVSEload = mdo.Storage.ExpectedStorageDispatch(1:32,1:24);
    EVSEloadDAMgraph = zeros(4,24);
    for hour = 1:24
        EVSEloadDAMgraph(1,hour) = -DAMEVSEload(1,hour)-DAMEVSEload(6,hour)-sum(DAMEVSEload(17:32,hour)); %A2F
        EVSEloadDAMgraph(2,hour) = -sum(DAMEVSEload(2:5,hour))-sum(DAMEVSEload(15,hour)); %GHI
        EVSEloadDAMgraph(3,hour) = -sum(DAMEVSEload(7:11,hour))-DAMEVSEload(16,hour); %NYC
        EVSEloadDAMgraph(4,hour) = -sum(DAMEVSEload(12:14,hour)); %Long Island
    end
    
end


%% Debug MW and LMP values; Store DAM Results
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
    for gen = 1:all_gen_count
        DAM_MW_Gen(hour,1) = DAM_MW_Gen(hour,1) + ms.Pg(gen,hour);
    end
end

%Calculate Error
DAM_MW_error = DAM_MW_Load - DAM_MW_Gen;
fprintf('For Case %d on %s, the mismatch (in MW) between day-ahead load and gen is:\n',...
    Case, datestring)
disp(DAM_MW_error)

% Store DAM Results
%%%%% Perhaps change the type of data structure that results are
%%%%% stored within
d = 1;
DAMresults(1,d) = d;
DAMresults(2,d) = Case;
DAMresults(3,d) = windyCurt;
DAMresults(4,d) = windyCurtFactor;
DAMresults(5,d) = sum(Gen_DAM_OpCost(1:Gens)) + sum(Gen_DAM_SUPCost(1:Gens));
DAMresults(6,d) = DAMwindyCurtMWh;
DAMresults(7,d) = DAMhydroCurtMWh;
DAMresults(8,d) = DAMotherCurtMWh;
DAMresults(9,d) = ms.f;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot DAM results

%Timescale
BigTime_DAM = int_stop_DAM;
Time4Graph = linspace(1,24,BigTime_DAM);

%% Figure - DAM Generator Output by Type
hFigA = figure(1);
set(hFigA, 'Position', [250 50 800 500]) %Pixels: from left, from bottom, across, high

% Get the width and height of the figure
lbwh = get(hFigA, 'position');
figw = lbwh(3);
figh = lbwh(4);

% % Number of rows and columns of axes
% % ncols = 1;
% % nrows = 2;
% % 
% % w and h of each axis in normalized units
% % axisw = (1 / ncols) * 0.85;
% % axish = (1 / nrows) * 0.85;
% 
% % A -- True Load, Net Load, Demand
% A1 = subplot(3,1,1); hold on;
% A2 = get(A1,'position'); A2(4) = A2(4)*0.80; set(A1, 'position', A2); A2(3) = A2(3)*0.75; set(A1, 'position', A2);
% yyaxis right
% hold on
% %                     plot(Time4Graph,ms.lamP(1,1:int_stop_DAM),'LineStyle','-','color',[0.85 .325 .098])
% bar(A1,ms.lamP(1,1:int_stop_DAM),'FaceAlpha',.2)
% axis 'auto y';
% grid on
% ylabel('DAM LMP ($/MWh)')
% hold off
% yyaxis left
% hold on
% plot(Time4Graph,NYCA_Load_Only(1:int_stop_DAM),'LineStyle','-','color',[0 .447 .741])
% plot(Time4Graph,NYCA_scen_NL(1:int_stop_DAM),'LineStyle','-','color',[.466 .674 .188])
% plot(Time4Graph,NYCA_scen_BTM_gen(1:int_stop_DAM),'LineStyle','-','color',[.494 .184 .556])
% ylabel('Real Power (MW)')
% axis([0.5,24.5,0,1000]);
% set(gca, 'XTick', [0 4 8 12 16 20 24]);
% axis 'auto y';
% hold off
% title('NYCA True Load, Net Load, & BTM Geneneration')
% A3 = legend('True Load', 'Net Load', 'BTM','LMP');
% rect = [.8, 0.76, 0.15, 0.0875]; %[left bottom width height]
% set(A3, 'Position', rect)
% ylabel('Real Power (MW)')
% set(gca, 'XTick', [0 4 8 12 16 20 24]);
% axis 'auto y';
% grid on; grid minor; box on; hold off

% B -- Generator Output (%)
% Create plot
% B1 = subplot(3,1,2); hold on;
B1 = subplot(2,1,1); hold on;
% Set the size and position of the subplot frame
% B2 = get(B1,'position');
% set(B1, 'position', [B2(1) B2(2) axisw axish]); 
% B2(4) = B2(4)*1.15; B2(2) = B2(2)*1; set(B1, 'position', B2); 
% B2(3) = B2(3)*1; set(B1, 'position', B2);
% Plot multiple lines from the same matrix
plot(Time4Graph,gen_output_percent(1,:),'LineStyle',':','LineWidth',2,'color',[0 .447 .741])
plot(Time4Graph,gen_output_percent(2,:),'LineStyle',':','LineWidth',2,'color',[.635 .078 .184])
plot(Time4Graph,gen_output_percent(3,:),'LineStyle',':','LineWidth',2,'color',[.85 .325 .098])
plot(Time4Graph,gen_output_percent(4,:),'LineStyle','--','color',[0 .447 .741])
plot(Time4Graph,gen_output_percent(5,:),'LineStyle','--','color',[.301 .745 .933])
plot(Time4Graph,gen_output_percent(6,:),'LineStyle','--','color',[.635 .078 .184])
plot(Time4Graph,gen_output_percent(7,:),'LineStyle','--','color',[.494 .184 .556])
plot(Time4Graph,gen_output_percent(8,:),'LineStyle','--','color',[.466 .674 .188])
plot(Time4Graph,gen_output_percent(10,:),'LineStyle','-.','color',[0 .447 .741])
plot(Time4Graph,gen_output_percent(11,:),'LineStyle','-.','color',[.494 .184 .556])
plot(Time4Graph,gen_output_percent(12,:),'LineStyle','-','color',[.494 .184 .556])
plot(Time4Graph,gen_output_percent(13,:),'LineStyle','-','color',[.466 .674 .188])
% Create title
title('Generator Capacity Factor')
% Create the legend for subplot B
legendB = legend('Nuke A2F','Nuke GHI','Nuke GHI','Steam A2F','Steam A2F',...
    'Steam GHI','Steam NYC','Steam LI','CC A2F','CC NYC','GT NYC','GT LI');
% Set the position of the legend
set(legendB,'Location','eastoutside','FontSize',10);
legszB = get(legendB,'Position');
% rect = [.9, 0.65, 0.15, .12]; %[left bottom width height]
% set(legendB, 'Position', rect)
% Set y-axis label
ylabel('Power (%)')
% Set remaining plot settings
xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
xticklabels({'0' '4' '8' '12' '16' '20' '24'})
%xticklabels({' ',' ',' ',' ',' ',' ',' '})
axis([0.5,24.5,-0.1,1.1]);
yticks([0, 0.5, 1.0])
yticklabels({' 0','50','100'});
grid on; box on; hold off

% C -- Generation by Type
% C1 = subplot(3,1,3); hold on;
C1 = subplot(2,1,2); hold on;
% C2 = get(C1,'position');
% set(C1, 'position', [C2(1) C2(2) axisw axish]);  
% C2(4) = C2(4)*1.15; C2(2) = C2(2)*1.35; set(C1, 'position', C2); 
% C2(3) = C2(3)*1; set(C1, 'position', C2);
bar([NukeGenDAM;SteamGenDAM;CCGenDAM;GTGenDAM;RenGen_windyDAM;RenGen_hydroDAM;RenGen_solarDAM;RenGen_otherDAM;BTM4GraphDAM;].'./1000,'stacked','FaceAlpha',.5)

title('Generation by Type')
legendC = legend('Nuke','Steam','CC','GT','Wind','Hydro','Solar','Other','BTM');
reorderLegendbar([1 2 3 4 5 6 7 8 9])
% rect = [.9, 0.13, 0.15, .12]; %[left bottom width height]
legszC = get(legendC,'Position');
legszC(3) = legszB(3);
legszC(1) = legszB(1);
set(legendC, 'Position', legszC, 'Location','eastoutside','FontSize',10)
ylabel('Power (GW)')
xlabel('Time (Hour)');
axis([0.5,24.5,0,30]);
xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
xticklabels({'0' '4' '8' '12' '16' '20' '24'})
set(gca, 'YTick', [0 10 20 30])
format shortg
grid on; box on; hold off

% Graph Title (Same for all graphs)
First_Line_Title = ['DAM Model -- ',datestring,' for the ',Case_Name_String];
supt = suptitle(First_Line_Title);
supt.FontSize = 16;
supt.FontWeight = 'bold';


% Save to an output file
if Fig_save == 1
    outfile = ['../../MarketModel_Output/ResultsPlot.', scen, datestring];
    %If this is the first loop through the iteration, open a new document
    if and(Case == case_start, d == d_start)
        if ispc
            % Capture current figure/model into clipboard:
            matlab.graphics.internal.copyFigureHelper(hFigA)
            % Start an ActiveX session with PowerPoint:
            word = actxserver('Word.Application');
            word.Visible = 1;
            % Create new presentation:
            op = invoke(word.Documents,'Add');
            % Paste the contents of the Clipboard:
            invoke(word.Selection,'Paste');
        else
            fig_cnt = 1;
            filestr = [outfile,sprintf('_%02d_',fig_cnt),'.pdf'];
            print(hFigA, '-dpdf','-bestfit', filestr)
            fig_cnt = fig_cnt + 1;
        end
        %Otherwise grab the existing word or ps document and paste in there.
    else
        if ispc
            % Capture current figure/model into clipboard:
            matlab.graphics.internal.copyFigureHelper(hFigA)
            % Find end of document and make it the insertion point:
            end_of_doc = get(word.activedocument.content,'end');
            set(word.application.selection,'Start',end_of_doc);
            set(word.application.selection,'End',end_of_doc);
            % Paste the contents of the Clipboard:
            invoke(word.Selection,'Paste');
        else
            filestr = [outfile,sprintf('_%02d_',fig_cnt),'.pdf'];
            print(hFigA, '-dpdf','-bestfit', filestr)
            fig_cnt = fig_cnt + 1;
        end
    end
    
    close all
end

%% Figure - DAM LMP
hFigLMP = figure(2);
set(hFigLMP, 'Position', [250 50 650 300]) %Pixels: from left, from bottom, across, high

% % Graph Title (Same for all graphs)
% First_Line_Title = ['Simulation for: ', datestring(5:6), ' ', datestring(7:8), ' ', datestring(1:4), ' in the ',Case_Name_String];
% ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off',...
%     'Units','normalized', 'clipping' , 'off');
% text(0.5, 1.0,[{'\bf \fontsize{12}' First_Line_Title}], 'HorizontalAlignment' ,...
%     'center', 'VerticalAlignment', 'top')

% B -- Load Weighted LMP
B1 = subplot(1,1,1); hold on;  %Pixels: from left, from bottom, across, high
% Set the position of the plot
B2 = get(B1,'Position'); 
B2(4) = B2(4)*.5; B2(2) = B2(2)*1.5+0.05; B2(3) = B2(3)*.85; B2(4) = B2(4)*1.5;
set(B1, 'Position', B2);
plot(1:24,AvgLoadLMP(1,:),'LineStyle','--','color',[0 .447 .741])
plot(1:24,AvgLoadLMP(2,:),'LineStyle','--','color',[.635 .078 .184])
plot(1:24,AvgLoadLMP(3,:),'LineStyle','--','color',[.85 .325 .098])
plot(1:24,AvgLoadLMP(4,:),'LineStyle','--','color',[.466 .674 .188])

B3 = legend('Upstate','LHV','NYC','LI');
title('Average Load Bus LMP by Region')
% Set the positon of the legend
rect = [.82, 0.45, 0.15, .12]; %[left bottom width height]
set(B3, 'Position', rect)
ylabel('LMP ($/MWh)')
xlabel('Time (Hour Beginning)');
%xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
%xticklabels({' ' ' ' ' ' ' ' ' ' ' ' ' '})
set(gca, 'XTick', [0 4 8 12 16 20 24]);
axis([1,24,0,20]);
axis 'auto y';
minval = max(max(max(AvgLoadLMP)),15);
ylim([0 minval])
%yticklabels({' 0','50','100'});
grid on; box on; hold off

% C -- Gen Weighted LMP
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

% Graph Title (Same for all graphs)
First_Line_Title = ['DAM Model -- ',datestring,' for the ',Case_Name_String];
supt = suptitle(First_Line_Title);
supt.FontSize = 16;
supt.FontWeight = 'bold';

% Save to an output file
if Fig_save == 1
    if ispc
        %If this is the first loop through the iteration, open a new document
        % Capture current figure/model into clipboard:
        matlab.graphics.internal.copyFigureHelper(hFigLMP)
        % Find end of document and make it the insertion point:
        end_of_doc = get(word.activedocument.content,'end');
        set(word.application.selection,'Start',end_of_doc);
        set(word.application.selection,'End',end_of_doc);
        % Paste the contents of the Clipboard:
        invoke(word.Selection,'Paste');
    else
        filestr = [outfile,sprintf('_%02d_',fig_cnt),'.pdf'];
        print(hFigLMP, '-dpdf','-bestfit', filestr)
        fig_cnt = fig_cnt + 1;
    end
    close all
end

%% Figure - Load and Generation by Region
hFigLoad = figure(3); set(hFigLoad, 'Position', [450 50 650 550]) %Pixels: from left, from bottom, across, high

% A -- Thermal Gen by Region
A1 = subplot(3,1,1); hold on;
A2 = get(A1,'position'); A2(4) = A2(4)*.85; A2(2) = A2(2)*.95; set(A1, 'position', A2); A2(3) = A2(3)*0.85; set(A1, 'position', A2);
bar([DAMThermGenByRegion(1,1:24);DAMThermGenByRegion(2,1:24);DAMThermGenByRegion(3,1:24);DAMThermGenByRegion(4,1:24);].','stacked','FaceAlpha',.5)
ylabel('Power (MW)')
title('Thermal Generation by Region')
axis([0.5,24.5,0,1500]);
axis 'auto y';
%set(gca, 'YTick', [0 500 1000 1500])
xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
xticklabels({'0' '4' '8' '12' '16' '20' '24'})
set(gca, 'YTick', [0 10000 20000 30000 40000 50000 60000 70000])
yticklabels({'0' '10,000' '20,000' '30,000' '40,000' '50,000' '60,000' '70,000'})
grid on;  box on; hold off

% B -- Renewable Gen by Region
B1 = subplot(3,1,2); hold on;
B2 = get(B1,'position'); B2(4) = B2(4)*.85; B2(2) = B2(2)*.95; set(B1, 'position', B2); B2(3) = B2(3)*0.85; set(B1, 'position', B2);
bar([DAMRenGenByRegion(1,1:24);DAMRenGenByRegion(2,1:24);DAMRenGenByRegion(3,1:24);DAMRenGenByRegion(4,1:24);].','stacked','FaceAlpha',.5)
ylabel('Power (MW)')
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
grid on;  box on; hold off

% C -- Load by Region
C1 = subplot(3,1,3); hold on;
C2 = get(C1,'position'); C2(4) = C2(4)*.85; C2(2) = C2(2)*1; set(C1, 'position', C2); C2(3) = C2(3)*0.85; set(C1, 'position', C2);
bar([DAMloadByRegion(1,1:24);DAMloadByRegion(2,1:24);DAMloadByRegion(3,1:24);DAMloadByRegion(4,1:24);].','stacked','FaceAlpha',.5)
ylabel('Power (MW)')
title('Load by Region')
axis([0.5,24.5,0,4000]);
axis 'auto y';
%title('C-E Flow (MW)')
xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
xticklabels({'0' '4' '8' '12' '16' '20' '24'})
set(gca, 'YTick', [0 10000 20000 30000 40000 50000 60000 70000])
yticklabels({'0' '10,000' '20,000' '30,000' '40,000' '50,000' '60,000' '70,000'})
xlabel('Time (Hour Beginning)')
grid on; box on; hold off

% Graph Title (Same for all graphs)
First_Line_Title = ['DAM Model -- ', datestring(5:6), '-',...
     datestring(7:8), '-', datestring(1:4), ' for the ',Case_Name_String];
supt = suptitle(First_Line_Title);
supt.FontSize = 16;
supt.FontWeight = 'bold';

% Save to an output file
if Fig_save == 1
    if ispc
        % Capture current figure/model into clipboard:
        matlab.graphics.internal.copyFigureHelper(hFigLoad)
        % Find end of document and make it the insertion point:
        end_of_doc = get(word.activedocument.content,'end');
        set(word.application.selection,'Start',end_of_doc);
        set(word.application.selection,'End',end_of_doc);
        % Paste the contents of the Clipboard:
        invoke(word.Selection,'Paste');
    else
        filestr = [outfile,sprintf('_%02d_',fig_cnt),'.pdf'];
        print(hFigLoad, '-dpdf','-bestfit', filestr)
        fig_cnt = fig_cnt + 1;
    end
    close all
end

%% Figure - Congestion charge by region
hFigCC = figure(4); set(hFigCC, 'Position', [450 50 800 650]) %Pixels: from left, from bottom, across, high

% A -- Load Cost by Region
A1 = subplot(3,1,1); hold on;
% Set the position of the subplot
A2 = get(A1,'position'); 
A2(2) = A2(2)*0.95; 
A2(3) = A2(3)*0.85; A2(4) = A2(4)*.95;
set(A1, 'position', A2);
% Create bar plot
%bar([DAM_congCharge_region_hr(1,1:24);DAM_congCharge_region_hr(2,1:24);DAM_congCharge_region_hr(3,1:24);DAM_congCharge_region_hr(4,1:24);].','stacked','FaceAlpha',.5)
bar([DAMloadCostByRegionHr(1,1:24);DAMloadCostByRegionHr(2,1:24);DAMloadCostByRegionHr(3,1:24);DAMloadCostByRegionHr(4,1:24);].','stacked','FaceAlpha',.5)
ylabel('Cost ($)')
title('DAM Load Cost by Region')
A3 = legend('Upstate','LHV','NYC','LI');
reorderLegendarea([1 2 3 4])
rect = [.81, 0.705, 0.15, .15]; %[left bottom width height]
set(A3, 'Position', rect)
axis([0.5,24.5,0,1500]);
axis 'auto y';
%set(gca, 'YTick', [0 500 1000 1500])
xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
xticklabels({'0' '4' '8' '12' '16' '20' '24'})
xticklabels({'0' '4' '8' '12' '16' '20' '24'})
set(gca, 'YTick', [0 100000 200000 300000 400000 500000 ])
yticklabels({'0' '100,000' '200,000'  '300,000' '400,000' '500,000'})
grid on; box on; hold off

% B -- Gen Payment by Region
B1 = subplot(3,1,2); hold on;
% Set the position of the subplot
B2 = get(B1,'position'); 
B2(2) = B2(2)*.95; 
B2(3) = B2(3)*0.85; B2(4) = B2(4)*.95;  
set(B1, 'position', B2);
%bar([DAM_congCharge_region_hr(1,1:24);DAM_congCharge_region_hr(2,1:24);DAM_congCharge_region_hr(3,1:24);DAM_congCharge_region_hr(4,1:24);].','stacked','FaceAlpha',.5)
bar([Gen_DAM_Revenue_hr(1,1:24);Gen_DAM_Revenue_hr(2,1:24);Gen_DAM_Revenue_hr(3,1:24);Gen_DAM_Revenue_hr(4,1:24);].','stacked','FaceAlpha',.5)
ylabel('Payment ($)')
title('DAM Generator Payments by Region')
B3 = legend('Upstate','LHV','NYC','LI');
reorderLegendarea([1 2 3 4])
rect = [.81, 0.405, 0.15, .15]; %[left bottom width height]
set(B3, 'Position', rect)
axis([0.5,24.5,0,1500]);
axis 'auto y';
%set(gca, 'YTick', [0 500 1000 1500])
xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
xticklabels({'0' '4' '8' '12' '16' '20' '24'})
set(gca, 'YTick', [0 100000 200000 300000 400000 500000 ])
yticklabels({'0' '100,000' '200,000'  '300,000' '400,000' '500,000'})
grid on; box on; hold off

% C -- Congestion Charge by Region
C1 = subplot(3,1,3); hold on;
C2 = get(C1,'position'); 
C2(2) = C2(2)*.95; 
C2(3) = C2(3)*0.85; C2(4) = C2(4)*.95;
set(C1, 'position', C2);
%bar([DAM_congCharge_region_hr(1,1:24);DAM_congCharge_region_hr(2,1:24);DAM_congCharge_region_hr(3,1:24);DAM_congCharge_region_hr(4,1:24);].','stacked','FaceAlpha',.5)
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
%set(gca, 'YTick', [0 500 1000 1500])
xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
xticklabels({'0' '4' '8' '12' '16' '20' '24'})
xlabel('Time (Hour Beginning)');
set(gca, 'YTick', [0 10000 20000 30000 40000 50000 60000 70000 80000 90000 100000 110000 120000])
yticklabels({'0' '10,000' '20,000' '30,000' '40,000' '50,000' '60,000' '70,000' '80,000' '90,000' '100,000' '110,000' '120,000'})
grid on; box on; hold off

% Graph Title (Same for all graphs)
First_Line_Title = ['DAM Model -- ',datestring,' for the ',Case_Name_String];
supt = suptitle(First_Line_Title);
supt.FontSize = 16;
supt.FontWeight = 'bold';

% Save to an output file
if Fig_save == 1
    if ispc
        % Capture current figure/model into clipboard:
        matlab.graphics.internal.copyFigureHelper(hFigCC)
        % Find end of document and make it the insertion point:
        end_of_doc = get(word.activedocument.content,'end');
        set(word.application.selection,'Start',end_of_doc);
        set(word.application.selection,'End',end_of_doc);
        % Paste the contents of the Clipboard:
        invoke(word.Selection,'Paste');
    else
        filestr = [outfile,sprintf('_%02d_',fig_cnt),'.pdf'];
        print(hFigCC, '-dpdf','-bestfit', filestr)
        fig_cnt = fig_cnt + 1;
    end
    close all
end

%% Figure - Renewable Curtailment in the DAM

% Open figure and set its size
hFigA = figure(5); 
set(hFigA, 'Position', [450 50 650 600]) %Pixels: from left, from bottom, across, high

% A -- Wind
A1 = subplot(4,1,1); hold on;
% Set the position of the subplot
A2 = get(A1,'position'); 
A2(3) = A2(3)*0.75; A2(4) = A2(4)*0.80;
set(A1, 'position', A2);
% Create the bar plot
bar(DAMwindy)
% Make title
title('DAM Wind Generation')
% Make legend and set its positon
A3 = legend('DAM available','DAM actual');
rect = [.75, 0.76, 0.15, 0.0875]; %[left bottom width height]
set(A3, 'Position', rect)
% Set all other plot setting
ylabel('Power (MW)')
set(gca, 'XTick', [0 4 8 12 16 20 24]);
axis 'auto y';
grid on; box on; hold off

% B -- Hydro
B1 = subplot(4,1,2); hold on;
% Set the position of the subplot
B2 = get(B1,'position'); 
B2(3) = B2(3)*0.75; B2(4) = B2(4)*1.;
set(B1, 'position', B2);
% Create the bar plot
bar(DAMhydro)
% Make title
title('DAM Hydro Generation')
% Make legend and set its positon
B3 = legend('DAM available','DAM actual');
rect = [.75, 0.45, 0.15, .12]; %[left bottom width height]
set(B3, 'Position', rect)
% Set all other plot setting
ylabel('Power (MW)')
axis([0.5,24.5,0,1]);
axis 'auto y';
set(gca, 'XTick', [0 4 8 12 16 20 24]);
grid on; box on; hold off

% C -- Solar
C1 = subplot(4,1,3); hold on;
% Set the position of the subplot
C2 = get(C1,'Position');  
C2(3) = C2(3)*0.75; C2(4) = C2(4)*1;
set(C1, 'Position', C2);
% Create the bar plot
bar(DAMsolar)
% Make title
title('DAM Solar VRE Generation')
% Make legend and set its positon
C3 = legend('DAM available','DAM actual');
rect = [.75, 0.125, 0.15, .12]; %[left bottom width height]
set(C3, 'Position', rect)
% Set all other plot setting
ylabel('Power (MW)')
axis([0.5,24.5,0,30000]);
axis 'auto y';
set(gca, 'XTick', [0 4 8 12 16 20 24]);
format shortg
grid on; box on; hold off


% D -- Other
D1 = subplot(4,1,4); hold on;
% Set the position of the subplot
D2 = get(D1,'Position');  
D2(3) = D2(3)*0.75; D2(4) = D2(4)*1;
set(D1, 'Position', D2);
% Create the bar plot
bar(DAMother)
% Make title
title('DAM Other VRE Generation')
% Make legend and set its positon
D3 = legend('DAM available','DAM actual');
rect = [.75, 0.125, 0.15, .12]; %[left bottom width height]
set(D3, 'Position', rect)
% Set all other plot setting
ylabel('Power (MW)')
xlabel('Time (hours)');
axis([0.5,24.5,0,30000]);
axis 'auto y';
set(gca, 'XTick', [0 4 8 12 16 20 24]);
format shortg
grid on; box on; hold off

% Graph Title (Same for all graphs)
First_Line_Title = ['DAM Model -- ',datestring,' for the ',Case_Name_String];
supt = suptitle(First_Line_Title);
supt.FontSize = 16;
supt.FontWeight = 'bold';

% Save to an output file
if Fig_save == 1
    if ispc
        % Capture current figure/model into clipboard:
        matlab.graphics.internal.copyFigureHelper(hFigA)
        % Find end of document and make it the insertion point:
        end_of_doc = get(word.activedocument.content,'end');
        set(word.application.selection,'Start',end_of_doc);
        set(word.application.selection,'End',end_of_doc);
        % Paste the contents of the Clipboard:
        invoke(word.Selection,'Paste');
    else
        filestr = [outfile,sprintf('_%02d_',fig_cnt),'.pdf'];
        print(hFigA, '-dpdf','-bestfit', filestr)
        fig_cnt = fig_cnt + 1;
    end
    close all
end


%% Figure - DAM Curtailment by Region

% Create Figure
if printCurt == 1
    hFigE = figure(6); 
    set(hFigE, 'Position', [450 50 650 450]) %Pixels: from left, from bottom, across, high
    
    % A -- Curtailment by Region
    A1 = subplot(2,1,1); hold on;
    A2 = get(A1,'position'); 
    A2(4) = A2(4)*.80; 
    A2(2) = A2(2)*1; set(A1, 'position', A2); 
    A2(3) = A2(3)*0.75; set(A1, 'position', A2);
    bar([DAMcurtRegion(1,1:24);DAMcurtRegion(2,1:24);DAMcurtRegion(3,1:24);DAMcurtRegion(4,1:24);].','stacked','FaceAlpha',.5)
    ylabel('Real Power (MW)')
    axis([0.5,24.5,0,2000]);
    %axis 'auto y';
    title('Curtailment by Region')
    A3 = legend('A2F','GHI','NYC','LIs');
    reorderLegendbar([1 2 3 4])
    rect = [.8, 0.6, 0.15, .2]; %[left bottom width height]
    set(A3, 'Position', rect)
    xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
    xticklabels({'0' '4' '8' '12' '16' '20' '24'})
    %set(gca, 'YTick', [0 250 500 1000])
    %xlabel('Time (hours)')
    ylabel('Curtailment (MW)')
    grid on;  box on; hold off
    
    % B -- Central-East Interface Flows
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
    %set(gca, 'YTick', [0 250 500 1000])
    xlabel('Time (hours)')
    ylabel('Real Power (MW)')
    grid on;  box on; hold off
    
    % Graph Title (Same for all graphs)
    First_Line_Title = ['DAM Model -- ',datestring,' for the ',Case_Name_String];
    supt = suptitle(First_Line_Title);
    supt.FontSize = 16;
    supt.FontWeight = 'bold';
    
    % Save to an output file
    if Fig_save == 1
        if ispc
            % Capture current figure/model into clipboard:
            matlab.graphics.internal.copyFigureHelper(hFigE)
            % Find end of document and make it the insertion point:
            end_of_doc = get(word.activedocument.content,'end');
            set(word.application.selection,'Start',end_of_doc);
            set(word.application.selection,'End',end_of_doc);
            % Paste the contents of the Clipboard:
            invoke(word.Selection,'Paste');
        else
            filestr = [outfile,sprintf('_%02d_',fig_cnt),'.pdf'];
            print(hFigE, '-dpdf','-bestfit', filestr)
            fig_cnt = fig_cnt + 1;
        end
        close all
    end
end

%% Figure - EVSE Load
if EVSE == 1
    % Create Figure
    hFigE = figure(7); 
    set(hFigE, 'Position', [450 50 650 200]) %Pixels: from left, from bottom, across, high
    
    % A -- EVSE
    A1 = subplot(1,1,1); hold on;
    A2 = get(A1,'position'); 
    A2(4) = A2(4)*.80; 
    A2(2) = A2(2)*2.1; set(A1, 'position', A2); 
    A2(3) = A2(3)*0.75; set(A1, 'position', A2);
    bar([EVSEloadDAMgraph(1,1:24);EVSEloadDAMgraph(2,1:24);EVSEloadDAMgraph(3,1:24);EVSEloadDAMgraph(4,1:24);].','stacked','FaceAlpha',.5)
    ylabel('Real Power (MW)')
    axis([0.5,24.5,0,1000]);
    axis 'auto y';
    A3 = legend('A2F','GHI','NYC','LIs');
    reorderLegendbar([1 2 3 4])
    rect = [.8, 0.25, 0.15, .35]; %[left bottom width height]
    set(A3, 'Position', rect)
    xticks([0.5 4.5 8.5 12.5 16.5 20.5 24.5])
    xticklabels({'0' '4' '8' '12' '16' '20' '24'})
    %set(gca, 'YTick', [0 250 500 1000])
    xlabel('Time (hours)')
    grid on; box on; hold off
    
    % Save to an output file
    if Fig_save == 1
        if ispc
            % Capture current figure/model into clipboard:
            matlab.graphics.internal.copyFigureHelper(hFigE)
            % Find end of document and make it the insertion point:
            end_of_doc = get(word.activedocument.content,'end');
            set(word.application.selection,'Start',end_of_doc);
            set(word.application.selection,'End',end_of_doc);
            % Paste the contents of the Clipboard:
            invoke(word.Selection,'Paste');
        else
            filestr = [outfile,sprintf('_%02d_',fig_cnt),'.pdf'];
            print(hFigE, '-dpdf','-bestfit', filestr)
            fig_cnt = fig_cnt + 1;
        end
        close all
    end
    
end

end

