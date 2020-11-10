clear all
close all
clearJavaMem();
KbName('UnifyKeyNames')
tic();

% initialise output options
EXPORT_FORMAT = {'jpg'};
EXPORT_DIR = sprintf('./Figs/%s',datestr(now,1));
pkgVer = 0.3;
[exportDir,exportFormat] = fig_init(pkgVer,EXPORT_FORMAT,EXPORT_DIR);

%% Get data
% s1 = load('rawMeasures-15-Jul-2013_A'); % rawMeasures-08-Jul-2013
% s2 = load('rawMeasures-15-Jul-2013_B'); % rawMeasures-08-Jul-2013
% 
% 
% figure()
% plot(s1.valsRaw(:), s2.valsRaw(:), 'o');
% corrcoef(s1.valsRaw(:), s2.valsRaw(:))
% 
% %%
% 
% inputV = (s1.inputV+s2.inputV)/2
% vals = (s1.vals+s2.vals)/2
% valsRaw = (s1.valsRaw+s2.valsRaw)/2
% maxLevel = s1.maxLevel
% nMeasures = size(vals,3)

s = load('rawMeasures-05-Dec-2013_bbkBasement.mat');
inputV = s.inputV;
vals = s.vals;
valsRaw = s.valsRaw;
maxLevel = s.maxLevel;
nMeasures = size(vals,3);

fprintf('All done. Took %1.2f mins', toc()/60);

%% clean up
% replace 1 dodgy point with vals of those around it

%vals(2,3,5) = mean([vals(2,2,5) vals(1,3,5) vals(3,3,5) vals(2,4,5)])

%%
hFig = fig_make([20 20], size(vals));

for i = 1:size(vals,1)
    for j = 1:size(vals,2)
        
        fig_subplot(i,j);
        valss = vals(i,j,:); valss = valss(:);
        
        %Gamma function fitting
        g = fittype('x^g');
        fittedmodel = fit(inputV',valss,g);
        firstFit = fittedmodel([0:maxLevel]/maxLevel); %#ok<NBRAK>
        
        %Spline interp fitting
        fittedmodel = fit(inputV',valss,'splineinterp');
        secondFit = fittedmodel([0:maxLevel]/maxLevel); %#ok<NBRAK>
        
        % plot
        hDat = plot(inputV, valss, '.', [0:maxLevel]/maxLevel, firstFit, '--', [0:maxLevel]/maxLevel, secondFit, '-.'); %#ok<NBRAK>
    end
end

% format all the axes
xTick = 0:0.5:1;
xTickLabels = [];
yTick = 0:0.5:1;
yTickLabels = [];
xTitle = [];
yTitle = [];
xlims = [-.15 1.15];
ylims = [-.15 1.15];
fig_axesFormat(NaN, xTick,xTickLabels, yTick,yTickLabels, xTitle,yTitle, xlims,ylims);

% add legend
hAxes = 1;
hDat = hDat;
datLabels = {'Measures', 'Gamma', 'Spline'};
legTitle = [];
loc = 'NorthWest';
fontSize = [];
markerSize = [];
hScale = [];
vScale = 1.2;
hLeg = fig_legend(hAxes, hDat,datLabels, legTitle, loc, fontSize,markerSize, hScale,vScale);
fig_nudge(hLeg, -0.01, 0);

% format the figure
xTitle = '\textbf{input luminance}';
yTitle = '\textbf{output luminance}';
mainTitle = [];
fontSize = 16;
fig_figFormat(hFig, xTitle,yTitle,mainTitle, fontSize);

% save
fig_save(hFig, 'calib_lattice', exportDir, exportFormat);

%%
hFig = fig_make([20 20], [1 1]);

for i = 1:size(vals,1)
    for j = 1:size(vals,2)
        valss = vals(i,j,:); valss = valss(:);
        
        %Spline interp fitting
        fittedmodel = fit(inputV',valss,'splineinterp');
        secondFit = fittedmodel([0:maxLevel]/maxLevel); %#ok<NBRAK>
        plot([0:maxLevel]/maxLevel, secondFit, '-.');
    end
end

valss = mean(mean(vals,1),2); valss = valss(:);
fittedmodel = fit(inputV',valss,'splineinterp');
secondFit = fittedmodel([0:maxLevel]/maxLevel); %#ok<NBRAK>
plot([0:maxLevel]/maxLevel, secondFit, 'k-', 'linewidth', 3);

% format all the axes
xTick = 0:0.25:1;
xTickLabels = [];
yTick = 0:0.25:1;
yTickLabels = [];
xTitle = [];
yTitle = [];
xlims = [-.15 1.15];
ylims = [-.15 1.15];
fig_axesFormat(NaN, xTick,xTickLabels, yTick,yTickLabels, xTitle,yTitle, xlims,ylims, 16);

% format the figure
xTitle = '\textbf{input luminance}';
yTitle = '\textbf{output luminance}';
mainTitle = [];
fontSize = 16;
fig_figFormat(hFig, xTitle,yTitle,mainTitle, fontSize);

% save
fig_save(hFig, 'calib_overlay', exportDir, exportFormat);

%%
figure()
x = valsRaw(:,:,8);
h = bar3(x)
for i = 1:length(h)
zdata = get(h(i),'Zdata');
set(h(i),'Cdata',zdata)
end



%% store data
gammaTable_ind = nan(size(vals,1),size(vals,2),256);
gammaTable_avg = nan(256,1);

for i = 1:size(vals,1)
    for j = 1:size(vals,2)
        
        valss = vals(i,j,:); valss = valss(:);
        
        fittedmodel = fit(inputV',valss,g);
        gammaTable1 = ((([0:maxLevel]'/maxLevel))).^(1/fittedmodel.g); %#ok<NBRAK>
    
        %Invert interpolation
        fittedmodel = fit(valss,inputV','splineinterp');
        gammaTable2 = fittedmodel([0:maxLevel]/maxLevel); %#ok<NBRAK>
        
        gammaTable_ind(i,j,:) = gammaTable1; % gammaTable2;
    end
end

valss = mean(mean(vals,1),2); valss = valss(:);
fittedmodel = fit(inputV',valss,g);
gammaTable1 = ((([0:maxLevel]'/maxLevel))).^(1/fittedmodel.g); %#ok<NBRAK>
fittedmodel = fit(inputV',valss,'splineinterp');
gammaTable2 = fittedmodel([0:maxLevel]/maxLevel); %#ok<NBRAK>
gammaTable_avg(:,1) = gammaTable1; % gammaTable2;

%% uncommented if running for real!
% save(sprintf('gammaTables-%s', datestr(now(),1)),'gammaTable_ind','gammaTable_avg')



%%


valssRaw = mean(mean(valsRaw,1),2); valssRaw = valssRaw(:);