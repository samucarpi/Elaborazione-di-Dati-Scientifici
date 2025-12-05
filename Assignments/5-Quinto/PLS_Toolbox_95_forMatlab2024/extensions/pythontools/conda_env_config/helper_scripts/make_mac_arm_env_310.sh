#!/bin/bash
#export PATH="~/opt/miniconda3/bin":$PATH;
#export PATH="~/miniconda3/bin":$PATH;
export PATH=$1:$PATH;
conda remove -y --name pls_toolbox_mac_arm_310 --all;
conda env create -f ../ymls/pls_toolbox_mac_arm_310.yml;
#conda install -y -n pls_toolbox_mac_38 -c conda-forge umap-learn==0.5.1;