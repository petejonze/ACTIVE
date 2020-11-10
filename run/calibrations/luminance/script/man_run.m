clear all
close all
clearJavaMem();
KbName('UnifyKeyNames')
if IsWin() 
    ShowHideWinTaskbairMex(0)
end
tic();
 
nMeasures = 13;
vals = nan(4,5,nMeasures);
valsRaw = vals;
%% Get data

for i = 1:size(vals,1)
    for j = 1:size(vals,2)
        %fprintf('\n\n [%i, %i]\n',i,j);
        [inputV, vals(i,j,:), valsRaw(i,j,:), maxLevel] = CalibrateMonitorPhotometer_hacked(nMeasures, 1, size(vals)) %#ok
        % fn = sprintf('gammaTables-%i-%i-%s', 1, 2, datestr(now(),1));
        save(sprintf('rawMeasures-%s', datestr(now(),1)),'inputV','vals','valsRaw','maxLevel')
        clearJavaMem();
    end
end

%% 2nd run

% vals_tmp = vals
% valsRaw_tmp = valsRaw
% 
% for i = 1:size(vals,1)
%     for j = 1:size(vals,2)
%         vals(i,j,:) = vals_tmp(5-i,6-j,:);
%         valsRaw(i,j,:) = valsRaw_tmp(5-i,6-j,:);
%     end
% end
% save(sprintf('rawMeasures-%s', datestr(now(),1)),'inputV','vals','valsRaw','maxLevel')

%% Finish up

if IsWin() 
    ShowHideWinTaskbairMex(1)
end