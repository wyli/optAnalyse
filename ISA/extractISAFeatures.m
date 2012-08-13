function [] = extractISAFeatures(xmlSet, outputSet, windowSize)
fprintf('%s extracting ISA features\n', datestr(now));
% input
xmlFiles = dir([xmlSet '/*.xml']);
cuboidSet = [outputSet '/cuboid_%d/'];
% output
mkdir([outputSet '/feaSet/']);
feaSet = [outputSet '/feaSet/%s'];
network_params = set_network_params(windowSize);
network = build_network(network_params, 2, [outputSet '/']);

params.postact = set_postact(0);
samplesPerFile = 1000;
cuboids = zeros(windowSize(2)^3, samplesPerFile);
for i = 1:size(xmlFiles, 1)
    rec = VOCreadxml([xmlSet '/' xmlFiles(i).name]);
    rec = rec.annotation.index;
    fprintf('%s level %d loading %s\n',...
        datestr(now), windowSize(2), rec);
    s = (i-1)*samplesPerFile + 1;
    e = i * samplesPerFile;
    cuboids(:,s:e) = loadCuboids(...
        cuboidSet, rec, windowSize(2), samplesPerFile);
    fprintf('%s extacting from %s\n', datestr(now), rec);
    [act_l2, act_l1_pca_reduced, ~] = activate2LISA(double(cuboids),...
        network.isa{1}, network.isa{2}, size(cuboids, 2), params.postact);
    X_features = [act_l2; act_l1_pca_reduced];
    featureFile = sprintf(feaSet, rec);
    save(featureFile, 'X_features');
end
end

function cuboids = loadCuboids(cuboidSet, name, window, samplesPerFile)
cuboidSet = sprintf(cuboidSet, window);
cuboidFile = sprintf('%s%s%s\n', cuboidSet, name);
load(cuboidFile);
cuboids = zeros(numel(cuboid{1, 1}), size(cuboid, 2));
for i = 1:size(cuboid, 2)
    cuboids(:,i) = cuboid{1,i}(:);
end
r = randsample(size(cuboids,2), min(size(cuboids,2), samplesPerFile));
cuboids = cuboids(:, r);
end
