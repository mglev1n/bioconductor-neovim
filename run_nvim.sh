#!/bin/bash

source ~/.bashrc

module load singularity
# module load R/4.3

export PATH=/project/voltron/rstudio/containers/quarto/quarto-1.6.40/bin:$PATH
export R_LIBS_USER=$HOME/R/rocker-rstudio/bioconductor-tidyverse_3.17
export SINGULARITY_BIND="/project/:/project/,/appl/:/appl/,/lsf/:/lsf/,/scratch/:/scratch,/static:/static"
export SINGULARITYENV_APPEND_PATH=/project/voltron/rstudio/containers/quarto/quarto-1.6.40/bin:${PATH}
export SINGULARITYENV_R_LIBS_USER=$HOME/R/rocker-rstudio/bioconductor-tidyverse_3.17

singularity run /project/damrauer_shared/Users/mglevin/bioconductor-neovim/containers/bioconductor-neovim_latest.sif
