build:
	podman build -t cloudstack-sim .

build-no-cache:
	podman build --no-cache -t cloudstack-sim .

clean:
	podman rm -f cloudstack-sim

run:
	podman run --name cloudstack-sim -d -p 8080:8080 -p 8888:8888 cloudstack-sim

shell:
	podman exec -it cloudstack-sim /bin/bash

logs:
	podman logs -f cloudstack-sim
