function xgd_table = xgd_DAM(mpc)

xgd_table.colnames = {
'InitialState',...
    'CommitKey', ...
        'CommitSched', ...
            'MinUp', ...
                'MinDown', ...
%                     'PositiveActiveReservePrice', ...
%                             'PositiveActiveReserveQuantity', ...
%                                     'NegativeActiveReservePrice', ... %DOUBLE THE POS VALUE?
%                                             'NegativeActiveReserveQuantity', ...
%                                                     'PositiveActiveDeltaPrice', ...
%                                                             'NegativeActiveDeltaPrice', ...
%                                                                     'PositiveLoadFollowReservePrice', ...
%                                                                             'PositiveLoadFollowReserveQuantity', ...
%                                                                                 'NegativeLoadFollowReservePrice', ...
%                                                                                         'NegativeLoadFollowReserveQuantity', ...
};

%% Tight
%1 InitialState: if positive (negative), number of uptime (downtime)
%periods at time t=0
%2 CommitKey: -1 offline, 0 or 1 availale for UC decisions, 2 must run
%3 CommitSched: 0 or 1, UC status to use for non-UC runs
%4 MinUp: minimum up time in number of periods
%5 MinDown: minimum downtime in number of periods
%1      2   3    4   5     
xgd_table.data = [
-25     1	1	24	22	;	%1 Nuke A2F: always on
-25     1	1	24	22	;	%2 Nuke GHI
-25     1	1	24	22	;	%3 Nuke GHI
-25     1	1	18	16	;	%4 Steam A2F 
-25     1	1	18	16	;	%5 Steam A2F 
-25     1	1	14	12	;	%6 Steam GHI
-25     1	1	14	12	;	%7 Steam NYC
-25     1	1	14	12	;	%8 Steam LI
-100	-1	1	2	1	;	%9 ISONE Import: offline
-25     1	1	5	4	;	%10 CC A2F
-25     1	1	4	3	;	%11 CC NYC
-1      1	1	1	1	;	%12 GT NYC
-1      1	1	1	1	;	%13 GT LI
-25     1	1	3	2	;	%14 HQ Import A2F
];

%% Loose
% MinDown of CC A2F, CC NYC, GT NYC, and GT LI are reduced
% %1      2   3   4   5     
% xgd_table.data = [
% -25	1	1	24	22	;	%1
% -25	1	1	24	22	;	%2
% -25	1	1	24	22	;	%3
% -25	1	1	18	16	;	%4
% -25	1	1	18	16	;	%5
% -25	1	1	14	12	;	%6
% -25	1	1	14	12	;	%7
% -25	1	1	14	12	;	%8
% -100	-1	1	2	1	;	%9
% -25	1	1	5	1	;	%10
% -25	1	1	4	1	;	%11
% -1	1	1	1	0	;	%12
% -1	1	1	1	0	;	%13
% -25	1	1	3	2	;	%14
% ];
