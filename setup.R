#!/usr/bin/env R
# Run after fresh clone. Add new packages to 'packages' list and re-run.

# Borrowed from:
# https://gist.github.com/stevenworthington/3178163#file-ipak-r
ipak <- function(pkg){
    new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
    if (length(new.pkg))
        install.packages(new.pkg, dependencies = TRUE)
    sapply(pkg, require, character.only = TRUE)
}

# Install Devtools
install.packages("devtools")

# packages to install
packages <- c("tidyverse", "import","glue", "RMariaDB", "ggplot2", "scales",
              "reshape2", "RSQLite", "DBI")

# TODO: Finish this setup 
# packages = read.delim("requirements_r.txt", header = F, sep = "\n", stringsAsFactors = F)[, 1]

# Install package list
ipak(packages)
