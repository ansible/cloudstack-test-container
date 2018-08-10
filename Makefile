build:
	docker build --no-cache -t cloudstack-sim .

clean:
	docker rm -f cloudstack-sim

run:
	docker run --name cloudstack-sim -d -p 8080:8080 -p 8888:8888 cloudstack-sim

shell:
	docker exec -it cloudstack-sim /bin/bash

logs:
	docker logs -f cloudstack-sim
