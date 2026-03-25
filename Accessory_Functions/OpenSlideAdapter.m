% --- Class definition for OpenSlideAdapter 
classdef OpenSlideAdapter < ImageAdapter

properties
    openslidePointer
end

methods

    function obj = OpenSlideAdapter(path)
        % Initializing properties to OpenSlideAdapter (openslidePointer
        % required for OpenSlide, ImageSize and 
        obj.open(path)
    end

    function open(obj,path)
        obj.openslidePointer = openslide_open(char(path));

        [width,height] = openslide_get_level0_dimensions(obj.openslidePointer);

        % OpenSlide returns ARGB values by default
        % ImageAdapter superclass wants size in the form of height X width
        % X channels
        obj.ImageSize = [height,width,4];
        obj.Colormap = eye(3);

    end

    function data = readRegion(obj,region_start, region_size)

        if isempty(obj.openslidePointer)
            obj.open(obj.image_path)
        end
        [data] = openslide_read_region(...
            obj.openslidePointer,...
            region_start(2)-1,region_start(1)-1,...
            region_size(2),region_size(1) ...
            );
        
        %fprintf("Block read")

    end

    function [] = writeRegion(obj, region_start, region_data)

        % Raise some kind of error, don't want to write anything from this
        % adapter.

    end

    function close(obj)
        openslide_close(obj.openslidePointer)
    end

end

end