%%
close all;
clear;
clc;
%加减乘除
%+ - * / ^
%加减乘除次方
%先乘除，后加减
%%
Fs = 400;     %采样频率200MHz
Ts = 1/Fs;      %采样间隔
N = 1024*4;       %采样点数

table = readmatrix("J5 CH2\150.csv");%读取csv文件
array = table(1:1024,4:7);%转化为数组
array = array';%取转置
f = array(:);%变为列向量
f = f';%变为行向量
t = (0:N-1)*Ts;%时间刻度

%模拟信号
f1 = 50;        
f2 = 89;
fx = 0.5*sin(2*pi*f1*t)+3*cos(2*pi*f2*t)+randn(1,N);

figure;
plot(t,fx);

Fx = fft(fx);
Fx_myself = my_fft(fx);
F = fft(f);
w = (0:N-1)*Fs/N;%傅里叶变换的对应频率刻度0~Fs，Fs~0
figure;
plot(w,abs(Fx_myself));
figure;
plot(w,abs(Fx));

w1 = w(1:N/2);%傅里叶变换的对应频率刻度0~Fs
F1 = F(1:N/2);%一半
figure;
plot(w1,abs(F1));