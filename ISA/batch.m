addpath('~/documents/optAnalyse/libsvm');
addpath('~/documents/optAnalyse/liblinear');
addpath('~/documents/optAnalyse/pwmetric');
RandStream.setDefaultStream(RandStream('mrg32k3a', 'seed', sum(100*clock)));

xmlSet = '~/desktop/description';
imgSet = '~/desktop/OPTmix';
generate_scheme = 1;
needDrawSamples = 1;
needTrainBases = 1;
needExtractFeatures = 1;
needClassifyVectors = 1;

id = '9';
baseFile = '~/desktop/output';
if isempty(id)
    id = datestr(now, 30);
end
outputSet = sprintf('%s/COVISA_%s', baseFile, id);
mkdir(outputSet);
diary([outputSet '/exp.log']);
fprintf('%s %s\n', datestr(now), 'starting batch...');

% draw samples
windowSizeL1 = 9;
windowSizeL2 = 21;
if needDrawSamples
    drawSamples(imgSet, xmlSet, outputSet, windowSizeL1);
    drawSamples(imgSet, xmlSet, outputSet, windowSizeL2);
end

% randomly split dataset
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
INCInd(end+1) = 60;
% randomly permutate
LGDInd = LGDInd(randperm(size(LGDInd, 2)));
INCInd = INCInd(randperm(size(INCInd, 2)));
allInd = zeros(1, 60);
allInd(1, 1:2:end) = LGDInd;
allInd(1, 2:2:end) = INCInd;

% ten fold cross validation
if generate_scheme
    k = 10;
    foldSize = 6;
    allInd = reshape(allInd, foldSize, []);
    testScheme = eye(k, 'int8');
else
    load([outputSet '/exparam']);
end


for f = 1:length(testScheme)

    trainInd = allInd(:, ~testScheme(f, :));
    trainInd = trainInd(:);
    trainInd = trainInd(trainInd ~= 60);
    testInd = allInd(:, f);
    testInd = testInd(testInd ~= 60);

    % train representative bases
    resultSet = sprintf('%s/result_%d', outputSet, f);
    mkdir(resultSet);
    baseSet = sprintf('%s/result_%d/base', outputSet, f);
    mkdir(baseSet);
    if needTrainBases
        trainBases(xmlSet, outputSet, baseSet,...
            trainInd, [windowSizeL1, windowSizeL2]);
    end

    % extract features from train, validation, test set
    feaSet = sprintf('%s/result_%d/feaSet', outputSet, f);
    if needExtractFeatures
        extractISAFeatures(xmlSet, outputSet, baseSet, feaSet, ...
            [windowSizeL1, windowSizeL2]);
    end

    % classify vectors
    if needClassifyVectors
        classifyVectors(xmlSet, feaSet, resultSet,...
            {trainInd; testInd});
    end
end
diary off;
