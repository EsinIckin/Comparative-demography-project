
# Cistus libanotis and Halimium halimifolium

Corresponding author: Maria Paniw  
Study DOI: [10.1098/rspb.2022.1494](https://royalsocietypublishing.org/doi/10.1098/rspb.2022.1494)

## Species

These two shrubs are common species in Doñana National Park in Spain.

## Model
Paniw et al. (2023) built a metapopulation model including these two species. They modelled demographic rates (sapling and adult survival) for each of the species using generalized linear models, incorporating covariates such as rainfall and inter- and intraspecific densities.
They constructed three-stages matrix population models for each of the two species.
The R code of the model, climate and population data, and posterior samples were provided by the corresponding author but they can also be found here: https://github.com/MariaPaniw/shrub_forecast
The generation time of each species was obtained from the supplementary materials of the paper. We computed the scaled sensitivities for all vital rates (1) and for each vital rate (2). This was done 100 times, each time resampling parameters from MCMC posterior distributions.

## Files Overview

Main code including models and analyses: perturbationsShrubs_MCMC.R

Inputs:
- allShrubs.Rdata
- Cistus libanotis.Rdata
- Halimium commutatum.Rdata
- Halimium halimifolium.Rdata
- Lavandula stoechas.Rdata
- Rosmarinus officinalis.Rdata
- shrub_number.csv

Outputs:
- sens.shrubs.MCMC.csv (1)
- sens.per.vr.shurbs.MCMC.csv (2)
