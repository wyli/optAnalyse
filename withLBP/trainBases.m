function [] = trainBases(...
        xmlSet, outputSet, baseSet, trainInd, windowSize, subSize, step3d, k)
fprintf('%s find %d clusters on small window %d\n', datestr(now), k, subSize);
% params
global numOfSubsamples;
numOfSubsamples = 4;
% input
xmlFiles = dir([xmlSet '/*.xml']);
cuboidSet = [outputSet '/cuboid_%d/%s'];

% output
clusterFile = [baseSet, '/clusters.mat'];

localSet = [];
for i = 1:size(trainInd, 1)
    rec = VOCreadxml([xmlSet '/' xmlFiles(trainInd(i)).name]);
    name = rec.annotation.index;
    cuboidFile = sprintf(cuboidSet, windowSize, name);
    load(cuboidFile);
    cuboid = cuboid(1,:);

    idMat = ones(1, size(cuboid, 2));
    repSize = mat2cell(idMat.*subSize, 1, idMat);
    repStep = mat2cell(idMat.*step3d, 1, idMat);
    localCells = cellfun(@sampleSubCuboids,...
        cuboid, repSize, repStep, 'UniformOutput', false);
    localMat = cell2mat(localCells');
    clear localCells cuboid;
    localSet = [localSet; localMat];
end
opts = statset('MaxIter', 500);
[~, clusters] = kmeans(localSet, k,...
    'Start', 'cluster', 'Replicates', 3, 'Options', opts);
save(clusterFile, 'clusters');
end

function localCuboid = sampleSubCuboids(image3d, wSize, wStep)
global numOfSubsamples;
imgSize = size(image3d);
halfSize = ceil(wSize/2);

xs = halfSize:wStep:(imgSize(1) - halfSize);
ys = halfSize:wStep:(imgSize(2) - halfSize);
zs = halfSize:wStep:(imgSize(3) - halfSize);

xs = randsample(xs, min(length(xs), numOfSubsamples));
ys = randsample(ys, min(length(ys), numOfSubsamples));
zs = randsample(zs, min(length(zs), numOfSubsamples));

localCuboid = zeros(numOfSubsamples, wSize^3);
for i = 1:numOfSubsamples
    sampleCell = getSurroundCuboid(...
        image3d, [xs(i), ys(i), zs(i)], [wSize, wSize, wSize]);
    localCuboid(i, :) = sampleCell(:)';
end
end
