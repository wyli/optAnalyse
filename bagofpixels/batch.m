addpath('~/documents/optAnalyse/libsvm');
addpath('~/documents/optAnalyse/liblinear');
addpath('~/documents/optAnalyse/pwmetric');
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
windowSize = 31;
if needDrawSamples
    drawSamples(imgSet, xmlSet, outputSet, windowSize);
end

% randomly split dataset
files = dir([xmlSet, '/*.xml']);
fileInd = randsample(size(files, 1), size(files, 1));
trainInd = fileInd(1:15);
validInd = fileInd(16:20);
testInd = fileInd(21:end);

subSize = 3;
step3d = 3;
k = 200;
% find k clusters in all training samples
if needTrainBases
    trainBases(xmlSet, outputSet, trainInd, windowSize, subSize, step3d, k);
end

% extract features from train, validation, test set
if needExtractFeatures
    extractBOPFeatures(xmlSet, outputSet, windowSize, subSize, step3d);
end

% classify vectors
if needClassifyVectors
    classifyVectors(xmlSet, outputSet, {trainInd; validInd; testInd});
end
