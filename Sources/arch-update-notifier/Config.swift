import Foundation
import Yams

struct Config: Codable {
    var checkRepoUpdatesCommand: String = "/usr/bin/checkupdates"
    var checkAURUpdatesCommand: String = "/usr/bin/yay -Qua"
    var updateRepoCommand: String = "/usr/bin/ghostty -e /usr/bin/sudo pacman -Syu"
    var updateAllCommand: String = "/usr/bin/ghostty -e /usr/bin/yay --sudoloop"
    var checkUpdateInterval: Int = 1800

    static func load(from filePath: String) throws -> Config {
        if !FileManager.default.fileExists(atPath: filePath) {
            let conf = Config()
            let encode = YAMLEncoder()
            let yaml = try encode.encode(conf)
            try yaml.write(toFile: filePath, atomically: true, encoding: .utf8)
            return conf
        }
        let yaml = try String(contentsOfFile: filePath, encoding: .utf8)
        let decode = YAMLDecoder()
        return try decode.decode(Config.self, from: yaml)
    }
}
