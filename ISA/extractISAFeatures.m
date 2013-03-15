function [] = extractISAFeatures(xmlSet, outputSet, baseSet, feaSet, windowSize)
fprintf('%s extracting ISA features\n', datestr(now));
% input
xmlFiles = dir([xmlSet '/*.xml']);
cuboidSet = [outputSet '/cuboid_%d/'];
% output
mkdir(feaSet);
feaSet = [feaSet '/%s'];

network_params = set_network_params(windowSize);
network = build_network(network_params, 2, [baseSet '/']);
params.postact = set_postact(0);

for i = 1:size(xmlFiles, 1)
    rec = VOCreadxml([xmlSet '/' xmlFiles(i).name]);
    rec = rec.annotation.index;
    fprintf('%s level %d loading %s\n',...
        datestr(now), windowSize(2), rec);
    cuboids = loadCuboids(...
        cuboidSet, rec, windowSize(2));
    fprintf('%s extacting from %s\n', datestr(now), rec);
    [act_l2, act_l1_pca_reduced, ~] = activate2LISA(double(cuboids),...
        network.isa{1}, network.isa{2}, size(cuboids, 2), params.postact);
    X_features = [act_l2; act_l1_pca_reduced];
    featureFile = sprintf(feaSet, rec);
    X_features = X_feautres';
    save(featureFile, 'X_features');
end
end

function cuboids = loadCuboids(cuboidSet, name, window)
cuboidSet = sprintf(cuboidSet, window);
cuboidFile = sprintf('%s%s%s\n', cuboidSet, name);
load(cuboidFile); % loading cuboid
cuboids = zeros(numel(cuboid{1, 1}), size(cuboid, 2));
for i = 1:size(cuboid, 2)
    cuboids(:,i) = cuboid{1,i}(:);
end
end
