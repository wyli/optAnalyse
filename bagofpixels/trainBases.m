function [] = trainBases(...
        xmlSet, outputSet, baseSet, trainInd,...
        windowSize, subSize, step3d, k, randMat)
fprintf('%s find %d clusters on small window %d\n', datestr(now), k, subSize);
% params
global numOfSubsamples;
numOfSubsamples = 4;
samplesPerFile = 800;
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
    r = randsample(size(cuboid,2), min(size(cuboid,2), samplesPerFile));
    cuboid = cuboid(1,r);

    idMat = ones(1, size(cuboid, 2));
    repSize = mat2cell(idMat.*subSize, 1, idMat);
    repStep = mat2cell(idMat.*step3d, 1, idMat);
    localCells = cellfun(@sampleSubCuboids,...
        cuboid, repSize, repStep, 'UniformOutput', false);
    localMat = cell2mat(localCells');
    clear localCells cuboid;
    localSet = [localSet; localMat];
end
opts = statset('MaxIter', 200);
localSet = (randMat*localSet')';
assert(size(localSet, 1) > 40000, '%d %d', size(localSet, 1), size(localSet, 2));
r = randsample(size(localSet, 1), 40000);
localSet = localSet(r, :);
%[~, clusters] = kmeans(localSet, k,...
%    'Start', 'cluster',...
%    'Replicates', 2,...
%    'EmptyAction', 'singleton',...
%    'Options', opts);
prm.nTrial = 3;
prm.maxIter = 200;
[~, clusters] = kmeans2(localSet, k, prm);
save(clusterFile, 'clusters');
end

function localCuboid = sampleSubCuboids(image3d, wSize, wStep)
global numOfSubsamples;
imgSize = size(image3d);
halfSize = ceil(wSize/2);

xs = halfSize:wStep:(imgSize(1) - halfSize);
ys = halfSize:wStep:(imgSize(2) - halfSize);
zs = halfSize:wStep:(imgSize(3) - halfSize);

xrec = min(length(xs), numOfSubsamples);
yrec = min(length(ys), numOfSubsamples);
zrec = min(length(zs), numOfSubsamples);

xs = randsample(xs, xrec);
ys = randsample(ys, yrec);
zs = randsample(zs, zrec);

localCuboid = zeros(numel(xs), wSize^3);
for i = 1:numel(xs)
    sampleCell = getSurroundCuboid(...
        image3d, [xs(i), ys(i), zs(i)], [wSize, wSize, wSize]);
    localCuboid(i, :) = sampleCell(:)';
end
end
