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
%1      2   3   4   5     
xgd_table.data = [
-25	1	1	24	22	;	%1
-25	1	1	24	22	;	%2
-25	1	1	24	22	;	%3
-25	1	1	18	16	;	%4
-25	1	1	18	16	;	%5
-25	1	1	14	12	;	%6
-25	1	1	14	12	;	%7
-25	1	1	14	12	;	%8
-100	-1	1	2	1	;	%9
-25	1	1	5	4	;	%10
-25	1	1	4	3	;	%11
-1	1	1	1	1	;	%12
-1	1	1	1	1	;	%13
-25	1	1	3	2	;	%14
];

%% Loose
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
