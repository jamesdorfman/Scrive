//
//  ParseJSON.swift
//  GoogleVision
//
//  Created by James Dorfman on 2017-07-06.
//  Copyright © 2017 James Dorfman. All rights reserved.
//

import UIKit

/*
Class to parse JSON file structured like this:
 
 {
    "objects" : [
        {
            "object number": 1
        }
        {
            "object number": 2
        }
    ]
 }
 
 getJSONDict() will return the dictionary that is attached to "objects"
*/
class ParseJSON{
    private var _resourceName: String!
    private var _rootObjName: String!
    private var _type: JSONType!
    
    public enum JSONType {
        case parse
        case index
    }
    
    init(resourceName: String, rootObjName: String, type: JSONType){
        self._resourceName = resourceName
        self._rootObjName = rootObjName
        self._type = type
    }
    
    func getJSONDict() -> [Dictionary<String,Any>]{
        print("root obj: \(_rootObjName)")
        print("just a test")
        if let path = Bundle.main.path(forResource: self._resourceName, ofType: "json") {
            do {
                print("lemme try")
                let jsonData = try NSData(contentsOfFile: path, options: NSData.ReadingOptions.mappedIfSafe)
                print("i tried")
                do {
                    print("in here")
                    let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: jsonData as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                    print("yo")
                    if let objects = jsonResult[_rootObjName] as? [Dictionary<String,Any>] {
                        return objects
                    }
                } catch {
                    print("Error when parsing nested JSON Objects")
                }
            } catch{
                print("Error when trying to open JSON file")
            }
        }
        //This is just for redundency.
        //Should already have returned the dict, since we know that the files exist and we know their content
        return [Dictionary<String,String>()]
    }
    
    func getJSONObj() -> Dictionary<String,Any>{
        print("in the json with \(self._resourceName)")
        if let path = Bundle.main.path(forResource: self._resourceName, ofType: "json") {
            do {
                print("first do")
                let jsonData = try NSData(contentsOfFile: path, options: NSData.ReadingOptions.mappedIfSafe)
                do {
                    print("bout to try")
                    let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: jsonData as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                    print("tried")
                    if let objects = jsonResult[_rootObjName] as? Dictionary<String, Any>{
                        return objects
                    }
                } catch {
                    print("Error when parsing nested JSON Objects")
                    let nsError = error as NSError
                    print(nsError.localizedDescription)
                }
            } catch{
                print("Error when trying to open JSON file")
            }
        } else{
            print("path wont work")
        }
        //This is just for redundency.
        //Should already have returned the dict, since we know that the files exist and we know their content
        return Dictionary<String,Any>()
    }
}
