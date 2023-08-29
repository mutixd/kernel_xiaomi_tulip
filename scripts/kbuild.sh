#! /bin/bash

# Copyright (C) 2020 StarLight5234
# Copyright (C) 2021-2023 Unitrix Kernel
#

DEVICE="xiaomi tulip"
TC_PATH="$HOME/clang-r498229b"
COMPILER_NAME="clang"
LD_NAME="ld.lld"
CROSS_COMPILE_ARM64="aarch64-linux-gnu-"
CROSS_COMPILE_ARM32="arm-linux-gnueabi-"
CMDS="LLVM=1 LLVM_IAS=1"
DEFCONFIG="tulip_defconfig kernelsu.config"
OUT_DIR="$(pwd)/out"
KERNEL_IMG="$OUT_DIR/arch/arm64/boot/Image.gz-dtb"
KBUILD_BUILD_USER="ghostmaster69-dev"
KBUILD_BUILD_HOST="codespace"
TZ="Asia/Kolkata"
ZIP_DIR="$HOME/AnyKernel3"

# Ask Telegram Channel/Chat ID
if [ -z "$CHANNEL_ID" ]; then
    echo -n "Plox,Give Me Your TG Channel/Group ID:"
    read -r tg_channel_id
    CHANNEL_ID="$tg_channel_id"
fi

# Ask Telegram Bot API Token
if [ -z "$TELEGRAM_TOKEN" ]; then
    echo -n "Plox,Give Me Your TG Bot API Token:"
    read -r tg_token
    TELEGRAM_TOKEN="$tg_token"
fi

# Upload buildlog to group
function tg_erlog() {
    ERLOG="$HOME/build/build$BUILD.txt"
    curl -F document=@"$ERLOG"  "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" \
	    -F chat_id="$CHANNEL_ID" \
	    -F caption="Build ran into errors after $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds, plox check logs"
}

# Upload zip to channel
function tg_pushzip() {
    FZIP="$(echo $ZIP_DIR/*.zip)"
    curl -F document=@"$FZIP"  "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" \
	    -F chat_id="$CHANNEL_ID" \
	    -F caption="SHA1: $(cat $ZIP_DIR/*.zip.sha1 | cut -c 1-40)"
}

# Send Updates
function tg_sendinfo() {
    curl -s "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
	    -d "parse_mode=html" \
	    -d text="$1" \
	    -d chat_id="$CHANNEL_ID" \
	    -d "disable_web_page_preview=true"
}

# Send a sticker
function start_sticker() {
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker" \
	    -d sticker="CAACAgUAAxkBAAMPXvdff5azEK_7peNplS4ywWcagh4AAgwBAALQuClVMBjhY-CopowaBA" \
	    -d chat_id="$CHANNEL_ID"
}

# clone toolchain
function clone_tc() {
    git clone --depth=1 --single-branch -b clang-r498229b https://gitlab.com/Neebe3289/android_prebuilts_clang_host_linux-x86 $TC_PATH
}

# clone anykernel3
function clone_anykernel3() {
    if ! [ -d $ZIP_DIR ]; then
        git clone --depth=1 -b tulip https://github.com/GhostMaster69-dev/AnyKernel3 $ZIP_DIR
    fi
}

# Make Kernel
function build_kernel() {
    DATE=$date
    BUILD_START=$(date +"%s")
    make ARCH=arm64 CC=$COMPILER_NAME LD=$LD_NAME CROSS_COMPILE=$CROSS_COMPILE_ARM64 CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32 $CMDS O=$OUT_DIR $DEFCONFIG
    make ARCH=arm64 CC=$COMPILER_NAME LD=$LD_NAME CROSS_COMPILE=$CROSS_COMPILE_ARM64 CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32 $CMDS O=$OUT_DIR -j$(nproc --all) |& tee -a $HOME/build/build$BUILD.txt
    BUILD_END=$(date +"%s")
    DIFF=$(($BUILD_END - $BUILD_START))
}

# Make flashable zip
function make_flashable() {
    make -C $ZIP_DIR clean &>/dev/null
    cp $KERNEL_IMG $ZIP_DIR
    cp -rf $(find $OUT_DIR -name "*.ko") $ZIP_DIR/modules/system/lib/modules &>/dev/null
    if [[ $(find $ZIP_DIR/modules/system/lib/modules -name *.ko) ]]; then
        sed -i "s/do.modules=0/do.modules=1/g" $ZIP_DIR/anykernel.sh
    else
        sed -i "s/do.modules=1/do.modules=0/g" $ZIP_DIR/anykernel.sh
    fi
    if [ "$BRANCH" = "test" ]; then
	make LINUX_VERSION="$KERNEL_VERSION" -C $ZIP_DIR test &>/dev/null
    elif [ "$BRANCH" = "beta" ]; then
	make LINUX_VERSION="$KERNEL_VERSION" -C $ZIP_DIR beta &>/dev/null
    else
	make LINUX_VERSION="$KERNEL_VERSION" -C $ZIP_DIR stable &>/dev/null
    fi
}

# Credits: @madeofgreat
BTXT="$HOME/build/buildno.txt" #BTXT is Build number TeXT
if ! [ -a "$BTXT" ]; then
    mkdir $HOME/build
    touch $HOME/build/buildno.txt
    echo $RANDOM > $BTXT
fi
BUILD=$(cat $BTXT)
BUILD=$(($BUILD + 1))
echo $BUILD > $BTXT

# send stickers if build failed
sticker=$(($RANDOM % 5))
if [ "$sticker" = "0" ]; then
    STICKER="CAACAgUAAxkBAAMQXvdgEdkCuvPzzQeXML3J6srMN4gAAvIAA3PMoVfqdoREJO6DahoE"
elif [ "$sticker" = "1" ];then
    STICKER="CAACAgQAAxkBAAMRXveCWisHv4FNMrlAacnmFRWSL0wAAgEBAAJyIUgjtWOZJdyKFpMaBA"
elif [ "$sticker" = "2" ];then
    STICKER="CAACAgUAAxkBAAMSXveCj7P1y5I5AAGaH2wt2tMCXuqZAAL_AAO-xUFXBB9-5f3MjMsaBA"
elif [ "$sticker" = "3" ];then
    STICKER="CAACAgUAAxkBAAMTXveDSSQq2q8fGrIvpmJ4kPx8T1AAAhEBAALKhyBVEsDSQXY-jrwaBA"
elif [ "$sticker" = "4" ];then
    STICKER="CAACAgUAAxkBAAMUXveDrb4guQZSu7mP7ZptE4547PsAAugAA_scAAFXWZ-1a2wWKUcaBA"
fi

function error_sticker() {
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker" \
	    -d sticker="$STICKER" \
	    -d chat_id="$CHANNEL_ID"
}

# Upload build logs file on telegram channel
function tg_push_logs() {
    LOG=$HOME/build/build$BUILD.txt
    curl -F document=@"$LOG"  "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" \
	    -F chat_id=$CHANNEL_ID \
	    -F caption="Build Finished after $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds"
}

# The magic begins here.
clone_tc
PATH="$TC_PATH/bin:$PATH"
make mrproper &>/dev/null
if ! [ -d "$OUT_DIR" ]; then
rm -rf $OUT_DIR
fi
start_sticker
COMPILER_VERSION="$($COMPILER_NAME -v 2>&1 | grep ' version ' | sed 's/([^)]*)[[:space:]]//' | sed 's/([^)]*)//' | sed 's/[[:space:]]*$//'), $($LD_NAME -v | sed 's/[[:space:]](.*)//')"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
COMMIT_HASH="$(git log --pretty=format:'%h' -1)"
COMMIT_MESSAGE="$(git log --pretty=format:'%s' -1)"
KERNEL_VERSION="$(make --no-print-directory kernelversion)"
tg_sendinfo "$(echo -e "\n
<b>Device</b>: <code>$DEVICE</code>\n
<b>Date</b>: <code>$(date +"%d %B %Y")</code>\n
<b>Linux Version</b>: <code>$KERNEL_VERSION</code>\n
<b>Username</b>: <code>$KBUILD_BUILD_USER</code>
<b>Hostname</b>: <code>$KBUILD_BUILD_HOST</code>\n
<b>Compiler version</b>: <code>$COMPILER_VERSION</code>\n
<b>Commit Branch</b>: <code>$BRANCH</code>
<b>Commit Hash</b>: <code>$COMMIT_HASH</code>
<b>Commit Message</b>: <i>$COMMIT_MESSAGE</i>\n")"
build_kernel
clone_anykernel3
if ! [ -a "$KERNEL_IMG" ]; then
    tg_erlog
    error_sticker
    exit 1
else
    tg_push_logs
    make_flashable
    tg_pushzip
fi
