clear
clc

%Import the CEMS data

% For some reason, not all of these CSVs result in the same opts from the
% following function. The following one works correctly
opts = detectImportOptions('cemsload_Feb18.csv');
months = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',...
    'Jul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'};

%Initialize the data structure
CEMS.data = cell(1);
CEMS.facilityID = [];
idx = 1;
for mo = months
    %Read data from the CSV file
    file = sprintf('cemsload_%s18.csv', cell2mat(mo));
    T_tmp = readtable(file, opts);
    %Format T_tmp data table
    T_tmp.Properties.VariableNames{'Var1'} = 'State';
    T_tmp.Properties.VariableNames{'Var2'} = 'FacilityName';
    T_tmp.Properties.VariableNames{'Var3'} = 'FacilityID';
    T_tmp.Properties.VariableNames{'Var4'} = 'UnitID';
    T_tmp.Properties.VariableNames{'Var5'} = 'Year';
    T_tmp.Properties.VariableNames{'Var6'} = 'Date';
    T_tmp.Properties.VariableNames{'Var7'} = 'Hour';
    T_tmp.Properties.VariableNames{'Var8'} = 'Load';
    T_tmp.Properties.VariableNames{'Var9'} = 'Status';
    T_tmp.Properties.VariableNames{'Var10'} = 'Type';
    T_tmp.Properties.VariableNames{'Var11'} = 'Fuel';
    T_tmp(:,end) = [];
    T_tmp(:,end) = [];
    T_tmp{:,'Date'} = T_tmp{:,'Date'} + hours(T_tmp{:,'Hour'});
    T_tmp(:,'Hour') = [];
    T_tmp(:,'Year') = [];
    T_tmp(:,'State') = [];
    T_tmp(:,'FacilityName') = [];
    
    %Aggrigate units attached to each facility
    all_facility = unique(T_tmp{:,'FacilityID'});
    for fac = all_facility
         
        
    end
    %Check for missing data data values
    
    %Put table for each facility in the CEMS.data cell array
    if idx == 1
        CEMS.data{idx} = T_tmp;
    else
        CEMS.data{idx} = [CEMS.data{idx}; T_tmp];
    end
    idx = idx + 1;
end

