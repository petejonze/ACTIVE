function [blockFns] = acuityNew_v0_0_1(metaParams, basicParams, graphicParams, trialParams, graphicStimParams, audioStimParams, psychophysParams)
% acuityNew_v1 gaze-ctoningent test of resolution acuity
%
%   Tries to find the minimum spatial frequency threshold (cycles/degree) for a given
%   contrast (0 - 1) level, using an adaptive psychophysical procedure
%
% @Requires:        PsychToolBox 3
%                   PsychTestRig
%                   ivis toolbox v1.6
%
% @Matlab:          v2012 onwards
%
% @Author(s):    	Pete R Jones <petejonze@gmail.com>
%
% @Version History: 0.0.1	PJ  10/03/2018	Initial build based on acuity_v3b.m
%
%   
% Copyright 2018 : P R Jones <petejonze@gmail.com>
% *********************************************************************
%

    %%%%%%%
    %% 0 %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% VERY BASIC INIT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
        fprintf('\nSetting up the basics...\n');
        
        %-------------Check OS/Matlab version------------------------------
        if ~strcmpi(computer(),'PCWIN64')
            error('This code has only been tested on Windows 7 running 64-bit Matlab\n  Detected architecture: %s', computer());
        end
        
       	%-------------Ready workspace-------------------------------------- 
        tmp = javaclasspath('-dynamic');
        clearJavaMem();
        close all;
        if length(tmp) ~= length(javaclasspath('-dynamic'))
            % MATLAB calls the clear java command whenever you change
            % the dynamic path. This command clears the definitions of
            % all Java classes defined by files on the dynamic class
            % path, removes all variables from the base workspace, and
            % removes all compiled scripts, functions, and
            % MEX-functions from memory.
            error('clearJavaMem:MemoryCleared','clearJavaMem has modified the java classpath (any items in memory will have been cleared)\nWill abort, since this is highly likely to lead to errors later.\nTry running again, or see ''help PsychJavaTrouble'' for a more permenant solution\n\ntl;dr: Try running again.\n\nFYI: the solution, in short is to open up the matlab classpath.txt file, and manually add the necessary locations. For example, for me I opened up:\n\n  %s\n\nand at the end of the file I added these two lines:\n\n  %s\n  %s\n\nand then I restarted Matlab\n\n\ntl;dr: try running script again (or edit classpath.txt).', 'C:\Program Files\MATLAB\R2016b\toolbox\local', 'C:\Users\petej\Dropbox\MatlabToolkits\Psychtoolbox\PsychJava', 'C:\Users\petej\Dropbox\MatlabToolkits\PsychTestRig\Utilities\memory\MatlabGarbageCollector.jar');
        end

        %-------------Check for requisite toolkits-------------------------
        AssertOpenGL();                         % ensure PTB-3 correctly installed; abort otherwise
        AssertPTR();                            % ensure PsychTestRig correctly installed; abort otherwise
        ivis.main.IvMain.assertVersion(1.6);    % ensure ivis correctly installed; abort otherwise

        %-------------Clear old memory-------------------------------------
        clear myex
        
        %-------------Check classpath--------------------------------------
        ivis.main.IvMain.checkClassPath();

        %-------------Hardcoded User params--------------------------------  
        IN_DEBUG_MODE       = false %#ok
        IN_SIMULATION_MODE  = false %#ok
        IN_FINAL_MODE       = true %#ok
        DRAW_FIX_CROSS      = true %#ok
        % media files
        RESOURCES_DIR   = fullfile('..', 'resources');
        SND_DIR         = fullfile(RESOURCES_DIR, 'audio', 'wav');
        IMG_DIR         = fullfile(RESOURCES_DIR, 'images');
        % data logs
        LOG_RAW_DIR     = fullfile('..', '..', 'data', '__EYETRACKING', 'raw');
        LOG_DAT_DIR     = fullfile('..', '..', 'data', '__EYETRACKING', 'data');
        % misc
        samplingRate_hz = 55;
        N_CALIB_SAMPLES_PER_LOC = 20;
        
        %-------------Validate-------%%%%%%
        if IN_DEBUG_MODE && IN_FINAL_MODE
            error('Inconsistent user inputs. Cannot be in DEBUG mode if in FINAL mode');
        end
        if IN_SIMULATION_MODE && IN_FINAL_MODE
            error('Inconsistent user inputs. Cannot be in SIMULATE mode if in FINAL mode');
        end
        
        %-------------Add any requisite paths------------------------------ 
        import ivis.main.* ivis.classifier.* ivis.broadcaster.* ivis.math.* ivis.graphic.* ivis.audio.* ivis.log.* ivis.calibration.*;
        import visfield.graphic.* visfield.math.* visfield.jest.*

        %-------------Display key params to user---------------------------
        dispStruct(metaParams)

        
    %%%%%%%
    %% 1 %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% VALIDATE INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        fprintf('\nVaidating inputs...\n');
    
        %-------------basicParams------------------------------------------
        p = inputParser;
        p.addParameter('introText',              @ischar);
        p.addParameter('blockIntroText',      	@ischar);
        p.addParameter('debriefText',            @ischar);
        p.addParameter('debugMode',              @islogical);
        p.addParameter('nBlocks',                @isPositiveInt);
        p.addParameter('breakAfterBlock',        @(x)isempty(x) | all(isPositiveInt(x)) );
        p.addParameter('giveEndOfBlockFeedback', @islogical);
        p.addParameter('videoAfterNTrials',   	@isPositiveInt);
        p.addParameter('nSecsRqdToBreakVid',   	@isPositiveNum);
        p.addParameter('minVidTime',   	@isPositiveNum); % must play video for at least this time (seconds)
        p.addParameter('classifierType',   	@(x)ismember(lower(x), {'box','ll'}) );
        p.addParameter('config',	@ischar);
        p.parse(basicParams);
        
        %-------------graphicParams----------------------------------------
        p = inputParser;
        p.addParameter('targFrameRate',   	@isPositiveInt);
        p.addParameter('testScreenNum',    	@isNonNegativeInt);
        p.addParameter('fullScreen',     	@islogical);
        p.addParameter('testScreenWidth', 	@isPositiveInt);
        p.addParameter('testScreenHeight',	@isPositiveInt);
        p.addParameter('viewDist_cm',       @isPositiveNum);
        p.addParameter('monitorWidth_cm',   @isPositiveNum);
        p.addParameter('maxFreq_cpd',       @isPositiveNum);
        p.parse(graphicParams);
        
        %-------------trialParams------------------------------------------
        p = inputParser;
        p.addParameter('d',             @isPositiveNum);
        p.addParameter('PreSI',         @isNonNegativeNum);
        p.addParameter('PostSI',     	@isNonNegativeNum);
        p.addParameter('giveCue',     	@islogical);
        p.addParameter('giveFeedback',	@islogical);
        p.parse(trialParams);
        
        %-------------graphicStimParams------------------------------------
        p = inputParser;
        p.addParameter('res',            @(x)length(x)==2 && all(isPositiveInt(x)));
        p.addParameter('phase',          @isNonNegativeNum);
        p.addParameter('sc',             @isPositiveNum);
        p.addParameter('contrast',       @isPositiveNum);
        p.addParameter('rotAngle',       @isnumeric);
        p.addParameter('scale');
        p.addParameter('maxVelocity',          @isNonNegativeInt);
        p.addParameter('maxRotationVelocity', 	@isNonNegativeInt);
        p.addParameter('nPoints',          @isPositiveInt);
        p.addParameter('screenMargin', 	 @isNonNegativeNum);
        p.addParameter('minDistFromPrev', 	 @isNonNegativeNum);
        p.addParameter('maxDistFromPrev', 	 @isNonNegativeNum);
        p.parse(graphicStimParams);
        
        %-------------audioStimParams--------------------------------------
        p = inputParser;
        p.addParameter('Fs',      	@isPositiveInt);
        p.addParameter('wd',     	@isNonNegativeNum);
        p.addParameter('cf',       	@isPositiveNum);
        p.addParameter('dbSPL',   	@isPositiveNum);
        p.addParameter('wav_dbSPL',	@isPositiveNum);
        p.addParameter('testChans',	@(x)all(isNonNegativeInt(x)));
        p.addParameter('debugLevel',	@isNonNegativeInt);%
        p.parse(audioStimParams);
        
        %-------------psychophysParams-------------------------------------
        p = inputParser;
        p.addParameter('startVal', 	@isnumeric);
        p.addParameter('stepSize',  	@(x)all(isnumeric(x)));
        p.addParameter('downMod',  	@(x)all(isnumeric(x)));
        p.addParameter('nReversals',	@(x)all(isPositiveInt(x)));
        p.addParameter('nUp',       	@isPositiveInt);
        p.addParameter('nDown',   	@isPositiveInt);
        p.addParameter('isAbsolute',	@islogical);
        p.addParameter('minVal',  	@isnumeric);
        p.addParameter('maxVal',    	@isnumeric);
        p.addParameter('maxNTrials',	@isPositiveInt);
        p.addParameter('verbosity', 	@isNonNegativeInt);
        p.parse(psychophysParams);

            
    %%%%%%%%
    %% 0b %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Additional Validation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    

        % replace default save params with dynamic values describing the current
        % participant
        rawParams = xmlRead(inputParams.config);
        rawParams.eyetracker.rawLog.dir = '$iv/logs/raw';
        rawParams.eyetracker.rawLog.filename = sprintf('IvRaw-%s-%i-%i-$time.raw', metaParams.expID, metaParams.partID, metaParams.sessID);
        rawParams.dataLog.dir = '$iv/logs/data';
        rawParams.dataLog.filename = 'to be set trial-by-trial'; % sprintf('IvData-%s-%i-%i-$time.csv', metaParams.expID, metaParams.partID, metaParams.sessID);

        rawParams.graphics.fullScreen = graphicParams.fullScreen;
        rawParams.graphics.testScreenNum = graphicParams.testScreenNum;
        rawParams.graphics.testScreenWidth = graphicParams.testScreenWidth;
        rawParams.graphics.testScreenHeight = graphicParams.testScreenHeight;
        rawParams.graphics.viewDist_cm = graphicParams.viewDist_cm;
        rawParams.graphics.monitorWidth_cm = graphicParams.monitorWidth_cm;
        rawParams.graphics.monitorHeight_cm = graphicParams.monitorHeight_cm;
        rawParams.graphics.targFrameRate = graphicParams.targFrameRate;

        
        % init movement handler params
        sigma = graphicStimParams.scale*sqrt(2)*graphicStimParams.res(1); % hack?
        %
        x0 = 0;
        x1 = graphicParams.testScreenWidth;
        y0 = 0;
        y1 = graphicParams.testScreenHeight;
        %
        b = [x0 x1 y0 y1];
        %
        xmargin = graphicStimParams.screenMargin*graphicParams.testScreenWidth;
        ymargin = graphicStimParams.screenMargin*graphicParams.testScreenHeight;
        x0 = (x0 + xmargin) + graphicStimParams.sc; % graphicStimParams.res(1); % sigma;
        x1 = (x1 - xmargin) - graphicStimParams.sc; % sigma;
        y0 = (y0 + ymargin) + graphicStimParams.sc; % sigma;
        y1 = (y1 - ymargin) - graphicStimParams.sc; % sigma;

        IvMain.assertVersion(1.4);
        IvMain.initialise(rawParams);
    
    %%%%%%%%
    %% 0b %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Additional Validation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
 
        % From bounce_mess8
        monitorWidth_cm = graphicParams.monitorWidth_cm % e.g. 59.5
        screenWidth_px = graphicParams.testScreenWidth % e.g. 1920
        viewDist_cm = graphicParams.viewDist_cm % e.g. 115
        %
        pixel_per_cm = screenWidth_px/monitorWidth_cm
        screenWidth_dg = 2*rad2deg(atan(monitorWidth_cm/(2*viewDist_cm)))
        pixel_per_dg = screenWidth_px/screenWidth_dg
        maxFreq_cpd = pixel_per_dg/2 % cycles per degree


        if truncDec(maxFreq_cpd,2) ~= truncDec(graphicParams.maxFreq_cpd,2)
            error('acuity_simple_main_v3:InvalidInput','Calculated max freq (%1.3f) does not match the max freq specified in the calibration (%1.3f) [cycles per degree]',maxFreq_cpd,graphicParams.maxFreq_cpd);
        end

        % compute further BOUNCE params
        if graphicStimParams.nPoints ~= length(graphicStimParams.scale)
            error('a:b','c');
        end
        rotAngles = ones(1, graphicStimParams.nPoints) * graphicStimParams.rotAngle; % rotation angles (in degrees: 0-360) gammaTable2
        scales = repmat(graphicStimParams.scale,1,graphicStimParams.nPoints);

    
    %%%%%%%%
    %% 0c %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Calc stim params %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    
        % pixel_per_dg  = 92.8195

        cpp = linspace(0,.5,18); % (could manually choose lower starting point potentially)
        cpp(1) = []
        cpp =  logspace(log10(0.01),log10(.5),12)

        ppc = unique(round(1./cpp))
        ppc(ppc < 4) = [] % exclude any where fewer than 2 pixels per band (i.e. 4 per cycle)
        cpp = 1./ppc
        cpd = cpp .* pixel_per_dg
        
        [~,adaptParams.startVal] = min(abs(cpd-adaptParams.startVal))

        adaptParams.minVal = 0; % allow blank
        adaptParams.maxVal = length(cpd);


    %when working with the PTB it is a good idea to enclose the whole body of your program
    %in a try ... catch ... end construct. This will often prevent you from getting stuck
    %in the PTB full screen mode
    try
   
        %%%%%%%
        %% 1 %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Init input %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Go!
            [eyetracker, winhandle, InH, params] = IvMain.launch();
            
            % Enable alpha-blending, set it to a blend equation useable for linear
            % superposition with alpha-weighted source. This allows to linearly
            % superimpose gabor patches in the mathematically correct manner,
            % should they overlap. Alpha-weighted source means: The 'globalAlpha'
            % parameter in the 'DrawTextures' can be used to modulate the intensity
            % of each pixel of the drawn patch before it is superimposed to the
            % framebuffer image, ie., it allows to specify a global per-patch
            % contrast value:
            Screen('BlendFunction', winhandle, GL_ONE, GL_ONE);
            
            % Gamma-adjustment (linearisation) [will be updated
            % frame-by-frame, below]
            load(fullfile('../calibrations/gamma/', graphicParams.gammaConfig)); % gammaTables-15-Jul-2013.mat; % gammaTables-08-Jul-2013.mat;
            gammaTable = gammaTable_avg;
            gamma_nRows = size(gammaTable_ind,1);
            gamma_nCols = size(gammaTable_ind,2);
            Screen('LoadNormalizedGammaTable', winhandle, gammaTable*[1 1 1],1);

        %%%%%%%
        %% 2 %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Load Resources %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            %% LOAD SOUNDS
            calib = ivis.audio.IvAudio.getInstance().calib;
            outChans = ivis.audio.IvAudio.getInstance().outChans;
            devID = ivis.audio.IvAudio.getInstance().devID;
            devName = ivis.audio.IvAudio.getInstance().devName;
            headID = ivis.audio.IvAudio.getInstance().headID;
            
            % estimate appropriate level (just use the 1 kHz calibration)
            wavRMS = calib_getTargRMS(calib, audioStimParams.wav_dbSPL, audioStimParams.testChans, 1000, [], devID, devName, headID);

            % load audio
            correctSound = wavread(char(fullfile(ivis.main.IvParams.getInstance().toolboxHomedir,'resources','audio','wav','good.wav')));
            correctSound = calib_setRMS(correctSound', wavRMS );
            incorrectSound = wavread(char(fullfile(ivis.main.IvParams.getInstance().toolboxHomedir,'resources','audio','wav','bad.wav')));
            incorrectSound = calib_setRMS(incorrectSound', wavRMS );
            endOfGameSound = wavread(char('../resources/audio/wav/yaaaay_mixdown.wav'));
            endOfGameSound = calib_setRMS(endOfGameSound', wavRMS ); %transpose to make compatible with psychportaudio (later) and set volume [i.e. portaudio expects row vectors, but wav is read in as columns]
            endOfGameSound = endOfGameSound * .05; % too loud!
            %
            nurseryRhymes = IvAudio.loadAll(fullfile(ivis.main.IvParams.getInstance().toolboxHomedir,'resources','audio','nurseryrhymes'));
            nNurseryRhymes = length(nurseryRhymes);
            %
            xylophone = IvAudio.wavload('../resources/audio/wav/173881__toam__xylophon-play-melody-c3-loop.wav');
            
            
    
            %% SYNTH SOUNDS
            cue_tone = getPureTone(audioStimParams.cf,audioStimParams.Fs,trialParams.PreSI,.01, calib, 70, audioStimParams.testChans);
            cue_tone = padChannels(cue_tone, audioStimParams.testChans, outChans); %#ok
            
            %% LOAD IMAGES
            [visFeedbackImage_correct, ~, alpha] = imread('../resources/images/feedback/500px-Happy_face.svg.png','png');
            visFeedbackImage_correct(:,:,4) = alpha(:,:); % add the transparency layer to the image (for trans. back.)
            visFeedbackTexture_correct=Screen('MakeTexture', winhandle, visFeedbackImage_correct);
            faceRect = [0, 0, size(alpha,2), size(alpha,1)];
            %
            [visFeedbackImage_incorrect, ~, alpha] = imread('../resources/images/feedback/500px-Sad_face.svg.png','png');
            visFeedbackImage_incorrect(:,:,4) = alpha(:,:); % add the transparency layer to the image (for trans. back.)
            visFeedbackTexture_incorrect=Screen('MakeTexture', winhandle, visFeedbackImage_incorrect);
            %
            [awesomeFaceImage, ~, alpha] = imread('../resources/images/feedback/600px-Happy_smiley_face.png','png');
            awesomeFaceImage = awesomeFaceImage + 180; % uniformly bleach the image
            awesomeFaceImage(:,:,4) = alpha(:,:); % add the transparency layer to the image (for trans. back.)
            awesomeFaceTexture=Screen('MakeTexture', winhandle, awesomeFaceImage);
            %
            % load each 'break' sprite data to cell array
            breakImageFiles = getFiles('../resources/images/breakscreen/*.png',true);
            breakImages = cell(1,length(breakImageFiles));
            breakTextures = cell(1,length(breakImageFiles));
            for j=1:length(breakImageFiles)
                [breakImage, ~, alpha] = imread(['../resources/images/breakscreen/' breakImageFiles{j}],'png');
                breakImage(:,:,4) = alpha(:,:); % add the transparency layer to the image (for trans. back.)
                breakImages{j} = breakImage;
                breakTextures{j} = Screen('MakeTexture', winhandle, breakImage);
            end
            % check
            if isempty(breakImages)
                ME = MException('Initialise:NoBreakscreenSprites', 'No breakscreen images found'); throw(ME);
            end

            %% SYNTH IMAGES
            FixCrossImage=ones(32,32,4)*0; % make a gray canvas. (useful to be a power of two)
            FixCrossImage(16:17,:,1:3)=params.graphics.gray; % draw a black cross
            FixCrossImage(:,16:17,1:3)=params.graphics.gray;
            FixCrossImage(:,:,4) = 0; % add the transparency layer
            FixCrossTexture = Screen('MakeTexture', winhandle, FixCrossImage); % convert image matrix to texture
            %
            %cueImage = FixCrossImage;
            cueTexture = FixCrossTexture;
            
            % Build a procedural gabor texture for a gabor with a support of tw x
            % th pixels and the 'nonsymetric' flag set to 0 to force only symmetric
            % aspect ratios. Since the texture is procedurally generated, the
            % precise parameters can be set dynamically at runtime (i..e during
            % the call to DrawTexture)
            tw = graphicStimParams.res(1);
            th = graphicStimParams.res(2);
            nonSymmetric = 0;
            backgroundColorOffset = [];
            disableNorm = 1;
            contrastPreMultiplicator = 0.5;
            gabortex = CreateProceduralGabor(params.graphics.winhandle, tw, th, nonSymmetric, backgroundColorOffset, disableNorm, contrastPreMultiplicator);
            gaborRect = Screen('Rect', gabortex);
            inrect = repmat(gaborRect', 1, graphicStimParams.nPoints);
   
            % calc potential positions (for static keyboard version)
            texrect = Screen('Rect', gabortex);
            x = [.4 .6] * params.graphics.testScreenWidth;
            y = [.5 .5] * params.graphics.testScreenHeight; 
            dstRects = {CenterRectOnPoint(texrect, x(1), y(1)), CenterRectOnPoint(texrect, x(2), y(2))};
                   
            % Draw the gabor once, just to make sure the gfx-hardware is ready for
            % the benchmark run below and doesn't do one time setup work inside the
            % benchmark loop. The flag 'kPsychDontDoRotation' tells 'DrawTexture'
            % not to apply its built-in texture rotation code for rotation, but
            % just pass the rotation angle to the 'gabortex' shader -- it will
            % implement its own rotation code, optimized for its purpose.
            % Additional stimulus parameters like phase, sc, etc. are passed as
            % 'auxParameters' vector to 'DrawTexture', this vector is just passed
            % along to the shader. For technical reasons this vector must always
            % contain a multiple of 4 elements, so we pad with three zero elements
            % at the end to get 8 elements. Aspect ratio is set to 1, but this
            % parameter will be ignored anyway, since nonSymmetric set false
            % above.
            % n.b. http://tech.groups.yahoo.com/group/psychtoolbox/message/9174
            freq_cpp = 10; % arbitrary value (cycles/pixel)
            Screen('DrawTexture', winhandle, gabortex, [], dstRects{1}, [], [], [], [], [], kPsychDontDoRotation, [graphicStimParams.phase, freq_cpp, graphicStimParams.sc, graphicStimParams.contrast, 1, 0, 0, 0]);
            Screen('Flip', winhandle, 0,0); % Flip
            Screen('Flip', winhandle, 0,0); % Clear
       
            %% MOVIES
            %IvVideo.getInstance().open('../resources/video/Waybuloo Adventures in Nara (2009) DVDRip Xvid - EMU.avi');
            IvVideo.getInstance().open('../resources/video/In.The.Night.Garden.All.Together [2010] Dvdrip - PRESTiGE.- Sample.avi');
			
            
            
        %%%%%%%
        %% 3 %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% RUN EXPERIMENT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        
        % init 
        blockFns = cell(basicParams.nBlocks, 1);
        HideCursor();
        KbWait([], 2);
        
        % Iterate through each block
        for bid = 1:basicParams.nBlocks
            fprintf('\n\nCOMMENCING BLOCK %i ...\n', bid);
            Screen('FillRect', winhandle , params.graphics.gray); % gray background

            %% initialise new staircase-object (OOP) %%%%%%%%%%%%%%%%%%%%%%
            aT = AdaptiveTrack(adaptParams);
            ivis.gui.IvGUI.getInstance().addFigureToPanel(aT.figHandles.hFig, 6);         

            
            %% Issue instructions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    

            % 1D classifier, for calibration
            myGraphic = IvGraphic('target', visFeedbackTexture_correct, 0, 0, faceRect(3)/2, faceRect(4)/2, winhandle); %/2 hack
            lmag = params.eyetracker.objectClassification.loglikelihood.lMagThresh;
            myClassifier = IvClassifierLL('1D', {IvPrior(), myGraphic},[lmag lmag*5]);
            
            % calculate stimulus placements
            minDist_px = ivis.data.IvUnitHandler.getInstance().deg2px(graphicStimParams.minDistFromPrev);
            maxDist_px = ivis.data.IvUnitHandler.getInstance().deg2px(graphicStimParams.maxDistFromPrev);
            
            % initial trackbox
            IvAudio.playNow(nurseryRhymes{randi(nNurseryRhymes)}*.005, false);
            Screen('BlendFunction', winhandle, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            TrackBox.getInstance();
            IvAudio.stop();
            
            % Run calib pre-trial(s) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            while 1
                
                TrackBox.getInstance().toggle();
                IvVideo.getInstance().play(true);
                % wait for click or timeout
                fprintf('\n');
                isReadyToGo = false;
                lookStartTime = GetSecs();
                isSkipped = false;
                while 1
                    % check for input
                    switch first(InH.getInput())
                        case InH.INPT_SPACE.code
                            isReadyToGo = true;
                        case InH.INPT_SKIP.code
                            isSkipped = true;
                            break
                    end
                    % start automatically once the infant is looking at the screen
                    if any(isnan(eyetracker.getLastKnownXY()))
                        lookStartTime = GetSecs(); % reset
                    elseif isReadyToGo && ((GetSecs()-lookStartTime) > basicParams.nSecsRqdToBreakVid)
                        break
                    end
                    % update
                    eyetracker.refresh(false); % false to supress logging
                    IvFlip(winhandle);
                    WaitSecs(.01);
                end
                if isSkipped
                    break;
                end
                TrackBox.getInstance().toggle();
                IvVideo.getInstance().stop();
                
                % PRESENT IN MIDDLE<<<<<<<<<<
                x = params.graphics.mx;
                y = params.graphics.my;
                myGraphic.reinitXY(x, y);
                
                % flush eyetracker
                eyetracker.flush();
                IvDataLog.getInstance().reset();
                
                % run until decision (or timeout)
                startTime = myClassifier.start();
                eyetracker.flush();
                Screen('BlendFunction', params.graphics.winhandle, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                xyAtClassification = [];
                IvAudio.playNow(xylophone, false);
                d = 4; % N seconds max
                T_scale = getTween(.4, .6, d, params.graphics.Fr, 'sin', 2);
                T_sway = getTween(-20, 20, d, params.graphics.Fr, 'sin', 4);
                jobDone = false;
                for i = 1:length(T_sway)
                    
                    InH.getInput();
                    
                    dstRect = CenterRectOnPointd(faceRect*T_scale(i), x, y);
                    Screen('DrawTexture', params.graphics.winhandle, visFeedbackTexture_correct, faceRect, dstRect, T_sway(i));
                    Screen('Flip', params.graphics.winhandle);
                    
                    n = eyetracker.refresh(true); % false to supress logging
                    
                    if n > 0 % update classifier
                        myClassifier.update();
                        if ~jobDone && ~myClassifier.isUndecided() % see if reached decision
                            responseLatency = GetSecs() - startTime;
                            xyAtClassification = eyetracker.getLastKnownXY(); % Use RAW rather than buffered
                            jobDone = true;
                            % if responseLatency > basicParams.minVidTime
                            break;
                            % end
                        end
                    end
                    
                    WaitSecs(params.graphics.ifi);
                end
                
                if isempty(xyAtClassification)
                    continue % restart trial (Aborted?)
                end
                
                resp = myClassifier.interogate().name;
                anscorrect = strcmpi(resp, 'target');
                
                if anscorrect
                    fprintf('Hit:  ');
                    % update drift correction
                    trueXY = [x y];
                    estXY = xyAtClassification; % eyetracker.lastXY(); % ivis.data.IvDataLog.getInstance().getLastN(1, 1:2);
                    eyetracker.updateDriftCorrectionFactor(trueXY, estXY, 99);
                    break
                else
                    fprintf('Miss\n');
                end
            end
            
            
            delete(myClassifier)
            % initialise the classifier to be used throughout testing
            if strcmpi(basicParams.classifierType, 'll')
                myGraphic = IvGraphic('target', [], [], [], [], [], IvHfGUmix2D([0 0], [135 155], .95, false), winhandle);
                myPrior = IvPrior(IvHfUniform2D());
                lmag = params.eyetracker.objectClassification.loglikelihood.lMagThresh;
                myClassifier = IvClassifierLL({myPrior, myGraphic},[],[lmag*2 lmag]);
            elseif strcmpi(basicParams.classifierType, 'box')
                myGraphic = IvGraphic('target', [], 0, 0, graphicStimParams.sc*3, graphicStimParams.sc*3, [], winhandle);
                myClassifier = IvClassifierBox(myGraphic);
            else
                error('unknown classifier type: %s', basicParams.classifierType);
            end
                
% myClassifier.show();
            %% Iterate through trials %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            trialNum = 0;
            while ~aT.isFinished() % more trials yet to go
                
                trialNum = trialNum + 1;
                % get variables
                trackStage = aT.getCurrentStage();
                step = aT.getDelta();
                if step > 0
                    freq_cpp = cpp(step); % cycles per pixel (for stim gen)
                    freq_ppc = ppc(step); %pixels per cycle (for stim gen sanity check)
                    freq_cpd = cpd(step); % cycle-per-degee (for reporting)
                    
                    % validate
                    if ~isPositiveInt(freq_ppc)
                        error('acuity:invalidPPC','pixels per cycle not a whole number?! (%1.5f)', freq_ppc);
                    end
                else
                    freq_cpp = 0;
                    freq_ppc = 0;
                    freq_cpd = 0;
                end

                fprintf('%i   =>  %1.3f (%1.3f) [%i]     ', step,freq_cpd,freq_cpp,freq_ppc)

                % init
                logFn = sprintf('IvData-%s-%i-%i-%i-%s.csv', metaParams.expID, metaParams.partID, metaParams.sessID, trialNum, datestr(now,30));
                
                % PLAY VIDEO BEFORE EVERY N TRIALS %%%%%%%%%%%%%%
                if 0 == mod(trialNum-1, basicParams.videoAfterNTrials)
%                     TrackBox.getInstance().toggle();
                    IvVideo.getInstance().play(true);
                    
                    % wait for click or timeout
                    videoStartTime = GetSecs();
                    lookStartTime = GetSecs();
                    while 1
                        switch first(InH.getInput())
                            case InH.INPT_SKIP.code
                                break
                        end
                        % start automatically once the infant is looking at the screen
                        if any(isnan(eyetracker.getLastKnownXY()))
                            lookStartTime = GetSecs(); % reset
                        else
                            if (((GetSecs()-lookStartTime) > basicParams.nSecsRqdToBreakVid) ...
                                    && ((GetSecs()-videoStartTime) > basicParams.minVidTime) )
                                break
                            end
                        end
                        eyetracker.refresh(false); % false to supress logging
                        IvFlip(winhandle);
                        WaitSecs(.01);
                    end
                    
%                     TrackBox.getInstance().toggle();
                    IvVideo.getInstance().stop();
                end
                
                % START TRIALS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                IvAudio.playNow(nurseryRhymes{randi(nNurseryRhymes)}, false);
                
                % init position
                counter = 0;
                eyetracker.refresh(false);
                [prevXY, t] = eyetracker.getLastKnownXY(false); % TRUE WAS WRONG??
                if (t-GetSecs()) > .5 || any(isnan(prevXY)) % PJ: should this really have been ||?
                    prevXY = [params.graphics.mx params.graphics.my]; % if can't detect
                    fprintf('\n\nNo previous position could be found, so assuming last feedback point\n\n'); % PJ: actually in middle?
                end
                while 1
                    
                    
                    % get random angle
                    theta = rand()*2*pi;
                    
                    % get random distance
                    r = minDist_px + (maxDist_px-minDist_px).*rand(graphicStimParams.nPoints,1);
                    
                    % convert to cartesian coordinates
                    [dx,dy] = pol2cart(theta,r);
                    
                    % calculate new position by adding the randomly
                    % generated vector to the last known fixation point
                    x = prevXY(1) + dx;
                    y = prevXY(2) + dy;
                    
                    % check if valid
                    if x > x0 && y > y0 && x < x1 && y < y1   
                        break;
                    end

                    counter = counter + 1;
                    if counter > 70
                        fprintf('\n\n\n\nWARNING: Failed to find an appropriate location for the new stimulus\n\n\n');
                        x = params.graphics.mx;
                        y = params.graphics.my;                       
                        break;
                    %error('a:b','c');
                    end
                end
                myGraphic.reinitXY(x, y);
                
                zi = (1:256)';
                if graphicStimParams.maxVelocity == 0
                    gammaTable = interpne(gammaTable_ind, [repmat([gamma_nCols*x/params.graphics.testScreenWidth gamma_nRows*y/params.graphics.testScreenHeight],256,1),zi]);
                    Screen('LoadNormalizedGammaTable', winhandle, gammaTable*[1 1 1], 1);
                    %
                else
                    % Init movement handler
                    s = 0; % init speed
                    v = (3-randi(2,[graphicStimParams.nPoints,1])*2) * graphicStimParams.maxVelocity/2 + graphicStimParams.maxVelocity*rand(graphicStimParams.nPoints,1);
                    u = (3-randi(2,[graphicStimParams.nPoints,1])*2) * graphicStimParams.maxVelocity/2 + graphicStimParams.maxVelocity*rand(graphicStimParams.nPoints,1);
                    m = ones(graphicStimParams.nPoints,1);
                    myLJP = LennardJonesPotential(x,y,v,u,m,b,sigma,params.graphics.ifi,[],graphicStimParams.maxVelocity);  
                end
                Screen('FillRect', winhandle , params.graphics.gray); % gray background
              
                % flush eyetracker
                eyetracker.flush();
                IvDataLog.getInstance().reset();
                
                % run until decision (or timeout)
                startTime = myClassifier.start();
                eyetracker.flush();
                Screen('BlendFunction', winhandle, GL_ONE, GL_ONE);
                xyAtClassification = [];
                while 1
                    
                    inpt = InH.getInput();
                    switch inpt(1) % take first (tmp hack)
                        case InH.INPT_RESTART.code
                            break; % break loop (and will subsequently restart trial)
                        case InH.INPT_BACK1.code
                            aT.goBackN(1);
                            break;
                        case InH.INPT_SKIP.code
                            aT.update(true);
                            break
                        case InH.INPT_FAIL.code
                            aT.update(false);
                            break
                    end

                    % update Position
                    if graphicStimParams.maxVelocity ~= 0 % else vars will never change, and may even run into division-by-zero errors
                        [x,y,s] = myLJP.calcNextTimestep();
                        gammaTable = interpne(gammaTable_ind, [repmat([gamma_nCols*x/params.graphics.testScreenWidth gamma_nRows*y/params.graphics.testScreenHeight],256,1),zi]);
                        Screen('LoadNormalizedGammaTable', winhandle, gammaTable*[1 1 1], 1);

                        myGraphic.setXY(x,y);
                    end
                    
                    % Recompute dstRects destination rectangles for each patch, given
                    % the 'per gabor' scale and new center location (x,y):
                    if graphicStimParams.nPoints == 1
                        r = (inrect .* repmat(scales,4,1))';
                    else
                        r = inrect .* repmat(scales,4,1);
                    end
                    dstRects = CenterRectOnPointd(r, x', y');        


                    % Compute new random orientation for each patch in next frame:
                    if graphicStimParams.maxRotationVelocity ~= 0 % else vars will never change, and may even run into division-by-zero errors
                        rotAngles = rotAngles+graphicStimParams.maxRotationVelocity*(s'/graphicStimParams.maxVelocity)/sqrt(2); % TODO: simplify
                    end
                    
                    if step > 0
                        Screen('DrawTexture', params.graphics.winhandle, gabortex, [], dstRects, rotAngles, [], [], [], [], kPsychDontDoRotation, [graphicStimParams.phase, freq_cpp, graphicStimParams.sc, graphicStimParams.contrast, 1, 0, 0, 0]);
                    end          
                    
                    % myClassifier.drawBoxes();
                    Screen('Flip', params.graphics.winhandle);
                    
                    n = eyetracker.refresh(true); % false to supress logging
                    
                    if n > 0 % update classifier
                        myClassifier.update();
                        if ~myClassifier.isUndecided() % see if reached decision
                            responseLatency = GetSecs() - startTime;
                            xyAtClassification = eyetracker.getLastKnownXY(); % use RAW rather than buffered. Why?
                            break
                        end
                    end
                    
                    WaitSecs(params.graphics.ifi);
                end
                
                if isempty(xyAtClassification)
                    continue % restart trial (Aborted?)
                end
                
                resp = myClassifier.interogate().name;
                anscorrect = strcmpi(resp, 'target');
                
                % give user feedback
                if anscorrect
                    fprintf('Hit:  ');
                    % update drift correction
                    trueXY = [x y];
                    estXY = xyAtClassification; % eyetracker.lastXY(); % ivis.data.IvDataLog.getInstance().getLastN(1, 1:2);
                    eyetracker.updateDriftCorrectionFactor(trueXY, estXY);
                    rectColour = [55 200 55];
                else
                    fprintf('Miss\n');
                    rectColour = [200 55 55];
                end
                
                % give feedback
                Screen('BlendFunction', params.graphics.winhandle, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                IvCalib.getInstance().present(x,y,true,rectColour)
                
                % save targ final position for later
                targ = [x y];
                
                % evaluate outcome
                aT.update(anscorrect);
                
                % save data
                isReversal = aT.wasAReversal();
                writeData(anscorrect,targ,resp,responseLatency,step,freq_cpp,freq_cpd,freq_ppc,trackStage,isReversal,logFn);
                IvDataLog.getInstance().dumpLog(logFn); % dump eyetrack log  
            end % end of trial
            
            if aT.isFinished() %i.e. if not aborted
                fprintf('\n       performance = %1.2f\n', aT.computeThreshold())
                
                % store filename reference
                blockFns{bid} = getCurBlockFn();
            end
            
        end % end of track/block
        
        %% easy/impossible catch trials
        IvVideo.getInstance().close();
        IvVideo.getInstance().open('../resources/video/In.The.Night.Garden.All.Together [2010] Dvdrip - PRESTiGE.- Sample.avi');

        % play video
        IvVideo.getInstance().play(true);
        % wait for click or timeout
        videoStartTime = GetSecs();
        lookStartTime = GetSecs();
        while 1
            switch first(InH.getInput())
                case InH.INPT_SKIP.code
                    break
            end
            % start automatically once the infant is looking at the screen
            if any(isnan(eyetracker.getLastKnownXY()))
                lookStartTime = GetSecs(); % reset
            else
                if (((GetSecs()-lookStartTime) > basicParams.nSecsRqdToBreakVid) ...
                        && ((GetSecs()-videoStartTime) > basicParams.minVidTime) )
                    break
                end
            end
            eyetracker.refresh(false); % false to supress logging
            IvFlip(winhandle);
            WaitSecs(.01);
        end
        IvVideo.getInstance().stop();
             
        for step = [length(cpp) 0 length(cpp)] % easy-hard-easy
            % START TRIAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            trialNum = trialNum + 1;
            % get variables
            trackStage = NaN;
            if step > 0
                freq_cpp = cpp(step); % cycles per pixel (for stim gen)
                freq_ppc = ppc(step); %pixels per cycle (for stim gen sanity check)
                freq_cpd = cpd(step); % cycle-per-degee (for reporting)
            else
                freq_cpp = 0;
                freq_ppc = 0;
                freq_cpd = 0;
            end

            fprintf('%i   =>  %1.3f (%1.3f) [%i]     ', step,freq_cpd,freq_cpp,freq_ppc)

            % init
            logFn = sprintf('IvData-%s-%i-%i-%i-%s.csv', metaParams.expID, metaParams.partID, metaParams.sessID, trialNum, datestr(now,30));
            
            IvAudio.playNow(nurseryRhymes{randi(nNurseryRhymes)}, false);
            
            % init position
            counter = 0;
            eyetracker.refresh(false);
            [prevXY, t] = eyetracker.getLastKnownXY(false); % TRUE WAS WRONG??
            if (t-GetSecs()) > .5 || any(isnan(prevXY))
                prevXY = [params.graphics.mx params.graphics.my]; % if can't detect
                fprintf('\n\nNo previous position could be found, so assuming last feedback point\n\n');
            end
            while 1
                % get random angle
                theta = rand()*2*pi;
                
                % get random distance
                r = minDist_px + (maxDist_px-minDist_px).*rand(graphicStimParams.nPoints,1);
                
                % convert to cartesian coordinates
                [dx,dy] = pol2cart(theta,r);
                
                % calculate new position by adding the randomly
                % generated vector to the last known fixation point
                x = prevXY(1) + dx;
                y = prevXY(2) + dy;
                
                % check if valid
                if x > x0 && y > y0 && x < x1 && y < y1
                    break;
                end
                
                counter = counter + 1;
                if counter > 70
                    fprintf('\n\n\n\nWARNING: Failed to find an appropriate location for the new stimulus\n\n\n');
                    x = params.graphics.mx;
                    y = params.graphics.my;
                    break;
                    %error('a:b','c');
                end
            end
            myGraphic.reinitXY(x, y);
            
            zi = (1:256)';
            if graphicStimParams.maxVelocity == 0
                gammaTable = interpne(gammaTable_ind, [repmat([gamma_nCols*x/params.graphics.testScreenWidth gamma_nRows*y/params.graphics.testScreenHeight],256,1),zi]);
                Screen('LoadNormalizedGammaTable', winhandle, gammaTable*[1 1 1], 1);
                %
            else
                % Init movement handler
                s = 0; % init speed
                v = (3-randi(2,[graphicStimParams.nPoints,1])*2) * graphicStimParams.maxVelocity/2 + graphicStimParams.maxVelocity*rand(graphicStimParams.nPoints,1);
                u = (3-randi(2,[graphicStimParams.nPoints,1])*2) * graphicStimParams.maxVelocity/2 + graphicStimParams.maxVelocity*rand(graphicStimParams.nPoints,1);
                m = ones(graphicStimParams.nPoints,1);
                myLJP = LennardJonesPotential(x,y,v,u,m,b,sigma,params.graphics.ifi,[],graphicStimParams.maxVelocity);
            end
            Screen('FillRect', winhandle , params.graphics.gray); % gray background
            
            % flush eyetracker
            eyetracker.flush();
            IvDataLog.getInstance().reset();
            
            % run until decision (or timeout)
            startTime = myClassifier.start();
            eyetracker.flush();
            Screen('BlendFunction', winhandle, GL_ONE, GL_ONE);
            xyAtClassification = [];
            while 1
                
                inpt = InH.getInput();
                switch inpt(1) % take first (tmp hack)
                    case InH.INPT_RESTART.code
                        break; % break loop (and will subsequently restart trial)
                    case InH.INPT_BACK1.code
                        aT.goBackN(1);
                        break;
                    case InH.INPT_SKIP.code
                        aT.update(true);
                        break
                    case InH.INPT_FAIL.code
                        aT.update(false);
                        break
                end
                
                % update Position
                if graphicStimParams.maxVelocity ~= 0 % else vars will never change, and may even run into division-by-zero errors
                    [x,y,s] = myLJP.calcNextTimestep();
                    gammaTable = interpne(gammaTable_ind, [repmat([gamma_nCols*x/params.graphics.testScreenWidth gamma_nRows*y/params.graphics.testScreenHeight],256,1),zi]);
                    Screen('LoadNormalizedGammaTable', winhandle, gammaTable*[1 1 1], 1);
                    
                    myGraphic.setXY(x,y);
                end
                
                % Recompute dstRects destination rectangles for each patch, given
                % the 'per gabor' scale and new center location (x,y):
                if graphicStimParams.nPoints == 1
                    r = (inrect .* repmat(scales,4,1))';
                else
                    r = inrect .* repmat(scales,4,1);
                end
                dstRects = CenterRectOnPointd(r, x', y');
                
                
                % Compute new random orientation for each patch in next frame:
                if graphicStimParams.maxRotationVelocity ~= 0 % else vars will never change, and may even run into division-by-zero errors
                    rotAngles = rotAngles+graphicStimParams.maxRotationVelocity*(s'/graphicStimParams.maxVelocity)/sqrt(2); % TODO: simplify
                end
                
                if step > 0
                    Screen('DrawTexture', params.graphics.winhandle, gabortex, [], dstRects, rotAngles, [], [], [], [], kPsychDontDoRotation, [graphicStimParams.phase, freq_cpp, graphicStimParams.sc, graphicStimParams.contrast, 1, 0, 0, 0]);
                end
                
                % myClassifier.drawBoxes();
                Screen('Flip', params.graphics.winhandle);
                
                n = eyetracker.refresh(true); % false to supress logging
                
                if n > 0 % update classifier
                    myClassifier.update();
                    if ~myClassifier.isUndecided() % see if reached decision
                        responseLatency = GetSecs() - startTime;
                        xyAtClassification = eyetracker.getLastKnownXY(); % use RAW rather than buffered. Why?
                        break
                    end
                end
                
                WaitSecs(params.graphics.ifi);
            end
            
            if isempty(xyAtClassification)
                continue % restart trial (Aborted?)
            end
            
            resp = myClassifier.interogate().name;
            anscorrect = strcmpi(resp, 'target');
            
            % give user feedback
            if anscorrect
                fprintf('Hit:  ');
                % update drift correction
                trueXY = [x y];
                estXY = xyAtClassification; % eyetracker.lastXY(); % ivis.data.IvDataLog.getInstance().getLastN(1, 1:2);
                eyetracker.updateDriftCorrectionFactor(trueXY, estXY);
                rectColour = [55 200 55];
            else
                fprintf('Miss\n');
                rectColour = [200 55 55];
            end
            
            % give feedback
            Screen('BlendFunction', params.graphics.winhandle, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            IvCalib.getInstance().present(x,y,true,rectColour)
            
            % save targ final position for later
            targ = [x y];
            
            % save data
            isReversal = NaN;
            writeData(anscorrect,targ,resp,responseLatency,step,freq_cpp,freq_cpd,freq_ppc,trackStage,isReversal,logFn);
            IvDataLog.getInstance().dumpLog(logFn); % dump eyetrack log 
        end
        
        
        
        
        fprintf('\n\nAll done! [%s]\n\n\n', datestr(now()));

        %%%%%%%
        %% 4 %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% DEBRIEF %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            IvAudio.playNow(endOfGameSound, false);
            
            Screen('PutImage', winhandle, awesomeFaceTexture);
            % Display the debrief text, centered in the display window:
            DrawFormattedText(winhandle, basicParams.debriefText, 'center', 'center',0,75,false,false,1.5);
            Screen('Flip', winhandle,0,0); % Show the drawn text at next display refresh cycle:
            % Wait for key stroke.
            KbWait([], 3);

        %%%%%%%
        %% 5 %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% CLEANUP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            local_cleanUp(); %clean up before exit

    catch ME
        %abortCurrentDataFile(ME)
        
        % This section is executed only in case an error happens in the
        % experiment code implemented between try and catch...
        local_cleanUp(); %clean up before exit

        %output the error message
        %psychrethrow(psychlasterror);
        rethrow(ME);
    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% GIVE BLOCK FEEDBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function local_giveBlockFeedback(winhandle, awesomeFaceTexture, feedbackTxt)  
    % Display the instructions text, centered in the display window:
    Screen('FillRect', winhandle , [255 255 255]); %white background
    Screen('DrawTexture', winhandle, awesomeFaceTexture);
    DrawFormattedText(winhandle, feedbackTxt, 'center', 'center');
    Screen('Flip', winhandle,0,0); % Show the drawn text at next display refresh cycle:
    % Wait for key stroke.
    KbWait([], 3);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SHOW BREAK SCREEN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function local_takeABreak(winhandle, breakTextures)

    RESP_CONTINUE = 'SPACE'; % TODO: replace with InputMapper etc

    % define end of block text
    eobTxt = sprintf('-Time for a Break-\nPress %s to continue', RESP_CONTINUE);

    % draw a random breakscreen image in the middle of the screen
    breakTexture = breakTextures{Randi(length(breakTextures))};
    Screen('DrawTexture', winhandle, breakTexture);

    % display performance feedback
    sy = 100;
    DrawFormattedText(winhandle, eobTxt, 'center', sy);
    Screen('Flip', winhandle,0,0);

    waitFor1ofNKeys({RESP_CONTINUE}); %wait for keystroke
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CLEAN UP HARDWARE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function local_cleanUp()

    ivis.main.IvMain.finishUp();

    % restore keyboard input
    fprintf('Attempting to restore user input')
    ShowCursor;
    ListenChar(0);
    fprintf(' ... done!\n')

    % restore desktop
    fprintf('Attempting to close screen')
    Screen('CloseAll'); %or sca
    fprintf(' ... done!\n')
    
    
    rmpath C:\Users\Student\Dropbox\Experiments\acuity\run\code\toolbox\ivis\src\
    rmpath C:\Users\Student\Dropbox\Experiments\acuity\run\code\toolbox\ivis\src\ivis_util\
    rmpath C:\Users\Student\Dropbox\Experiments\acuity\run\code\toolbox\ivis

end