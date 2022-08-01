#!/bin/bash
## Setup Conda venv
source ~/miniconda3/etc/profile.d/conda.sh
echo "--- Setting up virtual environment ---"
conda create --name imsearch -y
conda activate imsearch
conda install -c pytorch faiss-cpu -y # You may swap this with faiss-gpu, if you will be using utils/train.py on the same host
echo "export LIBRARY_PATH=~/miniconda3/envs/imsearch/lib" >> ~/.bashrc
export LIBRARY_PATH=~/miniconda3/envs/imsearch/lib

# Download and prepare imsearch source
echo "--- Downloading imsearch source ---"
cd ~
mkdir imsearch
cd imsearch
git clone https://github.com/lolishinshi/imsearch
cd imsearch
echo "--- Patching source ---"
minicondavenvincludepath="\/home\/$USER\/miniconda3\/envs\/imsearch\/include"
sed -i "s/\/\/ .include(\"\/home\/yhb\/.miniconda3\/include\")/.include(\"$minicondavenvincludepath\")/g" build.rs
sed -i 's/flann::SearchParams::new_1/flann::SearchParams::new/g' src/config.rs

# Building imsearch
echo "--- Building imsearch ---"
cargo install --path .
sudo cp ~/miniconda3/envs/imsearch/lib/libfaiss* /usr/lib/x86_64-linux-gnu
sudo cp ~/miniconda3/envs/imsearch/lib/libmkl* /usr/lib/x86_64-linux-gnu
sudo cp ~/.cargo/bin/imsearch /bin

# Cleaning up
## Uninstall conda
echo "--- Removing conda ---"
conda deactivate
conda activate base
conda install anaconda-clean -y
anaconda-clean --yes
conda deactivate
rm -rf ~/miniconda3
cd ~
rm -rf imsearch
rm -rf .anaconda_backup
rm Miniconda3-latest-Linux-x86_64.sh

## Remove rust
echo "--- Removing rust ---"
rustup self uninstall -y