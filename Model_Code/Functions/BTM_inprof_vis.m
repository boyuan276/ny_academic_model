function BTM_inprof_vis(YMatrix1,Zone)
%BTM_inprof_vis(YMatrix1)
%  YMATRIX1:  matrix of y data

% Create figure
figure1 = figure;

% Create axes
axes1 = axes('Parent',figure1);
hold(axes1,'on');

% Create multiple lines using matrix input to plot
plot1 = plot(YMatrix1,'LineWidth',1.5,'Parent',axes1);
set(plot1(1),'DisplayName','Load Only','Color',[0 0 0]);
set(plot1(2),'DisplayName','Input Net Load','LineStyle','--');
set(plot1(3),'DisplayName','Input BTM Generation','LineStyle','--',...
    'Color',[0 0 1]);
set(plot1(4),'DisplayName','Scenario BTM Generation','LineStyle','-.');
set(plot1(5),'DisplayName','Scenario Net Load','LineStyle','-.');

% Create ylabel
ylabel('Demand/Generation (MW)');

% Create xlabel
xlabel('Time Step');

% Create title
titlestr = sprintf('Effect of BTM Generation on Net Load in %s',Zone);
title(titlestr);

% Format plot frame
box(axes1,'on');
axis tight

% Show legend
legend('show','Location','Best')

end