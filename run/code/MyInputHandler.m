% could break up into seperate synchronous and asynchronous subclasses. But for now will just leave as one
classdef MyInputHandler < InputHandler
%DESCRIPTION

methods (Access = public)
    function obj = MyInputHandler(isAsynchronous, customQuickKeys, warnUnknownInputsByDefault, winhandle)
        if nargin < 1, isAsynchronous = []; end
        if nargin < 2, customQuickKeys = []; end
        if nargin < 3, warnUnknownInputsByDefault = []; end
        if nargin < 4, winhandle = []; end
        obj = obj@InputHandler(isAsynchronous, customQuickKeys, warnUnknownInputsByDefault, winhandle);
    end
end
    
    %% PROPERTIES ---------------------------------------------------------
    properties (Constant)
        INPT_INT1 = struct('key','q', 'code',1)
        INPT_INT2 = struct('key','e', 'code',2)
        INPT_RESTART = struct('key','r', 'code',3)
        INPT_BACK1 = struct('key','b', 'code',4)
        INPT_SKIP = struct('key','s', 'code',5)
        INPT_FAIL = struct('key','f', 'code',6)
    end

    
	%% ====================================================================
    %  -----SINGLETON BLURB-----
    %$ ====================================================================

    methods (Static, Access = ?Singleton)
        function obj = getSetSingleton(obj)
            persistent singleObj
            if nargin > 0, singleObj = obj; end
            obj = singleObj;
        end
    end
    methods (Static, Access = public)
        function obj = getInstance()
            obj = Singleton.getInstanceSingleton(mfilename('class'));
        end
        function [] = finishUp()
            Singleton.finishUpSingleton(mfilename('class'));
        end
    end
end