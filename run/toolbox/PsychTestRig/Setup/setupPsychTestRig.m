function setupPsychTestRig(homeDir, backupDir, useDb, dbHost, dbUsername, dbPassword, alertAddress)
%SETUPPSYCHTESTRIG short description.
%
%   long description.
%
%
% @Requires:        PsychTestRig [package]
%   
% @Input Parameters:
%
%    	homeDir     Char            Path
%                                   @default: []
%
%    	backupDir 	Char            Path
%                                   @default: []
%
%    	useDb 		Logical         ####
%                                   @default: []
%
% @Returns:  
%
%       <none>
%
%
% @Syntax:
%
%       setupPsychTestRig([homeDir], [backupDir], [useDb], )
%
% @Example:    
%
%       setupPsychTestRig('C:/Experiments','D:/Backups');
%       ptr -setup 'C:\Users\Pete\Dropbox\Experiments' 'C:\Users\Pete\Dropbox\Experiments\__TRASH' true;
%
% @See also:        PsychTestRig
% 
% @Author:          Pete R Jones <petejonze@gmail.com>
%
% @Version History: 1.0.0	01/01/10    First Build             [PJ]
%                   1.0.1	02/11/12    Extensive rewrite   	[PJ]
%
% @Todo:            - Only save changes at end???? (i.e. have a temp intermediate struct.

	%%%%%%%
    %% 0 %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Init %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
        % parse inputs
        if nargin < 1
            homeDir = [];
        end
        if nargin < 2
            backupDir = [];
        end
        if nargin < 3
            useDb = [];
        else
            useDb = str2log(useDb);
        end
        if nargin < 4
            dbHost = [];
        end
        if nargin < 5
            dbUsername = [];
        end
        if nargin < 6
            dbPassword = [];
        end
        if nargin < 7
            alertAddress = [];
        end

        %print welcome message to console
        cloutput('')
        cloutput('%line')
        cloutput('Welcome to the PsychTestRig setup.')
        input('press RETURN to begin (press ctrl+c to abort)\n');

        %clear any existing setup. Prompt for confirmation if necessary 
        clearSetup();    


	%%%%%%%
    %% 1 %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Diagnostics %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
        cloutput('1. We begin by running a few diagnostic tests on your system')
        input('press RETURN to continue\n');
        errCode=local_runDiagnostic();
        if (errCode==3)
            error('script terminated: Diagnostic failed.')
        elseif(errCode==1)
            cloutput('/*****Warning: Some aspects of your system have not been tested with PsychTestRig. It may not operate normally.*****/')
        end
        cloutput('');


	%%%%%%%
    %% 2 %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Directories %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        fprintf('2. Next you must a home directory in which all your experiments will be stored (e.g. "%s")\n', 'C:\My Documents\Experiments')
        if isempty(homeDir)
            input('press RETURN to continue');
            homeDir = uigetdir(cd,'Please select the directory which you would like to use as your home directory. This is where all your experiments will be stored (e.g. "C:\My Documents\Experiments").');
        end
        if (homeDir==0)
            error('script terminated by user')
        end    
        if ~exist(homeDir,'dir')
            error('setupPsychTestRig:invalidInput','Directory not found: %s',homeDir);
        end
        setPrefVal('homeDir',homeDir);
        fprintf('\n   homeDir: %s\n\n', homeDir)

        fprintf('2b. A backup directory in which copies of all your experimental data will be stored (e.g. "%s")\n', 'D:\MyBackups');
        if isempty(backupDir)
            input('press RETURN to continue');
            backupDir = uigetdir(cd,'Please select the directory which you would like to use as your backup directory.');
        end
        if (backupDir==0)
            error('script terminated by user')
        end
        if ~exist(backupDir,'dir')
            error('setupPsychTestRig:invalidInput','Directory not found: %s',backupDir);
        end
        setPrefVal('backupDir',backupDir);
        fprintf('\n   backupDir: %s\n\n', backupDir)
        

	%%%%%%%
    %% 3 %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Database %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        fprintf('3. Database storage\n');
        if isempty(useDb)
            useDb = getLogicalInput('   Do you want to link to a MySQL database? (y/n): ');
        end
        setPrefVal('useDb',useDb);
        fprintf('\n   useDb: %s\n\n', log2str(useDb))

        if useDb
            cloutput('   Checking database prerequisites...')
            %Check that mysql.m present
            fprintf('      mysql.m..........      ')
            if exist('mysql.m','file')
                fprintf(['Found' ' [OK]\n'])
            else
                fprintf(['Not Found' ' [FAIL]\n'])
                error('PsychTestRig:setupPsychTestRig:toolkitNotFound','Script Terminated. "mysql.m" not found.\n\nPlease download Robert Almgren''s mysql-matlab package. This should be available at:\n   http://www.mathworks.com/matlabcentral/fileexchange/8663-mysql-database-connector\nYou may be able to find help on using this package at these sites:\n   http://www.mmf.utoronto.ca/resrchres/mysql/\n   http://www.courant.nyu.edu/~almgren/mysql/\n\nIf you have already download this package then you may need to make it visible to matlab.\nDo this by adding the containing directory to the search path (e.g. File => Set Path => Add folder...)') 
            end
            %Check that mysql.mex present (i.e. is compiled
            fprintf('      mysql.mex........      ')
            try
                msg=mysql('status'); %#ok
            catch ME
                if strcmpi(ME.identifier,'MATLAB:scriptNotAFunction')
                    fprintf(['Not Found' ' [FAIL]\n'])
                  	error('"mysql.m" was found, but it has not been compiled to MEX form. You may be able to find help on how to compile this package at: http://www.courant.nyu.edu/~almgren/mysql/')
                elseif strcmpi(ME.identifier,'MATLAB:invalidMEXFile')
                    fprintf(['Invalid' ' [FAIL]\n'])
                    error('"mysql.m" and its associated mex file was found, but the Mex was invalid. The most likely reason for this is that you have not copied libmysql.dll into C:\Windows\System32. You may be able to find help at: http://www.courant.nyu.edu/~almgren/mysql/')
                else
                    fprintf(['Invalid' ' [FAIL]\n'])
                    rethrow(ME);
                end
            end
            fprintf(['Found' ' [OK]\n'])
            cloutput('   ...Success!\n')

            %close any/all existing connections (???)
            mysql('closeall')    
        
            %--------------------------------------------------------------
            % Check that server reachable
            %--------------------------------------------------------------
            cloutput('3b. We will now attempt to connect to your MySQL server.\n    - If the server is installed on this machine then the host is "localhost".\n    - If you do not know your username then try "root"\n    - If you do not know your password then try leaving it blank\n');
            retries=0;
            while (1)
                if isempty(dbHost)
                    dbHost=getStringInput('   host: ',true,true);
                else
                    fprintf('   host: %s\n', dbHost);
                end
                if isempty(dbUsername)
                    dbUsername=getStringInput('   username: ',true,true);
                else
                    fprintf('   username: %s\n', dbUsername);
                end
                if isempty(dbPassword)
                    dbPassword=getStringInput('   password: ',true,true);
                else
                    fprintf('   password: %s\n', dbPassword);
                end
                try
                    fprintf('\n   ');
                    msg=mysql_connect(dbHost,dbUsername,dbPassword);
                    break
                catch 
                    cloutput(['   ...Connection failed!: ' lasterr '\n']) % don't allow a fatal error to be thrown
                end
                
                retries = retries + 1;
                if (retries==3)
                    error('Script Terminated. Database authentication failed.')
                end
            end
            cloutput('   ...Success!\n')
            
            %Save authentication info
            dbInfo.host = dbHost;
            dbInfo.username = dbUsername;
            if getLogicalInput('   Would you like PsychTestRig to remember this password?\n   [n.b. this is not secure!!!]  (y/n): ')
                dbInfo.password = dbPassword;
            end
            setPrefVal('dbInfo',dbInfo);
            
            %check that Mysql is an appriate version
            cloutput('\n   Checking server properties...')
            fprintf('      MySQL ver........      ')
            ver=mysql('SELECT VERSION()');
            if ~mysql_isAtLeastVersion(5,0,2)
                fprintf([char(ver) ' [FAIL]\n'])
                error('Script Terminated: Please install MySQL version 5.0.2 or above.')
            else
                fprintf([char(ver) ' [OK]\n'])
            end
            cloutput('   ...Success!\n')
            
            %--------------------------------------------------------------
            % Check that server reachable
            %--------------------------------------------------------------
            cloutput('3c. We will now ensure that the right data structures are present');
            input('press RETURN to continue\n');
            %Ensure db exists
            cloutput('   Connecting to database "psychtestrig"...')
            try
                mysql_checkDatabaseExists('psychtestrig', 'CREATE DATABASE psychtestrig')
            catch ME
                cloutput('\n/*****script terminated: Database configuration failed (error in database).*****/')
                mysql('close')
                rethrow(ME)
            end
            cloutput('   ...Success!\n')
            
            %Connect to db
            msg=mysql('use psychtestrig'); %#ok
            
            %Verify tables
            cloutput('   Checking tables...')
            try
                local_checkTables();
            catch ME
                cloutput('\n/*****script terminated: Database configuration failed (error in tables).*****/')
                mysql('close')
                rethrow(ME)
            end
            cloutput('   ...Success!\n')
            
            mysql('close')
            
            %synchronise database with file structure
            syncDbWithFileStruct('indent',3);
        end
        
	%%%%%%%
    %% 4 %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Alerts %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
        cloutput('\n4. Session-complete alerts');
        if isempty(alertAddress)
            alertAddress = getStringInput('Email/phone account to receive alerts\n(leave blank for no alerts): ','allowNull',true);
        end
        setPrefVal('alertAddress',alertAddress);
        fprintf('\n   alertAddress: %s\n', alertAddress);
        
        
        
	%%%%%%%
    %% 5 %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Finish up %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
        cloutput('\n\nChecking:\n')
        
        if checkSetup(getPrefVal())
            fprintf('\n\n')
            cloutput('Setup complete!\nFor more information no what to do next type PsychTestRig')
        end
          
end


%%%%%%%%%%%%%%%%%%%%%%%
%%% LOCAL FUNCTIONS %%%
%%%%%%%%%%%%%%%%%%%%%%%

function errCode=local_runDiagnostic()
%return 2 for fail, 1 for untested, 0 for OK.    
    fail=0;
    untested=0;
    
    %check matlab version
    fprintf('   Matlab version...      ')
    matver = getversion();
    if (matver < 7.4)
        fail=1;
        fprintf([num2str(matver) ' [FAIL]\n'])
    else
        fprintf([num2str(matver) ' [OK]\n'])
    end
 
    %check OS
    fprintf('   OS...............      ')
    if ispc
        fprintf(['PC' ' [OK]\n'])
    elseif isunix
        untested=1;
        fprintf(['UNIX' ' [UNTESTED]\n'])
    else
        untested=1;
        fprintf(['unknown' ' [UNTESTED]\n'])
    end
    
    if (fail)
        errCode=2;
    elseif(untested)
        errCode=1;
    else
        errCode=0;
    end
end


function err=local_checkTables()
    err=0;
    
    %Check table: "experiments"
    cloutput('   |    Checking table "experiments"...')
    creationText='CREATE TABLE experiments (id_num INT NOT NULL AUTO_INCREMENT PRIMARY KEY, name VARCHAR(32) NOT NULL UNIQUE, last_update TIMESTAMP, creation_date datetime NOT NULL default "1900-01-01 00:00:00", status varchar(32) NOT NULL default "PENDING", notes mediumtext)';
    triggerText='CREATE TRIGGER experiments_updateDate BEFORE INSERT ON experiments FOR EACH ROW BEGIN IF NEW.creation_date = "1900-01-01 00:00:00" THEN SET NEW.creation_date = NOW(); END IF; END'; %to automatically initialise creation_date        
    try
    	mysql_checkTableExists('experiments',creationText,triggerText);
        checkDbTable('experiments');
    catch ME
        fprintf('>>> Bad table definition!!\nOne (extreme) option would be to drop the whole database with deleteDB() and start again(??)');
        rethrow(ME)
    end

    %Check table: "participants"
    cloutput('   |    Checking table "participants"...')
    creationText='CREATE TABLE participants (id_num INT NOT NULL AUTO_INCREMENT PRIMARY KEY, forename VARCHAR(32) NOT NULL, surname VARCHAR(32) NOT NULL, dob DATE NOT NULL, last_update TIMESTAMP, creation_date datetime NOT NULL default "1900-01-01 00:00:00", notes mediumtext, private_comments mediumtext)';
    triggerText='CREATE TRIGGER participants_updateDate BEFORE INSERT ON participants FOR EACH ROW BEGIN IF NEW.creation_date = "1900-01-01 00:00:00" THEN SET NEW.creation_date = NOW(); END IF; END'; %to automatically initialise creation_date        
    try
        mysql_checkTableExists('participants',creationText,triggerText);
        checkDbTable('participants');
    catch ME
        fprintf('>>> Bad table definition!!\nOne (extreme) option would be to drop the whole database with deleteDB() and start again(??)');
        rethrow(ME)
    end

   	%Check table: "sessions"
    cloutput('   |    Checking table "sessions"...')
    creationText='CREATE TABLE sessions (id_num INT NOT NULL AUTO_INCREMENT PRIMARY KEY, expID INT NOT NULL, partID INT NOT NULL, timestamp TIMESTAMP, notes mediumtext, FOREIGN KEY (expID) REFERENCES experiments(id_num), FOREIGN KEY (partID) REFERENCES participants(id_num))';     
    try
        mysql_checkTableExists('sessions',creationText);
        checkDbTable('sessions');
    catch ME
        fprintf('>>> Bad table definition!!\nOne (extreme) option would be to drop the whole database with deleteDB() and start again(??)');
        rethrow(ME)
    end
end