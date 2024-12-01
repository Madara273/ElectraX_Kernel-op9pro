#!/bin/bash
# build.sh - Kernel build script
# Make sure clang is added to your path before using this script.

# Define colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
NC='\033[0m' # No color

# Set Eastern Time timezone
export export TZ=Europe/Kiev # Enter your time zone

# Prompt user for data
echo -e "${PURPLE}Enter KBUILD_USER:${NC}"
read -rp "KBUILD_USER: " KBUILD_USER
echo -e "${PURPLE}Enter KBUILD_HOST:${NC}"
read -rp "KBUILD_HOST: " KBUILD_HOST

# Set environment variables
# echo "export PATH=$(pwd)/../clang+llvm-18.1.8-aarch64-linux-gnu/bin:\$PATH" >> ~/.zshrc
export CLANG_TRIPLE="aarch64-linux-gnu-"
export CROSS_COMPILE="aarch64-linux-gnu-"
export CROSS_COMPILE_ARM32="arm-linux-gnueabi-"

# Set target parameters
TARGET_ARCH="arm64"
TARGET_SUBARCH="arm64"
TARGET_CC="clang"
TARGET_HOSTLD="ld.lld"
TARGET_CLANG_TRIPLE="aarch64-linux-gnu-"
TARGET_CROSS_COMPILE="aarch64-linux-gnu-"
TARGET_CROSS_COMPILE_COMPAT="arm-linux-gnueabi-"
THREAD="$(nproc --all)"
CC_ADDITIONAL_FLAGS="LLVM_IAS=1 LLVM=1 -Wno-error=unused-function"
TARGET_BUILD_USER="$KBUILD_USER"
TARGET_BUILD_HOST="$KBUILD_HOST"
TARGET_COMPILER_STRING="$COMPILER_STRING"
TARGET_LD_VERSION="$LD_VERSION"
TARGET_CC_VERSION="$CC_VERSION"
TARGET_DTC_FLAGS="-q"
TARGET_OUT="../out"
TARGET_DEVICE="lahaina-qgki"
DTC_EXT=$(which dtc)

export TARGET_PRODUCT="$TARGET_DEVICE"

# Set the path to AnyKernel3
AK3_PATH="$TARGET_OUT/AnyKernel3"
LOG_FILE="$AK3_PATH/build.log"
WARNING_PATTERN="warning"
ERROR_PATTERN="error"

# Getting information about git remote, branch and commit
remote=$(git remote -v 2>&1 | grep push | head -n1 | cut -f2 | sed "s/(push)//" | cut -f4 -d "/")
domain=$(git remote -v 2>&1 | grep push | head -n1 | cut -f2 | sed "s/(push)//" | cut -f5 -d "/" | xargs)
branch=$(git status 2>&1 | grep "On branch" | sed -e 's/On branch //g')
commit=$(git rev-parse --short=8 HEAD)

# Kernel DIR
KERNEL_DIR=$(pwd)
echo -e "${GREEN}$KERNEL_DIR${NC}"

# Final kernel build parameters
FINAL_KERNEL_BUILD_PARA="ARCH=$TARGET_ARCH \
                         SUBARCH=$TARGET_SUBARCH \
                         HOSTLD=$TARGET_HOSTLD \
                         CC=$TARGET_CC \
                         CROSS_COMPILE=$TARGET_CROSS_COMPILE \
                         CROSS_COMPILE_COMPAT=$TARGET_CROSS_COMPILE_COMPAT \
                         CLANG_TRIPLE=$TARGET_CLANG_TRIPLE \
                         $CC_ADDITIONAL_FLAGS \
                         DTC_FLAGS=$TARGET_DTC_FLAGS \
                         O=$TARGET_OUT \
                         CC_VERSION=$TARGET_CC_VERSION \
                         LD_VERSION=$TARGET_LD_VERSION \
                         TARGET_PRODUCT=$TARGET_DEVICE \
                         KBUILD_COMPILER_STRING=$TARGET_COMPILER_STRING \
                         KBUILD_BUILD_USER=$TARGET_BUILD_USER \
                         KBUILD_BUILD_HOST=$TARGET_BUILD_HOST \
                         -j$THREAD"

# Kernel target parameters
TARGET_KERNEL_FILE="$TARGET_OUT/arch/arm64/boot/Image"
TARGET_KERNEL_DTB="$TARGET_OUT/arch/arm64/boot/dtb"
TARGET_KERNEL_DTB_IMG="$TARGET_OUT/arch/arm64/boot/dtb.img"
TARGET_KERNEL_DTBO_IMG="$TARGET_OUT/arch/arm64/boot/dtbo.img"
TARGET_KERNEL_NAME="Kernel"
TARGET_KERNEL_MOD_VERSION="$(make kernelversion)"

# Defconfig parameters
DEFCONFIG_PATH=arch/arm64/configs
DEFCONFIG_NAME="ElectraX_defconfig"

# Time parameters
START_SEC=$(date +%s)
CURRENT_TIME=$(date '+%Y%m%d-%H%M')

# Function to display build information
display_build_info(){
    echo -e "${PURPLE}***************ElectraX-Kernel**************${NC}"
    echo -e "PRODUCT: $TARGET_DEVICE"
    echo -e "USER: $KBUILD_USER"
    echo -e "HOST: $KBUILD_HOST"
    echo -e "SUBLEVEL: $(grep -E '^SUBLEVEL =' Makefile | awk '{print $3}')"
    echo -e "${PURPLE}***************Device-Builder**************${NC}"
    echo -e "BUILD_DEVICE: $(lsb_release -a)"
    echo -e "Compiler: $(clang --version | head -n 1)"
    echo -e "Core count: $(nproc)"
    echo -e "Build Date: $(date +"%Y-%m-%d %H:%M")"
    echo -e "${PURPLE}*************last commit details***********${NC}"
    echo -e "Last commit (name): $(git log -1 --pretty=format:%s)"
    echo -e "Last commit (hash): $(git log -1 --pretty=format:%H)"
    echo -e "${PURPLE}*******************************************${NC}"
}

# Function for interactive action selection
choose_action(){
    while true; do
        echo -e "Choose an action:"
        echo -e "${GREEN}1. Install necessary packages${NC}"
        echo -e "${GREEN}2. Start kernel compilation${NC}"
        echo -e "${GREEN}3. Exit program${NC}"
        read -p "Enter the action number (1/2/3): " choice
        case $choice in
            1 ) install_packages;;
            2 ) compile_kernel;;
            3 ) exit;;
            * ) echo -e "${RED}Invalid choice. Please enter 1, 2, or 3.${NC}";;
        esac
    done
}

# Install packages
install_packages(){
    echo -e "${YELLOW}Starting package installation...${NC}"

    sudo apt-get install -y bc
    sudo apt-get install -y bison
    sudo apt-get install -y build-essential
    sudo apt-get install -y zstd
    sudo apt-get install -y clang
    sudo apt-get install -y lld
    sudo apt-get install -y flex
    sudo apt-get install -y gnupg
    sudo apt-get install -y gperf
    sudo apt-get install -y ccache
    sudo apt-get install -y liblz4-tool
    sudo apt-get install -y libsdl1.2-dev
    sudo apt-get install -y libstdc++6
    sudo apt-get install -y libxml2
    sudo apt-get install -y libxml2-utils
    sudo apt-get install -y pngcrush
    sudo apt-get install -y schedtool
    sudo apt-get install -y squashfs-tools
    sudo apt-get install -y xsltproc
    sudo apt-get install -y zlib1g-dev
    sudo apt-get install -y libncurses5-dev
    sudo apt-get install -y bzip2
    sudo apt-get install -y git
    sudo apt-get install -y gcc
    sudo apt-get install -y g++
    sudo apt-get install -y libssl-dev
    sudo apt-get install -y openssl
    sudo apt-get install -y gcc-aarch64-linux-gnu
    sudo apt-get install -y llvm
    sudo apt-get install -y python3-pip
    sudo apt-get install -y device-tree-compiler
    sudo apt-get install -y cpio
    sudo apt-get install -y binutils
    sudo apt-get install -y device-tree-compiler

    echo -e "${GREEN}Necessary packages successfully installed.${NC}"
}

# Clone Anykernel3
clone_anykernel3(){
    while true; do
        echo -e "${YELLOW}Select branch to clone or skip:${NC}"
        echo -e "${BLUE}1. ElectraX${NC}"
        echo -e "${BLUE}2. Custom git clone command${NC}"
        echo -e "${BLUE}3. Skip${NC}"
        read -rp "Enter your choice (1, 2, or 3): " choice

        case $choice in
            1)
                branch="ElectraX"
                git clone --depth=1 https://github.com/Madara273/AnyKernel3.git -b "$branch" "$AK3_PATH" && { echo -e "${GREEN}Clone successful.${NC}"; break; } || echo -e "${RED}Clone failed.${NC}"
                ;;
            2)
                while true; do
                    read -rp "Enter the full git clone command (e.g., git clone https://github.com/username/repository.git -b branch_name): " clone_command
                    # Execute the custom command and check its success
                    eval "$clone_command" && { echo -e "${GREEN}Clone successful.${NC}"; break; } || echo -e "${RED}Clone failed. Please try again.${NC}"
                done
                return 0
                ;;
            3)
                echo -e "${YELLOW}Skipping AnyKernel3 cloning.${NC}"
                return 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                ;;
        esac
    done
}

# Function to check for necessary tools
check_tools(){
    echo -e "${YELLOW}Checking for necessary tools...${NC}"
    command -v clang > /dev/null 2>&1 || { echo -e "${RED}clang is not installed.${NC}"; exit 1; }
    command -v make > /dev/null 2>&1 || { echo -e "${RED}make is not installed.${NC}"; exit 1; }
    command -v mke2fs > /dev/null 2>&1 || { echo -e "${RED}mke2fs is not installed.${NC}"; exit 1; }
    echo -e "${GREEN}All necessary tools are installed.${NC}"
}

# Copy and rename defconfig
copy_and_rename_config() {
    local source_path="arch/arm64/configs/vendor/lahaina-qgki_defconfig"
    local destination_dir=$(dirname "$source_path")/..
    local destination_path="$destination_dir/ElectraX_defconfig"
    while true; do

        echo -e "${YELLOW}------------------------------${NC}"
        read -p "Do you want to copy and rename the file? (yes/no): " response
        case "$response" in
            [Yy][Ee][Ss]|[Yy])

                echo -e "${PURPLE}Operation start: copying and renaming file.${NC}"

                cp -v "$source_path" "$destination_path" && echo -e "${GREEN}File successfully copied and renamed.${NC}"
                break
                ;;
            [Nn][Oo]|[Nn])
                echo -e "${YELLOW}Operation skipped.${NC}"
                break
                ;;
            *)
                echo -e "${RED}Invalid response. Please answer 'yes' or 'no'.${NC}"
                ;;
        esac
    done
}

# Function to create default kernel configuration
make_defconfig(){
    echo -e "${YELLOW}------------------------------${NC}"
    echo -e "${YELLOW} Generating kernel configuration...${NC}"
    make $FINAL_KERNEL_BUILD_PARA $DEFCONFIG_NAME || { echo -e "${RED}Failed to create default kernel configuration.${NC}"; exit 1; }
    echo -e "${GREEN}Default kernel configuration created successfully.${NC}"
    echo -e "${YELLOW}------------------------------${NC}"
}

# Function to build the kernel
build_kernel(){
    echo -e "${YELLOW}------------------------------"
    echo " Building the kernel..."
    echo -e "----------------------------------${NC}"

    set -e  # Exit immediately if a command exits with a non-zero status

    # Function to echo with color and append to log with color sequences
    log_echo(){
        local color=$1
        shift
        local message="$@"
        echo -e "${color}${message}${NC}"
        echo -e "${color}${message}${NC}" >> "$LOG_FILE"
    }

    eval make $FINAL_KERNEL_BUILD_PARA 2>&1 | {
        while IFS= read -r line; do
            [[ $line =~ "$WARNING_PATTERN" ]] && log_echo "${PURPLE}" "$line"
            [[ $line =~ "$ERROR_PATTERN" ]] && log_echo "${RED}" "$line"
            [[ ! ($line =~ "$WARNING_PATTERN" || $line =~ "$ERROR_PATTERN") ]] && echo "$line" | tee -a "$LOG_FILE"
        done
    }

    END_SEC=$(date +%s)
    COST_SEC=$(($END_SEC - $START_SEC))
    echo -e "${GREEN}Kernel build took $(($COST_SEC / 60))m $(($COST_SEC % 60))s${NC}" | tee -a "$LOG_FILE"
}

# Function to link all dtb files
link_all_dtb_files(){
    echo -e "${YELLOW}Linking all dtb and dtbo files...${NC}"

    # Ensure the output directories exist
    mkdir -p $TARGET_OUT/arch/arm64/boot

    # Link .dtb files
    echo -e "${YELLOW}Linking .dtb files...${NC}"
    find $TARGET_OUT/arch/arm64/boot/dts/ -name '*.dtb' -exec cat {} + > $TARGET_OUT/arch/arm64/boot/dtb || echo -e "${RED}Failed to link .dtb files.${NC}"

    # Link .dtbo files
    echo -e "${YELLOW}Linking .dtbo files...${NC}"
    find $TARGET_OUT/arch/arm64/boot/dts/ -name '*.dtbo' -exec cat {} + > $TARGET_OUT/arch/arm64/boot/dtbo || echo -e "${RED}Failed to link .dtbo files.${NC}"

    echo -e "${YELLOW}Linking completed.${NC}"
}

# Generate modules
generate_modules(){
    echo -e "${YELLOW}------------------------------${NC}"
    echo -e "${YELLOW} Generating kernel modules...${NC}"
    echo -e "${YELLOW}------------------------------${NC}"

    # Checking if CONFIG_MODULES=y is set and performing the appropriate actions
    grep -q "^CONFIG_MODULES=y$" "$TARGET_OUT/.config" &&
        MODULES_DIR=$TARGET_OUT/modules_inst &&
        mkdir -p $MODULES_DIR &&
        make $FINAL_KERNEL_BUILD_PARA INSTALL_MOD_PATH=$MODULES_DIR modules_install &&
        echo -e "${YELLOW}Kernel modules generated and installed to $MODULES_DIR.${NC}" ||
        echo -e "${YELLOW}CONFIG_MODULES is not set. Skipping module generation.${NC}"
}

# Function to create a flashable ZIP file
generate_flashable(){
    echo -e "${YELLOW}------------------------------${NC}"
    echo -e "${YELLOW} Generating flashable kernel ${NC}"
    echo -e "${YELLOW}------------------------------${NC}"

    AK3_PATH=$TARGET_OUT/AnyKernel3

    echo -e "${YELLOW} Fetching AnyKernel ${NC}"

    cd $TARGET_OUT
    ANYKERNEL_PATH=AnyKernel3

    echo -e "${YELLOW} Copying kernel file ${NC}"
    cp -r $TARGET_KERNEL_FILE $ANYKERNEL_PATH/ || echo -e "${RED}Failed to copy $TARGET_KERNEL_FILE.${NC}"
    cp -r $TARGET_KERNEL_DTB $ANYKERNEL_PATH/ || echo -e "${RED}Failed to copy $TARGET_KERNEL_DTB.${NC}"
    cp -r $TARGET_KERNEL_DTB_IMG $ANYKERNEL_PATH/ || echo -e "${RED}Failed to copy $TARGET_KERNEL_DTB_IMG.${NC}"
    cp -r $TARGET_KERNEL_DTBO_IMG $ANYKERNEL_PATH/ || echo -e "${RED}Failed to copy $TARGET_KERNEL_DTBO_IMG.${NC}"

    echo -e "${YELLOW} Packing flashable kernel ${NC}"

    CURRENT_TIME=${CURRENT_TIME:-$(date +"%Y%m%d-%H%M")}
    CLEAN_TIME=$(echo "$CURRENT_TIME" | sed 's/[^a-zA-Z0-9._-]//g')

    cd $ANYKERNEL_PATH || { echo -e "${RED}Failed to enter $ANYKERNEL_PATH directory.${NC}"; exit 1; }

    zip -q -r ElectraX-$CLEAN_TIME.zip * -x "README.md" "defconfig" "kernel-changelog.txt" "build.log" || { echo -e "${RED}Failed to pack flashable kernel.${NC}"; exit 1; }

    echo -e "${YELLOW} Target file: $TARGET_OUT/$ANYKERNEL_PATH/ElectraX-$CLEAN_TIME.zip ${NC}"

    cd $KERNEL_DIR
}

# Save kernel configuration
save_defconfig(){
    echo -e "${YELLOW}------------------------------${NC}"
    echo -e "${YELLOW} Saving kernel configuration...${NC}"
    echo -e "${YELLOW}------------------------------${NC}"

    while true; do
        echo -e -n "${PURPLE}Do you want to save the kernel configuration?${NC} (y/n): "
        read answer
        case $answer in
            [Yy]* )
                # Copy the current .config to the destination
                cp $TARGET_OUT/.config $AK3_PATH/defconfig
                END_SEC=$(date +%s)
                COST_SEC=$((END_SEC-START_SEC))
                echo -e "${YELLOW}Completed. Kernel configuration saved to ${AK3_PATH}/defconfig${NC}"
                echo -e "${YELLOW}Kernel configuration save took ${COST_SEC} seconds.${NC}"
                break
                ;;
            [Nn]* )
                echo -e "${YELLOW}Skipping kernel configuration save.${NC}"
                break
                ;;
            * )
                echo -e "${RED}Invalid input. Please answer yes or no.${NC}"
                ;;
        esac
    done
}

# Clean
clean(){
    echo -e "${YELLOW}Cleaning source tree and build files...${NC}"
    make mrproper -j$THREAD > /dev/null 2>&1
    make clean -j$THREAD > /dev/null 2>&1
    rm -rf $TARGET_OUT
    echo -e "${GREEN}Clean completed.${NC}"
}

# Function to setup KernelSU
setup_kernelsu(){
    CONFIG_FILE="arch/arm64/configs/ElectraX_defconfig"

    # If the line CONFIG_KSU=y does not exist, add it
    grep -q '^CONFIG_KSU=y' "$CONFIG_FILE" || {
        # Remove the line # CONFIG_KSU is not set if it exists
        sed -i '/# CONFIG_KSU is not set/d' "$CONFIG_FILE"
        # Add a new line CONFIG_KSU=y
        echo 'CONFIG_KSU=y' >> "$CONFIG_FILE"
        echo -e "${YELLOW}KernelSU option enabled to be built!${NC}"
    }
}

# Generate Changelog
generate_changelog(){
  # Variables
  CHANGELOG_FILE="$AK3_PATH/kernel-changelog.txt"

  # Ensure the target directory exists
  mkdir -p "$AK3_PATH"

  # Use git log to get the latest kernel commits and save them directly in the target directory
  git log -n 350 --pretty=format:"%h - %s (%an)" > "$CHANGELOG_FILE"

  # Add commit titles to the changelog file
  sed -i -e "s/^/- /" "$CHANGELOG_FILE"

  # Print the path to the changelog file
  echo -e "${PURPLE}Changelog saved to $CHANGELOG_FILE ${NC}"
}

# Kernel compilation function
compile_kernel(){
    check_tools
    clean
    clone_anykernel3
    generate_changelog
    copy_and_rename_config
    setup_kernelsu
    make_defconfig
    display_build_info
    save_defconfig
    build_kernel
    link_all_dtb_files
    generate_flashable
}

# Prompt successive steps
choose_action

echo -e "${GREEN}Done.${NC}"
