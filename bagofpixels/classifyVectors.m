function [] = classifyVectors(xmlSet, feaSet, resultSet, indexes)
fprintf('%s classify vectors\n', datestr(now));
% params
isScale = 1;
isrbf = 0;
isSubsample = 0;
numOfTrain = 10000;
% input
xmlFiles = dir([xmlSet '/*xml']);
feaSet = [feaSet '/%s'];

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
    for log2c = -5:2:10
        for log2g = 3:-2:-10
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
                    ' -g ', num2str(bestg) ' -b 1 -h 0'];
                model = svmtrain2(trainLabels, trainSet, bestCMD);
            end
        end
    end
else % linear svm
    fprintf('searching for c and epsilon\n');
    fprintf('training set size: %dx%d\n', size(trainSet, 1), size(trainSet, 2));
    bestcv = 0;
    for log10c = -5:1:5
        for log10e = -5:1:5
            cmd = ['-v 10 -s 1 -c ', num2str(10^log10c),...
                ' -e ', num2str(10^log10e)]
            cv = train(trainLabels, sparse(trainSet), cmd);
            
            if cv > bestcv
                bestcv = cv;
                bestCMD = ['-s 1 -c ', num2str(10^log10c),...
                    ' -e ', num2str(10^log10e)];
                model = train(trainLabels, sparse(trainSet), bestCMD);
            end
        end
    end
end
fprintf('%s', bestCMD);

fprintf('%s predicting\n', datestr(now));
for i = 1:size(indexes{2}, 1)
    testSet = [];
    testLabels = [];
    rec = VOCreadxml([xmlSet '/' xmlFiles(indexes{2}(i)).name]);
    [labels, data] = loadDataset(rec, feaSet);
    testSet = data;
    testLabels = labels;
    
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
    else % linear svm
        [prediction, accuracy, prob] = predict(...
            testLabels, sparse(testSet), model);
    end
    fprintf('%s saving final result\n', datestr(now));
    resultFile = sprintf('%s/%s%s', resultSet, 'result', rec.annotation.index);
    save(resultFile, 'prediction', 'accuracy', 'prob', 'rec');
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
    [prediction, ~, ~] = predict(validLabels, sparse(validSet), cModel);
    result = result + sum((prediction - validLabels)==0) / size(validLabels, 1);
end
fprintf('validate: %.3f\n', result);
end
