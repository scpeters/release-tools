#!/bin/bash

set -x
set -e

# Original jenkins/homebrew directory 
JENKINS_ORIG=/Users/jenkins/jenkins.yLtQ
# Copied original directory into temp
TEMP_ORIG=/tmp/jenkins.yLtQ
CELLAR_DIR=${TEMP_ORIG}/Cellar
GAZEBO_ROOT_INSTALLATION=${CELLAR_DIR}/gazebo/HEAD/

TEMP_DIR=/tmp/lala
MACOS_DIR=${TEMP_DIR}/MyApp.app/Contents/MacOS/
FRAMEWORK_DIR=${TEMP_DIR}/MyApp.app/Contents/Frameworks

DYLIBBUNDLER=/tmp/dylibbundler

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
    [[ ${path:0:7} == '@loader' ]] && return 0
    # Do not change system references
    [[ ${path:0:4} == '/usr'      ]] && return 1 
    [[ ${path:0:5} == '/tmp/'     ]] && return 1 
    [[ ${path:0:9} == '/private/' ]] && return 1 
    [[ ${path:0:7} == '/System'   ]] && return 1
    [[ ${path:0:1} == '@'         ]] && return 1
    
    echo "!!!!! Unknown value of path: $path"
    exit -1
}

is_loader_path()
{
    local path=$1
    [[ ${path:0:7} == '@loader' ]] && return 0

    return 1
}

is_relative_loader_path()
{
    local path=$1
    [[ ${path:0:16} == '@loader_path/lib' ]] && return 0
    
    return 1
}

is_relative_path()
{
    [[ ${path:0:3} == 'lib' ]] && return 0

    return 1
}

check_existing_new_link()
{
    local new_path=${1}

    if is_loader_path $new_path; then
      new_path=${new_path/@loader_path}
    fi

    link=$(sed "s:@executable_path:${MACOS_DIR}:" <<<  ${new_path})
    if [[ ! -f $link ]]; then
        echo "Internal error - fail to locate link: ${link}"
        exit -1
    fi
}

fix_id()
{
    local file=$1
      
    abs_path=$(python -c 'import os; print os.path.realpath("'$file'")')
    print_debug "+ Change id -> ${abs_path}"
    install_name_tool -id ${abs_path} ${file}
}

fix_to_absolute_link_path()
{
    local file=$1 

    LINKED_LIBS=$(otool -L $file | tail -n+2 | awk '{ print $1 }')
    print_debug $LINKED_LIBS
    for link in ${LINKED_LIBS}; do
      print_debug "- Processing link ${link}" 
      local path=$(awk '{ print $1 }' <<< ${link})

      if need_path_fix_link $path; then
        if is_relative_path $path; then
          # Mostly fixing gazebo libraries
          # TODO: will be broken for paths different than just $TEMP_ORIG/lib/
          new_name="${TEMP_ORIG}/lib/${path}"
        elif is_relative_loader_path $path; then
          # Mostly fixing ogre libraries
          # TODO: will be broken for paths different than just $TEMP_ORIG/lib/
          new_name="@loader_path${TEMP_ORIG}/lib/${path/@loader_path\/}"
        else
          new_name=`sed "s:$JENKINS_ORIG:$TEMP_ORIG:" <<< $path`
        fi

        # Need to resolve symlinks
        if [[ -L $new_name ]]; then
          new_name=$(python -c 'import os; print os.path.realpath("'$new_name'")')
          print_debug " + Following symlink: ${new_name}"
        fi

        print_debug "  - ${path} -> ${new_name}"
        check_existing_new_link ${new_name}
        install_name_tool -change $path $new_name $file
      else
        print_debug "  ## skipped"
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

# TODO: define and Icon
echo "+ FIXING BINARIES IN $TEMP_ORIG"
pushd ${TEMP_ORIG}/bin 2> /dev/null
for f in *; do
    print_debug " * Binary: $f" 
    fix_to_absolute_link_path $f 
done
popd 2> /dev/null

echo "+ FIXING LIBS IN $TEMP_ORIG"
pushd ${TEMP_ORIG}/lib 2> /dev/null
for f in *.dylib; do
    print_debug " * Library: $f" 
    fix_id $f
    fix_to_absolute_link_path $f 
done
popd 2> /dev/null


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
# find ${ORIG_LIB_DIR} -name '*.dylib' -exec cp {} ${FRAMEWORK_DIR}  \;
# cp $(find ${ORIG_LIB_DIR} -name QtCore -type f -exec file {} \; | grep Mach-O | cut -d: -f 1) ${FRAMEWORK_DIR}
# cp $(find ${ORIG_LIB_DIR} -name QtGui -type f -exec file {} \; | grep Mach-O | cut -d: -f 1) ${FRAMEWORK_DIR}

#remove gazebo plugins, which belongs to a different directory
# rm -fr ${FRAMEWORK_DIR}/lib*Plugin.dylib

# We should place here gazebo plugins
mkdir -p ${TEMP_DIR}/MyApp.app/Contents/PlugIns
cp -pR ${GAZEBO_ROOT_INSTALLATION}/lib/gazebo-*/plugins/*.dylib \
       ${TEMP_DIR}/MyApp.app/Contents/PlugIns

#install dylibbundler if its not installed
if [ ! -f $DYLIBBUNDLER/dylibbundler ]; then
  #dylibbundler will automatically search every .dylib file used by a program,
  #then it will copy it to the given directory and set the absolute path to relative path.
  
  rm -fR $DYLIBBUNDLER
  mkdir -p $DYLIBBUNDLER
  pushd $DYLIBBUNDLER 2> /dev/null
  curl -c - -OL http://downloads.sourceforge.net/project/macdylibbundler/macdylibbundler/0.4.4/dylibbundler-0.4.4.zip
  unzip *.zip
  cd dylibbundler-*
  make
  cp dylibbundler $DYLIBBUNDLER
  popd 2> /dev/null
fi

echo "RUNNING dylibdundler"
pushd ${MACOS_DIR} 2> /dev/null
for f in *; do
    # Do not try to fix non binary files
    if [[ -z $(file ${f} | grep Mach-O) ]]; then
        print_debug " - ${file} is not binary ## Skipped"
        continue
    fi
    
    print_debug " * Binary: ${f} "
    $DYLIBBUNDLER/dylibbundler -od -b -x ${f} -d ${FRAMEWORK_DIR}
done
popd 2> /dev/null
