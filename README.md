# DevOpsLab3: Kafka with ELK (WORK IN PROGRESS. NOT COMPLETED)

## Set Kafka (Stream monitoring system) in one single-node installation with ELK

### Setting initial requirements

This DevOps Lab will require a virtual machine with 4GB memory and, at least, 10GB space to be executed.
That machine will be Ubuntu 18.04 (or similar Linux) with GIT, Docker and DockerCompose already installed.

### Project structure

```ascii
.
└── docker-compose.yml
└── README.md
```

[_docker-compose.yml_](docker-compose.yml)

```yaml
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:latest
  kafka:
    image: confluentinc/cp-server:latest
    ...
```

Alternatively, you could use the images in bitnami/kakfa or in wurstmeister/zookeeper

### Deploy with docker-compose

```bash
$ docker-compose up -d
Creating network "kafka" with driver "bridge"
Creating zookeeper ... done
Creating kafka_broker ... done
$
```

### Expected result

If everything is OK, you must see three containers running and the port mapping as displayed below (notice container ID could be different):

```bash
$ docker ps
CONTAINER ID        IMAGE                 COMMAND                  CREATED             STATUS                    PORTS                                                                                            NAMES
345a3e0f0b5b        zookeeper:6.0.1      "/usr/local/bin/dumb…"   11 seconds ago      Up 2 seconds             0.0.0.0:2181->2181/tcp                                                                           kib
fd3f0b35b448        kafka:6.0.1          "/usr/local/bin/dumb…"   11 seconds ago      Up 2 seconds             0.0.0.0:9092->9092/tcp                                                                           kib
$
```

Then, you can launch each application using the below links in your local web browser:

* Kafka: [`http://localhost:9092`](http://localhost:9092)

### Stop and remove the containers

```bash
$ docker-compose down
$
```

## How to test this Kafka implementation

Remember that Kafka is a stream processing system (a broker) between Producers and Consumers.

The best way to test the system is open two terminals in your docker container: one will play the role of Producer and the other for Consumer.

To open the terminals, you need to enter inside the container (using *'docker ps'* you can see the container-id)

```bash
$docker -i -t <container-id> /bin/bash (this is the command for opening each terminals)
$>
```

### The Producer

Now, in the Producer Terminal, a **TOPIC** (let's named *test_topic*) must be created linked to the Zookeeper process

```bash
$> /bin/kafka-topics --create --zookeeper zookeeper:2181 --partitions 1 --replication-factor 1 --topic testtopic
$>
```

Then, start the process that will publish datastream to the Kafka Broker from the standard input (keybaord) we are going to use for testing

```bash
$> /bin/kafka-console-producer --broker-list localhost:9092 --topic testtopic
$>
```

### The Consumer

Now, in the Consumer Terminal, the Consumer process must be created linked to the Kafka Broker

```bash
$> /bin/kafka-console-consumer --bootstrap-server localhost:9092 --topic testtopic
$>
```

Now, if everything is setup properly, all text that is typed in the Producer Terminal will appear in the Consumer Terminal
