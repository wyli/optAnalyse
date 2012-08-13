function [ cuboid ] = getSurroundCuboid ( image3d, point3d, sizeOfCuboid )
% Get the cuboid centred at the given 3d point.
% RETURN the cuboid(3d image patch)
% Tue 24 Apr 2012 20:31:29 BST
% Wenqi Li

sizeOfCuboid = floor(sizeOfCuboid ./ 2);
iStart = uint16(point3d - sizeOfCuboid); % starting index of x y z
iEnd = uint16(point3d + sizeOfCuboid); % ending index of x y z:w
try
    cuboid = uint8(image3d(...
        iStart(1):iEnd(1), iStart(2):iEnd(2), iStart(3):iEnd(3)));
catch error
    warning('OPT:rejectLocation', error.identifier);
    % clear cuboid
    cuboid = [];
end

end % end of function
