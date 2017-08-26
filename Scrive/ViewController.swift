//
//  ViewController.swift
//  GoogleVision
//
//  Created by James Dorfman on 2017-07-04.
//  Copyright © 2017 James Dorfman. All rights reserved.
//
//TO MOVE BOTTOM BUTTONS: camera drawing view and gallary drawing view: they are pinned 10 to the right and 10 to the left, respectively.
//Change those numbers, or delete them, and just center these two containers horizontally (tried that already though, and it didn't look good)
import UIKit
import Alamofire
import MobileCoreServices
import CoreImage
import CoreGraphics
import CoreData
import EVGPUImage2

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var segmentedController: UISegmentedControl!
    var imageView: UIImageView!
    @IBOutlet weak var captionLabel: UITextView!
    
    @IBOutlet weak var analyzingLabel: UILabel!
    var originalImage: UIImage!
    
    @IBOutlet weak var noImageLabel: UILabel!
    
    @IBOutlet weak var cameraButton: UIView!
    @IBOutlet weak var cameraImgHolder: UIView!
    @IBOutlet weak var cameraImg: UIButton!
    @IBOutlet weak var cameraTxt: UIButton!

    @IBOutlet weak var galleryButton: UIView!
    @IBOutlet weak var galleryImgHolder: UIView!
    @IBOutlet weak var galleryImg: UIButton!
    @IBOutlet weak var galleryTxt: UIButton!
    
    var captionData: Dictionary<String,[String]> = [:] //{ 'quotes': ['quote1','quote2'], 'jokes':['joke1','joke2'], ... }
    var transitioning = false

    
    @IBAction func segmentValChanged(_ sender: UISegmentedControl) {
        setCaptionLabel()
    }
    var newMedia: Bool?

    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        imageViewHeight.constant = self.view.frame.height * 3/7

        let cameraBtnList = [cameraButton, cameraImgHolder, cameraImg, cameraTxt]
        
        let galleryBtnList = [galleryButton, galleryImgHolder, galleryImg, galleryTxt]
        
        for view in cameraBtnList{
            let cameraTap = UITapGestureRecognizer(target: self, action: #selector(useCamera))
            view!.addGestureRecognizer(cameraTap)
            view!.isUserInteractionEnabled = true
        }
        
        for view in galleryBtnList{
            let gallaryTap = UITapGestureRecognizer(target: self, action: #selector(pickPhoto))
            view!.addGestureRecognizer(gallaryTap)
            view!.isUserInteractionEnabled = true
        }
        
        segmentedController.layer.cornerRadius = 0
        //segmentedController.layer.borderColor = UIColor.white.cgColor
        segmentedController.layer.borderWidth = 1.5
        segmentedController.layer.masksToBounds = true
        
        self.automaticallyAdjustsScrollViewInsets = false;
        segmentedController.selectedSegmentIndex = 0
        self.segmentedController.addTarget(self, action: #selector(segmentValChanged(_:)), for: .valueChanged)
    }

    func pickPhoto() {
        if UIImagePickerController.isSourceTypeAvailable(
            UIImagePickerControllerSourceType.savedPhotosAlbum) {
            let imagePicker = UIImagePickerController()
            
            imagePicker.delegate = self
            imagePicker.sourceType =
                UIImagePickerControllerSourceType.photoLibrary
            imagePicker.mediaTypes = [kUTTypeImage as String]
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true,
                         completion: nil)
            newMedia = false
        }
    }
    
    
    func useCamera() {
        
        if UIImagePickerController.isSourceTypeAvailable(
            UIImagePickerControllerSourceType.camera) {
            
            let imagePicker = UIImagePickerController()
            
            imagePicker.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
            imagePicker.sourceType =
                UIImagePickerControllerSourceType.camera
            imagePicker.mediaTypes = [kUTTypeImage as String]
            imagePicker.allowsEditing = false
            
            self.present(imagePicker, animated: true,
                         completion: nil)
            newMedia = true
        }
        print("camera used")
    }
    
    func sendImage(){
        /*
         Send image to the GoogleVision servers using the CurrentImage class.
         When request is returned, the code at bottom of function is run.
         */
        
        let base64: String = convertImageToBase64(image: imageView.image!)
    
        let parameters: Parameters! = [
            "requests":[
                [
                    "image": [
                        "content":"\(base64)"
                    ],
                    "features": [
                        [
                            "type": "LABEL_DETECTION"
                        ]
                    ]
                ]
            ]
        ]
        
        segmentedController.isHidden = true
        noImageLabel.isHidden = true
        captionLabel.text = ""
        segmentedController.isHidden = true

        let currentImage = CurrentImage(parameters: parameters)
        
        DispatchQueue.global().async {
            let faceInformation = self.detect()
            currentImage.faceCount = faceInformation.0
            currentImage.smiling = faceInformation.1
            
            DispatchQueue.main.async(execute: {
                //code for UI thread
            })
        }
        
        self.analyzingLabel.isHidden = false
        let timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateAnalyzeLabel), userInfo: nil, repeats: true)
        currentImage.sendImageRequest{
            while self.transitioning == true{
                //pass
            }
            
            UIView.transition(with: self.imageView,
                              duration:1.5,
                              options: .transitionCrossDissolve,
                              animations:{ self.imageView.image = self.originalImage },
                              completion: nil )
 
            self.captionData = currentImage.captionData
            self.setCaptionLabel()
            self.segmentedController.isHidden = false
            UIView.transition(with: self.analyzingLabel,
                              duration:1.5,
                              options: .transitionCrossDissolve,
                              animations:{ self.analyzingLabel.isHidden = true },
                              completion: nil )
            timer.invalidate()
            print("is the timer valid?? \(timer.isValid)")
        }
        imageView.isHidden = false
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        self.dismiss(animated: true, completion: nil)
        
        if mediaType.isEqual(to: kUTTypeImage as String) {
            let image = info[UIImagePickerControllerOriginalImage]
                as! UIImage
            
            let curImg = image.fixOrientation()
            imageView.image = curImg
            originalImage = curImg
            if (newMedia == true) {
                UIImageWriteToSavedPhotosAlbum(image, self,
                                               #selector(ViewController.image(image:didFinishSavingWithError:contextInfo:)), nil)
            } else if mediaType.isEqual(to: kUTTypeMovie as String) {
                // Code to support video here
                // no video supported yet
            }
        }
        sendImage()
    }
    
    
    func image(image: UIImage, didFinishSavingWithError error: NSErrorPointer, contextInfo:UnsafeRawPointer) {
        
        if error != nil {
            let alert = UIAlertController(title: "Save Failed",
                                          message: "Failed to save image",
                                          preferredStyle: UIAlertControllerStyle.alert)
            
            let cancelAction = UIAlertAction(title: "OK",
                                             style: .cancel, handler: nil)
            
            alert.addAction(cancelAction)
            self.present(alert, animated: true,
                         completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func setCaptionLabel(){//Key is the key we use for the captionData dictionary
        
        var key = ""
        if (self.segmentedController.selectedSegmentIndex == 0) { // switch to 1
            key = "quotes"
            self.segmentedController.selectedSegmentIndex = 0
        }
        else if segmentedController.selectedSegmentIndex == 1{
            key = "redditJokes"
            self.segmentedController.selectedSegmentIndex = 1
            //_key = "quotes"
            //_key = "massQuotes"
        }
        else{
            key = "hipHopLyrics"
            self.segmentedController.selectedSegmentIndex = 2
        }
        
        self.captionLabel.text = ""
        for caption in self.captionData[key]!{
            var text = caption
            //var text = "\"\(removeSpecialCharsFromString(text: caption).trimmingCharacters(in: .whitespacesAndNewlines))\"\n"
            text = text.replacingOccurrences(of: "newLineEncoded", with: "\n")//The jokes MAY have that encoded in them (by me, from AppDelegate.swift)
            text = text.replacingOccurrences(of: " nn", with: ". ")
            self.captionLabel.text = "\(self.captionLabel.text!)\(text)\n"
            if key != "hipHopLyrics"{
                self.captionLabel.text = "\(self.captionLabel.text!)\n"
            }
        }
        
        //Add space between each line.
        //This messes with the other styles (like the font), so they must be re-applied
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 6
        let attributes = [NSParagraphStyleAttributeName : style]
        self.captionLabel.attributedText = NSAttributedString(string: self.captionLabel.text!, attributes:attributes)
        self.captionLabel.font = UIFont(name: "HelveticaNeue", size: 17)
        
    }
    
    func detect() -> (Int,Bool){
        var faceCount = 0
        var smiling = false
        
        var imageOptions = Dictionary<String,Any>()
        var imageOrienttion = 0
        switch (imageView.image!.imageOrientation) {
        case UIImageOrientation.up:
            imageOrienttion = 1
            break;
        case UIImageOrientation.down:
            imageOrienttion = 3
            break;
        case UIImageOrientation.left:
            imageOrienttion = 8
            break;
        case UIImageOrientation.right:
            imageOrienttion = 6
            break;
        case UIImageOrientation.upMirrored:
            imageOrienttion = 2
            break;
        case UIImageOrientation.downMirrored:
            imageOrienttion = 4
            break;
        case UIImageOrientation.leftMirrored:
            imageOrienttion = 5
            break;
        case UIImageOrientation.rightMirrored:
            imageOrienttion = 7
            break;
        }
        imageOptions[CIDetectorImageOrientation] = imageOrienttion
        //imageOptions[CIDetectorImageOrientation] = 5
        imageOptions[CIDetectorSmile] = true
        let personciImage = CIImage(cgImage: imageView.image!.cgImage!)
        let accuracy = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy)
        let faces = faceDetector?.features(in: personciImage, options: imageOptions as [String : AnyObject])
        print("found \(Int(faces!.count)) faces")
        faceCount = Int((faces?.count)!)
        if let face = faces?.first as? CIFaceFeature {
            //print("found bounds are \(face.bounds)")
            
            if face.hasSmile {
                print("face is smiling");
                smiling = true
            }else{
                smiling = false
            }
            
            if face.hasLeftEyePosition {
                print("Left eye bounds are \(face.leftEyePosition)")
            }
            
            if face.hasRightEyePosition {
                print("Right eye bounds are \(face.rightEyePosition)")
            }
        } else {
            //no face was detected
        }
        return (faceCount,smiling)
    }
    
    func imageTransitions(){
        self.transitioning = true
        
        let hatch = Crosshatch()
        let dots = PolkaDot()
        let pixel = EmbossFilter()
        pixel.intensity = 0.1

        UIView.transition(
            with: self.imageView,
            duration:0,
            options: .transitionCrossDissolve,
            animations:{ self.imageView.image = self.imageView.image?.filterWithOperation(pixel) },
            completion: { booleanVariable in
                UIView.transition(with: self.imageView,
                duration:3,
                options: .transitionCrossDissolve,
                animations: {
                    self.imageView.image = self.imageView.image?.filterWithOperation(hatch)
                    self.transitioning = false
                },
                completion: { booleanVar in
                            //code here
                        }
                    )
                }
            )
        }
    
    @objc func updateAnalyzeLabel(){
        let text = self.analyzingLabel.text!
        var toSet = ""
        switch text {
        case "Analyzing picture":
            toSet = "Analyzing picture."
        case "Analyzing picture.":
            toSet = "Analyzing picture.."
        case "Analyzing picture..":
            toSet = "Analyzing picture..."
        case "Analyzing picture...":
            toSet = "Analyzing picture"
        default:
            break
        }
        self.analyzingLabel.text = toSet
    }
    
    
    func arrayToJSON(array:[String]) -> Any {
        let jsonData = try! JSONSerialization.data(withJSONObject: array, options: .prettyPrinted)
        let decoded = try! JSONSerialization.jsonObject(with: jsonData, options: [])
        return decoded
    }
    
    func convertImageToBase64(image: UIImage) -> String {
        
        //COME BACK HERE TO IMPROVE APP: MAKE IT THE SAME SIZE EVERY TIME
        //Size limit for Google Cloud is 10485760 bytes
        //currently just works for slightly larger than iphone 7 plus camera resolution
        let imageData = UIImageJPEGRepresentation(image, 0.4)
        let base64String = imageData?.base64EncodedString()
        
        return base64String!
        
    }
    func removeSpecialCharsFromString(text: String) -> String {
        let okayChars : Set<Character> =
            Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890+-*=(),.:!_".characters)
        return String(text.characters.filter {okayChars.contains($0) })
    }
}

