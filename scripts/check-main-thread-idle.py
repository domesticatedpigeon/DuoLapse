import re
import sys

MINIMUM_IDLE_SHARE = 0.5
THREAD_HEADER = re.compile(r"^\s{4}(\d+) Thread_")
SAMPLE_COUNT = re.compile(r"^[\s+!:|]*(\d+) ")
IDLE_FRAME = "__CFRunLoopServiceMachPort"
MAIN_THREAD_HEADER = re.compile(r"Thread_\d+.*(com\.apple\.main-thread|Main Thread)")


def main_thread_lines(lines):
    start = next(index for index, line in enumerate(lines) if MAIN_THREAD_HEADER.search(line))
    end = next(
        (index for index in range(start + 1, len(lines)) if THREAD_HEADER.match(lines[index])),
        len(lines),
    )
    return lines[start:end]


def idle_share(sample_text):
    lines = main_thread_lines(sample_text.splitlines())
    total = int(THREAD_HEADER.match(lines[0]).group(1))
    idle = max(
        (int(SAMPLE_COUNT.match(line).group(1)) for line in lines if IDLE_FRAME in line and SAMPLE_COUNT.match(line)),
        default=0,
    )
    return idle / total


share = idle_share(open(sys.argv[1], encoding="utf-8", errors="replace").read())
print(f"Main thread idle in the run loop for {share:.0%} of samples")
if share < MINIMUM_IDLE_SHARE:
    sys.exit(f"Main thread was busy for more than {1 - MINIMUM_IDLE_SHARE:.0%} of samples; the app is likely hung")
