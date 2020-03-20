function mfit = mergeFit(fit,fit2)
% mergeFit function
% Merge two HAR fit structure
    
    horizon = fieldnames(fit2);
    modeltypes = fieldnames(fit2.(horizon{1}));
    
    % Merge:
    mfit = fit;
    % Add fit2 to mfit:
    for i = 1:numel(modeltypes)
        for h = 1:numel(horizon)
            mfit.(horizon{h}).(modeltypes{i}) = fit2.(horizon{h}).(modeltypes{i});
        end
    end
end