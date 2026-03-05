# New method:
# change this section:
[plugins."io.containerd.grpc.v1.cri".registry]
  config_path = ""   
# to this:
[plugins."io.containerd.grpc.v1.cri".registry]
  config_path = "/etc/containerd/certs.d"     
# then create a directory
mkdir -p /etc/containerd/certs.d/docker-local.artifactory.medimpact.com
# put this file there:
/etc/containerd/certs.d/docker-local.artifactory.medimpact.com/hosts.toml
# with this contents:
[host."https://docker-local-cache-wtd.medimpact.com"]
  capabilities = ["pull", "resolve"]






# Potential registry cleanup steps
1. Scale down registry proxy
2. Run a registry in non-proxy, writable mode
3. Via API delete any images tagged "build"
4. Via API delete the oldest tag using semver sorting unless its the only tag (may need to adjust this. require a base count?)
5. Run the garbage collection function: `registry garbage-collect /etc/docker/registry/config.yml`
6. Restart redis to clear the manifest cache
7. Scale up the registry proxy again

# Possible api cleanup script
```
#!/bin/bash

# Get list of all repositories
repos=$(curl -s https://docker-local-cache-wtd.medimpact.com/v2/_catalog?n=500 | jq -r .repositories[])

for repo in $repos; do
    # Get all tags for each repository
    tags=$(curl -s -X GET https://docker-local-cache-wtd.medimpact.com/v2/$repo/tags/list | jq -r .tags[])

    for tag in $tags; do
        # Convert tag to lowercase and check if it contains "build"
        if [[ ${tag,,} =~ build ]]; then
            # We use -D- to dump headers to stdout, then grep for the Docker-Content-Digest
            digest=$(curl -s -D- -XHEAD -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
                https://docker-local-cache-wtd.medimpact.com/v2/$repo/manifests/$tag \
                | grep 'docker-content-digest:' | cut -d' ' -f2 | tr -d $'\r')

            echo "Deleting image: $repo:$tag"
            echo curl -X DELETE "https://docker-local-cache-wtd.medimpact.com/v2/$repo/manifests/$digest"
            curl -X DELETE "https://docker-local-cache-wtd.medimpact.com/v2/$repo/manifests/$digest"
        fi
    done

    # Skip repos with fewer than 5 tags
    if (( $(wc -w <<< "$tags") < 5 )); then
        continue
    fi

    # Find the semver least tag
    old_tag=$(printf '%s\n' $tags | sort -V | head -n 1)

    # First, get the digest for the oldest tag
    digest=$(curl -s -D- -XHEAD -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
        https://docker-local-cache-wtd.medimpact.com/v2/$repo/manifests/$old_tag \
        | grep 'docker-content-digest:' | cut -d' ' -f2 | tr -d $'\r')

    echo "Deleting image: $repo:$old_tag"

    # Delete the old_tag
    echo curl -X DELETE "https://docker-local-cache-wtd.medimpact.com/v2/$repo/manifests/$digest"
    curl -X DELETE "https://docker-local-cache-wtd.medimpact.com/v2/$repo/manifests/$digest"
done
```


# LEGACY:
# Need to add a section like this to containerd
```
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker-local.artifactory.medimpact.com"]
          endpoint = ["https://docker-local-cache-wtd.medimpact.com"]
```

# Via sed:
```
sed -i '/\[plugins."io.containerd.grpc.v1.cri".registry.mirrors\]/a \
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker-local.artifactory.medimpact.com"] \
          endpoint = ["https://docker-local-cache-wtd.medimpact.com"]' \
        /etc/containerd/config.toml
systemctl restart containerd
```



