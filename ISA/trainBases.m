function [] = trainBases(xmlSet, outputSet, trainInd, windowSize)

fprintf('%s training bases with %d %d\n',...
    datestr(now), windowSize(1), windowSize(2));
cuboidSet = [outputSet '/cuboid_%d/'];
xmlFiles = dir([xmlSet '/*.xml']);

samplesPerFile = 800;
network_params = set_network_params(windowSize);
for level = 1:2
    cuboids = [];
    for i = 1:size(trainInd, 1)
        rec = VOCreadxml([xmlSet '/' xmlFiles(trainInd(i)).name]);
        rec = rec.annotation.index;
        fprintf('%s level %d loading %s\n',...
            datestr(now), windowSize(level), rec);
        c = loadCuboids(...
            cuboidSet, rec, windowSize(level), samplesPerFile);
        cuboids = [cuboids, c];
    end

    fprintf('%s training ISA level %d\n', datestr(now), level);
    if level == 1
        network = build_network(network_params, 0, [outputSet '/']);
        train_isa(network, cuboids, [outputSet '/'],...
            set_training_params(1, network_params));
    else
        network = build_network(network_params, 1, [outputSet '/']);
        train_isa(network, cuboids, [outputSet '/'],...
            set_training_params(2, network_params));
    end
end
end

function cuboids = loadCuboids(cuboidSet, name, window, samplesPerFile)
cuboidSet = sprintf(cuboidSet, window);
cuboidFile = sprintf('%s%s%s\n', cuboidSet, name);
load(cuboidFile); % loading cuboid
cuboids = zeros(numel(cuboid{1, 1}), size(cuboid, 2));
for i = 1:size(cuboid, 2)
    cuboids(:,i) = cuboid{1,i}(:);
end
r = randsample(size(cuboids,2), min(size(cuboids,2), samplesPerFile));
cuboids = cuboids(:, r);
end
