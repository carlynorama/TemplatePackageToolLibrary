#!/usr/bin/env swift

//    chmod +x setup.swift
//    ./setup.swift clone clean

//TODO: Verify target is a valid target before continuing after clone / before git clean

import Foundation

let source = "https://github.com/carlynorama/TemplatePackageToolLibrary.git"
var target = ""
var newPrefix = ""
var commandArgs:[String] = [] //will provide defaults if none provided via args.


let helpText = """
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
"""

//Files that will be deleted by script.
var setupFiles = ["setup.swift", "SETUP.md"]

//UI Preferences
let affirmative = ["y", "Y", "yes", "YES"]
let negative = ["n", "N", "no", "NO"]
let abort = ["^C", "exit", "quit", "q", "e"]


//MARK: Initial Arg Checks
let script = CommandLine.arguments[0]
var inputArgs = CommandLine.arguments.dropFirst()

if checkForHelpRequest(in: inputArgs) {
    print()
    print(helpText)
    exit(0)
}

//MARK: Begin Template Transform
print("w00t! A New Project!")
let utilities = UtilityHandler()!
//------------------------------------------------------------------------------
//MARK: Name & Target Dir

//MARK: Use values from this script if set.
//TODO: What to put in target to force PWD? 
if !target.isEmpty || !newPrefix.isEmpty {
    print("Using hardcoded defaults")
    if target.isEmpty {

        if utilities.inDemoRepo {
            target = "\(utilities.pwd)/"
        } else {
            //creating a subfolder by default is safer.
            //but only makes sense if clone is going to happen.
            target = "\(utilities.pwd)/\(newPrefix)"
        }
        //TODO: hard coded forward slash flag
        
    } else if newPrefix.isEmpty {
        newPrefix = utilities.lastComponent(of: target)
    }
    print("Using name \(newPrefix) in directory \(target)")
    
    commandArgs = determineCommandSet(from: inputArgs)
}
//MARK: Prompt for needed information
else {
    let result = if inputArgs.isEmpty {
                    noArgumentsProvided()
                } else if (inputArgs.contains("clone") || inputArgs.contains("all")) {
                    downloadRequired(args: inputArgs)
                } else {
                    findOnDisk(args: inputArgs)
                }
    newPrefix = result.name
    target = result.destination
    commandArgs = result.commands
}

print("Using name:\(newPrefix)")
print("Targeting:\(target)")
print("Running:\(commandArgs)")

//------------------------------------------------------------------------------
//MARK: clone
if commandArgs.contains("clone") {
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
if commandArgs.contains("gitclean") {
    print("removing template's git traces...")
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
if commandArgs.contains("rename") {
    print("starting rename...")
    print("name:\(newPrefix) in directory:\(target)")
    
    do {
        try utilities.replace("MyTool", with: newPrefix, in: target)
    } catch {
        fatalError("name not full replaced due to \(error)")
    }
}

//------------------------------------------------------------------------------
//MARK: setupclean
if commandArgs.contains("setupclean") {
    print("removing template setup files...")
    do {
        try utilities.deleteSetupFiles(in: target)
    } catch {
        fatalError("problem removing setup files due to \(error)")
    }
}

//------------------------------------------------------------------------------
//MARK: tmp level up
if target == "tmp" {
    print("putting files in place...")
    do {
        try utilities.moveToCurrentDirectory(from: target)
    } catch {
        fatalError("problem moving files due to \(error)")
    }
}

//------------------------------------------------------------------------------
//MARK: init
if commandArgs.contains("init") {
    print("initialize fresh repo...")
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
        UtilityHandler.fM.fileExists(atPath: "Sources/MyToolCLI/MyToolCLI.swift")
    }
    
    
    public func clone(_ repo: String, to destination: String = "") throws {
        //try UtilityHandler.runPublicProcess(UtilityHandler.git_long, arguments: ["clone", repo, destination])
        try UtilityHandler.runPublicProcess(gitURL,
                                            arguments: ["clone", repo, destination],
                                            environment: ["PATH":path, "SHELL":shell]
        )
    }
    
    public func deleteGitFolder(in target: String) throws {
        //TODO: hard coded forward slash flag
        try UtilityHandler.privateShell("rm -rf \(target)/.git", as: shell)
    }
    
    public func deleteSetupFiles(in target: String) throws {
        for file in setupFiles {
            //TODO: hard coded forward slash flag
            try UtilityHandler.privateShell("rm -f \(target)/\(file)", as: shell)
        }
    }
    
    public func removeExtraGitIgnore(in target: String) throws {
        //FileManager.default.fileExists(atPath: "\(target)/.gitignore")
        //TODO: hard coded forward slash flag
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
        //TODO: hard coded forward slash flag
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


//--------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------
//MARK: Dialog Tree


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

func newTargetOrDie(try name:String) -> String {
    print(#"Create subfolder called "\#(name)"? (y or empty (to create directory), n (use this directory), or enter an alternate path)"#)
    if let confirm = readLine(strippingNewline: true) {
        
        checkForExitRequest(confirm, includeNegative: false)
        
        if affirmative.contains(confirm) { return name }
        else if negative.contains(confirm) { return "tmp" }
        
        else if !confirm.isEmpty {
            print("Assuming '\(confirm)' was an alternate path.")
            return pathHelper(confirm)
        }
        else {
            print("Making subdirectory")
            return name
        }
    } else {
        return name
    }
}


func pathHelper(_ input:String) -> String {
    if input.contains("../") {
        print(#"Sorry. I can't handle relative paths so well yet. Please try again entering a subpath or a full path."#)
        guard let tryAgain = readLine(strippingNewline: true) else {
            print(#"Can't continue without a repo location. Did you mean to use "./setup.swift all"?"#)
            exit(1)
        }
        checkForExitRequest(tryAgain)
        return tryAgain
    }
    return input
}

func determineCommandSet(from args:ArraySlice<String>) -> [String]  {
    if args.contains("all") {
        return ["clone", "gitclean", "rename", "setupclean", "init"]
    }

    if args.contains("post") {
       return ["gitclean", "rename", "setupclean", "init"]
    }
    return args.map { String($0) }
}

func noArgumentsProvided() -> (name:String, destination:String, commands:[String]) {
    if utilities.inDemoRepo {
        let dirName = utilities.enclosingFolder
        if dirName != "TemplatePackageToolLibrary" {
            let name = dirName
            let destination = "\(utilities.pwd)"
            print("Using defaults... \(newPrefix) for name operating in this folder.")
            let commands = !commandArgs.isEmpty ? commandArgs : ["gitclean", "rename", "setupclean", "init"]
            return (name, destination, commands)
        } else {
            print(#"Please rename the current folder to your desired new name or run "./setup.swift post" for more options"#)
            exit(1)
        }
    } else {
        print(#"I need a little more guidance.  Please rerun with "all" or "clone" to fetch a new copy of the repo, or "post" to select an already existing folder."#)
        exit(1)
    }
}

func downloadRequired(args:ArraySlice<String>) -> (name:String, destination:String, commands:[String]) {
    
    let commands = determineCommandSet(from: args)
    
    if utilities.inDemoRepo {
        print(#"seems like you've already downloaded the repo. Did you mean to run "./setup.swift post -f"?"#)
        exit(1)
    }
    
    if args.contains("-f") {
        return (utilities.enclosingFolder, "tmp", commands)
    } else {
        let name = getNameOrDie()
        return (name, newTargetOrDie(try: name), commands)
    }
}

func findOnDisk(args:ArraySlice<String>) -> (name:String, destination:String, commands:[String]) {
    
    let commands = determineCommandSet(from: args)
    
    if utilities.inDemoRepo {
        if args.contains("-f") {
            return (utilities.lastComponent(of: utilities.pwd), utilities.pwd, commands)
        }
        else {
            let name = getNameOrDie()
            return (name, newTargetOrDie(try: name), commands)
        }
    } else {
        print("Where is the repo you want me to update?")
        guard let tmpPath1 = readLine(strippingNewline: true) else {
            print(#"Can't continue without a repo. Did you mean to use "./setup.swift all"?"#)
            exit(1)
        }
        checkForExitRequest(tmpPath1)
        let destination = pathHelper(tmpPath1)
        let lastComponent = utilities.lastComponent(of: destination)
        
        if args.contains("-f") {
            return (lastComponent, destination, commands)
        }
        
        print("Did you want to use \(lastComponent) for the name? (y or empty for yes, n or exit to leave program, other response to use that for the name.)" )
        
        let nameResponse = readLine(strippingNewline: true)
        
        if let nameResponse {
            checkForExitRequest(nameResponse)
            if affirmative.contains(nameResponse) {
                return (lastComponent, destination, commands)
            } else if nameResponse.isEmpty {
                return (lastComponent, destination, commands)
            } else {
                return (nameResponse, destination, commands)
            }
        } else {
            return (lastComponent, destination, commands)
        }
    }
}

//------------------------------------------------------------------------------
//HELP

//WARNING - This will spew out help for all sorts of h leading input.
//Better to start permissive offering help when things are such a mess. 
func checkForHelpRequest(in args:ArraySlice<String>) -> Bool {
    //return true
    let sorted = args.sorted()
    for item in sorted {
        print(item)
        if let first = item.first  {
            switch first {
                case "h": return true
                //TODO: version that checks if --
                case "-": if item.contains("h") { return true } ; return false
                default: return false
            }
        }
    }
    return false
}

//--------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------
//MARK: Linux Support

#if os(Linux)

//https://github.com/apple/swift-corelibs-foundation/blob/36a411b304063de2cbd3fe06adc662e7648d5a9d/Sources/Foundation/URL.swift#L749
//also swift-foundation / Sources/FoundationEssentials/UTL+Stub.swift
//Should this be a #if !FOUNDATION_FRAMEWORK instead of if os(Linux)
//TODO: isDirectory one, too. 
extension URL {
    public func appending(component:String) -> Self {
        self.appendingPathComponent(path)
    }

    mutating public func append(component:String) {
        self.appendPathComponent(component)
    }

    public init(filePath:String) {
        //TODO: This force unwrap isn't great.
        self = .init(string:filePath)!
    }
}

#endif