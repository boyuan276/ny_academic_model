function storage = storage_gen(mpc)
%STORAGE_GEN  Storage data file for the New York Academic Model which 
%initializes storage resources based upon input profiles.

%   MOST
%   Copyright (c) 2015-2016, Power Systems Engineering Research Center (PSERC)
%   by Ray Zimmerman, PSERC Cornell

%%-----  storage  -----
ecap = 200;          %% energy capacity
pcap = ecap * .4; %0.25; %% power capacity
scost = 45.166667;      %% cost/value of initial/residual stored energy
%scost = 30;      %% cost/value of initial/residual stored energy
scost2 = 41.6666667;      %% cost/value of initial/residual stored energy
scost3 = 53.3333333;      %% cost/value of initial/residual stored energy
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

%   1   2   3   4   5   6   7   8      9       10   11  12  13  14  15  16  17  18  19  20  21
storage.gen = [
%	1	0	0	0	0	1	100	1	pcap	-pcap	0	0	0	0	0	0	0	20	20	0	0;
%	2	0	0	0	0	1	100	1	pcap	-pcap	0	0	0	0	0	0	0	20	20	0	0;
	3	0	0	0	0	1	100	1	pcap	-pcap	0	0	0	0	0	0	0	20	20	0	0;
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

storage.xgd_table.data = [
	2	1	1e-8	2*pcap	2e-8	2*pcap	1e-9	1e-9	1e-6	2*pcap	1e-6	2*pcap;
%	2	1	1e-8	2*pcap	2e-8	2*pcap	1e-9	1e-9	1e-6	2*pcap	1e-6	2*pcap;
%	2	1	1e-8	2*pcap	2e-8	2*pcap	1e-9	1e-9	1e-6	2*pcap	1e-6	2*pcap;
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

storage.sd_table.data = [
	0	0	ecap	scost	scost	0	ecap	1	1	1e-5	0;
%	0	0	ecap	scost2	scost2	0	ecap	1	1	0	0;
%	0	0	ecap	scost3	scost3	0	ecap	1	1	0	0;
];
    