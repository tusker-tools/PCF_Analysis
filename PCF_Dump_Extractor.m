%% General Description
% This script parses a byte stream transmitted on the MDI interface of a
% PCF79xx automotive transponder chip. It detects the sent commands and
% provides following information:
% - Full log of all detected commands
% - Extract the EROM binary which was written to the PCF
% - Extract the EEROM binary which was written to the pcf


%% This section has to be adapted by the user

% Raw data input: Read raw data from file (if 0, RawData is taken from workspace
LvRawDataFromFile = 1;
% Raw data file
RawDataFile = 'c:\Users\Testuser\RawByteOutput.bin';

% Write log of MDI communication to file?
LvWriteLogFile = 0;
% Location to the log file
LogFile = 'c:\Users\Testuser\MDI_Log.txt';

% Location where extracted dumps shall be written
EEROMDumpFile = 'c:\Users\Testuser\\EEROM.bin';
EROMDumpFile = 'c:\Users\Testuser\EROM.bin';

%% Rawdata Parser

% Read raw data from file
fhandler=fopen(RawDataFile,'r');
RawData = (fread(fhandler));
fclose(fhandler);

% Define all commands
    Texts =         {'C_CONNECT',   'C_TRACE',  'C_ER_EROM',    'C_WR_EROM',    'C_WR_EROM64',  'C_WR_EEROM',   'C_SETDAT', 'C_PROG_CONFIG',    'C_PROTECT',    'C_GETDAT'};
    CmdBytes =      {'0x55',        '0x02',     '0x08',         '0x09',         '0x18',         '0x0A',         '0x04',     '0x14',             '0x12',         '0x03'};
    PacketLength=   {1 ,            3,          19,             35,             35,             7,              3,          4,                  2,              4};
    LvHasResponse = {0 ,            1,          1,              1,              1,              1,              0,          1,                  1,              0};
    LvHasAddress =  {0 ,            0,          1,              1,              1,              1,              1,          0,                  0,              0};




% Function to convert hex string to dec value
hexstring2dec = @(j) sscanf(j,'%x');

% Setup command struct array
Commands = struct('Text',Texts,'CmdByte', cellfun(hexstring2dec,CmdBytes,'UniformOutput',0), 'PacketLength', PacketLength, 'LvHasResponse', LvHasResponse, 'LvHasAddress', LvHasAddress);
clear Texts CmdBytes PacketLength LvHasResponse LvHasAddress;

% Function to search for a command and output 1 if command was found
fun = @(i,SearchForCmd) Commands(i).CmdByte == SearchForCmd;

ParseLog = strings(1000,1);
i=1;
Packet = 1;
Response = 'NOK';
ErrPacketCnt = 0;
Address = 0;

% Initialize dumps
EEROM_dump = uint8(zeros(1024,1));
EROM_dump = uint8(zeros(8192,1));

while (i < length(RawData)) && (ErrPacketCnt < 10)
    searcher = RawData(i);
    idx = find(arrayfun(fun, [1:numel(Commands)],uint8(zeros(1,numel(Commands)))+searcher));
    
    if(length(idx)==1)  %% Command known
        
        ErrPacketCnt = 0;
        
        if Commands(idx).LvHasResponse
            if (bitget(RawData(i+Commands(idx).PacketLength-1),7)) %PERR Bit set
                Response = 'NOK';
            else
                Response = 'OK';
            end
        else
            Response = '';
        end
            
        if Commands(idx).LvHasAddress
            Address = [' 0x', sprintf('%X',RawData(i+1))];
        else
            Address = '';
        end
        
        % Extract EROM and EEROM dump from write commands
        if idx == 4 % C_WR_EROM command
            EROM_dump(uint32(RawData(i+1))*32+1:(uint32(RawData(i+1))*32+32)) = RawData(i+2:i+33);    % Collect 32 bytes raw data
        elseif idx == 5 % C_WR_EROM64 command
            EROM_dump(uint32(RawData(i+1))*64+1:(uint32(RawData(i+1))*64+64)) = RawData(i+2:i+65);    % Collect 64 bytes raw data
        elseif idx == 6 % C_WR_EEROM command
            EEROM_dump(uint32(RawData(i+1))*4+1:(uint32(RawData(i+1))*4+4)) = RawData(i+2:i+5);    % Collect 32 bytes raw data
        elseif idx == 2 % Special handling for C_TRACE: In case PCF is in protected mode, it does not respond with 0x00
            if RawData(i+1) ~=0
                i= i-2;
            end
        end
        
        ParseLog(Packet) = ['At offset 0x',sprintf('%X',i),' : ', Commands(idx).Text, Address, ' .... ', Response];
        
        i = i + Commands(idx).PacketLength; % Set index to next packet start
    else
        disp(['Cmd 0x', sprintf('%x',searcher), ' found at address 0x', sprintf('%x',i), ' not known']);
        ParseLog(Packet) = ['Cmd 0x', sprintf('%x',searcher), ' found at address 0x', sprintf('%x',i), ' not known'];
        i=i+1;
        ErrPacketCnt = ErrPacketCnt + 1;
    end
    
    Packet = Packet + 1;
end

% Write the Log File
ParseLogCell=cellstr(ParseLog);
if LvWriteLogFile
    fhandler = fopen(LogFile,'w');
    fwrite(fhandler,ParseLogCell,'char');
end



fhandler = fopen(EEROMDumpFile,'w');

% Revert extracted EEROM bytes as they are transmitted in bit-reverse order
EEROM_dump_rev = uint8(zeros(length(EEROM_dump),1));
for byte_nr=1:length(EEROM_dump)
    EEROM_dump_rev(byte_nr)=sum(uint8(bitset(0,1:8,bitget(uint8(EEROM_dump(byte_nr)), 8:-1:1))));
end
% Write EEROM to file
fwrite(fhandler,EEROM_dump_rev);
fclose(fhandler);

% Write EROM to file
fhandler = fopen(EROMDumpFile,'w');
fwrite(fhandler,EROM_dump);
fclose(fhandler);

clear EEROMDumpFile EROMDumpFile