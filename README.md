# puppet_lookup task

#### Table of Contents

1. [Description](#description)
2. [Requirements](#requirements)
3. [Usage - Basic](#usage)
4. [Reference - Parameters](#reference)
5. [Limitations - Parameters Not Implemented](#limitations)
6. [Getting Help - With Tasks](#getting-help)

## Description

This module provides the puppet_lookup task, which allows you to run `puppet lookup` via the Console or the command line.

## Requirements

This module is compatible with Puppet Enterprise.

## Usage

To run a puppet_lookup task, use the `task` command, specifying the key you want to retrieve.

For example, on the command line, run:

```
puppet task run puppet_lookup --nodes $(puppet config print server) key=xxx
```

## Reference

To view the available parameters, on the command line, run:

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
