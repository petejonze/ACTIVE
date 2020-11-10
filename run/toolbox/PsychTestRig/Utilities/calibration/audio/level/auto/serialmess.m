function serialmess

    %%%%%%%
    %% 0 %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% PARAMS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
        comport = 'COM1';
        %baudrate = 9600;
        baudrate = 19200; % this value can be found by going Setup => Output => pressing the setup button a few times to cycle through
        range_upperlimit_db = 100;
        duration_secs = 3; %20;
        %duration_secs = 10; %20;
        infoflag = 1;
        %oldMeasPath;
        
        % set datafiles
        dirname2260   = 'C:\DATA\MEAS1\AUTO';
        %filename2260  = sprintf('%s\\0001.S1A', dirname2260); <--
        %determined dynamically (at runtime)
        filelocal = './stemp2260.bin';


        % make the serial port 's' global in case code ever falls over
        global s
        
  
        %printf('2260 datafile      = ''%s'' ...\n', filename2260);
        fprintf('localfile          = ''%s'' ... \n', filelocal);

    %%%%%%%
    %% 1 %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% INITIALISATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    	
    
        try
            fclose(s);  % remove any previous serial connections
            delete(s); 
            fprintf('\nremoving previous serial connection to %s ... ', comport);
        catch
           % do nothing 
        end

        fprintf('\nsetting up interface using serial port %s ... ', comport);
        s = setup2260(comport, baudrate);
        fprintf('serial connection baudrate = %d \n', s.BaudRate);
        fprintf('\n');
            
        
%         oldMeasPath = '"C:\DATA\MEAS1"';
%         fprintf('\nreseting measurement path to %s on 2260''s local drive ...', oldMeasPath);
%         command = sprintf(':SE:M_PAT %s', oldMeasPath);
%         sendto2260BIN(s, command);
%         
        
        
        
% % % % %       	% check the directory again (the file should exist this time)
% % % % %        mdir2260(s, dirname2260, infoflag);
% % % % % 
% % % % %        
% % % % % %         % put 2260 into premade setup #1 
% % % % % %         % (from msetmode2260 ... 
% % % % % %         %        automatic mode with the important parameters being LCeq average on a 1-octave spectrum 
% % % % % %         %        on a 20-100 dB range with a 20-second recording time and with a auto-save at end of recording
% % % % % %         %        (to a '.S1A' file)
% % % % % %         fprintf('switching 2260 to ''automatic'' setup #1 ... \n');
% % % % % %         msetmode2260(s, 1, infoflag);
% % % % % %         
% % % % %         % PK - dummpy command to make sure next command executes
% % % % %         %command = sprintf(':SYSTEM:APPLICATION:ABOUT?');
% % % % %         command = sprintf(':SY:A:A?');
% % % % %         bkoutput = sendto2260BIN(s, command); %#ok
% % % % %         % PK - end
% % % % % 
% % % % % %                 command = sprintf(':SE:M_C:A_A_M?');
% % % % % %                 command = sprintf(':E?');
% % % % % %                 command = sprintf(':SE:I:S_I_C?');
% % % % % %                 command = sprintf(':SE:I:P_V?');
% % % % % %                 command = sprintf(':SETUP:MEASUREMENT_CONTROL:ACTION_AFTER_MEASUREMENT?');
% % % % % %                 command = sprintf(':SE:M_C:A_A_M?');
% % % % % %                 command = sprintf(':SE:O:A_1:M_L?');
% % % % % %                 command = sprintf(':SE:M_C:P_T? ');
% % % % % %                 
% % % % % %         bkoutput = sendto2260BIN(s, command); %#ok
% % % % % %         disp(bkoutput)
% % % % % %        
% % % % % 
% % % % %            command = sprintf(':SE:M_PAT?');
% % % % %            bkoutput = sendto2260BIN(s, command); %#ok
% % % % %             disp(bkoutput) 
% % % % %            
% % % % % %         command = sprintf(':SE:M_C:A_A_M?');
% % % % % %         bkoutput = sendto2260BIN(s, command); %#ok
% % % % % %         disp(bkoutput) 
% % % % % %            
% % % % %         
% % % % %         dfdfdf
        
        octave_spacing = 'O_3'; %O_3 (third), or O_1 (1 octave)
        fprintf('\nsetting octave spacing to %s...', octave_spacing);
        command = sprintf(':SE:M_PAR:S_B %s', octave_spacing);
        bkoutput = sendto2260BIN(s, command); %#ok
         fprintf('checking spectrum bandwidth ...                                  ');
        command = sprintf(':SE:M_PAR:S_B?'); %#ok
        bkoutput = sendto2260BIN(s, command) ;
        fprintf('output = %s\n', bkoutput);
duration_secs = 1             
        % set measurement duration on meter
        fprintf('\nsetting recording duration to %d seconds ...', duration_secs);
        command = sprintf(':SE:M_C:P_T 0,0,%d', duration_secs);
        bkoutput = sendto2260BIN(s, command); %#ok
        fprintf('checking recording duration ...                                  ');
        command = sprintf(':SE:M_C:P_T?', duration_secs); %#ok
        bkoutput = sendto2260BIN(s, command) ;
        fprintf('output = %s\n', bkoutput);

        % check what freq weights we have we are in: this should say 'ACCC'
        fprintf('checking frequency weightings (expecting ACCC) ...               ');
        command = sprintf(':SE:M_PAR:F_W?');
        bkoutput = sendto2260BIN(s, command) ;
        fprintf('output = %s\n', bkoutput);

        % Setting measurement path 
        fprintf('setting measurement path ...               ');
        %get
        fprintf('\nGetting current path ...               ');
    	command = sprintf(':SE:M_PAT?');
        oldMeasPath = sendto2260BIN(s, command);
        fprintf('old measurement path is %s on 2260''s local drive ... ', oldMeasPath);
        % change
     	dirname = sprintf('"%s"', dirname2260);
        fprintf('seting measurement path to ''%s'' on 2260''s local drive ... ', dirname);
        command = sprintf(':SE:M_PAT %s', dirname);
        sendto2260BIN(s, command);
        % check
        fprintf('Checking new path ...               ');
        command = sprintf(':SE:M_PAT?');
        bkoutput = sendto2260BIN(s, command);
        fprintf('new measurement path is ''%s'' on 2260''s local drive ... ', bkoutput);

        
    %%%%%%%
    %% 2 %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% MAKE MEASUREMENT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
        % set recoding level on meter
        fprintf('Checking new path ...               ');
        msetrange2260(s, range_upperlimit_db, infoflag);

        
%         % delete data file so we the 2260 can use overwrite it
%         mdeletedatafile2260(s, filename2260, infoflag);
%         fprintf('\n');
   
        % Play sound
        Fs = 44100;
        d = duration_secs + 5;
        n = Fs * d;
        cf = 1000;
        A = 0.2;
        t = (1:n)/Fs;
        x = A * sin(2 * pi * cf * t);
        sound(x,Fs);

        % count to 2 ...
        pause(2)
        
       % start the 2260 
       mstartmeasurement2260(s, duration_secs, infoflag);
       
       % check the directory listings
       bkdirectory = mdir2260(s, dirname2260, 0);
       pre_nfiles = bkdirectory.nfiles
       
        command = sprintf(':M:STO?');
        bkoutput = sendto2260BIN(s, command); %#ok
       
       % check the directory again (the file should exist this time)
       bkdirectory = mdir2260(s, dirname2260, 0);
        nfiles = bkdirectory.nfiles
       if pre_nfiles == nfiles
            ME = MException('\nserialmess:DataFileNotFound', sprintf('File appeared not to save on SLM. nFiles before==%i, nFiles after==%i',pre_nfiles,nfiles));
            throw(ME);
       end
        
       bkfile = bkdirectory.file(end);
       filename2260 = bkfile.filename;
       
       
       fileinfo = bkfile.fileinfo;
        [thisword, fileinfo] = strtok(fileinfo, ' ');
        [thisword, fileinfo] = strtok(fileinfo, ' ');
        [thisword, fileinfo] = strtok(fileinfo, ' ');
        filesize = str2num(thisword);
        
%        % save to host computer...
%        bytesgot = mgetdatafile2260(s, filename2260, filelocal, infoflag);
%        if bytesgot == 0
%            fprintf('error! bytesreceived = %d\n', bytesgot);
%            fprintf('stopping ... \n');
%           return;
%        end;
       
%         % get reading
%         fprintf('copying file %s from 2260 to computer  ... ', filename2260);
%         command = sprintf(':SY:F_M:CO? %s', filename2260);
%         bkoutput = sendto2260BIN(s, command) ;
%         fprintf('output = %s\n\n', bkoutput);


        % copy file to output  ...
        % put double quotes around filename
        bkfilename = sprintf('"%s"', filename2260);
        fprintf('\ncopying file %s from 2260 to computer  ... ', bkfilename);
        command = sprintf(':SY:F_M:CO? %s', bkfilename);
        bkoutput = sendto2260BIN(s, command) ;
        fprintf('output = %s', bkoutput);

        % grab data
        fprintf('getting binary data ... ');
        warning off MATLAB:serial:fgets:unsuccessfulRead

        %bkdata = grabdata2260_2(s, infoflag);   % this returns a 'uint8' datatype, so svae it alter using 'unit8' too ...
        %PK - get file data - filesize is also passed
        fprintf('\nattempting to grab data from file of size ''%i'' ...', filesize);
        bkdata = grabdata2260_PK(s, filesize, infoflag);   % this returns a 'uint8' datatype, so svae it alter using 'unit8' too ...
        %PK - end

        fprintf('total bytes = %d\n', length(bkdata));
        output_bytesgot = length(bkdata);

        % save data
        localfilename = filelocal%tmp
        fprintf('\nopening local file ''%s'' ...\n', localfilename);
        fid = fopen(localfilename, 'wb');
        fprintf('saving data ...\n');
        count = fwrite(fid, bkdata, 'uint8');
        fprintf('count = %d\n', count);
        fclose(fid);
  


	%%%%%%%
    %% 3 %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% FINISH UP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
   
%         % reset to premade setup #2 (manual mode, LCeq on the spectrums, 1/1 octave)
%         fprintf('switching 2260 to ''manual'' setup #2 ... \n');
%         msetmode2260(s, 2, infoflag);

        % delete file from SLM
        % put double quotes around filename
        bkfilename = sprintf('"%s"', filename2260);
        fprintf('attempting to delete data file ''%s'' on 2260''s local drive ... ', bkfilename);
        command = sprintf(':SY:F_M:DE? %s', bkfilename);
        bkoutput = sendto2260BIN(s, command);
        fprintf('output = %s\n', bkoutput);



        % reset measurement path
        fprintf('reseting measurement path to ''%s'' on 2260''s local drive ...', oldMeasPath);
        command = sprintf(':SE:M_PAT %s', oldMeasPath);
        sendto2260BIN(s, command);
        % check
        command = sprintf(':SE:M_PAT?');
        bkoutput = sendto2260BIN(s, command);
        fprintf('current measurement path is ''%s'' on 2260''s local drive ...', bkoutput);
        
        % delete port
        fprintf('\nclosing then deleting serial port ... \n');
        fclose(s);
        delete(s);
        
        
	%%%%%%%
    %% 4 %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% VIEW RESULTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
        fprintf('\n\n\n')
        fprintf('|$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$|\n');
        fprintf('|$$$$$$$$$$$$$$$>>>>          RESULTS          <<<<$$$$$$$$$$$$$$$|\n');
        fprintf('|$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$|\n');
        fprintf('\n\n')
        
       % parse data
       parseddata = mparse2260binaryfile_matlab7(filelocal, infoflag);
       save('measurementData.mat','parseddata');
       
        getStringInput('Press ENTER to view full data set',true);
        dispStruct(parseddata)


end