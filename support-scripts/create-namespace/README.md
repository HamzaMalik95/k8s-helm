```
./create-namespace.sh 
create-namespace.sh -n 'NEW-NAMESPACE-NAME' -c '(azprod|cadev|caprod|lab|prod)'

        -n: Namespace name to create, naming standards as project-environment
        -c: Cluster/Context to place the new namespace
```

THINGS YOU MUST DO FIRST: https://confluence.medimpact.com/display/ITINF/create-namespace+script

EXAMPLES:
```
    ./create-namespace.sh -n 'hotproject-lab' -c 'lab'
```


	***Create the namespace folder 'k8s-yamls/live/lab/namespaces/hotproject-lab' and 
	   related 1/2/3 files from template files in '[THIS DIRECTORY]/ns-templates/example-dev/'***

```
    ./create-namespace.sh -n 'devtest-dev' -c 'cadev'
```


	***Create the namespace folder 'k8s-yamls/live/cadev/namespaces/devtest-dev' and 
	   related 1/2/3 files from template files in '[THIS DIRECTORY]/ns-templates/example-dev/'.***

```
    ./create-namespace.sh -n 'projectname-prod' -c 'azprod'
```


	***Create the namespace folder 'k8s-yamls/live/azprod/namespaces/projectname-prod' and 
	   related 1/2/3 files from template files in '[THIS DIRECTORY]/ns-templates/example-prod/'.***

```
    ./create-namespace.sh -n 'name-e2e' -c 'caprod'
```


	***Create the namespace folder 'k8s-yamls/live/caprod/namespaces/name-e2e' and 
	   related 1/2/3 files from template files in '[THIS DIRECTORY]/ns-templates/example-uat/'.***

TODO:
	I would like to symlink the template files to the actual locations in the 'live namespaces/example-ENV' directories.
