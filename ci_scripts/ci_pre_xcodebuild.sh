#!/bin/sh

#  ci_pre_xcodebuild.sh
#  soap
#
#  Created by 하정우 on 2026/9/24.
#

#!/bin/sh
set -eu

SECRETS_DIR="$CI_PRIMARY_REPOSITORY_PATH/BuddyData/Sources/BuddyDataCore/Helper"
EXAMPLE="$SECRETS_DIR/OTLDebugSecrets.swift.example"
SECRETS="$SECRETS_DIR/OTLDebugSecrets.swift"

if [ ! -f "$SECRETS" ]; then
  cp "$EXAMPLE" "$SECRETS"
fi
