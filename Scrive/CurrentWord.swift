//
//  CurrentWord.swift
//  GoogleVision
//
//  Created by James Dorfman on 2017-07-10.
//  Copyright © 2017 James Dorfman. All rights reserved.
//

//SYNONYMS HAVE NOT YET BEEN IMPLEMENTED
//THIS CLASS IS NOT IN USE AT THE MOMENT
//IT IS HERE IN FOR FUTURE UPDATES

import Foundation
import Alamofire

class CurrentWord{
    private var _word: String!
    private var _synonyms: [String]
    
    var word: String{
        get{
            if self._word == nil{
                self._word = ""
            }
            return self._word
        }
    }
    
    var synonyms: [String]{
        // Already initialized in the initializer
        return self._synonyms
    }
    
    init(word: String) {
        self._word = word
        
        self._synonyms = []
    }
    
    func sendWordRequest(completed: @escaping DownloadCompleted){
        let WORD_URL = "\(WORD_BASE)\(self._word)\(WORD_END)"
        Alamofire.request(WORD_URL).responseJSON{ response in
            let result = response.result
            print(response)
            
            if let dict = result.value as? Dictionary<String,Any>{
                if let noun = dict["noun"] as? Dictionary<String,Any>{
                    if let syn = noun["syn"] as? [String]{
                        self._synonyms = syn
                    }
                }
                completed()
            }
        }
    }

}
