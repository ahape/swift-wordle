import Foundation
import AppKit

struct Config : Decodable {
    let answers: [String]
    let others: [String]
    var allWords: [String]? {
        get {
            return self.answers + self.others
        }
    }
}

class Wordle {
    private let cal = Calendar(identifier: .gregorian)
    private var startDate: Date { 
        get { 
            return self.cal.date(from: DateComponents(year: 2021, month: 6, day: 19))! 
        } 
    }
    let maxTries = 6
    let wordLen = 5
    var tries = 0
    var solved = false
    var config: Config!
    var answer: String!
    var wordleNum: Int!
    var shareText = ""

    public init() throws {
        try self.loadConfig()
        self.loadAnswer()
    }

    public func start() {
        print("""
This is Wordle. Enter the correct \(self.wordLen) letter word. You have \(self.maxTries) tries
""")

        while self.tries < self.maxTries && !self.solved {
            let word = (readLine() ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            if word == self.answer {
                self.colorizedResponse(word)
                self.solved = true
            } else if self.config.allWords!.contains(word) {
                self.colorizedResponse(word)
                self.tries += 1
                print("\(self.maxTries - self.tries) tries left. Guess again")
            } else if word.count != self.wordLen {
                print("Your word has to be \(self.wordLen) letters. Guess again")
            } else {
                print("Not a valid word. Guess again")
            }
        }

        if self.solved {
            print("You did it!")
        } else {
            print("You suck")
        }

        self.printShareText()
    }

    private func loadAnswer() {
        let todayDate = self.cal.startOfDay(for: Date.now)
        let daysSinceStart = self.cal.dateComponents([.day], from: self.startDate, to: todayDate).day!
        
        self.wordleNum = daysSinceStart
        self.answer = self.config.answers[daysSinceStart]
    }

    private func loadConfig() throws {
        let contents = try NSString(
            contentsOfFile: "./words.json",
            encoding: String.Encoding.ascii.rawValue) as String
        let jsonData = contents.data(using: .utf8)!

        self.config = try! JSONDecoder().decode(Config.self, from: jsonData)
    }

    private func colorizedResponse(_ word: String) {
        let (normalText, normalEmoji) = ("\u{001B}[0;37m", "\u{2B1C}")
        let (greenText, greenEmoji) = ("\u{001B}[0;32m", "\u{0001f7e9}")
        let (yellowText, yellowEmoji) = ("\u{001B}[0;33m", "\u{0001f7e8}")
        let (wordArr, answerArr) = (Array(word), Array(self.answer))
        var text = ""

        for i in 0..<word.count {
            let char = wordArr[i]
            if char == answerArr[i] {
                self.shareText += greenEmoji
                text += greenText + char.uppercased() + normalText
            } else if answerArr.contains(char) {
                self.shareText += yellowEmoji
                text += yellowText + char.uppercased() + normalText
            } else {
                self.shareText += normalEmoji
                text += char.uppercased()
            }
        }

        self.shareText += "\n"

        print("===> \(text)")
    }

    private func printShareText() {
        print("\nYour shareable results have been copied to the clipboard")

        self.shareText = """
Wordle \(self.wordleNum!) \(self.tries < self.maxTries ? String(self.tries + 1) : "X")/\(self.maxTries)


""" + self.shareText

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(self.shareText, forType: .string)
    }
}

try Wordle().start()
