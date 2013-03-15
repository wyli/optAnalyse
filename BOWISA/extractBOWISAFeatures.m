function [] = extractBOWISAFeatures(...
        xmlSet, outputSet, baseSet, feaSet, windowSize)
fprintf('%s extracting ISA features\n', datestr(now));
% input
xmlFiles = dir([xmlSet '/*.xml']);
cuboidSet = [outputSet '/cuboid_%d/'];
% output
mkdir(feaSet);
feaSet = [feaSet '/%s'];

load([baseSet '/clusters.mat']);
network_params = set_network_params(windowSize);
network = build_network(network_params, 1, [baseSet '/']);
params.postact = set_postact(0);

for i = 1:size(xmlFiles, 1)
    rec = VOCreadxml([xmlSet '/' xmlFiles(i).name]);
    rec = rec.annotation.index;
    fprintf('%s level %d loading %s\n',...
        datestr(now), windowSize(2), rec);
    cuboids = loadCuboids(...
        cuboidSet, rec, windowSize(2));
    fprintf('%s extacting from %s\n', datestr(now), rec);
    %[act_l2, act_l1_pca_reduced, ~] = activate2LISA(double(cuboids),...
    %    network.isa{1}, network.isa{2}, size(cuboids, 2), params.postact);
    %X_features = [act_l2; act_l1_pca_reduced];

    localFeatures = transactConvISA(single(cuboids), network.isa{1},...
        network.isa{2}, params.postact.layer1);
    % pca is fixed to 300 if not small than 300
    width = min(300, windowSize(1)^3);
    %  k is fixed as 200
    k = size(clusters, 1);
    X_features = zeros(size(localFeatures, 2), k);
    for i = 1:size(localFeatures, 2)
        localPatches = reshape(localFeatures(:, i), width, []);
        D = dist2(localPatches', clusters);
        [~, index] = min(D, [], 2);
        bins = 1:size(clusters, 1);
        histogram = histc(index', bins);
        X_features(i,:) = histogram;
    end
    featureFile = sprintf(feaSet, rec);
    save(featureFile, 'X_features');
    clear X_features;
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
