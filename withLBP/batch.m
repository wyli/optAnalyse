% set uniform patterns for LBP
addpath('~/documents/optAnalyse/STLBP_Matlab');
% end of set

addpath('~/documents/optAnalyse/libsvm');
addpath('~/documents/optAnalyse/liblinear');
addpath('~/documents/optAnalyse/pwmetric');
RandStream.setDefaultStream(RandStream('mrg32k3a', 'seed', sum(100*clock)));

xmlSet = '~/desktop/description';
imgSet = '~/desktop/OPTmix';
generate_scheme = 1;
needDrawSamples = 0;
needTrainBases = 1;
needExtractFeatures = 1;
needClassifyVectors = 1;

id='5';
baseFile = '~/desktop/output';
if isempty(id)
    id = datestr(now, 30);
end
outputSet = sprintf('%s/LBP_%s', baseFile, id);
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
INCInd(end+1) = 60;
LGDInd = LGDInd(randperm(size(LGDInd, 2)));
INCInd = INCInd(randperm(size(INCInd, 2)));
allInd = zeros(1, 60);
allInd(1, 1:2:end) = LGDInd;
allInd(1, 2:2:end) = INCInd;
% ten fold cross valid='13';
if generate_scheme
    k = 10;
    foldSize = 6;
    allInd = reshape(allInd, foldSize, []);
    testScheme = eye(k, 'int8');
    save([outputSet '/exparam'], 'testScheme', 'allInd');
else
    load([outputSet '/exparam']);
end



for f = 1:length(testScheme)
    
    trainInd = allInd(:, ~testScheme(f, :));
    trainInd = trainInd(:);
    trainInd = trainInd(trainInd ~= 60);
    testInd = allInd(:, f);
    testInd = testInd(testInd ~= 60);

    subSize= 5;
    step3d = 1;

    k = 200;

    resultSet = sprintf('%s/result_%d', outputSet, f);
    mkdir(resultSet);
    % find k clusters in all training samples
    baseSet = sprintf('%s/result_%d/base', outputSet, f);
    mkdir(baseSet);
    if needTrainBases
        trainBases(xmlSet, outputSet, baseSet,...
            trainInd, windowSize, subSize, step3d, k);
    end

    % extract features from train, valid='13';
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
