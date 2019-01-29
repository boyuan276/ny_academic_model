function UCprofile = UC_RTC_profile
%ITM profile data for deterministic unit commitment.

%define constants
% [GEN_BUS, PG, QG, QMAX, QMIN, VG, MBASE, GEN_STATUS, PMAX, PMIN, ...
%     MU_PMAX, MU_PMIN, MU_QMAX, MU_QMIN, PC1, PC2, QC1MIN, QC1MAX, ...
%     QC2MIN, QC2MAX, RAMP_AGC, RAMP_10, RAMP_30, RAMP_Q, APF] = idx_gen;

[InitialState,CommitKey,CommitSched, MinUp,MinDown] = idx_gen;
% 
[CT_LABEL, CT_PROB, CT_TABLE, CT_TBUS, CT_TGEN, CT_TBRCH, CT_TAREABUS, ...
    CT_TAREAGEN, CT_TAREABRCH, CT_ROW, CT_COL, CT_CHGTYPE, CT_REP, ...
    CT_REL, CT_ADD, CT_NEWVAL, CT_TLOAD, CT_TAREALOAD, CT_LOAD_ALL_PQ, ...
    CT_LOAD_FIX_PQ, CT_LOAD_DIS_PQ, CT_LOAD_ALL_P, CT_LOAD_FIX_P, ...
    CT_LOAD_DIS_P, CT_TGENCOST, CT_TAREAGENCOST, CT_MODCOST_F, ...
    CT_MODCOST_X] = idx_ct;

UCprofile = struct( ...
    'type', 'xGenData', ...
    'table', 'CommitKey', ...
    'rows', [1:59], ...
    'col', 2, ...
    'chgtype', CT_REP, ... %REPLACE VALUES WITH MW
    'values', [] );

% UCprofile = struct( ...
%     'type', 'xGenData', ...
%     'table', 'CommitKey', ...
%     'rows', [1:11], ...
%     'chgtype', CT_REP, ... %REPLACE VALUES WITH MW
%     'values', [] );

