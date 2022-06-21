# PCF_Analysis
Collection of tools and skripts for analyzing data of PCF79xx automotive transponders

# Requirements
For using the .m file scripts, a Matlab installation is required. Eventually, the scripts are also compatible with GNU Octave

# Detail Description:

1. **MDI_RawByte_Extractor.m**

 - Extracts all the raw bytes sent on the monitor and download interface (MDI) of a PCF79xx type transponder. Input is a capture of the PCF's SDA, SCL and VCC signal provided as .csv file

2. **MDI_PCF_Dump_Extractor.m**

-  From a raw byte stream transmittet on MDI, the command packets are detected. All commands are storad in a log structure. Based on the EEROM and EEPROM programming commands, the resulting EEPROM and EEROM dump is reconstructed and stored in a given path
