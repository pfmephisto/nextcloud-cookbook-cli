#!/usr/bin/env bash
###################################################################################
#  $$$$$$\                      $$\       $$\                           $$\       
# $$  __$$\                     $$ |      $$ |                          $$ |      
# $$ /  \__| $$$$$$\   $$$$$$\  $$ |  $$\ $$$$$$$\   $$$$$$\   $$$$$$\  $$ |  $$\ 
# $$ |      $$  __$$\ $$  __$$\ $$ | $$  |$$  __$$\ $$  __$$\ $$  __$$\ $$ | $$  |
# $$ |      $$ /  $$ |$$ /  $$ |$$$$$$  / $$ |  $$ |$$ /  $$ |$$ /  $$ |$$$$$$  / 
# $$ |  $$\ $$ |  $$ |$$ |  $$ |$$  _$$<  $$ |  $$ |$$ |  $$ |$$ |  $$ |$$  _$$<  
# \$$$$$$  |\$$$$$$  |\$$$$$$  |$$ | \$$\ $$$$$$$  |\$$$$$$  |\$$$$$$  |$$ | \$$\ 
#  \______/  \______/  \______/ \__|  \__|\_______/  \______/  \______/ \__|  \__|
###################################################################################
#
#
#
# Structure
#
# Settings
# Commangs
# Main function


SERVER=""
AUTHTOKEN=""
APP="apps/cookbook/"

source ~/.config/cli-cookbookrc



_jq() {
  echo ${1} | base64 --decode | jq -r ${2}
}

      # "${SERVER}${APP}apiv1/recipes" \
_command_get_all_recipes() {
  recipes=$(curl -X 'GET' \
    "${SERVER}${APP}/api/v1/recipes" \
    -s \
    -H 'accept: application/json' \
    -H "Authorization: Basic $AUTHTOKEN")
}

_command_get_single_recipe(){
  recipe=$(curl -X 'GET' \
    "${SERVER}${APP}/api/v1/recipes/$1" \
    -s \
    -H 'accept: application/json' \
    -H "Authorization: Basic $AUTHTOKEN")
}

_command_print_all_recipes(){
   for recipe in $(echo -n $recipes | jq -r '.[] | @base64'); do
    printf "%+10s" "$(_jq $recipe '.recipe_id')"
    printf " - $(_jq $recipe '.name')"
    printf "\n"
   done
}


_add_ingreediances_to_taskworrior(){

  ids=""

  for ingreedient in $(echo -n $recipe | jq '.recipeIngredient[] | @base64 ' | tr -d '"' )
  do
    id=$(echo $(task add project:Shopping "Buy: $(echo $ingreedient | base64 --decode)" 2> /dev/null ) | sed -r 's|.* ([0-9]+).|\1|g')
    ids="${ids},${id}"
  done

  ids=$(echo $ids | sed 's/,*//')

  task add project:ToDo depends:"$ids" "Cook: $(echo -n $recipe | jq '.name')" 1> /dev/null 2> /dev/null
  echo "Add ingrediants to taskwarior"
}



_ask_user_to_add_ingreediance(){
    read -p "Do you want to add the ingreedients to the Task/Shopping list? [y/N]:" confirm

    case $confirm in
      Y)
        _add_ingreediances_to_taskworrior
       return 0
        ;;

      y)
        _add_ingreediances_to_taskworrior
        return 0
        ;;

      N)
        return 1
        ;;

      n)
        return 0
        ;;

      *)
        return 1
        ;;

      esac
}

_command_print_list_ingreediance(){
  # Print Recipe Name
  printf "%-20s\n" "Name: $(echo $recipe | jq -r '.name')"

  # Print Ingreediants
  for ingreedient in $(echo -n $recipe | jq '.recipeIngredient[] | @base64 ' | tr -d '"' )
  do
    printf "> $(echo $ingreedient | base64 --decode )"
    printf "\n"
    # printf "%-20s\n" "> $ingreedient" #$(_jq $ingreedient '.' )"
  done
}



# Main function
if ! [ -z "$1" ]
then
  if [  "$1" == "get" ]
    then
      # Inside "get" command 
      if ! [ -z "$2" ]
      then
        if [ "$2" == "all" ]
        then
         # Inside "get all" all 
         _command_get_all_recipes
         _command_print_all_recipes
        fi
        if [ "$2" == "ingrediants" ]
        then
          # Inside "get ingrediants" command
          if ! [ -z "$3" ]
          then
            _command_get_single_recipe $3
            _command_print_list_ingreediance
            _ask_user_to_add_ingreediance
          fi
        fi
      fi
    fi
fi

