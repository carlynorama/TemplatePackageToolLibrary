# MyToolLibrary

The included file setup.swift will do these steps for you.

```
chmod +x setup.swift
./setup.swift all # will fetch repo
./setup.swift post # if have already cloned repo
```


For the official templates see:
See: https://github.com/apple/swift-package-manager/blob/main/Sources/Workspace/InitPackage.swift

## Get The Repo

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

## Strip it's history

```
rm -rf .git
```


## Set Up

### Update gitignore

There are some files currently ignored in the gitignore that allow for testing the template, but aren't typically included.

```
# REMOVE depending on your org's practice
.swiftpm
.vscode
Package.resolved
```

## Change The Names

"MyToolCLI" -> NewNameCLI
"MyToolLibrary" -> NewNamelLibrary


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

