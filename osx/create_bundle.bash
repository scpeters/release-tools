#!/bin/bash

#set -x
set -e

TEMP_DIR=/tmp/lala
CELLAR_DIR=/tmp/jenkins.yLtQ/Cellar
GAZEBO_ROOT_INSTALLATION=${CELLAR_DIR}/gazebo/HEAD/

MACOS_DIR=${TEMP_DIR}/MyApp.app/Contents/MacOS/
FRAMEWORK_DIR=${TEMP_DIR}/MyApp.app/Contents/Frameworks

DEBUG=${DEBUG:-false}

print_debug()
{
    local msg=${1}

    if $DEBUG; then
        echo $msg
    fi
}

need_path_fix_link()
{
    local path=$1
    
    # Fix all referecences to local user or relative
    [[ ${path:0:6} == '/Users'  ]] && return 0
    [[ ${path:0:3} == 'lib'     ]] && return 0
    [[ ${path:0:1} == '@'       ]] && return 0
    # Do not change system references
    [[ ${path:0:4} == '/usr'    ]] && return 1 
    [[ ${path:0:7} == '/System' ]] && return 1
    
    echo "!!!!! Unknown value of path: $path"
    exit -1
}

need_relative_path_keeping_prefix()
{
    local path=$1
    [[ ${path:0:7} == '@loader' ]] && return 1

    return 0
}

check_existing_new_link()
{
    local new_path=${1}

    link=$(sed "s:@executable_path:${MACOS_DIR}:" <<<  ${new_path})
    if [[ ! -f $link ]]; then
        echo "Internal error - fail to locate link: ${link}"
        #exit -1
    fi
}

fix_link_path()
{
    # libdir_path: relative path from exectuable
    local file=$1 libdir_path=$2

    echo "* File ${1}" 

    LINKED_LIBS=$(otool -L $file | tail -n+2 | awk '{ print $1 }')
    print_debug $LINKED_LIBS
    for link in ${LINKED_LIBS}; do
      print_debug "- Processing link ${link}" 
      local path=$(awk '{ print $1 }' <<< ${link})
      if need_path_fix_link $path; then
	# Special case when we need to preserve prefix but need relative path fixing
	# this is the case of @loader_path
	if need_relative_path_keeping_prefix $path; then
	    local prefix=${path%%/*}
	    local lib=${path/$prefix}
            local new_name="${prefix}${lib}"
	else
            local lib_name=${path##*/}
            local new_name="@executable_path/$libdir_path/$lib_name"
	fi

        print_debug " - ${path} -> ${new_name}"
        check_existing_new_link ${new_name}
        install_name_tool -change $path $new_name $file
      fi
    done
}

rm -fr ${TEMP_DIR}
mkdir -p ${TEMP_DIR}

mkdir -p ${TEMP_DIR}/MyApp.app/Contents/
cd ${TEMP_DIR}/MyApp.app/Contents/

cat > Info.plist <<DELIM
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist SYSTEM "file://localhost/System/Library/DTDs/PropertyList.dtd">
<plist version="0.9">
  <dict>
    <key>CFBundleName</key>
    <string>gazebo</string>

    <key>CFBundleDisplayName</key>
    <string>Gazebo Simulator</string>

    <key>CFBundleIdentifier</key>
    <string>org.osrfoundation.gazebo</string>

    <key>CFBundleVersion</key>
    <string>3.0.0</string>

    <key>CFBundlePackageType</key>
    <string>APPL</string>

    <key>CFBundleSignature</key>
    <string>????</string>
   
    <key>CFBundleExecutable</key>
    <string>gazebo</string>
  </dict>
</plist>
DELIM

# We should place here gazebo binary and all gz tools
mkdir -p ${MACOS_DIR} 
cp -pR ${GAZEBO_ROOT_INSTALLATION}/bin/* ${MACOS_DIR}

# We should place here SDF files and other resources
mkdir -p ${TEMP_DIR}/MyApp.app/Contents/Resources/
cp -pR ${GAZEBO_ROOT_INSTALLATION}/share/gazebo-*/* \
       ${TEMP_DIR}/MyApp.app/Contents/Resources/

# We should place here private shared libraries
# TODO: Improve the copy of only needed libs
mkdir -p $FRAMEWORK_DIR 
find ${CELLAR_DIR} -name '*.dylib' -exec cp {} ${FRAMEWORK_DIR}  \;
cp $(find ${CELLAR_DIR} -name QtCore -type f -exec file {} \; | grep Mach-O | cut -d: -f 1) ${FRAMEWORK_DIR}
cp $(find ${CELLAR_DIR} -name QtGui -type f -exec file {} \; | grep Mach-O | cut -d: -f 1) ${FRAMEWORK_DIR}

#remove gazebo plugins, which belongs to a different directory
rm -fr ${FRAMEWORK_DIR}/lib*Plugin.dylib

# We should place here gazebo plugins
mkdir -p ${TEMP_DIR}/MyApp.app/Contents/PlugIns
cp -pR ${GAZEBO_ROOT_INSTALLATION}/lib/gazebo-*/plugins/*.dylib \
       ${TEMP_DIR}/MyApp.app/Contents/PlugIns

# TODO: define and Icon

# Fix all bad references in library and binary
pushd ${FRAMEWORK_DIR} 2> /dev/null
for f in *; do
    fix_link_path $f ../Frameworks
done

pushd ${MACOS_DIR} 2> /dev/null
for f in *; do
    fix_link_path $f ../Frameworks
done
