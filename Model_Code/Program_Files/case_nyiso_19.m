function mpc = case_nyiso16
% Case file defines parameters of buses, generators, branches, and
% generator costs. Only thermal generators and imports are included now.

% 2016 NPCC 68-bus 16-machine system, developed in 1980s, include NYISO,
% ISONE, parts of PJM, and eastern Canada. NPCC model's parameters, R, X,
% B were adjusted to represent NYS power system. An exact match was
% intentionally avoided to protect confidential information.

% 68 buses = 52 load buses + 14 generator buses + 1 reference bus + 1 bus
% for 2016 ITM renewables

% MATPOWER Case Format : Version 2
mpc.version = '2';

% system MVA base
mpc.baseMVA = 100;

%% bus data
%Columns
%   columns 1-13 must be included in input matrix (in case file)
%    1  BUS_I       bus number (positive integer)
%    2  BUS_TYPE    bus type (1 = PQ (load), 2 = PV (gen), 3 = ref, 4 = isolated)
%    3  PD          Pd, real power demand (MW)
%    4  QD          Qd, reactive power demand (MVAr)
%    5  GS          Gs, shunt conductance (MW demanded at V = 1.0 p.u.)
%    6  BS          Bs, shunt susceptance (MVAr injected at V = 1.0 p.u.)
%    7  BUS_AREA    area number, (positive integer)
%    8  VM          Vm, voltage magnitude (p.u.)
%    9  VA          Va, voltage angle (degrees)
%    10 BASE_KV     baseKV, base voltage (kV)
%    11 ZONE        zone, loss zone (positive integer)
%    12 VMAX        maxVm, maximum voltage magnitude (p.u.)
%    13 VMIN        minVm, minimum voltage magnitude (p.u.)

%1  2    3      4   5   6   7   8   9   10  11  12   13
mpc.bus = [
1	1	189.1	0	0	0	1	1	0	230	1	1.1	0.9	;	
2	1	0       0	0	0	1	1	0	230	1	1.1	0.9	;	
3	1	177.4	0	0	0	1	1	0	230	1	1.1	0.9	;	
4	1	177.4	0	0	0	1	1	0	230	1	1.1	0.9	;	
5	1	0       0	0	0	1	1	0	230	1	1.1	0.9	;	
6	1	0       0	0	0	1	1	0	230	1	1.1	0.9	;	
7	1	177.4	0	0	0	1	1	0	230	1	1.1	0.9	;	
8	1	177.4	0	0	0	1	1	0	230	1	1.1	0.9	;	
9	1	189.1	0	0	0	1	1	0	230	1	1.1	0.9	;	
10	1	0       0	0	0	1	1	0	230	1	1.1	0.9	;	
11	1	0       0	0	0	1	1	0	230	1	1.1	0.9	;	
12	1	410.4	0	0	0	1	1	0	230	1	1.1	0.9	;	
13	1	0       0	0	0	1	1	0	230	1	1.1	0.9	;	
14	1	0       0	0	0	1	1	0	230	1	1.1	0.9	;	
15	1	410.4	0	0	0	1	1	0	230	1	1.1	0.9	;	
16	1	410.4	0	0	0	1	1	0	230	1	1.1	0.9	;	
17	1	0       0	0	0	1	1	0	230	1	1.1	0.9	;	
18	1	410.4	0	0	0	1	1	0	230	1	1.1	0.9	;	
19	1	0       0	0	0	1	1	0	230	1	1.1	0.9	;	
20	1	410.4	0	0	0	1	1	0	230	1	1.1	0.9	;	
21	1	328.4	0	0	0	1	1	0	230	1	1.1	0.9	;	
22	1	0       0	0	0	1	1	0	230	1	1.1	0.9	;	
23	1	328.4	0	0	0	1	1	0	230	1	1.1	0.9	;	
24	1	328.4	0	0	0	1	1	0	230	1	1.1	0.9	;	
25	1	177.4	0	0	0	1	1	0	230	1	1.1	0.9	;	
26	1	0       0	0	0	1	1	0	230	1	1.1	0.9	;	
27	1	410.4	0	0	0	1	1	0	230	1	1.1	0.9	;	
28	1	0       0	0	0	1	1	0	230	1	1.1	0.9	;	
29	1	0       0	0	0	1	1	0	230	1	1.1	0.9	;	
30	1	0       0	0	0	1	1	0	230	1	1.1	0.9	;	
31	1	0       0	0	0	1	1	0	230	1	1.1	0.9	;	
32	1	0       0	0	0	1	1	0	230	1	1.1	0.9	;	
33	1	189.1	0	0	0	1	1	0	230	1	1.1	0.9	;	
34	1	0       0	0	0	1	1	0	230	1	1.1	0.9	;	
35	1	0       0	0	0	1	1	0	230	1	1.1	0.9	;	
36	1	189.1	0	0	0	1	1	0	230	1	1.1	0.9	;	
37	1	189.1	0	0	0	1	1	0	230	1	1.1	0.9	;	
38	1	0       0	0	0	1	1	0	230	1	1.1	0.9	;	
39	1	189.1	0	0	0	1	1	0	230	1	1.1	0.9	;	
40	1	189.1	0	0	0	1	1	0	230	1	1.1	0.9	;	
41	1	189.1	0	0	0	1	1	0	230	1	1.1	0.9	;	
42	1	189.1	0	0	0	1	1	0	230	1	1.1	0.9	;	
43	1	0       0	0	0	1	1	0	230	1	1.1	0.9	;	
44	1	189.1	0	0	0	1	1	0	230	1	1.1	0.9	;	
45	1	189.1	0	0	0	1	1	0	230	1	1.1	0.9	;	
46	1	189.1	0	0	0	1	1	0	230	1	1.1	0.9	;	
47	1	189.1	0	0	0	1	1	0	230	1	1.1	0.9	;	
48	1	189.1	0	0	0	1	1	0	230	1	1.1	0.9	;	
49	1	189.1	0	0	0	1	1	0	230	1	1.1	0.9	;	
50	1	189.1	0	0	0	1	1	0	230	1	1.1	0.9	;	
51	1	189.1	0	0	0	1	1	0	230	1	1.1	0.9	;	
52	1	189.1	0	0	0	1	1	0	230	1	1.1	0.9	;	
53	2	0       0	0	0	1	1	0	230	1	1.1	0.9	;	%1
54	2	0       0	0	0	1	1	0	230	1	1.1	0.9	;	%2
55	2	0       0	0	0	1	1	0	230	1	1.1	0.9	;	%3
56	2	0       0	0	0	1	1	0	230	1	1.1	0.9	;	%4
57	2	0       0	0	0	1	1	0	230	1	1.1	0.9	;	%5
58	2	0       0	0	0	1	1	0	230	1	1.1	0.9	;	%6
59	2	0       0	0	0	1	1	0	230	1	1.1	0.9	;	%7
60	2	0       0	0	0	1	1	0	230	1	1.1	0.9	;	%8
61	2	0       0	0	0	1	1	0	230	1	1.1	0.9	;	%9
62	3	0       0	0	0	1	1	0	230	1	1.1	0.9	;	%Reference Bus
63	1	0       0	0	0	1	1	0	230	1	1.1	0.9	;	%This is the A2F 2016 ITM Gen Bus. Treat as load for now
64	2	0       0	0	0	1	1	0	230	1	1.1	0.9	;	%10
65	2	0       0	0	0	1	1	0	230	1	1.1	0.9	;	%11
66	2	0       0	0	0	1	1	0	230	1	1.1	0.9	;	%12
67	2	0       0	0	0	1	1	0	230	1	1.1	0.9	;	%13
68	2	0       0	0	0	1	1	0	230	1	1.1	0.9	;	%14
];
%1  2    3      4   5   6   7   8   9   10  11  12   13


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

%1   2  3   4         5        6    7   8     9      10    11  12  13  14  15  16   17      18     19      20  21
%bus    Qg Qmax     Qmin      Vg   mBase	 Pmax   Pmin   Pc1 Pc2        Qc2min           ramp_10             apf
%   Pg                                 stat                       Qc1min      Qc2max  	      	  ramp_30     
%                                                                     Qc1max      ramp_agc                ramp_q
mpc.gen = [
67	0	0	9999	-9999	 1.00 	100	1	3500	2625	0	0	0	0	0	0	0.01	0.67	2       0       0	;	%	 Nuke A2F           1
54	0	0	9999	-9999	 1.00 	100	1	1100	825     0	0	0	0	0	0	0.01	0.67	2       0.00	0	;	%	 Nuke GHI           2
60	0	0	9999	-9999	 1.00 	100	1	1100	825     0	0	0	0	0	0	0.01	0.67	2       0.00	0	;	%	 Nuke GHI           3
65	0	0	9999	-9999	 1.00 	100	1	816.5	0       0	0	0	0	0	0	3.22	32.2	96.3    0.00	0	;	%	 Steam A2F          4
64	0	0	9999	-9999	 1.00 	100	1	816.5	0       0	0	0	0	0	0	3.22	32.2	96.3    0.00	0	;	%	 Steam A2F          5
53	0	0	9999	-9999	 1.00 	100	1	1189	0       0	0	0	0	0	0	6.51	65.1	195.25	0.00	0	;	%	 Steam GHI          6
56	0	0	9999	-9999	 1.00 	100	1	3729	0       0	0	0	0	0	0	16.43	164.33	493 	0.00	0	;	%	 Steam NYC          7
58	0	0	9999	-9999	 1.00 	100	1	2060	34      0	0	0	0	0	0	10.02	100.35	300.75  0.00	0	;	%	 Steam LI           8
61	0	0	9999	-9999	 1.00 	100	1	2000	0       0	0	0	0	0	0	0.83	83.33	0       0.00	0	;	%	 ISONE Import       9
68	0	0	9999	-9999	 1.00 	100	1	4161	108     0	0	0	0	0	0	17.4	174 	522     0.00	0	;	%	 CC A2F             10
57	0	0	9999	-9999	 1.00 	100	1	2716	493     0	0	0	0	0	0	12.11   121.08	363.25  0.00	0	;	%	 CC NYC             11
55	0	0	9999	-9999	 1.00 	100	1	882 	0       0	0	0	0	0	0	7.84	78.417	235.35	0.00	0	;	%	 GT NYC             12
59	0	0	9999	-9999	 1.00 	100	1	1039	0   	0	0	0	0	0	0	6.08	60.75	182.25	0       0	;	%	 GT LI              13
66	0	0	9999	-9999	 1.00 	100	1	10000	0       0	0	0	0	0	0	0.83	83.33	0       0       0	;	%	 HQ Import A2F      14
]; 

%% branch data
% 1	 F_BUS      f, from bus number	
% 2	 T_BUS      t, to bus number	
% 3	 BR_R       r, resistance (p.u.)	
% 4	 BR_X       x, reactance (p.u.)	
% 5	 BR_B       b, total line charging susceptance (p.u.)	
% 6	 RATE_A     rateA, MVA rating A (long term rating)	LTE Rating
% 7	 RATE_B     rateB, MVA rating B (short term rating)	STE Rating
% 8	 RATE_C     rateC, MVA rating C (emergency rating)	Emergency Rating
% 9	 TAP        ratio, transformer off nominal turns ratio	
% 10 SHIFT      angle, transformer phase shift angle (degrees)	
% 11 BR_STATUS	initial branch status, 1 - in service, 0 - out of service	Set to 1
% 12 ANGMIN     minimum angle difference, angle(Vf) - angle(Vt) (degrees)	Set to -360
% 13 ANGMAX     maximum angle difference, angle(Vf) - angle(Vt) (degrees)	Set to 360

%fbus	  r	      x 	  b	  rateA    rateC	 angle	   angmin
%   tbus                           rateB   tap_ratio  status      angmax
%1  2     3       4       5     6   7   8     9    10  11    12      13   
mpc.branch = [
1	2	0.0035 	0.0411 	0.6987 	0	0	0	0.0000 	0	1	-360	360	;%1
1	30	0.0008 	0.0074 	0.4800 	0	0	0	0.0000 	0	1	-360	360	;%2
2	3	0.0013 	0.0151 	0.2572 	0	0	0	0.0000 	0	1	-360	360	;%3
2	25	0.0070 	0.0086 	0.1460 	0	0	0	0.0000 	0	1	-360	360	;%4
2	53	0.0000 	0.0181 	0.0000 	0	0	0	1.0250 	0	1	-360	360	;%5
3	4	0.0013 	0.0213 	0.2214 	0	0	0	0.0000 	0	1	-360	360	;%
3	18	0.0011 	0.0133 	0.2138 	0	0	0	0.0000 	0	1	-360	360	;%
4	5	0.0008 	0.0128 	0.1342 	0	0	0	0.0000 	0	1	-360	360	;%
4	14	0.0008 	0.0129 	0.1382 	0	0	0	0.0000 	0	1	-360	360	;%
5	6	0.0002 	0.0026 	0.0434 	0	0	0	0.0000 	0	1	-360	360	;%10
5	8	0.0008 	0.0112 	0.1476 	0	0	0	0.0000 	0	1	-360	360	;
6	7	0.0006 	0.0092 	0.1130 	0	0	0	0.0000 	0	1	-360	360	;
6	11	0.0007 	0.0082 	0.1389 	0	0	0	0.0000 	0	1	-360	360	;
6	54	0.0000 	0.0250 	0.0000 	0	0	0	1.0700 	0	1	-360	360	;
7	8	0.0004 	0.0046 	0.0780 	0	0	0	0.0000 	0	1	-360	360	;%15
8	9	0.0023 	0.0363 	0.3804 	0	0	0	0.0000 	0	1	-360	360	;
9	30	0.0019 	0.0183 	0.2900 	0	0	0	0.0000 	0	1	-360	360	;
10	11	0.0004 	0.0043 	0.0729 	0	0	0	0.0000 	0	1	-360	360	;
10	13	0.0004 	0.0043 	0.0729 	0	0	0	0.0000 	0	1	-360	360	;
10	55	0.0000 	0.0200 	0.0000 	0	0	0	1.0700 	0	1	-360	360	;%20
12	11	0.0016 	0.0435 	0.0000 	0	0	0	1.0600 	0	1	-360	360	;
12	13	0.0016 	0.0435 	0.0000 	0	0	0	1.0600 	0	1	-360	360	;
13	14	0.0009 	0.0101 	0.1723 	0	0	0	0.0000 	0	1	-360	360	;
14	15	0.0018 	0.0217 	0.3660 	0	0	0	0.0000 	0	1	-360	360	;
15	16	0.0009 	0.0094 	0.1710 	0	0	0	0.0000 	0	1	-360	360	;%25
16	17	0.0007 	0.0089 	0.1342 	0	0	0	0.0000 	0	1	-360	360	;
16	19	0.0016 	0.0195 	0.3040 	0	0	0	0.0000 	0	1	-360	360	;
16	21	0.0008 	0.0135 	0.2548 	0	0	0	0.0000 	0	1	-360	360	;
16	24	0.0003 	0.0059 	0.0680 	0	0	0	0.0000 	0	1	-360	360	;
17	18	0.0007 	0.0082 	0.1319 	0	0	0	0.0000 	0	1	-360	360	;%30
17	27	0.0013 	0.0173 	0.3216 	0	0	0	0.0000 	0	1	-360	360	;
19	20	0.0007 	0.0138 	0.0000 	0	0	0	1.0600 	0	1	-360	360	;
19	56	0.0007 	0.0142 	0.0000 	0	0	0	1.0700 	0	1	-360	360	;
20	57	0.0009 	0.0180 	0.0000 	0	0	0	1.0090 	0	1	-360	360	;
21	22	0.0008 	0.0140 	0.2565 	0	0	0	0.0000 	0	1	-360	360	;%35
22	23	0.0006 	0.0096 	0.1846 	0	0	0	0.0000 	0	1	-360	360	;
22	58	0.0000 	0.0143 	0.0000 	0	0	0	1.0250 	0	1	-360	360	;
23	24	0.0022 	0.0350 	0.3610 	0	0	0	0.0000 	0	1	-360	360	;
23	59	0.0005 	0.0272 	0.0000 	0	0	0	0.0000 	0	1	-360	360	;
25	26	0.0032 	0.0323 	0.5310 	0	0	0	0.0000 	0	1	-360	360	;%40
25	60	0.0006 	0.0232 	0.0000 	0	0	0	1.0250 	0	1	-360	360	;
26	27	0.0014 	0.0147 	0.2396 	0	0	0	0.0000 	0	1	-360	360	;
26	28	0.0043 	0.0474 	0.7802 	0	0	0	0.0000 	0	1	-360	360	;
26	29	0.0057 	0.0625 	1.0290 	0	0	0	0.0000 	0	1	-360	360	;
28	29	0.0014 	0.0151 	0.2490 	0	0	0	0.0000 	0	1	-360	360	;%45
29	61	0.0008 	0.0156 	0.0000 	0	0	0	1.0250 	0	1	-360	360	;
9	30	0.0019 	0.0183 	0.2900 	0	0	0	0.0000 	0	1	-360	360	;
9	36	0.0022 	0.0196 	0.3400 	0	0	0	0.0000 	0	1	-360	360	;
9	36	0.0022 	0.0196 	0.3400 	0	0	0	0.0000 	0	1	-360	360	;
36	37	0.0005 	0.0045 	0.3200 	0	0	0	0.0000 	0	1	-360	360	;%50
34	36	0.0033 	0.0111 	1.4500 	0	0	0	0.0000 	0	1	-360	360	;
35	34	0.0001 	0.0074 	0.0000 	0	0	0	0.9460 	0	1	-360	360	;
33	34	0.0011 	0.0157 	0.2020 	0	0	0	0.0000 	0	1	-360	360	;
32	33	0.0008 	0.0099 	0.1680 	0	0	0	0.0000 	0	1	-360	360	;
30	31	0.0013 	0.0187 	0.3330 	0	0	0	0.0000 	0	1	-360	360	;%55
30	32	0.0024 	0.0288 	0.4880 	0	0	0	0.0000 	0	1	-360	360	;
1	31	0.0016 	0.0163 	0.2500 	0	0	0	0.0000 	0	1	-360	360	;
31	38	0.0011 	0.0147 	0.2470 	0	0	0	0.0000 	0	1	-360	360	;
33	38	0.0036 	0.0444 	0.6930 	0	0	0	0.0000 	0	1	-360	360	;
38	46	0.0022 	0.0284 	0.4300 	0	0	0	0.0000 	0	1	-360	360	;%60
46	49	0.0018 	0.0274 	0.2700 	0	0	0	0.0000 	0	1	-360	360	;
1	47	0.0013 	0.0188 	1.3100 	0	0	0	0.0000 	0	1	-360	360	;
47	48	0.0025 	0.0268 	0.4000 	0	0	0	0.0000 	0	1	-360	360	;
47	48	0.0025 	0.0268 	0.4000 	0	0	0	0.0000 	0	1	-360	360	;
48	40	0.0020 	0.0220 	1.2800 	0	0	0	0.0000 	0	1	-360	360	;%65
35	45	0.0007 	0.0175 	1.3900 	0	0	0	0.0000 	0	1	-360	360	;
37	43	0.0005 	0.0276 	0.0000 	0	0	0	0.0000 	0	1	-360	360	;
43	44	0.0001 	0.0011 	0.0000 	0	0	0	0.0000 	0	1	-360	360	;
44	45	0.0025 	0.0730 	0.0000 	0	0	0	0.0000 	0	1	-360	360	;
39	44	0.0000 	0.0411 	0.0000 	0	0	0	0.0000 	0	1	-360	360	;%70
39	45	0.0000 	0.0839 	0.0000 	0	0	0	0.0000 	0	1	-360	360	;
45	51	0.0004 	0.0105 	0.7200 	0	0	0	0.0000 	0	1	-360	360	;
50	52	0.0012 	0.0288 	2.0600 	0	0	0	0.0000 	0	1	-360	360	;
50	51	0.0009 	0.0221 	1.6200 	0	0	0	0.0000 	0	1	-360	360	;
49	52	0.0076 	0.1141 	1.1600 	0	0	0	0.0000 	0	1	-360	360	;%75
52	42	0.0040 	0.0600 	2.2500 	0	0	0	0.0000 	0	1	-360	360	;
42	41	0.0040 	0.0600 	2.2500 	0	0	0	0.0000 	0	1	-360	360	;
41	40	0.0060 	0.0840 	3.1500 	0	0	0	0.0000 	0	1	-360	360	;
31	62	0.0000 	0.0260 	0.0000 	0	0	0	1.0400 	0	1	-360	360	;
32	63	0.0000 	0.0130 	0.0000 	0	0	0	1.0400 	0	1	-360	360	;%80
36	64	0.0000 	0.0075 	0.0000 	0	0	0	1.0400 	0	1	-360	360	;
37	65	0.0000 	0.0033 	0.0000 	0	0	0	1.0400 	0	1	-360	360	;
41	66	0.0000 	0.0015 	0.0000 	0	0	0	1.0000 	0	1	-360	360	;
42	67	0.0000 	0.0015 	0.0000 	0	0	0	1.0000 	0	1	-360	360	;
52	68	0.0000 	0.0030 	0.0000 	0	0	0	1.0000 	0	1	-360	360	;%85
1	27	0.0320 	0.3200 	0.4100 	0	0	0	1.0000 	0	1	-360	360	;
];

%%-----  OPF Data  -----%%
%% generator cost data
%	1	startup	shutdown	n	x1	y1	...	xn	yn
%	2	startup	shutdown	n	c(n-1)	...	c0

mpc.gencost = [
2	80000       0	3	0.001	5       225	;       %	Nuke A2F         1
2	80000       0	3	0.001	6       200	;       %	Nuke GHI         2
2	80000       0	3	0.001	5.5     300	;       %	Nuke GHI         3
2	60000       0	3	0.0005	9       250	;       %	Steam A2F        4
2	60000       0	3	0.001	9       300	;       %	Steam A2F        5
2	60000       0	3	0.001	7.5     250	;       %	Steam GHI        6
2	60000       0	3	0.001	9       175	;       %	Steam NYC        7
2	60000       0	3	0.001	8       225	;       %	Steam LI         8
2	300000000	0	3   0.001	10      808.633	;   %	ISONE Import     9
2	15000       0	3	0.001	9.5     400	;       %	CC A2F           10
2	20000       0	3	0.001	10      350	;       %	CC NYC           11
2	1000        0	3	0.001	13      50	;       %	GT NYC           12
2	1000        0	3	0.001	13.2	50	;       %	GT LI            13
2	300000000	0	3	0.001	1.0383	808.633	;   %	HQ Import A2F    14
];

