function y = rader(x)
    N = length(x);
    j = N/2;
    for i = 1:N-1%大于8用1:N-1,小于8用N/2-1
    %实现了奇偶前后分开排序，比较前半部分序数[0 1 2 3]，对每对中的后一个偶数进行交换，1换4，3换6
        if i<j
            t = x(j+1);
            x(j+1) = x(i+1);
            x(i+1) = t;
        end
        %求下一个倒序数
        k = N/2;%数组半长
        while(j>=k)%j为下一个倒序数，比较100的最高位1，若位1，置零
            j = j-k;
            k = k/2;
        end
        if j<k
            j = j+k;%找到0的一位，补成1，j就是下一个倒序数
        end
    end
    y = x;
end