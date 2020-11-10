classdef PtrSound < handle
    %#####
    %
    %   dfdfdf
    %
    % @Requires the following toolkits: <none>
    %
    % @Constructor Parameters:
    %
    %     	######
    %
    %
    % @Example:         <none>
    %
    % @See also:        <none>
    %
    % @Requires:        Matlab v2012 or later
    %
    % @Author:          Pete R Jones
    %
    % @Creation Date:	28/01/2014
    % @Last Update:     28/01/2014
    %
    % @Current Verion:  1.0.0
    % @Version History: v1.0.0	PJ 28/01/2014    Initial build.
    %
    % @Todo:            lots
    
    properties (GetAccess = 'public', SetAccess = 'private')
        soundwave
        Fs
        d
        pahandle
    end
    
    %% ====================================================================
    %  -----CONSTRUCTOR/DESTRUCTOR METHODS-----
    %$ ====================================================================
    
    methods (Access = 'public')
        
        function obj = PtrSound(SoundOrFullFn, Fs, rms, testChans, outChans, levelAdjust, pahandle)

            if ischar(SoundOrFullFn)
                try
                    [obj.soundwave, obsFs] = audioread(char(SoundOrFullFn));
                catch ME
                    warning('cannot find: %s', SoundOrFullFn);
                    rethrow(ME);
                end
                if nargin < 2 || isempty(Fs)
                    Fs = obsFs;
                elseif obsFs ~= Fs
                    warning('ptr_loadSound:SamplingFrequencyMismatch', 'Sampling rate mismatch.\n          Specified file (%s) had a detected sampling rate (%i) that differed from that specified/expected (%i)', SoundOrFullFn, obsFs, Fs);
                    obj.soundwave = resample(obj.soundwave, obsFs, obj.Fs);
                end
            else
                obj.soundwave = SoundOrFullFn;
            end
                    
            obj.Fs = Fs;
            
            if nargin > 2 && ~isempty(rms)
                obj.soundwave = calib_setRMS(obj.soundwave', rms ); %transpose to make compatible with psychportaudio (later) and set volume [i.e. portaudio expects row vectors, but soundwave is read in as columns]
            end
            
            if nargin > 3 && ~isempty(testChans)
                obj.soundwave = padChannels(obj.soundwave, testChans, outChans);
            end
            
            if nargin > 5 && ~isempty(levelAdjust)
                obj.soundwave = obj.soundwave * levelAdjust;
            end
            
            if nargin > 6 && ~isempty(pahandle)
                obj.pahandle = pahandle;
            end
            
            % calc duration
            obj.d = size(obj.soundwave,2)/obj.Fs;
        end
        
        function obj = delete(obj)
        end
    end
    
    %% ====================================================================
    %  -----PUBLIC METHODS-----
    %$ ====================================================================
    
    methods (Access = 'public')
        
        function [] = play(obj, block)
            if nargin < 2 || isempty(block)
                block = false;
            end
            
            % see IvAudio.m for Psychportaudio alternatives
            obj.pahandle = audioplayer(obj.soundwave, obj.Fs);
            if block
                obj.pahandle.playblocking();
            else
                obj.pahandle.play();
            end
        end
        
        function [] = stop(obj)
            obj.pahandle.stop();
        end
        
        
    end
    
    
    %% ====================================================================
    %  -----STATIC METHODS-----
    %$ ====================================================================
    
    methods(Static)
    end
    
    %% ====================================================================
    %  -----PRIVATE METHODS-----
    %$ ====================================================================
    
    methods(Access = 'private')
    end
    
end