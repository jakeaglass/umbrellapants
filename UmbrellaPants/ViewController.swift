//
//  ViewController.swift
//  UmbrellaPants
//
//  Created by Jake Glass on 7/25/16.
//  Copyright © 2016 Squee!. All rights reserved.
//

import UIKit
import CoreLocation
import SafariServices

class ViewController: UIViewController, CLLocationManagerDelegate {
    var locationManager:CLLocationManager?
    let stackView = UIStackView()
    var firstImageView = UIImageView()
    var secondImageView = UIImageView()
    var commentLabel = UILabel()
    
    var temperature:Int?
    var weather:String?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //authorise location
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
        
        //fix distance
        locationManager?.distanceFilter = 1000 // 1km to generate a change in location
        
        view.backgroundColor = UIColor(white: 1.0, alpha: 0.90) // very light gray colour
        
        self.view.addSubview(stackView)
        self.view.addSubview(commentLabel)
        
        stackView.distribution = .EqualCentering
        stackView.alignment = .Center
        stackView.axis = .Vertical
        
        self.view.layoutMargins = UIEdgeInsets(top:20,left:20,bottom:20,right:20)
        stackView.heightAnchor.constraintEqualToAnchor(self.view.heightAnchor,constant:-130.0).active = true
        stackView.widthAnchor.constraintEqualToAnchor(self.view.widthAnchor,constant:-40.0).active = true
        stackView.leftAnchor.constraintEqualToAnchor(self.view.leftAnchor, constant: 20.0).active = true
        stackView.topAnchor.constraintEqualToAnchor(self.view.topAnchor, constant: 70.0).active = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(firstImageView)
        stackView.addArrangedSubview(secondImageView)
        
        commentLabel.font = UIFont(name: "Avenir", size: 40.0)
        commentLabel.textColor = UIColor(colorLiteralRed: 67.0/255.0, green: 126.0/255.0, blue: 180.0/255.0, alpha: 1.0)
        commentLabel.textAlignment = .Center
        commentLabel.translatesAutoresizingMaskIntoConstraints = false
        commentLabel.bottomAnchor.constraintEqualToAnchor(self.view.bottomAnchor, constant: -25.0).active = true
        commentLabel.leftAnchor.constraintEqualToAnchor(self.view.leftAnchor).constant = 20.0
        commentLabel.rightAnchor.constraintEqualToAnchor(self.view.rightAnchor).constant = 20.0
        commentLabel.widthAnchor.constraintEqualToAnchor(self.view.widthAnchor).active = true
        
        self.navigationItem.title = "UmbrellaPants"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named:"info"), style: .Plain, target: self, action: #selector(showInfo))
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse || status == .AuthorizedAlways {
            locationManager?.startUpdatingLocation()
        } else if status == .Denied {
            let error = UIAlertController(title: "Whoops", message: "The app needs authorization to see your location to get your weather. Please go to settings and allow location when the app is in use.", preferredStyle: .Alert)
            error.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: nil))
            self.presentViewController(error, animated: true, completion: nil)
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        SwiftSpinner.show("Updating Weather for your Location")
        
        let latString = String(locations.last!.coordinate.latitude)
        let lonString = String(locations.last!.coordinate.longitude)
        
        let urlString = "http://forecast.weather.gov/MapClick.php?lat=\(latString)&lon=\(lonString)&FcstType=json"
        let weatherUrl = NSURL(string: urlString)

        let task = NSURLSession.sharedSession().dataTaskWithURL(weatherUrl!){ (data, response, error) in
            SwiftSpinner.hide({() in
                if let error = error {
                    let error = UIAlertController(title: "Whoops", message: "Failed to get the weather with error \(error.localizedDescription) Are you connected to the Internet?", preferredStyle: .Alert)
                    error.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: nil))
                    self.presentViewController(error, animated: true, completion: nil)

                } else if let data = data { //success
                    do {
                        let dict = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                        self.temperature = Int((dict.objectForKey("currentobservation") as! NSDictionary).objectForKey("Temp") as! String)!
                        self.weather = (dict.objectForKey("currentobservation") as! NSDictionary).objectForKey("Weather") as? String
                        
                        //set the temperature indicator label
                        self.commentLabel.text = String(self.temperature!)+"°F"
                        
                        //determine the appropriate images
                        if self.weather?.lowercaseString.rangeOfString("rain") != nil {
                            self.firstImageView.image = UIImage(named:"shirt")
                            if self.temperature > 70 { // shorts
                                self.secondImageView.image = UIImage(named:"shorts")
                            } else if self.temperature <= 70 { // pants
                                self.secondImageView.image = UIImage(named:"pants")
                            }
                        } else {
                            //tshirt weather! (well, just not rain)
                            if self.temperature >= 66 {
                                self.firstImageView.image = UIImage(named:"shirt")
                                self.secondImageView.image = UIImage(named:"shorts")
                            } else if self.temperature < 66 { // colder
                                self.firstImageView.image = UIImage(named:"jacket")
                                self.secondImageView.image = UIImage(named:"pants")
                            }
                        }
                        
                        //size the images
                        self.firstImageView.widthAnchor.constraintEqualToConstant(256.0).active = true
                        self.firstImageView.heightAnchor.constraintEqualToConstant(256.0).active = true
                        self.secondImageView.widthAnchor.constraintEqualToConstant(256.0).active = true
                        self.secondImageView.heightAnchor.constraintEqualToConstant(256.0).active = true


                    } catch {
                        let error = UIAlertController(title: "Whoops", message: "Failed to get the weather with error \(error) Maybe you're not on Earth? ", preferredStyle: .Alert)
                        error.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: nil))
                        self.presentViewController(error, animated: true, completion: nil)
                    }
                    
                }
            })
        }
        task.resume()
        
    }
    
    func showInfo(){
        print("tapped show info")
        let webView = SFSafariViewController(URL: NSURL(string: "http://squee.co")!)
        self.presentViewController(webView, animated: true, completion: nil)
    }
}

