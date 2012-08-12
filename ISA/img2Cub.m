function  cuboid  = img2Cub(imgFile, segFile, windowSize, step)

numOfSamples = 600;
% load images and segmentations.
load(imgFile);
load(segFile);

% get interesting locations
[~, locations3d] = scanForPositiveSampleLocations(...
					segImg, windowSize, step);
fprintf('Found %d positive locations\n', length(locations3d));
randIndex = randsample(size(locations3d,1), min(size(locations3d,1), numOfSamples));
fprintf('Randomly choose %d\n', min(size(locations3d,1), numOfSamples));
for loc = 1:size(randIndex,1)
	cuboid{1,loc} = getSurroundCuboid(...
					 oriImg, locations3d(randIndex(loc),:), windowSize);
	cuboid{2,loc} = locations3d(randIndex(loc),:);
end	
end
