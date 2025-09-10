#!/usr/bin/env zsh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${CYAN}=== Bash Scripts Test Suite ===${NC}"
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
    
    local test_file_array=($(find "$test_dir" -name "*.bats" 2>/dev/null))
    
    if [ ${#test_file_array[@]} -eq 0 ]; then
        echo -e "${YELLOW}No test files found in $test_dir${NC}"
        return 0
    fi
    
    echo -e "${CYAN}Running $test_name tests...${NC}"
    echo "Test directory: $test_dir"
    echo "Test files:"
    printf '  - %s\n' "${test_file_array[@]##*/}"
    echo
    
    local failed_files=0
    local total_files=0
    local dir_failed_tests=0
    local dir_passed_tests=0
    
    for test_file in "${test_file_array[@]}"; do
        local file_name=$(basename "$test_file")
        echo -e "${CYAN}Running $file_name...${NC}"
        
        # Run bats with TAP format to get individual test results
        local tap_output=""
        if tap_output=$(bats --tap "$test_file" 2>&1); then
            # File passed overall
            echo -e "${GREEN}✓ $file_name passed${NC}"
        else
            # File failed overall
            echo -e "${RED}✗ $file_name failed${NC}"
            failed_files=$((failed_files + 1))
        fi
        
        # Parse TAP output to get individual test results
        local file_test_count=0
        local file_failed_count=0
        
        while IFS= read -r line; do
            if [[ $line =~ ^ok\ [0-9]+\ (.+)$ ]]; then
                # Passed test
                local test_name="${BASH_REMATCH[1]}"
                all_tests+=("$file_name: $test_name")
                passed_tests+=("$file_name: $test_name")
                test_files+=("$file_name")
                file_test_count=$((file_test_count + 1))
                dir_passed_tests=$((dir_passed_tests + 1))
            elif [[ $line =~ ^not\ ok\ [0-9]+\ (.+)$ ]]; then
                # Failed test
                local test_name="${BASH_REMATCH[1]}"
                all_tests+=("$file_name: $test_name")
                failed_tests+=("$file_name: $test_name")
                test_files+=("$file_name")
                file_test_count=$((file_test_count + 1))
                file_failed_count=$((file_failed_count + 1))
                dir_failed_tests=$((dir_failed_tests + 1))
            fi
        done <<< "$tap_output"
        
        total_files=$((total_files + 1))
        total_test_count=$((total_test_count + file_test_count))
        echo "  Individual tests: $file_test_count total, $((file_test_count - file_failed_count)) passed, $file_failed_count failed"
        echo
    done
    
    if [ $failed_files -eq 0 ]; then
        echo -e "${GREEN}All $test_name test files passed! ($total_files/$total_files files, $dir_passed_tests/$((dir_passed_tests + dir_failed_tests)) tests)${NC}"
    else
        echo -e "${RED}$failed_files out of $total_files $test_name test files failed ($dir_failed_tests/$((dir_passed_tests + dir_failed_tests)) tests failed)${NC}"
    fi
    
    echo
    return $failed_files
}

# Initialize counters and test tracking arrays
total_failed=0
total_suites=0
declare -a all_tests=()
declare -a passed_tests=()
declare -a failed_tests=()
declare -a test_files=()
total_test_count=0

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

# Display detailed individual test results
if [ ${#failed_tests[@]} -gt 0 ]; then
    echo -e "${RED}=== Failed Tests (${#failed_tests[@]}) ===${NC}"
    for test in "${failed_tests[@]}"; do
        echo -e "${RED}✗ $test${NC}"
    done
    echo
fi

if [ ${#passed_tests[@]} -gt 0 ]; then
    echo -e "${GREEN}=== Passed Tests (${#passed_tests[@]}) ===${NC}"
    for test in "${passed_tests[@]}"; do
        echo -e "${GREEN}✓ $test${NC}"
    done
    echo
fi

# Final results
echo -e "${CYAN}=== Test Summary ===${NC}"
echo -e "${CYAN}Total Tests: $total_test_count | Passed: ${#passed_tests[@]} | Failed: ${#failed_tests[@]}${NC}"
echo

# Display test suite summary
if [ $total_failed -eq 0 ]; then
    echo -e "${GREEN}All test suites passed! 🎉${NC}"
    echo -e "${GREEN}Git scripts: ✓${NC}"
    [ -d "$ROOT_DIR/utility/tests" ] && echo -e "${GREEN}Utility scripts: ✓${NC}"
    [ -d "$ROOT_DIR/ide/tests" ] && echo -e "${GREEN}IDE scripts: ✓${NC}"
else
    echo -e "${RED}$total_failed out of $total_suites test suites failed${NC}"
    echo -e "Git scripts: $( [ $git_result -eq 0 ] && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}" )"
    [ -d "$ROOT_DIR/utility/tests" ] && echo -e "Utility scripts: $( [ $utility_result -eq 0 ] && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}" )"
    [ -d "$ROOT_DIR/ide/tests" ] && echo -e "IDE scripts: $( [ $ide_result -eq 0 ] && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}" )"
fi
echo

# Exit with appropriate code
if [ ${#failed_tests[@]} -gt 0 ]; then
    exit 1
else
    exit 0
fi