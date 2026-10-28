"""Exercise a Linux config install without package managers or network."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class LinuxInstallTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='dotfiles install ')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.repo = self.root / 'repo'
        shutil.copytree(ROOT, self.repo, ignore=shutil.ignore_patterns('.git', '__pycache__'))
        self.home = self.root / 'home'
        self.home.mkdir()
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        for name, body in {
            'uname': 'echo Linux',
            'defaults': 'echo MAC_PREFS_CALLED >&2; exit 98',
            'fish': '''case "$*" in
                *"fisher list"*) echo acomagu/fish-async-prompt ;;
                *"fisher remove"*) printf 'rewritten by Fisher\\n' > "$HOME/.config/fish/fish_plugins" ;;
            esac''',
        }.items():
            p = self.bin / name
            p.write_text('#!/bin/sh\n' + body + '\n')
            p.chmod(0o755)
        check = self.repo / 'scripts/check-install.sh'
        check.write_text('#!/bin/sh\necho CHECKED_INTERACTIVE_INSTALL\n')
        check.chmod(0o755)
        self.env = dict(os.environ, HOME=str(self.home), SHELL='/bin/sh', PATH=f'{self.bin}:/usr/bin:/bin')

    def install(self, stdin=None):
        result = subprocess.run(['/bin/bash', str(self.repo / 'install.sh'), '--skip-deps', '--no-tmux', '--shell', '/bin/sh'], env=self.env, text=True, capture_output=True, input=stdin)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('CHECKED_INTERACTIVE_INSTALL', result.stdout)
        return result

    def test_linux_links_shared_appearance_preserves_git_and_private_prompt(self):
        git = self.home / '.gitconfig'
        git.write_text('[user]\nname = Existing Author\n')
        private = self.home / '.config/dotfiles/starship.local.toml'
        private.parent.mkdir(parents=True)
        private.write_text('[hostname.aliases]\nprivate-test-host = "private-test-name"\n')
        self.install()
        self.assertIn('Existing Author', git.read_text())
        for dest in ('fish/config.fish', 'fish/colors.fish', 'lsd/config.yaml'):
            self.assertTrue((self.home / '.config' / dest).is_symlink())
        self.assertIn('private-test-host', (self.home / '.config/starship.toml').read_text())
        self.assertNotIn('private-test-host', (self.repo / 'starship.toml').read_text())
        before = (self.home / '.config/starship.toml').stat().st_mtime_ns
        self.install()
        self.assertEqual(before, (self.home / '.config/starship.toml').stat().st_mtime_ns)
        self.assertFalse((self.home / 'Library').exists())

    def test_fisher_does_not_consume_automation_stdin(self):
        fish = self.bin / 'fish'
        fish.write_text("""#!/bin/sh
case "$*" in
    *"fisher update"*|*"fisher remove"*)
        if read -r line; then echo "FISHER_CONSUMED_SCRIPT:$line" >&2; exit 98; fi ;;
esac
exit 0
""")
        self.install(stdin='echo next automation step\n')

    def test_fisher_cannot_rewrite_repo_through_legacy_manifest_link(self):
        manifest = self.repo / 'fish/fish_plugins'
        before = manifest.read_bytes()
        runtime = self.home / '.config/fish/fish_plugins'
        runtime.parent.mkdir(parents=True)
        runtime.symlink_to(manifest)
        self.install()
        self.assertEqual(before, manifest.read_bytes())
        self.assertFalse(runtime.is_symlink())
        self.assertIn('patrickf1/fzf.fish@v10.3', runtime.read_text())


if __name__ == '__main__':
    unittest.main()
