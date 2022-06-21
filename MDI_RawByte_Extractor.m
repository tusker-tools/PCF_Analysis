%% General Description
% This script reads a CSV file containing a communication on MDI interface
% (MSDA, MSDL and BATT line)of a PCF97xx automotive key transponder chip.
% It extracts the raw bytes transferred and saves them to a file


%% This section has to be adapted by the user
% Logic analyzer capture file
CsvCaptureFile = 'c:\Users\Testuser\PCF_capture.csv';

% Raw data file path
RawDataOutFile = 'c:\Users\Testuser\MDA_Rawdata.bin';

% Write RawData to File?
LvRawDataOutput = 0;

% Specify at which position of the CSV which Signal was captured
% MSCL Signal
MSCL_Column_CSV = 2;
MSDA_Column_CSV = 3;
VCC_Column_CSV = 4;

% Activate Signal Plotting
LvPlotSignals = 1;


%% Beginning of Data Processing
T = readtable(CsvCaptureFile,'Format','%f%f%f%f');

y(:,1) = T{:,MSCL_Column_CSV}; % Clk
y(:,2) = T{:,MSDA_Column_CSV}; % SDA
y(:,3) = T{:,VCC_Column_CSV}; % VCC
y = int8(y);

if(LvPlotSignals)
    time = T{:,1};
    
    figure;
    axSCL = axes();
    axSDA = axes();
    axVCC = axes();
    axTEST = axes();
    linkaxes([axSCL,axSDA,axVCC,axTEST],'x')

    stairs(axSCL,time,y(:,1));
    stairs(axSDA,time,y(:,2));
    stairs(axVCC,time,y(:,3));

    set([axSCL,axSDA,axVCC,axTEST],'Color', 'None', 'Box', 'on')
    ylim(axSCL,[-0.1 5.1]);
    ylim(axSDA,[-1.1 3.9]);
    ylim(axVCC,[-2.2 2.8]);
    ylim(axTEST,[-3.3 1.7]);
end


%% Detect Edges
tic;



%% Raw byte detection
NrBits = 0;
NrBitsArray = zeros(length(y),1);
LvByteTransferActive = 0;

RawData = uint8(zeros(10000,1));
ByteNr = 1;

for i=2:length(y)
    % Calculate Edges
    LvSdaFallEdge = (y(i,2)-y((i-1),2)) < 0;
    LvSdaRiseEdge = (y(i,2)-y((i-1),2)) > 0;
    LvClkFallEdge = (y(i,1)-y((i-1),1)) < 0;
    LvSdaFallWhileSclLow = LvSdaFallEdge & (y(i,1) == 0);
    
    % Process Signals
    if (LvSdaFallWhileSclLow && (NrBits == 0) && ~LvByteTransferActive)
        LvByteTransferActive = 1;
    else
        if LvByteTransferActive && y(i,3)
           if NrBits < 8
            if LvClkFallEdge
                if(LvSdaFallEdge || LvSdaRiseEdge)
                    RawData(ByteNr) = bitor(RawData(ByteNr),uint8(bitshift(uint8(y(i-1,2)),NrBits)));
                else
                    RawData(ByteNr) = bitor(RawData(ByteNr),uint8(bitshift(uint8(y(i,2)),NrBits)));
                end
                NrBits = NrBits+1;
            end
            if NrBits == 8
                LvByteTransferActive = 0;
                NrBits = 0;
                ByteNr = ByteNr + 1;
            else
                LvByteTransferActive = 1;
            end
           end
        else
            LvByteTransferActive = 0;
        end
    end
    NrBitsArray(i) = NrBits;
end

if(LvPlotSignals)
    hold on;
    stairs(axTEST,time,NrBitsArray./8);
end

if (LvRawDataOutput)
    fhandler=fopen(RawDataOutFile,'w');
    fwrite(fhandler,RawData);
    fclose(fhandler);
end