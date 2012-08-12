xmlSet = '~/desktop/description';
imgSet = '~/desktop/OPTmix';
needDrawSamples = 1;
needSplitSet = 0;
needTrainBases = 0;
needExtractFeatures = 1;
needClassifyVectors = 0;

id = '20120812T005342';
baseFile = '~/desktop/output';
if isempty(id)
    id = datestr(now, 30);
end
outputSet = sprintf('%s/exp_%s', baseFile, id);
mkdir(outputSet);

windowSizeL1 = 16;
windowSizeL2 = 21;
if needDrawSamples
    drawSamples(imgSet, xmlSet, outputSet, windowSizeL1);
    drawSamples(imgSet, xmlSet, outputSet, windowSizeL2);
end