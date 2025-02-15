#!/bin/bash


# Get the current Xcode $CURRENT_PROJECT_VERSION
current_build=$(xcrun agvtool what-version -terse)

# Bump $CURRENT_PROJECT_VERSION
xcrun agvtool bump

# Get the bumped $CURRENT_PROJECT_VERSION
# This is separate from above to avoid having to extract the value
# from a human-readable string
new_build=$(xcrun agvtool what-version -terse)
echo "${current_build} > ${new_build}"

# Change `linux_version.swift`
platform=$(uname)
if [[ ${platform} = Darwin ]]; then
    sed -i '' "s|Int = ${current_build}|Int = ${new_build}|" "$PWD/dlist/linux_version.swift"
else
    sed -i "s|Int = ${current_build}|Int = ${new_build}|" "$PWD/dlist/linux_version.swift"
fi
