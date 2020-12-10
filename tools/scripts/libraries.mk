# File where libraries are handled

#	IIO
ifeq (y,$(strip $(TINYIIOD)))

TINYIIOD_DIR = $(NO-OS)/libraries/iio/libtinyiiod

include ../../tools/scripts/iio_srcs.mk

CFLAGS += -DTINYIIOD_VERSION_MAJOR=0	 \
	   -DTINYIIOD_VERSION_MINOR=1		 \
	   -DTINYIIOD_VERSION_GIT=0x$(shell git -C $(TINYIIOD_DIR)/ \
	   				rev-parse --short HEAD) \
	   -DIIOD_BUFFER_SIZE=0x1000		 \
	   -D_USE_STD_INT_TYPES
CFLAGS += -DIIO_SUPPORT

ifeq ($(wildcard $(TINYIIOD_DIR)/.git),)
INIT_SUBMODULES += git submodule update --init $(TINYIIOD_DIR) && 
endif

endif

#	MBEDTLS
ifneq ($(if $(findstring mbedtls, $(LIBRARIES)), 1),)
# Generic part
MBEDTLS_DIR					= $(NO-OS)/libraries/mbedtls
MBEDTLS_LIB_DIR				= $(MBEDTLS_DIR)/library
MBEDTLS_LIB_NAMES			= libmbedtls.a libmbedx509.a libmbedcrypto.a
MBEDTLS_LIBS				= $(addprefix $(MBEDTLS_LIB_DIR)/,$(MBEDTLS_LIB_NAMES))
EXTRA_LIBS					+= $(MBEDTLS_LIBS)
EXTRA_LIBS_PATHS			+= $(MBEDTLS_LIB_DIR)
EXTRA_INC_PATHS		+= $(MBEDTLS_DIR)/include
ifeq ($(wildcard $(MBEDTLS_DIR)/.git),)
INIT_SUBMODULES				+= git submodule update --init $(MBEDTLS_DIR) &&
endif

#Rules
MBED_TLS_CONFIG_FILE = $(NO-OS)/network/noos_mbedtls_config.h
CLEAN_MBEDTLS	= $(call remove_fun,$(MBEDTLS_LIB_DIR)/*.o $(MBEDTLS_LIBS))
$(MBEDTLS_LIB_DIR)/libmbedcrypto.a: $(MBED_TLS_CONFIG_FILE)
	-$(CLEAN_MBEDTLS)
	$(MAKE) -C $(MBEDTLS_LIB_DIR)
$(MBEDTLS_LIB_DIR)/libmbedx509.a: $(MBEDTLS_LIB_DIR)/libmbedcrypto.a
$(MBEDTLS_LIB_DIR)/libmbedtls.a: $(MBEDTLS_LIB_DIR)/libmbedx509.a

# Custom settings
CFLAGS 		+= -I$(dir $(MBED_TLS_CONFIG_FILE)) \
			-DMBEDTLS_CONFIG_FILE=\"$(notdir $(MBED_TLS_CONFIG_FILE))\"
else
DISABLE_SECURE_SOCKET ?= y
endif

#	FATFS
ifneq ($(if $(findstring fatfs, $(LIBRARIES)), 1),)
# Generic part
FATFS_DIR					= $(NO-OS)/libraries/fatfs
FATFS_LIB					= $(FATFS_DIR)/libfatfs.a
EXTRA_LIBS					+= $(FATFS_LIB)
EXTRA_LIBS_PATHS			+= $(FATFS_DIR)
EXTRA_INC_PATHS	+= $(FATFS_DIR)/source

# Rules
CLEAN_FATFS	= $(MAKE) -C $(NO-OS)/libraries/fatfs clean
$(FATFS_LIB):
	$(MAKE) -C $(FATFS_DIR)

# Custom settings
CFLAGS		+= -I$(DRIVERS)/sd-card -I$(INCLUDE)

endif

#	MQTT
ifneq ($(if $(findstring mqtt, $(LIBRARIES)), 1),)
# Generic part
MQTT_DIR					= $(NO-OS)/libraries/mqtt
MQTT_LIB					= $(MQTT_DIR)/libmqtt.a
EXTRA_LIBS					+= $(MQTT_LIB)
EXTRA_LIBS_PATHS			+= $(MQTT_DIR)
EXTRA_INC_PATHS		+= $(MQTT_DIR)

CLEAN_MQTT	= $(MAKE) -C $(MQTT_DIR) clean
$(MQTT_LIB):
	$(MAKE) -C $(MQTT_DIR)

endif

LIB_TARGETS			+= $(MBEDTLS_TARGETS) $(FATFS_LIB) $(MQTT_LIB)
EXTRA_LIBS_NAMES	= $(subst lib,,$(basename $(notdir $(EXTRA_LIBS))))
LIB_FLAGS			+= $(addprefix -l,$(EXTRA_LIBS_NAMES))
LIB_PATHS			+= $(addprefix -L,$(EXTRA_LIBS_PATHS))


#TODO remove afeter changes are done
#Convert variable to linux.mk naming
ifneq (aducm3029,$(strip $(PLATFORM)))
INC_PATHS += $(EXTRA_INC_PATHS)
LIBS += $(LIB_FLAGS)
endif

# Build project Release Configuration
PHONY := libs
libs: $(LIB_TARGETS)

PHONY += clean_libs
clean_libs:
	-$(CLEAN_MBEDTLS)
	-$(CLEAN_FATFS)
	-$(CLEAN_MQTT)
	-$(CLEAN_IIO)
