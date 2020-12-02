function [wind, hydro, pv, btm, bio, lfg, ees, ev, stoch, Case_Name_String]... 
     = NYAM2030_base(wind, hydro, pv, btm, bio, lfg)
%% Base scenario of renewable integration in 2030
% Referencing NYISO 2019 CARIS Report "70x30" base load scenario

Case_Name_String = '2020 Base Scenario';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Input FUTURE Capacity Values (MW)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% FUTURE SCENARIO renewable capacity in A2F
% lbw.A2F_cap     = 8772.41;
% osw.A2F_cap     = 0;
wind.A2F_cap    = 8772.41;
hydro.A2F_cap   = 4368.44;
pv.A2F_cap      = 13041.44;
btm.A2F_cap     = 4237;
bio.A2F_cap     =  122 + 0;
lfg.A2F_cap     =   13 + 0;
ees.A2F_cap     =    0 + 0;
% other.A2F_cap   = 6138.4;
% phs.A2F_cap     = 1409.9;

% FUTURE SCENARIO renewable capacity in GHI
% lbw.GHI_cap     = 0;
% osw.GHI_cap     = 0;
wind.GHI_cap    = 0;
hydro.GHI_cap   = 98.8;
pv.GHI_cap      = 2031.77;
btm.GHI_cap     = 1180;
bio.GHI_cap     =    0 + 0;
lfg.GHI_cap     =    3 + 0;
ees.GHI_cap     =    0 + 0;
% other.GHI_cap   = 3071;
% phs.GHI_cap     = 0;

% FUTURE SCENARIO renewable capacity in NYC
% lbw.NYC_cap     = 0;
% osw.NYC_cap     = 4320;
wind.NYC_cap    = 4320;
hydro.NYC_cap   = 0;
pv.NYC_cap      = 0;
btm.NYC_cap     = 950;
bio.NYC_cap     =    0 + 0;
lfg.NYC_cap     =   34 + 0;
ees.NYC_cap     =    0 + 0;
% other.NYC_cap   = 0;
% phs.NYC_cap     = 0;

% FUTURE SCENARIO renewable capacity on LI
% lbw.LIs_cap     = 0;
% osw.LIs_cap     = 1778;
wind.LIs_cap    = 1778;
hydro.LIs_cap   = 0;
pv.LIs_cap      = 76.5;
btm.LIs_cap     = 1176;
bio.LIs_cap     =    0 + 0;
lfg.LIs_cap     =    3 + 0;
ees.LIs_cap     =    0 + 0;
% other.LIs_cap   = 1111.4;
% phs.LIs_cap     = 0;

% FUTURE SCENARIO renewable capacity in NE
wind.NEw_cap    = 0;
hydro.NEw_cap   = 0;
pv.NEw_cap      = 0;
btm.NEw_cap     = 0;
bio.NEw_cap     = 0;
lfg.NEw_cap     = 0;
ees.NEw_cap     = 0;

% FUTURE SCENARIO renewable capacity in PJM
wind.PJM_cap    = 0;
hydro.PJM_cap   = 0;
pv.PJM_cap      = 0;
btm.PJM_cap     = 0;
bio.PJM_cap     = 0;
lfg.PJM_cap     = 0;
ees.PJM_cap     = 0;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Input EXISTING Capacity Values (MW)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% EXISTING renewable capacity in A2F (values here are for 2016. Other 
% regions are set to zero installed capacity due to low penetration).
wind.A2F_exist_cap  = 1755;
hydro.A2F_exist_cap = 5219;
pv.A2F_exist_cap    =    0;
btm.A2F_exist_cap   =  266;
bio.A2F_exist_cap   =  148;
lfg.A2F_exist_cap   =  126;
ees.A2F_exist_cap   =    0;


% Existing renewable capacity in GHI
wind.GHI_exist_cap  =    0;
hydro.GHI_exist_cap =    0;
pv.GHI_exist_cap    =    0;
btm.GHI_exist_cap   =  155;
bio.GHI_exist_cap   =    0;
lfg.GHI_exist_cap   =    0;
ees.GHI_exist_cap   =    0;


% Existing renewable capacity in NYC
wind.NYC_exist_cap  =    0;
hydro.NYC_exist_cap =    0;
pv.NYC_exist_cap    =    0;
btm.NYC_exist_cap   =   82;
bio.NYC_exist_cap   =    0;
lfg.NYC_exist_cap   =    0;
ees.NYC_exist_cap   =    0;

% Existing renewable capacity on LI
wind.LIs_exist_cap  =    0;
hydro.LIs_exist_cap =    0;
pv.LIs_exist_cap    =    0;
btm.LIs_exist_cap   =  209;
bio.LIs_exist_cap   =    0;
lfg.LIs_exist_cap   =    0;
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
