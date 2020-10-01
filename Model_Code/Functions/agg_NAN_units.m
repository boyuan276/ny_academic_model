function [Fac_T_tmp, all_units] = agg_NAN_units(Fac_T_tmp, all_units)
%agg_NAN_units aggrigates all the units at a given facility that have the
%Unit ID listed at NaN.
%   Fac_T_tmp   is a table array containing data for all the units at a
%               given facility. All units in this table whose Unit ID is
%               listed as NaN are aggrigated into a single unit.
%   all_units   gives all the unique unit IDs. Between input and output,
%               NaNs in this vector are replaced with a singular unit with
%               UnitID = 999.

%Ensure that you are not being passed an empty data table
if isempty(Fac_T_tmp)
    fprintf(2,'ERROR: you have passed an empty data table to agg_NAN_units.m\n')
    return
end

%Extract the column names
cols = Fac_T_tmp.Properties.VariableNames;

%Remove NaNs and add Unit 999
all_units = all_units(~isnan(all_units));
all_units(end+1) = 999;

%Subset table with NaN units
isnanunit = isnan(Fac_T_tmp{:,'UnitID'});
T_nan = Fac_T_tmp(isnanunit,:);

%Loop through all the days and creat a new date table
st_date = min(T_nan{:,'Date'});
end_date = max(T_nan{:,'Date'});
day2 = min(setdiff(T_nan{:,'Date'},min(T_nan{:,'Date'})));
dt = day2 - st_date;
n = hours(dt);
alldays = (st_date:hours(n):end_date)';
timeidx = ndgrid(1:numel(alldays));

%Create table prefilled with NaN 
T_tmp = table(repmat(Fac_T_tmp{1,'FacilityName'}, numel(timeidx), 1), ...
    Fac_T_tmp{1,'FacilityID'}*ones(numel(timeidx), 1), ...
    999*ones(numel(timeidx), 1), ...
    alldays(timeidx(:)), ...
    NaN(numel(timeidx), 1),...
    NaN(numel(timeidx), 1), ...
    NaN(numel(timeidx), 1),...
    NaN(numel(timeidx), 1),'VariableNames', cols);

%Convert Type, Status, and Fuel to categorical arrays
T_tmp.Type = categorical(T_tmp.Type);
T_tmp.Status = categorical(T_tmp.Status);
T_tmp.Fuel = categorical(T_tmp.Fuel);

for ii = 1:length(alldays)
   %Combine load values from all NaN units
   datematch = ismember(T_nan{:,'Date'}, alldays(ii));
   idx = find(datematch, 1, 'first');
   T_tmp{ii,'Load'} = nansum(T_nan{datematch,'Load'});
   T_tmp{ii,'Status'} = T_nan{idx,'Status'};
   T_tmp{ii,'Type'} = T_nan{idx,'Type'};
   T_tmp{ii,'Fuel'} = T_nan{idx,'Fuel'};
end

%Remove NaN units from the facility-level data table
Fac_T_tmp(isnanunit,:) = [];

%Append new data table onto the facility-level data table
Fac_T_tmp = [Fac_T_tmp; T_tmp];

end

