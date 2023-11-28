%% CT图像的气管与肺部分割 王逸钦 2021-12-12 wangyiqi19@mails.tsinghua.edu.cn%%
%% 图像读取
clear;
clc;
addpath("NIfTI_20140122");
addpath("SliceBrowser");
img_path = 'data\coronacases_org_004.nii';
mask_path_trachea = 'data\coronacases_trachea_004.nii';
mask_path_lung = 'data\coronacases_lung_004.nii';
img_info = load_nii(img_path);
mask_info_trachea = load_nii(mask_path_trachea);
mask_info_lung = load_nii(mask_path_lung);
img = double(img_info.img);
mask_trachea = double(mask_info_trachea.img>=1);
mask_lung = double(mask_info_lung.img>=1); %大于1的均变为1
img = permute(img,[2,1,3]); %img要转置一下
[a,b,c] = size(img);
mask_trachea(3:a,2:b,:) = mask_trachea(1:a-2,1:b-1,:); %气管要平移一下
mask_lung = permute(mask_lung,[2,1,3]); %肺数据也要转置一下
img = windowing(img, -150, 1500); %窗技术
% figure,imshow(squeeze(img(:,:,1)));
% figure('Name','Ground Truth Trachea'),volshow(mask_trachea);
% figure('Name','Ground Truth Lung'),volshow(mask_lung);

%% 二维切片图像处理
img_2_trachea = zeros(a,b,c); %用于存放气管结果
img_2_lung = zeros(a,b,c); %用于存放肺结果
for i=1:c %逐片分出气管区域
    if i==182
        temp=1;
    end
    img_2_trachea(:,:,i) = operation(squeeze(img(:,:,i)),'Trachea');
    img_2_lung(:,:,i) = operation(squeeze(img(:,:,i)),'Lung');
end
% figure('Name','2D Processed Trachea'),volshow(img_2_trachea);
% figure('Name','2D Processed Lung'),volshow(img_2_lung);
%%
% figure,title('Slice182~183'),subplot(2,2,1),imshow(squeeze(img(:,:,192))),...
%     subplot(2,2,2),imshow(squeeze(img_2_trachea(:,:,192))),...
%     subplot(2,2,3),imshow(squeeze(img(:,:,193))),...
%     subplot(2,2,4),imshow(squeeze(img_2_trachea(:,:,193)));

%% 三维连通域处理去噪
img_3_trachea = operation3d(img_2_trachea,'Trachea');
img_3_lung = max(operation3d(img_2_lung,'Lung')-img_3_trachea, 0);
% figure('Name','Final Trachea'),volshow(img_3_trachea);
% figure('Name','Final Lung'),volshow(img_3_lung);

%% 算法效果衡量
dice_trachea = dice(img_3_trachea, mask_trachea);
dice_lung = dice(img_3_lung, mask_lung);

%% 功能函数
%窗技术，窗宽窗位(要求输入0~1的double图片)
function imgnew = windowing(img, WL, WW)
    lo = WL - WW / 2;
    hi = WL + WW / 2;
    imgnew = (img - lo) / (hi - lo);
    imgnew(imgnew < 0) = 0;
    imgnew(imgnew > 1) = 1;
end

%分出气管/肺区域
function region = operation(img,organ)
    if strcmp(organ,'Trachea')
        thres_proportion=0.5;
    elseif strcmp(organ,'Lung')
        thres_proportion=25;
    end
    img = 1-imbinarize(img, graythresh(img)); %根据Otsu确定的阈值二值化，黑白转换
    if strcmp(organ,'Trachea')
        img = imerode(img, strel('diamond',4)); %用对角线为9的菱形kernel腐蚀图片
    end
    img = bwlabel(img, 4); %用四连通算法对连通域做标记    
    count = tabulate(img(:))'; %统计各连通域像素数
    for i = count
        if i(3)<thres_proportion %寻找面积0.5%以内连通域(气管)或25%以内连通域(肺)
            img(img==i(1)) = 1; %置为白色
        else
            img(img==i(1)) = 0; %其余置为黑色
        end
    end
    if strcmp(organ,'Trachea')
        img = imdilate(img, strel('diamond',4)); %用对角线为9的菱形kernel膨胀图片
    end
    region = img;
end

%在三维取最大连通域
function img_3 = operation3d(img_2, organ)
    [a,b,c] = size(img_2);
    list = bwconncomp(img_2).PixelIdxList; %三维连通域列表
    count = cellfun(@numel,list); %各连通域体积
    [~,index] = max(count);
    if strcmp(organ,'Trachea')
        %未延伸到末层(颈部)的连通域必不是气管
        while max(list{index})<=(a*b*(c-1)) 
            count(index) = 0;
            [~,index] = max(count);
        end
    elseif strcmp(organ,'Lung')
        %每一切片太靠上或靠下必不是肺
        row=mod(list{index},a);
        while max(row)>(0.95*a) || min(row)<(0.05*a)
            count(index) = 0;
            [~,index] = max(count);
            row=mod(list{index},a);
        end
    end
    img_3 = zeros(a,b,c);
    img_3(list{index}) = 1;
end
