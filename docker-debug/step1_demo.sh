SCRIPT=./build_and_run.sh
while [ ! -f "$SCRIPT" ]; do sleep 1; done
chmod +x "$SCRIPT"
"$SCRIPT"