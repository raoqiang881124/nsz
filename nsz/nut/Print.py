import sys
import time
import json
from sys import argv
from multiprocessing.process import current_process
from nsz.ParseArguments import ParseArguments
from traceback import print_exc

enableInfo = True
enableError = True
enableWarning = True
enableDebug = False
silent = False
# Turning on machine output will convert all levels to JSON.
machineReadableOutput = False
minimalOutput = False
lastProgress = ""
lastMinimalProgress = ""
lastMinimalProgressLength = 0
spinnerFrames = ["|", "/", "-", "\\"]
spinnerIndex = 0

if len(argv) > 1:
    # We must re-parse the command line parameters here because this module
    # is re-imported in multiple modules which resets the variables each import.
    args = ParseArguments.parse(for_nutPrint=True)

    # Does the user want machine readable output?
    if args.machine_readable:
        machineReadableOutput = True

    # Minimal output suppresses normal info logs. Errors and warnings are kept.
    if args.minimal_output:
        minimalOutput = True
        enableInfo = False


def info(s, pleaseNoPrint=None):
    if silent or not enableInfo:
        return

    if pleaseNoPrint is None:
        if not machineReadableOutput:
            sys.stdout.write(s + "\n")
    else:
        if not machineReadableOutput:
            while pleaseNoPrint.value() > 0:
                time.sleep(0.01)
            pleaseNoPrint.increment()
            sys.stdout.write(s + "\n")
            sys.stdout.flush()
            pleaseNoPrint.decrement()


def error(errorCode, s):
    if silent or not enableError:
        return
    if machineReadableOutput:
        s = json.dumps({"type": "error", "code": errorCode, "message": s})

    sys.stdout.write(s + "\n")


def warning(s):
    if silent or not enableWarning:
        return
    if machineReadableOutput:
        s = json.dumps({"type": "warning", "message": s})

    sys.stdout.write(s + "\n")


def debug(s):
    if silent or not enableDebug:
        return
    if not machineReadableOutput:
        sys.stdout.write(s + "\n")


def exception():
    if not machineReadableOutput:
        print_exc()


def progress(job, s):
    global lastProgress
    global lastMinimalProgress
    global lastMinimalProgressLength
    global spinnerIndex

    if machineReadableOutput:
        data = s if isinstance(s, dict) else {}
        if job == "Complete":
            payload = {"type": "complete", "file": data.get("filePath", "")}
        else:
            payload = {"type": "progress", "step": data.get("step", job)}
            if data.get("filePath"):
                payload["file"] = data["filePath"]
            total = data.get("sourceSize")
            current = data.get("processed")
            if total is not None:
                payload["totalWrite"] = total
            if current is not None:
                payload["currentWrite"] = current
            if total is not None and current is not None and total > 0:
                payload["percent"] = round(current * 100 / total, 1)
            if "readSize" in data:
                payload["totalRead"] = data["readSize"]
            if "read" in data:
                payload["currentRead"] = data["read"]

        line = json.dumps(payload)
        if line != lastProgress:
            sys.stdout.write(line + "\n")
            lastProgress = line
        return

    if minimalOutput:
        # Keep minimal output stable by avoiding worker-process duplicates.
        if current_process().name != "MainProcess":
            return
        if job == "Complete":
            minimalLine = "100% Done"
        elif isinstance(s, dict) and "sourceSize" in s and "processed" in s:
            total = s["sourceSize"]
            processed = s["processed"]
            percentage = 0 if total <= 0 else min(100, int(processed * 100 / total))
            step = s["step"] if "step" in s else job
            spinner = spinnerFrames[spinnerIndex]
            spinnerIndex = (spinnerIndex + 1) % len(spinnerFrames)
            minimalLine = f"{spinner} {percentage}% {step}"
        else:
            return
        if job != "Complete" or minimalLine != lastMinimalProgress:
            padding = ""
            if lastMinimalProgressLength > len(minimalLine):
                padding = " " * (lastMinimalProgressLength - len(minimalLine))
            if job == "Complete":
                sys.stdout.write("\r" + minimalLine + padding + "\n")
                lastMinimalProgressLength = 0
                lastMinimalProgress = ""
            else:
                sys.stdout.write("\r" + minimalLine + padding)
                lastMinimalProgressLength = len(minimalLine)
                lastMinimalProgress = minimalLine
            sys.stdout.flush()
        return

    if job == "Complete":
        filePath = s.get("filePath", "") if isinstance(s, dict) else ""
        if filePath:
            sys.stdout.write("[DONE]       {0}\n".format(filePath))
        else:
            sys.stdout.write("[DONE]\n")
        sys.stdout.flush()


def isMinimalOutput():
    return minimalOutput
