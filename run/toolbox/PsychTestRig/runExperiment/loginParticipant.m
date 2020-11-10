function [partID,partInfo]=loginParticipant(expID,varargin)
%LOGINPARTICIPANT description.
%
% .... allowParticipantCreation?? Add authentication in FULL mode
% password dialog:
% http://www.mathworks.com/matlabcentral/fileexchange/19729
%
% Example: none
%
% See also
% 
% @Author: Pete R Jones
% @Date: 22/01/10

    %----------------------------------------------------------------------
    p = inputParser;   % Create an instance of the class.
    p.addRequired('experimentID',@ischar);
    p.addOptional('partID',[]);
    p.addOptional('skipLoginChecks',@islogical);
    p.FunctionName = 'LOGINPARTICIPANT';
    p.parse(expID,varargin{:}); % Parse & validate all input args
    %----------------------------------------------------------------------
 	expID=p.Results.experimentID;
    partID=p.Results.partID;
    skipLoginChecks=p.Results.skipLoginChecks;
    %----------------------------------------------------------------------
    
    
    % Check good to go
    if ~isValidExpID(expID)
        error('PsychTestRig:loginParticipant',['Invalid Experiment ID: ' expID])
    end
    
    % print
    fprintf('----------------------------------------------------------------\n\n')
    fprintf('Logging in participant..\n')
    
    % Find last part ID
    promptTxt = '';
    expDir=[getPrefVal('homeDir') filesep expID];
    tmp = dir([expDir filesep 'data']);
    parts = tmp([tmp.isdir]);
    idx = regexp({parts.name}, '^(0|[1-9][0-9]*)$');
    idx = ~cellfun(@isempty,idx,'UniformOut',true);
    if any(idx==1) % if any candidates
        parts = parts(idx);
        partids = str2double({parts.name});
        partids_sorted = sort(partids);
        idx = 1:partids_sorted(find(diff(partids_sorted)>50, 1 ));
        parts = parts(ismember(partids,idx)); % exclude any numbers after big jumps (e.g., if you have participants 1,2,3,4,999)
        %
        if ~isempty(idx)
            %
            x = [parts.datenum];
            idx = x==max(x);
            if sum(idx) > 1 % in a tie break situation
                idx = find(idx,1,'last'); % pick the greatest number
            end
            lastAccessed = str2double(parts(idx).name);
            %
            [~,i] = max(partids(ismember(partids,idx)));
            if ~isempty(i)
                biggestPartId = str2double(parts(i).name);
                %
                if lastAccessed == biggestPartId
                    lastPart = lastAccessed;
                    promptTxt = sprintf(' (Last was %i)', lastPart);
                end
            end
        end
    end

    % Query user
    if isempty(partID)
        partID=getIntegerInput(sprintf('Participant ID%s: ',promptTxt) ,false,0);
    end
    
    % Check valid
    if ~isValidPartID(expID, partID)
        error('loginParticipant:Fail','Login Failed.');
    end
    
    % 
    partInfo = login_ensurePartInfo(expID, partID,skipLoginChecks);
    
    % Ensure an data output directory exists
    login_ensurePartDataDir(expID, partID,skipLoginChecks);
    
    fprintf('..login complete\n')
    
end


%%%%%%%%%%%%%%%%%%%%%%%
%%% LOCAL FUNCTIONS %%%
%%%%%%%%%%%%%%%%%%%%%%%

