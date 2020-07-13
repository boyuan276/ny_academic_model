function [wind, hydro, pv, btm, bio, lfg, ees, ev, stoch, Case_Name_String]... 
     = NYAM2030_case2(wind, hydro, pv, btm, bio, lfg)
%% Scenario 2 of renewable integration in Leah's thesis
% Scenario for achieving energy goals of NYISO 2019 Power Trends

Case_Name_String = '2030 Scenario';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Input FUTURE Capacity Values (MW)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% FUTURE SCENARIO renewable capacity in A2F
wind.A2F_cap    = 4313;
hydro.A2F_cap   =  6619.3;
pv.A2F_cap      = 2966;
btm.A2F_cap     = 0;
bio.A2F_cap     =  9;
lfg.A2F_cap     =   0;
ees.A2F_cap     =    540;

% FUTURE SCENARIO renewable capacity in GHI
wind.GHI_cap    =    0 + 0;
hydro.GHI_cap   =   107;
pv.GHI_cap      =  968;
btm.GHI_cap     =  0;
bio.GHI_cap     =    28;
lfg.GHI_cap     =    0;
ees.GHI_cap     =    340;

% FUTURE SCENARIO renewable capacity in NYC
wind.NYC_cap    =  5776;
hydro.NYC_cap   =    0 + 0;
pv.NYC_cap      =    0 + 0;
btm.NYC_cap     =  0;
bio.NYC_cap     =    0 + 0;
lfg.NYC_cap     =   0;
ees.NYC_cap     =    747;

% FUTURE SCENARIO renewable capacity on LI
wind.LIs_cap    =  7132;
hydro.LIs_cap   =    0 + 0;
pv.LIs_cap      =  104;
btm.LIs_cap     = 0;
bio.LIs_cap     =    32;
lfg.LIs_cap     =    0;
ees.LIs_cap     =    345;

% FUTURE SCENARIO renewable capacity in NE
wind.NEw_cap    =    0 + 0;
hydro.NEw_cap   =    0 + 0;
pv.NEw_cap      =    0 + 0;
btm.NEw_cap     =    0 + 0;
bio.NEw_cap     =    0 + 0;
lfg.NEw_cap     =    0 + 0;
ees.NEw_cap     =    0 + 0;

% FUTURE SCENARIO renewable capacity in PJM
wind.PJM_cap    =    0 + 0;
hydro.PJM_cap   =    0 + 0;
pv.PJM_cap      =    0 + 0;
btm.PJM_cap     =    0 + 0;
bio.PJM_cap     =    0 + 0;
lfg.PJM_cap     =    0 + 0;
ees.PJM_cap     =    0 + 0;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Input EXISTING Capacity Values (MW)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% EXISTING renewable capacity in A2F (values here are for 2016. Other 
% regions are set to zero installed capacity due to low penetration).
wind.A2F_exist_cap  = 4189;
hydro.A2F_exist_cap =  542;
pv.A2F_exist_cap    = 3044;
btm.A2F_exist_cap   = 1358;
bio.A2F_exist_cap   =  122;
lfg.A2F_exist_cap   =   13;
ees.A2F_exist_cap   =    0;


% Existing renewable capacity in GHI
wind.GHI_exist_cap  =    0;
hydro.GHI_exist_cap =   45;
pv.GHI_exist_cap    =  438;
btm.GHI_exist_cap   =  793;
bio.GHI_exist_cap   =    0;
lfg.GHI_exist_cap   =    3;
ees.GHI_exist_cap   =    0;


% Existing renewable capacity in NYC
wind.NYC_exist_cap  =  408;
hydro.NYC_exist_cap =    0;
pv.NYC_exist_cap    =    0;
btm.NYC_exist_cap   =  419;
bio.NYC_exist_cap   =    0;
lfg.NYC_exist_cap   =   34;
ees.NYC_exist_cap   =    0;

% Existing renewable capacity on LI
wind.LIs_exist_cap  =  591;
hydro.LIs_exist_cap =    0;
pv.LIs_exist_cap    =  373;
btm.LIs_exist_cap   = 1069;
bio.LIs_exist_cap   =    0;
lfg.LIs_exist_cap   =    3;
ees.LIs_exist_cap   =    0;

% Existing renewable capacity in NE
wind.NEw_exist_cap  =    0;
hydro.NEw_exist_cap =    0;
pv.NEw_exist_cap    =    0;
btm.NEw_exist_cap   =    0;
bio.NEw_exist_cap   =    0;
lfg.NEw_exist_cap   =    0;
ees.NEw_exist_cap   =    0;

% Existing renewable capacity in PJM
wind.PJM_exist_cap  =    0;
hydro.PJM_exist_cap =    0;
pv.PJM_exist_cap    =    0;
btm.PJM_exist_cap   =    0;
bio.PJM_exist_cap   =    0;
lfg.PJM_exist_cap   =    0;
ees.PJM_exist_cap   =    0;


% Get EVSE Load Data (MWh total for the Day)
% Electric Vehicle Energy Usage Forecast (2018 Gold Book) in GWh
%     A   B   C   D   E    F   G   H   I   J   K
ev.MWhLoad = [
      3   5   4   0   2    5   6   3   5  13  23;     %2016 (Existing)
    154 183 180  12  99  206 230 100 150 520 781;     %2030 (Scenario)
    ]./365;   

% Total Increase in Coincident Winter Peak Demand by Zone in MW (Use winter as its worse than summer)
%   A   B   C   D   E   F   G   H   I   J   K
ev.MWLoad  = [
    1   1   1   0    1   1   2   1   1    4   7;       %2016 (Existing)
    30 36  35   2   19  40  45  20  29  101 153;       %2030 (Scenario)
    ];    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Input profile/stochastic information
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
stoch.type = 'history';
stoch.loadprof = {'Jan-19-2016','Mar-22-2016','Jul-25-2016','Nov-10-2016'};
stoch.windprof = {'Jan-19-2016','Mar-22-2016','Jul-25-2016','Nov-10-2016'};
stoch.PVprof = {'Jan-19-2016','Mar-22-2016','Jul-25-2016','Nov-10-2016'};
stoch.transmat = {[0.25, 0.25, 0.25, 0.25]};

end
