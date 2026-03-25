% --- Function to extract random image from .svs file
function Extract_Rand_Img(app,structure_num)

current_structure = app.SelectStructureDropDown.Value;
slide_idx = app.Slide_Idx;

% Finding the row with this structure name
structure_row = find(strcmp(app.SelectStructureDropDown.Value,app.Structure_Names{:,1}));

annotation_ids = app.Structure_Names{structure_row,2};
annotation_ids = str2double(strsplit(annotation_ids{1},','));

if contains(app.Slide_Names{slide_idx},'.')
    wsi_ext = strsplit(app.Slide_Names{slide_idx},'.');
    wsi_ext = wsi_ext{end};
end

% % Getting the xml filename
if contains(app.Slide_Names{slide_idx},wsi_ext)
    if strcmp(app.Annotation_Format,'XML')
        file_name = strrep(app.Slide_Names{slide_idx},wsi_ext,'xml');
    else
        file_name = strrep(app.Slide_Names{slide_idx},wsi_ext,'json');
        if ~isfile(strcat(app.Slide_Path,filesep,file_name))
            file_name = strrep(file_name,'.json','.geojson');
        end
    end
else
    if strcmp(app.Annotation_Format,'XML')
        file_name = strrep(app.Slide_Names{slide_idx},wsi_ext,'xml');
    else
        file_name = strrep(app.Slide_Names{slide_idx},wsi_ext,'json');
        if ~isfile(strcat(app.Slide_Path,filesep,file_name))
            file_name = strrep(file_name,'.json','.geojson');
        end
    end
end


if strcmp(app.Annotation_Format,'XML')
    
    xml_path = strcat(app.Slide_Path,filesep,file_name);
    [bbox_coords,mask_coords] = Read_XML_Annotations(xml_path,annotation_ids,structure_num);
else
    json_path = strcat(app.Slide_Path,filesep,file_name);
    [bbox_coords,mask_coords] = Read_JSON_Annotations(json_path,structure_num);
end

% 3:4 = rows, 1:2 = columns
slide_path = strcat(app.Slide_Path,filesep,app.Slide_Names{slide_idx});
[scaled_I,scaled_mask,scale_factor] = Check_Region_Request(slide_path,bbox_coords,mask_coords);

app.Current_Name = app.Slide_Names{slide_idx};

if ~isempty(app.StainNorm_Params) && ~any(app.StainNorm_Params.Means==0,'all') && ~any(app.StainNorm_Params.Maxs==0,'all')
    norm_img = normalizeStaining(scaled_I,240,0.15,1,app.StainNorm_Params.Means,...
        app.StainNorm_Params.Maxs);

    app.Norm_Img = norm_img;
else
    app.Norm_Img = [];
end
        
app.Current_Img = scaled_I;
app.Current_Mask = scaled_mask;
% end

