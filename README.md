# macOS Setup Guide

## Installation
Based on James Jingyi's [setup](https://jamesjingyi.notion.site/How-I-set-up-my-Mac-141c522194a480908a5cd3b07391d17f)

## 1 - Install apps

### 1.1 - Install Homebrew

Install Homebrew using the following command:

```bash
/bin/bash -c "$(curl -fsSL <https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh>)"
```

### **1.2** - Install packages

### **1.2.1** - Brewfile placement

Place the `Brewfile` (which you downloaded from here, or created yourself) in your `/usr/` directory — you can get here in Finder by selecting `Go` > `Go to Folder...` (or pressing `⌘` + `⇧` + `G`) and typing `~/`. Terminal should launch here by default.

### **1.2.2** - Installation

Open Terminal and run the following command:

```bash
brew bundle install
```

(If you have your `Brewfile` in a different location, you can specify this by running `brew bundle install /path/to/Brewfile`)

## 2 - Settings

### 2.1 - System Preferences

todo

### 2.2 - Preinstalled Apps

todo

### 2.3 - Replacing default macOS functions

#### 2.3.1 - Raycast

Use the rayconfig file to setup aliases and extensions.

#### 2.3.2 - Shottr

I use `Shottr` instead of macOS’s built in screenshot utility.

Since I want it to replace the default screenshots in macOS, I set it up to:

* Fullscreen screenshot: `shift + command + 3`
* Area screenshot: `shift + command + 4`
* Instant Text/QR Recognition: `shift + command + 2`
