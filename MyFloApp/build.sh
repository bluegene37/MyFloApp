#! /bin/bash
#Accept the user arguments into local variables
WORKSPACE=$PWD
PROJECT_NAME="MagicApp"
DESTINATION_PATH="${WORKSPACE}/Output"
#
#
#Set internal variables
PROJDIR="${WORKSPACE}"
PROJECT_BUILDDIR="${PROJDIR}/build/Products"
PBPROJECT_LOCATION=`pwd`/MagicApp.xcodeproj
echo PROJECT_BUILDDIR: $PROJECT_BUILDDIR

#
#Creating the output folder if no exist
if [ ! -d ${DESTINATION_PATH} ]
then
	mkdir ${DESTINATION_PATH}
fi
#
#

APP_ID=`grep 'bundle.identifier' settings.properties | awk '{print substr($1,length("bundle.identifier")+2,length($1))}'`
VERSION_NAME=`grep 'version' settings.properties | awk '{print substr($1,length("version")+2,length($1))}'`
VERSION_CODE=`grep 'build' settings.properties | awk '{print substr($1,length("build")+2,length($1))}'`
PROVISONNING_PROFILE=`grep 'provisioning.profile.filename' settings.properties | awk '{print substr($1,length("provisioning.profile.filename")+2,length($1))}'`

#The next 2 variables are used for handling blank spaces in the required value
FROM_COLUMN=`echo 'bundle.display.name' | awk '{print length($1)+2}'`
DNAME_STRING_LENGTH=`grep 'bundle.display.name' settings.properties | awk '{print length('$1')}'`
BUNDLE_DISPLAY_NAME=`grep 'bundle.display.name' settings.properties | cut -c${FROM_COLUMN}-$DNAME_STRING_LENGTH`

FROM_COLUMN=`echo 'target.name' | awk '{print length($1)+2}'`
DNAME_STRING_LENGTH=`grep 'target.name' settings.properties | awk '{print length('$1')}'`
TARGET_NAME=`grep 'target.name' settings.properties | cut -c${FROM_COLUMN}-$DNAME_STRING_LENGTH`

FROM_COLUMN=`echo 'developer.account.name' | awk '{print length($1)+2}'`
DNAME_STRING_LENGTH=`grep 'developer.account.name' settings.properties | awk '{print length('$1')}'`
DEVELOPPER_NAME=`grep 'developer.account.name' settings.properties | cut -c${FROM_COLUMN}-$DNAME_STRING_LENGTH`

#The next variable is for the URLSchema (used for launching the app from external app
#The values used here is the app name without spaces.
URL_SCHEMA="${BUNDLE_DISPLAY_NAME// /}"

PLIST_LOCATION=`pwd`/MagicApp/MagicApp-Info.plist
defaults write $PLIST_LOCATION CFBundleIdentifier $APP_ID
defaults write $PLIST_LOCATION CFBundleDisplayName $BUNDLE_DISPLAY_NAME
defaults write $PLIST_LOCATION CFBundleName $BUNDLE_DISPLAY_NAME
defaults write $PLIST_LOCATION CFBundleShortVersionString $VERSION_NAME
defaults write $PLIST_LOCATION CFBundleVersion $VERSION_CODE
defaults write $PLIST_LOCATION CFBundleURLTypes -array '{CFBundleURLName="'$APP_ID'";CFBundleURLSchemes=('$URL_SCHEMA');}'

sed -i '' "s/PROJECT_TARGET/${TARGET_NAME}/" ${PBPROJECT_LOCATION}/project.pbxproj

if  [ "$1" == "-h" ] ; then
   cat buildSh.help
    exit 1
fi

#Adds few lines of declarations to the project so that the project will include the Settings.Bundle files (which defined the Settings screen).
#This will be done only for generic URL app (URL="").
if [ -e "Settings.bundle" ] 
then
	 #check if this is generic url app
	 if grep -q 'key="URL" val=""' execution.properties 
	 then
	 	 #check if added already
	 	 if ! grep -q Settings.bundle "${PBPROJECT_LOCATION}"/project.pbxproj
	 	 then
			 SETTINGSTR='\
79C04DC9178C598B00171F4F = {isa = PBXBuildFile; fileRef = 79C04DC8178C598B00171F4F ; };\
79C04DC8178C598B00171F4F = {isa = PBXFileReference; lastKnownFileType = "wrapper.plug-in"; path = Settings.bundle; sourceTree = "<group>"; };'
			 sed -i '' "s/objects = {/&${SETTINGSTR}/" ${PBPROJECT_LOCATION}/project.pbxproj
			 SETTINGSTR='\
79C04DC8178C598B00171F4F,'
			 sed -i '' "/72F38F9C15299F1F0090D412 =/,/children =/s/children = (/&${SETTINGSTR}/" ${PBPROJECT_LOCATION}/project.pbxproj
			 SETTINGSTR='\
79C04DC9178C598B00171F4F,'
			 sed -i '' "/isa = PBXResourcesBuildPhase;/,/files =/s/files = (/&${SETTINGSTR}/" ${PBPROJECT_LOCATION}/project.pbxproj
	 	 fi
	 fi
fi

#Creating log file if does not exist and cleaning it if exists before every build
FIND_LOG=`ls -ltrh | grep build.log`
if [ FIND_LOG != "" ] ; then
    echo "" > build.log
else
    touch build.log
fi

echo "Building the project"
xcodebuild -target "${TARGET_NAME}" -configuration "Release" >> build.log
BUILD_RESULT=$?
#Check if build succeeded
if  [ $BUILD_RESULT != "0" ] ; then
	echo "Build failed with error $BUILD_RESULT!! Script is terminating"
	exit 1
else
	echo "Build succeeded!  Continue to sign the build"
fi

#Create and sign the IPA
if [ -z "$CODESIGN_ALLOCATE" ]; then
 export CODESIGN_ALLOCATE="`xcode-select --print-path`/Platforms/iPhoneOS.platform/Developer/usr/bin/codesign_allocate"
fi
echo "Create and sign the IPA"
/usr/bin/xcrun -sdk iphoneos PackageApplication -v "${PROJECT_BUILDDIR}/${TARGET_NAME}.app" -o "${DESTINATION_PATH}/${TARGET_NAME}.ipa" --sign "${DEVELOPPER_NAME}" --embed "${PROVISONNING_PROFILE}" >> build.log

#Check if the archive creation  succeeded
BUILD_RESULT=$?
    if  [ $BUILD_RESULT != "0" ] ; then
        echo "Archive creation failed  with error $BUILD_RESULT!! Script is terminating"
        exit 1
    else
        echo "Archive creation succeeded!Continue to clean the build"
    fi
#Cleaning
echo "Cleaning intermediate files"
xcodebuild clean -configuration "Release" >> build.log
rm -rf "Build"
