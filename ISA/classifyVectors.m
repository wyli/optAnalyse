function [] = classifyVectors(xmlSet, outputSet, indexes)
fprintf('%s classify vectors\n', datestr(now));
% params
isScale = 1;
isrbf = 1;
isSubsample = 1;
numOfTrain = 12000;
% input
xmlFiles = dir([xmlSet '/*xml']);
feaSet = [outputSet '/feaSet/%s'];
% first set of indexes training
trainSet = [];
trainLabels = [];
for i = 1:size(indexes{1}, 1)
    rec = VOCreadxml([xmlSet '/' xmlFiles(indexes{1}(i)).name]);
    [labels, data]  = loadDataset(rec, feaSet);
    trainSet = [trainSet; data];
    trainLabels = [trainLabels; labels];
end

if isSubsample
    subInd = randsample(size(trainLabels, 1),...
        min(size(trainLabels, 1), numOfTrain));
    trainSet = trainSet(subInd, :);
    trainLabels = trainLabels(subInd, :);
end

if isScale
    fprintf('%s scaling dataset\n', datestr(now));
    minTrain = min(trainSet, [], 1);
    maxTrain = max(trainSet, [], 1);
    trainSet = (trainSet - repmat(minTrain, size(trainSet,1), 1))*...
        spdiags(1./(maxTrain-minTrain)',0,size(trainSet,2), size(trainSet,2));
end

if isrbf
    fprintf('searching for C and gamma\n');
    bestcv = 0;
    for log2c = -5:2:15
        for log2g = 3:-2:-15
            cmd = ['-c ', num2str(2^log2c), ' -g ', num2str(2^log2g),...
                ' -h 0 -m 1024'];
            fprintf('parameters: %s\n', cmd);
            cModel = svmtrain2(trainLabels, trainSet, cmd);
            cv = validateModel(...
                cModel, xmlSet, feaSet, indexes{2}, [maxTrain; minTrain]);
            if cv >= bestcv
                bestcv = cv;
                bestc = 2^log2c; 
                bestg = 2^log2g;
                bestCMD = ['-c ', num2str(bestc), ...
                    ' -g ', num2str(bestg) ' -b 1'];
                model = svmtrain2(trainLabels, trainSet, bestCMD);
            end
        end
    end
    fprintf('%s BestCMD: %s\n', datestr(now), bestCMD);
else
    model = train(trainLabels, sparse(trainSet), '-s 1');
end

fprintf('%s predicting\n', datestr(now));
testSet = [];
testLabels = [];
for i = 1:size(indexes{3}, 1)
    rec = VOCreadxml([xmlSet '/' xmlFiles(indexes{3}(i)).name]);
    [labels, data] = loadDataset(rec, feaSet);
    testSet = [testSet; data];
    testLabels = [testLabels; labels];

    if isScale
        fprintf('%s scaling test set\n', datestr(now));
        minTrain = min(trainSet, [], 1);
        maxTrain = max(trainSet, [], 1);
        testSet = (testSet - repmat(minTrain, size(testSet,1), 1))*...
            spdiags(1./(maxTrain-minTrain)',0,size(testSet,2), size(testSet,2));
    end
    if isrbf
        [prediction, accuracy, prob] = svmpredict(...
            testLabels, testSet, model, '-b 1');
    else
        [prediction, accuracy, prob] = predict(...
            testLabels, sparse(testSet), model, '-b 1');
    end
    fprintf('%s saving final result\n', datestr(now));
    resultFile = sprintf('%s/%s%s', outputSet, 'result', rec.annotation.index);
    save(resultFile, 'prediction', 'accuracy', 'prob');
end
%[Dtrain, Dtest] = compute_kernel_matrices(trainSet, testSet);
%clear trainSet testSet;
%n_total = length(trainLabels);
%n_pos = sum(trainLabels);
%n_neg = n_total - n_pos;
%cost = 100;
%w_pos = n_total/(2*n_pos);
%w_neg = n_total/(2*n_neg);
%option_string = sprintf('-t 4 -q -s 0 -b 1 -c %f -w1 %f -w0 %f',...
    %cost, w_pos, w_neg);
%model = svmtrain(trainLabels, trainSet, model, option_string);
%[~, accuracy, prob_est] = svmpredict(testLabels, testSet, model, '-b 1');
%save([output '/result1.mat'], 'prediction', 'accuracy', 'prob');
end

function [labels, data] = loadDataset(rec, feaSet)
name = rec.annotation.index;
type = rec.annotation.type;
feaFile = sprintf(feaSet, name);
load(feaFile);
data = X_features';
if strcmp(type, 'Cancers')
    labels = ones(size(X_features', 1) ,1);
else
    labels = -1 * ones(size(X_features', 1), 1);
end
end

function result = validateModel(cModel, xmlSet, feaSet, fileInd, maxMin)
xmlFiles = dir([xmlSet '/*xml']);
result = 0;
for i = 1:size(fileInd, 1)
    rec = VOCreadxml([xmlSet '/' xmlFiles(fileInd(i)).name]);
    [validLabels, validSet] = loadDataset(rec, feaSet);
    if ~isempty(maxMin)
        maxTrain = maxMin(1,:);
        minTrain = maxMin(2,:);
        validSet = (validSet - repmat(minTrain, size(validSet,1), 1))*...
           spdiags(1./(maxTrain-minTrain)',0,size(validSet,2),size(validSet,2));
    end
    [prediction, ~, ~] = svmpredict(validLabels, validSet, cModel);
    result = result + sum((prediction - validLabels)==0) / size(validLabels, 1);
end
fprintf('validate: %.3f\n', result);
end
