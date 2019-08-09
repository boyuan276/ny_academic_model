function [outDATA] = missing_data_NAN(inDATA)
%missing_data_NAN replaces missing data with a NAN value
%   inDATA     data table that will have missing entries filled with NANs

%Ensure that you are not being passed an empty data table
if isempty(inDATA)
    fprintf(2,'ERROR: you have passed an empty data table to missing_data_NAN.m\n')
    return
end

%Extract the column names
cols = inDATA.Properties.VariableNames;
%Extract the start and end date
st_date = inDATA{1,'Date'};
st_date = datetime(st_date);
st_date.Format = 'MMM-dd-yyyy HH:mm:ss';
end_date = inDATA{end,'Date'};
end_date = datetime(end_date);
st_date.Format = 'MMM-dd-yyyy HH:mm:ss';
%Extract the time interval
dt = inDATA{2,'Date'} - inDATA{1,'Date'};
n = hours(dt);
%Ensure the incoming Type, Status, and Fuel are categorical arrays 
inDATA.Type = categorical(inDATA.Type);
inDATA.Status = categorical(inDATA.Status);
inDATA.Fuel = categorical(inDATA.Fuel);

%Generate all combination of days
alldays = (st_date:hours(n):end_date)';
timeidx = ndgrid(1:numel(alldays));  
%Create table prefilled with NaN 
outDATA = table(cell(numel(timeidx), 1), NaN(numel(timeidx), 1), ...
    NaN(numel(timeidx), 1), alldays(timeidx(:)), ...
    NaN(numel(timeidx), 1), NaN(numel(timeidx), 1), ...
    NaN(numel(timeidx), 1), NaN(numel(timeidx), 1), ...
    'VariableNames', cols);
%Convert Type, Status, and Fuel to categorical arrays
outDATA.Type = categorical(outDATA.Type);
outDATA.Status = categorical(outDATA.Status);
outDATA.Fuel = categorical(outDATA.Fuel);

%Find which dates are present in original data
[isinorig, rowidx] = ismember(outDATA{:, 'Date'}, inDATA{:, 'Date'}, 'rows');
%Overwrite the NANs with known data values
outDATA{isinorig, 'FacilityName'} = ...
    inDATA{rowidx(isinorig), 'FacilityName'};
outDATA{isinorig, 'FacilityID'} = ...
    inDATA{rowidx(isinorig), 'FacilityID'}; 
outDATA{isinorig, 'UnitID'} = ...
    inDATA{rowidx(isinorig), 'UnitID'}; 
outDATA{isinorig, 'Load'} = ...
    inDATA{rowidx(isinorig), 'Load'}; 
outDATA{isinorig, 'Status'} = ...
    inDATA{rowidx(isinorig), 'Status'}; 
outDATA{isinorig, 'Type'} = ...
    inDATA{rowidx(isinorig), 'Type'}; 
outDATA{isinorig, 'Fuel'} = ...
    inDATA{rowidx(isinorig), 'Fuel'}; 

end

