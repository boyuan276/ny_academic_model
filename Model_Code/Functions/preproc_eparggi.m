%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script preprocesses EPA AMPD. Specifically, this data was contained
% within the RGGI hourly unit-level emissions data database. Only data for
% 2018 was downloaded initially, but in principle, this script should work
% for any year of data as long as long as there is a file corresponding to
% each entry in the 'months' cell array.
%
% This script writes a .mat file called 'CEMSbyfacility<year>.mat'.
%
% Created by Jeff Sward 07/11/2019.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear
clc

% Set the data year for output file for input/output file naming purposes.
yr = 2018;
yrstr = num2str(yr);
yrstr = yrstr(end-1:end);
optfile = sprintf('cemsload_Feb%s.csv',yrstr);
outfile = sprintf('CEMSbyfacility%s.mat',yrstr);

% For some reason, not all of these CSVs result in the same opts from the
% following function. The following one works correctly
opts = detectImportOptions('cemsload_Feb18.csv');
months = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',...
    'Jul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'};

%Initialize the data structure
CEMS.data = cell(1);
CEMS.facilityNAME = [];
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
%     T_tmp(:,'FacilityName') = [];
    T_tmp.Type = categorical(T_tmp.Type);
    T_tmp.Status = categorical(T_tmp.Status);
    T_tmp.Fuel = categorical(T_tmp.Fuel);
    
    %Separate units based upon facility name
    all_facility = unique(T_tmp{:,'FacilityName'});
    for ii = 1:length(all_facility)
        %Determine which units are attached to this facility
        isfac = strcmp(T_tmp{:,'FacilityName'}, all_facility(ii));
        Fac_T_tmp = T_tmp(isfac,:);
        all_units = unique(Fac_T_tmp{:,'UnitID'});
        %If there are NaNs in the Unit IDs, aggrigate them into Unit 999
        if sum(isnan(all_units)) ~= 0
            [Fac_T_tmp, all_units] = agg_NAN_units(Fac_T_tmp, all_units);
        end
        uidx = 1;
        for jj = 1:length(all_units)
            isunit = ismember(Fac_T_tmp{:,'UnitID'}, all_units(jj), 'rows');
            Unit_T_tmp = Fac_T_tmp(isunit,:);
            %Check for missing data data values for each unit
            Unit_T_tmp = missing_data_NAN(Unit_T_tmp);
            %Aggrigate units after checking
            if uidx == 1
                Fac_T_agg = Unit_T_tmp;
            else
                Fac_T_agg{:,'Load'} = nansum([Fac_T_agg{:,'Load'}, Unit_T_tmp{:,'Load'}], 2);
                if isempty(Fac_T_agg{isundefined(Fac_T_agg{:,'Status'}),'Status'}) == 0
                    Fac_T_agg{isundefined(Fac_T_agg{:,'Status'}),'Status'} = ...
                        Unit_T_tmp{isundefined(Fac_T_agg{:,'Status'}),'Status'};
                end
                if isempty(Fac_T_agg{isundefined(Fac_T_agg{:,'Type'}),'Type'}) == 0
                    Fac_T_agg{isundefined(Fac_T_agg{:,'Type'}),'Type'} = ...
                        Unit_T_tmp{isundefined(Fac_T_agg{:,'Type'}),'Type'};
                end
                if isempty(Fac_T_agg{isundefined(Fac_T_agg{:,'Fuel'}),'Fuel'}) == 0
                    Fac_T_agg{isundefined(Fac_T_agg{:,'Fuel'}),'Fuel'} = ...
                        Unit_T_tmp{isundefined(Fac_T_agg{:,'Fuel'}),'Fuel'};
                end
            end
            uidx = uidx + 1;
        end
        %Determine if the facility already exists in the CEMS structure
        incems = strcmp(all_facility(ii), CEMS.facilityNAME);
        incems = sum(incems) > 0;
        %Put table for each facility in the CEMS.data cell array
        if incems
            rowidx = find(incems);
            CEMS.data{rowidx} = [CEMS.data{rowidx}; Fac_T_agg];
        else
            if isempty(CEMS.data{end})
                CEMS.data{end} = Fac_T_agg;
            else
                CEMS.data{end+1} = Fac_T_agg;
            end
            CEMS.facilityNAME = [CEMS.facilityNAME; all_facility(ii)];
        end
        
    end
    
end

save(outfile, 'CEMS')
