# TemplatePackageToolLibrary

This repo is a template package repo that can be used as a starter Swift Package Manager project.

There are some steps required before you should use it for your own project. 

The included setup.swift file will do these steps for you. You can grab it first and have it download the repository for you or wait to run it after. 

No need to compile, but you'll need to give it proper permission to work. 

```
cd $DIRECTORY_WITH_SCRIPT
chmod +x setup.swift
```

Running options:

```
./setup.swift all # will fetch a new copy of the repo
./setup.swift post # if have already cloned repo
```

Add the `-f` flag with either of the above option if you'd like to automate using the current folder as location and name.  

Each step can also be run one by one by hand:

```
OVERVIEW: A script for preparing a template repository for use

USAGE: ./setup.swift [-f] [[all | post] | [other options]]

OPTIONS:
    -f            Bypass prompts to detect vars from PWD
    all           Runs every command.
    post          Runs every command after clone.
    clone         Downloads the repo in 'source'  
    gitclean      Removes connection to template repo, etc. 
    rename        Replaces phrase MyTool with 'newPrefix' 
    setupclean    Removes files listed in 'setupFiles' 
    init          Initializes a new git repo, makes first commit
```

Note For the official templates see:
- https://github.com/apple/swift-package-manager/blob/main/Sources/Workspace/InitPackage.swift

## Steps To Prepare Repo 

### Get Repo

Using the GitHub tools

```
gh repo clone carlynorama/TemplatePackageToolLibrary
```

Using git, example shows cloning it the directory you're in

```
TODO - TEST AND FIX
git clone https://myrepo.com/git.git temp
mv temp/.git code/.git
rm -rf temp
```

### Strip it's relationship to parent repo

#### Remove git

```
rm -rf .git
```

#### Remove misc from .gitignore

There are some files currently ignored in the gitignore that allow for testing the template, but aren't typically included.

```
# REMOVE depending on your org's practice
.swiftpm
.vscode
Package.resolved
```

### Change The Names

"MyToolCLI" -> NewNameCLI  
"MyToolLibrary" -> NewNamelLibrary

In every file name, directory name and all content. 

### Delete setup related files

There's an array of file names. Right now it's just 

- `setup.swift`
- `SETUP.md`

### First Commit
```
## Recommended Git Alias
git config --global alias.start-repo '!git init . && git add . && git commit --allow-empty -m "Initialize repository"'
```

```
## Otherwise
git init . 
git add . 
git commit --allow-empty -m "Initialize repository"
```