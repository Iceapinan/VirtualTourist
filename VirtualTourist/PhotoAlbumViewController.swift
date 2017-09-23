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
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var noImagesLabel: UILabel!
    var shouldDelete = false
    var insertedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!
    var selectedPhotos : [IndexPath]! = [] {
        didSet {
            if selectedPhotos.count > 0 {
                shouldDelete = true
                actionButton.setTitle("Remove Selected Pictures", for: .normal)
            } else {
                shouldDelete = false
                actionButton.setTitle("New Collection", for: .normal)
            }
        }
    }
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    lazy var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult> = {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: AppConstants.fcSortDescriptorKey, ascending: true)]
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
        collectionView.allowsMultipleSelection = true
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
                print(error)
                self.noImagesLabel.isHidden = false
            }
            else {
                guard let photosURLs = photosURLs, let page = page else { return }
                    if (photosURLs.count == 0) {
                        self.noImagesLabel.isHidden = false
                    } else {
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
    
    @IBAction func actionButtonTapped(_ sender: Any) {
        if shouldDelete {
            for indexPath in selectedPhotos {
            let object = fetchedResultsController.object(at: indexPath) as! Photo
            AppDelegate.stack.context.delete(object)
            }
            AppDelegate.stack.save()
            selectedPhotos = [IndexPath]()
        } else {
            removeAllPhotosFromDatabase()
            collectionView.reloadData()
            checkIfPhotosDataIsPersisted()
        }
        
    }
    
    func removeAllPhotosFromDatabase() {
        if let photosFetched = fetchedResultsController.fetchedObjects as? [Photo] {
            for photo in photosFetched {
                AppDelegate.stack.context.delete(photo)
            }
        }
        AppDelegate.stack.save()
    }
    
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        insertedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        let set = IndexSet(integer: sectionIndex)
        switch type {
        case .insert:
            self.collectionView.insertSections(set)
        case .delete:
            self.collectionView.deleteSections(set)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .delete:
            deletedIndexPaths.append(indexPath!)
        case .update:
            updatedIndexPaths.append(indexPath!)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        collectionView.performBatchUpdates({() -> Void in
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItems(at: [indexPath])
            }
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItems(at: [indexPath])
            }
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItems(at: [indexPath])
            }
        },  completion: nil)
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
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! AlbumCollectionViewCell
        selectedPhotos = collectionView.indexPathsForSelectedItems
        cell.imageView.alpha = 0.5
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! AlbumCollectionViewCell
        cell.imageView.alpha = 1.0
        selectedPhotos = collectionView.indexPathsForSelectedItems
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections![section].numberOfObjects
    }
    
    fileprivate func downloadPhotosFromFlickr(_ photoFetched: Photo, _ cell: AlbumCollectionViewCell) {
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
    }
    
    fileprivate func configureCell(_ photoFetched: Photo, _ cell: AlbumCollectionViewCell) {
        if photoFetched.photo == nil
        {
            cell.progressIndicator.isHidden = false
            cell.progressIndicator.startAnimating()
            cell.imageView.image = #imageLiteral(resourceName: "placeholder")
            downloadPhotosFromFlickr(photoFetched, cell)
        } else {
            cell.progressIndicator.isHidden = true
            cell.imageView.image = UIImage(data: photoFetched.photo! as Data)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "albumViewCell", for: indexPath) as! AlbumCollectionViewCell
        let photoFetched = fetchedResultsController.object(at: indexPath) as! Photo
        configureCell(photoFetched, cell)
     return cell
  }
}
   

