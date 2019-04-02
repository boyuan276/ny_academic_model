function [A2F_BTM_inc_cap, GHI_BTM_inc_cap, NYC_BTM_inc_cap, LIs_BTM_inc_cap, NEw_BTM_inc_cap, PJM_BTM_inc_cap,...
    A2F_ITM_inc_wind_cap, GHI_ITM_inc_wind_cap, NYC_ITM_inc_wind_cap, LIs_ITM_inc_wind_cap, NEw_ITM_inc_wind_cap, PJM_ITM_inc_wind_cap,...
    A2F_ITM_inc_hydro_cap, GHI_ITM_inc_hydro_cap, NYC_ITM_inc_hydro_cap, LIs_ITM_inc_hydro_cap, NEw_ITM_inc_hydro_cap, PJM_ITM_inc_hydro_cap,...
    A2F_ITM_inc_PV_cap, GHI_ITM_inc_PV_cap, NYC_ITM_inc_PV_cap, LIs_ITM_inc_PV_cap, NEw_ITM_inc_PV_cap, PJM_ITM_inc_PV_cap, ...
    A2F_ITM_inc_Bio_cap, GHI_ITM_inc_Bio_cap, NYC_ITM_inc_Bio_cap, LIs_ITM_inc_Bio_cap, NEw_ITM_inc_Bio_cap, PJM_ITM_inc_Bio_cap,...
    A2F_ITM_inc_LFG_cap, GHI_ITM_inc_LFG_cap, NYC_ITM_inc_LFG_cap, LIs_ITM_inc_LFG_cap, NEw_ITM_inc_LFG_cap, PJM_ITM_inc_LFG_cap,...
    A2F_ITM_inc_EES_cap, GHI_ITM_inc_EES_cap, NYC_ITM_inc_EES_cap, LIs_ITM_inc_EES_cap, NEw_ITM_inc_EES_cap, PJM_ITM_inc_EES_cap,...
    A2F_BTM_existing_cap, GHI_BTM_existing_cap, NYC_BTM_existing_cap, LIs_BTM_existing_cap, NEw_BTM_existing_cap, PJM_BTM_existing_cap,...
    A2F_existing_ITM_wind_ICAP, A2F_existing_ITM_hydro_ICAP, A2F_existing_ITM_PV_ICAP, A2F_existing_ITM_Bio_ICAP, A2F_existing_ITM_LFG_ICAP, A2F_existing_ITM_EES_ICAP,...
    GHI_existing_ITM_wind_ICAP, GHI_existing_ITM_hydro_ICAP, GHI_existing_ITM_PV_ICAP, GHI_existing_ITM_Bio_ICAP, GHI_existing_ITM_LFG_ICAP, GHI_existing_ITM_EES_ICAP,...
    NYC_existing_ITM_wind_ICAP, NYC_existing_ITM_hydro_ICAP, NYC_existing_ITM_PV_ICAP, NYC_existing_ITM_Bio_ICAP, NYC_existing_ITM_LFG_ICAP, NYC_existing_ITM_EES_ICAP,...
    LIs_existing_ITM_wind_ICAP, LIs_existing_ITM_hydro_ICAP, LIs_existing_ITM_PV_ICAP, LIs_existing_ITM_Bio_ICAP, LIs_existing_ITM_LFG_ICAP, LIs_existing_ITM_EES_ICAP,...
    NEw_existing_ITM_wind_ICAP, NEw_existing_ITM_hydro_ICAP, NEw_existing_ITM_PV_ICAP, NEw_existing_ITM_Bio_ICAP, NEw_existing_ITM_LFG_ICAP, NEw_existing_ITM_EES_ICAP,...
    PJM_existing_ITM_wind_ICAP, PJM_existing_ITM_hydro_ICAP, PJM_existing_ITM_PV_ICAP, PJM_existing_ITM_Bio_ICAP, PJM_existing_ITM_LFG_ICAP, PJM_existing_ITM_EES_ICAP,...
    EVSE_Gold_MWh, EVSE_Gold_MW] = NYAM2030
%NYAM2030 contains the future capacity values for the 2030 case compiled by
%Steve Burchett and the NYISO
%   Detailed explanation of data sources and assumptions should be
%   included here.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input FUTURE Capacity Values (MW)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Amount of INCREMENTAL BTM Capacity.
A2F_BTM_inc_cap = 1358;
GHI_BTM_inc_cap =  793;
NYC_BTM_inc_cap =  419;
LIs_BTM_inc_cap = 1069;
NEw_BTM_inc_cap =    0;
PJM_BTM_inc_cap =    0;

% Amount of ITM INCREMENTAL Wind Generation Capacity by Zone. 
A2F_ITM_inc_wind_cap = 4189;
GHI_ITM_inc_wind_cap =    0;
NYC_ITM_inc_wind_cap =  408;
LIs_ITM_inc_wind_cap =  591;
NEw_ITM_inc_wind_cap =    0;
PJM_ITM_inc_wind_cap =    0;

% Amount of ITM INCREMENTAL hydro Generation Capacity by region. 
A2F_ITM_inc_hydro_cap =  542;
GHI_ITM_inc_hydro_cap =   45;
NYC_ITM_inc_hydro_cap =    0;
LIs_ITM_inc_hydro_cap =    0;
NEw_ITM_inc_hydro_cap =    0;
PJM_ITM_inc_hydro_cap =    0;

% Amount of ITM INCREMENTAL Utility-scale PV Generation Capacity by
% region.
A2F_ITM_inc_PV_cap = 3044;
GHI_ITM_inc_PV_cap =  438;
NYC_ITM_inc_PV_cap =    0;
LIs_ITM_inc_PV_cap =  373;
NEw_ITM_inc_PV_cap =    0;
PJM_ITM_inc_PV_cap =    0;

% Amount of ITM INCREMENTAL Bio Generation Capacity by region.
% What does "biomass" mean in this context?????
A2F_ITM_inc_Bio_cap =  122;
GHI_ITM_inc_Bio_cap =    0;
NYC_ITM_inc_Bio_cap =    0;
LIs_ITM_inc_Bio_cap =    0;
NEw_ITM_inc_Bio_cap =    0;
PJM_ITM_inc_Bio_cap =    0;

% Amount of ITM INCREMENTAL LFG Generation Capacity by region.
A2F_ITM_inc_LFG_cap =   13;
GHI_ITM_inc_LFG_cap =    3;
NYC_ITM_inc_LFG_cap =   34;
LIs_ITM_inc_LFG_cap =    3;
NEw_ITM_inc_LFG_cap =    0;
PJM_ITM_inc_LFG_cap =    0;

% Amount of INCREMENTAL Storage capacity by region.
A2F_ITM_inc_EES_cap =    0;
GHI_ITM_inc_EES_cap =    0;
NYC_ITM_inc_EES_cap =    0;
LIs_ITM_inc_EES_cap =    0;
NEw_ITM_inc_EES_cap =    0;
PJM_ITM_inc_EES_cap =    0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input EXISTING Capacity Values (MW)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Existing BTM Capacity (values here are for 2016).
A2F_BTM_existing_cap =  266;
GHI_BTM_existing_cap =  155;
NYC_BTM_existing_cap =   82;
LIs_BTM_existing_cap =  209;
NEw_BTM_existing_cap =    0;
PJM_BTM_existing_cap =    0;

% Existing renewable capacity in A2F (values here are for 2016. Other 
% regions are set to zero installed capacity due to low penetration).
A2F_existing_ITM_wind_ICAP  = 1755;
A2F_existing_ITM_hydro_ICAP = 5219;
A2F_existing_ITM_PV_ICAP    =    0;
A2F_existing_ITM_Bio_ICAP   =  148;
A2F_existing_ITM_LFG_ICAP   =  126;
A2F_existing_ITM_EES_ICAP   =    0;


% Existing renewable capacity in GHI
GHI_existing_ITM_wind_ICAP  =    0;
GHI_existing_ITM_hydro_ICAP =    0;
GHI_existing_ITM_PV_ICAP    =    0;
GHI_existing_ITM_Bio_ICAP   =    0;
GHI_existing_ITM_LFG_ICAP   =    0;
GHI_existing_ITM_EES_ICAP   =    0;


% Existing renewable capacity in NYC
NYC_existing_ITM_wind_ICAP  =    0;
NYC_existing_ITM_hydro_ICAP =    0;
NYC_existing_ITM_PV_ICAP    =    0;
NYC_existing_ITM_Bio_ICAP   =    0;
NYC_existing_ITM_LFG_ICAP   =    0;
NYC_existing_ITM_EES_ICAP   =    0;

% Existing renewable capacity on LI
LIs_existing_ITM_wind_ICAP  =    0;
LIs_existing_ITM_hydro_ICAP =    0;
LIs_existing_ITM_PV_ICAP    =    0;
LIs_existing_ITM_Bio_ICAP   =    0;
LIs_existing_ITM_LFG_ICAP   =    0;
LIs_existing_ITM_EES_ICAP   =    0;

% Existing renewable capacity in NE
NEw_existing_ITM_wind_ICAP  =    0;
NEw_existing_ITM_hydro_ICAP =    0;
NEw_existing_ITM_PV_ICAP    =    0;
NEw_existing_ITM_Bio_ICAP   =    0;
NEw_existing_ITM_LFG_ICAP   =    0;
NEw_existing_ITM_EES_ICAP   =    0;

% Existing renewable capacity in PJM
PJM_existing_ITM_wind_ICAP  =    0;
PJM_existing_ITM_hydro_ICAP =    0;
PJM_existing_ITM_PV_ICAP    =    0;
PJM_existing_ITM_Bio_ICAP   =    0;
PJM_existing_ITM_LFG_ICAP   =    0;
PJM_existing_ITM_EES_ICAP   =    0;


% Get EVSE Load Data (MWh total for the Day)
% Electric Vehicle Energy Usage Forecast (2018 Gold Book) in GWh
%     A   B   C   D   E    F   G   H   I   J   K
EVSE_Gold_MWh = [
      3   5   4   0   2    5   6   3   5  13  23;     %2016
    154 183 180  12  99  206 230 100 150 520 781;     %2030
    ]./365;   

% Total Increase in Coincident Winter Peak Demand by Zone in MW (Use winter as its worse than summer)
%   A   B   C   D   E   F   G   H   I   J   K
EVSE_Gold_MW  = [
    1   1   1   0    1   1   2   1   1    4   7;       %2016
    30 36  35   2   19  40  45  20  29  101 153;       %2030
    ];    

end

