"""Check installed dotfiles through a real terminal, including prompt events."""
import errno
import fcntl
import os
from pathlib import Path
import pty
import re
import select
import shlex
import shutil
import signal
import struct
import subprocess
import sys
import tempfile
import termios
import time


class CheckError(Exception):
    pass


def interactive_probe(fish, env):
    """Wait for the initial prompt before querying it; fish -ic skips that event."""
    with tempfile.TemporaryDirectory(prefix='dotfiles-probe-') as tmp:
        probe = Path(tmp) / 'probe.fish'
        probe.write_text("""printf '\\n__DOTFILES_BEGIN__\\n'
functions fish_prompt
for tool in fish starship lsd git fzf
    if command -q $tool
        printf '__DOTFILES_TOOL__%s=%s\\n' $tool (command -s $tool)
    else
        printf '__DOTFILES_MISSING__%s\\n' $tool
    end
end
if functions -q __async_prompt_fire
    printf '__DOTFILES_ASYNC__\\n'
end
printf '__DOTFILES_END__\\n'
""")
        pid, fd = pty.fork()
        if pid == 0:
            os.execve(fish, [fish, '-i'], dict(env, TERM='xterm-256color'))
        fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack('HHHH', 30, 120, 0, 0))
        data = bytearray()
        started = last_output = time.monotonic()
        sent = False
        try:
            while time.monotonic() - started < 20:
                ready, _, _ = select.select([fd], [], [], 0.1)
                if ready:
                    try:
                        chunk = os.read(fd, 65536)
                    except OSError as exc:
                        if exc.errno == errno.EIO:
                            break
                        raise
                    if not chunk:
                        break
                    data.extend(chunk)
                    last_output = time.monotonic()
                    # Answer cursor queries instead of waiting for Fish's timeout.
                    if b'\x1b[6n' in chunk:
                        os.write(fd, b'\x1b[1;1R')
                elif data and not sent and time.monotonic() - last_output > 0.5:
                    os.write(fd, ('source ' + shlex.quote(str(probe)) + '\n').encode())
                    sent = True
                if b'__DOTFILES_END__\r\n' in data:
                    text = data.decode(errors='replace')
                    return text.split('__DOTFILES_BEGIN__\r\n', 1)[-1]
            raise CheckError('Interactive Fish did not finish its prompt check within 20 seconds.')
        finally:
            os.close(fd)
            try:
                os.kill(pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            os.waitpid(pid, 0)


def check_fish(env):
    fish = shutil.which('fish', path=env.get('PATH'))
    if not fish:
        raise CheckError('fish is missing from PATH.')
    report = interactive_probe(fish, env)
    if '__DOTFILES_ASYNC__' in report or '__async_prompt' in report:
        raise CheckError('fish-async-prompt overrides Starship. Rerun install.sh to remove the conflicting plugin.')
    if not re.search(r'\bstarship\b', report.split('__DOTFILES_TOOL__', 1)[0]):
        raise CheckError('The interactive Fish prompt is not using Starship.')
    missing = re.findall(r'__DOTFILES_MISSING__(\w+)', report)
    if missing:
        raise CheckError('Missing tools in interactive Fish PATH: ' + ', '.join(missing))
    tools = dict(re.findall(r'__DOTFILES_TOOL__(\w+)=([^\r\n]+)', report))
    for tool in ('fish', 'starship', 'lsd', 'git', 'fzf'):
        if tool not in tools:
            raise CheckError('Interactive Fish did not report a path for ' + tool)
        print('PASS: ' + tool + ' → ' + tools[tool])
    for tool, minimum in [('fish', (3, 4)), ('fzf', (0, 33))]:
        version = subprocess.check_output([tools[tool], '--version'], text=True)
        match = re.search(r'(\d+)\.(\d+)', version)
        if not match or tuple(map(int, match.groups())) < minimum:
            raise CheckError(tool + ' is too old for the configured fzf.fish plugin.')
    plugins = Path(env['HOME']) / '.config/fish/fish_plugins'
    if not plugins.is_file() or 'patrickf1/fzf.fish@v10.3' not in plugins.read_text().lower():
        raise CheckError('fzf.fish must be pinned to v10.3 for compatibility with Fish 3.7.')
    print('PASS: Starship remains active after the first interactive prompt; Fish/fzf versions are compatible')


def check_tmux(env):
    home = Path(env['HOME'])
    state = home / '.config/dotfiles/features.conf'
    if not state.is_file():
        raise CheckError('Feature configuration is missing. Run install.sh first.')
    result = subprocess.run(['/bin/bash', '-c', 'source "$1"; printf "%s\\n%s\\n" "$USE_TMUX" "$SHELL_PATH"', 'check', str(state)], env=env, check=True, capture_output=True, text=True)
    enabled, shell = result.stdout.strip().splitlines()
    if enabled == '0':
        print('PASS: tmux disabled in features.conf')
        return
    tmux = shutil.which('tmux', path=env.get('PATH'))
    if not tmux:
        raise CheckError('tmux is enabled but missing from PATH.')
    # A short, private socket avoids macOS's Unix socket path-length limit.
    with tempfile.TemporaryDirectory(prefix='dotfiles-tmux-', dir='/tmp') as tmp:
        socket = str(Path(tmp) / 'socket')
        marker = str(Path(tmp) / 'path-check')
        tmux_env = dict(env, DOTFILES_CHECK='1', PATH=marker + os.pathsep + env.get('PATH', ''))
        command = [tmux, '-S', socket]
        def run(*args):
            return subprocess.run(command + list(args), env=tmux_env, check=True, capture_output=True, text=True).stdout.strip()
        try:
            run('-f', str(home / '.tmux.conf'), 'new-session', '-d', '-s', 'dotfiles-check', '/bin/sleep 30')
            if run('show-option', '-gv', 'default-shell') != shell:
                raise CheckError('tmux default-shell differs from the configured shell.')
            if run('show-option', '-gv', 'prefix') != 'C-a':
                raise CheckError('tmux prefix is not Ctrl-A.')
            if marker not in run('show-environment', '-g', 'PATH').removeprefix('PATH=').split(os.pathsep):
                raise CheckError('tmux overwrites PATH instead of inheriting user tool paths.')
        finally:
            subprocess.run(command + ['kill-server'], env=tmux_env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print('PASS: isolated tmux server uses the configured shell, Ctrl-A, and inherited PATH')


def main():
    try:
        check_fish(dict(os.environ))
        check_tmux(dict(os.environ))
    except (CheckError, OSError, subprocess.CalledProcessError, ValueError) as exc:
        print('FAIL: ' + str(exc), file=sys.stderr)
        return 1
    print('Installation checks passed.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
