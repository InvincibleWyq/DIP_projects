%% 初始化
clear; clc;
radius = 4;
intensity_level = 20;
I_rgb = imread("Pic\selfie.jpg");
% I_rgb = floor(256*rand(8,8,3));

%% 预处理
tic
[w,h,c]=size(I_rgb);
I_gray = rgb2gray(I_rgb);
I_gray = floor(I_gray*(intensity_level/255)); % 降采样
matrix_num = (2*radius+1)^2;
I_trans_rgb = uint8(zeros(w,h,c,matrix_num));
I_trans_gray = uint8(zeros(w,h,matrix_num));
% 图片向各个方向平移，总计matrix_num个，依次排列在高维
count = 0;
for i = -radius:radius
    for j = -radius:radius
        count = count+1;
        I_trans_rgb(max(1,1-i):min(w,w-i),max(1,1-j):min(h,h-j),:,count) = ...
            I_rgb(max(1,1+i):min(w,w+i),max(1,1+j):min(h,h+j),:); 
        I_trans_gray(max(1,1-i):min(w,w-i),max(1,1-j):min(h,h-j),count) = ...
            I_gray(max(1,1+i):min(w,w+i),max(1,1+j):min(h,h+j));        
    end
end

%% 寻找每个像素周围出现频率最高的像素位置，并替换，从而产生"油画"效果
% 把第三维matrix_num个矩阵压进cell
I_trans_gray_cell = num2cell(I_trans_gray, 3);
% 看每个cell频次最高的非0元素，记录其坐标位置Index
[~, Num] = cellfun(@(x) max(histcounts(x,1:matrix_num)), I_trans_gray_cell);
eq = Num==I_trans_gray;
eq_cell = num2cell(eq, 3);
% Indexes含有所有频次最高非0元素的位置，只需要任取一个即可
Indexes = cellfun(@(x) find(x), eq_cell, 'UniformOutput',false);
Index = cellfun(@headofcell, Indexes);
% 把Index和I_trans_rgb联结在一起，转为I_cell
I_trans_rgb_integrate = uint8(zeros(w,h,c,matrix_num+1));
I_trans_rgb_integrate(:,:,:,1:matrix_num) = I_trans_rgb;
I_trans_rgb_integrate(:,:,:,matrix_num+1) = repmat(uint8(Index),[1,1,c]);
I_cell = num2cell(I_trans_rgb_integrate, 4);
% 用频次最高的非0元素替换原本的像素
I_result = cellfun(@(x) x(x(matrix_num+1)),I_cell);
toc
imwrite(I_result,"Pic\selfie_oil.png");

% 函数：取出cell的首元素，若cell为空则令其为1
function y = headofcell(x)
    if numel(x)~=0
        y = x(1);
    else
        y = 1;
    end
end

