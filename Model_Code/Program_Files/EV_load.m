function EV = EV_load(mpc)
%% generator data
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

%1  2   3   4   5   6   7   8    9 10  11  12  13  14  15  16    17      18      19      20    21
EV.gen = [
53	0	0	0	0	1	100	1	100	0	0	0	0	0	0	0	9999	9999	9999	9999	0	;	%
54	0	0	0	0	1	100	1	100	0	0	0	0	0	0	0	9999	9999	9999	9999	0	;	%
55	0	0	0	0	1	100	1	100	0	0	0	0	0	0	0	9999	9999	9999	9999	0	;	%
56	0	0	0	0	1	100	1	100	0	0	0	0	0	0	0	9999	9999	9999	9999	0	;	%
57	0	0	0	0	1	100	1	100	0	0	0	0	0	0	0	9999	9999	9999	9999	0	;	%
58	0	0	0	0	1	100	1	100	0	0	0	0	0	0	0	9999	9999	9999	9999	0	;	%
59	0	0	0	0	1	100	1	100	0	0	0	0	0	0	0	9999	9999	9999	9999	0	;	%
60	0	0	0	0	1	100	1	100	0	0	0	0	0	0	0	9999	9999	9999	9999	0	;	%
61	0	0	0	0	1	100	1	100	0	0	0	0	0	0	0	9999	9999	9999	9999	0	;	%
63	0	0	0	0	1	100	1	100	0	0	0	0	0	0	0	9999	9999	9999	9999	0	;	%
64	0	0	0	0	1	100	1	100	0	0	0	0	0	0	0	9999	9999	9999	9999	0	;	%
65	0	0	0	0	1	100	1	100	0	0	0	0	0	0	0	9999	9999	9999	9999	0	;	%
66	0	0	0	0	1	100	1	100	0	0	0	0	0	0	0	9999	9999	9999	9999	0	;	%
67	0	0	0	0	1	100	1	100	0	0	0	0	0	0	0	9999	9999	9999	9999	0	;	%
68	0	0	0	0	1	100	1	100	0	0	0	0	0	0	0	9999	9999	9999	9999	0	;	%
];

%% xGenData
EV.xgd_table.colnames = {
	'CommitKey', ...
		'CommitSched', ...
			'InitialPg'};

%1  2   3   
EV.xgd_table.data = [
2	1	1;	%1
2	1	1;	%2
2	1	1;	%3
2	1	1;	%4
2	1	1;	%5
2	1	1;	%6
2	1	1;	%7
2	1	1;	%8
2	1	1;	%9
2	1	1;	%10
2	1	1;	%11
2	1	1;	%12
2	1	1;	%13
2	1	1;	%14
2	1	1;	%15
];
