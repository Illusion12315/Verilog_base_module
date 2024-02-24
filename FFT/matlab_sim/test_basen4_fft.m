clc;
clear;
close all;
%%
N = 4;
data(1:N) = randn(1,N) + 1i*randn(1,N);
mult = 1;

a = fft(data);
b = butterfly_base_n4(data,N,mult);
b = [b(1),b(3),b(2),b(4)];
figure
subplot(2,1,1)
plot(abs(a));
subplot(2,1,2)
plot(abs(b));

%%
N = 16;
%data(1:N) = randn(1,N) + 1i*randn(1,N);
x = 1:2:32;
data = x + 1i*(32-x);

a = fft(data);
data1 = butterfly_base_n4(data,N,64);

dataA = butterfly_base_n4(data1(1:4),4,1);
dataB = butterfly_base_n4(data1(5:8),4,1);
dataC = butterfly_base_n4(data1(9:12),4,1);
dataD = butterfly_base_n4(data1(13:16),4,1);

data2 = [dataA,dataB,dataC,dataD];
b = rader(data2);
figure
subplot(2,1,1)
plot(abs(a));
subplot(2,1,2)
plot(abs(b));