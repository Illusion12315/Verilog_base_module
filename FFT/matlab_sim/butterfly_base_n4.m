function y = butterfly_base_n4(x,N)
    n = 0:N/4-1;
    W = exp(-1i*2*pi/N);
    x1 = x(1 : N/4);
    x2 = x(N/4 + 1 : N/2);
    x3 = x(N/2 + 1 : 3*N/4);
    x4 = x(3*N/4 + 1 : N);

    dataA = x1 + x3;
    dataB = x2 + x4;
    dataC = x1 - x3;
    dataD = x2 - x4;

    dataA1 = dataA + dataB;
    dataB1 = dataA - dataB;
    dataC1 = dataC - 1i*dataD;
    dataD1 = dataC + 1i*dataD;

    y(1 : N/4) = dataA1;
    y(N/4 + 1 : N/2) = dataB1.*(W.^(2*n));
    y(N/2 + 1 : 3*N/4) = dataC1.*(W.^(1*n));
    y(3*N/4 + 1 : N) = dataD1.*(W.^(3*n));
end