# Docker Commands Reference

## Images

### List Images
```bash
# List all images
docker images

# List all images (alternative)
docker image ls

# List all images including intermediate images
docker images -a
```

### Save Image to TAR File
```bash
# Save a single image
docker save nginx:latest > nginx.tar

# Save a single image (alternative syntax)
docker save -o nginx.tar nginx:latest

# Save multiple images
docker save -o images.tar nginx:latest alpine:latest
```

### Load Image from TAR File
```bash
# Load image from tar file
docker load < nginx.tar

# Load image from tar file (alternative syntax)
docker load -i nginx.tar
```

## Containers

### List Containers
```bash
# List running containers
docker ps

# List all containers (running and stopped)
docker ps -a

# List containers (alternative)
docker container ls

# List all containers (alternative)
docker container ls -a
```
