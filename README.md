# Azouk Libraries #

Azouk libraries contain:
  * Multiplexer
  * distributed Logging component


## Multiplexer ##

Multiplexer is short for Azouk Enterprise Message Bus. It consists of
  * server that acts as a service broker,
  * client library,
  * abstract classes for writing Multiplexer-based backends and services
and provides fast, robust, fault-tolerant, asynchronous communication in distributed environment.

Both client library and backend classes are available in
  * C++
  * Python
  * Java (for Java client & server contact the project owners - they're ready but not yet released)

The communication format leverages [Google Protocol Buffers](http://code.google.com/apis/protocolbuffers/). For gluing C++ and Python it uses [Boost.Python](http://www.boost.org/doc/libs/1_37_0/libs/python/doc/index.html). Asynchronous communication is handled with [Asio](http://tenermerx.com/Asio/).

## Azouk Logging ##

Logging library is a rich-format logging based on Google Protocol Buffers.
It consists of
  * client library that formats and renders log entries on both stderr and binary logging stream suitable for machine parsing;
    * fast
    * no overhead when log is not written
    * for both
      * C++
      * Python
  * log streamer that packs log entries from binary logging stream and sends them using Multiplexer
  * log collector that holds the log entries in memory and allows to search them.

C++ logging API leverages [Boost.Preprocessor meta programming library](http://www.boost.org/doc/libs/1_37_0/libs/preprocessor/doc/index.html). For gluing C++ and Python it uses [Boost.Python](http://www.boost.org/doc/libs/1_37_0/libs/python/doc/index.html).

Altough it's designed for general purpose, it serves well, and so we use it, to monitor and log events in a [django](http://www.djangoproject.com/)-powered app.

# Authors #

Multiplexer and Azouk Logging were end-to-end designed and implemented by Piotr Findeisen as a part of his work for Azouk. Krzysztof Kulewski participated in the architecture overview.

Java client, Java server were designed and implemented ground up by Kasia Findeisen and Piotr Findeisen. Pure-Python client (a work in progress) is modelled after Java version and developed by Piotr Findeisen.

# Credits #

Credits go to Azouk Network Ltd. for contributing the libraries to the Open Source community.