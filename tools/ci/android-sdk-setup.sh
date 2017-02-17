#!/bin/bash

# Sets up the Android SDK.
# Marks a flag to remember whether the SDK has been installed previously
# and will bypass downloading if the flag exists. Note that if you change the version or
# components passed in, you should delete the flag and the installation so that the script will download
# the new version or components.
#
# The script expects several parameters in this order:
# 1. android home directory, e.g. ~/android-sdk
# 2. Android tools version, e.g. 25.2.5
# 3. flag path, e.g. ~/flags/android-sdk-setup
# 4. android sdk components, as used by `sdkmanager`.  e.g. "platforms;android-25" "build-tools;25.0.2" "platform-tools" "docs" "extras;android;m2repository"

set +e

android_sdk_installation_dir="$1"
android_tools_version="$2"
android_sdk_flag_file="$3"
shift 3
android_sdk_components_to_install=("$@")

if ! test -f ${android_sdk_flag_file}; then
  echo "Install Android SDK ${android_tools_version} to ${android_sdk_installation_dir} with ${android_sdk_components_to_install[@]}"

  # Optionally download the SDK, as it might already exist in some environments.
  if ! test -d $android_sdk_installation_dir; then
    mkdir -p $android_sdk_installation_dir
    curl -o $HOME/android-sdk-temp.zip "https://dl.google.com/android/repository/tools_r${android_tools_version}-linux.zip"
    unzip $HOME/android-sdk-temp.zip -d $android_sdk_installation_dir
    rm $HOME/android-sdk-temp.zip
  fi

  mkdir -p ${android_sdk_installation_dir}/licenses/
  cp tools/ci/android-sdk-license ${android_sdk_installation_dir}/licenses/android-sdk-license

  if ! test -d ~/.android; then
    mkdir ~/.android
  fi

  cp tools/ci/repositories.cfg ~/.android/repositories.cfg

  for component in ${android_sdk_components_to_install[@]}; do
      echo "Installing ${component}"
      ${android_sdk_installation_dir}/tools/bin/sdkmanager ${component}
  done

  touch ${android_sdk_flag_file}
fi