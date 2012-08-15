function [ image3d, locations ] =...
        scanForPositiveSampleLocations( image3d, window3d, step )
% scanForCuboids looking for cuboids locations in the 3d image
% RETURN 3d images and locations
% e.g.:
% [~, loc] = scanForCuboids('/cancer/annotation/73c', [21,21,11], [10,10,5]);
% Wed 25 Apr 2012 00:31:06 BST
% Wenqi Li


sizeOfImg = size(image3d);
index = find(image3d);
[~, ~, frameInx] = ind2sub(size(image3d), index);
frameInx = unique(frameInx);

locations = [];
window3d = floor(window3d./2);
for i = 1:size(frameInx,1);
    if (frameInx(i) - window3d(3) < 1) ||...
            (frameInx(i) + window3d(3) > sizeOfImg(3))
        continue;
    end

    startFrame = frameInx(i);
    [xs ys] = find(image3d(:,:,startFrame));
    xLow = max(min(xs), window3d(1)+1);
    xHigh = min(max(xs), sizeOfImg(1)-window3d(1));
    yLow = max(min(ys), window3d(2)+1);
    yHigh = min(max(ys), sizeOfImg(2)-window3d(2));

    for x = xLow:step(1):xHigh
        for y = yLow:step(2):yHigh
            try
                if all(image3d( x-window3d(1):x+window3d(1),...
                        y-window3d(2):y+window3d(2),...
                        startFrame ))
                    % locations of positive examples.
                    locations = [locations; [x y startFrame]];
                end
            catch e
                warning(e.identifier, 'In scanForPositiveSampleLocations');
                % do nothing
            end
        end
    end
end
if isempty(locations)
    err = MException('OPT:nolocation',...
        'Cannot find any continuous annotations');
    throw(err);
end
end % end of function


% debugging for visualise ROI
% figure;
% colormap(gray);
% imagesc(image3d(:,:,frameInx(5)));
% for i = 1:1000
% l = locations(i,:);
% if l(3) == frameInx(5)
% rectangle('Position',...
%    [l(2)-window3d(2), l(1)-window3d(1),window3d(2)*2, window3d(1)*2],'FaceColor', 'r');
% end
% end
%
% clear i overlap;
%end
%
