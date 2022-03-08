# DevOpsLab3-Kafka

## Set Kafka (Stream monitoring system) in one single-node installation (with or without ELK)

This example of Kafka implementation must not be used in a production environment as it is not securely configured.
The purpose of this lab is shown the concepts of Stream, Topic, Producer and Consumer in a Kafka arquitecture and how it is used to manage streams in front of an ELK stack arquitecture.

Project structure:

```ascii
.
└── docker-compose.yaml  (kafka + Stack ELK)
└── docker-compose_only_kafka.yaml
└── README.md
```

[_docker-compose-only-kafka.yml_](docker-compose-only-kafka.yml)

```yml
services:
  zookeeper:
    image: zookeeper:latest
    ...
  kafka:
    image: bitnami/kafka:latest
    ...
```

[_docker-compose.yml_](docker-compose.yml)

```yml
services:
  zookeeper:
    image: zookeeper:latest
    ...
  kafka:
    image: bitnami/kafka:latest
    ...
  elasticsearch:
    image: elasticsearch:7.17.1
    ...
  logstash:
    image: logstash:7.17.1
    ...
  kibana:
    image: kibana:7.17.1
    ...
  filebeat:
    image: elastic/filebeat:7.17.1
    ...
```

Alternatively, you could use the images in confluentic/cp-kakfa or in wurstmeister/zookeeper

## Deploy with docker-compose

When using only the kafka installation

```bash
$ docker-compose -f docker-compose-only-kafka.yml up -d
Creating network "kafka" with driver "bridge"
Creating zookeeper ... done
Creating kafka ... done
$
```

or when using with the full Stack ELK integration

```bash
$ docker-compose up -d
Creating network "kafka" with driver "bridge"
Creating zookeeper ... done
Creating kafka ... done
Creating elasticsearch ... done
Creating logstash ... done
Creating kibana ... done
Creating filebeat ... done
$
```

## Expected result

If everything is OK, you must see two containers running and the port mapping as displayed below (notice container ID could be different):

```bash
$ docker ps
CONTAINER ID        IMAGE                 COMMAND                  CREATED             STATUS                    PORTS                                                                                            NAMES
345a3e0f0b5b        zookeeper:latest      "/usr/local/bin/dumb…"   11 seconds ago      Up 2 seconds             0.0.0.0:2181->2181/tcp                                                                           zoo
fd3f0b35b448        kafka:latest          "/usr/local/bin/dumb…"   11 seconds ago      Up 2 seconds             0.0.0.0:9092->9092/tcp                                                                           broker
$
```

or if with full Stack ELK integration, four aditional containers will be shown

```bash
$ docker ps
CONTAINER ID  IMAGE                 COMMAND                 CREATED         STATUS                 PORTS                                                NAMES
345a3e0f0b5b  zookeeper:latest       "/usr/local/bin/dumb…"  11 seconds ago  Up 2 seconds           0.0.0.0:2181->2181/tcp                               zoo
fd3f0b35b448  kafka:latest           "/usr/local/bin/dumb…"  11 seconds ago  Up 2 seconds           0.0.0.0:9092->9092/tcp                               broker
45e9b302d0f0  elasticsearch:7.17.1   "/tini -- /usr/local…"  12 seconds ago  Up 2 seconds (healthy) 0.0.0.0:47321->9200/tcp, 0.0.0.0:49156->9300/tcp     els
164f0553ed54  logstash:7.17.1        "/usr/local/bin/dock…"  13 seconds ago  Up 1 seconds           0.0.0.0:5000->5000/tcp, 0.0.0.0:5044->5044/tcp, 0.0.0.0:9600->9600/tcp, 0.0.0.0:5000->5000/udp   logstash
fd3f0b35b448  kibana:7.17.1          "/usr/local/bin/dumb…"  14 seconds ago  Up 2 seconds           0.0.0.0:5601->5601/tcp                               kibana
e2f3bacd4f46  filebeat:7.17.1        "/usr/local/bin/dock…" 12 seconds ago  Up 1 seconds           0.0.0.0:                                             filebeat
$ 
```

Then, you can launch each application using the below links in your local web browser:

* Kafka: [`http://localhost:9092`](http://localhost:9092)
* For the ELK stack, please see how to verify in [https://github.com/JuanLuisGozaloFdez/DevOpsLab2-ELK](https://github.com/JuanLuisGozaloFdez/DevOpsLab2-ELK)

Stop and remove the containers and volumes

```bash
$ docker-compose down -v
$
```

## First part of the Lab: To test the standalone Kafka implementation

Remember that Kafka is a stream processing system (a broker) between Producers and Consumers.

The best way to test the system is open TWO terminals in your docker KAFKA container: one will play the role of Producer and the other for Consumer.

To open the terminals, you need to enter inside the container (using *'docker ps'* you can see the container-id and then execute a *'docker -i -t your-container-id /bin/bash'* command for opening each terminals)

### The Producer

Now, in the Producer Terminal, a **TOPIC** (let's named *test_topic*) must be created linked to the Zookeeper process

```bash
$> kafka-topics --create --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1 --topic testtopic
Created topic testtopic
$>
```

Then, start the process that will publish datastream to the Kafka Broker from the standard input (keybaord) we are going to use for testing

```bash
$> kafka-console-producer --broker-list localhost:9092 --topic testtopic
>
```

Also, the process can be injected with data comming from an external process, let's simulate with a loop

```bash
$> for x in {1..100}; do echo $x; done | /bin/kafka-console-producer --broker-list localhost:9092 --topic testtopic 
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
$>
```

### The Consumer

Now, in the Consumer Terminal, the Consumer process must be created linked to the Kafka Broker (let's set a timeout also for testing.

```bash
$> /bin/kafka-console-consumer --bootstrap-server localhost:9092 --from-beginning --topic testtopic --timeout-ms 10000
>
```

Now, if everything is setup properly, all text that is typed in the Producer Terminal will appear in the Consumer Terminal and, if you have used the loop, all numbers will appear in the screen.
If nothing is received, then the process will be finished with a message saying "Error processing message, terminating consumer process"

Enjoy it!

## Second part of the Lab: Test Kafka with ELK stack

To verify Kafka it is required to start the Lab with the full docker-compose.yml file to launch the containers and then you must make a few changes in the configuration files as it is shown in the following steps:

### Pre-step: Launching the new docker-compose set

Use this command:

```bash
$ docker-compose up -d
... done
$
```

### Pre-step: Set up Filebeat to get info from system (System => Filebeat)

First thing is to make Filebeat to collect some info from system to simulate a Stream incoming log.

```bash
$ docker exec –it filebeat /bin/bash
$> chown root filebeat.yml
$> chmod go-w filebeat.yml
$> ./filebeat –E "filebeat.config.modules.path=./modules.d/*.yml" modules enable system
Enabled system module
$> ./filebeat setup --pipelines --modules system
Loaded Ingest pipelines
$> ./filebeat setup –e
....
$> 
```

### Step 1: Set Filebeat as a Kafka producer (Filebeat => Kafka)

The current filebeat.yml file must be modified to comment the elasticsearc output and to define the new kafka output. Then, the filebeat container must be restarted.

```ascii
# output.elasticsearch:
#hosts: ["localhost:9200"]
output.kafka:
  hosts: ["broker:9092"]
  topic: "devopslab"
  codec.json:
    pretty: false"
```

### Step 2: Set up Logstash as a Kafka consumer (Kafka <= Logstash)

To do this, a new configuration file must be established for this consumer

(for convenience purpose, the file is already created in the logstash directory of this repository):
```ascii
input {
  kafka {
    bootstrap_servers => 'localhost:9092'
    topics => ["devopslab"]
    codec => json {}
  }
}
filter{}
output {
  elasticsearch {
        index  => "devopslab-%{+YYYY.MM.dd}"
        hosts => ["localhost:9200"]
        sniffing => false
    }
  stdout { codec => rubydebug}
}
```

### Step 3: Verify in ElasticSearch (as Logstash is already set to send data to Elastic) (Logstash => Elastic)

```bash
$ curl "localhost:9200/_cat/indices?v=true"
an index with name devopslab-YYYY.MM.DD must be shown in the list of indexes
$ curl -X GET "localhost:9200/<name-of-the-devopslab-index>/_search?pretty" (please substitute index name as appropiate)
the documents
$
```
