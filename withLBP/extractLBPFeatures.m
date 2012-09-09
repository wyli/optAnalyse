function [] = extractLBPFeatures(...
        xmlSet, outputSet, baseSet, feaSet, windowSize, subSize, step3d)
fprintf('%s build histogram for each cuboid\n', datestr(now));
% input 
xmlFiles = dir([xmlSet '/*.xml']);
cuboidSet = [outputSet '/cuboid_%d/%s'];
clusterSet = [baseSet '/clusters'];
% output
feaSet = [feaSet '/'];
mkdir(feaSet);
feaSet = [feaSet '%s'];

load(clusterSet);
for i = 1:size(xmlFiles, 1)
    rec = VOCreadxml([xmlSet '/' xmlFiles(i).name]);
    name = rec.annotation.index;
    fprintf('%s extracting LBP features %s\n', datestr(now), name);
    cuboidFile = sprintf(cuboidSet, windowSize, name);
    load(cuboidFile);
    cuboid = cuboid(1,:);

    idMat = ones(1, size(cuboid, 2));
    repSize = mat2cell(idMat.*subSize, 1, idMat);
    repStep = mat2cell(idMat.*step3d, 1, idMat);
    rMat = ones(1, size(cuboid, 2)) * size(clusters, 2);
    repClusters = mat2cell(...
        repmat(clusters, 1, size(cuboid,2)), size(clusters, 1), rMat);

    histograms = cellfun(@cuboid2Hist,...
        cuboid, repClusters, repSize, repStep, 'UniformOutput', false);
    clear rMat repClusters repSize repStep cuboid;

    X_features = cell2mat(histograms');
    X_features = X_features';
    featureFile = sprintf(feaSet, name);
    save(featureFile, 'X_features');
    clear X_features histograms;
end
end

function histogram = cuboid2Hist(image3d, clusters, wSize, wStep)
imgSize = size(image3d);
halfSize = ceil(wSize/2);
xs = halfSize:wStep:(imgSize(1) - halfSize);
ys = halfSize:wStep:(imgSize(2) - halfSize);
zs = halfSize:wStep:(imgSize(3) - halfSize);
[x y z] = meshgrid(xs, ys, zs);
x = x(:);
y = y(:);
z = z(:);
localFeature = cell(numel(x), 1); % 3 x 59 patterns
for i = 1:size(localFeature, 1)
    sampleCell = getSurroundCuboid(...
        image3d, [x(i), y(i), z(i)], [wSize, wSize, wSize]);
    localFeature{i} = sampleCell;
end
localFeature = cellfun(@calcLBP, localFeature, 'UniformOutput', false);
localFeature = cell2mat(localFeature);
assert(size(localFeature, 2) == 177,...
    'not right dimension %d', size(localFeature, 2));
D = dist2(localFeature, clusters);
[~, nearest] = min(D, [], 2);
bins = 1:size(clusters, 1);
histogram = histc(nearest', bins);
end

function histLBP = calcLBP(image3d)
global uniformCode
image3d = double(image3d);
FxRadius = 1;
FyRadius = 1;
TInterval = 1;

TimeLength = 1;
BorderLength = 1;

bBilinearInterpolation = 1;

Bincount = 59;
NeighborPoints = [8 8 8];
histLBP = LBPTOP(image3d, FxRadius, FyRadius, TInterval, NeighborPoints,...
    TimeLength, BorderLength, bBilinearInterpolation, Bincount, uniformCode);
histLBP = histLBP(:)';
assert(size(histLBP, 2) == 177, 'LBP histogram length %d?', 177);
end
