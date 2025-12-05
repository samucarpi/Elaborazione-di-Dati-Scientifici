#!/bin/bash
export PATH="~/opt/miniconda3/bin":$PATH;
export PATH="~/miniconda3/bin":$PATH;
cd $(conda info | grep -i 'base environment' | sed -E 's/base environment \: (.*) \(writable\)/\1/'); cd envs/pls_toolbox_linux_38/bin/;
pwd;
