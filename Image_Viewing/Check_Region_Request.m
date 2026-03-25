% --- Function to test whether request region of an image is larger than a
% manually set "maximum dimensions". If the requested region is larger,
% then a downsampled image region and scale factor are returned.
function [scaled_I, scaled_mask, scale_factor] = Check_Region_Request(image_path,bounding_box, mask_coords,image_adapter)

% image_path = str
% bounding_box = (min_x, max_x, min_y, max_y)

% Formats which are readable in MATLAB
matlab_formats = [imformats().ext];

% File extension for slide
image_ext = strsplit(image_path,'.');
image_ext = image_ext{end};

% Applying scale factor
max_dims = [1e3,1e3];

% Structure dims in y,x (rows,cols)
structure_dims = [...
    bounding_box(4)- bounding_box(3),...
    bounding_box(2) - bounding_box(1)
];

% Checking if either the height or width exceeds the maximum dimensions
if any(structure_dims > max_dims) 
    
    % Loading blockedImage if readable by MATLAB
    if ismember({image_ext},matlab_formats)
        big_image = blockedImage(image_path);

        level_dims = big_image.Size;
        scale_list = ones(big_image.NumLevels,1);
    
        % Level = 1 is full resolution
        for l = 2:big_image.NumLevels
            scale = level_dims(l,:) / level_dims(1,:);
            scale_list(l) = scale;
        end
        
        % The first row value here is the lowest (largest resolution) value
        % that is less than the maximum dimensions (max_dims)
        [row,col] = find((structure_dims .* scale_list) < max_dims);
        use_level = min(row);
        scale_factor = scale_list(use_level);
    
        scaled_mask_coords = mask_coords .* scale_factor;
        scaled_bbox = double(uint16(bounding_box .* scale_factor));
    
        scaled_I = getRegion(...
            big_image,...
            [scaled_bbox(3), scaled_bbox(1)],...
            [scaled_bbox(4), scaled_bbox(2)],...
            Level = use_level...
        );        
        scaled_mask = poly2mask(...
            scaled_mask_coords(:,1),scaled_mask_coords(:,2),...
            size(scaled_I,1),size(scaled_I,2)...
        );


    else

        % OpenSlide route for reading WSIs (does not have a blocked- method
        % so have to iterate, reconstruct, and resize.
        try
            if ~exist('image_adapter','var')
                slide_adapter = OpenSlideAdapter(image_path);
            else
                if ~isempty(image_adapter)
                    slide_adapter = image_adapter;
                else
                    slide_adapter = OpenSlideAdapter(image_path);
                end
            end

            % Resize scale should be the multiple of max_dims ./
            % structure_dims
            scale_factor = min(max_dims ./ structure_dims);
            scale_fun = @(block_struct) imresize(block_struct.data,scale_factor);
            
            scaled_I = blockproc(...
                slide_adapter,...
                [100,100],...
                scale_fun,...
                "DisplayWaitbar",false ...
            );

            
            scaled_mask_coords = mask_coords .* scale_factor;
            scaled_mask = poly2mask(...
                scaled_mask_coords(:,1),scaled_mask_coords(:,2),...
                size(scaled_I,1),size(scaled_I,2) ...
            );
            

        catch
            f = msgbox(["Unable to open the specified slide: ",image_path]);

        end

    end


else

    % This is if the annotation/structure is less than the maximum
    % dimensions

    scaled_mask = poly2mask(...
        mask_coords(:,1),mask_coords(:,2),...
        structure_dims(2), structure_dims(1)...
    );
    scale_factor = 1;
    if ismember({image_ext},matlab_formats)

        scaled_I = imread(...
            image_path,...
            "Index", 1,...
            'PixelRegion',{bounding_box(3:4),bounding_box(1:2)}...
            );

    else
        
        if ~exist('image_adapter','var')
            slide_adapter = OpenSlideAdapter(image_path);
        else
            if ~isempty(image_adapter)
                slide_adapter = image_adapter;
            else
                slide_adapter = OpenSlideAdapter(image_path);
            end
        end        
        
        scaled_ARGB = slide_adapter.readRegion(...
            [bounding_box(2),bounding_box(1)],...
            [structuure_dims(1),structure_dims(2)] ...
        );
        scaled_I = scaled_ARGB(2:end,:);
        
    end

end




