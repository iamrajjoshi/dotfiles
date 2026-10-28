"""Regress prompt-event failures that a fish -ic function query cannot catch."""
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('check_install', ROOT / 'scripts/check_install.py')
check = importlib.util.module_from_spec(spec)
spec.loader.exec_module(check)


@unittest.skipUnless(all(shutil.which(tool) for tool in ('fish', 'starship', 'lsd', 'git', 'fzf')), 'requires the shell toolchain')
class InteractivePromptTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='dotfiles check test ')
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        config = self.home / '.config/fish'
        config.mkdir(parents=True)
        self.config = config / 'config.fish'
        self.config.write_text('set fish_greeting ""\nstarship init fish | source\n')
        (config / 'fish_plugins').write_text('patrickf1/fzf.fish@v10.3\n')
        (self.home / '.config/starship.toml').write_text('format = "$character"\n')
        self.env = dict(os.environ, HOME=str(self.home), XDG_CONFIG_HOME=str(self.home / '.config'),
                        STARSHIP_CONFIG=str(self.home / '.config/starship.toml'),
                        STARSHIP_CACHE=str(self.home / '.cache/starship'), TERM='xterm-256color')

    def test_starship_survives_real_initial_prompt(self):
        check.check_fish(self.env)

    def test_prompt_event_override_is_detected(self):
        with self.config.open('a') as f:
            f.write('''
function replace_prompt --on-event fish_prompt
    function fish_prompt
        printf 'fallback> '
    end
end
''')
        # The old probe falsely passes: no prompt event occurs before -c.
        old = subprocess.run([shutil.which('fish'), '-ic', 'functions fish_prompt'], env=self.env,
                             check=True, capture_output=True, text=True)
        self.assertIn('starship', old.stdout)
        with self.assertRaisesRegex(check.CheckError, 'not using Starship'):
            check.check_fish(self.env)


@unittest.skipUnless(shutil.which('tmux'), 'requires tmux')
class TmuxPathTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='dotfiles tmux test ')
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        state = self.home / '.config/dotfiles'
        state.mkdir(parents=True)
        (state / 'features.conf').write_text('USE_TMUX=1\nSHELL_PATH=/bin/sh\n')
        self.config = self.home / '.tmux.conf'
        self.config.write_text('set -g default-shell /bin/sh\nset -g prefix C-a\n')
        self.env = dict(os.environ, HOME=str(self.home))

    def test_tmux_inherits_user_tool_paths(self):
        check.check_tmux(self.env)

    def test_tmux_path_override_is_detected(self):
        with self.config.open('a') as f:
            f.write('set-environment -g PATH /usr/bin:/bin\n')
        with self.assertRaisesRegex(check.CheckError, 'overwrites PATH'):
            check.check_tmux(self.env)


if __name__ == '__main__':
    unittest.main()
