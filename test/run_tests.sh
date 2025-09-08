#!/usr/bin/env zsh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}=== Bash Scripts Test Suite ===${NC}"
echo

# Check if bats is installed
if ! command -v bats &> /dev/null; then
    echo -e "${RED}Error: bats-core is not installed${NC}"
    echo "Install it with: brew install bats-core"
    exit 1
fi

# Function to run tests in a directory
run_test_directory() {
    local test_dir="$1"
    local test_name="$2"
    
    if [ ! -d "$test_dir" ]; then
        echo -e "${YELLOW}Warning: Test directory $test_dir not found, skipping${NC}"
        return 0
    fi
    
    local test_files=($(find "$test_dir" -name "*.bats" 2>/dev/null))
    
    if [ ${#test_files[@]} -eq 0 ]; then
        echo -e "${YELLOW}No test files found in $test_dir${NC}"
        return 0
    fi
    
    echo -e "${BLUE}Running $test_name tests...${NC}"
    echo "Test directory: $test_dir"
    echo "Test files: ${test_files[@]##*/}"
    echo
    
    local failed=0
    local total=0
    
    for test_file in "${test_files[@]}"; do
        echo -e "${BLUE}Running $(basename "$test_file")...${NC}"
        if bats "$test_file"; then
            echo -e "${GREEN}✓ $(basename "$test_file") passed${NC}"
        else
            echo -e "${RED}✗ $(basename "$test_file") failed${NC}"
            failed=$((failed + 1))
        fi
        total=$((total + 1))
        echo
    done
    
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}All $test_name tests passed! ($total/$total)${NC}"
    else
        echo -e "${RED}$failed out of $total $test_name test files failed${NC}"
    fi
    
    echo
    return $failed
}

# Initialize counters
total_failed=0
total_suites=0

# Run git script tests
if run_test_directory "$ROOT_DIR/git/tests" "Git Script"; then
    git_result=0
else
    git_result=$?
    total_failed=$((total_failed + 1))
fi
total_suites=$((total_suites + 1))

# Run utility script tests (if they exist)
if [ -d "$ROOT_DIR/utility/tests" ]; then
    if run_test_directory "$ROOT_DIR/utility/tests" "Utility Script"; then
        utility_result=0
    else
        utility_result=$?
        total_failed=$((total_failed + 1))
    fi
    total_suites=$((total_suites + 1))
fi

# Run IDE script tests (if they exist)
if [ -d "$ROOT_DIR/ide/tests" ]; then
    if run_test_directory "$ROOT_DIR/ide/tests" "IDE Script"; then
        ide_result=0
    else
        ide_result=$?
        total_failed=$((total_failed + 1))
    fi
    total_suites=$((total_suites + 1))
fi

# Final results
echo -e "${BLUE}=== Test Summary ===${NC}"
if [ $total_failed -eq 0 ]; then
    echo -e "${GREEN}All test suites passed! 🎉${NC}"
    echo -e "${GREEN}Git scripts: ✓${NC}"
    [ -d "$ROOT_DIR/utility/tests" ] && echo -e "${GREEN}Utility scripts: ✓${NC}"
    [ -d "$ROOT_DIR/ide/tests" ] && echo -e "${GREEN}IDE scripts: ✓${NC}"
    exit 0
else
    echo -e "${RED}$total_failed out of $total_suites test suites failed${NC}"
    echo -e "Git scripts: $( [ $git_result -eq 0 ] && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}" )"
    [ -d "$ROOT_DIR/utility/tests" ] && echo -e "Utility scripts: $( [ $utility_result -eq 0 ] && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}" )"
    [ -d "$ROOT_DIR/ide/tests" ] && echo -e "IDE scripts: $( [ $ide_result -eq 0 ] && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}" )"
    exit 1
fi