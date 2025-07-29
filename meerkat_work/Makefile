IC_NAME      ?= chiffre
INPUT_IMAGE  ?= chiffre_logo.png
INPUT_GDS    ?= ../klayout/croc_chip.gds
ARTISTIC_DIR ?= $(shell pwd)/artistic

PYTHON ?= oseda ./.venv/bin/python3

all: $(IC_NAME)_chip.gds.gz render

$(IC_NAME)_tm.gds: $(INPUT_GDS)
	$(PYTHON) $(ARTISTIC_DIR)/scripts/meerkat_interface.py \
	    -i $(INPUT_GDS) \
	    -m $(IC_NAME)_tm.gds.gz \
	    -g $(IC_NAME)_logo.gds \
	    -o $(IC_NAME)_chip.gds.gz \
	    -w . \
	    -l 134
	klayout -zz -rm $(ARTISTIC_DIR)/scripts/export_top_metal.py
	gzip -d $(IC_NAME)_tm.gds.gz

$(IC_NAME)_logo.gds: $(IC_NAME)_tm.gds
	convert $(INPUT_IMAGE) -remap pattern:gray50 mono_$(INPUT_IMAGE)
	$(PYTHON) $(ARTISTIC_DIR)/scripts/meerkat.py \
		-m "161,162,150,149" \
	    -i mono_$(INPUT_IMAGE) \
	    -g $(IC_NAME)_tm.gds \
		-l 134 \
		-n $(IC_NAME) \
		-s $(IC_NAME)_logo.svg \
		-o $(IC_NAME)_logo.gds

$(IC_NAME)_chip.gds.gz: $(IC_NAME)_logo.gds
	klayout -zz -rm $(ARTISTIC_DIR)/scripts/merge_logo.py

render: $(IC_NAME)_chip.gds.gz
	mkdir -p /dev/shm/renderics
	cp $(IC_NAME)_chip.gds.gz /dev/shm/renderics/$(IC_NAME)_chip.gds.gz
	cd $(ARTISTIC_DIR) && $(MAKE) analyze CFG_FILE=../$(IC_NAME).json
	cd $(ARTISTIC_DIR) && $(MAKE) gen_raw CFG_FILE=../$(IC_NAME).json
	cd $(ARTISTIC_DIR) && $(MAKE) gen_pdfs CFG_FILE=../$(IC_NAME).json -j

clean:
	rm -f $(IC_NAME)_tm.gds $(IC_NAME)_logo.gds $(IC_NAME)_chip.gds.gz
	rm -f meerkat_design.py
	rm -f $(IC_NAME)_logo.svg