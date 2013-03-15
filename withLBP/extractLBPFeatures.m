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

    X_features = zeros(size(clusters, 1), size(cuboid, 2));
    for m = 1:size(cuboid, 2)
        X_features(:, m) = cuboid2Hist(uint8(cuboid{1, m}), clusters, subSize, step3d);
    end
    featureFile = sprintf(feaSet, name);
    save(featureFile, 'X_features');
    clear X_features;
end
end

function histogram = cuboid2Hist(image3d, clusters, wSize, wStep)
imgSize = size(image3d);
halfSize = ceil(wSize/2);
imgSize = imgSize - halfSize;
wStep = 3;
xs = halfSize:wStep:imgSize(1);
while size(xs, 2) < 1
    wStep = wStep - 1;
    xs = halfSize:wStep:imgSize(1);
end
[x y z] = meshgrid(xs, xs, xs);
x = x(:);
y = y(:);
z = z(:);
localFeature = zeros(numel(x), 177); % 3 x 59 patterns
for i = 1:size(localFeature, 1)
    localFeature(i, :)=LBPHist(getSurroundCuboid(...
        image3d, [x(i), y(i), z(i)], [wSize, wSize, wSize]));
    %localFeature(i, :) = LBPHist(sampleCell);
end
D = dist2(localFeature, clusters);
[~, nearest] = min(D, [], 2);
bins = 1:size(clusters, 1);
histogram = histc(nearest', bins);
end
