bash my_run_test.sh ${1%.*} > /Users/dreamer/Desktop/Programm/Test/my.ans
diff /Users/dreamer/Desktop/Programm/Test/my.ans ./testcase/${1%.*}.ans