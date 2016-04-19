clear
clear classes
clc

mcc = MCCOpen;

elements = mexHID('summarizeElements', mcc.primaryID);
types = [elements.Type];
reports = [elements.ReportID];

isJuicy = reports == 21;
[elements(isJuicy).ElementCookie]


mexHID('terminate');