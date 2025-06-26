#!/usr/bin/env bash
##===----------------------------------------------------------------------===##
# Copyright (c) 2024, Modular Inc. All rights reserved.
#
# Licensed under the Apache License v2.0 with LLVM Exceptions:
# https://llvm.org/LICENSE.txt
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##===----------------------------------------------------------------------===##

set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
REPO_ROOT="${SCRIPT_DIR}"/..
BUILD_DIR="${REPO_ROOT}"/build

echo "Creating build directory for building the Library running the tests in."
mkdir -p "${BUILD_DIR}"

source "${SCRIPT_DIR}"/package-lib.sh
TEST_PATH="${REPO_ROOT}/src/test"
if [[ $# -gt 0 ]]; then
  # If an argument is provided, use it as the specific test file or directory
  TEST_PATH=$1
fi

# Run the tests
mojo test -D ASSERT=all -I build/ $TEST_PATH
