function [ONOFF,mdo,ms,most_busload_RTC,most_windy_gen_RTC,most_hydro_gen_RTC,most_other_gen_RTC,NukeGen, SteamGen, ...
            CCGen, GTGen, LOHIGen,RenGen_windy, RenGen_hydro, RenGen_other,BTM4Graph,Previous_RTC_InitState, MaxGenforRTD_SUP,MaxGenforRTD_SHUT,...
            EVSEloadRTD,RTCtotalEVSEload,RTMifFlows,DAMstartupModeLastRTC] = ...
    RunRTC(RTD_UC_Status,RT_int,most_busload,most_bus_rengen_windy,most_bus_rengen_hydro,most_bus_rengen_other,...
            therm_gen_count,RTD_UC_Status_Nm2,DAM_UC_Results,gen_startuptime_hrs,hourbin,Previous_RTC_InitState,...
            RTD_Gen_Storage,MinRunTime,MinDownTime,...
            most_period_count_RTC,NYCA_TrueLoad,NYCA_CASE_net_load,demand,datestring,Case_Name_String,...
            NukeGen, SteamGen, CCGen, GTGen, LOHIGen,RenGen_windy, RenGen_hydro, RenGen_other,BTM4Graph,...
            windyCurtRTC,hydroCurtRTC,otherCurtRTC,droppit,printRTC,minrunshorter,mustRun,...
            windyCurtFactorRTC, hydroCurtFactorRTC,otherCurtFactorRTC,mdo_old,gen_startuptime,...
            IncreasedRTCramp_Steam,RTCrampFactor_Steam, killNuke,IncreasedRTCramp_CC,RTCrampFactor_CC,RTC_hrs,...
            REC_Cost,REC_hydro,...
            map_Array, lims_Array, IFlims,RTMifFlows,...
            EVSE,BatCount,NYCA_Load_buses,A2F_Load_buses,GHI_Load_buses,NYC_Load_buses,LIs_Load_buses,...
            EVSE_Region_Ind_MW,RTCtotalEVSEload,DAMEVSEload,EVSEloadRTD,RTC_periods,DAMstarts,DAMshutdowns,DAMstartupModeLastRTC)

        
    %% Debug Pause Button 
        if RT_int == 16 %make sure its going to hit (divisible by... 3?)
            stop_please = 1;
        end
    %% Which Hour does this RTC run start in? 
        %Define this RTC run's first and last intervals
            RTC_int_start = RT_int;
            RTC_int_end = RT_int + most_period_count_RTC -1;
        %Which Hours does this RTC run span? 
            for hour =1:24
                if and(RTC_int_start>=hourbin(hour,2),RTC_int_start<=hourbin(hour,3))
                    hour_1 = hourbin(hour);
                    hour_2 = hourbin(hour+1);
                    hour_3 = hourbin(hour+2);
                    hour_4 = hourbin(hour+3);
                break
                end
            end
        %Number of 5-minute intervals till top of the next hour
            IntsTillHour = hourbin(hour_2,2) - RTC_int_start;
    %% Define Deterministic Load Profile
        most_busload_RTC = most_busload(RTC_int_start:RTC_int_end,:);
    %% Define Deterministic Renewable Generation Profile
        most_windy_gen_RTC = most_bus_rengen_windy(RTC_int_start:RTC_int_end,:);
        most_hydro_gen_RTC = most_bus_rengen_hydro(RTC_int_start:RTC_int_end,:);
        most_other_gen_RTC = most_bus_rengen_other(RTC_int_start:RTC_int_end,:);
    %% Thermal Generation
        %% Was a unit started or shutdown in the previous RTC run? 
            %Initialize
                ONOFF = zeros(therm_gen_count,1);
            %Get UC results from final binding period of last RTC run
                Previous_RTC_Status = RTD_UC_Status(:,3);
            %In the Previous RTC run, was a unit started or shutdown? 
                for gen = 1:therm_gen_count
                   if  RTD_UC_Status_Nm2(gen) - Previous_RTC_Status(gen) >0 %unit shutdown
                       ONOFF(gen) = -1; %If so, then = -1
                   else
                       if RTD_UC_Status_Nm2(gen) - Previous_RTC_Status(gen) <0 %unit started
                           ONOFF(gen) = 1; %if shutdown then = 1
                       end
                   end
                end
        %% CommitKey - Calculate initial vector (array comes later)
            %Initialize
                most_CommitKey_RTC = ones(therm_gen_count,1);
            %Identify any units that are forced on or off
                for genUC = 1:therm_gen_count
                    %Is there any DAM committment in the RTC horizon? 
                        DAMvalue = DAM_UC_Results(genUC,hour_1) + DAM_UC_Results(genUC,hour_2)+ DAM_UC_Results(genUC,hour_3)+ DAM_UC_Results(genUC,hour_4);
                    %Force OFF units with (1) a Long StartUp Period and (2) no DAM committment
                        if Previous_RTC_Status(genUC) == 0
                            if and(DAMvalue ==0, gen_startuptime_hrs(genUC) > 0.5)
                                most_CommitKey_RTC(genUC) = -1;
                            end
                        end
                end
            %Prevent unauthorized operation of LoHi Unit
                 most_CommitKey_RTC(14) = -1;
            %Force ON units with DAM commitment at start of RTC run(but not GT's w/ short SUP time, ie. units beyond 11)
                for genUC = 1:11
                    if DAM_UC_Results(genUC,hour_1) == 1
                        most_CommitKey_RTC(genUC) = 2;
                    end
                    if DAM_UC_Results(genUC,hour_1) == 0
                        most_CommitKey_RTC(genUC) = -1;
                    end
                end
        %% Calculate number of intervals till any DAM scheduled STARTS and SHUTDOWNS
            %Initialize
                IntsTillDAMstart = 1000.*ones(therm_gen_count,1);
                IntsTillDAMshutdown = 1000.*ones(therm_gen_count,1);
            %Find intervals till DAM Start: 
                for gen = 1:therm_gen_count
                    if DAMstarts(gen) ~= 0
                        IntsTillDAMstart(gen) = DAMstarts(gen) - RTC_int_start + 1; %The # of ints unit will be offline
                    end
                end
            %Find intervals till DAM Shutdown: 
                for gen = 1:therm_gen_count
                    if DAMshutdowns(gen) ~= 0
                        IntsTillDAMshutdown(gen) = DAMshutdowns(gen) - RTC_int_start + 1; %The # of ints unit will be online
                    end
                end
        %% Find Periods till previous RTC Committment (if any)
            IntsTillRTCcommit = zeros(1,therm_gen_count);
            for gen = 1:therm_gen_count
                %If the unit was offline in the first binding period of the last RTC run
                if mdo_old.UC.CommitSched(gen,1) == 0
                    try
                        IntsTillRTCcommit(gen) = find(mdo_old.UC.CommitSched(gen,:),1) -6; %+3 for advancing from last RTC, +3 for this next RTC
                    catch
                        IntsTillRTCcommit(gen) = 289;
                    end
                end
            end
        %% Initial State - Number of periods online or offline
            %% Traditional (used for Min Down Time & Min Run Time)
                %Initialize
                    InitialState_RTC_Trad = zeros(14,1);
                %Calc number of period online or offline
                    for gen = 1:therm_gen_count
                        if ONOFF(gen) == 0
                            InitialState_RTC_Trad(gen) = sign(Previous_RTC_InitState(gen))*(abs(Previous_RTC_InitState(gen))+3);
                        else
                            InitialState_RTC_Trad(gen) = ONOFF(gen)*3;
                        end
                    end
                %Update Previous Initial State & pass on to next RTC Run
                    Previous_RTC_InitState(1:therm_gen_count) = InitialState_RTC_Trad(1:therm_gen_count);
            %% New (used for SUP Notification Time)
                %Initialize
                    InitialState_RTC_New = zeros(14,1);
                %Calculate Initial State to use in RTC
                    for gen = 1:therm_gen_count
                        %allow unit to start at earlier of SUP notification and previous RTC commitment (already advanced 3 ints)
                            InitialState_RTC_New(gen) = -(MinDownTime(gen) - min(gen_startuptime(gen),IntsTillRTCcommit(gen)));
                        %if the result happens to be positive (bad) set to -1
                            if InitialState_RTC_New(gen) > 0 
                                InitialState_RTC_New(gen) = -1;
                            end
                    end
            %% Compare Traditional and New: Pick most restrictive of the two. 
                %Initialize
                    InitialState_RTC = zeros(14,1);
                %find most restrictive InitialState
                    for gen = 1:therm_gen_count
                        %If unit is online, use the traditional one. 
                            if InitialState_RTC_Trad(gen) > 0
                                InitialState_RTC(gen) = InitialState_RTC_Trad(gen);
                            else
                        %If unit is offline, allow to start at later of Trad (MDT) and New (SUP, prev RTC)
                                InitialState_RTC(gen) = max(InitialState_RTC_Trad(gen),InitialState_RTC_New(gen));
                            end
                    end
            %% DAM Startups Shall Be Honored
                %If a DAM startup is in the RTC window, InitialState must not prevent it from being honored. 
                    for gen = 1:11
                        if and(DAMstarts(gen)>=RTC_int_start, DAMstarts(gen)<=RTC_int_end)
                            InitialState_RTC(gen) = min(-1,-(MinDownTime(gen) - IntsTillDAMstart(gen)+1));
                        end
                    end
            %% DAM Shutdowns Shall Be Honored
                %If a DAM shutdown is in the RTC window, InitialState must not prevent it from being honored. 
                    for gen = 1:11
                        if and(DAMshutdowns(gen)>=RTC_int_start, DAMshutdowns(gen)<=RTC_int_end)
                            InitialState_RTC(gen) =  (MinRunTime(gen) - IntsTillDAMshutdown(gen));
                        end
                    end
    %% Populate Profiles & MOST Options
        %Add Network Model: Bus, Gen, Branch, Gen_Cost
            define_constants
            casefile = 'case_nyiso16';
            mpc = loadcase(casefile);
            xgd = loadxgendata('xgd_RTC' , mpc);
        %Populate Min Run/Down Time
            xgd.MinUp = MinRunTime;
            xgd.MinDown = MinDownTime;
        %Populate CommitKey (-1, 0/1, 2)
            xgd.CommitKey = most_CommitKey_RTC;
        %Populate InitialState (periods on/off line)
            xgd.InitialState = InitialState_RTC;
        %% Unused Simulation Features
            %Increase RAMP
                if IncreasedRTCramp_Steam == 1
                    for col = 17:19
                        mpc.gen(4:8,col) = mpc.gen(4:8,col).*RTCrampFactor_Steam;
                    end
                end 
                if IncreasedRTCramp_CC == 1
                    for col = 17:19
                        mpc.gen(10:11,col) = mpc.gen(10:11,col).*RTCrampFactor_CC;
                    end
                end 
            %Drop the mingen
                if droppit== 1
                    mpc.gen(1:therm_gen_count,10) = mpc.gen(:,10)./10;
                end
            %Reduce the min down time
                if minrunshorter == 1
                    for gen = 1:14
                        xgd.MinDown(gen) = floor(xgd.MinDown(gen)/10);
                    end
                end
        %% Add EVSE Load
            if EVSE == 1
                %% Initialize
%                     clear storage %guessing we'll have to comment out this line
                        %Tables
                            storage.gen             = zeros(BatCount,21);
                            storage.sd_table.data   = zeros(BatCount,13);
                            storage.xgd_table.data  = zeros(BatCount,2);
                            storage.gencost         = zeros(BatCount, 7);
                            MinStorageLevelPROFILE = zeros(32,RTC_periods);
                        %StorageData Parameters
                            storage.sd_table.OutEff				= 1;
                            storage.sd_table.InEff				= 1;
                            storage.sd_table.LossFactor			= 0;
                            storage.sd_table.rho				= 0;
                            storage.sd_table.colnames = {
                                'InitialStorage', ...
                                    'InitialStorageLowerBound', ...
                                        'InitialStorageUpperBound', ...
                                            'InitialStorageCost', ...
                                                'TerminalStoragePrice', ...
                                                    'MaxStorageLevel', ...
                                                        'MinStorageLevel', ...
                                                            'OutEff', ...
                                                                'InEff', ...
                                                                    'LossFactor', ...
                                                                        'rho', ...
                                                                            'ExpectedTerminalStorageMin',...
                                                                                'ExpectedTerminalStorageMax',...
                            };

                            storage.xgd_table.colnames = {
                                'CommitKey', ...
                                    'CommitSched', ...
                                    };    
                %% Create Battery Data Containers     
                    for Bat = 1:BatCount
                        %% Which Region are we in?
                            if sum(ismember(NYCA_Load_buses(Bat),A2F_Load_buses)) > 0
                                Region = 1; %Region 1 is A2F
                            else
                                if sum(ismember(NYCA_Load_buses(Bat),GHI_Load_buses)) >0
                                    Region = 2; %Region 2 is GHI
                                else
                                    if sum(ismember(NYCA_Load_buses(Bat),NYC_Load_buses)) >0
                                        Region = 3; %Region 3 is NYC
                                    else
                                        if sum(ismember(NYCA_Load_buses(Bat),LIs_Load_buses)) >0
                                            Region = 4; %Region 4 is Long Island
                                        else
                                            Region = 5;
                                        end
                                    end
                                end
                            end
                        %% Add individual battery parameters
                                               % bus            Qmin    mBase   Pmax    Pc1     Qc1min	Qc2min	ramp_agc	ramp_q
                                               % 	Pg	Qg	Qmax	Vg      status	   Pmin	Pc2     Qc1max	Qc2max	ramp_10     apf
                                               %                                                                        ramp_30	
                           storage.gen(Bat,:) = [NYCA_Load_buses(Bat)...
                                                    0   0   0   0   1   100 1 -0.00001 -EVSE_Region_Ind_MW(Region) ...
                                                                                        0   0   0   0   0   0   0   0   EVSE_Region_Ind_MW(Region)*12   0   0];
                        %% Calculate Total EVSE MWh for RTC2
                            RTCtotalEVSEload(Bat,(RT_int-1)/3+1) = RTCtotalEVSEload(Bat,(RT_int-1)/3) + .25*DAMEVSEload(Bat,hour_3) - sum(EVSEloadRTD(Bat,RT_int-3:RT_int-1))/12;
                        %% Add storage data
                                                            %1 InitialStorage
                                                                %2 InitialStorageLowerBound
                                                                    %3 InitialStorageUpperBound
                                                                        %4 InitialStorageCost
                                                                            %5 TerminalStoragePrice
                                                                                %6 MaxStorageLevel
                                                                                    %7 MinStorageLevel
                                                                                        %8 OutEff
                                                                                            %9 InEff
                                                                                                %10 LossFactor
                                                                                                    %11 rho
                                                                                                        %12 Expected Terminal Storage Min
                                                                                                            %13 Expected Terminal Storage Max
                                                            %1   2   3   4   5  6   7    8   9   10  11  12                13
                           storage.sd_table.data(Bat,:) =   [0   0   0   0   0  -RTCtotalEVSEload(Bat,(RT_int-1)/3+1),...
                                                                                    0    1   1   0   0   -RTCtotalEVSEload(Bat,(RT_int-1)/3+1) -RTCtotalEVSEload(Bat,(RT_int-1)/3+1)];
                        %% Add storage XGD data
                                                            %1 CommitKey
                                                                %2 CommitSched
                                                                    %3 PositiveActiveReservePrice
                                                                        %4 PositiveActiveReserveQuantity
                                                                            %5 NegativeActiveReservePrice
                                                                                %6 NegativeActiveReserveQuantity
                                                                                    %7 PositiveActiveDeltaPrice
                                                                                        %8 NegativeActiveDeltaPrice
                                                                                            %9 PositiveLoadFollowReservePrice
                                                                                                %10 PositiveLoadFollowReserveQuantity
                                                                                                    %11 NegativeLoadFollowReservePrice
                                                                                                        %12 NegativeLoadFollowReserveQuantity
                                                            %1   2   3   4   5   6   7   8   9   10  11  12
                           storage.xgd_table.data(Bat,:) = [2    1  ];% 0   0   0   0   0   0   0   0   0   0];
                        %% Add storage cost data
                                             %2	startup	n	c(n-1)	...	c0
                                             %      shutdown
                            storage.gencost(Bat,:) = [2	0	0	2	0 0 0]; 
                        %% Min Storage Level
                            %Set targets at top of every hour
    %                             MinStorageLevelPROFILE(Bat,  1:11) =  0;
    %                             MinStorageLevelPROFILE(Bat, 12:23) = -EVSEloadDAM(Bat,1);
    %                             MinStorageLevelPROFILE(Bat, 24:29) = -EVSEloadDAM(Bat,1) - EVSEloadDAM(Bat,2);
    %                             MinStorageLevelPROFILE(Bat, 30   ) = -EVSEloadDAM(Bat,1) - EVSEloadDAM(Bat,2) - 0.5*EVSEloadDAM(Bat,3);
                            %Set 1 target at end of 2.5 hours
                                MinStorageLevelPROFILE(Bat, RTC_periods   ) = -RTCtotalEVSEload(Bat,(RT_int-1)/3+1);
                    end
            end
        %% Add MOST Profiles
            %% WIND
                %Add wind Gener ators
                    [iwind, mpc, xgd] = addwind('wind_gen' , mpc, xgd);
                %Add empty max & min profiles
                    profiles = getprofiles('wind_profile_Pmax' , iwind); 
                    profiles = getprofiles('wind_profile_Pmin' , profiles);
                    profiles(1).values(:,1,:) = most_bus_rengen_windy(RTC_int_start:RTC_int_end,:);
                    if windyCurtRTC == 1
                        profiles(2).values(:,1,:) = most_bus_rengen_windy(RTC_int_start:RTC_int_end,:).*windyCurtFactorRTC;
                    else
                        profiles(2).values(:,1,:) = most_bus_rengen_windy(RTC_int_start:RTC_int_end,:);
                    end
            %% HYDRO
                %Add hydro Generators
                    [ihydro, mpc, xgd] = addwind('hydro_gen' , mpc, xgd);
                %Add empty max & min profiles
                    profiles = getprofiles('hydro_profile_Pmax' , profiles); 
                    profiles = getprofiles('hydro_profile_Pmin' , profiles);
                    profiles(3).values(:,1,:) = most_bus_rengen_hydro(RTC_int_start:RTC_int_end,:);
                    if hydroCurtRTC == 1
                        profiles(4).values(:,1,:) = most_bus_rengen_hydro(RTC_int_start:RTC_int_end,:).*hydroCurtFactorRTC;
                    else
                        profiles(4).values(:,1,:) = most_bus_rengen_hydro(RTC_int_start:RTC_int_end,:);
                    end
            %% OTHER
                %Add other Generators
                    [iother, mpc, xgd] = addwind('other_gen' , mpc, xgd);
                %Add empty max & min profiles
                    profiles = getprofiles('other_profile_Pmax' , profiles); 
                    profiles = getprofiles('other_profile_Pmin' , profiles);
                    profiles(5).values(:,1,:) = most_bus_rengen_other(RTC_int_start:RTC_int_end,:);
                    if otherCurtRTC == 1
                        profiles(6).values(:,1,:) = most_bus_rengen_other(RTC_int_start:RTC_int_end,:).*otherCurtFactorRTC;
                    else
                        profiles(6).values(:,1,:) = most_bus_rengen_other(RTC_int_start:RTC_int_end,:);
                    end
            %% LOAD
                    profiles = getprofiles('load_profile' , profiles);
                    profiles(7).values(:,1,:) = most_busload(RTC_int_start:RTC_int_end,:);
            %% Initial Pg
                %Renewables
                    xgd.InitialPg(15:29) = most_bus_rengen_windy(RTC_int_start,:);
                    xgd.InitialPg(30:44) = most_bus_rengen_hydro(RTC_int_start,:);
                    xgd.InitialPg(45:59) = most_bus_rengen_other(RTC_int_start,:);
                %Thermal
                    xgd.InitialPg(1:14) = RTD_Gen_Storage(1:therm_gen_count,RT_int-1);
            %% Max and Min Gen Limits
                %Create Max and Min Gen Profile Spaces
                    profiles = getprofiles('therm_profile_Pmax' , profiles); 
                    profiles = getprofiles('therm_profile_Pmin' , profiles); 
                %Initialize
                    therm_Pmax_RTC_Profile = zeros(most_period_count_RTC,therm_gen_count);
                    therm_Pmin_RTC_Profile = zeros(most_period_count_RTC,therm_gen_count);
                    DAMstartupMode = zeros(14,most_period_count_RTC);
                    DAMstartupModeThisRTC = zeros(14,1);
                    DAMshutdownMode = zeros(14,most_period_count_RTC);
                %Calculate max/min limits for each unit
                    for gen = 1:therm_gen_count
                        %% First period limits
                            %If the unit was offline in the last RTD run
                                if RTD_Gen_Storage(gen,RT_int-1) == 0
                                    %and if the unit is a gas turbine
                                        if or(gen == 12, gen == 13)
                                            %If committed, force GT to hit min gen on first online interval, or as high as it can ramp in 5mins. 
                                                therm_Pmax_RTC_Profile(1,gen) = max(mpc.gen(gen,10),mpc.gen(gen,19)/6);
                                                therm_Pmin_RTC_Profile(1,gen) = min(mpc.gen(gen,10),mpc.gen(gen,19)/6);                                                
                                        end
                            %If the unit was online
                                else
                                    %Limit max/min output to formal limits or ramping ability
                                        therm_Pmax_RTC_Profile(1,gen) = min(RTD_Gen_Storage(gen,RT_int-1) + mpc.gen(gen,19)/6,mpc.gen(gen,9));
                                        therm_Pmin_RTC_Profile(1,gen) = max(RTD_Gen_Storage(gen,RT_int-1) - mpc.gen(gen,19)/6,mpc.gen(gen,10)); 
                                end
                        %% Second period and beyond
                            for int = 2:most_period_count_RTC
                                %then set max/min values = actual max/min values
                                    therm_Pmax_RTC_Profile(int,gen) = mpc.gen(gen,9);
                                    therm_Pmin_RTC_Profile(int,gen) = mpc.gen(gen,10);                                   
                            end
                        %% Special Case: unit offline at start of RTC Window and has DAM committment in RTC window,
                                        %Then create MinGenMW staircase with step size = Ramp Rate
                            %Does not apply to GTs 
                                if or(gen == 12, gen == 13)
                                else
                                    %Unit must (1) be offline in previous RTD interval
                                    if RTD_Gen_Storage(gen,RT_int-1) == 0
                                        %and (2) have a DAM scheduled startup within the RTC window
                                        if and(IntsTillDAMstart(gen) < most_period_count_RTC, IntsTillDAMstart(gen) > 0)
                                            %Initialize: 
                                                RampStepMW = 0; %MW value of the current step
                                                StepCounter = 0;%Start counting number of steps again
                                            %Set Max = Min = 0 until DAM commitment occurs
                                                therm_Pmax_RTC_Profile(1:IntsTillDAMstart(gen),gen) = 0;
                                                therm_Pmin_RTC_Profile(1:IntsTillDAMstart(gen),gen) = 0; 
                                            %set Max = Min = Ramp Rate(MW) - 1MW for first 5min interval when DAM committment occurs
                                                therm_Pmax_RTC_Profile(IntsTillDAMstart(gen),gen) = mpc.gen(gen,19)/6-1;
                                                therm_Pmin_RTC_Profile(IntsTillDAMstart(gen),gen) = mpc.gen(gen,19)/6-1; 
                                            %Count this first step
                                                RampStepMW = mpc.gen(gen,19)/6-1;
                                            %Create Staircase
                                                %While MW value of current step is less than min gen
                                                while RampStepMW < mpc.gen(gen,10)
                                                    %Count number of steps
                                                        StepCounter = StepCounter + 1;
                                                    %Climb up another step
                                                        RampStepMW =  RampStepMW + mpc.gen(gen,19)/6-1;
                                                    %Keep stepping while still in RTC window 
                                                    if StepCounter + IntsTillDAMstart(gen) <= most_period_count_RTC
                                                        %set the max/min value for that interval equal to the Ramp step 
                                                        %if we have stepped above the min gen, set the min gen = actual and max = step. 
                                                            therm_Pmax_RTC_Profile(IntsTillDAMstart(gen)+StepCounter,gen) = RampStepMW;
                                                            therm_Pmin_RTC_Profile(IntsTillDAMstart(gen)+StepCounter,gen) = min(RampStepMW,mpc.gen(gen,10)); 
                                                        %Record the unit as in startup mode
                                                            DAMstartupMode(gen,(IntsTillDAMstart(gen)+StepCounter)) = 1;
                                                            DAMstartupModeThisRTC(gen) = 1;
                                                    else
                                                        break
                                                    end
                                                end
                                            %Set Max and Min limits in any remaining periods
                                                if (IntsTillDAMstart(gen)+StepCounter+1) <= most_period_count_RTC
                                                    therm_Pmax_RTC_Profile(IntsTillDAMstart(gen)+StepCounter+1:most_period_count_RTC,gen) = mpc.gen(gen,9);
                                                    therm_Pmin_RTC_Profile(IntsTillDAMstart(gen)+StepCounter+1:most_period_count_RTC,gen) = mpc.gen(gen,10);
                                                end
                                        end
                                    end
                                end
                        %% Special Case: unit online at start of RTC Window and has DAM shutdown at ANY TIME in rest of day. 
                                        %Then create staircase down (not limited to RTC window)
                            %Does not apply to GTs or units in startup mode
                                if and(sum(DAMstartupMode(gen,1:most_period_count_RTC))>0,or(gen == 12, gen == 13))%does not apply to GTs
                                else
                                    %To apply, unit must be (1) online in previous RTD interval
                                        if RTD_Gen_Storage(gen,RT_int-1) ~= 0 
                                            %and (2) have a DAM scheduled shutdown AT ANY TIME in the rest of the day. 
                                                if and(RT_int < DAMshutdowns(gen), DAMshutdowns(gen) < 500)
                                                    %Then make a Pmax/Pmin value ensuring the DAM shutdown will be feasible in RTC... even if its not for hours. 
                                                    %Initialize Step
                                                        step = 0;
                                                    %First Interval Limits (MOST bug allows initial Pg and actual unit output in first int to be different)
                                                        %Max Gen Limit is smaller of (Previous RTD output + Ramping ability) and (limit needed to make DAM shutdown)
                                                            therm_Pmax_RTC_Profile(1,gen) = min(IntsTillDAMshutdown(gen)*mpc.gen(gen,19)/6,...
                                                                                                (RTD_Gen_Storage(gen,RT_int-1) + mpc.gen(gen,19)/6 ));
                                                        %Min Gen Limit is greater of (Previous RTD output + Ramping ability) and (Min Gen)
                                                            %If the unit is below its min gen (i.e. will be after being forced down for 5 minutes)
                                                            if (RTD_Gen_Storage(gen,RT_int-1) - mpc.gen(gen,19)/6 ) < mpc.gen(gen,10)
                                                                %Then don't consider the min gen level. 
                                                                    therm_Pmin_RTC_Profile(1,gen) = RTD_Gen_Storage(gen,RT_int-1) - mpc.gen(gen,19)/6;
                                                            else
                                                                %pick the lower of min gen and the value it can reach ramping down max for 5minutes. 
                                                                    therm_Pmin_RTC_Profile(1,gen) = max(mpc.gen(gen,10),...
                                                                                                        (RTD_Gen_Storage(gen,RT_int-1) - mpc.gen(gen,19)/6 ));
                                                            end
                                                    %All other intervals
                                                        for int = 2:most_period_count_RTC
                                                            %Increment the step
                                                                step = step +1;
                                                            %Max Gen Limit is smaller of (Max Gen) and (limit needed to make DAM shutdown... step included)
                                                                therm_Pmax_RTC_Profile(int,gen) = min(mpc.gen(gen, 9),(IntsTillDAMshutdown(gen)-step)*mpc.gen(gen,19)/6);
                                                            %But it cannot be less than zero. 
                                                                therm_Pmax_RTC_Profile(int,gen) = max(0,therm_Pmax_RTC_Profile(int,gen));
                                                            %Min Gen Limit is the smaller of (Min Gen) and (limit needed to make DAM shutdown... step included)
                                                                therm_Pmin_RTC_Profile(int,gen) = min(mpc.gen(gen,10),(IntsTillDAMshutdown(gen)-step)*mpc.gen(gen,19)/6);
                                                            %But it cannot be less than zero
                                                                therm_Pmin_RTC_Profile(int,gen) = max(0,therm_Pmin_RTC_Profile(int,gen));
                                                            %Note this unit is in shutdown mode for future use. 
                                                                DAMshutdownMode(gen,int) = 1;
                                                        end
                                                end
                                        else %if the unit is observing a DAM shutdown at the very start of this RTC period... 
                                            if RT_int == DAMshutdowns(gen)
                                                therm_Pmax_RTC_Profile(1:most_period_count_RTC,gen) = 0;
                                                therm_Pmin_RTC_Profile(1:most_period_count_RTC,gen) = 0;
                                            end
                                        end
                                end
                        %% Special Case - Unit online at start of RTC window and Unit is in startup mode.
                    %Does not apply to GTs 
                        if or(gen == 12, gen == 13)
                        else
                            %Is this unit in startup mode? 
                                if and(DAMstartupModeLastRTC(gen) == 1, RTD_Gen_Storage(gen,RT_int-1) < mpc.gen(gen,10))
                                    DAMstartupModeThisRTC(gen) = 1;
                                end
                            %If online and starting up 
                                if and(RTD_Gen_Storage(gen,RT_int-1) ~= 0,DAMstartupModeThisRTC(gen) == 1)
                                    %First Period
                                        %Limit max/min output to formal limits or ramping ability
                                            therm_Pmax_RTC_Profile(1,gen) = RTD_Gen_Storage(gen,RT_int-1) + mpc.gen(gen,19)/6;
                                            therm_Pmin_RTC_Profile(1,gen) = min(RTD_Gen_Storage(gen,RT_int-1) + mpc.gen(gen,19)/6,...
                                                                                mpc.gen(gen,10)); 
                                    %Second Period and Beyond
                                        for int = 2:most_period_count_RTC
                                            %Set Max = ramp step
                                                therm_Pmax_RTC_Profile(int,gen) = RTD_Gen_Storage(gen,RT_int-1)+ mpc.gen(gen,19)/6*(int);
                                            %Set Min = lesser of min gen and rampStep
                                                therm_Pmin_RTC_Profile(int,gen) = min(RTD_Gen_Storage(gen,RT_int-1)+ mpc.gen(gen,19)/6*(int),...
                                                                                      mpc.gen(gen,10)); 
                                        end
                                end
                            %Update Startup Mode for next RTC run
                                DAMstartupModeLastRTC(gen) = DAMstartupModeThisRTC(gen);
                        end
                    end
                %Assign Values to Profiles
                    profiles(8).values(:,1,:) = therm_Pmax_RTC_Profile(1:most_period_count_RTC,:);
                    profiles(9).values(:,1,:) = therm_Pmin_RTC_Profile(1:most_period_count_RTC,:);
            %% EVSE Parameters
                if EVSE == 1
                    %% Push Battery Data to MOST
                        [~,mpc,xgd,storage] = addstorage(storage,mpc,xgd);
                    %% EVSE Initial Pg
                        xgd.InitialPg(60:91) = -0.00001;
                    %% EVSE Pmin and Pmax limits
                        profiles = getprofiles('EVSE_profile_MinLvl' , profiles);    
                    %% Add EVSE Profile
                        profiles(10).values(:,1,:) = MinStorageLevelPROFILE.';
                end
            %% Limits to pass on to RTD to prevent MinGen > Max Gen for units in startup mode in RTD due to DAM committment
                %Initialize
                    MaxGenforRTD_SUP = zeros(therm_gen_count,3);
                %Create Max/Min gen limits for Nuke, Steam, and CC units in Startup Mode
                    for gen = 1:11
                        %If unit is in Startup Mode
                            if DAMstartupModeThisRTC(gen) == 1
                                MaxGenforRTD_SUP(gen,1:3) = therm_Pmax_RTC_Profile(1:3,gen);
                            end
                    end
            %% Limits to pass on to RTD to prevent MinGen > Max Gen for units in shutdown mode in RTD due to DAM committment
                %Initialize
                    MaxGenforRTD_SHUT = zeros(therm_gen_count,3);
                    for gen = 1:11
                        %If unit is in Shutdown Mode (any time output limited by impending shutdown (could be hrs away))
                            if sum(DAMshutdownMode(gen,1:3)) >= 1
                                %Limit output 
                                MaxGenforRTD_SHUT(gen,1:3) = therm_Pmax_RTC_Profile(1:3,gen);
                            end
                    end
            %% CommitKey
                CommitKey_RTC_profile = ones(most_period_count_RTC,59);
                for gen = 1:11
                    %Start by populating with vector calculated earlier
                        CommitKey_RTC_profile(:,gen)  = most_CommitKey_RTC(gen);
                    %if DAM committment starts within RTC lookahead
                        if and(IntsTillDAMstart(gen) < most_period_count_RTC, IntsTillDAMstart(gen) > 0)
                            CommitKey_RTC_profile(1:IntsTillDAMstart(gen),gen) = -1;
                            CommitKey_RTC_profile(IntsTillDAMstart(gen),gen) = 2;
                            CommitKey_RTC_profile(IntsTillDAMstart(gen)+1:end,gen) = 2;
                        end
                    %if DAM commitment stops within RTC lookahead
                        if and(IntsTillDAMshutdown(gen) < most_period_count_RTC, IntsTillDAMshutdown(gen) > 0)
                            CommitKey_RTC_profile(1:IntsTillDAMshutdown(gen),gen) = 2;
                            CommitKey_RTC_profile(IntsTillDAMshutdown(gen)+1:end,gen) = -1;
                        end
                    %if DAM commitment stops at the very first interval of this RTC lookahead
                        if (RT_int-1) == DAMshutdowns(gen)
                            CommitKey_RTC_profile(1:most_period_count_RTC,gen) = -1;
                        end
                end
            %Allow all GTs to operate whenever RTC wants
                CommitKey_RTC_profile(:,12:13) = 1;
            %Force off Imports
                CommitKey_RTC_profile(:,9) = -1;
                CommitKey_RTC_profile(:,14) = -1;
            %Force ON all renewable units
                for gen = 15:59
                    CommitKey_RTC_profile(:,gen) = 2;
                end
            %Create Profile
                profiles = getprofiles('UC_RTC_profile' , profiles); 
            %Populate Profile
                if EVSE == 1
                    profiles(11).values(:,1,:) = CommitKey_RTC_profile;
                else
                    profiles(10).values(:,1,:) = CommitKey_RTC_profile;
                end
    %% Set $-5/MWh renewable cost to avoid curtailment
        mpc.gencost(15:29,6) = REC_Cost;
        mpc.gencost(30:44,6) = REC_hydro;
        mpc.gencost(45:59,6) = REC_Cost;
        mpc.gencost(15:59,4) = 3;
    %% Add transmission interface limits
        if IFlims == 1
            mpc.if.map = map_Array;
            mpc.if.lims  = lims_Array;
            mpc = toggle_iflims_most(mpc, 'on'); 
        end
    %% Run Algorithm
        %Determine number of intervals in the simulation
            nt = most_period_count_RTC; % number of period
        %Eliminate 'inf' in renewable InitialState
            xgd.InitialState(15:59) = 1;
        %Set options
            mpopt = mpoption;
            mpopt = mpoption(mpopt,'most.dc_model', 1); % use DC network model (default)
%             mpopt = mpoption(mpopt,'most.solver', 'GUROBI');
            mpopt = mpoption(mpopt, 'verbose', 0);
            mpopt = mpoption(mpopt,'most.skip_prices', 1);
        %% Load all data
            %EVSE
                if EVSE == 1
                    numm = 91;
                    mdi = loadmd(mpc, nt, xgd, storage, [], profiles);
                    %% Modify Index for EVSE
                        mdi.Storage.UnitIdx(1:32) = [60:91];
                else
                    numm = 59;
                    mdi = loadmd(mpc, nt, xgd, [], [], profiles);
                end
            %Set Time period
                mdi.Delta_T = 5/60;
            %Set Ramp Costs = 0
                mdi.RampWearCostCoeff = zeros(numm,RTC_periods);
                for tt = 1:RTC_periods
                    mdi.offer(tt).PositiveActiveReservePrice = zeros(numm,1);
                    mdi.offer(tt).NegativeActiveReservePrice = zeros(numm,1);
                    mdi.offer(tt).PositiveActiveDeltaPrice = zeros(numm,1);
                    mdi.offer(tt).NegativeActiveDeltaPrice = zeros(numm,1);
                    mdi.offer(tt).PositiveLoadFollowReservePrice = zeros(numm,1);
                    mdi.offer(tt).NegativeLoadFollowReservePrice = zeros(numm,1);
                end
        %% Run MOST
            try
                if IFlims == 1
                    mdo = most_if(mdi, mpopt);
                else
                    mdo = most(mdi, mpopt);
                end
            catch
                save temp mdi mpopt %"load temp" then line above in 'try'
            end
        %View Results
            ms = most_summary(mdo); % print results, depending on verbose  option
    %% Plot RTC results
        %% Initialize
            %RTD Run String for title
                RTC_str = num2str(RT_int, '%03i');
                RTIntstring = strcat('RT Int:  ', RTC_str);
            % Intervals
                BigTime = most_period_count_RTC;
                Time4Graph = linspace(0,RTC_hrs,BigTime);      
        %% EVSE Load
            if EVSE == 1
                k = 1;
                for int = RT_int:RT_int+2
                    EVSEloadRTD(1:32,int) = mdo.Storage.ExpectedStorageDispatch(1:32,k);
                    k = k+1;
                end
            end
        %% Interface Limits
                round = 1;
            for int = RTC_int_start:RTC_int_start+2
                RTMifFlows(int,1) = ms.Pf(1,round)  - ms.Pf(16,round);
                RTMifFlows(int,2) = ms.Pf(1,round)  - ms.Pf(16,round) + ms.Pf(86,round); 
                RTMifFlows(int,3) = ms.Pf(7,round)  + ms.Pf(9,round)  + ms.Pf(13,round); 
                RTMifFlows(int,4) = ms.Pf(28,round) + ms.Pf(29,round);
                round = round + 1;
            end        
                clear round;
        %% Gather Gen Output in percent
            gen_output = ms.Pg;
            gen_capacity = mpc.gen(:,9);
            for gen = 1:length(gen_capacity)
                gen_output_percent_all(gen,:) = gen_output(gen,:)./gen_capacity(gen);
            end
            gen_output_percent_all(isnan(gen_output_percent_all)) = 0;
                %Modify % output to show offline/online units
                    for gen = 1:therm_gen_count
                        for time = 1:most_period_count_RTC
                            %offline
                            if gen_output_percent_all(gen,time) == 0
                                gen_output_percent_all(gen,time) = -gen*.01;
                            else
                                %at max
                                if gen_output_percent_all(gen,time) == 1
                                    gen_output_percent_all(gen,time) = 1+gen*.01;
            %                         else
            %                             %in between... Do nothing
                                end
                            end
                        end
                    end
        %% Gather temp data for Figures 
            demand1(1:most_period_count_RTC) = demand(RTC_int_start:RTC_int_end);
            NetLoad(1:most_period_count_RTC) = NYCA_CASE_net_load(RTC_int_start:RTC_int_end);
            TrueLoad(1:most_period_count_RTC) = NYCA_TrueLoad(RTC_int_start:RTC_int_end);
            RenGen_hydro1 = zeros(1,most_period_count_RTC);
            RenGen_windy1 = zeros(1,most_period_count_RTC);
            RenGen_other1 = zeros(1,most_period_count_RTC);
            BTM4Graph1 = zeros(1,most_period_count_RTC);
            for iter = 1:most_period_count_RTC
                    for renge = 15:29
                        RenGen_windy1(iter) = RenGen_windy1(iter) + ms.Pg(renge,iter);
                    end
                    for renge = 30:44
                        RenGen_hydro1(iter) = RenGen_hydro1(iter) + ms.Pg(renge,iter);
                    end
                    for renge = 45:59
                        RenGen_other1(iter) = RenGen_other1(iter) + ms.Pg(renge,iter);
                    end
                BTM4Graph1(iter) = TrueLoad(iter) - NetLoad(iter);
            end
        %% Gather Gen Output by Type - RTC 
            for iter = RT_int:RT_int+most_period_count_RTC-1
                run = iter-RT_int+1;
                NukeGen(iter) = ms.Pg(1,run)+ms.Pg(2,run)+ms.Pg(3,run); %NUKE
                SteamGen(iter) = ms.Pg(4,run)+ms.Pg(5,run)+ms.Pg(6,run)+ms.Pg(7,run)+ms.Pg(8,run);%STEAM
                CCGen(iter) = ms.Pg(10,run)+ms.Pg(11,run);%CC
                GTGen(iter) = ms.Pg(12,run)+ms.Pg(13,run);%GT
                LOHIGen(iter) = ms.Pg(14,run); %Lo High Unit
                RenGen_windy(iter) = 0;
                for renge = 15:29
                    RenGen_windy(iter) = RenGen_windy(iter) + ms.Pg(renge,run);
                end
                RenGen_hydro(iter) = 0;
                for renge = 30:44
                    RenGen_hydro(iter) = RenGen_hydro(iter) + ms.Pg(renge,run);
                end
                RenGen_other(iter) = 0;%RENEWABLE
                for renge = 45:59
                    RenGen_other(iter) = RenGen_other(iter) + ms.Pg(renge,run);
                end
                BTM4Graph(iter) = TrueLoad(run) - NetLoad(run);
            end
        %% Gather Gen Output by Type - RTD
            NukeGenRTD = NaN(1,288);
            SteamGenRTD = NaN(1,288);
            CCGenRTD = NaN(1,288);
            GTGenRTD = NaN(1,288);
            LOHIGenRTD = NaN(1,288);
            RenGen_windyRTD = NaN(1,288);
            RenGen_hydroRTD = NaN(1,288);
            RenGen_otherRTD = NaN(1,288);
            BTM4GraphRTD = NaN(1,288);
            for iter = 1:RT_int-1
                NukeGenRTD(iter) = RTD_Gen_Storage(1,iter)+RTD_Gen_Storage(2,iter)+RTD_Gen_Storage(3,iter); %NUKE
                SteamGenRTD(iter) = RTD_Gen_Storage(4,iter)+RTD_Gen_Storage(5,iter)+RTD_Gen_Storage(6,iter)+RTD_Gen_Storage(7,iter)+RTD_Gen_Storage(8,iter);%STEAM
                CCGenRTD(iter) = RTD_Gen_Storage(10,iter)+RTD_Gen_Storage(11,iter);%CC
                GTGenRTD(iter) = RTD_Gen_Storage(12,iter)+RTD_Gen_Storage(13,iter);%GT
                LOHIGenRTD(iter) = RTD_Gen_Storage(14,iter);
                RenGen_windyRTD(iter) = 0;
                for renge = 15:29
                    RenGen_windyRTD(iter) = RenGen_windyRTD(iter) + RTD_Gen_Storage(renge,iter);
                end
                RenGen_hydroRTD(iter) = 0;
                for renge = 30:44
                    RenGen_hydroRTD(iter) = RenGen_hydroRTD(iter) + RTD_Gen_Storage(renge,iter);
                end
                RenGen_otherRTD(iter) = 0;%RENEWABLE
                for renge = 45:59
                    RenGen_otherRTD(iter) = RenGen_otherRTD(iter) + RTD_Gen_Storage(renge,iter);
                end
                BTM4GraphRTD(iter) = NYCA_TrueLoad(iter) - NYCA_CASE_net_load(iter);
            end         
        %% Print Figures
            if printRTC == 1
                %% Create Figures
                        hFigA = figure(2); set(hFigA, 'Position', [450 50 650 850]) %Pixels: from left, from bottom, across, high
                    %% A -- True Load, Net Load, Demand
                            A1 = subplot(4,1,1); hold on;
                            A2 = get(A1,'position'); A2(4) = A2(4)*.85; A2(3) = A2(3)*1; set(A1, 'position', A2);
                                plot(Time4Graph(1:most_period_count_RTC),NYCA_TrueLoad(RTC_int_start:RTC_int_end)./1000,'LineStyle','-','color',[0 .447 .741],'marker','*')
                                plot(Time4Graph(1:most_period_count_RTC),NYCA_CASE_net_load(RTC_int_start:RTC_int_end)./1000,'LineStyle','--','color','red','marker','x')
                                plot(Time4Graph,demand(RTC_int_start:RTC_int_end)./1000,'LineStyle','-','color',[.494 .184 .556],'marker','d','markeredgecolor',[.494 .184 .556])
                                area(Time4Graph,[demand1;RenGen_windy1; RenGen_hydro1; RenGen_other1; BTM4Graph1;].'./1000,'FaceAlpha',.5)
                            title('True Load, Net Load, & Demand')
        %                     A3 = legend('True Load', 'Net Load', 'Demand','Demand', 'Wind','Hydro', 'Other Ren', 'BTM Ren');      
        %                         reorderLegendarea([8 1 7 2 3 4 5 6])
        %                         rect = [.8, 0.77, 0.15, 0.0875]; %[left bottom width height]
        %                         set(A3, 'Position', rect)
                            axis([0,RTC_hrs,0,30]); 
                                set(gca, 'YTick', [0 10 20 30])
        %                         axis 'auto y';
                                ylabel('Real Power (GW)')
                                set(gca, 'XTick', Time4Graph);
                            set(gca, 'xticklabel', {'0', ' ', ' ', ' ', ' ', ' ','0.5',  ' ', ' ', ' ', ' ', ' ', '1' , ' ', ' ', ' ', ' ', ' ', '1.5'...
                                                       , ' ', ' ', ' ', ' ', ' ','2', ' ', ' ', ' ', ' ', '2.5'})
%                             set(gca, 'xticklabel', {'0', ' ', ' ', ' ', ' ', ' ','1',  ' ', ' ', ' ', ' ', ' ', '2' , ' ', ' ', ' ', ' ', ' ', '3'...
%                                                        , ' ', ' ', ' ', ' ', ' ','4', ' ', ' ', ' ', ' ', '5'})
                                grid on; box on; hold off 
                    %% B -- Generator Output (%)
                        B1 = subplot(4,1,2); hold on;
                            B2 = get(B1,'position'); B2(4) = B2(4)*.85; B2(2) = B2(2)*1; set(B1, 'position', B2); B2(3) = B2(3)*1; set(B1, 'position', B2);
                            plot(Time4Graph,gen_output_percent_all(1,:),'LineStyle',':','color',[0 .447 .741])
                            plot(Time4Graph,gen_output_percent_all(2,:),'LineStyle',':','color',[.635 .078 .184])
                            plot(Time4Graph,gen_output_percent_all(3,:),'LineStyle',':','color',[.85 .325 .098])
                            plot(Time4Graph,gen_output_percent_all(4,:),'LineStyle','--','color',[0 .447 .741])
                            plot(Time4Graph,gen_output_percent_all(5,:),'LineStyle','--','color',[.301 .745 .933])
                            plot(Time4Graph,gen_output_percent_all(6,:),'LineStyle','--','color',[.635 .078 .184])
                            plot(Time4Graph,gen_output_percent_all(7,:),'LineStyle','--','color',[.494 .184 .556])
                            plot(Time4Graph,gen_output_percent_all(8,:),'LineStyle','--','color',[.466 .674 .188])
                            plot(Time4Graph,gen_output_percent_all(10,:),'LineStyle','-.','color',[0 .447 .741])
                            plot(Time4Graph,gen_output_percent_all(11,:),'LineStyle','-.','color',[.494 .184 .556])
                            plot(Time4Graph,gen_output_percent_all(12,:),'LineStyle','-','color',[.494 .184 .556])
                            plot(Time4Graph,gen_output_percent_all(13,:),'LineStyle','-','color',[.466 .674 .188])
    %                         B3 = legend('Nuke A2F','Nuke GHI','Nuke GHI','Steam A2F','Steam A2F','Steam GHI','Steam NYC','Steam LI',...
    %                                     'CC A2F','CC NYC','GT NYC','GT LI')                        
                            title('RTC Generation (% Of Nameplate)')
    %                         rect = [.8, 0.49, 0.15, .12]; %[left bottom width height]
    %                         set(B3, 'Position', rect)
                            ylabel('Real Power (%)')
                            axis([0,RTC_hrs,-0.16,1]); 
                            set(gca, 'YTick', [0 0.25 0.5 0.75 1])
                            set(gca, 'yticklabel', {'0', '25', '50', '75', '100'})
                            set(gca, 'XTick', Time4Graph);
                            set(gca, 'xticklabel', {'0', ' ', ' ', ' ', ' ', ' ','0.5',  ' ', ' ', ' ', ' ', ' ', '1' , ' ', ' ', ' ', ' ', ' ', '1.5'...
                                                       , ' ', ' ', ' ', ' ', ' ','2', ' ', ' ', ' ', ' ', '2.5'})
%                             set(gca, 'xticklabel', {'0', ' ', ' ', ' ', ' ', ' ','1',  ' ', ' ', ' ', ' ', ' ', '2' , ' ', ' ', ' ', ' ', ' ', '3'...
%                                                        , ' ', ' ', ' ', ' ', ' ','4', ' ', ' ', ' ', ' ', '5'})
                            grid on; box on; hold off 
                    %% C -- Generation by Type - RTC
                        C1 = subplot(4,1,3); hold on;
                            C2 = get(C1,'position'); C2(4) = C2(4)*.85; C2(2) = C2(2)*1; set(C1, 'position', C2); C2(3) = C2(3)*1; set(C1, 'position', C2);
                            area(1:288,[NukeGen;SteamGen;CCGen;GTGen;RenGen_windy;RenGen_hydro;RenGen_other;BTM4Graph;].'./1000,'FaceAlpha',.5)
    %                         C3 = legend('Nuke', 'Steam', 'CC', 'GT', 'Wind', 'Hydro', 'Other Ren', 'BTM');
    %                         reorderLegendarea([1 2 3 4 5 6 7 8]) 
                            title('RTC Generation By Type')
    %                         rect = [.8, 0.23, 0.15, .12]; %[left bottom width height]
    %                         set(C3, 'Position', rect)
                            ylabel('Real Power (GW)')
                            axis([0,288,0,30]); 
                            set(gca, 'YTick', [0 10 20 30])
                            set(gca, 'XTick', [0 12 24 36 48 60 72 84 96 108 120 132 144 156 168 180 192 204 216 228 240 252 264 276 288]);
                            set(gca, 'xticklabel', {'0', ' ', ' ', ' ','4', ' ', ' ', ' ', '8', ' ', ' ', ' ', '12', ' ', ' ', ' ', '16', ' ', ' ', ' ', '20', ' ', ' ', ' ', '24'})
                            grid on; box on; hold off 
                    %% D -- Generation by Type - RTD
                        D1 = subplot(4,1,4); hold on;
                            D2 = get(D1,'position'); D2(4) = D2(4)*.85; D2(2) = D2(2)*1; set(D1, 'position', D2); D2(3) = D2(3)*1; set(D1, 'position', D2);
                            area(1:288,[NukeGenRTD;SteamGenRTD;CCGenRTD;GTGenRTD;RenGen_windyRTD;RenGen_hydroRTD;RenGen_otherRTD;BTM4GraphRTD;].'./1000,'FaceAlpha',.5)
                            title('RTD Generation By Type')
                            ylabel('Real Power (GW)')
                            xlabel('Time (Hour Beginning)');
                            axis([0,288,0,30]); 
                            set(gca, 'YTick', [0 10 20 30])
                            set(gca, 'XTick', [0 12 24 36 48 60 72 84 96 108 120 132 144 156 168 180 192 204 216 228 240 252 264 276 288]);
                            set(gca, 'xticklabel', {'0', ' ', ' ', ' ','4', ' ', ' ', ' ', '8', ' ', ' ', ' ', '12', ' ', ' ', ' ', '16', ' ', ' ', ' ', '20', ' ', ' ', ' ', '24'})
                            grid on; box on; hold off 
                    %% Graph Title (Same for all graphs)
                        First_Line_Title = [datestring(5:6), ' ', datestring(7:8), ', ', Case_Name_String,', ', RTIntstring];
                        ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off',...
                            'Units','normalized', 'clipping' , 'off');
                        text(0.5, 1.0,[{'\bf \fontsize{18}' First_Line_Title}], 'HorizontalAlignment' ,...
                            'center', 'VerticalAlignment', 'top')     
                %% Copy Figure to clipboard:
                    matlab.graphics.internal.copyFigureHelper(hFigA)
            end
end

