# ASAP7 VLSI flow for CUHK HPC server clusters

## Steps

* Clone this repo.
```bash
$ git clone https://github.com/baichen318/chipyard.git
$ cd chipyard
$ git checkout boom
```

* Initialize the Chipyard environment
This step may require 3rd party tools, you may install them by yourself manually.
```bash
$ ./scripts/init-submodules-no-riscv-tools.sh
```

* Building the toolchain
```bash
$ ./scripts/build-toolchains.sh riscv-tools # for a normal risc-v toolchain
```

* EDA tools plugins requirement

Email to `hammer-plugins-access@lists.berkeley.edu` with a request for plugins.
1. hammer-cadence-plugins

2. hammer-mentor-plugins

3. hammer-synopsys-plugins

* Initialize the VLSI environment
```bash
$ ./scripts/init-vlsi.sh asap7
```

* Initalize the Hammer environment
```bash
$ cd vlsi
$ export HAMMER_HOME=$PWD/hammer
$ source $HAMMER_HOME/sourceme.sh
```

* Configure EDA tools environment for Hammer

Configure files including
1. vlsi/env.yml

2. vlsi/example.yml

3. hammer-cadence-plugins/synthesis/genus/defaults.yml

4. hammer-cadence-plugins/par/innovus/defaults.yml

5. hammer-synopsys-plugins/sim/vcs/defaults.yml

* VLSI for compilation from Chisel to Verilog
```bash
$ make build \
  MACROCOMPILER_MODE='-l /path/to/chipyard/vlsi/hammer/src/hammer-vlsi/technology/asap7/sram-cache.json -hir chipyard.TestHarness.SmallBoomConfig.hir' CONFIG=SmallBoomConfig
```

* VLSI for synthesis using Genus
```bash
$ make syn \
  MACROCOMPILER_MODE='-l /path/to/chipyard/vlsi/hammer/src/hammer-vlsi/technology/asap7/sram-cache.json -hir chipyard.TestHarness.SmallBoomConfig.hir' CONFIG=SmallBoomConfig
```

* VLSI for place-and-route using Innovus
```bash
$ make par \
  MACROCOMPILER_MODE='-l /path/to/chipyard/vlsi/hammer/src/hammer-vlsi/technology/asap7/sram-cache.json -hir chipyard.TestHarness.SmallBoomConfig.hir' CONFIG=SmallBoomConfig
```

* Replace SRAM with self-modifiled SRAMs
```bash
$ cp sram_behav_models.v generated_src/chipyard.TestHarness.SmallBoomConfig/
```

* VLSI for simulation using VCS

Configurate vcs.sh
```bash
$ make sim \
  MACROCOMPILER_MODE='-l /path/to/chipyard/vlsi/hammer/src/hammer-vlsi/technology/asap7/sram-cache.json -hir chipyard.TestHarness.SmallBoomConfig.hir' CONFIG=SmallBoomConfig \
  BINARY=/path/to/benchmark.riscv
$ bash vcs.sh
```

