#!/usr/bin/env swift

    //    chmod +x setup.swift
    //    ./setup.swift clone clean


import Foundation

let source = "https://github.com/carlynorama/TemplatePackageToolLibrary.git"
var target = ""
var newPrefix: String = ""

print("w00t! A New Project!")
let utilities = UtilityHandler()!

/// the very first element is the current script
let script = CommandLine.arguments[0]
print("Script:", script)

/// you can get the input arguments by dropping the first element
var inputArgs = CommandLine.arguments.dropFirst()

if inputArgs.contains("-f") {
    newPrefix = utilities.enclosingFolder
} else {
    print("Please enter new package name:")
        guard let tmpPrefix = readLine(strippingNewline: true) else {
            fatalError("Can't continue without a name.")
        }
        newPrefix = tmpPrefix
    if target.isEmpty {
        print("Create subfolder with this name? (alternative is to use this directory)")
        if let confirm = readLine(strippingNewline: true) {
            let affirmative = ["y", "Y", "yes", "YES"]
            if affirmative.contains(confirm) {
                target = newPrefix
            } else {
                print("I'm assuming '\(confirm)' meant you wanted to use this directory. ^C to abort. To avoid these messages, update the setup script.")
                target = "tmp"
            }
        } else {
            target = "tmp"
        }
    }
    
}


if inputArgs.contains("all") {
    inputArgs = ["clone", "gitclean", "rename", "setupclean", "init"]
}

if inputArgs.contains("post") {
    inputArgs = ["gitclean", "rename", "setupclean", "init"]
}



if target.isEmpty {
    target = "tmp"
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
        try utilities.replaceMyTool(with: newPrefix, in: target)
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

//MARK: tmp level up
if target == "tmp" {
    do {
        try utilities.moveToCurrentDirectory(from: target)
    } catch {
        fatalError("problem moving files due to \(error)")
    }   
}

//------------------------------------------------------------------------------
//MARK: clean up tmp


//--------------------------------------------------------------------------------------------------
//MARK: UtilityHandler
struct UtilityHandler {

    let shell:String
    let path:String
    let pwd:String

    let gitURL:URL

    var enclosingFolder:String {
        let index = pwd.lastIndex(of: "/")!
        return String(pwd.suffix(from: pwd.index(after: index)))
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

    public func replaceMyTool(with newName:String, in target:String) throws {
        let url = URL(fileURLWithPath: "\(target)")
        let files = try UtilityHandler.enumerateFiles(in: url)
        //print(files)
        for file in files {
            try UtilityHandler.replaceAllOccurrences(of:"MyTool", in:file, with: newName)
        }
    }

    public func moveToCurrentDirectory(from target:String) throws {
        let result = try UtilityHandler.privateShell("mv \(target)/{.,}* .; rm -rf \(target)", as: shell)
        print(result)
    }

    
//--------------------------------------------------------------------------------------------------
//MARK: UtilityHandler - static

    //not currently used in init script. 
    private static let git_guess = URL(fileURLWithPath: "/usr/bin/git")

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

    public static func enumerateFiles(in url:URL) throws -> [URL] {
        let fM = FileManager()
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
        print(environment)
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
        print(gitPath)
        self.gitURL =  URL(fileURLWithPath: gitPath.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}