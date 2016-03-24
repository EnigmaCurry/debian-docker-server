# Prompt the user to set a variable name and confirm it's correct
ask_confirm() {
    # Args: PROMPT VARIABLE
    # example: ask_confirm "Enter your name" NAME
    while :
    do
	read -p "$1"": " $2
	echo ${2}=${!2}
	read -p "Does this look right? (Y/n) " LOOKS_RIGHT
	if [ "$LOOKS_RIGHT" == "" ] || [ "$LOOKS_RIGHT" == "Y" ] || [ "$LOOKS_RIGHT" == "y" ]
	then
	    break
	fi
    done
}

# Confirm with the user a set of vars are correct:
confirm_vars() {
    # Args: list of variables to confirm
    # Example:
    #   read -p "Enter your name" NAME
    #   read -p "Enter your age" AGE
    #   confirm_vars NAME AGE
    for var in "$@"
    do
	echo $var=${!var}
    done
    read -p "Does this look right? (Y/n) " LOOKS_RIGHT
    if [ "$LOOKS_RIGHT" == "" ] || [ "$LOOKS_RIGHT" == "Y" ] || [ "$LOOKS_RIGHT" == "y" ]
    then
	return 0
    else
	return 1
    fi
}
