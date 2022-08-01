#!/bin/bash

# Update packages
echo "--- Updating packages ---"
sudo apt update
sudo apt upgrade -y

# Install dependencies for imsearch building
echo "--- Preparing environment to compile imsearch ---"

## Install OpenCV, BLAS libraries, Clang and compilers
echo "--- Installing dependencies via APT: build-essential libopencv-dev libopenblas-dev clang libclang-dev ---"
sudo apt install build-essential libopencv-dev libopenblas-dev clang libclang-dev git curl -y

## Install Miniconda
echo "--- Installing miniconda ---"
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
sh Miniconda3-latest-Linux-x86_64.sh -b
export PATH=~/miniconda3/bin:$PATH
conda --version
conda init bash

## Install Rustup
echo "--- Installing rust ---"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain nightly --profile minimal
export PATH=~/.cargo/bin:$PATH
cargo --version

echo "Please restart your shell to run part 2 of this script"
source ~/.bashrc
#### BREAK: SHELL RESTART REQUIRED
#### For some reason source ~/.bashrc isn't working correctly, because running conda activate imsearch will fail