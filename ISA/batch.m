addpath('~/documents/optAnalyse/libsvm');
addpath('~/documents/optAnalyse/liblinear');
xmlSet = '~/desktop/description';
imgSet = '~/desktop/OPTmix';
needDrawSamples = 1;
needTrainBases = 1;
needExtractFeatures = 1;
needClassifyVectors = 1;

id = '';
baseFile = '~/desktop/output';
if isempty(id)
    id = datestr(now, 30);
end
outputSet = sprintf('%s/exp_%s', baseFile, id);
mkdir(outputSet);
diary([outputSet '/exp.log']);
fprintf('%s %s\n', datestr(now), 'starting batch...');

% draw samples
windowSizeL1 = 17;
windowSizeL2 = 21;
if needDrawSamples
    drawSamples(imgSet, xmlSet, outputSet, windowSizeL1);
    drawSamples(imgSet, xmlSet, outputSet, windowSizeL2);
end

% randomly split dataset
files = dir([xmlSet, '/*.xml']);
fileInd = randsample(size(files, 1), size(files, 1));
trainInd = fileInd(1:15);
validInd = fileInd(16:20);
testInd = fileInd(21:end);

% train representative bases
if needTrainBases
    trainBases(xmlSet, outputSet, trainInd, [windowSizeL1, windowSizeL2]);
end

% extract features from train, validation, test set
if needExtractFeatures
    extractISAFeatures(xmlSet, outputSet, [windowSizeL1, windowSizeL2]);
end

% classify vectors
if needClassifyVectors
    classifyVectors(xmlSet, outputSet, {trainInd; validInd; testInd});
end
