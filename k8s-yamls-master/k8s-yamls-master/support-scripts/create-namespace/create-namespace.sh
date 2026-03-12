#!/usr/bin/env bash

printUsage () {
	SHORTFILE=$( basename $0 )
	echo "${SHORTFILE} -n 'NEW-NAMESPACE-NAME' -c '(azprod|cadev|caprod|lab|prod)'"
	echo ""
	echo "	-n: Namespace name to create, naming standards as project-environment"
	echo "	-c: Cluster/Context to place the new namespace"
	exit 0
}

getConf () {
	local MSG
	local INP
	MSG="${1} (Please enter 'Y' to continue): "
	while true; do
		echo -e "${MSG}"
		read INP
		if [[ "${INP}" == "Y" || "${INP}" == "y" ]]; then
			break
		else
			echo -e "${RED}Invalid input. Please enter 'Y' to continue, or 'Ctrl-C' to exit.${NC}"
		fi
	done   
}

genNSFile () {
	local NSENV
	NSENV=${1}
	LEFT_NAME=$( echo "${NSNAME}" | awk -F- '{ print $1 }' )

	case ${NSENV} in 
		uat|e2e)
			sed "s/example-uat/${NSNAME}/g" "$(pwd)/ns-templates/example-uat/1-ns.yaml.example" > "${FNSP}/1-ns.yaml" 
			sed "s/example-uat/${NSNAME}/g" "$(pwd)/ns-templates/example-uat/2-sa-vault-default.yaml.example" > "${FNSP}/2-sa-vault-default.yaml" 
			sed -i "s/example-default/${LEFT_NAME}-default/g" "${FNSP}/2-sa-vault-default.yaml" 
			sed "s/example-uat/${NSNAME}/g" "$(pwd)/ns-templates/example-uat/3-sa-restarter.yaml.example" > "${FNSP}/3-sa-restarter.yaml" ;;
		*)
			sed "s/example-${NSENV}/${NSNAME}/g" "$(pwd)/ns-templates/example-${NSENV}/1-ns.yaml.example" > "${FNSP}/1-ns.yaml" 
			sed "s/example-${NSENV}/${NSNAME}/g" "$(pwd)/ns-templates/example-${NSENV}/2-sa-vault-default.yaml.example" > "${FNSP}/2-sa-vault-default.yaml" 
			sed -i "s/example-default/${LEFT_NAME}-default/g" "${FNSP}/2-sa-vault-default.yaml" 
			sed "s/example-${NSENV}/${NSNAME}/g" "$(pwd)/ns-templates/example-${NSENV}/3-sa-restarter.yaml.example" > "${FNSP}/3-sa-restarter.yaml" ;;
	esac
}

printSlyCommands () {
	echo "${BLUE}Sly also wants to print out these commands.${NC}"
	echo ""
	echo "${BLUE}git add ${FNSP}/*${NC}"
	echo "${BLUE}git commit -m 'AUTO-GENERATED CHANGE THIS COMMIT MESSAGE.'${NC}"
	echo "${BLUE}git push origin $(whoami)${NC}"
	

}

unset -v NSNAME
unset -v KCLUSTER 

RED='\033[0;31m' # Red Color
BLUE='\033[0;34m' # Blue Color
NC='\033[0m' # No Color

while getopts n:c: flag
do
    case "${flag}" in
        n) NSNAME=${OPTARG};;
        c) KCLUSTER=${OPTARG};;
    esac
done

FULL_PATH_TO_LIVE='~/WHERE-MY-GIT-FILES-ARE/k8s-yamls/live'

if [ "$#" -ne 4 ]; then
	printUsage
fi

CTCHK=$( echo "${KCLUSTER}" | egrep -c '(azprod|cadev|caprod|lab|prod)' )
if [ ${CTCHK} -eq 1 ]; then
	NSP="${FULL_PATH_TO_LIVE}/${KCLUSTER}/namespaces"	
	NS_FOLDER_CHK=$( find "${NSP}" -maxdepth 0 -type d 2> /dev/null | wc -l ) 
	if [ ${NS_FOLDER_CHK} -eq 0 ]; then
		getConf "The parent 'namespaces' folder does not currently exist.\nContinuing WILL create the 'namespaces' folder, in addition to the actual namespace folder."	
	fi
	FNSP="${NSP}/${NSNAME}"
	FULL_FOLDER_CHK=$( find "${FNSP}" -maxdepth 0 -type d 2> /dev/null | wc -l )
	if [ ${FULL_FOLDER_CHK} -eq 0 ]; then
		mkdir -p "${FNSP}"
	fi
	RIGHT_ENV=$( echo "${NSNAME}" | awk -F- '{ print $NF }' )
	SCRAPE_ENV_CHK=$( echo "${RIGHT_ENV}" | egrep -c '(dev|qa|uat|e2e|prod)' )
	if [ ${SCRAPE_ENV_CHK} -ne 1 ]; then
		getConf "The detected env name of '${RIGHT_ENV}' does not appear to confirm to our standards. Please contact Mark Deckert. Exiting."
		exit -5
	fi
	genNSFile "${RIGHT_ENV}"
	printSlyCommands
else
	printUsage
fi
