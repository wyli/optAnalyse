addpath('U:/github/optAnalyse/libsvm');
addpath('U:/github/optAnalyse/liblinear');
addpath('U:/github/optAnalyse/pwmetric');
xmlSet = 'U:/OPTannotation/description';
imgSet = 'U:/OPTannotation/OPTmix';
needDrawSamples = 0;
needTrainBases = 1;
needExtractFeatures = 1;
needClassifyVectors = 1;

id = '20120906T045201';
baseFile = 'U:/optresults';
if isempty(id)
    id = datestr(now, 30);
end
outputSet = sprintf('%s/exp_%s', baseFile, id);
mkdir(outputSet);
diary([outputSet '/exp.log']);
fprintf('%s %s\n', datestr(now), 'starting batch...');

% draw samples
windowSize = 21;
if needDrawSamples
    drawSamples(imgSet, xmlSet, outputSet, windowSize);
end

files = dir([xmlSet, '/*.xml']);
LGDInd = [];
INCInd = [];
for i = 1:length(files)
    rec = VOCreadxml([xmlSet '/' files(i).name]);
    if strcmp(rec.annotation.type, 'LGD')
        LGDInd(end+1) = i;
    else
        INCInd(end+1) = i;
    end
end
% randomly permutate
LGDInd = LGDInd(randperm(size(LGDInd, 2)));
INCInd = INCInd(randperm(size(INCInd, 2)));
allInd = zeros(1, size(files, 1));
allInd(1, 1:2:end) = LGDInd;
allInd(1, 2:2:end) = INCInd;
% ten fold cross validation
k = 10;
foldSize = 3;
allInd = reshape(allInd, foldSize, []);
testScheme = eye(k, 'int8');

for f = 1:length(testScheme)
    
    trainInd = allInd(:, ~testScheme(f, :));
    trainInd = trainInd(:);
    testInd = allInd(:, f);

    subSize = 19;
    step3d = 1;
    k = 200;

    randMat = randn(150, subSize^3);

    resultSet = sprintf('%s/result_%d', outputSet, f);
    mkdir(resultSet);
    % find k clusters in all training samples
    baseSet = sprintf('%s/result_%d/base', outputSet, f);
    mkdir(baseSet);
    if needTrainBases
        trainBases(xmlSet, outputSet, baseSet,...
            trainInd, windowSize, subSize, step3d, k,...
            randMat);
    end

    % extract features from train, validation, test set
    feaSet = sprintf('%s/result_%d/feaSet', outputSet, f);
    if needExtractFeatures
        extractBOPFeatures(xmlSet, outputSet, baseSet, feaSet,...
            windowSize, subSize, step3d, randMat);
    end

    % classify vectors
    if needClassifyVectors
        classifyVectors(xmlSet, feaSet, resultSet,...
            {trainInd; testInd});
    end
end
diary off;
