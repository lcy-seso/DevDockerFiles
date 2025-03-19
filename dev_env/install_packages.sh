#!/bin/bash

apt-get update

apt-get install -y build-essential cmake git wget curl vim

MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
MINICONDA_INSTALLER="/tmp/miniconda.sh"

echo "Downloading Miniconda installer..."
wget -q $MINICONDA_URL -O $MINICONDA_INSTALLER
chmod +x $MINICONDA_INSTALLER

echo "Installing Miniconda..."
$MINICONDA_INSTALLER -b -p /opt/conda
rm $MINICONDA_INSTALLER

echo "Setting up conda environment..."
ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh
echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc
echo "conda activate base" >> ~/.bashrc

export PATH="/opt/conda/bin:$PATH"

/opt/conda/bin/conda update -y conda

/opt/conda/bin/pip install --upgrade pip
