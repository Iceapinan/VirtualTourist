//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by IceApinan on 20/8/17.
//  Copyright © 2017 IceApinan. All rights reserved.
//

import UIKit
import MapKit
import CoreData
class PhotoAlbumViewController: UIViewController {
    
    var pin : Pin!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    
    let itemsPerRow: CGFloat = 3
    lazy var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult> = {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin = %@", pin)
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: AppDelegate.stack.context, sectionNameKeyPath: nil, cacheName: nil)
    }()
    
    fileprivate func setupDelegates() {
        mapView.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDelegates()
        setInitialMapView()
        setupCollectionViewFlowLayout()
        checkIfPhotosDataIsPersisted()
        
    }
 
    func setupCollectionViewFlowLayout() {
        let space : CGFloat = 2.5
        let dimension = (collectionView.frame.width - (2 * space)) / 3
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        flowLayout.minimumLineSpacing = space
        flowLayout.minimumInteritemSpacing = space
    }
    
    func checkIfPhotosDataIsPersisted() {
        guard (!performFetchPhotos().isEmpty) else {
            downloadFlickrPhotos(pin: pin)
            return
        }
    }

    // Fetch from the database and load into memory
    func performFetchPhotos() -> [Photo] {
        var photos = [Photo]()
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            if let result = fetchedResultsController.fetchedObjects as? [Photo]
            {
                photos = result
            }
        } catch {
            print("Failed to fetch Photos")
        }
        
        return photos
    }
    
    func downloadFlickrPhotos(pin: Pin) {
        FlickrClient.sharedInstance().performFetchPhotosURL(pin: pin) { (photosURLs, page, error) in
            if error != nil {
                guard let error = error else { return }
                self.alertShow(title: "Error!", message: error)
            }
            else {
                guard let photosURLs = photosURLs, let page = page else { return }
                DispatchQueue.main.async {
                    for url in photosURLs {
                        let photoInstance = Photo(pin: pin, url: url, pageNumber: page, context: AppDelegate.stack.context)
                        pin.addToPhoto(photoInstance)
                    }
                    AppDelegate.stack.save()
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
     func setInitialMapView () {
        let point = MKPointAnnotation()
        point.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        mapView.camera.centerCoordinate = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
        mapView.camera.altitude = 10000
        mapView.addAnnotation(point)
        mapView.isUserInteractionEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    @IBAction func newCollectionPressed(_ sender: Any) {
        print(performFetchPhotos())
    }
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
    }
    
}
extension PhotoAlbumViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        return pinView
    }
}

extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections![section].numberOfObjects
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "albumViewCell", for: indexPath) as! AlbumCollectionViewCell
        let photoFetched = fetchedResultsController.object(at: indexPath) as! Photo
    
        if photoFetched.photo == nil
    {
        cell.progressIndicator.isHidden = false
        cell.progressIndicator.startAnimating()
        FlickrClient.sharedInstance().downloadPhotosFromFlickr(pin: pin, photoURL: URL(string: photoFetched.url)!)
        { (data, success, error) in
            if let error = error {
                self.alertShow(title: "Error!", message: error)
            } else
            {
                guard let imageData = data else {
                    return
                }
                    DispatchQueue.main.async
                {
                    photoFetched.photo = imageData
                    AppDelegate.stack.save()
                    let image = UIImage(data: imageData as Data)
                    cell.progressIndicator.stopAnimating()
                    cell.progressIndicator.isHidden = true
                    cell.imageView.image = image!
                    
                }
            }
        }
    } else {
            cell.imageView.image = UIImage(data: photoFetched.photo! as Data)
       }
     return cell
  }
}
   

