clear;
ori_img = imread('3.bmp');
[ori_M,ori_N]= size(ori_img);
%ÿ������16���ر߿���ÿ��8*8���ܱ���Ϊ32*32�����ģ��������ָ�Ƶĳ���
img = uint8(254*ones(ori_M+32, ori_N+32));
img(17:ori_M+16, 17:ori_N+16) = ori_img(:,:);
img = im2double(img);
[M,N]= size(img);
subM=floor(ori_M/8);
subN=floor(ori_N/8);
dir = zeros(subM,subN);    %��ÿ����ͼ��ָ�Ƴ���
dis = zeros(subM,subN);    %��ÿ����ͼ��FFT����ͼ˫����
mag = zeros(subM,subN);    %��ÿ����ͼ��FFT������
mask = zeros(subM,subN);   %��ÿ����ͼ�Ƿ���ָ�ƣ���mag����
figure(1),imshow(ori_img);

enhanced_img = double(zeros(subM*8, subN*8));
maxpix=0;minpix=255;%enhanced_img������������أ�������Ա任��0~255

for m=1:1:subM
    for n=1:1:subN
        %(m,n)��ʾ�ڼ����ĸ���ͼ
        subimg = img(8*m-7:8*m+24, 8*n-7:8*n+24); 
        F = fftshift(fft2(subimg)); 
        Mag = abs(F);
        [Mag,id] = sort(Mag(:),'descend'); 
        [x1,y1] = ind2sub(size(F),id(1)); %����ͼ������λ��
        [x2,y2] = ind2sub(size(F),id(2)); %����ͼ�ϴδ��λ��
        mag(m, n) = Mag(1);
        mask(m, n) = Mag(1)<1000 && Mag(1)>10; %����mask������1000����Ϊ��Ч
        dis(m, n) = sqrt((x1-x2)^2+(y1-y2)^2) * mask(m, n); 
        angles = atan((x2-x1)/(y1-y2)); %FFT����ͼ˫�����߷��򣬻�����
        dir(m, n) = mod(angles*180/pi,180)-90; %ת�Ƕ��ƣ���ֱ���90��
        %��ͼ����ǿ�����ݴ���8*8Gabor�˲�����Ӧ������ͼ 
        
        if mask(m, n)
            g_filter = zeros(32);
            sigma = 4;
            omega = dis(m, n); %��dis��ΪGabor��Ƶ��
            direction = angles+pi/2;%��angles��ΪGabor�ķ���
            for i = 1:32
                for j = 1:32
                    g_filter(i,j) = exp(-((i-16)^2 + (j-16)^2)/(2*sigma^2))*sin( cos(direction) * omega*pi*i/32 + sin(direction) * omega*pi*j/32);
                end
            end
            g_filter_dft = abs(fftshift(fft2(g_filter)));
            fig_dft = fftshift(fft2(subimg));
            I = ifft2(ifftshift(abs(g_filter_dft).*fig_dft));
            %�ڰ���ʾ
            g_subimg = I;
            g_subimg(find(I>=median(I(:))))=1;
            g_subimg(find(I<median(I(:))))=0;
            enhanced_img(8*m-7:8*m, 8*n-7:8*n) = g_subimg(17:24, 17:24);
        else
            enhanced_img(8*m-7:8*m, 8*n-7:8*n) = 0;
        end         
        
        
%         if mask(m, n) %��maskΪ0����ָ�ƣ�ֱ������
%             flt_size = 32;
%             var = 16; %Gabor�ķ�����Ϊ1
%             omega = dis(m, n); %��dis��ΪGabor��Ƶ��
%             direction = angles+pi/2;%��angles��ΪGabor�ķ���
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
%             %��Gabor֮���32*32��ͼ������8*8��ͼ���enhanced_img
%             enh_ori = g_subimg(17:24, 17:24);
%             enh_bin = g_subimg(17:24, 17:24);
%             enh_bin(enh_ori<median(enh_ori(:))) = 0;
%             enh_bin(enh_ori>median(enh_ori(:))) = 1;
%             enhanced_img(8*m-7:8*m, 8*n-7:8*n) = enh_bin;
%         end 
        
    end
end

%DrawDir(1,dir,8,'g',mask); %figure���1���������dir����ߴ�8�����ߣ�mask

sindir = sin(2*dir*pi/180);
cosdir = cos(2*dir*pi/180);
sindir_gauss = imgaussfilt(sindir,1);%����1����Ӧ��Ĭ���˲�����СΪ5*5
cosdir_gauss = imgaussfilt(cosdir,1);
dir_gauss = atan2(sindir_gauss,cosdir_gauss)*180/(2*pi);
DrawDir(1,dir_gauss,8,'g',mask);%���к��Ϸ�DrawDirҪע�͵�һ������ʾ��һ��

freq = dis/max(dis(:)); 
figure(2),imshow(freq);

freq_gauss = imgaussfilt(freq,0.5,'Filtersize',5);%ʹ��Ĭ�ϵ�0.5���3*3�˲���
%figure(2),imshow(freq_gauss);%���к��Ϸ�imshow(freq)Ҫע�͵�һ������ʾ��һ��

%enhanced_img
%enhanced_img = min( max(enhanced_img-minpix, 0)*255/(maxpix-minpix), 255);
figure(3),imshow(enhanced_img);

