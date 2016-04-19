function MCCRecordData(context, newData)
dataTime = max(newData(:,3));
newData(:,4) = context.cacheRow;
context.dataMap(dataTime) = newData;