function varargout = PCF_GUI(varargin)
% PCF_GUI MATLAB code for PCF_GUI.fig
%      PCF_GUI, by itself, creates a new PCF_GUI or raises the existing
%      singleton*.
%
%      H = PCF_GUI returns the handle to a new PCF_GUI or the handle to
%      the existing singleton*.
%
%      PCF_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PCF_GUI.M with the given input arguments.
%
%      PCF_GUI('Property','Value',...) creates a new PCF_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before PCF_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to PCF_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help PCF_GUI

% Last Modified by GUIDE v2.5 21-Jun-2022 20:34:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PCF_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @PCF_GUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before PCF_GUI is made visible.
function PCF_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to PCF_GUI (see VARARGIN)

% Choose default command line output for PCF_GUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes PCF_GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = PCF_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in extractRawData.
function extractRawData_Callback(hObject, eventdata, handles)
% hObject    handle to extractRawData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = guidata(hObject);

ReadCaptureCsv(hObject);

y = handles.y;

NrBits = 0;
NrBitsArray = zeros(length(y),1);
LvByteTransferActive = 0;

RawData = uint8(zeros(100000,1));
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

RawData = RawData(1:ByteNr+100);    % trim to needed size
handles.RawData = RawData;
handles.ByteNr = ByteNr;


set(handles.RawBytesStatus,'String', sprintf('Data Extraction:\n %d bytes detected',ByteNr));

guidata(hObject,handles);



% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over extractRawData.
function extractRawData_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to extractRawData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in openCapture.
function openCapture_Callback(hObject, eventdata, handles)
% hObject    handle to openCapture (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

handles.MSCL_Column_CSV = 2;
handles.MSDA_Column_CSV = 3;
handles.VCC_Column_CSV = 4;

[file,path] = uigetfile('*.csv');

if(file ~= 0)

    handles.CsvFile = file;
    handles.CsvPath = path;

    fileDisplayString = strcat(path,file);
    fileDisplayString = strcat('...',fileDisplayString(length(fileDisplayString)-25:length(fileDisplayString)));
    set(handles.SelectedCsvFile,'String', fileDisplayString);

    fileDisplayString = strcat(path,'RawByteOutput.bin');
    fileDisplayString = strcat('...',fileDisplayString(length(fileDisplayString)-25:length(fileDisplayString)));
    set(handles.SelectedRawOutputFile,'String',fileDisplayString);
    handles.RawDataOutputFilePath = path;
    handles.RawDataOutputFileName = 'RawByteOutput.bin';
    
    fileDisplayString = strcat(path,'EEROM.bin');
    fileDisplayString = strcat('...',fileDisplayString(length(fileDisplayString)-25:length(fileDisplayString)));
    set(handles.EEROMFileSelected,'String', fileDisplayString);
    
    fileDisplayString = strcat(path,'EROM.bin');
    fileDisplayString = strcat('...',fileDisplayString(length(fileDisplayString)-25:length(fileDisplayString)));
    set(handles.EROMFileSelected,'String', fileDisplayString);


    T = readtable(fullfile(path,file),'Format','%f%f%f%f');
    
    % Clear Popup menus
    handles.MSDA_ChSelect_pupupmenu.String = [];
    handles.MSCL_ChSelect_pupupmenu.String = [];
    handles.VCC_ChSelect_pupupmenu.String = [];
    
    
    for i=2:length(T.Properties.VariableNames)
        PopUpMenuEntries(i-1) = T.Properties.VariableNames(i);
    end
    
    if(~isempty(find(contains(PopUpMenuEntries,'SDA'),1)))
        handles.MSDA_Column_CSV = find(contains(PopUpMenuEntries,'SDA'),1);
    end
    if(~isempty(find(contains(PopUpMenuEntries,'SCL'),1)))
        handles.MSCL_Column_CSV = find(contains(PopUpMenuEntries,'SCL'),1);
    end
    if(~isempty(find(contains(PopUpMenuEntries,'VCC'),1)))
        handles.VCC_Column_CSV = find(contains(PopUpMenuEntries,'VCC'),1);
    end
        
    handles.MSDA_ChSelect_pupupmenu.String = PopUpMenuEntries;
    handles.MSCL_ChSelect_pupupmenu.String = PopUpMenuEntries;
    handles.VCC_ChSelect_pupupmenu.String = PopUpMenuEntries;
    
    handles.MSDA_ChSelect_pupupmenu.Value = handles.MSDA_Column_CSV-1;
    handles.MSCL_ChSelect_pupupmenu.Value = handles.MSCL_Column_CSV-1;
    handles.VCC_ChSelect_pupupmenu.Value = handles.VCC_Column_CSV-1;
        
    handles.T = T;
    clear T;
    guidata(hObject,handles);
end

function ReadCaptureCsv(hObject)
    
    handles = guidata(hObject);
    
    y(:,1) = handles.T{:,handles.MSCL_Column_CSV}; % Clk
    y(:,2) = handles.T{:,handles.MSDA_Column_CSV}; % SDA
    y(:,3) = handles.T{:,handles.VCC_Column_CSV}; % VCC
    y = int8(y);
    
    handles.y = y;
    
    guidata(hObject,handles);

% --- Executes on button press in SaveRawData.
function SaveRawData_Callback(hObject, eventdata, handles)
% hObject    handle to SaveRawData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = guidata(hObject);

if(isfield(handles, 'ByteNr') && handles.ByteNr > 0 && isfield(handles, 'RawData'))
    RawData = handles.RawData;
    fhandler=fopen(fullfile(handles.RawDataOutputFilePath,handles.RawDataOutputFileName),'w');
    fwrite(fhandler,RawData);
    fclose(fhandler);
else
    warndlg('No raw bytes detected or detection not started yet!','Warning');
end



% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over openCapture.
function openCapture_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to openCapture (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in RawOutputFileSelector.
function RawOutputFileSelector_Callback(hObject, eventdata, handles)
% hObject    handle to RawOutputFileSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

[filename, path] = uiputfile('RawByteOutput.bin');
if(filename ~= 0)
    handles.RawDataOutputFileName = filename;
    handles.RawDataOutputFilePath = path;
else
    filename = handles.RawDataOutputFileName;
    path = handles.RawDataOutputFilePath;
end

fileDisplayString = strcat(path,filename);
fileDisplayString = strcat('...',fileDisplayString(length(fileDisplayString)-25:length(fileDisplayString)));
set(handles.SelectedRawOutputFile,'String', fileDisplayString);

guidata(hObject, handles);


% --- Executes on button press in ExtractPcfDumps.
function ExtractPcfDumps_Callback(hObject, eventdata, handles)
% hObject    handle to ExtractPcfDumps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% Rawdata Parser
handles = guidata(hObject);

if(isfield(handles,'RawData') && ~isempty(handles.RawData))
    RawData = handles.RawData;
    
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
            elseif idx == 6 %% C_WR_EEROM command
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


    % Revert extracted EEROM bytes as they are transmitted in bit-reverse order
    EEROM_dump_rev = uint8(zeros(length(EEROM_dump),1));
    for byte_nr=1:length(EEROM_dump)
        EEROM_dump_rev(byte_nr)=sum(uint8(bitset(0,1:8,bitget(uint8(EEROM_dump(byte_nr)), 8:-1:1))));
    end
    
    handles.EEROM_dump_rev = EEROM_dump_rev;
    handles.EROM_dump = EROM_dump;
    
    guidata(hObject,handles);
end


% --- Executes on button press in pushbutton7.
function pushbutton7_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

% Write EROM to file
fhandler = fopen(fullfile(handles.RawDataOutputFilePath,'EROM.bin'),'w');
fwrite(fhandler,handles.EROM_dump);
fclose(fhandler);

fhandler = fopen(fullfile(handles.RawDataOutputFilePath,'EEROM.bin'),'w');
fwrite(fhandler,handles.EEROM_dump_rev);
fclose(fhandler);


% --- Executes on selection change in MSDA_ChSelect_pupupmenu.
function MSDA_ChSelect_pupupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to MSDA_ChSelect_pupupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

handles.MSDA_Column_CSV = handles.MSDA_ChSelect_pupupmenu.Value;

guidata(hObject,handles);

% Hints: contents = cellstr(get(hObject,'String')) returns MSDA_ChSelect_pupupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from MSDA_ChSelect_pupupmenu


% --- Executes during object creation, after setting all properties.
function MSDA_ChSelect_pupupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MSDA_ChSelect_pupupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in MSCL_ChSelect_pupupmenu.
function MSCL_ChSelect_pupupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to MSCL_ChSelect_pupupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

handles.MSCL_Column_CSV = handles.MSCL_ChSelect_pupupmenu.Value;

guidata(hObject,handles);
% Hints: contents = cellstr(get(hObject,'String')) returns MSCL_ChSelect_pupupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from MSCL_ChSelect_pupupmenu


% --- Executes during object creation, after setting all properties.
function MSCL_ChSelect_pupupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MSCL_ChSelect_pupupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in VCC_ChSelect_pupupmenu.
function VCC_ChSelect_pupupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to VCC_ChSelect_pupupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

handles.VCC_Column_CSV = handles.VCC_ChSelect_pupupmenu.Value;

guidata(hObject,handles);

% Hints: contents = cellstr(get(hObject,'String')) returns VCC_ChSelect_pupupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from VCC_ChSelect_pupupmenu


% --- Executes during object creation, after setting all properties.
function VCC_ChSelect_pupupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to VCC_ChSelect_pupupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
