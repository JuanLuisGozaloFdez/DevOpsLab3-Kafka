#!/bin/bash
/usr/bin/kafka-console-consumer --bootstrap-server localhost:9092 --from-beginning --timeout-ms 10000 --topic testtopic