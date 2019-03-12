function [storage,EVSE_PminProfile] = ...
    EVSE_resource(EVSE_Gold_MWh, A2F_load_bus_count, GHI_load_bus_count, ...
    NYC_load_bus_count, LIs_load_bus_count)
%EVSE_Load takes in EVSE_Gold_MWh - the EV load estimate from the NYISO
%Gold Book - and creates load profiles and characterizes the battery
%resource from the EV fleet. 
%   Detailed explanation goes here


% Calculate EVSE MWh load at each bus
    %Pick load for the current Case & convert to MWh
    EVSE_Zone = EVSE_Gold_MWh(Case+1,:).*1000; %convert from GWh to MWh
    %Group by Region
    EVSE_Region = [sum(EVSE_Zone(1:6)) sum(EVSE_Zone(7:9)) EVSE_Zone(10) EVSE_Zone(11) 0];
    %Divide by # of load buses in each region = EVSE MWh to add to each load bus in each region [A2F, GHI, NYC, LIs]
    EVSE_Region_Ind = EVSE_Region./[A2F_load_bus_count GHI_load_bus_count NYC_load_bus_count LIs_load_bus_count 1];
    
    % Calculate EVSE MW peak at each bus
    %Determine Max EVSE Load in each region
    EVSE_Region_MW = [sum(EVSE_Gold_MW(Case+1,1:6)) sum(EVSE_Gold_MW(Case+1,7:9)) EVSE_Gold_MW(Case+1,10) EVSE_Gold_MW(Case+1,11) 0];
    EVSE_Region_Ind_MW = EVSE_Region_MW./[A2F_load_bus_count GHI_load_bus_count NYC_load_bus_count LIs_load_bus_count 1];
    
    % Add Batteries to each Load Bus
    % Calculate how many batteries we are adding here.
    BatCount = A2F_load_bus_count + GHI_load_bus_count + ...
        NYC_load_bus_count + LIs_load_bus_count;
    
    % Initialize
    EVSE_PminProfile = zeros(32,1);
    %Tables
    storage.gen             = zeros(BatCount,21);
    storage.sd_table.data   = zeros(BatCount,13);
    storage.xgd_table.data  = zeros(BatCount,2);
    storage.gencost         = zeros(BatCount,7);
%     storage.ExpectedTerminalStorageAim = zeros(BatCount,1);
%     storage.InitialStorage  = zeros(BatCount,1);
%     storage.InitialStorageCost  = zeros(BatCount,1);
%     storage.InitialStorageLowerBound  = zeros(BatCount,1);
%     storage.InitialStorageUpperBound  = zeros(BatCount,1);
%     storage.TerminalStorageUpperBound  = zeros(BatCount,1);
    
    %Storage Data Parameters
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
    
    % Create Battery Data Containers
    for Bat = 1:BatCount
        % Which Region are we in?
        if sum(ismember(NYCA_Load_buses(Bat),A2F_Load_buses)) >0
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
        
        % Add individual battery parameters
        % bus            Qmin    mBase   Pmax    Pc1     Qc1min	Qc2min	ramp_agc	ramp_q
        % 	Pg	Qg	Qmax	Vg      status	Pmin	Pc2     Qc1max	Qc2max	ramp_10     apf
        %                                                                        ramp_30
        storage.gen(Bat,:) = [NYCA_Load_buses(Bat)...
            0   0   0   0   1   100 1   -0.00001   -EVSE_Region_Ind_MW(Region)...
            0   0   0   0   0   0   0   0   EVSE_Region_Ind_MW(Region)   0   0];
        
        % Record Pmin Data
        EVSE_PminProfile(Bat) = -EVSE_Region_Ind_MW(Region);
        
        % Add storage data. Input parameters are defined below:
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
        %1   2   3   4   5   6   7                         8   9   10  11  12                      13
        storage.sd_table.data(Bat,:) =   [0   0   0   0   0   0   EVSE_Region_Ind(Region)   1   1   0   0   EVSE_Region_Ind(Region) EVSE_Region_Ind(Region)];
        
        % Add storage extra gen data. Input parameters are defined below:
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
                                        %1    2      3   4   5   6   7   8   9   10  11  12
        storage.xgd_table.data(Bat,:) = [2    1  ];% 0   0   0   0   0   0   0   0   0   0];
        
        % Add storage cost data; 1 row for each battery. Each row
        % has the following parameter definitions. Note that the
        % first column is must be filled in with the interger 2 in
        % order to invoke these options:
        % 2	startup    shutdown     n	c(n-1)	...	 c0
        
        %storage.gencost(Bat,:) = [2    0	0	3	0.01 10 100];
        storage.gencost(Bat,:) = [2     0	0	2	0     0   0];
    end
    
end

