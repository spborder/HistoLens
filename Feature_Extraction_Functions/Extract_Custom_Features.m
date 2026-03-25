% --- Function where you can add custom features
function custom_features = Extract_Custom_Features(img,comp_img,feat_idxes,mpp,scale_factor)

custom_features = zeros(1,length(feat_idxes));
% Maximum index included in Features_Extract_General and Feature_Vis_Gen is
% 448

% "scale_factor" is applied to any large annotated regions. if you have an
% area or length calculation, multiply that value by 1/scale_factor to get
% an accurate full-resolution pixel count.

% Example features quantification silver stain content
if any(ismember(feat_idxes,(449:460)))
    
    % stain stored as first channel in sub-compartment segmentation
    silver_mask = comp_img(:,:,1);

    % total area of silver stain
    silver_area = sum(silver_mask,'all') * (1/scale_factor);

    % silver stain area divided by total area
    silver_area_ratio = silver_area / (sum(comp_img,'all'));

    % silver deposits greater than certain areas (pixel-wise)
    area_breaks = (10:10:100);
    silver_area_thresholds = zeros(1,length(area_breaks));
    silver_dist = bwdist(~silver_mask) * (1/scale_factor);
    for a=1:length(area_breaks)
        
        intermediate_mask = silver_dist>area_breaks(a);
        silver_area_thresholds(a) = sum(intermediate_mask,'all');
    
    end

    % This insures that the features are added to the total feature row in
    % order
    feat_subgroup = [silver_area,silver_area_ratio,silver_area_thresholds];
    [overlap,int_idx,~] = intersect(feat_idxes,(449:460));
    custom_features(1,int_idx) = feat_subgroup(overlap-448);

end










