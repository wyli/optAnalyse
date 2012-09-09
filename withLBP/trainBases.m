function [] = trainBases(...
        xmlSet, outputSet, baseSet, trainInd, windowSize, subSize, step3d, k)
    fprintf('%s find %d clusters on small window %d\n', datestr(now), k, subSize);
    % params
    global numOfSubsamples;
    numOfSubsamples = 4;
    samplesPerFile = 400;
    subsamplesPerFile = numOfSubsamples * samplesPerFile;
    % input
    xmlFiles = dir([xmlSet '/*.xml']);
    cuboidSet = [outputSet '/cuboid_%d/%s'];

    % output
    clusterFile = [baseSet, '/clusters.mat'];

    localSet = zeros(size(trainInd, 1) * subsamplesPerFile, 177);
    for i = 1:size(trainInd, 1)
        rec = VOCreadxml([xmlSet '/' xmlFiles(trainInd(i)).name]);
        name = rec.annotation.index;
        cuboidFile = sprintf(cuboidSet, windowSize, name);
        load(cuboidFile);
        assert(size(cuboid, 2) > samplesPerFile, 'not enough samples per file');
        r = randsample(size(cuboid,2), min(size(cuboid,2), samplesPerFile));
        cuboid = cuboid(1,r);

        idMat = ones(1, size(cuboid, 2));
        repSize = mat2cell(idMat.*subSize, 1, idMat);
        repStep = mat2cell(idMat.*step3d, 1, idMat);
        localCells = cellfun(@sampleSubCuboids,...
            cuboid, repSize, repStep, 'UniformOutput', false);
        localMat = cell2mat(localCells');
        clear localCells cuboid;
        localSet((1+(i-1)*subsamplesPerFile):(i*subsamplesPerFile), :) =...
            localMat;
    end
    assert(size(localSet, 1) > 40000, 'not enough samples');
    r = randsample(size(localSet, 1), 40000);
    localSet = localSet(r, :);

    fprintf('doing kmeans on %d %d\n', size(localSet, 1), size(localSet, 2));
    prm.nTrial = 3;
    prm.maxIter = 200;
    [~, clusters] = kmeans2(localSet, k, prm);
    save(clusterFile, 'clusters');
end

function localFeature = sampleSubCuboids(image3d, wSize, wStep)
    global numOfSubsamples;
    imgSize = size(image3d);
    halfSize = ceil(wSize/2);

    xs = halfSize:wStep:(imgSize(1) - halfSize);
    ys = halfSize:wStep:(imgSize(2) - halfSize);
    zs = halfSize:wStep:(imgSize(3) - halfSize);

    xs = randsample(xs, min(length(xs), numOfSubsamples));
    ys = randsample(ys, min(length(ys), numOfSubsamples));
    zs = randsample(zs, min(length(zs), numOfSubsamples));

    %localFeature = zeros(numOfSubsamples, 177); % 3 x 59 patterns
    localFeature = cell(numOfSubsamples, 1);
    for i = 1:numOfSubsamples
        sampleCell = getSurroundCuboid(...
            image3d, [xs(i), ys(i), zs(i)], [wSize, wSize, wSize]);
        localFeature{i} = sampleCell; 
    end
    localFeature = cellfun(@calcLBP, localFeature, 'UniformOutput', false);
    localFeature = cell2mat(localFeature);
    assert(size(localFeature, 2) == 177, 'not right dimension');
    assert(size(localFeature, 1) == numOfSubsamples, 'not enough subsamples');
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
