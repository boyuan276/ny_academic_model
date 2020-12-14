function NYCANotMatched = importNotMatched(workbookFile, sheetName, dataLines)
%IMPORTFILE Import 2019 NYCA generator data not matched in RGGI database
%  NYCANOTMATCHED = IMPORTNOTMATCHED(FILE) reads NYCA generator data

%% Input handling

% If no sheet is specified, read first sheet
if nargin == 1 || isempty(sheetName)
    sheetName = 1;
end

% If row start and end points are not specified, define defaults
if nargin <= 2
    dataLines = [2, 156];
end

%% Setup the Import Options and import the data
opts = spreadsheetImportOptions("NumVariables", 19);

% Specify sheet and range
opts.Sheet = sheetName;
opts.DataRange = "A" + dataLines(1, 1) + ":S" + dataLines(1, 2);

% Specify column names and types
opts.VariableNames = ["Var1", "Var2", "NYISOName", "Zone", "PTID", "Town", "Var7", "Var8", "Var9", "NamePlateRatingMW", "CRISSummerMW", "CRISWinterMW", "CapabilitySummerMW", "CapabilityWinterMW", "DualFuel", "UnitType", "FuelType", "FuelTypesecondary", "NetEnergyGWh"];
opts.SelectedVariableNames = ["NYISOName", "Zone", "PTID", "NamePlateRatingMW", "CRISSummerMW", "CRISWinterMW", "CapabilitySummerMW", "CapabilityWinterMW", "UnitType", "FuelType", "NetEnergyGWh"];
opts.VariableTypes = ["char", "char", "categorical", "categorical", "categorical", "categorical", "char", "char", "char", "double", "double", "double", "double", "double", "double", "categorical", "categorical", "categorical", "double"];

% Specify variable properties
opts = setvaropts(opts, ["Var1", "Var2", "Var7", "Var8", "Var9"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Var1", "Var2", "NYISOName", "Zone", "PTID", "Town", "Var7", "Var8", "Var9", "UnitType", "FuelType", "FuelTypesecondary"], "EmptyFieldRule", "auto");

% Import the data
NYCANotMatched = readtable(workbookFile, opts, "UseExcel", false);

for idx = 2:size(dataLines, 1)
    opts.DataRange = "A" + dataLines(idx, 1) + ":S" + dataLines(idx, 2);
    tb = readtable(workbookFile, opts, "UseExcel", false);
    NYCANotMatched = [NYCANotMatched; tb]; %#ok<AGROW>
end

% Exclude generators fueling on wood and refuse (renewable energy)
NYCANotMatched = NYCANotMatched(NYCANotMatched.FuelType ~= "Wood" & NYCANotMatched.FuelType ~= "Refuse", :);
% Exclude generators with zero gross load in 2019
NYCANotMatched = NYCANotMatched(NYCANotMatched.NetEnergyGWh > 0, :);
end