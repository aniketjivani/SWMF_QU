**Notes on analysis**:
1) Made scatter plots of each parameter in the i/p parameter space, colored by success or failure of the respective runs. 

2) Visual: See which plots have clearly separable boundaries:
- BrFactor_ADAPT vs nChromoSi_AWSoM
- BrMin vs nChromoSi_AWSoM
- LperpTimesSqrtBSi vs nChromoSi_AWSoM
- PoyntingFluxPerBSi vs nChromoSi_AWSoM
- rMinWaveReflection vs nChromoSi_AWSoM
- StochasticExponent vs nChromoSi_AWSoM

3) Regression model identifies one way and two way interactions

4) Principal Components: Success is doubtful since imbalance in dataset (> 60% are failed runs). Need to check if predictions are more accurate than i) flipping a coin ii) guessing failed every time

5) Also need to check the following: 
i) Make plots of all the variables in the analysis. Where the comparisons with OMNI are bad, categorize separately. Does this make a difference or not?

ii) How do the interactions described by regression hold up here? That is, if we generated test points, do predictions of PCA match up with interaction of the factors in our test points? 
For this, points need to be carefully generated, starting from some baseline and tweaking them for the various (+, -) treatments of factors. 


iii) If the above is consistent, can we use Bayesian optimization to suggest the next points, and weed out points that are unlikely to yield a successful run / successful run with good comparisons? This automatically would constrain the parameter space to meaningful values. 


