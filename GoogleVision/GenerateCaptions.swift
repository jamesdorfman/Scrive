//
//  GenerateCaptions.swift
//  GoogleVision
//
//  Created by James Dorfman on 2017-07-06.
//  Copyright © 2017 James Dorfman. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class GenerateCaptions{
    private var _GLabels: [String]!
    private var _GScores: [CGFloat]!
    
    private var _jokeScore: [Int]!
    private var _jokeContent: [String]!
    private var _quoteScore: [Int]!
    private var _quoteContent: [String]!
    private var _faceCount: Int!
    private var _smiling: Bool!
    private var oneLiners = Dictionary<String,Int>()
 //String #1 is the joke of the joke, int #2 is the amount of time it came up through the different label searches
    //Improvement, use the int ID? Would this make it quicker?
    
    private var imgType: String{
        get{
            if _faceCount > 1{
                return "group"
            }
            else if _faceCount == 1{
                return "self"
            }
            else{
                return "none" //THIS WILL NEVER BE CALLED
            }
        }
    }
    
    private var IDsForTesting = [0,0,0]
    init(GLabels: [String], GScores: [CGFloat], faceCount: Int, smiling: Bool!){
        self._GLabels = GLabels
        self._GScores = GScores
        self._faceCount = faceCount
        self._smiling = smiling
    }
    
    func generateQuotes() -> [String]{
        var labels = self._GLabels!
        var scores = self._GScores!
        
        var labelData = Dictionary<String,[Int]>()
        var quoteData = Dictionary<String,Double>()
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let indexFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "QuoteWord")
        let quoteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Quote")

        var scoreList = [Int]()
        
        for i in 0...labels.count-1{
            scoreList.append(labels.count-1-i)
        }
        
        var indecesToRemove:[Int] = []
        for i in 0 ... labels.count-1{
            let label = labels[i]
            do{
                print("index for \(label)")
                indexFetch.predicate = NSPredicate(format: "word==%@",label)
                print("post predicate")
                var lines = try context.fetch(indexFetch) as! [QuoteWord]
                print("here")
                let emptyArray: [QuoteWord] = []
                print("are they equal? \(lines != emptyArray)")
                if lines != emptyArray{
                    print("lines count is \(lines.count)")
                    let line = lines[0]
                    var indeces: [Int] = []
                    let stringIndeces = line.ids!.components(separatedBy: " ")
                    for strInd in stringIndeces{
                        indeces.append(Int(strInd)!)
                    }
                    print("labelData[\(line.word!)] = \(indeces)")
                    labelData[line.word!] = Array(Set(indeces))
                } else{
                    print("im in here doc")
                    indecesToRemove.append(i)
                    print("im out here doc")
                }
            } catch{
                print("error in getting joke indeces")
            }
        }
        print("i left \(indecesToRemove)")
        indecesToRemove.sort{ $1 < $0 }
        print("post sort \(indecesToRemove)")
        for index in indecesToRemove{
            labels.remove(at: index)
            scores.remove(at: index)
        }
        
        var labelMultiples: [Int] = []
        for i in 0 ... labels.count-1{
            labelMultiples.append(i)
        }
        
        //We want to rate the earlier labels higher, because they are more accurate (that's the way that google sorts them
        for i in 0...labels.count-1{
            let label = labels[i]
            let gScore = scores[i]
            
            do{
                let idList = labelData[label]!
                var convertedIdList: [NSNumber] = []
                for elem in idList{
                    convertedIdList.append(NSNumber(value: elem))
                }
                print("before predicate")
                quoteFetch.predicate = NSPredicate(format: "id IN %@",  convertedIdList) //make sure its not part of a word, just the actual word with a space on each sideactual word with a space on each side
                //check for " label" and "label " in both the tags and the text
                let fetchedLines = try context.fetch(quoteFetch) as! [Quote]
                print("After predicate")
                for quote in fetchedLines{
                    var text = quote.text!
                    let regex = try! NSRegularExpression(pattern: "([a-z])([A-Z])") //<-Use capturing, `([a-z])`->$1, `([A-Z])`->$2
                    text = regex.stringByReplacingMatches(in: text, range: NSRange(0..<text.utf16.count), withTemplate: "$1. $2") //<- Use `$1`, `$2`... as reference to capture groups
                    var score = quote.score
                    if text.characters.count < 300 && text.lowercased().contains("potter") == false{
                        print("quoteData[\(text)] = \(Double(score)) * \(Double(labelMultiples[i]))")
                        quoteData[text] = Double(score) * Double(labelMultiples[i])
                    }
                }
            } catch{
                print("error with CoreData quote fetch")
            }
        }
        if quoteData.count > 0{
            var bestQuotes: [String] = []
            return bestRatedCaptions(data: quoteData)
        }
        return ["Looks like we weren't able to generate this type of caption for your image... \nPlease try again with another image"]
    }
    
    /*                    for i in 0 ... text.characters.count - 1{
     let curChar = text[i]
     var prevChar = ""
     if i > 0 && i < text.characters.count - 1{
     prevChar = text[i-1]
     if curChar.lowercased() != curChar && prevChar.lowercased() == prevChar && prevChar != " " && prevChar.contains("?") == nil && prevChar.contains("!") == nil {
     print(" in here")
     text = " \(text.substring(to: i)). \(curChar)\(text.substring(from: i+1))"
     }
     } else{
     //pass
     }
     }*/
    
    func generateRedditJokes() -> [String]{
        print("i entered reddit jokes")
        let labels = self._GLabels!
        let scores = self._GScores!
        
        var labelData = Dictionary<String,[Int]>()
        var jokeDatas: [Dictionary<String,Double>] = [] // [<jokeContent, jokeScore>]
        
        for i in 0 ... labels.count-1{
            jokeDatas.append(Dictionary<String,Double>())
        }

        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let indexFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "JokeWord")
        let jokeFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "RedditJoke")
        
        print("getting indexes")
        for label in labels{
            do{
                print("index for \(label)")
                indexFetch.predicate = NSPredicate(format: "word==%@",label)
                var lines = try context.fetch(indexFetch) as! [JokeWord]
                if lines.count > 0{
                    let line = lines[0]
                    var indeces: [Int] = []
                    let stringIndeces = line.ids!.components(separatedBy: " ")
                    for strInd in stringIndeces{
                        indeces.append(Int(strInd)!)
                    }
                    //print("labelData[\(line.word!)] = \(indeces)")
                    labelData[line.word!] = Array(Set(indeces))
                }
            } catch{
                print("error in getting joke indeces")
            }
        }
            //let gScore = scores[i]x
        var num = 0
        if labels.count>1 {
            num = 1
        }
        /*var labelMultiples: [Int] = []
        for i in 0 ... labels.count-1{
            labelMultiples.append(i-1)
        }
        print("labelMultiples: \(labelMultiples)")*/
        print("real joke fetching")
        for i in 0 ... labels.count - 1{
            let label = labels[i]
            if labelData.keys.contains(label) && label != "line"{
                    print("on label \(label)")
                    do{
                        let idList = labelData[label]!
                        var convertedIdList: [NSNumber] = []
                        for elem in idList{
                            convertedIdList.append(NSNumber(value: elem))
                        }
                            print("before predicate")
                            jokeFetch.predicate = NSPredicate(format: "id IN %@",  convertedIdList) //make sure its not part of a word, just the actual word with a space on each side
                            let fetchedLines = try context.fetch(jokeFetch) as! [RedditJoke]
                            print("After predicate")
                            for joke in fetchedLines{
                                var text = joke.text!
                                //text = text.replacingOccurrences(of: "\\n      \\u201c", with: "")
                                var score = Int(joke.score!)!
                                /*print("text is \(text)")
                                let splitText = text.components(separatedBy: "newLineEncoded")
                                print("elements of split text are: \(splitText)")
                                if splitText.count > 1{
                                    print("i split this text")
                                    if splitText[0].trimmingCharacters(in: .whitespaces).range(of: splitText[1]) != nil{
                                        print("the inception exists")
                                        splitText[1].replacingOccurrences(of: splitText[0].trimmingCharacters(in: .whitespaces), with: "")
                                        text = ""
                                        var firstPhrase = false
                                        for phrase in splitText{
                                            if firstPhrase == false{
                                                firstPhrase = true
                                                text = phrase
                                            } else{
                                                text = "\(text)newLineEncoded\(phrase)) "
                                            }
                                        }
                                    }
                                }*/
                                if text.characters.count < 300{
                                    jokeDatas[i][text] = Double(score)// * Double(labelMultiples[i])
                                }
                            }
                    } catch{
                        print("error with CoreData quote fetch")
                    }
            }
        }
        var captionsExist = false
        for data in jokeDatas{
            if data.count > 0{
                captionsExist = true
                break
            }
        }
        if captionsExist{
            var bestJokes: [String] = []
            //This way, I have one caption from each label (just in case some of the labels are inaccurate, there will be variety.
            for i in 0 ... labels.count-1{
                if jokeDatas[i].count > 0{
                    bestJokes.append( (keyMaxValue(dict: jokeDatas[i])?.replacingOccurrences(of: ".", with: ". "))! )
                }
            }
            return bestJokes
        }
        return ["Looks like we weren't able to generate this type of caption for your image... \nPlease try again with another image"]
    }
    func generateMusicLyrics() -> [String]{
        let labels = self._GLabels!
        let scores = self._GScores!
        
        var captions: [String] = []

        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let lyricFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Lyric")

           if self._faceCount > 0{ //1+ people are in the picture
                do{
                    lyricFetch.predicate = NSPredicate(format: "type contains %@", self.imgType) //make sure its not part of a word, just the actual word with a space on each side
                    let fetchedLines = try context.fetch(lyricFetch) as! [Lyric]

                    for row in fetchedLines{
                        let text = row.text! //in the csv rap line I replaced , with ; to make things easier
                        //let numTags = Int(row["Number of tags"]!)!
                        let type = row.type! //'self' or 'group'
                        if row.tags == nil{
                            print("nil tag for lyric \(row.text!)")
                        }
                        var tags = row.tags!
                        
                        if self.imgType=="self" && !self._smiling{
                            print("inside contemplative")
                            if tags.contains("contemplative"){
                                print("\(text) is contemplative")
                                captions.append("\(text)\n")
                            }
                        } else{
                            if !tags.contains("contemplative"){
                                captions.append("\(text)\n")
                            }
                        }
                    }
                } catch{
                    print("Error while parsing one-liner joke CSV")
                }
            }
        if captions.count > 0{
            var toReturn: [String] = []
            for _ in 0...2{
                //I wrote the randNum func. It did not come with swift. Bottom of this class
                let x = randNum(zeroUpTo: captions.count) //last num is not included
                toReturn.append(captions[x])
                captions.remove(at: x)
            }
            return toReturn
        }
        //else noone is in the picture
        return ["Looks like we weren't able to generate this type of caption for your image... \nPlease try again with another image"]
    }
    
    
    func generateMassQuotes() -> [String]{
        print("generating")
        let labels = self._GLabels!
        
        var captions: [String] = []
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let quoteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "MassQuote")
        
        for i in 0...labels.count-1{
            if self._faceCount > 0{ //1+ people are in the picture
                let label = labels[i]
                do{
                    quoteFetch.predicate = NSPredicate(format: "text contains %@", label) //make sure its not part of a word, just the actual word with a space on each side
                    let fetchedLines = try context.fetch(quoteFetch) as! [MassQuote]
                    
                    for row in fetchedLines{
                        let text = row.text!
                        captions.append("\(text)\n")
                    }
                } catch{
                    print("Error while parsing Mass Quotes")
                }
            }
        }
        if captions.count > 0{
            var toReturn: [String] = []
            for _ in 0...2{
                //I wrote the randNum func. It did not come with swift. Bottom of this class
                let x = randNum(zeroUpTo: captions.count) //last num is not included
                toReturn.append(captions[x])
                captions.remove(at: x)
            }
            return toReturn
        }
        //else noone is in the picture
        return ["Looks like we weren't able to generate this type of caption for your image... \nPlease try again with another image"]
    }
    
    func bestRatedCaptions(data: Dictionary<String,Double>) -> [String]{
        switch data.count{ //switches in swift break automatically
        case 0:
            return []
        case 1:
            return  Array(data.keys)
        default:
            /*var highestScore = -1
            var highestScoreIndex = 0

            for i in 0...scores.count-1{
                let scoreInt = scores[i]
                if  scoreInt > highestScore{
                    highestScore = scoreInt
                    highestScoreIndex = i
                }
            }
            return captions[highestScoreIndex]*/
            
            let sortedKeys = Array(data.keys).sorted(by: ({data[$0]! > data[$1]!}))
            
            var toReturn: [String] = []
            
            var numberToReturn = 3
            if sortedKeys.count < numberToReturn{
                numberToReturn = sortedKeys.count
            }
            for i in 0...numberToReturn-1{
                toReturn.append(sortedKeys[i])
            }
            
            return toReturn
            
            
        }
    }
    
    /*func topCaptions(dict: Dictionary<String,Int>, top: Int) -> [String]{
    //works so long as top > 0
        var mutableDict =  dict
        var captionList: [String] = []
        for i in 1 ... top{
            let caption = keyMaxValue(dict: mutableDict)!
            captionList.append(caption)
            mutableDict.removeValue(forKey: caption)
        }
        return captionList
    }*/
    
    func keyMaxValue(dict: Dictionary<String,Double>) -> String? {
        for (key, value) in dict {
            if value == dict.values.max() {
                return key
            }
        }
        
        return nil
    }
    
    func randNum(zeroUpTo: Int) -> Int{
        return Int(arc4random_uniform(UInt32(zeroUpTo))) //zeroUpTo - 1 is max that can be returned
    }

    
}
