fid = fopen('~/desktop/converting.log', 'w');
fprintf(fid, '%s start converting...\n', datestr(now));
% Load XML file.
recordSet = '/Volumes/data/OPTfinal/description/';
recordFile = dir([recordSet '*.xml']);

segSet = '/Volumes/data/OPTfinal/%s/Annotated/%s%s';
oriSet = '/Volumes/data/OPTfinal/%s/Images/%s%s';

rotateMat = [0 0 1 0; 0 1 0 0; -1 0 0 0; 0 0 0 1];
% % update xml files. (some file need rotating)
for i = 1:size(recordFile, 1)
    rec = VOCreadxml([recordSet, recordFile(i).name]);
    name = rec.annotation.index;
    for p = 1:size(rec.annotation.part, 2)
        part = rec.annotation.part{p};
        fprintf(fid, '%s checking %s%s\n',datestr(now), name, part);
        segFile = sprintf(segSet,...
            rec.annotation.dataset, name, part);
        segFile = load_nii(segFile);
        segImg = segFile.img;
        try
            scanForPositiveSampleLocations(segImg, [15,15,15], [5,5,5]);
            rec.annotation.needRotate{p} = 0;
            fprintf(fid, '%s no rotate writing %s%s\n',...
                datestr(now), name, part);
            VOCwritexml(rec, [recordSet, recordFile(i).name]);
            clear segImg;
        catch e
            if strcmp(e.identifier, 'OPT:nolocation')
                fprintf(fid, '%s rotate writing %s%s\n',...
                   datestr(now), name, part);
                rec.annotation.needRotate{p} = 1;
                VOCwritexml(rec, [recordSet, recordFile(i).name]);% [recordSet, recordFile(i).name]);
            end
        end
    end
end

% scale & rotate
savingSeg = '/Volumes/data/OPTfinal/OPTmix/Annotated/%s%s';
savingOri = '/Volumes/data/OPTfinal/OPTmix/Images/%s%s';
for i = 1:size(recordFile, 1)
    rec = VOCreadxml([recordSet, recordFile(i).name]);
    name = rec.annotation.index;
    for p = 1:size(rec.annotation.part,2)
        part = rec.annotation.part{p};
        % load segmentation
        segFile = sprintf(segSet,...
            rec.annotation.dataset, name, part);
        segFile = load_nii(segFile);
        segImg = segFile.img;
        clear segFile;
        % scale segmentation
        fprintf(fid, '%s scaling %s%s\n', datestr(now), name, part);
        tempImg = zeros(size(segImg,1)*2, size(segImg,2)*2, size(segImg,3));
        for n = 1:size(segImg, 3)
            tempImg(:,:,n) = imresize(segImg(:,:,n), 2);
        end
        segImg = tempImg;
        clear tempImg;
        % rotate segmentation if needed
        if rec.annotation.needRotate{p}
            fprintf(fid, '%s rotating %s%s\n', datestr(now), name, part);
            segImg = affine(segImg, rotateMat);
        end
        % to binary image
        tempImg = zeros(size(segImg));
        for n = 1:size(tempImg, 3)
            tempImg(:,:,n) = im2bw(segImg(:,:,n), 0.5);
        end
        segImg = tempImg;
        clear tempImg;
        % save segmentation to disk
        savingSegFile = sprintf(savingSeg, name, part);
        save(savingSegFile, 'segImg');
        clear segImg;

        % load original image
        oriFile = sprintf(oriSet,...
            rec.annotation.dataset, name, part);
        oriFile = load_nii(oriFile);
        oriImg = oriFile.img;
        clear oriFile;

        % rotate image if needed
        if rec.annotation.needRotate{p}
            fprintf(fid, '%s rotating %s%s\n', datestr(now), name, part);
            oriImg = affine(oriImg, rotateMat);
        end
        oriImg = uint8(oriImg);
        % save image to disk
        savingOriFile = sprintf(savingOri, name, part);
        save(savingOriFile, 'oriImg');
        clear oriImg;
    end
end
fclose(fid);
