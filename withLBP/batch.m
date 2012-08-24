addpath('~/documents/optAnalyse/libsvm');
addpath('~/documents/optAnalyse/liblinear');
addpath('~/documents/optAnalyse/pwmetric');
addpath('~/documents/optAnalyse/STLBP_Matlab');
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

    subSize = 5;
    step3d = 5;
    k = 200;

    resultSet = sprintf('%s/result_%d', outputSet, f);
    mkdir(resultSet);
    % find k clusters in all training samples
    baseSet = sprintf('%s/result_%d/base', outputSet, f);
    if needTrainBases
        trainBases(xmlSet, outputSet, baseSet,...
            trainInd, windowSize, subSize, step3d, k);
    end

    % extract features from train, validation, test set
    feaSet = sprintf('%s/result_%d/feaSet', outputSet, f);
    if needExtractFeatures
        extractLBPFeatures(xmlSet, outputSet, baseSet, feaSet,...
            windowSize, subSize, step3d);
    end

    % classify vectors
    if needClassifyVectors
        classifyVectors(xmlSet, feaSet, resultSet,...
            {trainInd; testInd});
    end
end
diary off;
