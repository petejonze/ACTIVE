% init
clc
clear all

% set up MCS
vals = 1:2:9;
MCS = ConstantStimuli(vals, 10);

% simulated observer
mu = 5;
sigma = 2;

% run
while ~MCS.isFinished()
    x = MCS.getDelta();
    anscorrect = x > normrnd(mu,sigma);
    MCS.update(anscorrect);
end

% query for summary statistics
pc = MCS.getPC();

% plot (though really the 'proper' way to plot 2AFC would be 'Proportion of
% times responded '2' as a function of the difference between the 2
% intervals -- that way you can easily see any bias, and the slope becomes
% a pure measure of sensitivity)
figure();
plot(vals, pc, 'o');
