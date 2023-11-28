clear;
ori_img = imread('3.bmp');
[ori_M,ori_N]= size(ori_img);
%每侧扩出16像素边框，让每个8*8都能被作为32*32的中心，算出其中指纹的朝向
img = uint8(254*ones(ori_M+32, ori_N+32));
img(17:ori_M+16, 17:ori_N+16) = ori_img(:,:);
img = im2double(img);
[M,N]= size(img);
subM=floor(ori_M/8);
subN=floor(ori_N/8);
dir = zeros(subM,subN);    %存每个子图的指纹朝向
dis = zeros(subM,subN);    %存每个子图的FFT幅度图双峰间距
mag = zeros(subM,subN);    %存每个子图的FFT最大幅度
mask = zeros(subM,subN);   %存每个子图是否是指纹，由mag决定
figure(1),imshow(ori_img);

enhanced_img = double(zeros(subM*8, subN*8));
maxpix=0;minpix=255;%enhanced_img的最亮和最暗像素，最后线性变换到0~255

for m=1:1:subM
    for n=1:1:subN
        %(m,n)表示在计算哪个子图
        subimg = img(8*m-7:8*m+24, 8*n-7:8*n+24); 
        F = fftshift(fft2(subimg)); 
        Mag = abs(F);
        [Mag,id] = sort(Mag(:),'descend'); 
        [x1,y1] = ind2sub(size(F),id(1)); %幅度图上最大的位置
        [x2,y2] = ind2sub(size(F),id(2)); %幅度图上次大的位置
        mag(m, n) = Mag(1);
        mask(m, n) = Mag(1)<1000 && Mag(1)>10; %设置mask，低于1000才视为有效
        dis(m, n) = sqrt((x1-x2)^2+(y1-y2)^2) * mask(m, n); 
        angles = atan((x2-x1)/(y1-y2)); %FFT幅度图双峰连线方向，弧度制
        dir(m, n) = mod(angles*180/pi,180)-90; %转角度制，垂直需减90°
        %子图像增强，根据创建8*8Gabor滤波器并应用于子图 
        
        if mask(m, n)
            g_filter = zeros(32);
            sigma = 4;
            omega = dis(m, n); %以dis作为Gabor的频率
            direction = angles+pi/2;%以angles作为Gabor的方向
            for i = 1:32
                for j = 1:32
                    g_filter(i,j) = exp(-((i-16)^2 + (j-16)^2)/(2*sigma^2))*sin( cos(direction) * omega*pi*i/32 + sin(direction) * omega*pi*j/32);
                end
            end
            g_filter_dft = abs(fftshift(fft2(g_filter)));
            fig_dft = fftshift(fft2(subimg));
            I = ifft2(ifftshift(abs(g_filter_dft).*fig_dft));
            %黑白显示
            g_subimg = I;
            g_subimg(find(I>=median(I(:))))=1;
            g_subimg(find(I<median(I(:))))=0;
            enhanced_img(8*m-7:8*m, 8*n-7:8*n) = g_subimg(17:24, 17:24);
        else
            enhanced_img(8*m-7:8*m, 8*n-7:8*n) = 0;
        end         
        
        
%         if mask(m, n) %若mask为0则不是指纹，直接跳过
%             flt_size = 32;
%             var = 16; %Gabor的方差设为1
%             omega = dis(m, n); %以dis作为Gabor的频率
%             direction = angles+pi/2;%以angles作为Gabor的方向
%             [X, Y] = meshgrid(1:flt_size);
%             g_filter =exp(((X-flt_size/2-0.5).^2+(Y-flt_size/2-0.5).^2)/(-2*var)) ...
%                 .* sin((cos(direction)*Y/flt_size+sin(direction)*X/flt_size)*omega)/8;
% 
%             %g_subimg = imfilter(subimg, g_filter);
%             
%             g_filter_dft = abs(fftshift(fft2(g_filter)));
%             subimg_dft = fftshift(fft2(subimg));
%             g_subimg = ifft2(ifftshift(g_filter_dft.*subimg_dft));
%             
%             %把Gabor之后的32*32子图的中心8*8子图存给enhanced_img
%             enh_ori = g_subimg(17:24, 17:24);
%             enh_bin = g_subimg(17:24, 17:24);
%             enh_bin(enh_ori<median(enh_ori(:))) = 0;
%             enh_bin(enh_ori>median(enh_ori(:))) = 1;
%             enhanced_img(8*m-7:8*m, 8*n-7:8*n) = enh_bin;
%         end 
        
    end
end

%DrawDir(1,dir,8,'g',mask); %figure序号1，方向矩阵dir，块尺寸8，绿线，mask

sindir = sin(2*dir*pi/180);
cosdir = cos(2*dir*pi/180);
sindir_gauss = imgaussfilt(sindir,1);%方差1，对应的默认滤波器大小为5*5
cosdir_gauss = imgaussfilt(cosdir,1);
dir_gauss = atan2(sindir_gauss,cosdir_gauss)*180/(2*pi);
DrawDir(1,dir_gauss,8,'g',mask);%此行和上方DrawDir要注释掉一个，显示另一个

freq = dis/max(dis(:)); 
figure(2),imshow(freq);

freq_gauss = imgaussfilt(freq,0.5,'Filtersize',5);%使用默认的0.5方差，3*3滤波器
%figure(2),imshow(freq_gauss);%此行和上方imshow(freq)要注释掉一个，显示另一个

%enhanced_img
%enhanced_img = min( max(enhanced_img-minpix, 0)*255/(maxpix-minpix), 255);
figure(3),imshow(enhanced_img);

