function Xrms=calib_getTargRMS(calib,targLeq,outChans,freq,tolerance,devID,devName,headID)
% GETRMS Returns a target RMS power level required to attain the specified
% Leq (SPL), as determined by a previously obtained calibration file.
%
%   Uses a linear regression (Leq regressed onto log10(rms)) backwards.
%
%   Currently if freq is -1 then it will attempt to find a whitenoise
%   calibration
%
% @Parameters:             
%
%     	calib                   Struct/Char    	Either calib structure or name of file to load (including relative or absolute path if not in current directory)
%                                e.g. './calibrations/calib-1234.mat'
%     	targLeq                 Real         	Desired output level
%                                e.g. 64
%     	outChans                 Int             #####
%                                e.g. 0
%     	freq                    Real            Expected headphone ID
%                                e.g. 1000
%     	[tolerance]             Real            see calib_getFreqIndex()
%                                e.g.
%     	[devID]                 Int             Expected device ID
%                                e.g. 1
%     	[devName]               Char            Expected device name
%                                e.g. 'C-Media USB Headphone Set'
%     	[headID]                Char            Expected headphone name
%                                e.g. 'Sen-ME4'
% @Returns:  
%
%    	Xrms       	Real      The rms value required to obtain the desired output level. RMS is the square root of the arithmetic mean (average) of the squares of the original values
%
%
% @Usage:           Xrms=calib_getTargRMS(calib, targLeq, outChans, freq, [tolerance], [devID], [devName], [headID])   
% @Example:         Xrms=calib_getTargRMS(myCalib, 30, 1, -1) 
%                   Xrms=calib_getTargRMS(myCalib, 30, 1, -1, [], [], 'Sony-MX300') 
%
% @Requires:        PsychTestRig2
%   
% @See also:        #####
%
% @Matlab:          v2008 onwards
%
% @Author(S):    	Pete R Jones
%
% @Creation Date:	28/01/2011
% @Last Update:     28/01/2011
%
% @Current Verion:  1.0.0
% @Version History: v1.0.0	28/01/2011    Initial build.
%
% @Todo:            Lots!
%
%                	additional input validation
%                   change name to getLeq ? or just 'get' ?


%   	%%%%%%%%%
%     %%% -1 %%
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     %%% If dummy calib %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         
%         % dummy calibrations are useful if you are just developing a script
%         % (e.g. on a random computer), and don't want all the hastle of having
%         % to actually perform a proper calibration. See calib_dummy.m
%         if isstruct(calib) && isfield(calib,'isDummy') && calib.isDummy
%             Xrms = exp10( (targLeq - calib.coefs(2) ) / calib.coefs(1) );
%             return
%         end
        
    %%%%%%%%%
    %%% 0 %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Initialise variable %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % necessary params
        if nargin < 1 || isempty(calib)
            fprintf('USAGE: Xrms=calib_getTargRMS(calib, targLeq, outChans, freq, [tolerance], [devID], [devName], [headID])\n');
            error('calib_getTargRMS:invalidInput','No calibration specified');
        elseif nargin < 2 || isempty(targLeq)
            error('calib_getTargRMS:invalidInput','No targLeq specified');
        elseif nargin < 3 || isempty(outChans)
            error('calib_getTargRMS:invalidInput','No channel specified');    
        elseif nargin < 4 || isempty(freq)
            error('calib_getTargRMS:invalidInput','No freq specified');
        end

        % optional params
        if nargin < 5
            tolerance = [];
        end
        if nargin < 6
            devID = [];
        end
        if nargin < 7
            devName = [];
        end
        if nargin < 8
            headID = [];
        end

        % extra
        isWNoise = false;
        if freq == -1
            isWNoise = true;
            freq = [];
        end

    %%%%%%%%%
    %%% 1 %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Load/validate calib %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
        calib = calib_load(calib,devName,devID,headID,outChans,isWNoise,freq,tolerance);
    
        
    i = 1;
    nChans = length(outChans);
    Xrms = ones(nChans,1) * NaN;
    for outChan=outChans    
        
        %%%%%%%%%
        %%% 2 %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Get appropriate fit coeficients %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   

            chanIdx = calib_getChanIndex(calib,outChan);
            SLM = [];
           
            if isWNoise
                if isfield(calib.channels(chanIdx).whitenoise.fit, 'SLM')
                    error('calib_getTargRMS:NotYetComplete:whitenoise','Sorry whitenoise SLM support not yet written.\n');
                else
%                     warning('calib_getTargRMS:Legacy:whitenoise','NO SLM calib found, extracting regression coefs instead.\n');
                    coefs =  calib.channels(chanIdx).whitenoise.fit.coefs;
                end
            else % pure tone
                targFreqIdx = calib_getFreqIndex(calib,chanIdx,freq,tolerance,true);
                if isfield(calib.channels(chanIdx).freqs(targFreqIdx).fit, 'SLM')
                    SLM = calib.channels(chanIdx).freqs(targFreqIdx).fit.SLM;
                else
%                     warning('calib_getTargRMS:Legacy','NO SLM calib found, extracting regression coefs instead.\n');
                    coefs = calib.channels(chanIdx).freqs(targFreqIdx).fit.coefs;
                end
            end

        %%%%%%%%%
        %%% 3 %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Calc required Xrms %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        

%             % log10 since we are fitting a straight line by log(10)ing the RMS
%             % values
%             % (x-c)/m rather than mx+c (i.e. polyval), since we are using the
%             % regression model in reverse
%             % exp10 since we want to recover the actual rms value, not the log10 of
%             % it
%             Xrms(i) = exp10( (log10(targLeq) - coefs(2) ) / coefs(1) );
%             Xrms(i) = exp10( (targLeq - coefs(2) ) / coefs(1) );
%             %OLD: rms = exp(polyval(coefs,dbSPL));

            
            % now using SLM toolbox for advance fits:
            if ~isempty(SLM)
                Xrms(i) = exp10(slmeval(targLeq,SLM,-1)); % -1, using in reverse mode
            else
%                 warning('calib_getTargRMS:Legacy','NO SLM structure found, reverting to regression.\n');
                Xrms(i) = exp10( (targLeq - coefs(2) ) / coefs(1) );
            end
        
        i = i + 1;
    end
	
end