function [inputV, vals, valsRaw, maxLevel] = CalibrateMonitorPhotometer_hacked(numMeasures, screenid, grid)
% [gammaTable1, gammaTable2, displayBaseline, displayRange. displayGamma, maxLevel ] = CalibrateMonitorPhotometer([numMeasures=9][, screenid=max])
%
% A simple calibration script for analog photometers.
%
% Use CalibrateMonSpd() if you want to do more fancy calibration with
% different types of photometers or special devices like Bits+ or DataPixx,
% assuming you know how to operate CalibrateMonSpd() that is...
%
% numMeasures (default: 9) readings are taken manually, and the readings
% are fit with a gamma function and piecewise cubic splines. numMeasures -
% 1 should be a power of 2, ideally (9, 17, 33, etc.). The corresponding
% linearized gamma tables (1 -> gamma, 2 -> splines) are returned, as well
% as the display baseline, display range in cd/m^2 and display gamma. Plots
% of the two fits are created as well. Requires fit tools.
%
% If the normalized gamma table is not loaded, then the cd/m^2 value of a
% screen value can be figured out by the formula: cdm2 =
% displayRange*(screenval/maxLevel).^(1/displayGamma) + displayBaseline.
%
% Generally, you will want to load the normalized gamma tables and use them
% in Screen('LoadNormalizedGammaTable'). For example:
%
% [gammaTable1, gammaTable2] = CalibrateMonitorPhotometer;
% %Look at the outputted graphs to see which one gives a better fit
% %Then save the corresponding gamma table for later use
% gammaTable = gammaTable1;
% save MyGammaTable gammaTable
% 
% %Then when you're ready to use the gamma table:
% load MyGammaTable
% Screen('LoadNormalizedGammaTable', win, gammaTable*[1 1 1]);
%
%
% History:
% Version 1.0: Patrick Mineault (patrick.mineault@gmail.com)
% 22.10.2010 mk Switch numeric input from use of input() to use of
%               GetNumber(). Restore gamma table after measurement. Make
%               more robust.
% 19.08.2012 mk Some cleanup.
%  4.09.2012 mk Use Screen('ColorRange') to adapt number/max of intensity
%               level to given range of framebuffer.

    if (nargin < 1) || isempty(numMeasures)
        numMeasures = 9;
    end

    sprintf(['When black screen appears, point photometer, \n' ...
           'get reading in cd/m^2, input reading using numpad and press enter. \n' ...
           'A screen of higher luminance will be shown. Repeat %d times. '], numMeasures);
       
    psychlasterror('reset');    
    try
        if nargin < 2 || isempty(screenid)
            % Open black window on default screen:
            screenid = max(Screen('Screens'));
        end
        
        % Open black window:
        [win,rect] = Screen('OpenWindow', screenid, 0);
        maxLevel = Screen('ColorRange', win);

        % draw lines and wait for space
        [mx,my] = RectCenter(rect);
       	[w,h] = RectSize(rect);
        %
        hlines = linspace(0,h,grid(1)+1);
        hlines(end) = [];
        hlines = hlines + diff(hlines(1:2))/2;
        hlines = [hlines; hlines]; hlines = hlines(:);
        hlines = [zeros(size(hlines)) hlines]';
        hlines(1,2:2:end) = w;
        Screen('DrawLines', win, hlines, 2, [0 200 0]);
        %
        vlines = linspace(0,w,grid(2)+1);
        vlines(end) = [];
        vlines = vlines + diff(vlines(1:2))/2;
        vlines = [vlines; vlines]; vlines = vlines(:);
        vlines = [vlines zeros(size(vlines))]';
        vlines(2,2:2:end) = h;
        Screen('DrawLines', win, vlines, 2, [0 200 0]);
        %
        Screen('Flip', win);
        KbWait

        % Load identity gamma table for calibration:
        LoadIdentityClut(win);

        vals = [];
        inputV = [0:(maxLevel+1)/(numMeasures - 1):(maxLevel+1)]; %#ok<NBRAK>
        inputV(end) = maxLevel;
        for i = inputV
            Screen('FillRect',win,i);
            Screen('Flip',win);

%             fprintf('Value? ');
%             resp = GetNumber;
%             fprintf('%1.2f\n', resp);
            
            resp = getRealInput(sprintf('%4.2f Value? ', i))
            vals = [vals resp]; %#ok<AGROW>
        end
        
        % Restore normal gamma table and close down:
        RestoreCluts;
        Screen('CloseAll');
    catch %#ok<*CTCH>
        RestoreCluts;
        Screen('CloseAll');
        psychrethrow(psychlasterror);
    end

    displayRange = range(vals);
    displayBaseline = min(vals);
    
    %Normalize values
    valsRaw = vals;
    vals = (vals - displayBaseline) / displayRange;
    inputV = inputV/maxLevel;
    
return;
