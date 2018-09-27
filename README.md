# puppet_lookup task

#### Table of Contents

1. [Description](#description)
2. [Requirements](#requirements)
3. [Usage - Basic](#usage)
4. [Reference - Parameters](#reference)
5. [Limitations - Parameters Not Implemented](#limitations)
6. [Getting Help - With Tasks](#getting-help)

## Description

This module provides the `puppet_lookup` task.

This task allows you to run `puppet lookup` via the Console or the command line.

## Requirements

This module is compatible with Puppet Enterprise.

## Usage

Use the `puppet task run` command, specifying the nodes and the key you want to retrieve:

```
puppet task run puppet_lookup --nodes master.example.com key=test
```

Note that the `--nodes` parameter is limited to masters and compile masters.

For example, on the command line, run:

```
[root@pe-agent ~]# puppet task run puppet_lookup --nodes $(puppet config print server) key=puppet_enterprise::profile::master::java_args
Starting job ...
Note: The task will run only on permitted nodes.
New job ID: 1
Nodes: 1

Started on master.example.com ...
Finished on node master.example.com
  status : success
  command : puppet lookup puppet_enterprise::profile::master::java_args --node master.example.com --environment production --merge first --render-as json
  results :
    Xms : 3072m
    Xmx : 3072m

Job completed. 1/1 nodes succeeded.
Duration: 2 sec
```

## Reference

To view the available parameters for this task, on the command line, run:

```
puppet task show puppet_lookup
```

## Limitations

The following `puppet lookup` command parameters are not implemented:

1. `--default`
1. `--explain-options`
1. `--facts`
1. `--knock-out-prefix`
1. `--merge-hash-arrays`
1. `--sort-merged-arrays`
1. `--type`

## Getting Help

To show help for tasks, run `puppet task run --help`
