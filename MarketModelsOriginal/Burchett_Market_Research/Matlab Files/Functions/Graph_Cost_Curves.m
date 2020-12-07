clear all
close all
clc


mpc.gencost = [
2	80000       0	3	0.001	5       225	;	%1NUKE
2	80000       0	3	0.001	6       200	;	%2
2	80000       0	3	0.001	5.5      300	;	%3

2	60000       0	3	0.0005	9      250	;	%4STEAM
2	60000       0	3	0.001	9      300	;	%5
2	60000       0	3	0.001	7.5      250	;	%6
2	60000       0	3	0.001	9       175	;	%7
2	60000       0	3	0.001	8       225	;	%8

2	300000000	0	3	0.001	10      808.633	;	%9

2	4500        0	3	0.001	9.5     400	;	%10CC
2	4500        0	3	0.001	10       350	;	%11

2	1000        0	3	0.001	13      50	;	%12GT
2	1000        0	3	0.001	13.2	50	;	%13

2	300000000	0	3	0.001	1.0383	808.633	;	%14
];

T = linspace(140,5300,1000);

Pout = [3500,	2625    ;...
        1100,	825     ;...
        1100,	825     ;...
        1400,	140     ;...
        1400,	140     ;...
        2900,	290     ;...
        3900,	390     ;...
        2600,	260     ;...
        2000,	0       ;...
        5300,	530     ;...
        3300,	300     ;...
        2600,	260     ;...
        2377,	237.7	;...
        10000,	0       ;]

hold on
for gen = 1:14

    

    p = mpc.gencost(gen,5:7)
    
    PoutRange(gen,:) = linspace(Pout(gen,2),Pout(gen,1),50);
    
    Cost(gen,:) = polyval(p,PoutRange(gen,:))
end
hold on
                    plot(PoutRange(1,:),Cost(1,:),'LineStyle',':','color',[0 .447 .741])
                    plot(PoutRange(2,:),Cost(2,:),'LineStyle',':','color',[.635 .078 .184])
                    plot(PoutRange(3,:),Cost(3,:),'LineStyle',':','color',[.85 .325 .098])
                    plot(PoutRange(4,:),Cost(4,:),'LineStyle','--','color',[0 .447 .741])
                    plot(PoutRange(5,:),Cost(5,:),'LineStyle','--','color',[.301 .745 .933])
                    plot(PoutRange(6,:),Cost(6,:),'LineStyle','--','color',[.635 .078 .184])
                    plot(PoutRange(7,:),Cost(7,:),'LineStyle','--','color',[.494 .184 .556])
                    plot(PoutRange(8,:),Cost(8,:),'LineStyle','--','color',[.466 .674 .188])
                    plot(PoutRange(10,:),Cost(10,:),'LineStyle','-.','color',[0 .447 .741])
                    plot(PoutRange(11,:),Cost(11,:),'LineStyle','-.','color',[.494 .184 .556])
                    plot(PoutRange(12,:),Cost(12,:),'LineStyle','-','color',[.494 .184 .556])
                    plot(PoutRange(13,:),Cost(13,:),'LineStyle','-','color',[.466 .674 .188])
                    
                    title('Generator Cost Curves')
                    B3 = legend('Nuke A2F','Nuke GHI','Nuke GHI','Steam A2F','Steam A2F','Steam GHI','Steam NYC','Steam LI',...
                               'CC A2F','CC NYC','GT NYC','GT LI');    
                    ylabel('Cost ($/MWh)')
                    xlabel('Output (MW for 1 hour)')
                    
                    grid on
                    grid minor

hold off