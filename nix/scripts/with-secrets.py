import json
import os
import sys

refs_path, op, *command = sys.argv[1:]
if not command or command == ['--help']:
    print('Usage: with-secrets COMMAND [ARG...]')
    sys.exit(0 if command else 2)
refs = json.load(open(refs_path))
missing = {key: ref for key, ref in refs.items() if not os.environ.get(key) or os.environ[key].startswith('op://')}
if not missing:
    os.execvp(command[0], command)
env = os.environ.copy()
env.update(missing)
flags = ['--no-masking'] if sys.stdin.isatty() and sys.stdout.isatty() else []
os.execve(op, [op, 'run', *flags, '--', *command], env)
