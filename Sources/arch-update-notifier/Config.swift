import Foundation

struct Config {
    var checkRepoCommand: String = "/usr/bin/checkupdates"
    var checkAURCommand: String = "/usr/bin/yay -Qua"
    var updateRepoCommand: String = "/usr/bin/ghostty -e /usr/bin/sudo pacman -Syu"
    var updateCommand: String = "/usr/bin/ghostty -e /usr/bin/yay --sudoloop"
    var checkUpdateInterval: Int = 1800

    static func load(from filePath: String) throws -> Config {
        var conf = Config()
        let ini: String
        if FileManager.default.fileExists(atPath: filePath) {
            ini = try String(contentsOfFile: filePath, encoding: .utf8)
        } else {
            print("No config found! creating a default one at \(filePath)")
            ini = """
            checkRepoCommand = \(conf.checkRepoCommand)
            checkAURCommand = \(conf.checkAURCommand)
            updateRepoCommand = \(conf.updateRepoCommand)
            updateCommand = \(conf.updateCommand)
            checkUpdateInterval = \(conf.checkUpdateInterval)
            """
            try ini.write(toFile: filePath, atomically: true, encoding: .utf8)
            return conf
        }
        let decode = decode(ini)
        conf.checkRepoCommand = decode["checkRepoCommand"] ?? conf.checkRepoCommand
        conf.checkAURCommand = decode["checkAURCommand"] ?? conf.checkAURCommand
        conf.updateRepoCommand = decode["updateRepoCommand"] ?? conf.updateRepoCommand
        conf.updateCommand = decode["updateCommand"] ?? conf.updateCommand
        conf.checkUpdateInterval = Int(decode["checkUpdateInterval"] ?? "") ?? 1800

        return conf
    }

    private static func decode(_ str: String) -> [String:String] {
        str.split(separator: "\n").reduce(into: [String: String]()) { acc, elem in
            let split = elem.split(separator: "=").map(String.init)
            acc[split[0]] = split[1]
        }
    }
}
