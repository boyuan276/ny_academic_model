function RGGI2NYCA2019 = importRefTable(workbookFile, sheetName, dataLines)
%IMPORTREFTABLE Import RGGI to NYCA reference table

%% Input handling

% If no sheet is specified, read first sheet
if nargin == 1 || isempty(sheetName)
    sheetName = 1;
end

% If row start and end points are not specified, define defaults
if nargin <= 2
    dataLines = [2, 184];
end

%% Setup the Import Options and import the data
opts = spreadsheetImportOptions("NumVariables", 21);

% Specify sheet and range
opts.Sheet = sheetName;
opts.DataRange = "A" + dataLines(1, 1) + ":U" + dataLines(1, 2);

% Specify column names and types
opts.VariableNames = ["NYISOName", "PTID", "Zone", "FacilityName", "FacilityID", "UnitID", "UnitType", "FuelType", "OperatingTime", "GrossLoadMWh", "HeatInputMMBtu", "FacilityLatitude", "FacilityLongitude", "MaxHourlyHIRateMMBtuhr", "NamePlateRatingMW", "NetEnergyGWh", "CRISSummerMW", "CRISWinterMW", "CapabilitySummerMW", "CapabilityWinterMW", "Combined"];
opts.VariableTypes = ["categorical", "categorical", "categorical", "categorical", "categorical", "categorical", "categorical", "categorical", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "categorical"];

% Specify variable properties
opts = setvaropts(opts, ["NYISOName", "PTID", "Zone", "FacilityName", "FacilityID", "UnitID", "UnitType", "FuelType", "Combined"], "EmptyFieldRule", "auto");

% Import the data
RGGI2NYCA2019 = readtable(workbookFile, opts, "UseExcel", false);

for idx = 2:size(dataLines, 1)
    opts.DataRange = "A" + dataLines(idx, 1) + ":U" + dataLines(idx, 2);
    tb = readtable(workbookFile, opts, "UseExcel", false);
    RGGI2NYCA2019 = [RGGI2NYCA2019; tb]; %#ok<AGROW>
end

% Exclude generators fueling on wood and refuse (renewable energy)
RGGI2NYCA2019 = RGGI2NYCA2019(RGGI2NYCA2019.FuelType ~= "Wood" & RGGI2NYCA2019.FuelType ~= "Refuse", :);
% Exclude generators with zero gross load in 2019
RGGI2NYCA2019 = RGGI2NYCA2019(RGGI2NYCA2019.GrossLoadMWh > 0, :);

end