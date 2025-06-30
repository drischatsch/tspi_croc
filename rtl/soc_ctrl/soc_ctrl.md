## Summary

| Name                                               | Offset   |   Length | Description                                            |
|:---------------------------------------------------|:---------|---------:|:-------------------------------------------------------|
| soc_ctrl.[`bootaddr`](#bootaddr)                   | 0x0      |        4 | Core Boot Address                                      |
| soc_ctrl.[`fetchen`](#fetchen)                     | 0x4      |        4 | Core Fetch Enable                                      |
| soc_ctrl.[`corestatus`](#corestatus)               | 0x8      |        4 | Core Return Status (return value, EOC)                 |
| soc_ctrl.[`bootmode`](#bootmode)                   | 0xc      |        4 | Core Boot Mode                                         |
| soc_ctrl.[`sram_dly`](#sram_dly)                   | 0x10     |        4 | SRAM A_DLY value                                       |
| soc_ctrl.[`restart_counter`](#restart_counter)     | 0x14     |        4 | Bootrom restarts counter                               |
| soc_ctrl.[`bootaddr_after`](#bootaddr_after)       | 0x18     |        4 | Core Boot Address After Bootrom                        |
| soc_ctrl.[`bootaddr_after_sd`](#bootaddr_after_sd) | 0x1c     |        4 | Core Boot Address After Bootrom if SD Card is attached |

## bootaddr
Core Boot Address
- Offset: `0x0`
- Reset default: `0x300d000`
- Reset mask: `0xffffffff`

### Fields

```wavejson
{"reg": [{"name": "bootaddr", "bits": 32, "attr": ["rw"], "rotate": 0}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80}}
```

|  Bits  |  Type  |   Reset   | Name     | Description   |
|:------:|:------:|:---------:|:---------|:--------------|
|  31:0  |   rw   | 0x300d000 | bootaddr | Boot Address  |

## fetchen
Core Fetch Enable
- Offset: `0x4`
- Reset default: `0x0`
- Reset mask: `0x1`

### Fields

```wavejson
{"reg": [{"name": "fetchen", "bits": 1, "attr": ["rw"], "rotate": -90}, {"bits": 31}], "config": {"lanes": 1, "fontsize": 10, "vspace": 90}}
```

|  Bits  |  Type  |  Reset  | Name    | Description   |
|:------:|:------:|:-------:|:--------|:--------------|
|  31:1  |        |         |         | Reserved      |
|   0    |   rw   |   0x0   | fetchen | Fetch Enable  |

## corestatus
Core Return Status (return value, EOC)
- Offset: `0x8`
- Reset default: `0x0`
- Reset mask: `0xffffffff`

### Fields

```wavejson
{"reg": [{"name": "core_status", "bits": 32, "attr": ["rw"], "rotate": 0}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80}}
```

|  Bits  |  Type  |  Reset  | Name        | Description                                             |
|:------:|:------:|:-------:|:------------|:--------------------------------------------------------|
|  31:0  |   rw   |   0x0   | core_status | Core Return Status (EOC(bit[31]) and status(bit[30:0])) |

## bootmode
Core Boot Mode
- Offset: `0xc`
- Reset default: `0x0`
- Reset mask: `0x1`

### Fields

```wavejson
{"reg": [{"name": "bootmode", "bits": 1, "attr": ["rw"], "rotate": -90}, {"bits": 31}], "config": {"lanes": 1, "fontsize": 10, "vspace": 100}}
```

|  Bits  |  Type  |  Reset  | Name     | Description   |
|:------:|:------:|:-------:|:---------|:--------------|
|  31:1  |        |         |          | Reserved      |
|   0    |   rw   |   0x0   | bootmode | Boot Mode     |

## sram_dly
SRAM A_DLY value
- Offset: `0x10`
- Reset default: `0x1`
- Reset mask: `0x1`

### Fields

```wavejson
{"reg": [{"name": "sram_dly", "bits": 1, "attr": ["rw"], "rotate": -90}, {"bits": 31}], "config": {"lanes": 1, "fontsize": 10, "vspace": 100}}
```

|  Bits  |  Type  |  Reset  | Name     | Description                                                       |
|:------:|:------:|:-------:|:---------|:------------------------------------------------------------------|
|  31:1  |        |         |          | Reserved                                                          |
|   0    |   rw   |   0x1   | sram_dly | Controls the A_DLY pin of the SRAMs (configured internal timings) |

## restart_counter
Bootrom restarts counter
- Offset: `0x14`
- Reset default: `0x0`
- Reset mask: `0xffffffff`

### Fields

```wavejson
{"reg": [{"name": "restart_counter", "bits": 32, "attr": ["rw"], "rotate": 0}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80}}
```

|  Bits  |  Type  |  Reset  | Name            | Description     |
|:------:|:------:|:-------:|:----------------|:----------------|
|  31:0  |   rw   |   0x0   | restart_counter | Restart Counter |

## bootaddr_after
Core Boot Address After Bootrom
- Offset: `0x18`
- Reset default: `0x10000000`
- Reset mask: `0xffffffff`

### Fields

```wavejson
{"reg": [{"name": "bootaddr_after", "bits": 32, "attr": ["rw"], "rotate": 0}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80}}
```

|  Bits  |  Type  |   Reset    | Name           | Description                |
|:------:|:------:|:----------:|:---------------|:---------------------------|
|  31:0  |   rw   | 0x10000000 | bootaddr_after | Boot Address After Bootrom |

## bootaddr_after_sd
Core Boot Address After Bootrom if SD Card is attached
- Offset: `0x1c`
- Reset default: `0x60000000`
- Reset mask: `0xffffffff`

### Fields

```wavejson
{"reg": [{"name": "bootaddr_after_sd", "bits": 32, "attr": ["rw"], "rotate": 0}], "config": {"lanes": 1, "fontsize": 10, "vspace": 80}}
```

|  Bits  |  Type  |   Reset    | Name              | Description                                       |
|:------:|:------:|:----------:|:------------------|:--------------------------------------------------|
|  31:0  |   rw   | 0x60000000 | bootaddr_after_sd | Boot Address After Bootrom if SD Card is attached |

