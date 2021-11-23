import os
import sys

isWin = sys.platform[:3] == 'win'
wslPrefix = 'ubuntu.exe run ' if isWin else ''

test_cases_dir = './testcase'
path_of_bit = 'C:/a.bit' # A Windows-style path is ok if you runs on Windows
excluded_test_cases = []

color_red = "\033[0;31m"
color_green = "\033[0;32m"
color_none = "\033[0m"


def program_device():
    os.system('vivado -nolog -nojournal -notrace -mode batch -source pd.tcl -tclarg ' + path_of_bit + ' > ' + ('NUL' if isWin else '/dev/null'))

def collect_test_cases():
    test_cases = []
    for f in os.listdir(test_cases_dir):
        if os.path.splitext(f)[1] == '.c':
            test_cases.append(os.path.splitext(os.path.split(f)[1])[0])
    for s in excluded_test_cases:
        if s in test_cases: test_cases.remove(s)
    test_cases.sort()
    return test_cases

def main():
    test_cases = collect_test_cases()

    for t in test_cases:
        print('Generate bin of : ' + t + ': ')
        os.system('sudo bash generate_bin_bash.sh ' + t)

if __name__ == '__main__':
    main()