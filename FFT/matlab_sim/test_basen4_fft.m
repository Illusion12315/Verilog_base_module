clc;
clear;
close all;
%%
N = 4;
data(1:N) = randn(1,N) + 1i*randn(1,N);

a = fft(data);
b = butterfly_base_n4(data,N);
figure
subplot(2,1,1)
plot(abs(a));
subplot(2,1,2)
plot(abs(b));

%%
N = 16;
data(1:N) = randn(1,N) + 1i*randn(1,N);

a = fft(data);
data1 = butterfly_base_n4(data,N);

dataA = butterfly_base_n4(data1(1:4),4);
dataB = butterfly_base_n4(data1(5:8),4);
dataC = butterfly_base_n4(data1(9:12),4);
dataD = butterfly_base_n4(data1(13:16),4);

data2 = [dataA,dataB,dataC,dataD];
b = rader(data2);
figure
subplot(2,1,1)
plot(abs(a));
subplot(2,1,2)
plot(abs(b));