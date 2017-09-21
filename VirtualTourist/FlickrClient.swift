//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by IceApinan on 20/8/17.
//  Copyright © 2017 IceApinan. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class FlickrClient : NSObject {
    
    func performFetchPhotosURL(pin: Pin, completionForPagesNumber : @escaping (_ data: [URL]?,_ totalPages: Int32?,_ error: String?) -> Void) {
        
        let methodParameters =
            [AppConstants.FlickrParameterKeys.APIKey : AppConstants.FlickrParameterValues.APIKey,
             AppConstants.FlickrParameterKeys.Extras: AppConstants.FlickrParameterValues.MediumURL,
             AppConstants.FlickrParameterKeys.Method : AppConstants.FlickrParameterValues.SearchMethod,
             AppConstants.FlickrParameterKeys.SafeSearch: AppConstants.FlickrParameterValues.UseSafeSearch,
             AppConstants.FlickrParameterKeys.Format: AppConstants.FlickrParameterValues.ResponseFormat,
             AppConstants.FlickrParameterKeys.NoJSONCallback: AppConstants.FlickrParameterValues.DisableJSONCallback,
             AppConstants.FlickrParameterKeys.Latitude: pin.latitude,
             AppConstants.FlickrParameterKeys.Longitude: pin.longitude] as [String : Any]
        
        Alamofire.request(flickrURLFromParameters(methodParameters as [String:AnyObject]), method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            if response.result.error == nil {
                guard let data = response.data else { return }
                let json = JSON(data: data)
                
                // MARK : Get Total Pages Number
                
                 let totalPages = json[AppConstants.FlickrResponseKeys.Photos][AppConstants.FlickrResponseKeys.Pages].int
                
                if let totalPages = totalPages {
                    let pageLimit = min(totalPages, 40)
                    let randomPage = Int32(arc4random_uniform(UInt32(pageLimit))) + 1
                self.getPhotosURLFromLocation(pin: pin, method: methodParameters, pageNumber: randomPage, completionForPhotosURL: completionForPagesNumber)
                } else {
                     completionForPagesNumber(nil, nil, "Cannot find key '\(AppConstants.FlickrResponseKeys.Pages)' ")
                }
            }
            else {
                guard let error = (response.result.error as NSError?)?.userInfo.description else { return }
                completionForPagesNumber(nil, nil, error)
            }
        }
    }
    
   private func getPhotosURLFromLocation (pin: Pin, method: [String: Any], pageNumber: Int32, completionForPhotosURL : @escaping (_ data: [URL]?,_ totalPages: Int32?,_ error: String?) -> Void) {
        var methodParametersWithPageNumber = method
        methodParametersWithPageNumber[AppConstants.FlickrParameterKeys.Page] = pageNumber
        methodParametersWithPageNumber[AppConstants.FlickrParameterKeys.PerPage] = AppConstants.maximumPhotosPerPage
        var photosURLArray = [URL]()
    Alamofire.request(flickrURLFromParameters(methodParametersWithPageNumber as [String:AnyObject]), method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            
            // MARK : Get Photos URLs from the random page
            if response.result.error == nil {
                guard let data = response.data else { return }
                let json = JSON(data: data)
                for photoURL in json[AppConstants.FlickrResponseKeys.Photos][AppConstants.FlickrResponseKeys.Photo].arrayValue {
                    guard let photoURL = photoURL[AppConstants.FlickrResponseKeys.MediumURL].url?.absoluteURL else {
                        return }
                    photosURLArray.append(photoURL)
                }
                if !(photosURLArray.isEmpty) {
                    completionForPhotosURL(photosURLArray, pageNumber, nil)
                } else {
                    completionForPhotosURL(nil, pageNumber, "No data was returned by the request!")
                }
                
            } else {
                guard let error = (response.result.error as NSError?)?.userInfo.description else { return }
                completionForPhotosURL(nil, pageNumber, error)
            }
            
        }
        
        
    }
    
    func downloadPhotosFromFlickr(pin : Pin, photoURL: URL, completion : @escaping (_ imageData: NSData?, _ success: Bool, _ error: String?) -> Void)
    {
        Alamofire.request(photoURL).responseData(completionHandler: { (response) in
            
            if response.result.error == nil {
            guard let data = response.data else { return }
            guard let image = UIImage(data: data)
             else { return }
                guard let imageData = UIImageJPEGRepresentation(image, 1.0) as NSData? else { return }
                completion(imageData, true, nil)
                
            } else {
                guard let error = (response.result.error as NSError?)?.userInfo.description else { return }
                completion(nil, false, error)
            }
        })
    
    
}
    // MARK: Helper for Creating a URL from Parameters
    private func flickrURLFromParameters(_ parameters: [String: AnyObject]) -> URL
    {

        var components = URLComponents()
        components.scheme = AppConstants.Flickr.APIScheme
        components.host = AppConstants.Flickr.APIHost
        components.path = AppConstants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
    
}

