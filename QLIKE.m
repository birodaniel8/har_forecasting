function [loss] = QLIKE(f,f_hat)
% QLIKE loss measure
% QLIKE = f/f_hat - log(f/f_hat) - 1
% where f is the actual and f_hat is the predicted value
    loss = f./f_hat - log(f./f_hat) - 1;
end