# dlist 0.1.1

### Swift-based macOS CLI tool for listing connected MCUs

## Usage

Run `dlist` to get a list of connected MCUs, eg. Raspberry Pi Pico boards.

If only one board is connected, its path within the `/dev` directory will be provided. This is issued to `STDOUT` so that it can be passed into another command. For example:

```shell
minicom -D $(dlist) -b 9600
```

or calling the `dlist` itself:

```shell
dlist
/dev/cu.PL2303G-USBtoUART10
```

If multiple MCUs are connected, `dlist` will return a numerical list:

```shell
1. cu.PL2303G-USBtoUART10
2. cu.USB-MODEM-001
```

This list is issued to `STDERR`, so it’s printed in a terminal, but will typically not be passed to another program. This allows you to select which item you wish to use. For example:

```shell
minicom -D $(dlist 2) -b 9600
```

Including a numerical argument causes `dlist` to issue the specified device (by index in the list) to subsequent commands through `STDOUT`.

**Note** If there is only one MCU connected and you still specify a value that is not `1`, this will generate a warning on `STERR` but will still issue the device 


Copyright © 2025, Tony Smith (@smittytone)
