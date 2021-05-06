%% Animated Polar Plot

% polarplot(GSV_AZM, GSV_ELV, 'o', 'MarkerFaceColor', 'b')

i = 0;
j = ceil(max(GSV_ELV)/10)*10;

for k = 1:100:length(GSV_PRN)

    % if mod(k, 100) == 0
        hold off;
    % end

    l = k + 99;

    if l > length(GSV_PRN)
        l = length(GSV_PRN);
    end
        
    polarplot(GSV_AZM(k : l), GSV_ELV(k : l), 'o', ...
        'MarkerSize', 10, 'MarkerFaceColor', 'r');
    rlim([i j])

    hold on;
    pause(0.1);

end