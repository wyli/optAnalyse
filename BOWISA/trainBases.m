function [] = trainBases(xmlSet, outputSet, baseSet, trainInd, windowSize, k)

fprintf('%s training bases with %d %d\n',...
    datestr(now), windowSize(1), windowSize(2));
cuboidSet = [outputSet '/cuboid_%d/'];
xmlFiles = dir([xmlSet '/*.xml']);

samplesPerFile = 400;
fprintf('sample per patient for taining: %d\n', samplesPerFile);
network_params = set_network_params(windowSize);
for level = 1:2
    ys = 1;
    sizeCub = windowSize(level)^3;
    cuboids = zeros(sizeCub, samplesPerFile*size(trainInd, 1));
    for i = 1:size(trainInd, 1)
        rec = VOCreadxml([xmlSet '/' xmlFiles(trainInd(i)).name]);
        rec = rec.annotation.index;
        fprintf('%s level %d loading %s\n',...
            datestr(now), windowSize(level), rec);
        c = loadCuboids(...
            cuboidSet, rec, windowSize(level), samplesPerFile);
        ye = ys + size(c, 2) - 1;
        cuboids(:, ys:ye) = c;
        ys = ye + 1;
    end
    cuboids = cuboids(:, 1:ye);
    fprintf('%s training ISA level %d\n', datestr(now), level);
    if level == 1
        network = build_network(network_params, 0, [baseSet '/']);
        train_isa(network, cuboids, [baseSet '/'],...
            set_training_params(1, network_params));
        clear cuboids;
    else
        network = build_network(network_params, 1, [baseSet '/']);
        %train_isa(network, cuboids, [baseSet '/'],...
        %    set_training_params(2, network_params));
        params = set_training_params(2, network_params);
        localPatches = transactConvISA(single(cuboids), network.isa{1},...
            network.isa{2}, params.postact.layer1);
        width = min(150, windowSize(1)^3);
        localPatches = reshape(localPatches, width, []);
        localPatches = localPatches';
        size(localPatches)
        s = randsample(size(localPatches, 1),...
            min(size(localPatches, 1), 60000));
        localPatches = localPatches(s, :);
        clusterPath = sprintf('%s/clusters.mat', baseSet);
%        opts = statset('MaxIter', 500);
%        fprintf('kmeans clustering ... %d\n', size(localPatches));
%        [~, clusters] = kmeans(localPatches, k,...
%            'EmptyAction', 'singleton',...
%            'Replicates', 2,...
%            'Options', opts);
%            ---------------------------------kmeans2---------------
        fprintf('kmeans clustering ... %d\n', size(localPatches));
        prm.nTrial = 5;
        prm.maxIter = 500;
        [~, clusters] = kmeans2(localPatches, k, prm);
%            --------------------------------kmeans2---------------
        save(clusterPath, 'clusters');
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
