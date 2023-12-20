# ccKVS
An RDMA skew-aware key-value store, which implements the [Scale-Out ccNUMA](https://dl.acm.org/citation.cfm?id=3190550 "Scale-Out ccNUMA paper") design, to exploit skew in order to increase performance of data-serving applications.

In particular ccKVS consists of: 
* **Symmetric Caching**: 
a distributed cache architecture which allows requests for the most popular items to be executed on all nodes.
* **Fully distributed strongly consistent protocols**: 
to efficiently handle writes while maintaining consistency of the caches.

We briefly explain these ideas bellow, more details can be found in our Eurosys'18 [paper](https://dl.acm.org/citation.cfm?id=3190550 "Scale-Out ccNUMA paper")  and [slides](https://www.slideshare.net/AntoniosKatsarakis/scaleout-ccnuma-eurosys18 "Scale-Out ccNUMA slides").

## Symmetric Caching
* Every node contains an identical cache storing the hottest keys in the cluster
* Uniformly spread the requests to all of the nodes
  * Requests for the hottests objects (majority) will be served on all nodes locally
  * Requests missing the cache will either be served through the local portion of KVS or more likely through the RDMA network
* **Benefits**:
  * **Load balances** and **filters the skew**
  * **Throughput scales** with the number of servers
  * **Less network b/w** due to requests served by caches

## Fully distributed strongly consistent protocols
Protocols are implemented efficiently on top of RDMA, offering:
* **Fully distributed writes** 
    * Writes (for any key) are directly executed on any node, as oposed using a primary node --> hot-spot
    * Single global writes ordering is guaranteed via per-key logical (lamport) clocks
      * Reduces network RTTs
      * Avoids hot-spots and evenly spread the write propagation costs to all nodes
* Two per-key **strongly consistent** flavours:
    * **Linearizability** (Lin - strongest --> 2 network rtts): 1) Broadcast Invalidations* 2) Broadcast Updates*
    * **Sequential Consistency** (SC --> 1rtt): 1) Broadcast Updates* 
    * *along with logical (Lamport) clocks

## Testbed

* Cloudlab machine c6220 with 9 cluster setup.
* Ubuntu 18.04

## How to run

* To setup the whole cluster, in one of the machines run:

```sh
$ cd bin
$ ./deploy.sh -s
```

* Adjust [run-ccKVS.sh](https://github.com/aagontuk/ccKVS/blob/master/src/ccKVS/run-ccKVS.sh) with correct IP addresses for the nodes. Set `MEMCACHED_IP` with one of the nodes IP.

* Build ccKVS in common shared directory:

```sh
cd /proj/sandstorm-PG0/ashfaq/ccKVS/src
make
```

* Generate trace file with [trace-generator](https://github.com/akatsarakis/trace-generator).

* Use [trace-splitter](https://github.com/aagontuk/ccKVS/blob/master/traces/trace-splitter.py) to split the trace for each client and keep the traces in /proj/sandstorm-PG0/ashfaq/ccKVS/traces/current-splited-traces. Example for 3 machine setup:

```sh
cat trace_w_10000000_k_1000000_c_250000_s_3_r_0.05_a_0.99_i_10.txt | ./trace-splitter.py -s 3 -c 10 -w 10 -k 100000 -C 250000 -o ./current-splited-traces/
```

* Run ccKVS in each node with following command:

```sh
rm -rf ~/ccKVS; cp -r /proj/sandstorm-PG0/ashfaq/ccKVS ~/ccKVS; cd ~/ccKVS/src/ccKVS/; ./run-ccKVS.sh
```

## Acknowledgments
1. ccKVS is based on [HERD/MICA](https://github.com/efficient/rdma_bench/tree/master/herd "HERD repo") design as an underlying KVS, the code of which we have adapted to implement both our underlying KVS and our (symmetric) caches.
2. Similarly for implementing efficient (CRCW) synchronization over seqlocks we have used the [OPTIK](https://github.com/LPD-EPFL/ASCYLIB "OPTIK repo") library.

More details can be found in our Eurosys'18 [paper](https://dl.acm.org/citation.cfm?id=3190550 "Scale-Out ccNUMA paper")  and [slides](https://www.slideshare.net/AntoniosKatsarakis/scaleout-ccnuma-eurosys18 "Scale-Out ccNUMA slides").
