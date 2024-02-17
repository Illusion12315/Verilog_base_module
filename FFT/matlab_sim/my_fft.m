function y = my_fft(x)
    N = length(x);
    if(N == 1)
        y = x;
        return;
    end
    W = exp(-1i*2*pi/N);

    x_even = x(1:2:end);
    x_odd = x(2:2:end);

    y_even = my_fft(x_even);
    y_odd = my_fft(x_odd);

    for k = 0:1:N/2-1
        y(k+1) = y_even(k+1) + W^k * y_odd(k+1);
        y(k+N/2+1) = y_even(k+1) - W^k * y_odd(k+1);
    end
    return;
end