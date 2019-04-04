function [A2F_net_load_RT, GHI_net_load_RT, NYC_net_load_RT, LIs_net_load_RT,...
    A2F_net_load, GHI_net_load, NYC_net_load, LIs_net_load] = ...
    NYISOnetloadPRE_DAM(date, undrbidfac, useinstant)
%NYISOnetloadPRE_DAM preprocess NYISO data taken from OASIS and outputs
%hourly load data by region.
%   UNDERBIDFAC may be specified to account for the underbidding of load in
%   the day ahead market. This value defaults to 1 if not provided.
%   USEINSTANT may be set to one if you would like to use a value from the
%   beginning of the hour rather than average the values over the hour.
%   This option is turned off by default.
%   Note that the values in the NYISO data are not organized by Zone A,
%   Zone B, ... Rather, they are orgainized as follows:
%   Row  1:CAPITL -- Zone F
%   Row  2:CENTRL -- Zone C
%   Row  3:DUNWOD -- Zone I
%   Row  4:GENESE -- Zone B
%   Row  5:HUD VL -- Zone G
%   Row  6:LONGIL -- Zone K
%   Row  7:MHK VL -- Zone E
%   Row  8:MILLWD -- Zone H
%   Row  9:NYC    -- Zone J
%   Row 10:NORTH  -- Zone D
%   Row 11:WEST   -- Zone A

%Deal with input arguments
if nargin < 3
    if exist('date','var') ~= 1
        fprintf(2,'Error: you must provide an input date.')
        return
    end
    if exist('undrbidfac','var') ~= 1
        undrbidfac = 1;
    end
    if exist('useinstant','var') ~= 1
        useinstant = 0;
    end
end       

%Define the filename
m_file_loc = '../NYISO Data/ActualLoad5min/';


if exist(strcat(m_file_loc,date,'pal.mat'),'file')  < 1
    %Enusre that datestring is in the correct format
    date = datestr(date,'yyyymmdd');
end
    
%Get data file
RT_actual_load = load([m_file_loc,date,'pal.mat']);

%Parse through vector which has 288 entries per hour corresponding to 5
%minute data in each zone. 
periods = 0:288-1;
A2F_net_load_RT = (...
    RT_actual_load.M(1 +(periods)*11,2)+...                 %Zone F
    RT_actual_load.M(2 +(periods)*11,2)+...                 %Zone C
    RT_actual_load.M(4 +(periods)*11,2)+...                 %Zone B
    RT_actual_load.M(7 +(periods)*11,2)+...                 %Zone E
    RT_actual_load.M(10+(periods)*11,2)+...                 %Zone D
    RT_actual_load.M(11+(periods)*11,2));                   %Zone A
GHI_net_load_RT = (...
    RT_actual_load.M(3 +(periods)*11,2)+...                 %Zone I
    RT_actual_load.M(5 +(periods)*11,2)+...                 %Zone G
    RT_actual_load.M(8 +(periods)*11,2));                   %Zone H
NYC_net_load_RT = (RT_actual_load.M(9 +(periods)*11,2));    %Zone J
LIs_net_load_RT = (RT_actual_load.M(6 +(periods)*11,2));    %Zone K

% Modify for DAM (24 periods)
% Take average of load values over each hour
A2F_net_load = zeros(1,24);
GHI_net_load = zeros(1,24);
NYC_net_load = zeros(1,24);
LIs_net_load = zeros(1,24);
for int_DAM = 1:24
    if useinstant == 1
        A2F_net_load(int_DAM) = A2F_net_load_RT(int_DAM*12-11);
        GHI_net_load(int_DAM) = GHI_net_load_RT(int_DAM*12-11);
        NYC_net_load(int_DAM) = A2F_net_load_RT(int_DAM*12-11);
        LIs_net_load(int_DAM) = A2F_net_load_RT(int_DAM*12-11);
    else
        A2F_net_load(int_DAM) = mean(A2F_net_load_RT(int_DAM*12-11:int_DAM*12));
        GHI_net_load(int_DAM) = mean(GHI_net_load_RT(int_DAM*12-11:int_DAM*12));
        NYC_net_load(int_DAM) = mean(NYC_net_load_RT(int_DAM*12-11:int_DAM*12));
        LIs_net_load(int_DAM) = mean(LIs_net_load_RT(int_DAM*12-11:int_DAM*12));
    end
end

%Reduce by 100*(1 - undrbidfac)% to account for underbidding of load
A2F_net_load = A2F_net_load.*undrbidfac;
GHI_net_load = GHI_net_load.*undrbidfac;
NYC_net_load = NYC_net_load.*undrbidfac;
LIs_net_load = LIs_net_load.*undrbidfac;

end

