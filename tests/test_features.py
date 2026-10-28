"""Exercise feature setup in isolated homes without network or installed tools."""
import os
from pathlib import Path
import subprocess
import shlex
import shutil
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'scripts/configure-features.sh'


class FeaturesTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='dotfiles features ')
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name) / 'home'
        self.home.mkdir()
        self.bin = Path(self.temp.name) / 'bin'
        self.bin.mkdir()
        for tool in ['tmux', 'willow']:
            p = self.bin / tool
            p.write_text('#!/bin/sh\nexit 0\n')
            p.chmod(0o755)
        # Keep host-installed tmux/Willow out of missing-dependency checks.
        for tool in ('dirname', 'mkdir', 'mktemp', 'cat', 'cmp', 'head', 'rm', 'mv', 'id', 'awk'):
            (self.bin / tool).symlink_to(shutil.which(tool))
        self.env = dict(os.environ, HOME=str(self.home), SHELL='/bin/sh', PATH=str(self.bin))

    def run_setup(self, *args, success=True):
        result = subprocess.run(['/bin/bash', str(SCRIPT), *args], env=self.env,
                                text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def state(self):
        return (self.home / '.config/dotfiles/features.conf').read_text()

    def test_all_combinations(self):
        for tmux in [False, True]:
            for willow in [False, True]:
                with self.subTest(tmux=tmux, willow=willow):
                    self.run_setup('--tmux' if tmux else '--no-tmux',
                                   '--willow' if willow else '--no-willow', '--shell', '/bin/sh')
                    state = self.state()
                    ghostty = (self.home / '.config/ghostty/config').read_text()
                    tmux_config = (self.home / '.tmux.conf').read_text()
                    self.assertIn(f'USE_TMUX={int(tmux)}', state)
                    self.assertIn(f'USE_WILLOW={int(willow)}', state)
                    self.assertIn('SHELL_PATH=/bin/sh', state)
                    self.assertEqual('ghostty/tmux.conf' in ghostty, tmux)
                    self.assertEqual('new-session -A -s main' in ghostty, tmux)
                    self.assertEqual('tmux/tmux.conf' in tmux_config, tmux)
                    self.assertEqual('tmux/willow.conf' in tmux_config, tmux and willow)
                    self.assertIn('default-shell "/bin/sh"', tmux_config)
                    command = next(line.split(' = ', 1)[1] for line in ghostty.splitlines() if line.startswith('command = '))
                    self.assertEqual(shlex.split(command)[0], str(self.bin / 'tmux') if tmux else '/bin/sh')
                    if not tmux:
                        self.assertIn('command = "/bin/sh"', ghostty)
                    base_commands = '\n'.join(line for line in (ROOT / 'tmux/tmux.conf').read_text().splitlines() if not line.lstrip().startswith('#'))
                    self.assertNotIn('willow', base_commands)
                    self.assertNotIn('keybind = cmd+t=', (ROOT / 'ghostty/config').read_text())

    def test_new_machine_defaults(self):
        self.run_setup('--shell', '/bin/sh')
        self.assertIn('USE_TMUX=1', self.state())
        self.assertIn('USE_WILLOW=0', self.state())

    def test_persistence_and_idempotence(self):
        self.run_setup('--no-tmux', '--willow', '--shell', '/bin/sh')
        paths = [self.home / '.config/dotfiles/features.conf',
                 self.home / '.config/ghostty/config', self.home / '.tmux.conf']
        before = [(p.read_bytes(), p.stat().st_mtime_ns) for p in paths]
        self.run_setup()
        self.assertEqual(before, [(p.read_bytes(), p.stat().st_mtime_ns) for p in paths])
        self.assertFalse(list(self.home.rglob('*.before-features*')))
        self.run_setup('--tmux')
        self.assertIn('USE_TMUX=1', self.state())
        self.assertIn('USE_WILLOW=1', self.state())

    def test_missing_willow_writes_nothing(self):
        (self.bin / 'willow').unlink()
        result = self.run_setup('--willow', '--shell', '/bin/sh', success=False)
        self.assertIn('Willow is enabled but missing', result.stderr)
        self.assertFalse((self.home / '.config').exists())
        self.assertFalse((self.home / '.tmux.conf').exists())

    def test_missing_tmux_only_blocks_enabled_tmux(self):
        (self.bin / 'tmux').unlink()
        self.run_setup('--tmux', '--shell', '/bin/sh', success=False)
        self.assertFalse((self.home / '.config').exists())
        self.run_setup('--no-tmux', '--no-willow', '--shell', '/bin/sh')

    def test_invalid_input_writes_nothing(self):
        for args in [('--oops',), ('--shell',), ('--shell', 'fish'), ('--shell', '/no/shell')]:
            self.run_setup(*args, success=False)
            self.assertFalse((self.home / '.config').exists())

    def test_existing_symlink_is_preserved_without_changing_target(self):
        target = Path(self.temp.name) / 'old config'
        target.write_text('old source\n')
        tmux = self.home / '.tmux.conf'
        tmux.symlink_to(target)
        backup = self.home / '.tmux.conf.before-features'
        backup.write_text('earlier backup\n')
        self.run_setup('--tmux', '--no-willow', '--shell', '/bin/sh')
        self.assertEqual(target.read_text(), 'old source\n')
        self.assertFalse(tmux.is_symlink())
        self.assertTrue((self.home / '.tmux.conf.before-features.1').is_symlink())
        self.assertEqual(backup.read_text(), 'earlier backup\n')

    def test_feature_only_command_does_not_restore_app_settings(self):
        self.run_setup('--tmux', '--no-willow', '--shell', '/bin/sh')
        self.assertFalse((self.home / 'Library').exists())
        self.assertFalse((self.home / '.gitconfig').exists())
        self.assertFalse((self.home / '.zshrc').exists())


if __name__ == '__main__':
    unittest.main()
