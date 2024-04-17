#!/usr/bin/env swift

//    chmod +x setup.swift
//    ./setup.swift clone clean

//TODO: n response confusing
//TODO: Filenames not updated yet.

import Foundation

let source = "https://github.com/carlynorama/TemplatePackageToolLibrary.git"
var target = ""
var newPrefix: String = ""

let affirmative = ["y", "Y", "yes", "YES"]
let negative = ["n", "N", "no", "NO"]
let abort = ["^C", "exit", "quit", "q", "e"]

print("w00t! A New Project!")
let utilities = UtilityHandler()!

/// the very first element is the current script
let script = CommandLine.arguments[0]

/// you can get the input arguments by dropping the first element
var inputArgs = CommandLine.arguments.dropFirst()

//------------------------------------------------------------------------------
//MARK: Name & Target Dir

//MARK: Use values from this script if set.
//TODO: does not currently include the setting of default argument set?
if !target.isEmpty || !newPrefix.isEmpty {
    print("Using hardcoded defaults")
    if target.isEmpty {
        //creating a subfolder by default is safer.
        target = "\(utilities.pwd)/newPrefix"
    } else if newPrefix.isEmpty {
        newPrefix = utilities.lastComponent(of: target)
    }
    print("Using name \(newPrefix) in directory \(target)")
}
//MARK: Prompt for needed information
else {
    //MARK: no arguments
    if inputArgs.isEmpty {
        if utilities.inDemoRepo {
            let dirName = utilities.enclosingFolder
            if dirName != "TemplatePackageToolLibrary" {
                newPrefix = dirName
                target = "\(utilities.pwd)"
                print("Using defaults... \(newPrefix) for name operating in this folder.")
                inputArgs = ["gitclean", "rename", "setupclean", "init"]
            } else {
                print(#"Please rename the current folder to your desired new name or run "./setup.swift post" for more options"#)
                exit(1)
            }
        } else {
            print(#"I need a little more guidance.  Please rerun with "all" or "clone" to fetch a new copy of the repo, "post" to select an already existing folder."#)
            exit(1)
        }
    //MARK: clone & all path
    } else if (inputArgs.contains("clone") || inputArgs.contains("all")) {
        
        if utilities.inDemoRepo {
            print(#"seems like you've already downloaded the repo. Did you mean to run "./setup.swift post -f"?"#)
            exit(1)
        }
        if inputArgs.contains("-f") {
            newPrefix = utilities.enclosingFolder
            target = "tmp"
        } else {
            newPrefix = getNameOrDie()
            if target.isEmpty {
                print(#"Create subfolder called "\#(newPrefix)"? (y, n (use this directory), alternate path)"#)
                if let confirm = readLine(strippingNewline: true) {
                    
                    checkForExitRequest(confirm, includeNegative: false)
                    
                    if affirmative.contains(confirm) {
                        target = newPrefix }
                    else if negative.contains(confirm) {
                        target = newPrefix }
                    else if !confirm.isEmpty {
                        print("Assuming '\(confirm)' was an alternate path. ^C to abort. To avoid these messages, update the setup script.")
                        target = confirm}
                    else {
                        print("Final files will be in this directory. ^C to abort. To avoid these messages, update the setup script.")
                        target = "tmp"
                    }
                } else {
                    target = "tmp"
                }
            }
        }
    //MARK: no new download path
    } else {
        if utilities.inDemoRepo {
            target = "\(utilities.pwd)"
            if inputArgs.contains("-f") {
                newPrefix = utilities.lastComponent(of: target)
            }
            else {
                newPrefix = getNameOrDie()
            }
        } else {
            print("Where is the repo you want me to update?")
            guard let tmpPath1 = readLine(strippingNewline: true) else {
                print(#"Can't continue without a repo. Did you mean to use "./setup.swift all"?"#)
                exit(1)
            }
            
            checkForExitRequest(tmpPath1)
            
            if tmpPath1.contains("../") {
                print(#"Sorry. I can't handle relative paths so well yet. Please try again entering a subpath or a full path."#)
                guard let tmpPath2 = readLine(strippingNewline: true) else {
                    print(#"Can't continue without a repo. Did you mean to use "./setup.swift all"?"#)
                    exit(1)
                }
                checkForExitRequest(tmpPath2)
                target = tmpPath2
            } else {
                target = tmpPath1
            }
            
            newPrefix = getNameOrDie()
            
        }
    }
}


func checkForExitRequest(_ input:String, includeNegative:Bool = true) {
    if abort.contains(input) || (includeNegative && negative.contains(input)) {
        print("Seems like you don't want to continue.")
        exit(1)
    }
}

func getNameOrDie() -> String {
    print("Please enter new package name. Press enter to use directory name or type exit to leave the program.")
    let tmpPrefix = readLine(strippingNewline: true)
    
    if let tmpPrefix {
        checkForExitRequest(tmpPrefix)
        if !tmpPrefix.isEmpty {
            return tmpPrefix
        } else {
            return utilities.enclosingFolder
        }
    } else {
        return utilities.enclosingFolder
    }
}

//------------------------------------------------------------------------------
//MARK: What am I doing?
if inputArgs.contains("all") {
    inputArgs = ["clone", "gitclean", "rename", "setupclean", "init"]
}

if inputArgs.contains("post") {
    inputArgs = ["gitclean", "rename", "setupclean", "init"]
}

//------------------------------------------------------------------------------
//MARK: clone
if inputArgs.contains("clone") {
    print("fetching repo...")
    do {
        try utilities.clone(source, to: target)
    } catch {
        print("failed download")
        fatalError("Template not downloadable due to \(error)")
    }
}

//------------------------------------------------------------------------------
//MARK: gitclean
if inputArgs.contains("gitclean") {
    do {
        try utilities.removeExtraGitIgnore(in: target)
    } catch {
        fatalError("gitignore update failed due to: \(error)")
    }
    
    do {
        try utilities.deleteGitFolder(in: target)
    } catch {
        fatalError("git folder not deleted due to \(error)")
    }
}

//------------------------------------------------------------------------------
//MARK: rename
if inputArgs.contains("rename") {
    print("\(newPrefix) in \(target)")
    
    do {
        try utilities.replace("BunnyBunny", with: newPrefix, in: target)
    } catch {
        fatalError("name not full replaced due to \(error)")
    }
}

//------------------------------------------------------------------------------
//MARK: setupclean
if inputArgs.contains("setupclean") {
    do {
        try utilities.deleteSetupFiles(in: target)
    } catch {
        fatalError("problem removing setup files due to \(error)")
    }
}

//------------------------------------------------------------------------------
//MARK: tmp level up
if target == "tmp" {
    do {
        try utilities.moveToCurrentDirectory(from: target)
    } catch {
        fatalError("problem moving files due to \(error)")
    }
}

//------------------------------------------------------------------------------
//MARK: init
if inputArgs.contains("init") {
    let repoDir =  target == "tmp" ? "." : target
    do {
        try utilities.initializeRepo(at: repoDir)
    } catch {
        fatalError("couldn't init due to \(error)")
    }
}

//--------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------
//MARK: UtilityHandler
struct UtilityHandler {
    
    let shell:String
    let path:String
    let pwd:String
    
    let gitURL:URL
    
    var enclosingFolder:String {
        lastComponent(of: pwd)
    }
    
    func lastComponent(of path:String) -> String {
        let url = URL(filePath: path)
        return url.lastPathComponent
    }
    
    var inDemoRepo:Bool {
        UtilityHandler.fM.fileExists(atPath: "Sources/BunnyBunnyCLI/BunnyBunnyCLI.swift")
    }
    
    
    public func clone(_ repo: String, to destination: String = "") throws {
        //try UtilityHandler.runPublicProcess(UtilityHandler.git_long, arguments: ["clone", repo, destination])
        try UtilityHandler.runPublicProcess(gitURL,
                                            arguments: ["clone", repo, destination],
                                            environment: ["PATH":path, "SHELL":shell]
        )
    }
    
    public func deleteGitFolder(in target: String) throws {
        try UtilityHandler.privateShell("rm -rf \(target)/.git", as: shell)
    }
    
    public func deleteSetupFiles(in target: String) throws {
        try UtilityHandler.privateShell("rm -f \(target)/SETUP.md", as: shell)
        try UtilityHandler.privateShell("rm -f \(target)/setup.swift", as: shell)
    }
    
    public func removeExtraGitIgnore(in target: String) throws {
        //FileManager.default.fileExists(atPath: "\(target)/.gitignore")
        let url = URL(fileURLWithPath: "\(target)/.gitignore")
        try UtilityHandler.trimFrom("#", in: url)
    }
    
    public func replace(_ phrase:String, with newPhrase:String, in target:String) throws {
        let url = URL(fileURLWithPath: "\(target)")
        let files = try UtilityHandler.enumerateFiles(in: url)
        //print(files)
        for file in files {
            try UtilityHandler.replaceAllOccurrences(of:phrase, in:file, with: newPhrase)
        }
        
        let items = try UtilityHandler.enumerateToRename(in: url, pathContains:phrase)
        for file in items.files {
            let newFileName = file.lastPathComponent.replacingOccurrences(of: phrase, with: newPhrase)
            try UtilityHandler.rename(at: file, to: newFileName)
        }
        for directory in items.directories {
            let newDirName = directory.lastPathComponent.replacingOccurrences(of: phrase, with: newPhrase)
            try UtilityHandler.rename(at: directory, to: newDirName)
        }
    }
    
    public func moveToCurrentDirectory(from target:String) throws {
        let result = try UtilityHandler.privateShell("mv \(target)/{.,}* .; rm -rf \(target)", as: shell)
        print(result)
    }
    
    //TODO: figure out what's going wrong...
    // public func moveToCurrentDirectory(from target:String) throws {
    //     let cwdURL =  URL(fileURLWithPath: pwd)
    //     print(cwdURL)
    //     let src = cwdURL.appending(component: target)
    //     print(src)
    //     try UtilityHandler.fM.moveItem(at:src, to:cwdURL)
    // }
    
    public func initializeRepo(at repo:String) throws {
        do {
            if repo == "." {
                let initString = #"git init . ; git add -- . :!setup.swift ; git commit --allow-empty -m "Initialize repository""#
                try UtilityHandler.privateShell(initString, as: shell)
            } else {
                let initString = #"cd \#(target); git init . ; git add . ; git commit --allow-empty -m "Initialize repository""#
                try UtilityHandler.privateShell(initString, as: shell)
            }
        } catch {
            fatalError("repo did not init correctly")
        }
    }
    
    
    //--------------------------------------------------------------------------------------------------
    //MARK: UtilityHandler - static
    
    //not currently used in init script, but if can't assume which, hard coding is an option.
    //private static let git_guess = URL(fileURLWithPath: "/usr/bin/git")
    private static let fM = FileManager.default
    
    public static func replaceAllOccurrences(of toReplace:String, in url:URL, with replacement:String) throws {
        guard url.isFileURL else {
            print("\(url) is not a file.")
            return
        }
        let string = try String(contentsOf: url)
        let newFile = string.replacingOccurrences(of: toReplace, with: replacement)
        try newFile.write(to: url, atomically: true, encoding: .utf8)
    }
    
    public static func trimFrom(_ char:String.Element, in url:URL) throws {
        let string = try String(contentsOf: url)
        guard let index = string.lastIndex(of: char) else{
            //TODO: throw instead.
            fatalError("file didn't have the right content to remove.")
        }
        let newFile = string.prefix(upTo: index)
        try newFile.write(to: url, atomically: true, encoding: .utf8)
    }
    
    public static func rename(at srcURL:URL, to newName:String) throws {
        var tmp = srcURL.deletingLastPathComponent()
        //TODO: FLAG - did not work fo maartene?
        tmp.append(component: newName)
        try fM.moveItem(at: srcURL, to: tmp)
    }
    
    public static func enumerateFiles(in url:URL) throws -> [URL] {
        guard let enumerator = fM.enumerator(at: url,
                                             includingPropertiesForKeys: [.isDirectoryKey],
                                             options: [.skipsHiddenFiles])
        else {
            //TODO: throw
            fatalError("no files")
        }
        var files:[URL] = []
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey]),
                  let isDirectory = resourceValues.isDirectory else {
                //TODO: throw
                fatalError("no resource value")
            }
            guard !isDirectory else {
                continue
            }
            
            files.append(fileURL)
        }
        
        return files
        
    }
    
    public static func enumerateDirectories(in url:URL, pathContains:String? = nil) throws -> [URL] {
        guard let enumerator = fM.enumerator(at: url,
                                             includingPropertiesForKeys: [.isDirectoryKey],
                                             options: [.skipsHiddenFiles])
        else {
            //TODO: throw
            fatalError("no files")
        }
        var folders:[URL] = []
        for case let dirURL as URL in enumerator {
            guard let resourceValues = try? dirURL.resourceValues(forKeys: [.isDirectoryKey]),
                  let isDirectory = resourceValues.isDirectory else {
                //TODO: throw
                fatalError("no resource value")
            }
            guard isDirectory else {
                continue
            }
            if let pathContains {
                if dirURL.absoluteString.contains(pathContains)  {
                    folders.append(dirURL)
                }
            } else {
                folders.append(dirURL)
            }
        }
        
        return folders
        
    }
    
    public static func enumerateToRename(in url:URL, pathContains:String) throws -> (files:[URL], directories:[URL]) {
        guard let enumerator = fM.enumerator(at: url,
                                             includingPropertiesForKeys: [.isDirectoryKey],
                                             options: [.skipsHiddenFiles])
        else {
            //TODO: throw
            fatalError("no files")
        }
        var files:[URL] = []
        var directories:[URL] = []
        for case let candidateURL as URL in enumerator {
            guard let resourceValues = try? candidateURL.resourceValues(forKeys: [.isDirectoryKey]),
                  let isDirectory = resourceValues.isDirectory else {
                //TODO: throw
                fatalError("no resource value")
            }
            
            if candidateURL.absoluteString.contains(pathContains)  {
                if isDirectory {
                    directories.append(candidateURL)
                } else {
                    files.append(candidateURL)
                }
            }
        }
        
        return (files, directories)
        
    }
    
    
    
    //--------------------------------------------------------------------------------------------------
    //MARK: Process and Shell
    public static func runPublicProcess(_ url:URL,
                                        arguments:[String] = [],
                                        environment:Dictionary<String,String> = [:]
    ) throws {
        let process = Process()
        process.arguments = arguments
        process.executableURL = url
        if !environment.isEmpty {
            process.environment = environment
        }
        try process.run()
        process.waitUntilExit()
    }
    
    @discardableResult
    public static func runPrivateProcess(_ url:URL,
                                         arguments:[String] = [],
                                         environment:Dictionary<String,String> = [:]
    ) throws -> String {
        let process = Process()
        let pipe = Pipe()
        
        if !environment.isEmpty {
            process.environment = environment
        }
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.arguments = arguments
        
        process.standardInput = nil
        process.executableURL = url
        try process.run()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        
        process.waitUntilExit()
        
        if process.terminationStatus == 0 || process.terminationStatus == 2 {
            return output
        } else {
            print(output)
            throw CommandError.unknownError(exitCode: process.terminationStatus)
        }
    }
    
    @discardableResult
    public static func  privateShell(_ command: String, as shellPath:String, environment:Dictionary<String,String> = [:]) throws -> String {
        let process = Process()
        let pipe = Pipe()
        
        if !environment.isEmpty {
            process.environment = environment
        }
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.arguments = ["-c", command]
        
        process.standardInput = nil
        process.executableURL = URL(fileURLWithPath: shellPath)
        
        try process.run()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        
        process.waitUntilExit()
        
        if process.terminationStatus == 0 || process.terminationStatus == 2 {
            return output
        } else {
            print(output)
            throw CommandError.unknownError(exitCode: process.terminationStatus)
        }
    }
    
    enum CommandError: Error {
        case unknownError(exitCode: Int32)
    }
    //--------------------------------------------------------------------------------------------------
}

//--------------------------------------------------------------------------------------------------
//MARK: UtilityHandler - Environment Reading Init
extension UtilityHandler {
    init?() {
        let info = ProcessInfo.processInfo
        let environment = info.environment
        //print(environment)
        self.shell = environment["SHELL"]!
        self.path = environment["PATH"]!
        self.pwd = environment["PWD"]!
        guard let gitPath = try? UtilityHandler.privateShell("which git", as: shell) else {
            print("please manually update the script with your git path")
            return nil
        }
        guard !gitPath.contains("not found") else {
            print("please install git")
            return nil
        }
        self.gitURL =  URL(fileURLWithPath: gitPath.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
