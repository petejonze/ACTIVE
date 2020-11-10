function setupStruct=getBlankSetup()
%GETBLANKSETUP shortdescr.
%
% Description
%
% Example: none
%
% See also
% 
% @Author: Pete R Jones
% @Date: 22/01/10

    setupStruct=struct( 'homeDir',''...
                        ,'lastUpdate',''...
                        ,'backupDir',''...
                        ,'useDb',''...
                        ,'dbInfo',struct('host','','username','','password','')...
                        ,'alertAddress',''...
                        );
    
end