%% Init
clear; clc;
Src = imread('Pic\Goal.png');
template = 2; %1:Truck, 2:Gallery, 3:Cookbook

%% Segmentation
if template==1
    Truck = imread("Pic\TruckRed.jpg");    
    Truck_red = Truck(:,:,1);
    Truck_green = Truck(:,:,2);
    Truck_blue = Truck(:,:,3);
    Truck_mask = Truck_blue<100 & ...
                 Truck_green<100 & ...
                 Truck_red>150;
    imwrite(Truck_mask, "Pic\TruckMaskTemp.bmp");
    Truck_mask = imerode(Truck_mask, strel('disk',1));
    Truck_mask = imdilate(Truck_mask, strel('disk',1));
    imwrite(Truck_mask, "Pic\TruckMask.bmp");
elseif template==2
    Gallery = imread("Pic\GalleryGreen.jpg");
    Gallery_red = Gallery(:,:,1);
    Gallery_green = Gallery(:,:,2);
    Gallery_blue = Gallery(:,:,3);
    Gallery_mask = Gallery_blue<100 & ...
                   Gallery_green>200 & ...
                   Gallery_red<100;
    imwrite(Gallery_mask, "Pic\GalleryMaskTemp.bmp");
    Gallery_mask(132:739,1:201)=1;
    Gallery_mask(132:739,622:824)=1;
    imwrite(Gallery_mask, "Pic\GalleryMask.bmp");
elseif template==3
    Cookbook = imread("Pic\CookbookBlue.jpg");
    Cookbook_red = Cookbook(:,:,1);
    Cookbook_green = Cookbook(:,:,2);
    Cookbook_blue = Cookbook(:,:,3);
    Cookbook_mask = Cookbook_blue>200 & ...
                    Cookbook_green<120 & ...
                    Cookbook_red<120;
    imwrite(Cookbook_mask, "Pic\CookbookMaskTemp.bmp");
    Cookbook_mask = imdilate(Cookbook_mask, strel('disk',10));
    Cookbook_mask = imerode(Cookbook_mask, strel('disk',10));
    imwrite(Cookbook_mask, "Pic\CookbookMask.bmp");
end

%% Spatial Trans & Light Effect(Style Trans)
% rewrite from lecture code file "registration_controlpoints.m"
if template==1
    [h_ori,w_ori,~] = size(Src);
    if h_ori*1.5>w_ori %Truck需要对原图剪裁
        Src = Src(1:floor(w_ori/1.5)-1,:,:);
    else
        Src = Src(:,1:floor(h_ori*1.5)-1,:);
    end
    [h1,w1,~] = size(Src);
    xs1 = [1 w1 1 w1]';
    ys1 = [1 1 h1 h1]';
    Tar = imread('Pic\Truck.jpg');    
    Tar_mask = imread('Pic\TruckMask.bmp');
    [h2,w2,~] = size(Tar);
    % figure,imshow(Tar)
    % [xs2,ys2] = ginput(4);%四个点的取法分别是左上、右上、左下、右下
    xs2 = [598; 1001; 598; 1001];
    ys2 = [295; 240; 560; 560];
    tform = fitgeotrans([xs1 ys1],[xs2 ys2],'projective');
    Src_trans = imwarp(Src,tform,'OutputView',imref2d(size(Tar)));
    % Light Effect
    Truck_white = imread("Pic\TruckWhite.jpg");
    Src_trans = uint8(double(Src_trans).*double(Truck_white)/256);
elseif template==2
    [h1,w1,~] = size(Src);
    xs1 = [1 w1 1 w1]';
    ys1 = [1 1 h1 h1]';
    Tar = imread('Pic\Gallery.jpg');
    Tar_mask = imread('Pic\GalleryMask.bmp');
    [h2,w2,~] = size(Tar);
    xs2 = [183; 642; 183; 642];
    ys2 = [150; 150; 723; 723];
    tform = fitgeotrans([xs1 ys1],[xs2 ys2],'projective');
    Src_trans = imwarp(Src,tform,'OutputView',imref2d(size(Tar)));
elseif template==3
    [h1,w1,~] = size(Src);
    xs1 = [1 w1/6 2*w1/6 3*w1/6 4*w1/6 5*w1/6 ...
        w1 w1 w1 w1 w1 w1 ...
        w1 5*w1/6 4*w1/6 3*w1/6 2*w1/6 w1/6 ...
        1 1 1 1 1 1 ]';
    ys1 = [1 1 1 1 1 1 ...
        1 h1/6 2*h1/6 3*h1/6 4*h1/6 5*h1/6 ...
        h1 h1 h1 h1 h1 h1 ...
        h1 5*h1/6 4*h1/6 3*h1/6 2*h1/6 h1/6 ]';
    Tar = imread('Pic\Cookbook.jpg');
    Tar_mask = imread('Pic\CookbookMask.bmp');
    [h2,w2,~] = size(Tar);
    xs2 = [584; 644; 704; 758; 810; 858; ...
        908; 955; 1001; 1046; 1090; 1130.3; ...
        1175; 1106; 1041; 975; 908; 847.6; ...
        795.5; 760.3; 725; 689.8; 654.5; 619.3];
    ys2 = [423; 397; 389; 387; 383; 379; ...
        373; 412.9; 452.8; 492.8; 532.7; 572.6; ...
        612.5; 631.3; 644.3; 655; 665; 680.6; ...
        704; 657.2; 610.3; 563.5; 516.7; 469.8];
    tform = fitgeotrans([xs1 ys1],[xs2 ys2],'polynomial',3);
    Src_trans = imwarp(Src,tform,'OutputView',imref2d(size(Tar)));
    % Light Effect
    Cookbook_white = imread("Pic\CookbookWhite.jpg");
    Src_trans = uint8(double(Src_trans).*double(Cookbook_white)/256);
end


mask = sum(Src_trans,3)~=0 & Tar_mask~=0;
idx = find(mask);
Tar(idx) = Src_trans(idx);
Tar(idx+h2*w2) = Src_trans(idx+h2*w2);
Tar(idx+2*h2*w2) = Src_trans(idx+2*h2*w2);

%% Output
if template==1    
    imwrite(Tar, "Pic\TruckTrans.png");
elseif template==2
    imwrite(Tar, "Pic\GalleryTrans.png");
elseif template==3
    imwrite(Tar, "Pic\CookbookTrans.png");
end

