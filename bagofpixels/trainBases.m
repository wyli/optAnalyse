function [] = trainBases(...
        xmlSet, outputSet, trainInd, windowSize, subSize, step3d, k)
fprintf('%s find %d clusters on %d small window\n', datestr(now), k, subSize);
% params
global numOfSubsamples;
numOfSubsamples = 10;
% input
xmlFiles = dir([xmlSet '/*.xml']);
cuboidSet = [outputSet '/cuboid_%d/%s'];

% output
clusterFile = [outputSet, '/clusters.mat'];

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
    clear localMat;
end
[~, clusters] = kmeans(localMat, k);
save(clusterFile, 'clusters');
end

function localCuboid = sampleSubCuboids(image3d, wSize, wStep)
global numOfSubsamples;
imgSize = size(image3d);
halfSize = cell(wSize/2);

xs = halfSize:wStep:(imgSize(1) - halfSize);
ys = halfSize:wStep:(imgSize(2) - halfSize);
zs = halfSize:wStep:(imgSize(3) - halfSize);

xs = randperm(xs, numOfSubsamples);
ys = randperm(ys, numOfSubsamples);
zs = randperm(zs, numOfSubsamples);

localCuboid = zeros(numOfSubsamples, wSize^3);
for i = 1:numOfSubsamples
    sampleCell = getSurroundCuboid(...
        image3d, [xs(i), ys(i), zs(i)], [wSize, wSize, wSize]);
    localCuboid(i, :) = sampleCell(:)';
end
end
