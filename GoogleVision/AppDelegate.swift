//
//  AppDelegate.swift
//  GoogleVision
//
//  Created by James Dorfman on 2017-07-04.
//  Copyright © 2017 James Dorfman. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        //only preload it the first time app is run.
        let defaults = UserDefaults.standard
        let isPreloaded = defaults.bool(forKey: "isPreloaded")
        if !isPreloaded {
            //ADD JSON AND CSV FILES INTO COREDATA
            preloadQuotes()
            preloadLyrics()
            preloadRedditJokes()
            defaults.set(true, forKey: "isPreloaded")
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "CaptionManager")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    // MARK: - Core Data Saving support
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func preloadQuotes(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let managedObjectContext = delegate.persistentContainer.viewContext
        // Retrieve data from the source file
        let parseForQuotes = ParseJSON(resourceName: "refined_quotes",rootObjName: "quotes", type: ParseJSON.JSONType.parse)
        let quotes = parseForQuotes.getJSONDict() //FROM global.swift        
            // Preload the menu items
        var id = 0
        for elem in quotes {
            let Quote = NSEntityDescription.insertNewObject(forEntityName: "Quote", into: managedObjectContext) as! Quote //Quote = name of entity
            Quote.text = elem["text"]! as! String
            Quote.score = Int64((elem["score"]! as! NSString) as String)!
            var tagList = ""
            var firstFlag = true
            let tags = elem["tags"] as! [String]
            for tag in tags{
                if firstFlag{
                    firstFlag = false
                    tagList = " \(tag)" //add space to the beginning
                }
                else{
                    tagList = "\(tagList) \(tag)"
                }
            }
            tagList = "\(tagList) " //add space to the end
            tagList = "\(tagList) \(Quote.text) "
            Quote.tags = tagList
            
            Quote.id = elem["id"]! as! Int64
            id = id + 1
        }
        do {
            try managedObjectContext.save()
        } catch {
            fatalError("Failure to save context: \(error)")
        }
        
        preloadQuoteIds()
        
    }
    
    func preloadQuoteIds(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let managedObjectContext = delegate.persistentContainer.viewContext
        // Retrieve data from the source file
        let parseForJokes = ParseJSON(resourceName: "refined_quote_index",rootObjName: "words", type: ParseJSON.JSONType.index)
        let words = parseForJokes.getJSONObj()
        //print("words: \(words)")
        for (key,value) in words {
            let QuoteWord = NSEntityDescription.insertNewObject(forEntityName: "QuoteWord", into: managedObjectContext) as! QuoteWord //Quote = name of entity
            QuoteWord.word = key //assuming none of the jokes contain the string 'newLineEncoded'
            let ids = value as! NSArray
            var idString = ""
            var firstFlag = true
            for id in ids{
                if firstFlag{
                    firstFlag = false
                    idString = "\(id)" //no space to the beginning
                }
                else{
                    idString = "\(idString) \(id)"
                }
            }
            QuoteWord.ids = idString
            //print("joke \(JokeWord.word!) has tags \(JokeWord.ids!)")
        }
        do {
            try managedObjectContext.save()
        } catch {
            fatalError("Failure to save context: \(error)")
        }
        
    }

    func preloadRedditJokes(){
        print("preloading reddit jokes")
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let managedObjectContext = delegate.persistentContainer.viewContext
        // Retrieve data from the source file
        let parseForJokes = ParseJSON(resourceName: "reddit_jokes",rootObjName: "jokes", type: ParseJSON.JSONType.parse)
        let jokes = parseForJokes.getJSONDict()
        // Preload the menu items
        var id = 0
        for elem in jokes {
            let Joke = NSEntityDescription.insertNewObject(forEntityName: "RedditJoke", into: managedObjectContext) as! RedditJoke //Quote = name of entity
            Joke.text = "\(elem["text"]!)"
            //print("joke is \(Joke.text!)")
            Joke.score = "\(elem["score"]!)"
            Joke.id = elem["id"]! as! Int64
            id = id + 1
            //print("joke \(Joke.text!) has id \(Joke.id)")
        }
        do {
            try managedObjectContext.save()
        } catch {
            fatalError("Failure to save context: \(error)")
        }
        preloadRedditJokeIds()
    }
    
    func preloadRedditJokeIds(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let managedObjectContext = delegate.persistentContainer.viewContext
        // Retrieve data from the source file
        let parseForJokes = ParseJSON(resourceName: "reddit_joke_index",rootObjName: "words", type: ParseJSON.JSONType.index)
        let words = parseForJokes.getJSONObj()
        //print("words: \(words)")
        for (key,value) in words {
            let JokeWord = NSEntityDescription.insertNewObject(forEntityName: "JokeWord", into: managedObjectContext) as! JokeWord //Quote = name of entity
            JokeWord.word = key //assuming none of the jokes contain the string 'newLineEncoded'
            let ids = value as! NSArray
            var idString = ""
            var firstFlag = true
            for id in ids{
                if firstFlag{
                    firstFlag = false
                    idString = "\(id)" //no space to the beginning
                }
                else{
                    idString = "\(idString) \(id)"
                }
            }
            JokeWord.ids = idString
            //print("joke \(JokeWord.word!) has tags \(JokeWord.ids!)")
        }
        do {
            try managedObjectContext.save()
        } catch {
            fatalError("Failure to save context: \(error)")
        }

    }
    
    func preloadLyrics(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let managedObjectContext = delegate.persistentContainer.viewContext
        
        let rows = getCSVRows(CSVName: "best_rap_lines_tweets_tagged")
        
        for elem in rows {
            let Lyric = NSEntityDescription.insertNewObject(forEntityName: "Lyric", into: managedObjectContext) as! Lyric //Quote = name of entity
            let text = elem["text"]!.replacingOccurrences(of: ";", with: ",") //in the csv rap line I replaced , with ; to make things easier
            Lyric.text = text
            Lyric.type = elem["type"]!
            var tagList = ""
            var firstFlag = true
            let numTags = Int(elem["Number of tags"]!)!
            let tag_postfixes = ["one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve"]
            for num in 0 ... numTags{
                let tag = elem["tag_\(tag_postfixes[num])"]!
                if firstFlag{
                    firstFlag = false
                    tagList = " \(tag)" //add space to the beginning
                }
                else{
                    tagList = "\(tagList) \(tag)"
                }
            }
            tagList = "\(tagList) " //add space to the end
            Lyric.tags = tagList
            //print("lyric \(Lyric.text!) has tags \(Lyric.tags!)")
        }
        do {
            try managedObjectContext.save()
        } catch {
            fatalError("Failure to save context: \(error)")
        }
    }
    
    func getCSVRows(CSVName: String) -> [Dictionary<String,String>]{
        do{
            let path = Bundle.main.path(forResource: CSVName, ofType: "csv")!
            let csv = try CSV (contentsOfURL: path)
            return csv.rows
            
        } catch{
            print("Error while parsing CSV")
        }
        return [Dictionary<String,String>()] //Should never get here

    }
    
    func preloadMassQuotes(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let managedObjectContext = delegate.persistentContainer.viewContext
        
        let file = "mass_quotes.txt" //this is the file. we will write to and read from it
        
        var text = "" //just a text
        
        if let filepath = Bundle.main.path(forResource: "mass_quotes", ofType: "txt")
        {
            do
            {
                let contents = try String(contentsOfFile: filepath)
                let lines = contents.components(separatedBy: "\n")
            for line in lines{
                let Quote = NSEntityDescription.insertNewObject(forEntityName: "MassQuote", into: managedObjectContext) as! MassQuote //Quote = name of entity
                if line.range(of:"\t") != nil{
                    let words = line.components(separatedBy: "\t")
                    //print("words \(words)")
                    Quote.text = words[1] as! String
                }
            }
                } catch{
                    print("ERROR")
                }
            do {
                try managedObjectContext.save()
            } catch {
                fatalError("Failure to save context: \(error)")
            }
        }
    }
}





/*func preloadOneLiners () {
 
 let delegate = UIApplication.shared.delegate as! AppDelegate
 let managedObjectContext = delegate.persistentContainer.viewContext
 // Retrieve data from the source file
 let items = parseCSV()
 // Preload the menu items
 for item in items {
 let oneLiner = NSEntityDescription.insertNewObject(forEntityName: "OneLiner", into: managedObjectContext) as! OneLiner //OneLiner = name of entity
 oneLiner.joke = item["Joke"]
 }
 do {
 try managedObjectContext.save()
 } catch {
 fatalError("Failure to save context: \(error)")
 }
 }*/


/*    func parseCSV() -> [Dictionary<String,String>]{
 let shortJokeIndex = ParseJSON(resourceName: "shortjokes", rootObjName: "words", type: ParseJSON.JSONType.index)
 shortJokeIndeces = shortJokeIndex.getJSONObj()
 do{
 print("try catch")
 let path = Bundle.main.path(forResource: "shortjokes", ofType: "csv")!
 print("path")
 let csv = try CSV(contentsOfURL: path)
 print("contents")
 return csv.rows
 }
 catch{
 print("csv error")
 }
 
 return [Dictionary<String,String>()]
 
 }
 */
