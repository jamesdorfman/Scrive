//
//  CurrentImage.swift
//  GoogleVision
//
//  Created by James Dorfman on 2017-07-04.
//  Copyright © 2017 James Dorfman. All rights reserved.
//

import Foundation
import Alamofire

class CurrentImage{
    
    private var _parameters: Parameters!
    private var _caption: String!
    
    private var _captionData: Dictionary<String,[String]> //Check the properties of ViewController.swift to see what is inside this
    
    private var _faceCount: Int!
    private var _smiling: Bool!
    
    init(parameters: Parameters){
        _parameters = parameters
        _captionData = Dictionary<String,[String]>()
    }
    
    var smiling: Bool{
        get{
            if self._smiling == nil{
                self._smiling = false
            }
            return self._smiling
        }
        set{
            self._smiling = newValue
        }
    }
    var faceCount: Int{
        get{
            if self._faceCount == nil{
                self._faceCount = 0
            }
            return self._faceCount
        }
        set{
            self._faceCount = newValue
        }
    }
    
    var caption: String{
        get{
            if _caption == nil{
                _caption = ""
            }
            return _caption
        }
        set{
            _caption = newValue
        }
    }
    
    var captionData: Dictionary<String,[String]>{
        //Nil value is handled inside the main View Controller already
        return _captionData
    }
    
    func sendImageRequest(completed: @escaping DownloadCompleted){
        Alamofire.request(API_URL, method: .post, parameters: _parameters, encoding: JSONEncoding.default).responseJSON{ response in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = response.result
                print(response)
            
                if let dict = result.value as? Dictionary<String,Any>{
                    if let list = dict["responses"] as? [Dictionary<String,Any>]{
                        if let _labelAnnotations = list[0]["labelAnnotations"] as? [Dictionary<String,  Any>]{
                            self.makeCaptions(labelAnnotations: _labelAnnotations)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        completed()
                    }
                }
            }
            
        }
    }
    
    func makeCaptions(labelAnnotations: [Dictionary<String,Any>]){
        var _labels: [String] = []
        var _scores: [CGFloat] = []
        for label in labelAnnotations{
            if let desc = label["description"] as? String{
                if let gScore = label["score"] as? CGFloat{
                    _labels.append(desc)
                    _scores.append(gScore)
                }
            }
        }
        if _labels.count > 0{
            //Print statements are to see how long each one takes to generate
            let generate = GenerateCaptions(GLabels: _labels, GScores: _scores, faceCount: self.faceCount, smiling: self.smiling)
            print("quotes")
            let quotes = generate.generateQuotes()
            print("end quotes")
            print("jokes")
            let redditJokes = generate.generateRedditJokes()
            print("end jokes")
            print("lyrics")
            let hipHopLyrics = generate.generateMusicLyrics()
            print("end lyrics")
            
            self._captionData["quotes"] = quotes
            self._captionData["redditJokes"] = redditJokes
            self._captionData["hipHopLyrics"] = hipHopLyrics
        }
    }
}
