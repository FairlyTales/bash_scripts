#!/usr/bin/env zsh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

# Spinner animation with dynamic test statistics
SPINNER_PID=""
spinner_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

start_spinner() {
    local message="$1"
    tput civis # Hide cursor
    (
        i=0
        while true; do
            printf "\r${CYAN}%s %s${NC}" "${spinner_chars:$i:1}" "$message"
            i=$(( (i + 1) % ${#spinner_chars} ))
            sleep 0.1
        done
    ) &
    SPINNER_PID=$!
}

start_dynamic_spinner() {
    local message="$1"
    local stats_file="$2"
    tput civis # Hide cursor
    (
        i=0
        while true; do
            local stats=""
            if [ -f "$stats_file" ]; then
                stats=$(cat "$stats_file" 2>/dev/null || echo "")
            fi
            printf "\r${CYAN}%s %s${NC}" "${spinner_chars:$i:1}" "$message"
            if [ -n "$stats" ]; then
                printf "\n  ${WHITE}%s${NC}" "$stats"
                printf "\033[1A" # Move cursor back up
            fi
            i=$(( (i + 1) % ${#spinner_chars} ))
            sleep 0.1
        done
    ) &
    SPINNER_PID=$!
}

stop_spinner() {
    if [ -n "$SPINNER_PID" ]; then
        kill "$SPINNER_PID" 2>/dev/null
        wait "$SPINNER_PID" 2>/dev/null
        SPINNER_PID=""
    fi
    printf "\r\033[K" # Clear the current line
    printf "\n\033[1A\033[K" # Clear the line below and move back up
    tput cnorm # Show cursor
}

# Cleanup function for spinner
cleanup_spinner() {
    stop_spinner
    exit
}

# Trap to ensure spinner cleanup on interruption
trap cleanup_spinner INT TERM

# Script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${CYAN}=== Bash Scripts Test Suite ===${NC}"
echo

# Display test directories that will be run
echo -e "${CYAN}Test directories to run:${NC}"
test_dirs_found=0
if [ -d "$ROOT_DIR/git/tests" ]; then
    echo "  - Git Scripts ($ROOT_DIR/git/tests)"
    test_dirs_found=$((test_dirs_found + 1))
fi
if [ -d "$ROOT_DIR/utility/tests" ]; then
    echo "  - Utility Scripts ($ROOT_DIR/utility/tests)"
    test_dirs_found=$((test_dirs_found + 1))
fi
if [ -d "$ROOT_DIR/ide/tests" ]; then
    echo "  - IDE Scripts ($ROOT_DIR/ide/tests)"
    test_dirs_found=$((test_dirs_found + 1))
fi

if [ $test_dirs_found -eq 0 ]; then
    echo -e "${YELLOW}  No test directories found${NC}"
    exit 1
fi

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
        
        # Create temporary file for dynamic stats
        local stats_file=$(mktemp)
        echo "Passed: 0 | Failed: 0 | Executed: 0" > "$stats_file"
        
        # Start dynamic spinner animation
        start_dynamic_spinner "Running $file_name..." "$stats_file"
        
        # Initialize counters for this file
        local file_test_count=0
        local file_failed_count=0
        local file_passed_count=0
        local file_total_tests=0
        
        # Get total test count first
        if command -v grep &> /dev/null; then
            file_total_tests=$(grep -c "^@test" "$test_file" 2>/dev/null || echo "?")
        else
            file_total_tests="?"
        fi
        
        # Run bats with TAP format and process output in real-time
        local bats_exit_code=0
        local temp_exit_file=$(mktemp)
        
        while IFS= read -r line; do
            if [[ $line =~ ^ok\ [0-9]+\ (.+)$ ]]; then
                # Passed test
                local test_name="${line#ok * }"
                all_tests+=("$file_name: $test_name")
                passed_tests+=("$file_name: $test_name")
                test_files+=("$file_name")
                file_test_count=$((file_test_count + 1))
                file_passed_count=$((file_passed_count + 1))
                dir_passed_tests=$((dir_passed_tests + 1))
                
                # Update dynamic stats
                echo "Passed: $file_passed_count | Failed: $file_failed_count | Executed: $file_test_count/$file_total_tests" > "$stats_file"
                
            elif [[ $line =~ ^not\ ok\ [0-9]+\ (.+)$ ]]; then
                # Failed test
                local test_name="${line#not ok * }"
                all_tests+=("$file_name: $test_name")
                failed_tests+=("$file_name: $test_name")
                test_files+=("$file_name")
                file_test_count=$((file_test_count + 1))
                file_failed_count=$((file_failed_count + 1))
                dir_failed_tests=$((dir_failed_tests + 1))
                
                # Update dynamic stats
                echo "Passed: $file_passed_count | Failed: $file_failed_count | Executed: $file_test_count/$file_total_tests" > "$stats_file"
            fi
        done < <(bats --tap "$test_file" 2>/dev/null; echo $? > "$temp_exit_file")
        
        # Get the exit code
        bats_exit_code=$(cat "$temp_exit_file")
        rm -f "$temp_exit_file"
        
        # Stop spinner and show results
        stop_spinner
        rm -f "$stats_file"
        
        if [ $bats_exit_code -eq 0 ]; then
            echo -e "${GREEN}✓ $file_name passed${NC}"
        else
            echo -e "${RED}✗ $file_name failed${NC}"
            failed_files=$((failed_files + 1))
        fi
        
        total_files=$((total_files + 1))
        total_test_count=$((total_test_count + file_test_count))
        echo "  Individual tests: $file_test_count total, $file_passed_count passed, $file_failed_count failed"
        echo
    done
    
    if [ $failed_files -eq 0 ]; then
        echo -e "${GREEN}All test files passed! ($total_files/$total_files files, $dir_passed_tests/$((dir_passed_tests + dir_failed_tests)) tests)${NC}"
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