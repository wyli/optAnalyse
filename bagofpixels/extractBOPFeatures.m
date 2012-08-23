function [] = extractBOPFeatures(...
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
    fprintf('%s extracting BoG features %s\n', datestr(now), name);
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
localCuboid = zeros(numel(x), wSize^3);
for i = 1:size(localCuboid, 1)
    sampleCell = getSurroundCuboid(...
        image3d, [x(i), y(i), z(i)], [wSize, wSize, wSize]);
    localCuboid(i, :) = sampleCell(:)';
end
D = dist2(localCuboid, clusters);
[~, nearest] = min(D, [], 2);
bins = 1:size(clusters, 1);
histogram = histc(nearest', bins);
end
