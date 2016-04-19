function info = MCCPlexonCode(mcc, code)
% Write a digital word to from the MCC 1208FS digital ports to Plexon.
%
% I'm using a Plexon MAP with digital input in "mode 3", to accept 15-bit
% strobed words.
%
% I have
%   - 1208FS digital port A0-7 connected to Plexon DSP bits 0-7
%   - 1208FS digital port B0-6 connected to Plexon DSP bits 8-14
%   - 1208FS digital port B7 connected to Plexon DSP strobe
%
% code is treated as an unsigned integer, mod 2^15.  code is sent to Plexon
% in the following steps:
%   - the low byte of code (mod 2^8) written to 1208FS port A
%   - the high byte of code (div 2^8, mod 2^7), written to 1208FS port B
%   - the high byte, plus 2^7, written to 1208FS port B (strobe high)
%   - the high byte, alone, written to 1208FS port B (strobe low)
%
% info contains mexHID status and timing information, and the formatted
% report, for each step above.

littleByte = mod(floor(code), 2^8);
bigByte = mod(floor(code/(2^8)), 2^7);

info(1).name = 'set bits A';
info(1).report = MCCFormatReport(mcc, 'DOut', mcc.DOutA, littleByte);
info(2).name = 'set bits B';
info(2).report = MCCFormatReport(mcc, 'DOut', mcc.DOutB, bigByte);
info(3).name = 'strobe high';
info(3).report = MCCFormatReport(mcc, 'DOut', mcc.DOutB, bigByte+2^7);
info(4).name = 'strobe low';
info(4).report = MCCFormatReport(mcc, 'DOut', mcc.DOutB, bigByte);

for ii = 1:numel(info)
    [info(ii).status, info(ii).timing] = mexHID('writeDeviceReport', ...
        mcc.primaryID, info(ii).report);
end