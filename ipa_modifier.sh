# script for validating/modifying ipa files
# this is a stand alone script 
# usage is for John Scharnikow and Jam Borja
# contact the Resource Managers to try this 
# script once the prototype is working
# version 1.1

#  COLOR schemes borrowed from Mobius
BGCOLOR=$(tput setab 237)
FGCOLOR=$(tput setaf 188)
BOLD=$(tput bold)
CLEAR=$(tput sgr0)
RESET=$CLEAR$BGCOLOR$FGCOLOR
REQCOLOR=$(tput setaf 71)
SUCCESS=$(tput setaf 116)
ALERT=$(tput setaf 213)

echo "-------------------------------------------"
echo "|     .ipa Modifier/Validator Script      |"
echo "-------------------------------------------"
echo "$REQCOLOR NOTE: This script is for prepping .ipa files.$RESET"
echo "$REQCOLOR This can be run independently from Mobius. $RESET"
echo "$REQCOLOR This assumes that the path to the .ipa file contains only 1 .ipa file."
echo ""
echo ""

# [*] take the path to the .ipa file as input
echo "Ex: /var/path_to_ipa_file"
echo "NOTE: Do not include the app_filename.ipa in the path"
echo -ne "Enter path to .ipa file or [Q]uit > $RESET"
read ipa_path

if [[ "$ipa_path" == 'Q' || "$ipa_path" == 'q' ]]
then 
	exit
else

	if [[ -d "$ipa_path" ]]
	then 
		home_dir=`pwd` 
		cd "$ipa_path"
		# Create a copy of the ipa in the modified_ipa directory, and then rename the .ipa to .zip
        # file_name=$(ls -1 "$ipa_path/"*.ipa )
        file_name=$(ls -1 *.ipa )

        cd "$home_dir"
        echo "File name of the ipa file: $file_name"
	    cp "$ipa_path/$file_name" "$ipa_path/newfile_name.ipa" > /dev/null 2>&1
	    mv "$ipa_path/newfile_name.ipa" "$ipa_path/newfile_name.zip" > /dev/null 2>&1
	    
	    #  [*] unzip the ipa
	    echo "Decompressing ipa file..."
	    echo ""
	    unzip "newfile_name.zip"  > /dev/null 2>&1
	    
	    # [*] examine the Info.plist and get basic attributes 
	    # extract bundle ID
	    cd "$ipa_path/Payload"	    
	    # app_bundle=$(ls -1 $ipa_path/Payload/*.app) 

	    app_bundle=$(ls -1)
		echo "value of app bundle is: $app_bundle"

	    cd "$home_dir"

	    # echo "App_bundle value is: $app_bundle"
	    minOSversion=`plutil -key MinimumOSVersion Payload/"$app_bundle"/Info.plist`
	    echo "MinumumOSVersion : $REQCOLOR$minOSversion$RESET"
	    echo ""
	    # [*] extract compatible devices
	    supported_devices=$(plutil -key UIDeviceFamily  Payload/"$app_bundle"/Info.plist)
	    # supported_devices=$(plutil -key UIDeviceFamily  Info.plist)
	    if [[ "$supported_devices" == *1* ]]; then
	        iphone_supported=1
	        app_device_types="Phone"
	    fi

	    if [[ "$supported_devices" == *2* ]]; then
	       	ipad_supported=1
	        app_device_types="Tablet"
	    fi

	    if [[ -n iphone_supported && -n ipad_supported ]]; then
	        app_device_types="Any"
	    fi

	    echo "Support Devices are: $REQCOLOR$app_device_types.$RESET"
	    echo ""
	    # another plutil check for compatible devices
	    device_capabilities=$(plutil -key UIRequiredDeviceCapabilities Payload/"$app_bundle"/Info.plist)
	    # device_capabilities=$(plutil -key UIRequiredDeviceCapabilities Info.plist)
	    echo "These are other device requirements to run the application: "
	    echo "$REQCOLOR$device_capabilities$RESET"
	    echo ""

	    # [*] extract compatible architectures
	    if [[ "$device_capabilities" == *armv6* ]]; then 
	    	armv6_supported=1
	    	echo "$REQCOLOR armv6 is supported.$RESET"
		fi

		if [[ "$device_capabilities" == *armv7* ]]; then
			armv7_supported=1
			echo "$REQCOLOR armv7 is supported.$RESET"
		fi

		if [[ "$device_capabilities" == *arm64* ]]; then 
			arm64_supported=1
			echo "$REQCOLOR arm64 is supported.$RESET"
		fi

		# another otool check for device architectures
		app_binary_name=`plutil -key CFBundleExecutable Payload/"$app_bundle"/Info.plist`
		device_architectures=`otool -arch all -Vhm Payload/"$app_bundle"/"$app_binary_name"`
		echo "Device Architectures are: "
		echo "$REQCOLOR$device_architectures$RESET"
		echo ""
	    # [*] check for simulator build and alert if so e.g. "iPhoneSimulator" or "iphonesimulator"
	    simulator_build="N"
	    supported_platforms=`plutil -key CFBundleSupportedPlatforms Payload/"$app_bundle"/Info.plist`
	    platform_name=`plutil -key DTPlatformName Payload/"$app_bundle"/Info.plist`
	    DTSDK_name=`plutil -key DTSDKName Payload/"$app_bundle"/Info.plist`
	    if [[ "$supported_platforms" == "iPhoneSimulator" || "$supported_platforms" == "iphonesimulator" ]]; then
	    	simulator_build="Y"
		fi

		if [[ "$platform_name" == "iPhoneSimulator" || "$platform_name" == "iphonesimulator" ]]; then 
	    	simulator_build="Y"
		fi

		if [[ "$DTSDK_name" == "$iPhoneSimulator" || "$DTSDKName" == "iphonesimulator" ]]; then 
	    	simulator_build="Y"
		fi

		if [[ "$simulator_build" == "Y" || "$simulator_build" == "y" ]]; then
			echo ""
			echo "$ALERT Application has simulator build!$RESET"
			echo "App build is:"
			echo ""
			echo "supported platforms: $supported_platforms"
			echo "platform name: $platform_name"
			echo "dtsdk name: $DTSDK_name"
			echo ""
		fi

	    # [*] check whether app is encrypted
    	app_version=$(plutil -key CFBundleVersion Payload/"$app_bundle"/Info.plist)
		if [ -z "$app_version" ]
		then
			app_version="not specified"
		fi
		app_binary_path="Payload/$app_bundle/$app_binary_name"
		is_encrypted=`otool -arch all -lm "$app_binary_path" |grep cryptid`
		### APPS THAT ARE NOT ENCRYPTED WILL RETURN HERE ###
		echo "Checking if app is encrypted..."
		echo ""
	    if [[ "$is_encrypted" == *0* ]]
	    then
	    	echo "$REQCOLOR App is not encrypted.$RESET"
	    else
	    	echo "$ALERT App is encrypted.$RESET"
	    fi
	    echo ""

	    # [*] check whether app has been signed	
	    echo "Checking if app has been signed..."
	    echo ""
	    code_sign=`find Payload/"$app_bundle"/ -type d -name "_CodeSignature"`
	    # echo "value for $code_sign"
	    if [[ "$code_sign" != "" ]]
	    then 
	    	echo "$REQCOLOR Application has been signed! $RESET"
		else
			echo "$ALERT Application has not been signed! $RESET"
		fi
		echo ""

		# if we want to support running this script in MacBooks too
		#################### CHECK CODE SIGNATURE DETAILS ########################
		# this is a code for Mac only
		# echo "Code Signature Details: "
		# echo `codesign -dv`
		
	    # [*] check version number of app for non-standard characters
    	if [[ "$app_version" =~ [0-9] ]]
    	echo "App version : $REQCOLOR$app_version$RESET"
    	echo ""
    	then 
	    	echo "$REQCOLOR The app version is fine. It contains characters as expected.$RESET"
	    else
    		echo "$ALERT There are non-standard characters found in the app version! It should only contain numbers. $RESET"
	    fi
	    echo ""
	    echo ""

	    echo ""
	    # [*] as per Jam's suggestion, provide an option for the user to change MinimumOSVersion
	    is_changed="N"
	    echo -ne "Do you want to change the MinimumOSVersion of the app [Y | N]? > "
	    read change_minos_ans
	    if [[ "$change_minos_ans" == "y" || "$change_minos_ans" == "Y" ]]
	    then 
	    	while true
	    	do 
	    		echo -ne "Enter a new value for MinimumOSVersion: "
	    		read new_minos_value
	    		if [[ "$new_minos_value" =~ [0-9.]* ]]
	    		then 
	    			# change minos version
				    success_minOSversion=`plutil -key MinimumOSVersion -value "$new_minos_value" Payload/"$app_bundle"/Info.plist`
				    new_minos_version=`plutil -key MinimumOSVersion Payload/"$app_bundle"/Info.plist`
				    echo "changing MinimumOSVersion..."
				    echo "$SUCCESS MinimumOSVersion is changed to: $new_minos_version. $RESET"
				    echo ""
				    is_changed="Y"
				    break
		    	else
		    		echo "$ALERT The MinimumOSVersion that you entered is not allowed. Try again. $RESET"
		    		continue
		    	fi
		    done
		fi
		echo ""
		echo ""

	    # [*] provide options for the user to change version number or compatible device types
	    echo -ne "Do you want to change the version number of the app [Y | N]? > "
	    read change_ver_ans
	    if [[ "$change_ver_ans" == "y" || "$change_ver_ans" == "Y" ]]
	    then 
	    	while true
	    	do
		    	echo -ne "Enter new value for version number: "
		    	read new_version_value
		    	if [[ "$new_version_value" =~ [0-9.]* ]]
		    	then
					# change app version number
			    	success_changed=$(plutil -key CFBundleVersion -value "$new_version_value" "Payload/$app_bundle/Info.plist")
			    	new_app_version=$(plutil -key CFBundleVersion "Payload/$app_bundle/Info.plist")
					echo "changing app version number..."
					echo "$SUCCESS App version is changed to: $new_app_version. $RESET"
					echo ""
					is_changed="Y"
					break
				else 
		    		echo "$ALERT There are non-standard characters found in the app version! Try again. $RESET"
		    		continue
				fi
	    	done 
		fi
		echo ""
		echo ""


	    # [*] output modified ipa file
	    if [[ "$is_changed" == 'Y' ]]
	    then 
	    	# output modified ipa file
			# recompress the zip file again
		    new_file_name="$file_name"
		    updated_name=`echo "$new_file_name" | sed -e 's/.ipa//g'`
			echo "Compressing the ipa again..."
			zip -r "$updated_name"_updated.zip Payload
			rm -rf "newfile_name.zip" > /dev/null 2>&1		    
		    mv "$updated_name"_updated.zip "$updated_name"_updated.ipa > /dev/null 2>&1
		    output_name="$updated_name"
		    updated_val="_updated.ipa"
		    echo "$REQCOLOR Modified ipa $output_name$updated_val is found @: $ipa_path $RESET" 
	    else
			echo "$REQCOLOR There are no modifications made on the ipa file.$RESET"
		fi
	else
		echo "$ALERT ERROR: The path $ipa_path is not existing! Quitting...$RESET"
	fi

fi
