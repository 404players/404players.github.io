#/bin/bash

###################################################################
# Script Name : 404players.sh
# Description : Convert API Gomo to player format.
# Author      : Raja Nq
# Email       : raja.nq.kotlin@gmail.com
# Using       : ./404players.sh "GomoKEY"
###################################################################

apt-get -qq -y install wget jq

start=$(date +%s)

API_D="api"

rm -rf "${API_D}"
mkdir -p "${API_D}"

KEY=${1:-}
wget -O "${API_D}"/episodes.json "https://user.gomo.to/user-api/episodes?key=${KEY}&allepisodelist=yes"
wget -O "${API_D}"/movies.json "https://user.gomo.to/user-api/movies?key=${KEY}&allmovieslist=yes"

E=$(jq length "${API_D}"/episodes.json)
EP=0
declare -A arr_e
echo "Start parse ${E} episodes"
jq -r '.[]|[.[0], .[1], .[2], .[3]] | @tsv' "${API_D}"/episodes.json |
  while IFS=$'\t' read -r id season episode slug; do
  	EP=$((EP+1))
  	echo "${EP}/${E}) ${id} ${season} ${episode} ${slug}"
  	if [ "${arr_e[${id}]}" ]; then
  		arr_e[${id}]="${arr_e[${id}]},{\"season\":\"${season}\",\"episode\":\"${episode}\",\"iframe\":\"https://gomo.to/show/${slug}/${season}-${episode}\"}"
  	else
  		arr_e[${id}]="{\"season\":\"${season}\",\"episode\":\"${episode}\",\"iframe\":\"https://gomo.to/show/${slug}/${season}-${episode}\"}"
  	fi
  	if [ ${EP} -eq ${E} ]; then
  		echo "Start save episodes"
  		IDs=""
  		for key in ${!arr_e[@]}; do
  			echo "${key}"
  			echo "{\"id\":\"${key}\",\"simple-api\":[${arr_e[${key}]}]}" > "${API_D}/${key}.json"
  			arr_e[${key}]=""
  			if [ "${IDs}" ]; then
  				IDs="${IDs},\"${key}\""
  			else
  				IDs="\"${key}\""
  			fi
  		done
  		echo "{\"api\":[${IDs}]}" > "${API_D}/episodes.json"
  		break;
  	fi
  done

M=$(jq length "${API_D}"/movies.json)
MP=0
declare -A arr_m
echo "Start parse ${M} movies"
jq -r '.[]|[.imdId, .slug] | @tsv' "${API_D}"/movies.json |
  while IFS=$'\t' read -r id slug; do
  	MP=$((MP+1))
  	echo "${MP}/${M}) ${id} ${slug}"
  	if [ "${arr_m[$id]}" ]; then
  		arr_m[$id]="${arr_m[$id]},{\"iframe\":\"https://gomo.to/movie/${slug}\"}"
  	else
  		arr_m[$id]="{\"iframe\":\"https://gomo.to/movie/${slug}\"}"
  	fi
  	if [ ${MP} -eq ${M} ]; then
  		echo "Start save movies"
  		IDs=""
  		for key in ${!arr_m[@]}; do
  			echo "${key}"
  			echo "{\"id\":\"${key}\",\"simple-api\":[${arr_m[${key}]}]}" > "${API_D}/${key}.json"
  			arr_m[${key}]=""
  			if [ "${IDs}" ]; then
  				IDs="${IDs},\"${key}\""
  			else
  				IDs="\"${key}\""
  			fi
  		done
  		echo "{\"api\":[${IDs}]}" > "${API_D}/movies.json"
  		break;
  	fi
  done

end=$(date +%s)

echo "Runtime: $((end - start)) sec"