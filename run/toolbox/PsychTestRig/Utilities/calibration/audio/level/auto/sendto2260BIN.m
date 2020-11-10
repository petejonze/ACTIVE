function Output=sendto2260BIN(SO,Message)
% function Output = sendto2260BIN(SO,Message)
%
% ---------------------------------------------
% Sends a command to the soundlevel meter and gets the output too
% Set for type 2260 meter
% -----------------------------------------------
%
% SENDTO2260BIN, sends binary data to the 2260 one char at a time and reads the 2260 echoed char to confirm the char was received.
% SENDTO2260BIN, breaks a message string into individual binary chars which it sends, 
% and reads the 2260 echo of, one char at a time. It then outputs any relevent message.
%
%
% MAA ... command should be abbreviation 
% eg :SY:A:A? not :SYSTEM:APLLICATION:ABOUT?
% as the meter echoes the *abbrievation* back and this code pulls it off the output 
%
% MAA ... wait for 1.5 seconds at the end to give the chance for the serial
% line to clear (not really sure if this is necessary but I like it)
%
%
% Used by most of the #m...2260' commands
%
% Edited by S. Maver , v 1.0, 06/05/2003
% Edited by Pete Jones , 15/07/2010
%------------------------------------------------------------------------------------



% First check the serial device is valid(open)
if SO.status ~= 'open'
    warning off backtrace;   % doesnt display the line number of the warning trigger
    warning('Serial device not ready.');
end % if

%To surpress the unsuccessful fscanf read (you could change the terminator, but what to?)
%warning off MATLAB:serial:fscanf:unsuccessfulRead %may need it eventually

CopyOfMessage = Message ;
MsgCount = 1; % start at 1 not 0
MsgEnd = length(CopyOfMessage);

fprintf('\nSending data:');
for I = 1:length(Message),       % For... the whole message string,
    fwrite(SO,double(Message(I))); % write one binary char,
    echo = fread(SO,1);           % read that char back to confirm it was received ok ,
%     if debug
%         fprintf('sent == %i',double(Message(I)));
%         fprintf('   ....     received == %i\n',double(echo));
%     end
    fprintf(' .');
    % using binary read so we can ignore the terminator, which isnt defined for 2260 echoes.
    if echo ~= double(Message(I))        % if it wasnt output a message...
        warning off backtrace;   % doesnt display the line number of the warning trigger
        warning('Message not echoed from 2260 correctly.');
        error = double(Message(I));
        return;
    end % if
end % for
fprintf('\n');

% The Message string is sent, so send the LineFeed(LF or char(10)) to
% terminate input.
fwrite(SO,double(char(10)));
echo = fread(SO,1); %Read back the final LF

if echo ~= double(char(10))
    warning off backtrace;   % doesnt display the line number of the warning trigger
    warning('Problem reading End Of Line.');
    return;
end % if

%Now grab the 2260 output
if CopyOfMessage(MsgEnd) == '?'
    TrueOutput = fscanf(SO);
    OutputEnd = length(TrueOutput);
else
    warning off MATLAB:serial:fscanf:unsuccessfulRead ;
    TrueOutput = fscanf(SO);
    OutputEnd = length(TrueOutput);
end %if
warning on MATLAB:serial:fscanf:unsuccessfulRead ; % reset warning in case its needed


% Modify the output to remove the original command for ease of reading
% For this to work we need to send shorthand commands instead of full words
% as the 2260 responds this way



% CopyOfMessage
if CopyOfMessage(MsgEnd) == '?' % we're only dealing with output to questions right now!
    if OutputEnd > 0  %if anything was read back
       for J = 1:MsgEnd, % for every char in original command
            if (CopyOfMessage(J) == TrueOutput(J)) %if its the same char
                MsgCount = MsgCount + 1;    %increase the eventual first char marker
            end % if
        end %for
        MsgCount = MsgCount +1; % add one to get rid of spac char
        Output = TrueOutput(MsgCount:OutputEnd);
    else % if nothing was read back
        Output = '';
        %warning('No output detected from 2260!');
        %return;
    end %if > 0
else % all output to commands is passed through untouched right now.
    if OutputEnd > 0 % except for zero length output which we convert for error checking
        Output = TrueOutput;
    else
        Output = '';
    end % if > 0
end % if ?

% MAA wait about a second anyway
pause(0.5);

