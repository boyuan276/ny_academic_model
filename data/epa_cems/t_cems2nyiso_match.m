clear
clc

%Import the CEMS data

% For some reason, not all of these CSVs result in the same opts from the
% following function. The following one works correctly
opts = detectImportOptions('cemsload_Feb18.csv');
months = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',...
    'Jul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'};
idx = 1;
for mo = months
    file = sprintf('cemsload_%s18.csv', cell2mat(mo));
    if idx ~= 1
        T_new = readtable(file, opts);
        CEMS = [CEMS; T_new];
    else
        CEMS = readtable(file, opts);
    end
    idx = idx + 1;
end

%Format CEMS data table
CEMS.Properties.VariableNames{'Var1'} = 'State';
CEMS.Properties.VariableNames{'Var2'} = 'FacilityName';
CEMS.Properties.VariableNames{'Var3'} = 'FacilityID';
CEMS.Properties.VariableNames{'Var4'} = 'UnitID';
CEMS.Properties.VariableNames{'Var5'} = 'Year';
CEMS.Properties.VariableNames{'Var6'} = 'Date';
CEMS.Properties.VariableNames{'Var7'} = 'Hour';
CEMS.Properties.VariableNames{'Var8'} = 'Load';
CEMS.Properties.VariableNames{'Var9'} = 'Status';
CEMS.Properties.VariableNames{'Var10'} = 'Type';
CEMS.Properties.VariableNames{'Var11'} = 'Fuel';
CEMS(:,end) = [];
CEMS(:,end) = [];