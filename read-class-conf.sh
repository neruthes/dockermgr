#!/bin/bash

###############################################################################
#
# read-class-conf.sh
#
# This script reads necessary variables from class definition and expose them
#   to the other parts of the program.
#
###############################################################################

# TARGET_APP_CLASS_ID=$1
# CLASS_DATABASE_PREFIX="/home/neruthes/DEV/dockermgr/class"
# CLASS_FIELDS_LIST="AppClassId DockerImageIdentifier CreationParams DefaultPortMapOut DefaultPortMapIn DefaultInstanceNamePrefix DefaultAutoStart"


### Import class properties

function _importClassProperty() {
    FILED_NAME=$1
    GOT_LINE=$(grep "${FILED_NAME}=" "$CLASS_DATABASE_PREFIX/$TARGET_APP_CLASS_ID")
    LINE_VALUE="${GOT_LINE/$FILED_NAME\=/}"
    printf -- "$LINE_VALUE"
}

for i in $CLASS_FIELDS_LIST; do
    export $i="$(_importClassProperty $i)"
done

### Provide getter function

function _getProp() {
    VAR_NAME=$1
    bash -c 'echo "$'$VAR_NAME'"'
}

### Check data integrity

for i in $CLASS_FIELDS_LIST; do
    if [[ -z "$(_getProp $i)" ]]; then
        echo "!!! [ERROR] The property $i is empty. Should there be a bug?"
        exit 1
    fi
done

echo "[INFO] Imported class definition of '$(_getProp AppClassId)'."