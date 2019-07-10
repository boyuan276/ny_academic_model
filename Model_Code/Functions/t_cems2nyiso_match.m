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
    T_tmp.Type = categorical(T_tmp.Type);
    T_tmp.Status = categorical(T_tmp.Status);
    T_tmp.Fuel = categorical(T_tmp.Fuel);
    
    %Aggrigate units attached to each facility
    all_facility = unique(T_tmp{:,'FacilityID'});
    for ii = 1:length(all_facility)
        %Determine which units are attached to this facility
        [isfac, rowidx] = ismember(T_tmp{:,'FacilityID'}, all_facility(ii), 'rows');
        Fac_T_tmp = T_tmp(isfac,:);
        all_units = unique(Fac_T_tmp{:,'UnitID'});
        %If there are NaNs in the Unit IDs, aggrigate them into Unit 999
        if sum(isnan(all_units)) ~= 0
            [Fac_T_tmp, all_units] = agg_NAN_units(Fac_T_tmp, all_units);
        end
        uidx = 1;
        for jj = 1:length(all_units)
            [isunit, rowidx] = ismember(Fac_T_tmp{:,'UnitID'}, all_units(jj), 'rows');
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
        [incems, rowidx] = ismember(all_facility(ii), CEMS.facilityID);
        %Put table for each facility in the CEMS.data cell array
        if incems
            CEMS.data{rowidx} = [CEMS.data{rowidx}; Fac_T_agg];
        else
            if isempty(CEMS.data{end})
                CEMS.data{end} = Fac_T_agg;
            else
                CEMS.data{end+1} = Fac_T_agg;
            end
            CEMS.facilityID = [CEMS.facilityID; all_facility(ii)];
        end
        
    end
    
    
end

