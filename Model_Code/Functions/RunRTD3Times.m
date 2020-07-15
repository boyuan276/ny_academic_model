function [RT_int,RTD_Load_Storage,RTD_Gen_Storage,RTD_RenGen_Max_Storage, RTD_RenGen_Min_Storage,RTD_UC_Status,RTD_LMP,Gen_RTD_OpCost,most_busload] = ...
    RunRTD3Times(RT_int,mdo,therm_gen_count,mpc,most_busload_RTC,most_bus_rengen_windy,most_bus_rengen_hydro,...
                 most_bus_rengen_other,RTD_Load_Storage,RTD_Gen_Storage,RTD_RenGen_Max_Storage, RTD_RenGen_Min_Storage,RTD_LMP,Gen_RTD_OpCost,...
                 windyCurt,windyCurtFactor,hydroCurt,hydroCurtFactor,otherCurt,otherCurtFactor,ms,IncreasedRTCramp_Steam,RTCrampFactor_Steam,MaxGenforRTD_SUP,MaxGenforRTD_SHUT,...
                 IncreasedRTDramp_Steam,RTDrampFactor_Steam,IncreasedRTCramp_CC,RTCrampFactor_CC,IncreasedRTDramp_CC,RTDrampFactor_CC,...
                 EVSE,EVSEloadRTD,NYCA_Load_buses,most_busload,Gens)

        %Initialize
             define_constants
             curtbus = 0; 

        %% Eliminate Tiny Outputs from generators
            for gen = 1:therm_gen_count
                for Col = 1:30
                    if ms.Pg(gen,Col) < 0.00001
                        ms.Pg(gen,Col) = 0;
                        mdo.UC.CommitSched(gen,Col) = 0;
                    end
                end
            end
        %% Gather UC for all 3 RTD runs
            RTD_UC_Status = mdo.UC.CommitSched(1:therm_gen_count,1:4);        
        %% Loop through RTD Runs    
            for RTDLoop = 1:3
                %% debug Stop Point
                    if RT_int == 112
                        stop_here_please = 1;
                    end
                %% Get data
                    mpc_RTD = mpc;
                %% Remove EVSE as Batteries
                    if EVSE == 1
                        mpc_RTD.gen(60:91,:) = []; %Make their max gen = 0
                        mpc_RTD.genfuel(60:91,:) = [];
                        mpc_RTD.gencost(60:91,:) = [];
                        mpc_RTD.iess = [];
                    end
                %% Ramp Rates
                    %restore ramp rates to original values (from RTC to original)
                        if IncreasedRTCramp_Steam == 1
                            for col = 17:19
                                mpc_RTD.gen(4:8,col) = mpc_RTD.gen(4:8,col)./RTCrampFactor_Steam;
                            end
                        end 
                        if IncreasedRTCramp_CC == 1
                            for col = 17:19
                                mpc_RTD.gen(10:11,col) = mpc_RTD.gen(10:11,col)./RTCrampFactor_CC;
                            end
                        end 
                    %set ramp rates to new RTD values (from original to RTD)
                        if IncreasedRTDramp_Steam == 1
                            for col = 17:19
                                mpc_RTD.gen(4:8,col) = mpc_RTD.gen(4:8,col).*RTDrampFactor_Steam;
                            end
                        end 
                        if IncreasedRTDramp_CC == 1
                            for col = 17:19
                                mpc_RTD.gen(10:11,col) = mpc_RTD.gen(10:11,col).*RTDrampFactor_CC;
                            end
                        end 
                %% Remove Offline Generators & Set Max/Min Gen Limits
                    %Initialize
                        offlineGens = 0;
                    for gen = 1:therm_gen_count
                        %If the unit is online
                            if RTD_UC_Status(15-gen,RTDLoop) ~= 0
                                %If RTC is going to shut down unit in next iteration, then 
                                    if RTD_UC_Status(15-gen,RTDLoop)- RTD_UC_Status(15-gen,RTDLoop+1) == 1
                                        %limit Pmax to RTC's suggested value (don't let RTD dispatch above RTC's desired value)
                                            mpc_RTD.gen(15-gen,9)  = ms.Pg(15-gen,RTDLoop);
                                            mpc_RTD.gen(15-gen,10)  = ms.Pg(15-gen,RTDLoop);
                                %If unit is online and not shutting down in next RTD interval
                                    else
                                        %If the unit is starting
                                            if MaxGenforRTD_SUP(15-gen, RTDLoop) ~=0
                                                %then set the max gen = RTC value
                                                    mpc_RTD.gen(15-gen,9) = MaxGenforRTD_SUP(15-gen, RTDLoop);
                                                    mpc_RTD.gen(15-gen,10) = min(MaxGenforRTD_SUP(15-gen, RTDLoop),mpc_RTD.gen(15-gen,10));
                                        %If unit operating normally (between min and max)
                                            else
                                                if MaxGenforRTD_SHUT(15-gen, RTDLoop) ~=0
                                                    mpc_RTD.gen(15-gen,9) = MaxGenforRTD_SHUT(15-gen, RTDLoop);
                                                    mpc_RTD.gen(15-gen,10) = min(MaxGenforRTD_SHUT(15-gen, RTDLoop),mpc_RTD.gen(15-gen,10));
                                                else
                                                %set limits =  (1) previous value +/- ramping ability, or (2) max/min limits
                                                    mpc_RTD.gen(15-gen,9)  = min(RTD_Gen_Storage(15-gen,RT_int-1) + mpc_RTD.gen(15-gen,19)/6,mpc_RTD.gen(15-gen,9));
                                                    mpc_RTD.gen(15-gen,10) = max(RTD_Gen_Storage(15-gen,RT_int-1) - mpc_RTD.gen(15-gen,19)/6,mpc_RTD.gen(15-gen,10));
                                                end
                                            end
                                    end
                         %If unit is offline
                            else
                                %eliminate it from mpc and count it. 
                                    mpc_RTD.gen(15-gen,:) = [];
                                    mpc_RTD.gencost(15-gen,:) = [];
                                    mpc_RTD.genfuel(15-gen,:) = [];
                                    offlineGens = offlineGens+1;
                            end
                    end
                %% Define load 
                    mpc_RTD.bus(1:52, PD) = most_busload_RTC(RTDLoop,:);
                    mpc_RTD.bus(53:68, PD) = 0;  
                %% Add EVSE as load
                    if EVSE == 1
                        for EV = 1:32
                            mpc_RTD.bus(NYCA_Load_buses(EV), PD) = mpc_RTD.bus(NYCA_Load_buses(EV), PD) - EVSEloadRTD( EV,RT_int);                
                        end
                    end
                %% Define renewable output
                    %Identify renewable generator numbers
                        first_windy = 14-offlineGens+1;  last_windy = first_windy+14;
                        first_hydro = last_windy+1;      last_hydro = first_hydro+14;
                        first_other = last_hydro+1;      last_other = first_other+14;
                    %Define Max and Min Gen
                        %wind
                            mpc_RTD.gen(first_windy:last_windy,9)  = (most_bus_rengen_windy(RT_int,:)).';
                            if windyCurt == 1
                                mpc_RTD.gen(first_windy:last_windy,10) = ((most_bus_rengen_windy(RT_int,:)).').*windyCurtFactor;
                            else
                                mpc_RTD.gen(first_windy:last_windy,10) = (most_bus_rengen_windy(RT_int,:)).';
                            end
                        %Hydro
                            mpc_RTD.gen(first_hydro:last_hydro,9)  = (most_bus_rengen_hydro(RT_int,:)).';
                            if hydroCurt == 1
                                mpc_RTD.gen(first_hydro:last_hydro,10) = ((most_bus_rengen_hydro(RT_int,:)).').*hydroCurtFactor;
                            else
                                mpc_RTD.gen(first_hydro:last_hydro,10) = (most_bus_rengen_hydro(RT_int,:)).';
                            end
                        %Other
                            mpc_RTD.gen(first_other:last_other,9)  = (most_bus_rengen_other(RT_int,:)).';
                            if otherCurt == 1
                                mpc_RTD.gen(first_other:last_other,10) = ((most_bus_rengen_other(RT_int,:)).').*otherCurtFactor;
                            else
                                mpc_RTD.gen(first_other:last_other,10) = (most_bus_rengen_other(RT_int,:)).';
                            end
                %% Run DC OPF
                    clear results
                    mpopt = mpoption;       %start with default options
                    mpopt = mpoption(mpopt, 'model', 'DC');
                    mpopt = mpoption(mpopt,'out.all',0);
                    mpopt = mpoption(mpopt,'verbose',0); 
                %Run MatPower
                    results = runopf(mpc_RTD, mpopt);
                %exit if failure occurs
                    if results.success == 0
                        %Read out everything
                            mpopt = mpoption(mpopt,'out.all',1); 
                            mpopt = mpoption(mpopt,'verbose',2);
                        %Identify buses to allow curtailment
                            curtbus = 12; %Bus 12 is a load bus w/o gen in NYC. 
                        %Increase curtailable amount from 1% to 100%
                            for iter = 1:100
                                %Convert Fixed Loads to Dispatchable
                                    mpc_Dis = load2disp_walkIn(mpc_RTD,[],curtbus,5000,iter);
                                %Run the program again
                                    results = runopf(mpc_Dis, mpopt);
                                %If it works, then stop increasing the curtailable amount
                                    if results.success == 1
                                        most_busload(RT_int,12) = most_busload(RT_int,12) + results.gen(last_other+1,10);
                                        break
                                    end
                            end
                    end
                %% Gather results for graphing
                    %Load
                        RTD_Load_Storage(:,RT_int) = results.bus(:,3);
                    %Thermal Gen Power Output
                        onlinegen = 1;
                        for gen = 1:therm_gen_count
                            if RTD_UC_Status(gen,RTDLoop) == 1
                                RTD_Gen_Storage(gen,RT_int) = results.gen(onlinegen,2);
                                onlinegen = onlinegen +1;
                            else
                                RTD_Gen_Storage(gen,RT_int) = 0;
                            end
                        end
                        RTD_Gen_Storage(therm_gen_count+1:therm_gen_count+45,RT_int) = results.gen(onlinegen:onlinegen+44,2);
                    %Max and Min limits for thermal gens
                        RTD_RenGen_Max_Storage(:,RT_int) = results.gen(onlinegen:onlinegen+44,9);
                        RTD_RenGen_Min_Storage(:,RT_int) = results.gen(onlinegen:onlinegen+44,10);
                    %RTD Prices
                        RTD_LMP(1:68,RT_int) = results.bus(1:68,14);
                    %RTD Gen Operating Costs
                        for gen = 1:Gens
                            Gen_RTD_OpCost(gen) = Gen_RTD_OpCost(gen) + ...
                                    1/12*mdo.UC.CommitSched(gen,RTDLoop)*(mpc.gencost(gen,7) + RTD_Gen_Storage(gen,RT_int) *mpc.gencost(gen,6) + RTD_Gen_Storage(gen,RT_int)^2 *mpc.gencost(gen,5));
                        end
% %                         %If Load Curtailment occured
% %                         if curtbus == 12
% %                             %then add it to the operating cost
% %                                 Gen_RTD_OpCost(genn) = Gen_RTD_OpCost(genn) + ...
% %                                     1/12*-results.gen(51,2)*5000;
% %                             %and reset Curtbus variable
% %                                 curtbus = 0;
% %                         end

                %Increment period
                    RT_int = RT_int + 1
            end
end

