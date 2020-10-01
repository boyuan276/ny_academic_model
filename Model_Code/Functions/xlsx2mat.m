clear
clc

date_array = [2016,1,19;2016,3,22;2016,7,25;2016,11,10];
ren_tab_array = ["Jan 19";"Mar 22";"Jul 25";"Nov 10";];
d = 3;

BTM = xlsread('rtd_profiles.xlsx',ren_tab_array(d),'C18:KD28');
wind  = xlsread('rtd_profiles.xlsx',ren_tab_array(d),'C34:KD44');
hydro = xlsread('rtd_profiles.xlsx',ren_tab_array(d),'C49:KD59');
PV = xlsread('rtd_profiles.xlsx',ren_tab_array(d),'C64:KD74');
Bio = xlsread('rtd_profiles.xlsx',ren_tab_array(d),'C79:KD89');
LFG   = xlsread('rtd_profiles.xlsx',ren_tab_array(d),'C94:KD104');

A2F_BTM_inc_gen = sum(BTM(1:6,:));
GHI_BTM_inc_gen = sum(BTM(7:9,:));
NYC_BTM_inc_gen = BTM(10,:);
LIs_BTM_inc_gen = BTM(11,:);

A2F_INC_ITM_wind_gen = sum(wind(1:6,:));
GHI_INC_ITM_wind_gen = sum(wind(7:9,:));
NYC_INC_ITM_wind_gen =     wind(10,:);
LIs_INC_ITM_wind_gen =     wind(11,:);

A2F_INC_ITM_hydro_gen = sum(hydro(1:6,:));
GHI_INC_ITM_hydro_gen = sum(hydro(7:9,:));
NYC_INC_ITM_hydro_gen =     hydro(10,:);
LIs_INC_ITM_hydro_gen =     hydro(11,:);

A2F_INC_ITM_PV_gen = sum(PV(1:6,:));
GHI_INC_ITM_PV_gen = sum(PV(7:9,:));
NYC_INC_ITM_PV_gen =     PV(10,:);
LIs_INC_ITM_PV_gen =     PV(11,:);

A2F_INC_ITM_Bio_gen = sum(Bio(1:6,:));
GHI_INC_ITM_Bio_gen = sum(Bio(7:9,:));
NYC_INC_ITM_Bio_gen =     Bio(10,:);
LIs_INC_ITM_Bio_gen =     Bio(11,:);

A2F_INC_ITM_LFG_gen = sum(LFG(1:6,:));
GHI_INC_ITM_LFG_gen = sum(LFG(7:9,:));
NYC_INC_ITM_LFG_gen =     LFG(10,:);
LIs_INC_ITM_LFG_gen =     LFG(11,:);

wind = struct;
pv = struct;
btm = struct;
bio = struct;
hydro = struct;
lfg = struct;

wind.A2F_genin = A2F_INC_ITM_wind_gen';
wind.GHI_genin = GHI_INC_ITM_wind_gen';
wind.NYC_genin = NYC_INC_ITM_wind_gen';
wind.LIs_genin = LIs_INC_ITM_wind_gen';

pv.A2F_genin = A2F_INC_ITM_PV_gen';
pv.GHI_genin = GHI_INC_ITM_PV_gen';
pv.NYC_genin = NYC_INC_ITM_PV_gen';
pv.LIs_genin = LIs_INC_ITM_PV_gen';

btm.A2F_genin = A2F_BTM_inc_gen';
btm.GHI_genin = GHI_BTM_inc_gen';
btm.NYC_genin = NYC_BTM_inc_gen';
btm.LIs_genin = LIs_BTM_inc_gen';

bio.A2F_genin = A2F_INC_ITM_Bio_gen';
bio.GHI_genin = GHI_INC_ITM_Bio_gen';
bio.NYC_genin = NYC_INC_ITM_Bio_gen';
bio.LIs_genin = LIs_INC_ITM_Bio_gen';

hydro.A2F_genin = A2F_INC_ITM_hydro_gen';
hydro.GHI_genin = GHI_INC_ITM_hydro_gen';
hydro.NYC_genin = NYC_INC_ITM_hydro_gen';
hydro.LIs_genin = LIs_INC_ITM_hydro_gen';

lfg.A2F_genin = A2F_INC_ITM_LFG_gen';
lfg.GHI_genin = GHI_INC_ITM_LFG_gen';
lfg.NYC_genin = NYC_INC_ITM_LFG_gen';
lfg.LIs_genin = LIs_INC_ITM_LFG_gen';


Casenam = 'NYAM2030';
dat = '20160725';
outfile = sprintf('%s_REdat_%s.mat', Casenam, dat);
save(outfile, 'wind', 'pv', 'btm', 'hydro', 'bio', 'lfg')
