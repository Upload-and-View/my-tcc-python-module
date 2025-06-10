#!/bin/bash

# setup.sh - Script to set up libtcc and build the Python C extension

# Exit immediately if a command exits with a non-zero status.
set -e

echo "--- Starting TCC and Python module setup ---"

# --- Configuration ---
TCC_VERSION="0.9.27" # Using the version that successfully downloaded from the mirror
TCC_TARBALL="tcc-$TCC_VERSION.tar.bz2"
TCC_DOWNLOAD_URL="https://mirror.accum.se/mirror/gnu.org/savannah/tinycc/$TCC_TARBALL"
TCC_DIR="tcc-$TCC_VERSION"

# Default installation prefix for TCC
# /usr/local is common, but may require sudo.
# You can change this to a user-writable path like $HOME/opt if you prefer
TCC_INSTALL_PREFIX="/usr/local"

# --- 1. Install Build Tools (if not present) ---
echo "1. Checking/installing build tools..."
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    if ! command -v gcc &> /dev/null || ! command -v make &> /dev/null; then
        echo "   Installing build-essential (gcc, make)..."
        sudo apt-get update && sudo apt-get install -y build-essential curl
    else
        echo "   Build tools already installed."
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    if ! command -v gcc &> /dev/null; then
        echo "   Installing Xcode Command Line Tools (gcc, make)..."
        xcode-select --install || true # `|| true` to prevent error if already installed
    else
        echo "   Build tools already installed."
    fi
    if ! command -v brew &> /dev/null; then
        echo "   Installing Homebrew (for curl/wget if needed)..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
fi
if ! command -v curl &> /dev/null; then
    echo "   Curl not found, attempting to install..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get install -y curl
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install curl
    fi
fi


# --- 2. Download and Install libtcc ---
echo "2. Downloading and installing libtcc..."

# Check if the TCC source directory already exists from a previous *successful* extraction.
# If it exists, we skip download and extraction.
# IMPORTANT: Before running this script, ensure you've done 'rm -rf tcc-0.9.27' if previous attempts failed.
if [ -d "$TCC_DIR" ]; then
    echo "   TCC source directory '$TCC_DIR' already exists. Skipping download and extraction."
else
    echo "   Downloading $TCC_TARBALL from $TCC_DOWNLOAD_URL..."
    curl -o "$TCC_TARBALL" "$TCC_DOWNLOAD_URL"

    echo "   Extracting $TCC_TARBALL..."
    tar xjf "$TCC_TARBALL"

    # Patch bcheck.c to disable __malloc_hook block for modern glibc compatibility
    echo "   Patching bcheck.c to disable __malloc_hook block for modern glibc compatibility..."
    sed -i 's/#ifdef CONFIG_TCC_MALLOC_HOOKS/#if 0 \/\/ PATCHED_FOR_GLIBC_COMPATIBILITY/g' "$TCC_DIR"/lib/bcheck.c
fi

echo "   Navigating to TCC source directory..."
cd "$TCC_DIR"

echo "   Configuring TCC with shared library support..."
# --enable-shared is crucial for libtcc.so/.dll/.dylib
# We keep this flag despite the 'unrecognized option' warning for TCC 0.9.27,
# as it might still influence the Makefile.
./configure --prefix="$TCC_INSTALL_PREFIX" --enable-shared

echo "   Compiling TCC..."
make

echo "   Installing TCC (this may require sudo password if installing to /usr/local)..."
sudo make install

# Update dynamic linker cache on Linux
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "   Updating dynamic linker cache..."
    sudo ldconfig
fi

echo "   TCC installed to $TCC_INSTALL_PREFIX"
cd .. # Go back to the parent directory where setup.py is

# --- 3. Install Python Dependencies ---
echo "3. Installing Python dependencies..."
echo "   Installing Cython..."
pip install cython

# --- 4. Build Python C Extension ---
echo "4. Building Python C extension module..."
# The --inplace flag builds the module in the current directory
python setup.py build_ext --inplace

echo "--- Setup complete! ---"
echo "You can now run 'python test_tcc.py' to test your module."
