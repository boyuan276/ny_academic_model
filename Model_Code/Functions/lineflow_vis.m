function lineflow_vis(ms)
%lineflow_vis(ms) creates a color map displaying the line flow for the MOST
%optimization.


h = heatmap(abs(ms.Pf));
h.FontSize = 14;
h.GridVisible = 'off';
h.ColorLimits = [0 4000];
h.YLabel = 'Branch';
h.XLabel = 'Hour';
title('Power Flow in MW on Each Branch')
colormap(flipud(hot))

end

