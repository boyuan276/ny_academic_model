function [outDATA] = missing_data_NAN(inDATA)
%missing_data_NAN replaces missing data with a NAN value
%   inDATA     data vector that will have missing entries filled with NANs
%   n          time interval (in hours)

%Extract the column names
cols = inDATA.Properties.VariableNames;
%Extract the start and end date
st_date = inDATA{1,'Date'};
st_date = datetime(st_date);
st_date.Format = 'MMM-dd-yyyy HH:mm:ss';
end_date = inDATA{end,'Date'};
end_date = datetime(end_date);
st_date.Format = 'MMM-dd-yyyy HH:mm:ss';
%Extract the interval
dt = inDATA{2,'Date'} - inDATA{1,'Date'};
n = hours(dt);

%Generate all combination of days
alldays = (st_date:hours(n):end_date)';
timeidx = ndgrid(1:numel(alldays));  
%Create table prefilled with NaN 
outDATA = table(NaN(numel(timeidx), 1), NaN(numel(timeidx), 1), ...
    alldays(timeidx(:)), NaN(numel(timeidx), 1),...
    NaN(numel(timeidx), 1), NaN(numel(timeidx), 1),...
    NaN(numel(timeidx), 1),'VariableNames', cols); 
%Loop through the columns
%!If the table columns contain cells, these NaNs also must be within cells!
for col = cols
    if iscell(inDATA{1,col})
        outDATA{:,col} = num2cell(outDATA{:,col});
    end
end
%Find which dates are present in original data
[isinorig, rowidx] = ismember(outDATA{:, 'Date'}, inDATA{:, 'Date'}, 'rows');
%Overwrite the NANs with known data values
outDATA{isinorig, 'FacilityID'} = ...
    inDATA{rowidx(isinorig), 'FacilityID'}; 
outDATA{isinorig, 'UnitID'} = ...
    inDATA{rowidx(isinorig), 'UnitID'}; 
outDATA{isinorig, 'Load'} = ...
    inDATA{rowidx(isinorig), 'Load'}; 
% I need to make outDATA{isinorig, 'Status'} a cells containing NaNs
outDATA{isinorig, 'Status'} = ...
    inDATA{rowidx(isinorig), 'Status'}; 
outDATA{isinorig, 'Type'} = ...
    inDATA{rowidx(isinorig), 'Type'}; 
outDATA{isinorig, 'Fuel'} = ...
    inDATA{rowidx(isinorig), 'Fuel'}; 

end

