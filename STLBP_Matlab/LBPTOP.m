function Histogram = LBPTOP(VolData, Code)

%%
[height width Length] = size(VolData);
Histogram = zeros(3, 59); % Bincount = 59;

for i = 2: Length - 1
    for yc = 2: height - 1
        for xc = 2: width - 1
            
            CenterVal = VolData(yc, xc, i);
            %% In XY plane
            BasicLBP = 0;
            FeaBin = 0;
            
            for p = 0 :7
                X = floor(xc + cos((2 * pi * p) / 8) + 0.5);
                Y = floor(yc - sin((2 * pi * p) / 8) + 0.5);
                
                %CurrentVal = VolData(Y, X, i);
                
                if VolData(Y, X, i) >= CenterVal
                    BasicLBP = BasicLBP + 2 ^ FeaBin;
                end
                FeaBin = FeaBin + 1;
            end
            Histogram(1, Code(BasicLBP + 1, 2) + 1) = Histogram(1, Code(BasicLBP + 1, 2) + 1) + 1;
            
            %% In XT plane
            BasicLBP = 0;
            FeaBin = 0;
            for p = 0 :7
                X = floor(xc + cos((2 * pi * p) / 8) + 0.5);
                Z = floor(i + sin((2 * pi * p) / 8) + 0.5);
                
                %CurrentVal = VolData(yc, X, Z);
                
                if VolData(yc, X, Z) >= CenterVal
                    BasicLBP = BasicLBP + 2 ^ FeaBin;
                end
                FeaBin = FeaBin + 1;
            end
            
            Histogram(2, Code(BasicLBP + 1, 2) + 1) = Histogram(2, Code(BasicLBP + 1, 2) + 1) + 1;
            
            %% In YT plane
            BasicLBP = 0;
            FeaBin = 0;
            for p = 0 :7 
                Y = floor(yc - sin((2 * pi * p) / 8) + 0.5);
                Z = floor(i + cos((2 * pi * p) / 8) + 0.5);
                
                %CurrentVal = VolData(Y, xc, Z);
                
                if VolData(Y, xc, Z) >= CenterVal
                    BasicLBP = BasicLBP + 2 ^ FeaBin;
                end
                FeaBin = FeaBin + 1;
            end
            Histogram(3, Code(BasicLBP + 1, 2) + 1) = Histogram(3, Code(BasicLBP + 1, 2) + 1) + 1;
            
        end
    end
end

%% normalization
for j = 1 : 3
    Histogram(j, :) = Histogram(j, :)./sum(Histogram(j, :));
end
