close all;
clear;
clc;


%%%%%%%%%%%stage1

N = 64;
n = 0:N/4-1;
W = exp(-1i*2*pi/N*(2*n));
data(1:64) = randn(1,64) + 1i*randn(1,64); %????????  ????
dataA = (data(1:16) + data(33:48) + data(17:32) + data(49:64));                                % 0 4 8  12 16......
dataB = (((data(1:16) + data(33:48)) - (data(17:32) +  data(49:64))).*exp(-1i*2*pi/N*(2*n)));   % 2 6 10 14 18......
dataC = (((data(1:16) - data(33:48)) - 1i*(data(17:32) -  data(49:64))).*exp(-1i*2*pi/N*(1*n))); % 1 5 9  13 17......
dataD = (((data(1:16) - data(33:48)) + 1i*(data(17:32) -  data(49:64))).*exp(-1i*2*pi/N*(3*n))); % 3 7 11 15 19......

%%%%%%%%%stage2

N = 16;
n = 0:N/4-1;
W = exp(-1i*2*pi/N*(2*n));
dataA1 = (dataA(1:4) + dataA(9:12) + dataA(5:8) + dataA(13:16));                               % 0  16 32 48
dataA2 = (((dataA(1:4) + dataA(9:12)) - (dataA(5:8) +  dataA(13:16))).*exp(-1i*2*pi/N*(2*n)));  % 8  24 40 56
dataA3 = (((dataA(1:4) - dataA(9:12)) - 1i*(dataA(5:8) -  dataA(13:16))).*exp(-1i*2*pi/N*(1*n)));% 4  20 36 52
dataA4 = (((dataA(1:4) - dataA(9:12)) + 1i*(dataA(5:8) -  dataA(13:16))).*exp(-1i*2*pi/N*(3*n)));% 12 28 44 60

fft_dataA(1:4:16) = fft(dataA1);
fft_dataA(3:4:16) = fft(dataA2);
fft_dataA(2:4:16) = fft(dataA3);
fft_dataA(4:4:16) = fft(dataA4);

dataB1 = (dataB(1:4) + dataB(9:12) + dataB(5:8) + dataB(13:16));                               % 2  18 34 50
dataB2 = (((dataB(1:4) + dataB(9:12)) - (dataB(5:8) +  dataB(13:16))).*exp(-1i*2*pi/N*(2*n)));  % 10 26 42 58
dataB3 = (((dataB(1:4) - dataB(9:12)) - 1i*(dataB(5:8) -  dataB(13:16))).*exp(-1i*2*pi/N*(1*n)));% 6  22 38 54
dataB4 = (((dataB(1:4) - dataB(9:12)) + 1i*(dataB(5:8) -  dataB(13:16))).*exp(-1i*2*pi/N*(3*n)));% 14 30 46 62

fft_dataB(1:4:16) = fft(dataB1);
fft_dataB(3:4:16) = fft(dataB2);
fft_dataB(2:4:16) = fft(dataB3);
fft_dataB(4:4:16) = fft(dataB4);

dataC1 = (dataC(1:4) + dataC(9:12) + dataC(5:8) + dataC(13:16));                               % 1  17 33 49
dataC2 = (((dataC(1:4) + dataC(9:12)) - (dataC(5:8) +  dataC(13:16))).*exp(-1i*2*pi/N*(2*n)));  % 9  25 41 57
dataC3 = (((dataC(1:4) - dataC(9:12)) - 1i*(dataC(5:8) -  dataC(13:16))).*exp(-1i*2*pi/N*(1*n)));% 5  21 37 53
dataC4 = (((dataC(1:4) - dataC(9:12)) + 1i*(dataC(5:8) -  dataC(13:16))).*exp(-1i*2*pi/N*(3*n)));% 13 29 45 61

fft_dataC(1:4:16) = fft(dataC1);
fft_dataC(3:4:16) = fft(dataC2);
fft_dataC(2:4:16) = fft(dataC3);
fft_dataC(4:4:16) = fft(dataC4);

dataD1 = (dataD(1:4) + dataD(9:12) + dataD(5:8) + dataD(13:16));                               % 3  19 35 51
dataD2 = (((dataD(1:4) + dataD(9:12)) - (dataD(5:8) +  dataD(13:16))).*exp(-1i*2*pi/N*(2*n)));  % 11 27 42 59
dataD3 = (((dataD(1:4) - dataD(9:12)) - 1i*(dataD(5:8) -  dataD(13:16))).*exp(-1i*2*pi/N*(1*n)));% 7  23 39 55
dataD4 = (((dataD(1:4) - dataD(9:12)) + 1i*(dataD(5:8) -  dataD(13:16))).*exp(-1i*2*pi/N*(3*n)));% 15 31 47 63

fft_dataD(1:4:16) = fft(dataD1);
fft_dataD(3:4:16) = fft(dataD2);
fft_dataD(2:4:16) = fft(dataD3);
fft_dataD(4:4:16) = fft(dataD4);

fft2(1:4:64) = fft_dataA;
fft2(3:4:64) = fft_dataB;
fft2(2:4:64) = fft_dataC;
fft2(4:4:64) = fft_dataD;

fft1 = (fft(data));
figure
subplot(1,2,1);
plot(abs(fft1));
subplot(1,2,2);
plot(abs(fft2));