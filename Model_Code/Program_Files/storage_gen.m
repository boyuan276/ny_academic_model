function storage = storage_gen(...
    A2F_existing_ITM_EES_ICAP, GHI_existing_ITM_EES_ICAP, NYC_existing_ITM_EES_ICAP, LIs_existing_ITM_EES_ICAP, NEw_existing_ITM_EES_ICAP, PJM_existing_ITM_EES_ICAP,...
    A2F_ITM_inc_EES_cap, GHI_ITM_inc_EES_cap, NYC_ITM_inc_EES_cap, LIs_ITM_inc_EES_cap, NEw_ITM_inc_EES_cap, PJM_ITM_inc_EES_cap,...
    A2F_Load_buses, GHI_Load_buses, NYC_Load_buses, LIs_Load_buses, NYCA_Load_buses, NEw_Load_buses, PJM_Load_buses,...
    A2F_load_bus_count,GHI_load_bus_count, NYC_load_bus_count, LIs_load_bus_count, NYCA_load_bus_count, NEw_load_bus_count, PJM_load_bus_count)
%STORAGE_GEN  Storage data file for the New York Academic Model which 
%initializes storage resources based upon input power capacities.

%   
%   
%   

%% Evenly distribute battery capacity

BatPCbyRgn = [
    A2F_existing_ITM_EES_ICAP + A2F_ITM_inc_EES_cap,...
    GHI_existing_ITM_EES_ICAP + GHI_ITM_inc_EES_cap,...
    NYC_existing_ITM_EES_ICAP + NYC_ITM_inc_EES_cap,...
    LIs_existing_ITM_EES_ICAP + LIs_ITM_inc_EES_cap,...
    NEw_existing_ITM_EES_ICAP + NEw_ITM_inc_EES_cap,...
    PJM_existing_ITM_EES_ICAP + PJM_ITM_inc_EES_cap
    ]; 

BatPCbyBus = BatPCbyRgn./[A2F_load_bus_count, GHI_load_bus_count, NYC_load_bus_count, LIs_load_bus_count, NEw_load_bus_count, PJM_load_bus_count];

%% Add Batteries to each Load Bus
% Calculate how many batteries we are adding (add one battery to each
% load bus).
BatCount = NYCA_load_bus_count + NEw_load_bus_count + PJM_load_bus_count;
All_Load_buses = [NYCA_Load_buses, NEw_Load_buses, PJM_Load_buses];

for Bat = 1:BatCount
    % In which region are batteries located?
    if sum(ismember(All_Load_buses(Bat), A2F_Load_buses)) > 0
        Region = 1; %Region 1 is A2F
    elseif sum(ismember(All_Load_buses(Bat), GHI_Load_buses)) > 0
        Region = 2; %Region 2 is GHI
    elseif sum(ismember(All_Load_buses(Bat), NYC_Load_buses)) > 0
        Region = 3; %Region 3 is NYC
    elseif sum(ismember(All_Load_buses(Bat), LIs_Load_buses)) > 0
        Region = 4; %Region 4 is LI
    elseif sum(ismember(All_Load_buses(Bat), NEw_Load_buses)) > 0
        Region = 5; %Region 5 is NE
    elseif sum(ismember(All_Load_buses(Bat), PJM_Load_buses)) > 0
        Region = 6; %Region 6 is PJM
    end

%%-----  storage characteristics for the battery -----
pcap = BatPCbyBus(Region);      %% power capacity (MW)
ecap = pcap*(17233/9934);       %% energy capacity (MWh)
scost = 45.166667;              %% cost/value of initial/residual stored energy
%scost = 30;                     %% cost/value of initial/residual stored energy
scost2 = 41.6666667;            %% cost/value of initial/residual stored energy
scost3 = 53.3333333;            %% cost/value of initial/residual stored energy

%% generator data
% generator data
% 1	 GEN_BUS	bus number
% 2	 PG         Pg, real power output (MW)
% 3	 QG         Qg, reactive power output (MVAr)
% 4	 QMAX       Qmax, maximum reactive power output (MVAr)
% 5	 QMIN       Qmin, minimum reactive power output (MVAr)
% 6	 VG         Vg, voltage magnitude setpoint (p.u.)
% 7	 MBASE      mBase, total MVA base of machine, defaults to baseMVA
% 8	 GEN_STATUS	status, > 0 - in service, <= 0 - out of service
% 9	 PMAX       Pmax, maximum real power output (MW)
% 10 PMIN       Pmin, minimum real power output (MW)
% 11 PC1        Pc1, lower real power output of PQ capability curve (MW)
% 12 PC2        Pc2, upper real power output of PQ capability curve (MW)
% 13 QC1MIN     Qc1min, minimum reactive power output at Pc1 (MVAr)
% 14 QC1MAX     Qc1max, maximum reactive power output at Pc1 (MVAr)
% 15 QC2MIN     Qc2min, minimum reactive power output at Pc2 (MVAr)
% 16 QC2MAX     Qc2max, maximum reactive power output at Pc2 (MVAr)
% 17 RAMP_AGC	ramp rate for load following/AGC (MW/min)
% 18 RAMP_10	ramp rate for 10 minute reserves (MW)
% 19 RAMP_30	ramp rate for 30 minute reserves (MW)
% 20 RAMP_Q     ramp rate for reactive power (2 sec timescale) (MVAr/min)
% 21 APF        area participation factor

%    1                      2   3   4   5   6   7   8      9       10   11  12  13  14  15  16  17  18  19      20  21
storage.gen(Bat,:) = [
	 All_Load_buses(Bat)	0	0	0	0	1	100	1	pcap	-pcap	0	0	0	0	0	0	0	0	pcap	0	0;
];

%%-----  OPF Data  -----%%
%% generator cost data
%	1	startup	shutdown	n	x1	y1	...	xn	yn
%	2	startup	shutdown	n	c(n-1)	...	c0
% storage.gencost = [
% 	2	0	0	2	0	0;
% ];

%% xGenData
storage.xgd_table.colnames = {
	'CommitKey', ...
		'CommitSched', ...
			'PositiveActiveReservePrice', ...
				'PositiveActiveReserveQuantity', ...
					'NegativeActiveReservePrice', ...
						'NegativeActiveReserveQuantity', ...
							'PositiveActiveDeltaPrice', ...
								'NegativeActiveDeltaPrice', ...
									'PositiveLoadFollowReservePrice', ...
										'PositiveLoadFollowReserveQuantity', ...
											'NegativeLoadFollowReservePrice', ...
												'NegativeLoadFollowReserveQuantity', ...
};

storage.xgd_table.data(Bat,:) = [
	2	1	1e-8	2*pcap	2e-8	2*pcap	1e-9	1e-9	1e-6	2*pcap	1e-6	2*pcap;
];

%% StorageData
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
};

storage.sd_table.data(Bat,:) = [
	0	0	ecap	scost	scost	0	ecap	1	1	1e-5	0;
%	0	0	ecap	scost2	scost2	0	ecap	1	1	0	0;
%	0	0	ecap	scost3	scost3	0	ecap	1	1	0	0;
];

end

end
    