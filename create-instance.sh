#!/bin/bash

###############################################################################
#
# create-instance.sh
#
# This script reads necessary variables from class definition and expose them
#   to the other parts of the program.
#
###############################################################################

echo "[INFO] This program requires sudo access to perform its functionalities. Getting sudo access..."
sudo echo "[INFO] Acquired sudo access."

### Start User Configuration
Config_AutoRemove=false
### End User Configuration

### Check dependencies
DEPENDENCIES_LIST="uuidgen"
for i in $DEPENDENCIES_LIST; do
    if [[ $(which $i) == "" ]]; then
        echo "!!! [ERROR] Unsatisfied dependency: '$i'."
        exit 1
    fi
done

### Arguments & constants & important variales
export TARGET_APP_CLASS_ID=$1
export REPO_PREFIX="/home/neruthes/DEV/dockermgr"
export CLASS_DATABASE_PREFIX="$REPO_PREFIX/class"
export CLASS_FIELDS_LIST="AppClassId DockerImageIdentifier CreationParams \
DefaultPortMapOut DefaultPortMapIn DefaultInstanceNamePrefix DefaultAutoStart \
DefaultMountPaths"

### Less important constants
MOUNT_PATH_PREFIX="/srv/dockermgr/mount"

### Main logic
if [[ -z "$TARGET_APP_CLASS_ID" ]]; then
    echo "!!! [ERROR] You should supply the 'AppClassId' of the desired package."
fi

echo "[INFO] Looking for class definition of '$TARGET_APP_CLASS_ID'..."

if [[ ! -e "$CLASS_DATABASE_PREFIX/$TARGET_APP_CLASS_ID" ]]; then
    echo "!!! [ERROR] Cannot find class definition of '$TARGET_APP_CLASS_ID'."
    exit 1
fi
echo "[INFO] Found class definition of '$TARGET_APP_CLASS_ID'."
echo "------------------------------------------"
echo "$(cat "$CLASS_DATABASE_PREFIX/$TARGET_APP_CLASS_ID")"
echo "------------------------------------------"

source "$REPO_PREFIX/read-class-conf.sh"

### Initialize variable DOCKER_COMMAND
TMP_UUID=$(uuidgen)
FAKE_SEQ_ID="${TMP_UUID:0:6}"
INSTANCE_IDENTIFIER="$DefaultInstanceNamePrefix-$FAKE_SEQ_ID"
DOCKER_COMMAND="docker run -d --name $INSTANCE_IDENTIFIER"

if [[ "$CreationParams" != "!" ]]; then
    DOCKER_COMMAND="$DOCKER_COMMAND $CreationParams"
fi

if [[ "$Config_AutoRemove" == "true" ]]; then
    DOCKER_COMMAND="$DOCKER_COMMAND --rm"
fi

### Network & port forwarding
if [[ "$DefaultPortMapOut" == "host" ]]; then
    DOCKER_COMMAND="$DOCKER_COMMAND --network host"
else
    DOCKER_COMMAND="$DOCKER_COMMAND -p $DefaultPortMapOut:$DefaultPortMapIn"
fi

### Mount
function _parseMount() {
    RAW_PROP=$1
    echo "RAW_PROP: $RAW_PROP" >&2
    if [[ "$RAW_PROP" == "!" ]]; then
        echo "[INFO] This application does not have mount paths." >&2
        return 0
    else
        echo "[INFO] Processing mount paths..." >&2
        sudo mkdir -p "$MOUNT_PATH_PREFIX"
        DIRS_LIST="${RAW_PROP//,/ }"
        echo "DIRS_LIST: $DIRS_LIST" >&2
        for i in $DIRS_LIST; do
            MOUNT_DIR_NAME_PRE="${i//\//-}"
            MOUNT_DIR_NAME="${MOUNT_DIR_NAME_PRE:1}"
            SRC_DIR_PATH="$MOUNT_PATH_PREFIX/$INSTANCE_IDENTIFIER/$MOUNT_DIR_NAME"
            sudo mkdir -p "$SRC_DIR_PATH"
            sudo chown root:docker "$SRC_DIR_PATH"
            printf -- " --mount src=$SRC_DIR_PATH,target=$i,type=bind "
            # echo " --mount src=$MOUNT_PATH_PREFIX/$INSTANCE_IDENTIFIER/$MOUNT_DIR_NAME,target=$i,type=bind " >&2
        done
    fi
    # EXAMPLE_STRING="--mount src=/mnt/NEPd2_Archer/ls/WWW/n.nextcloud1/var/www/html,target=/var/www/html,type=bind"
}
if [[ "$DefaultMountPaths" != "!" ]]; then
    echo "[INFO] Parsing mount paths..."
    echo "$(_parseMount $DefaultMountPaths) = $DefaultMountPaths"
    DOCKER_COMMAND="$DOCKER_COMMAND $(_parseMount $DefaultMountPaths)"
fi

DOCKER_COMMAND="$DOCKER_COMMAND $DockerImageIdentifier"

echo "[INFO] Calculated Docker command:"
echo "       $DOCKER_COMMAND"