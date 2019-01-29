function mpc1 = load2disp(mpc0, fname, idx, voll, iter)
%LOAD2DISP Converts fixed loads to dispatchable.
%   MPC = LOAD2DISP(MPC0);
%   MPC = LOAD2DISP(MPC0, FNAME);
%   MPC = LOAD2DISP(MPC0, FNAME, IDX);
%   MPC = LOAD2DISP(MPC0, FNAME, IDX, VOLL);
%
%   Takes a MATPOWER case file or struct and converts fixed loads to
%   dispatchable loads and returns the resulting case struct. Inputs
%   are as follows:
%
%   MPC0 - File name or struct with initial MATPOWER case.
%
%   FNAME (optional) - Name to use to save resulting MATPOWER case. If empty,
%       the case will not be saved to a file.
%
%   IDX (optional) - Vector of bus indices of loads to be converted. If empty
%       or not supplied, it will convert all loads with positive real
%       power demand.
%
%   VOLL (optional) - Scalar or vector specifying the value of lost
%       load to use as the value for the dispatchable loads. If it is
%       a scalar it is used for all loads, if a vector, the dimension
%       must match that of IDX. Default is $5000 per MWh.

%   MATPOWER
%   Copyright (c) 2010-2016, Power Systems Engineering Research Center (PSERC)
%   by Alberto Lamadrid, PSERC Cornell
%   modified by Ray Zimmerman, PSERC Cornell
%
%   This file is part of MATPOWER.
%   Covered by the 3-clause BSD License (see LICENSE file for details).
%   See http://www.pserc.cornell.edu/matpower/ for more info.

%% define constants
[BUS_I, BUS_TYPE, PD, QD, GS, BS, BUS_AREA, VM, ...
    VA, BASE_KV, ZONE, VMAX, VMIN] = idx_bus;

[GEN_BUS, PG, QG, QMAX, QMIN, VG, MBASE, GEN_STATUS, PMAX, PMIN, ...
    PC1, PC2, QC1MIN, QC1MAX, ...
    QC2MIN, QC2MAX, RAMP_AGC, RAMP_10, RAMP_30, RAMP_Q, APF] = idx_gen;

[MODEL, STARTUP, SHUTDOWN, NCOST, COST1, COST2, COST3] = idx_cost;

mpc = loadcase(mpc0);

%% which loads will be converted?
% if nargin < 3 || isempty(idx)
%     idx = find(mpc.bus(:, PD) > 0); %% by default, all with PD > 0
% end
% You must specify the bus which will be converted to dispatchable load

%% set some defaults
voll0   = 5000;             %% default value of lost load
mBase   = 100;              %% generator MVA base
nld     = length(idx);
v1      = ones(nld, 1);     %% vector of ones
v0      = zeros(nld, 1);    %% vector of zeros

%% gen table
gen = [
    mpc.bus(idx, BUS_I), ...        %% GEN_BUS
    -mpc.bus(idx, PD)*iter/100, ...  %% PG
    -mpc.bus(idx, QD), ...          %% QG
    max(0, -mpc.bus(idx, QD)), ...  %% QMAX
    min(0, -mpc.bus(idx, QD)), ...  %% QMIN
    mpc.bus(idx, VM), ...           %% VG
    mBase * v1, ...                 %% MBASE
    v1, ...                         %% GEN_STATUS
    max(0, -mpc.bus(idx, PD)), ...  %% PMAX %smb:  this will always be zero
    min(0, -mpc.bus(idx, PD)*iter/100), ...  %% PMIN
    zeros(nld, 6), ...              %% capability curve
    Inf(nld, 4), ...                %% ramp rates
    zeros(nld, 1), ...              %% participation factor
];
mpc.gen =  [mpc.gen; gen];  %% add dispatchable loads

%% bus table
mpc.bus(idx, QD) = 0; %% zero out fixed loads... smb actually don't zero out. 
mpc.bus(idx, PD) = mpc.bus(idx, PD)*(1-iter/100); %% zero out fixed loads... smb actually don't zero out. 

%% gencost table
nc = size(mpc.gencost, 2);
if nargin < 4
    voll = voll0 * v1;
elseif length(voll) == 1
    voll = voll * v1;
end
gencost = [             %% use a linear, polynomial cost format
    2, ...      %% MODEL
    0,0, ...      %% STARTUP, SHUTDOWN
    3, ...             %% NCOST
    voll, ...               %% COST, linear term
    0,0 ...    %% constant term and zero-padding
];
mpc.gencost = [mpc.gencost; gencost];

%% save case, if filename is given
if nargin > 1 && ~isempty(fname)
    savecase(fname, mpc, '2');
end
if nargout > 0
    mpc1 = mpc;
end
