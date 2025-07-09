#!/bin/bash

# ---- General Setup ----
cd "$(dirname "$0")" # Go to where the script is running
set -e # Exit after error

dotfiles_sel="" # Dotfiles selected, leave empty for now to initalize
folder_list="fastfetch gtk-3.0 gtk-4.0 hypr kitty waybar wofi" # List of folders to overwrite

# Variables for colours, cause I aint remembering all of that.
__RED='\033[1;31m' # Bold red text, for errors
__GREEN='\033[1;32m' # Bold green text for.. uh.. the opposite of errors
__RESET='\033[0m' # Regular boring text

# Create a function to tell the user what argum- I mean disagreements the program has (im not an arguer)
usage() {
	printf "Usage: $0 [OPTION]\n\n"
	printf " -o, --ocha		A simplistic theme that reminds me of green tea.\n"
	printf " -m, --minimalist	A simplistic, black and white theme.\n"
	printf " -t, --teto		A red, Kasane Teto focused rice.\n"
        printf " -f, --fuwamoco		A pink and blue Fuwamoco themed rice.\n"
	exit 1 # Exit with code 1, user did not input any command line arguments
}


# ---- Backup Function ----
backupconfigs() {
	# Make a timestamped backup directory
	backup_dir="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
	mkdir -p "$backup_dir"

	echo "Backing up your configs to $backup_dir/"
	
	# Back up the bashrc and bash_profile first
	
	if [ -f "$HOME/.bash_profile" ]; then
		mv "$HOME/.bash_profile" "$backup_dir/bash_profile"
	fi

	if [ -f "$HOME/.bashrc" ]; then
		mv "$HOME/.bashrc" "$backup_dir/bashrc"
	fi

	for folder in $folder_list; do # loop for every folder in the list I gave earlier
		dest="$HOME/.config/$folder" # dest is short for destination im just using slang here guys
		if [ -d "$dest" ]; then
			mv "$dest" "$backup_dir/"
		fi
	done
}

# ---- Backup Offer ---- 
# A function to ask the user if they would like to backup their old rice
backupask() { 
	printf "\nWould you like to ${__GREEN}backup your files${__RESET} before proceeding?\n"
	printf "This will allow you to revert back to how it was before you installed my rice.\n\n"
	printf "${__RED}!! WARNING !!${__RESET}\n"
	printf "Your old dots will be ${__RED}OVERWRITTEN${__RESET} if you decline!\n\n"

	while :; do # While loop so it loops if the answer isnt yes or no, to avoid overwriting people's dots.

		printf "Would you like to backup existing configs? (y/n): "
		read backupconfirm
		case $backupconfirm in
			[yY][eE][sS]|[yY]) # Check each possible case sensitive answer, this is a positive answer
				backupconfigs
				break # Exit loop now that we have an answer.
				;;
			[nN][oO]|[nN])
				printf "Skipping backup.. overwriting existing configs.\n"
				break # Exit loop
				;;
			*)
				printf "Invalid Input. Please accept or decline.\n"
				;;
		esac
	done
}

# ---- If Hyprland is already running, inform the user it will restart if they decide to install the dotfiles. ----
hyprcheck() {
	if ps cax | grep -q Hyprland; then
		printf "Hyprland is ${__GREEN}running. ${__RESET}Continuing ${__GREEN}installation ${__RESET}will ${__RED}close it.${__RESET}\n"
		read -p "Install dots and restart Hyprland? (y/n): " hypranswer
		case "$hypranswer" in
			[yY][eE][sS]|[yY]) restart_hypr=true ;;
			*) echo "Aborting Install.."; exit 0 ;;
		esac
	else
		restart_hypr=false
	fi

}

# ---- Installation Function ---
installdots() {
	# Tell it where to obtain configs and the wallpaper.
	config_path="./Rices/$dotfiles_sel/Config"
	common_path="./Common" # Files used by ALL rices
	
	# --- Config ---
	if [ ! -d "$config_path" ]; then # check and make sure the config src is good
		printf "${__RED}ERROR:${__RESET} Config not found! This is either a bug, or you messed up something. Config path: $config_path\n"
		exit 2 # exit with code 2 if it cant find the config.
	fi

	for folder in $folder_list; do # Finally, config time.
		src="$config_path/$folder"
		dest="$HOME/.config/$folder"

		if [ -d "$src" ]; then
			echo "Copying $folder to .config"
			rm -rf "$dest" # Since rm -rf is silent, I can remove the old config that was there, if there isnt one then it wont yap ab it and just keep going
			cp -r "$src" "$dest" # Copy to destination
		else
			echo "$folder config is not present in this rice. Skipping." # Future proofing! Awesome!
		fi
	done # I am done the loop

	# --- Wallpaper ---
		
	# Since a wallpaper isnt required, ask the user if they want it.

	while :; do # While loop so it loops if the answer isnt yes or no
		printf "\nDo you want to install the wallpaper? (y/n): " 
		read wlpranswer
		case "$wlpranswer" in 
			[yY][eE][sS]|[yY])
				mkdir -p "$HOME/Pictures/Wallpapers"
				cp ./Rices/"$dotfiles_sel"/Wallpaper/* "$HOME/Pictures/Wallpapers/" && printf "\nWallpaper was ${__GREEN}successfully installed${__RESET}\n\n"
				break
				;;
			[nN][oO]|[nN])
				printf "Skipping wallpaper install..\n"
				break # Exit loop
				;;
			*)
				printf "${__RED}Invalid Input${__RESET}. Please ${__GREEN}accept${__RESET} or ${__RED}decline.${__RESET}\n"
				;;
		esac
	done


	# --- Common Files ---
	if [ -f "$common_path/bashrc" ]; then
		cp "$common_path/bashrc" "$HOME/.bashrc"
	fi

	if [ -f "$common_path/bash_profile" ]; then
		cp "$common_path/bash_profile" "$HOME/.bash_profile"
	fi

	# --- Done! ---
	# This should show up after install.
	printf "${__GREEN}Install Successful!${__RESET} Enjoy!\n"

	# --- If Hyprcheck was triggered, restart after 3 seconds. ---
	if [ "$restart_hypr" = true ]; then
		printf "\nClosing Hyprland in 3 seconds...\n"
		sleep 3
		hyprctl dispatch exit
	fi
}

# ---- Command Line Options ----
case "$1" in
	-o|--ocha) dotfiles_sel="ocha" ;;
	-m|--minimalist) dotfiles_sel="minimalist" ;;
	-t|--teto) dotfiles_sel="teto" ;;
	-f|--fuwamoco) dotfiles_sel="fuwamoco" ;;
	*) # Display usage info if no correct argument is passed.
		printf "${__RED}ERROR:${__RESET} Invalid Syntax.\n\n"
		usage
		;;
esac

hyprcheck
backupask
installdots
